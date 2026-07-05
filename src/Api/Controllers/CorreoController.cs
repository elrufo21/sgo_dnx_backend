using System.Globalization;
using System.Net;
using System.Net.Mail;
using Ecommerce.Application.Models.Email;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public class CorreoController : ControllerBase
{
    private const long MaxArchivoBytes = 10 * 1024 * 1024;
    private const long MaxTotalBytes = 20 * 1024 * 1024;
    private static readonly HttpClient DescargaHttpClient = new()
    {
        Timeout = TimeSpan.FromSeconds(30)
    };

    private static readonly HashSet<string> ExtensionesPermitidas = new(StringComparer.OrdinalIgnoreCase)
    {
        ".pdf",
        ".xml",
        ".zip"
    };

    private readonly EmailSettings _emailSettings;

    public CorreoController(IOptions<EmailSettings> emailSettings)
    {
        _emailSettings = emailSettings.Value;
    }

    [AllowAnonymous]
    [HttpPost("enviar-comprobante", Name = "EnviarCorreoComprobante")]
    [RequestSizeLimit(25 * 1024 * 1024)]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    [ProducesResponseType((int)HttpStatusCode.BadRequest)]
    [ProducesResponseType((int)HttpStatusCode.InternalServerError)]
    public async Task<IActionResult> EnviarComprobante([FromForm] EnviarCorreoComprobanteRequest request, CancellationToken cancellationToken)
    {
        var errores = ValidarRequest(request);
        if (errores.Count > 0)
        {
            return BadRequest(new
            {
                ok = false,
                mensaje = "Existen campos obligatorios faltantes o inválidos para enviar el correo.",
                errores
            });
        }

        var emisor = (_emailSettings.Email ?? string.Empty).Trim();
        var clave = (_emailSettings.Key ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(emisor) || string.IsNullOrWhiteSpace(clave))
        {
            return StatusCode((int)HttpStatusCode.InternalServerError, new
            {
                ok = false,
                mensaje = "No está configurado EmailSettings:Email o EmailSettings:Key."
            });
        }

        try
        {
            using var mail = new MailMessage
            {
                From = new MailAddress(emisor, string.IsNullOrWhiteSpace(_emailSettings.DisplayName) ? null : _emailSettings.DisplayName.Trim()),
                Subject = request.Asunto!.Trim(),
                Body = request.Cuerpo ?? string.Empty,
                IsBodyHtml = request.EsHtml
            };

            foreach (var destinatario in SepararCorreos(request.Para))
            {
                mail.To.Add(destinatario);
            }

            foreach (var copia in SepararCorreos(request.Cc))
            {
                mail.CC.Add(copia);
            }

            foreach (var copiaOculta in SepararCorreos(request.Bcc))
            {
                mail.Bcc.Add(copiaOculta);
            }

            foreach (var archivo in ObtenerArchivos(request))
            {
                var stream = archivo.OpenReadStream();
                mail.Attachments.Add(new Attachment(stream, archivo.FileName, archivo.ContentType));
            }

            var adjuntosDescargados = await DescargarAdjuntosUrlAsync(request, cancellationToken);
            foreach (var archivo in adjuntosDescargados)
            {
                mail.Attachments.Add(new Attachment(archivo.Stream, archivo.Nombre, archivo.ContentType));
            }

            using var smtp = new SmtpClient
            {
                Host = string.IsNullOrWhiteSpace(_emailSettings.Host) ? "smtp.gmail.com" : _emailSettings.Host.Trim(),
                Port = _emailSettings.Port.GetValueOrDefault(587),
                EnableSsl = _emailSettings.EnableSsl ?? true,
                DeliveryMethod = SmtpDeliveryMethod.Network,
                UseDefaultCredentials = false,
                Credentials = new NetworkCredential(emisor, clave)
            };

            await smtp.SendMailAsync(mail, cancellationToken);

            var adjuntosRespuesta = ObtenerArchivos(request).Select(a => new
                {
                    origen = "file",
                    nombre = a.FileName,
                    bytes = a.Length
                })
                .Concat(adjuntosDescargados.Select(a => new
                {
                    origen = "url",
                    nombre = a.Nombre,
                    bytes = a.Bytes
                }))
                .ToList();

            return Ok(new
            {
                ok = true,
                mensaje = "Correo enviado correctamente.",
                para = SepararCorreos(request.Para),
                adjuntos = adjuntosRespuesta
            });
        }
        catch (SmtpException ex)
        {
            return StatusCode((int)HttpStatusCode.InternalServerError, new
            {
                ok = false,
                mensaje = "No se pudo enviar el correo por SMTP.",
                detalle = ex.Message,
                status = ex.StatusCode.ToString()
            });
        }
        catch (Exception ex)
        {
            return StatusCode((int)HttpStatusCode.InternalServerError, new
            {
                ok = false,
                mensaje = "No se pudo enviar el correo.",
                detalle = ex.Message
            });
        }
    }

    private static List<string> ValidarRequest(EnviarCorreoComprobanteRequest request)
    {
        var errores = new List<string>();
        if (string.IsNullOrWhiteSpace(request.Para))
        {
            errores.Add("Para es requerido.");
        }
        else
        {
            foreach (var correo in SepararCorreos(request.Para))
            {
                if (!MailAddress.TryCreate(correo, out _))
                {
                    errores.Add($"Correo destinatario inválido: {correo}.");
                }
            }
        }

        foreach (var correo in SepararCorreos(request.Cc).Concat(SepararCorreos(request.Bcc)))
        {
            if (!MailAddress.TryCreate(correo, out _))
            {
                errores.Add($"Correo copia inválido: {correo}.");
            }
        }

        if (string.IsNullOrWhiteSpace(request.Asunto))
        {
            errores.Add("Asunto es requerido.");
        }

        var archivos = ObtenerArchivos(request).ToList();
        var urls = ObtenerUrlsAdjuntos(request).ToList();
        if (archivos.Count == 0 && urls.Count == 0)
        {
            errores.Add("Debe enviar al menos un archivo adjunto.");
        }

        if (!TieneXml(request))
        {
            errores.Add("Debe enviar el XML como archivo xml o como URL xmlUrl/xml_url/DOCU_XML_URL.");
        }

        if (!TieneCdr(request))
        {
            errores.Add("Debe enviar el CDR como archivo cdr o como URL cdrUrl/cdr_url/DOCU_CDR_URL.");
        }

        var totalBytes = archivos.Sum(a => a.Length);
        if (totalBytes > MaxTotalBytes)
        {
            errores.Add($"El total de adjuntos no debe superar {FormatearMb(MaxTotalBytes)} MB.");
        }

        foreach (var archivo in archivos)
        {
            if (archivo.Length <= 0)
            {
                errores.Add($"El archivo {archivo.FileName} está vacío.");
                continue;
            }

            if (archivo.Length > MaxArchivoBytes)
            {
                errores.Add($"El archivo {archivo.FileName} supera {FormatearMb(MaxArchivoBytes)} MB.");
            }

            var extension = Path.GetExtension(archivo.FileName);
            if (!ExtensionesPermitidas.Contains(extension))
            {
                errores.Add($"El archivo {archivo.FileName} no tiene extensión permitida. Use PDF, XML o ZIP.");
            }
        }

        foreach (var url in urls)
        {
            if (!Uri.TryCreate(url.Url, UriKind.Absolute, out var uri) ||
                (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps))
            {
                errores.Add($"{url.Campo} debe ser una URL http/https válida.");
                continue;
            }

            var extension = Path.GetExtension(uri.AbsolutePath);
            if (!string.IsNullOrWhiteSpace(extension) && !ExtensionesPermitidas.Contains(extension))
            {
                errores.Add($"{url.Campo} debe apuntar a un archivo PDF, XML o ZIP.");
            }
        }

        return errores;
    }

    private static async Task<IReadOnlyList<AdjuntoDescargado>> DescargarAdjuntosUrlAsync(
        EnviarCorreoComprobanteRequest request,
        CancellationToken cancellationToken)
    {
        var archivos = new List<AdjuntoDescargado>();
        foreach (var url in ObtenerUrlsAdjuntos(request))
        {
            using var response = await DescargaHttpClient.GetAsync(url.Url, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                throw new InvalidOperationException($"{url.Campo} no se pudo descargar ({(int)response.StatusCode} {response.ReasonPhrase}). URL: {url.Url}");
            }

            var contentLength = response.Content.Headers.ContentLength;
            if (contentLength.HasValue && contentLength.Value > MaxArchivoBytes)
            {
                throw new InvalidOperationException($"{url.Campo} supera {FormatearMb(MaxArchivoBytes)} MB.");
            }

            var bytes = await response.Content.ReadAsByteArrayAsync(cancellationToken);
            if (bytes.Length <= 0)
            {
                throw new InvalidOperationException($"{url.Campo} no devolvió contenido.");
            }

            if (bytes.Length > MaxArchivoBytes)
            {
                throw new InvalidOperationException($"{url.Campo} supera {FormatearMb(MaxArchivoBytes)} MB.");
            }

            var nombre = url.NombreFallback;
            var contentType = response.Content.Headers.ContentType?.MediaType ?? "application/octet-stream";
            archivos.Add(new AdjuntoDescargado(nombre, contentType, bytes.Length, new MemoryStream(bytes)));
        }

        return archivos;
    }

    private static IEnumerable<IFormFile> ObtenerArchivos(EnviarCorreoComprobanteRequest request)
    {
        if (request.Pdf is not null)
        {
            yield return request.Pdf;
        }

        if (request.Xml is not null)
        {
            yield return request.Xml;
        }

        if (request.Cdr is not null)
        {
            yield return request.Cdr;
        }

        if (request.Archivos is null)
        {
            yield break;
        }

        foreach (var archivo in request.Archivos.Where(a => a is not null))
        {
            yield return archivo;
        }
    }

    private static IEnumerable<AdjuntoUrl> ObtenerUrlsAdjuntos(EnviarCorreoComprobanteRequest request)
    {
        var nombreBase = ConstruirNombreBaseComprobante(request);

        var pdfUrl = ObtenerPrimerValor(request.PdfUrl, request.pdf_url, request.DOCU_PDF_URL);
        if (!string.IsNullOrWhiteSpace(pdfUrl))
        {
            yield return new AdjuntoUrl("pdfUrl", pdfUrl, "comprobante.pdf");
        }

        var xmlUrl = ObtenerPrimerValor(request.XmlUrl, request.xml_url, request.XML_URL, request.DOCU_XML_URL);
        if (!string.IsNullOrWhiteSpace(xmlUrl))
        {
            yield return new AdjuntoUrl("xmlUrl", xmlUrl, $"{nombreBase}.XML");
        }

        var cdrUrl = ObtenerPrimerValor(request.CdrUrl, request.cdr_url, request.CDR_URL, request.DOCU_CDR_URL);
        if (!string.IsNullOrWhiteSpace(cdrUrl))
        {
            yield return new AdjuntoUrl("cdrUrl", cdrUrl, $"R-{nombreBase}.XML");
        }
    }

    private static string ConstruirNombreBaseComprobante(EnviarCorreoComprobanteRequest request)
    {
        var ruc = (request.RucEmisor ?? "").Trim();
        var comprobante = (request.NroComprobante ?? "").Trim().ToUpper();

        if (string.IsNullOrWhiteSpace(ruc) || string.IsNullOrWhiteSpace(comprobante))
        {
            return "comprobante";
        }

        return $"{ruc}-01-{comprobante}";
    }
    private static bool TieneXml(EnviarCorreoComprobanteRequest request)
    {
        return request.Xml is not null ||
            !string.IsNullOrWhiteSpace(ObtenerPrimerValor(request.XmlUrl, request.xml_url, request.XML_URL, request.DOCU_XML_URL));
    }

    private static bool TieneCdr(EnviarCorreoComprobanteRequest request)
    {
        return request.Cdr is not null ||
            !string.IsNullOrWhiteSpace(ObtenerPrimerValor(request.CdrUrl, request.cdr_url, request.CDR_URL, request.DOCU_CDR_URL));
    }

    private static string? ObtenerPrimerValor(params string?[] valores)
    {
        return valores.FirstOrDefault(valor => !string.IsNullOrWhiteSpace(valor))?.Trim();
    }

    private static string ObtenerNombreArchivoUrl(string url, string fallback)
    {
        return Uri.TryCreate(url, UriKind.Absolute, out var uri)
            ? Path.GetFileName(uri.AbsolutePath) is { Length: > 0 } nombre ? nombre : fallback
            : fallback;
    }

    private static IReadOnlyList<string> SepararCorreos(string? valor)
    {
        return (valor ?? string.Empty)
            .Split(new[] { ';', ',' }, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(correo => !string.IsNullOrWhiteSpace(correo))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static string FormatearMb(long bytes)
    {
        return (bytes / 1024m / 1024m).ToString("0.##", CultureInfo.InvariantCulture);
    }

    private sealed record AdjuntoUrl(string Campo, string Url, string NombreFallback);

    private sealed record AdjuntoDescargado(string Nombre, string ContentType, long Bytes, Stream Stream);
}

public class EnviarCorreoComprobanteRequest
{
    public string? Para { get; set; }
    public string? Cc { get; set; }
    public string? Bcc { get; set; }
    public string? Asunto { get; set; }
    public string? Cuerpo { get; set; }
    public bool EsHtml { get; set; } = true;
    public string? PdfUrl { get; set; }
    public string? XmlUrl { get; set; }
    public string? CdrUrl { get; set; }
    public string? pdf_url { get; set; }
    public string? xml_url { get; set; }
    public string? cdr_url { get; set; }
    public string? XML_URL { get; set; }
    public string? CDR_URL { get; set; }
    public string? DOCU_PDF_URL { get; set; }
    public string? DOCU_XML_URL { get; set; }
    public string? DOCU_CDR_URL { get; set; }
    public string? RucEmisor { get; set; }
    public string? NroComprobante { get; set; }
    public IFormFile? Pdf { get; set; }
    public IFormFile? Xml { get; set; }
    public IFormFile? Cdr { get; set; }
    public List<IFormFile>? Archivos { get; set; }
}
