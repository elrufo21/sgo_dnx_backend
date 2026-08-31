using System.Globalization;
using System.Net;
using System.Net.Mail;
using Ecommerce.Application.Models.Email;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
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
                Body = ConstruirCuerpoComprobante(request),
                IsBodyHtml = true
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

    [Authorize]
    [HttpPost("enviar-cierre-caja", Name = "EnviarCorreoCierreCaja")]
    [RequestSizeLimit(25 * 1024 * 1024)]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    [ProducesResponseType((int)HttpStatusCode.BadRequest)]
    [ProducesResponseType((int)HttpStatusCode.InternalServerError)]
    public async Task<IActionResult> EnviarCierreCaja(
        [FromForm] EnviarCierreCajaRequest request,
        [FromServices] IConfiguration configuration,
        CancellationToken cancellationToken)
    {
        if (request.CajaId <= 0)
            return BadRequest(new { ok = false, mensaje = "No se pudo identificar la caja." });
        if (request.Pdf is null || request.Pdf.Length <= 0)
            return BadRequest(new { ok = false, mensaje = "Debe adjuntar el PDF del cierre de caja." });
        if (request.Pdf.Length > MaxArchivoBytes ||
            !string.Equals(Path.GetExtension(request.Pdf.FileName), ".pdf", StringComparison.OrdinalIgnoreCase))
            return BadRequest(new { ok = false, mensaje = "El adjunto debe ser un PDF de hasta 10 MB." });

        var connectionString = configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode((int)HttpStatusCode.InternalServerError, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        string destinatarios;
        var nombreCompania = "SGO";
        var nombreResponsable = "Equipo de caja";
        await using (var connection = new SqlConnection(connectionString))
        await using (var command = new SqlCommand("""
            SELECT compania.CorreosAdmin,
                   COALESCE(NULLIF(LTRIM(RTRIM(compania.CompaniaComercial)), ''),
                            NULLIF(LTRIM(RTRIM(compania.CompaniaRazonSocial)), ''),
                            'SGO') AS NombreCompania,
                   COALESCE(
                       NULLIF(LTRIM(RTRIM(CONCAT(
                           SUBSTRING(ISNULL(personal.PersonalNombres, ''), 1, CHARINDEX(' ', ISNULL(personal.PersonalNombres, '') + ' ') - 1),
                           ' ',
                           SUBSTRING(ISNULL(personal.PersonalApellidos, ''), 1, CHARINDEX(' ', ISNULL(personal.PersonalApellidos, '') + ' ') - 1)
                       ))), ''),
                       NULLIF(LTRIM(RTRIM(caja.CajaEncargado)), ''),
                       'Equipo de caja'
                   ) AS NombreResponsable
              FROM Caja caja
              INNER JOIN Usuarios usuario ON usuario.UsuarioID = caja.UsuarioId
              INNER JOIN Personal personal ON personal.PersonalId = usuario.PersonalId
              INNER JOIN Compania compania ON compania.CompaniaId = personal.CompaniaId
             WHERE caja.CajaId = @CajaId
            """, connection))
        {
            command.Parameters.AddWithValue("@CajaId", request.CajaId);
            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (await reader.ReadAsync(cancellationToken))
            {
                destinatarios = reader["CorreosAdmin"]?.ToString()?.Trim() ?? string.Empty;
                nombreCompania = reader["NombreCompania"]?.ToString()?.Trim() ?? nombreCompania;
                nombreResponsable = reader["NombreResponsable"]?.ToString()?.Trim() ?? nombreResponsable;
            }
            else
            {
                destinatarios = string.Empty;
            }
        }

        var correos = SepararCorreos(destinatarios);
        if (correos.Count == 0)
            return BadRequest(new { ok = false, mensaje = "La compañía no tiene correos administrativos configurados." });
        if (correos.Any(correo => !MailAddress.TryCreate(correo, out _)))
            return BadRequest(new { ok = false, mensaje = "Hay correos administrativos inválidos en la compañía." });

        var emisor = (_emailSettings.Email ?? string.Empty).Trim();
        var clave = (_emailSettings.Key ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(emisor) || string.IsNullOrWhiteSpace(clave))
            return StatusCode((int)HttpStatusCode.InternalServerError, new { ok = false, mensaje = "No está configurado el correo de envío." });

        var fecha = request.FechaReporte?.Date ?? DateTime.Today;
        var fechaTexto = fecha.ToString("dd-MM-yyyy", CultureInfo.InvariantCulture);
        var diferencial = request.Diferencial;

        try
        {
            await using var pdfStream = request.Pdf.OpenReadStream();
            using var mail = new MailMessage
            {
                From = new MailAddress(emisor, string.IsNullOrWhiteSpace(_emailSettings.DisplayName) ? null : _emailSettings.DisplayName.Trim()),
                Subject = $"DXN CIERRE DE CAJA GENERAL DEL DIA {fechaTexto}",
                Body = ConstruirCuerpoCierreCaja(nombreCompania, nombreResponsable, fecha, "Caja", request.CajaId, diferencial),
                IsBodyHtml = true
            };

            foreach (var correo in correos)
                mail.To.Add(correo);

            mail.Attachments.Add(new Attachment(pdfStream, request.Pdf.FileName, "application/pdf"));

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

            return Ok(new { ok = true, mensaje = "Correo de cierre de caja enviado correctamente.", para = correos });
        }
        catch (SmtpException ex)
        {
            return StatusCode((int)HttpStatusCode.InternalServerError, new { ok = false, mensaje = "No se pudo enviar el correo por SMTP.", detalle = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode((int)HttpStatusCode.InternalServerError, new { ok = false, mensaje = "No se pudo enviar el correo de cierre de caja.", detalle = ex.Message });
        }
    }

    [Authorize]
    [HttpPost("enviar-informe-caja-final", Name = "EnviarCorreoInformeCajaFinal")]
    [RequestSizeLimit(25 * 1024 * 1024)]
    public async Task<IActionResult> EnviarInformeCajaFinal([FromForm] EnviarInformeCajaFinalRequest request, [FromServices] IConfiguration configuration, CancellationToken cancellationToken)
    {
        if (request.ConteoId <= 0 || request.Pdf is null || request.Pdf.Length <= 0 || request.Pdf.Length > MaxArchivoBytes || !string.Equals(Path.GetExtension(request.Pdf.FileName), ".pdf", StringComparison.OrdinalIgnoreCase)) return BadRequest(new { ok = false, mensaje = "Debe adjuntar un PDF válido de hasta 10 MB." });
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString)) return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });
        string destinatarios = string.Empty, compania = "SGO", responsable = "Equipo de caja";
        await using (var connection = new SqlConnection(connectionString))
        await using (var command = new SqlCommand("""
            SELECT compania.CorreosAdmin,
                   COALESCE(NULLIF(LTRIM(RTRIM(compania.CompaniaComercial)), ''), NULLIF(LTRIM(RTRIM(compania.CompaniaRazonSocial)), ''), 'SGO'),
                   COALESCE(NULLIF(LTRIM(RTRIM(CONCAT(SUBSTRING(ISNULL(personal.PersonalNombres, ''), 1, CHARINDEX(' ', ISNULL(personal.PersonalNombres, '') + ' ') - 1), ' ', SUBSTRING(ISNULL(personal.PersonalApellidos, ''), 1, CHARINDEX(' ', ISNULL(personal.PersonalApellidos, '') + ' ') - 1)))), ''), 'Equipo de caja')
              FROM ConteoMonedas conteo
              INNER JOIN Usuarios usuario ON usuario.UsuarioID = conteo.UsuarioId
              INNER JOIN Personal personal ON personal.PersonalId = usuario.PersonalId
              INNER JOIN Compania compania ON compania.CompaniaId = personal.CompaniaId
             WHERE conteo.ConteoId = @ConteoId
            """, connection))
        {
            command.Parameters.AddWithValue("@ConteoId", request.ConteoId); await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (await reader.ReadAsync(cancellationToken)) { destinatarios = reader.GetValue(0)?.ToString()?.Trim() ?? string.Empty; compania = reader.GetValue(1)?.ToString()?.Trim() ?? compania; responsable = reader.GetValue(2)?.ToString()?.Trim() ?? responsable; }
        }
        var correos = SepararCorreos(destinatarios);
        if (correos.Count == 0 || correos.Any(correo => !MailAddress.TryCreate(correo, out _))) return BadRequest(new { ok = false, mensaje = "La compañía no tiene correos administrativos válidos configurados." });
        var emisor = (_emailSettings.Email ?? string.Empty).Trim(); var clave = (_emailSettings.Key ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(emisor) || string.IsNullOrWhiteSpace(clave)) return StatusCode(500, new { ok = false, mensaje = "No está configurado el correo de envío." });
        try
        {
            var fecha = request.FechaReporte?.Date ?? DateTime.Today;
            await using var pdfStream = request.Pdf.OpenReadStream();
            using var mail = new MailMessage { From = new MailAddress(emisor, string.IsNullOrWhiteSpace(_emailSettings.DisplayName) ? null : _emailSettings.DisplayName.Trim()), Subject = $"DXN INFORME FINAL DE CAJA DEL DIA {fecha:dd-MM-yyyy}", Body = ConstruirCuerpoCierreCaja(compania, responsable, fecha, "Informe final", request.ConteoId, request.Diferencial), IsBodyHtml = true };
            foreach (var correo in correos) mail.To.Add(correo);
            mail.Attachments.Add(new Attachment(pdfStream, request.Pdf.FileName, "application/pdf"));
            using var smtp = new SmtpClient { Host = string.IsNullOrWhiteSpace(_emailSettings.Host) ? "smtp.gmail.com" : _emailSettings.Host.Trim(), Port = _emailSettings.Port.GetValueOrDefault(587), EnableSsl = _emailSettings.EnableSsl ?? true, DeliveryMethod = SmtpDeliveryMethod.Network, UseDefaultCredentials = false, Credentials = new NetworkCredential(emisor, clave) };
            await smtp.SendMailAsync(mail, cancellationToken);
            return Ok(new { ok = true, mensaje = "Correo del informe final enviado correctamente.", para = correos });
        }
        catch (Exception ex) { return StatusCode(500, new { ok = false, mensaje = "No se pudo enviar el correo del informe final.", detalle = ex.Message }); }
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

    private static string ConstruirCuerpoComprobante(EnviarCorreoComprobanteRequest request)
    {
        var compania = WebUtility.HtmlEncode(string.IsNullOrWhiteSpace(request.NombreCompania)
            ? "Comprobante electrónico"
            : request.NombreCompania.Trim());
        var tipoComprobante = WebUtility.HtmlEncode(string.IsNullOrWhiteSpace(request.TipoComprobante)
            ? "Comprobante electrónico"
            : request.TipoComprobante.Trim());
        var esBoleta = request.TipoComprobante?.Contains("boleta", StringComparison.OrdinalIgnoreCase) == true;
        var mensajeAdjunto = esBoleta
            ? $"Se adjunta su <strong>{tipoComprobante}</strong>, aceptada por SUNAT."
            : $"Se adjunta su <strong>{tipoComprobante}</strong>, aceptada por SUNAT, en formato PDF, XML y CDR.";
        var numero = WebUtility.HtmlEncode(request.NroComprobante?.Trim() ?? string.Empty);
        var titulo = string.IsNullOrWhiteSpace(numero) ? tipoComprobante : $"{tipoComprobante} · {numero}";

        return $"""
            <!doctype html>
            <html lang="es">
            <body style="margin:0;padding:0;background:#f4f7fb;font-family:Arial,Helvetica,sans-serif;color:#1f2937;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="padding:32px 16px;background:#f4f7fb;">
                <tr><td align="center">
                  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:600px;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 6px 24px rgba(15,23,42,.10);">
                    <tr><td style="padding:26px 32px;background:#9f3028;color:#ffffff;text-align:center;">
                      <div style="font-size:20px;font-weight:700;letter-spacing:.2px;">{compania}</div>
                      <div style="margin-top:7px;font-size:13px;opacity:.9;">Documento electrónico</div>
                    </td></tr>
                    <tr><td style="padding:34px 32px 26px;">
                      <div style="font-size:20px;font-weight:700;color:#172033;">{titulo}</div>
                      <div style="width:44px;height:3px;margin:16px 0 22px;background:#9f3028;border-radius:2px;"></div>
                      <p style="margin:0 0 16px;font-size:15px;line-height:1.6;">Buen día,</p>
                      <p style="margin:0;font-size:15px;line-height:1.65;">{mensajeAdjunto}</p>
                      <table role="presentation" cellspacing="0" cellpadding="0" style="margin-top:24px;width:100%;background:#eef8f0;border-radius:10px;">
                        <tr><td style="padding:14px 16px;color:#24713a;font-size:14px;font-weight:700;">✓ Comprobante aceptado por SUNAT</td></tr>
                      </table>
                      <p style="margin:26px 0 0;font-size:15px;line-height:1.6;">Saludos cordiales,<br><strong>{compania}</strong></p>
                    </td></tr>
                    <tr><td style="padding:18px 32px;background:#f8fafc;color:#6b7280;text-align:center;font-size:12px;line-height:1.5;">Este es un mensaje automático. Por favor, no responda a este correo.</td></tr>
                  </table>
                </td></tr>
              </table>
            </body>
            </html>
            """;
    }
    private static string ConstruirCuerpoCierreCaja(
        string? nombreCompania,
        string? nombreResponsable,
        DateTime fecha,
        string etiquetaRegistro,
        long cajaId,
        decimal diferencial)
    {
        var compania = WebUtility.HtmlEncode(string.IsNullOrWhiteSpace(nombreCompania)
            ? "SGO"
            : nombreCompania.Trim());
        var responsable = WebUtility.HtmlEncode(string.IsNullOrWhiteSpace(nombreResponsable)
            ? "Equipo de caja"
            : nombreResponsable.Trim());
        var cultura = CultureInfo.GetCultureInfo("es-PE");
        var fechaLarga = fecha.ToString("dddd, dd 'de' MMMM 'de' yyyy", cultura);
        var fechaVisible = WebUtility.HtmlEncode(char.ToUpper(fechaLarga[0], cultura) + fechaLarga[1..]);
        var cajaVisible = WebUtility.HtmlEncode(cajaId.ToString(CultureInfo.InvariantCulture));
        var esCuadre = diferencial == 0m;
        var esSobrante = diferencial > 0m;
        var importe = Math.Abs(diferencial).ToString("N2", cultura);
        var estado = esCuadre ? "Caja cuadrada" : esSobrante ? "Sobrante de efectivo" : "Faltante de efectivo";
        var detalle = esCuadre
            ? "La caja cuadró correctamente."
            : esSobrante
                ? $"Se registró un sobrante de efectivo de S/ {importe}."
                : $"Se registró un faltante de efectivo de S/ {importe}.";
        var colorEstado = esCuadre ? "#16794a" : esSobrante ? "#b45309" : "#b42318";
        var fondoEstado = esCuadre ? "#eaf8ef" : esSobrante ? "#fff7e8" : "#fff0f0";

        return $"""
            <!doctype html>
            <html lang="es">
            <body style="margin:0;padding:0;background:#f4f7fb;font-family:Arial,Helvetica,sans-serif;color:#1f2937;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="padding:32px 16px;background:#f4f7fb;">
                <tr><td align="center">
                  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:600px;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 6px 24px rgba(15,23,42,.10);">
                    <tr><td style="padding:26px 32px;background:#9f3028;color:#ffffff;">
                      <div style="font-size:20px;font-weight:700;letter-spacing:.2px;">{compania}</div>
                      <div style="margin-top:7px;font-size:13px;opacity:.9;">Resumen de cierre de caja</div>
                    </td></tr>
                    <tr><td style="padding:32px 32px 26px;">
                      <div style="font-size:21px;font-weight:700;color:#172033;">Cierre de caja confirmado</div>
                      <div style="width:44px;height:3px;margin:16px 0 22px;background:#b23636;border-radius:2px;"></div>
                      <p style="margin:0 0 16px;font-size:15px;line-height:1.6;">Buen día,</p>
                      <p style="margin:0;font-size:15px;line-height:1.65;">Se ha generado el reporte de cierre de caja. Encontrará el documento PDF adjunto a este correo.</p>
                      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-top:24px;border:1px solid #e5e7eb;border-radius:10px;">
                        <tr>
                          <td style="padding:14px 16px;border-bottom:1px solid #e5e7eb;color:#64748b;font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.4px;">{WebUtility.HtmlEncode(etiquetaRegistro)}</td>
                          <td align="right" style="padding:14px 16px;border-bottom:1px solid #e5e7eb;color:#172033;font-size:14px;font-weight:700;">#{cajaVisible}</td>
                        </tr>
                        <tr>
                          <td style="padding:14px 16px;color:#64748b;font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.4px;">Fecha de cierre</td>
                          <td align="right" style="padding:14px 16px;color:#172033;font-size:14px;font-weight:700;">{fechaVisible}</td>
                        </tr>
                      </table>
                      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-top:16px;background:{fondoEstado};border-radius:10px;">
                        <tr><td style="padding:15px 16px;color:{colorEstado};font-size:14px;font-weight:700;">{estado}</td></tr>
                        <tr><td style="padding:0 16px 15px;color:#334155;font-size:14px;line-height:1.55;">{detalle}</td></tr>
                      </table>
                      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-top:16px;background:#f8fafc;border-radius:10px;">
                        <tr><td style="padding:14px 16px;color:#475569;font-size:13px;line-height:1.5;">Archivo adjunto: <strong>Reporte de cierre de caja en formato PDF.</strong></td></tr>
                      </table>
                      <p style="margin:26px 0 0;font-size:15px;line-height:1.6;">Saludos cordiales,<br><strong>{responsable}</strong></p>
                    </td></tr>
                    <tr><td style="padding:18px 32px;background:#f8fafc;color:#6b7280;text-align:center;font-size:12px;line-height:1.5;">Este es un mensaje automático. Por favor, no responda a este correo.</td></tr>
                  </table>
                </td></tr>
              </table>
            </body>
            </html>
            """;
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
    public string? NombreCompania { get; set; }
    public string? TipoComprobante { get; set; }
    public IFormFile? Pdf { get; set; }
    public IFormFile? Xml { get; set; }
    public IFormFile? Cdr { get; set; }
    public List<IFormFile>? Archivos { get; set; }
}

public sealed class EnviarCierreCajaRequest
{
    public long CajaId { get; set; }
    public DateTime? FechaReporte { get; set; }
    public decimal Diferencial { get; set; }
    public IFormFile? Pdf { get; set; }
}

public sealed class EnviarInformeCajaFinalRequest
{
    public long ConteoId { get; set; }
    public DateTime? FechaReporte { get; set; }
    public decimal Diferencial { get; set; }
    public IFormFile? Pdf { get; set; }
}
