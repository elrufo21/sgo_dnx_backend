using System.Collections.Generic;
using BusinessEntities;
using MegaRosita.Capa.Aplicacion;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Ecommerce.Api.Legacy;

public sealed class CpeGateway : ICpeGateway
{
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
