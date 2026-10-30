using System.Collections.Generic;
using BusinessEntities;
using MegaRosita.Capa.Aplicacion;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Xml.Linq;
using System.IO.Compression;
using System.Text;

namespace Ecommerce.Api.Legacy;

public sealed class CpeGateway : ICpeGateway
{
    private static readonly HttpClient CdrClient = new() { Timeout = TimeSpan.FromSeconds(30) };
    private readonly CpePruebasSettings _pruebasSettings;
    private readonly ILogger<CpeGateway> _logger;

    public CpeGateway(IOptions<CpePruebasSettings> pruebasSettings, ILogger<CpeGateway> logger)
    {
        _pruebasSettings = pruebasSettings.Value;
        _logger = logger;
    }

    public Dictionary<string, string> Envio(CPE cpe)
    {
        var respuesta = new CPEConfig().Envio(cpe);

        if (_pruebasSettings.GuardarXmlNotaCredito &&
            string.Equals(cpe.COD_TIPO_DOCUMENTO?.Trim(), "07", StringComparison.Ordinal))
        {
            IntentarGuardarXmlNotaCreditoPruebas(cpe, respuesta);
        }

        return respuesta;
    }

    public Dictionary<string, string> EnvioResumen(CPE_RESUMEN_BOLETA resumen)
    {
        return new CPEConfig().EnvioResumen(resumen);
    }

    public Dictionary<string, string> EnvioBaja(CPE_BAJA baja)
    {
        return new CPEConfig().EnvioBaja(baja);
    }

    public Dictionary<string, string> ConsultaTicket(CONSULTA_TICKET consultaTicket)
    {
        return new CPEConfig().ConsultaTicket(consultaTicket);
    }

    public async Task<byte[]> ConsultarCdrAsync(string ruc, string usuarioSol, string claveSol, int tipoProceso, string serie, string numero, CancellationToken cancellationToken)
    {
        XNamespace soap = "http://schemas.xmlsoap.org/soap/envelope/";
        XNamespace wsse = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";
        XNamespace service = "http://service.sunat.gob.pe";
        var envelope = new XDocument(new XElement(soap + "Envelope",
            new XElement(soap + "Header", new XElement(wsse + "Security", new XElement(wsse + "UsernameToken",
                new XElement(wsse + "Username", ruc + usuarioSol), new XElement(wsse + "Password", claveSol)))),
            new XElement(soap + "Body", new XElement(service + "getStatusCdr",
                new XElement("rucComprobante", ruc), new XElement("tipoComprobante", "01"),
                new XElement("serieComprobante", serie), new XElement("numeroComprobante", numero)))));
        using var request = new HttpRequestMessage(HttpMethod.Post, CPEConfig.ResolverUrlOce(tipoProceso));
        request.Headers.TryAddWithoutValidation("SOAPAction", "\"http://service.sunat.gob.pe/getStatusCdr\"");
        request.Content = new StringContent(envelope.ToString(SaveOptions.DisableFormatting), Encoding.UTF8, "text/xml");
        using var response = await CdrClient.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
        if (response.Content.Headers.ContentLength > 15 * 1024 * 1024) throw new InvalidOperationException("La respuesta del OSE es demasiado grande.");
        await using var body = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var reader = System.Xml.XmlReader.Create(body, new System.Xml.XmlReaderSettings { DtdProcessing = System.Xml.DtdProcessing.Prohibit, MaxCharactersInDocument = 15 * 1024 * 1024 });
        XDocument result;
        try { result = XDocument.Load(reader); }
        catch (System.Xml.XmlException) when (!response.IsSuccessStatusCode)
        {
            throw new CdrConsultaException($"El OSE respondió con HTTP {(int)response.StatusCode} sin un error SOAP válido.");
        }
        var fault = result.Descendants().FirstOrDefault(x => x.Name.LocalName == "Fault");
        if (fault is not null)
        {
            var faultCode = fault.Descendants().FirstOrDefault(x => x.Name.LocalName == "faultcode")?.Value.Trim() ?? "";
            var faultMessage = fault.Descendants().FirstOrDefault(x => x.Name.LocalName == "faultstring")?.Value.Trim() ?? "";
            foreach (var secret in new[] { ruc + usuarioSol, usuarioSol, claveSol })
            {
                if (!string.IsNullOrWhiteSpace(secret))
                {
                    faultCode = faultCode.Replace(secret, "[oculto]", StringComparison.OrdinalIgnoreCase);
                    faultMessage = faultMessage.Replace(secret, "[oculto]", StringComparison.OrdinalIgnoreCase);
                }
            }
            faultCode = new string(faultCode.Where(c => char.IsLetterOrDigit(c) || c is ':' or '.' or '-' or '_').Take(80).ToArray());
            faultMessage = new string(faultMessage.Where(c => !char.IsControl(c)).Take(300).ToArray());
            throw new CdrConsultaException($"El OSE devolvió un error SOAP{(faultCode.Length > 0 ? $" ({faultCode})" : "")}{(faultMessage.Length > 0 ? $": {faultMessage}" : ".")}");
        }
        if (!response.IsSuccessStatusCode)
            throw new CdrConsultaException($"El OSE respondió con HTTP {(int)response.StatusCode}.");
        var status = result.Descendants().FirstOrDefault(x => x.Name.LocalName == "statusCode")?.Value.Trim();
        var content = result.Descendants().FirstOrDefault(x => x.Name.LocalName == "content")?.Value.Trim();
        if (!int.TryParse(status, out var statusNumber) || statusNumber != 0 || string.IsNullOrWhiteSpace(content))
        {
            var codigo = !string.IsNullOrWhiteSpace(status) && status.Length <= 12 && status.All(char.IsAsciiLetterOrDigit) ? status : "desconocido";
            throw new CdrConsultaException($"El OSE no devolvió el CDR. Código de respuesta: {codigo}.");
        }
        var zipBytes = Convert.FromBase64String(content);
        using var zipStream = new MemoryStream(zipBytes);
        using var zip = new ZipArchive(zipStream, ZipArchiveMode.Read);
        var entry = zip.Entries.SingleOrDefault(x => x.Name.EndsWith(".xml", StringComparison.OrdinalIgnoreCase));
        if (entry is null || entry.Length <= 0 || entry.Length > 10 * 1024 * 1024) throw new InvalidOperationException("El CDR recibido no contiene un XML válido.");
        using var cdrStream = entry.Open();
        using var output = new MemoryStream();
        await cdrStream.CopyToAsync(output, cancellationToken);
        output.Position = 0;
        using var xmlReader = System.Xml.XmlReader.Create(output, new System.Xml.XmlReaderSettings { DtdProcessing = System.Xml.DtdProcessing.Prohibit, MaxCharactersInDocument = 10 * 1024 * 1024 });
        var cdr = XDocument.Load(xmlReader);
        if (cdr.Root?.Name.LocalName != "ApplicationResponse") throw new InvalidOperationException("El XML recibido no es un CDR.");
        var reference = cdr.Descendants().FirstOrDefault(x => x.Name.LocalName == "DocumentReference")?.Elements().FirstOrDefault(x => x.Name.LocalName == "ID")?.Value.Trim();
        var parts = reference?.Split('-', 2);
        if (parts?.Length != 2 || !string.Equals(parts[0], serie, StringComparison.OrdinalIgnoreCase) ||
            !long.TryParse(parts[1], out var referenceNumber) || !long.TryParse(numero, out var requestedNumber) || referenceNumber != requestedNumber)
            throw new InvalidOperationException("El CDR recibido corresponde a otro comprobante.");
        return output.ToArray();
    }

    private void IntentarGuardarXmlNotaCreditoPruebas(CPE cpe, Dictionary<string, string> respuesta)
    {
        try
        {
            var nombreArchivo = $"{cpe.NRO_DOCUMENTO_EMPRESA}-{cpe.COD_TIPO_DOCUMENTO}-{cpe.NRO_COMPROBANTE}";
            var rutaOrigen = CpeRutaResolver.ResolverRutaTrabajo(cpe.TIPO_PROCESO);
            var archivoOrigen = Path.Combine(rutaOrigen, nombreArchivo + ".XML");

            if (!File.Exists(archivoOrigen))
            {
                _logger.LogWarning(
                    "GuardarXmlNotaCredito activo, pero no se encontró el XML en {RutaXml}",
                    archivoOrigen);
                respuesta["xml_prueba_guardado"] = "false";
                respuesta["xml_prueba_mensaje"] = "No se encontró el XML firmado en la ruta de trabajo.";
                return;
            }

            var carpetaDestino = string.IsNullOrWhiteSpace(_pruebasSettings.RutaXmlNotaCredito)
                ? Path.Combine(AppContext.BaseDirectory, "xml-pruebas", "nota-credito")
                : _pruebasSettings.RutaXmlNotaCredito.Trim();

            Directory.CreateDirectory(carpetaDestino);
            var archivoDestino = Path.Combine(carpetaDestino, nombreArchivo + ".xml");
            File.Copy(archivoOrigen, archivoDestino, overwrite: true);

            respuesta["xml_prueba_guardado"] = "true";
            respuesta["xml_prueba_ruta"] = archivoDestino;

            _logger.LogInformation("XML de nota de crédito guardado para pruebas en {RutaXml}", archivoDestino);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "No se pudo guardar el XML de nota de crédito para pruebas.");
            respuesta["xml_prueba_guardado"] = "false";
            respuesta["xml_prueba_mensaje"] = ex.Message;
        }
    }
}

public sealed class CdrConsultaException : Exception
{
    public CdrConsultaException(string message) : base(message) { }
}
