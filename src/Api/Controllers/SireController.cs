using System.Net;
using System.Globalization;
using System.Security.Claims;
using System.Text.Json;
using Ecommerce.Api.Interfaces;
using Ecommerce.Api.Models;
using Ecommerce.Api.Services;
using Ecommerce.Api.Security;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/sunat/sire")]
[RequirePermission("CONTABILIDAD.VER")]
public class SireController : ControllerBase
{
    private readonly ISireService _sireService;
    private readonly ISunatComprobanteService _sunatComprobanteService;
    private readonly ILogger<SireController> _logger;
    private readonly IConfiguration _configuration;

    public SireController(
        ISireService sireService,
        ISunatComprobanteService sunatComprobanteService,
        ILogger<SireController> logger,
        IConfiguration configuration)
    {
        _sireService = sireService;
        _sunatComprobanteService = sunatComprobanteService;
        _logger = logger;
        _configuration = configuration;
    }

    [HttpGet("compras", Name = "GetSireCompras")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> ObtenerCompras([FromQuery] string periodo)
    {
        if (!EsPeriodo(periodo))
        {
            return BadRequest(new { message = "El parametro periodo es requerido. Ejemplo: 202606." });
        }

        try
        {
            var result = await _sireService.ObtenerComprasAsync(periodo);
            return Content(result, "application/json");
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Configuracion SIRE compras incompleta.");
            return BadRequest(new { message = ex.Message });
        }
        catch (SunatApiException ex)
        {
            _logger.LogError(ex, "SUNAT SIRE devolvio error en compras. Url: {Url}. Body: {Body}", ex.RequestUrl, ex.ResponseBody);
            return StatusCode((int)ex.StatusCode, new
            {
                message = "SUNAT SIRE devolvio error en compras.",
                statusCode = (int)ex.StatusCode,
                requestUrl = ex.RequestUrl,
                sunatResponse = ex.ResponseBody
            });
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "No se pudo consultar compras SIRE.");
            return StatusCode((int)HttpStatusCode.BadGateway, new
            {
                message = "No se pudo consultar compras en SIRE.",
                detail = ex.Message
            });
        }
    }

    [HttpGet("ventas/comparar", Name = "CompareSireVentasConBd")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> CompararVentasConBd(
        [FromQuery] string periodo,
        [FromQuery] string? serie = null,
        [FromQuery] string? tipoCodigo = null,
        [FromQuery] int? companiaId = null,
        [FromQuery] string? fecDocumentoDesde = null,
        [FromQuery] string? fecDocumentoHasta = null,
        [FromQuery] int maxIntentos = 10,
        [FromQuery] int segundosEspera = 3)
    {
        maxIntentos = Math.Clamp(maxIntentos, 1, 20);
        segundosEspera = Math.Clamp(segundosEspera, 1, 10);
        if (!EsPeriodo(periodo))
        {
            return BadRequest(new { message = "El parametro periodo es requerido. Ejemplo: 202606." });
        }

        var companiaClaim = User.FindFirstValue("companiaId");
        if (!int.TryParse(companiaClaim, out var companiaAutenticada))
        {
            return Unauthorized(new { message = "El token no contiene una compañía válida." });
        }
        companiaId = companiaAutenticada;

        try
        {
            var bd = await ObtenerDocumentosBdAsync(periodo, serie, tipoCodigo, companiaId, fecDocumentoDesde, fecDocumentoHasta);
            var sireResult = await _sireService.ObtenerRegistrosVentasAsync(
                periodo,
                maxIntentos,
                segundosEspera,
                fecDocumentoDesde,
                fecDocumentoHasta,
                codTipoCDP: tipoCodigo);

            var sire = ExtraerDocumentosSire(sireResult, serie, tipoCodigo);
            var bdPorClave = bd
                .GroupBy(x => x.Clave)
                .ToDictionary(x => x.Key, x => x.First(), StringComparer.OrdinalIgnoreCase);
            var sirePorClave = sire
                .GroupBy(x => x.Clave)
                .ToDictionary(x => x.Key, x => x.First(), StringComparer.OrdinalIgnoreCase);

            var soloEnBd = bdPorClave
                .Where(x => !sirePorClave.ContainsKey(x.Key))
                .Select(x => x.Value)
                .OrderBy(x => x.Serie)
                .ThenBy(x => x.NumeroValor)
                .ToArray();

            var soloEnSire = sirePorClave
                .Where(x => !bdPorClave.ContainsKey(x.Key))
                .Select(x => x.Value)
                .OrderBy(x => x.Serie)
                .ThenBy(x => x.NumeroValor)
                .ToArray();

            var totalEnAmbos = bdPorClave.Keys.Count(sirePorClave.ContainsKey);

            return Ok(new
            {
                periodo,
                serie = string.IsNullOrWhiteSpace(serie) ? null : serie.Trim().ToUpperInvariant(),
                tipoCodigo = string.IsNullOrWhiteSpace(tipoCodigo) ? null : tipoCodigo.Trim(),
                filtros = new { fecDocumentoDesde, fecDocumentoHasta, companiaId },
                resumen = new
                {
                    totalBd = bdPorClave.Count,
                    totalSire = sirePorClave.Count,
                    totalEnAmbos,
                    totalSoloEnBd = soloEnBd.Length,
                    totalSoloEnSire = soloEnSire.Length
                },
                soloEnBd,
                soloEnSire
            });
        }
        catch (SunatApiException ex)
        {
            _logger.LogError(ex, "SUNAT SIRE devolvio error al comparar ventas. Url: {Url}. Body: {Body}", ex.RequestUrl, ex.ResponseBody);
            return StatusCode((int)ex.StatusCode, new
            {
                message = "SUNAT SIRE devolvio error al comparar ventas.",
                statusCode = (int)ex.StatusCode,
                requestUrl = ex.RequestUrl,
                sunatResponse = ex.ResponseBody
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "No se pudo comparar ventas BD vs SIRE.");
            return StatusCode((int)HttpStatusCode.InternalServerError, new
            {
                message = "No se pudo comparar ventas BD vs SIRE.",
                detail = ex.Message
            });
        }
    }

    [HttpPost("ventas/validar-sunat", Name = "ValidateSireVentasEnSunat")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> ValidarVentasEnSunat([FromBody] JsonElement request, CancellationToken cancellationToken)
    {
        try
        {
            var documentos = ExtraerDocumentosParaValidar(request);
            if (documentos.Count == 0)
            {
                return BadRequest(new
                {
                    message = "No se encontraron documentos para validar. Envia un array o una propiedad documentos/soloEnBd/soloEnSire."
                });
            }
            if (documentos.Count > 100)
                return BadRequest(new { message = "Valida como máximo 100 comprobantes por solicitud." });

            var results = await _sunatComprobanteService.ValidarAsync(documentos, cancellationToken);
            return Ok(new
            {
                resumen = new
                {
                    total = results.Count,
                    consultados = results.Count(x => x.Consultado),
                    existenEnSunat = results.Count(x => x.ExisteEnSunat),
                    noExistenEnSunat = results.Count(x => x.Codigo == "0"),
                    conError = results.Count(x => !string.IsNullOrWhiteSpace(x.Error) || !x.Consultado)
                },
                resultados = results
            });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Falta configuración para validar comprobantes SUNAT.");
            return BadRequest(new { message = ex.Message });
        }
        catch (SunatApiException ex)
        {
            _logger.LogError(ex, "SUNAT devolvio error al validar comprobantes. Url: {Url}. Body: {Body}", ex.RequestUrl, ex.ResponseBody);
            return StatusCode((int)ex.StatusCode, new
            {
                message = "SUNAT devolvio error al validar comprobantes.",
                statusCode = (int)ex.StatusCode,
                requestUrl = ex.RequestUrl,
                sunatResponse = ex.ResponseBody
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "No se pudo validar comprobantes en SUNAT.");
            return StatusCode((int)HttpStatusCode.InternalServerError, new
            {
                message = "No se pudo validar comprobantes en SUNAT.",
                detail = ex.Message
            });
        }
    }

    [HttpGet("ventas", Name = "GetSireVentas")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> ObtenerVentas([FromQuery] string periodo)
    {
        if (!EsPeriodo(periodo))
        {
            return BadRequest(new { message = "El parametro periodo es requerido. Ejemplo: 202606." });
        }

        try
        {
            var result = await _sireService.ObtenerVentasAsync(periodo);
            return Content(result, "application/json");
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Configuracion SIRE ventas incompleta.");
            return BadRequest(new { message = ex.Message });
        }
        catch (SunatApiException ex)
        {
            _logger.LogError(ex, "SUNAT SIRE devolvio error en ventas. Url: {Url}. Body: {Body}", ex.RequestUrl, ex.ResponseBody);
            return StatusCode((int)ex.StatusCode, new
            {
                message = "SUNAT SIRE devolvio error en ventas.",
                statusCode = (int)ex.StatusCode,
                requestUrl = ex.RequestUrl,
                sunatResponse = ex.ResponseBody
            });
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "No se pudo consultar ventas SIRE.");
            return StatusCode((int)HttpStatusCode.BadGateway, new
            {
                message = "No se pudo consultar ventas en SIRE.",
                detail = ex.Message
            });
        }
    }

    [HttpGet("ventas/registros", Name = "GetSireVentasRegistros")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> ObtenerRegistrosVentas(
        [FromQuery] string periodo,
        [FromQuery] int maxIntentos = 10,
        [FromQuery] int segundosEspera = 3,
        [FromQuery] string? fecDocumentoDesde = null,
        [FromQuery] string? fecDocumentoHasta = null,
        [FromQuery] string? mtoTotalDesde = null,
        [FromQuery] string? mtoTotalHasta = null,
        [FromQuery] string? numRucAdquiriente = null,
        [FromQuery] string? numCarSunat = null,
        [FromQuery] string? codTipoCDP = null,
        [FromQuery] string? codTipoInconsistencia = null)
    {
        maxIntentos = Math.Clamp(maxIntentos, 1, 20);
        segundosEspera = Math.Clamp(segundosEspera, 1, 10);
        if (!EsPeriodo(periodo))
        {
            return BadRequest(new { message = "El parametro periodo es requerido. Ejemplo: 202606." });
        }

        try
        {
            var result = await _sireService.ObtenerRegistrosVentasAsync(
                periodo,
                maxIntentos,
                segundosEspera,
                fecDocumentoDesde,
                fecDocumentoHasta,
                mtoTotalDesde,
                mtoTotalHasta,
                numRucAdquiriente,
                numCarSunat,
                codTipoCDP,
                codTipoInconsistencia);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "No se pudieron obtener registros RVIE automaticamente.");
            return BadRequest(new { message = ex.Message });
        }
        catch (SunatApiException ex)
        {
            _logger.LogError(ex, "SUNAT SIRE devolvio error al obtener registros ventas. Url: {Url}. Body: {Body}", ex.RequestUrl, ex.ResponseBody);
            return StatusCode((int)ex.StatusCode, new
            {
                message = "SUNAT SIRE devolvio error al obtener registros ventas.",
                statusCode = (int)ex.StatusCode,
                requestUrl = ex.RequestUrl,
                sunatResponse = ex.ResponseBody
            });
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "No se pudo obtener registros ventas SIRE.");
            return StatusCode((int)HttpStatusCode.BadGateway, new
            {
                message = "No se pudo obtener registros ventas en SIRE.",
                detail = ex.Message
            });
        }
    }

    [HttpGet("ventas/periodos", Name = "GetSireVentasPeriodos")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> ObtenerPeriodosVentas([FromQuery] string codLibro = "140000")
    {
        if (string.IsNullOrWhiteSpace(codLibro))
        {
            return BadRequest(new { message = "El parametro codLibro es requerido. Ejemplo: 140000." });
        }

        try
        {
            var result = await _sireService.ObtenerPeriodosVentasAsync(codLibro);
            return Content(result, "application/json");
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Configuracion SIRE periodos ventas incompleta.");
            return BadRequest(new { message = ex.Message });
        }
        catch (SunatApiException ex)
        {
            _logger.LogError(ex, "SUNAT SIRE devolvio error en periodos ventas. Url: {Url}. Body: {Body}", ex.RequestUrl, ex.ResponseBody);
            return StatusCode((int)ex.StatusCode, new
            {
                message = "SUNAT SIRE devolvio error en periodos ventas.",
                statusCode = (int)ex.StatusCode,
                requestUrl = ex.RequestUrl,
                sunatResponse = ex.ResponseBody
            });
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "No se pudo consultar periodos ventas SIRE.");
            return StatusCode((int)HttpStatusCode.BadGateway, new
            {
                message = "No se pudo consultar periodos ventas en SIRE.",
                detail = ex.Message
            });
        }
    }

    [HttpGet("ventas/ticket", Name = "GetSireVentasTicket")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> ConsultarTicketVentas(
        [FromQuery] string perIni,
        [FromQuery] string perFin,
        [FromQuery] string numTicket,
        [FromQuery] int page = 1,
        [FromQuery] int perPage = 20)
    {
        page = Math.Max(1, page);
        perPage = Math.Clamp(perPage, 1, 100);
        if (string.IsNullOrWhiteSpace(perIni) || string.IsNullOrWhiteSpace(perFin) || string.IsNullOrWhiteSpace(numTicket))
        {
            return BadRequest(new { message = "Los parametros perIni, perFin y numTicket son requeridos. Ejemplo: perIni=202606&perFin=202606&numTicket=2026..." });
        }

        try
        {
            var result = await _sireService.ConsultarTicketVentasAsync(perIni, perFin, numTicket, page, perPage);
            return Content(result, "application/json");
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Configuracion SIRE ticket ventas incompleta.");
            return BadRequest(new { message = ex.Message });
        }
        catch (SunatApiException ex)
        {
            _logger.LogError(ex, "SUNAT SIRE devolvio error al consultar ticket ventas. Url: {Url}. Body: {Body}", ex.RequestUrl, ex.ResponseBody);
            return StatusCode((int)ex.StatusCode, new
            {
                message = "SUNAT SIRE devolvio error al consultar ticket ventas.",
                statusCode = (int)ex.StatusCode,
                requestUrl = ex.RequestUrl,
                sunatResponse = ex.ResponseBody
            });
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "No se pudo consultar ticket ventas SIRE.");
            return StatusCode((int)HttpStatusCode.BadGateway, new
            {
                message = "No se pudo consultar ticket ventas en SIRE.",
                detail = ex.Message
            });
        }
    }

    [HttpGet("ventas/archivo", Name = "GetSireVentasArchivo")]
    [ProducesResponseType((int)HttpStatusCode.OK)]
    public async Task<IActionResult> DescargarArchivoVentas(
        [FromQuery] string nomArchivoReporte,
        [FromQuery] string codTipoArchivoReporte = "01",
        [FromQuery] string codLibro = "140000",
        [FromQuery] string? perTributario = null,
        [FromQuery] string? codProceso = null,
        [FromQuery] string? numTicket = null)
    {
        if (string.IsNullOrWhiteSpace(nomArchivoReporte))
        {
            return BadRequest(new { message = "El parametro nomArchivoReporte es requerido. Debe venir desde la consulta del ticket." });
        }

        try
        {
            var bytes = await _sireService.DescargarArchivoVentasAsync(
                nomArchivoReporte,
                codTipoArchivoReporte,
                codLibro,
                perTributario,
                codProceso,
                numTicket);
            var fileName = Path.GetFileName(nomArchivoReporte);
            return File(bytes, "application/octet-stream", string.IsNullOrWhiteSpace(fileName) ? "sire-rvie.zip" : fileName);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Configuracion SIRE archivo ventas incompleta.");
            return BadRequest(new { message = ex.Message });
        }
        catch (SunatApiException ex)
        {
            _logger.LogError(ex, "SUNAT SIRE devolvio error al descargar archivo ventas. Url: {Url}. Body: {Body}", ex.RequestUrl, ex.ResponseBody);
            return StatusCode((int)ex.StatusCode, new
            {
                message = "SUNAT SIRE devolvio error al descargar archivo ventas.",
                statusCode = (int)ex.StatusCode,
                requestUrl = ex.RequestUrl,
                sunatResponse = ex.ResponseBody
            });
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "No se pudo descargar archivo ventas SIRE.");
            return StatusCode((int)HttpStatusCode.BadGateway, new
            {
                message = "No se pudo descargar archivo ventas en SIRE.",
                detail = ex.Message
            });
        }
    }

    private async Task<List<DocumentoComparacion>> ObtenerDocumentosBdAsync(
        string periodo,
        string? serie,
        string? tipoCodigo,
        int? companiaId,
        string? fecDocumentoDesde,
        string? fecDocumentoHasta)
    {
        var connectionString = _configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Missing connection string: DefaultConnection");

        var (desde, hasta) = ResolverRangoFechas(periodo, fecDocumentoDesde, fecDocumentoHasta);
        var documentos = new List<DocumentoComparacion>();

        const string sql = @"
SELECT
    DocuId,
    CompaniaId,
    DocuDocumento,
    LTRIM(RTRIM(TipoCodigo)) AS TipoCodigo,
    LTRIM(RTRIM(DocuSerie)) AS Serie,
    LTRIM(RTRIM(DocuNumero)) AS Numero,
    DocuEmision,
    DocuTotal,
    EstadoSunat
FROM DocumentoVenta
WHERE DocuEmision >= @Desde
  AND DocuEmision <= @Hasta
  AND (@Serie = '' OR LTRIM(RTRIM(DocuSerie)) = @Serie)
  AND (@TipoCodigo = '' OR LTRIM(RTRIM(TipoCodigo)) = @TipoCodigo)
  AND (@CompaniaId IS NULL OR CompaniaId = @CompaniaId);";

        await using var con = new SqlConnection(connectionString);
        await con.OpenAsync();

        await using var cmd = new SqlCommand(sql, con);
        cmd.Parameters.AddWithValue("@Desde", desde);
        cmd.Parameters.AddWithValue("@Hasta", hasta);
        cmd.Parameters.AddWithValue("@Serie", (serie ?? string.Empty).Trim().ToUpperInvariant());
        cmd.Parameters.AddWithValue("@TipoCodigo", (tipoCodigo ?? string.Empty).Trim());
        cmd.Parameters.AddWithValue("@CompaniaId", companiaId.HasValue ? companiaId.Value : DBNull.Value);

        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var docSerie = reader["Serie"]?.ToString() ?? string.Empty;
            var docNumero = reader["Numero"]?.ToString() ?? string.Empty;
            var normalizado = NormalizarNumero(docNumero);
            if (string.IsNullOrWhiteSpace(docSerie) || string.IsNullOrWhiteSpace(normalizado))
            {
                continue;
            }

            documentos.Add(new DocumentoComparacion
            {
                Origen = "BD",
                Serie = docSerie.Trim().ToUpperInvariant(),
                Numero = docNumero.Trim(),
                NumeroNormalizado = normalizado,
                NumeroValor = ParseNumero(normalizado),
                Clave = CrearClave(docSerie, normalizado),
                Fecha = reader["DocuEmision"] == DBNull.Value ? null : Convert.ToDateTime(reader["DocuEmision"]).ToString("yyyy-MM-dd"),
                TipoDocumento = reader["TipoCodigo"]?.ToString()?.Trim(),
                Monto = reader["DocuTotal"] == DBNull.Value ? null : Convert.ToDecimal(reader["DocuTotal"]).ToString(CultureInfo.InvariantCulture),
                Estado = reader["EstadoSunat"]?.ToString()?.Trim()
            });
        }

        return documentos;
    }

    private static List<DocumentoComparacion> ExtraerDocumentosSire(object sireResult, string? serieFiltro, string? tipoCodigoFiltro)
    {
        var documentos = new List<DocumentoComparacion>();
        var serieEsperada = (serieFiltro ?? string.Empty).Trim().ToUpperInvariant();
        var tipoEsperado = (tipoCodigoFiltro ?? string.Empty).Trim();
        var json = JsonSerializer.Serialize(sireResult);
        using var document = JsonDocument.Parse(json);

        if (!document.RootElement.TryGetProperty("archivo", out var archivo)
            || !archivo.TryGetProperty("registros", out var registros)
            || registros.ValueKind != JsonValueKind.Array)
        {
            return documentos;
        }

        foreach (var registro in registros.EnumerateArray())
        {
            if (registro.ValueKind != JsonValueKind.Object)
            {
                continue;
            }

            var campos = registro.EnumerateObject()
                .OrderBy(x => x.Name, StringComparer.OrdinalIgnoreCase)
                .Select(x => x.Value.ValueKind == JsonValueKind.String ? x.Value.GetString() ?? string.Empty : x.Value.ToString())
                .ToArray();

            var doc = ExtraerDocumentoSireDesdeCampos(campos, serieEsperada, tipoEsperado);
            if (doc is not null)
            {
                documentos.Add(doc);
            }
        }

        return documentos;
    }

    private static DocumentoComparacion? ExtraerDocumentoSireDesdeCampos(string[] campos, string serieEsperada, string tipoEsperado)
    {
        var tipoDocumento = BuscarTipoDocumento(campos);
        if (!string.IsNullOrWhiteSpace(tipoEsperado)
            && !string.Equals(tipoDocumento, tipoEsperado, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        for (var i = 0; i < campos.Length - 1; i++)
        {
            var serie = (campos[i] ?? string.Empty).Trim().ToUpperInvariant();
            if (!EsSerieCdp(serie))
            {
                continue;
            }

            if (!string.IsNullOrWhiteSpace(serieEsperada) && serie != serieEsperada)
            {
                continue;
            }

            var numero = BuscarNumeroPosterior(campos, i + 1);
            var normalizado = NormalizarNumero(numero);
            if (string.IsNullOrWhiteSpace(normalizado))
            {
                continue;
            }

            return new DocumentoComparacion
            {
                Origen = "SIRE",
                Serie = serie,
                Numero = numero,
                NumeroNormalizado = normalizado,
                NumeroValor = ParseNumero(normalizado),
                Clave = CrearClave(serie, normalizado),
                Fecha = BuscarFecha(campos),
                TipoDocumento = tipoDocumento,
                Raw = campos
            };
        }

        return null;
    }

    private static (DateTime Desde, DateTime Hasta) ResolverRangoFechas(string periodo, string? desdeTexto, string? hastaTexto)
    {
        if (DateTime.TryParseExact(desdeTexto, "dd/MM/yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out var desde)
            && DateTime.TryParseExact(hastaTexto, "dd/MM/yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out var hasta))
        {
            return (desde.Date, hasta.Date);
        }

        if (periodo.Length != 6
            || !int.TryParse(periodo[..4], out var year)
            || !int.TryParse(periodo[4..], out var month))
        {
            throw new ArgumentException("El periodo debe tener formato yyyyMM. Ejemplo: 202606.");
        }

        var inicio = new DateTime(year, month, 1);
        return (inicio, inicio.AddMonths(1).AddDays(-1));
    }

    private static string BuscarNumeroPosterior(string[] campos, int startIndex)
    {
        for (var i = startIndex; i < Math.Min(campos.Length, startIndex + 4); i++)
        {
            var valor = (campos[i] ?? string.Empty).Trim();
            if (EsNumeroDocumento(valor))
            {
                return valor;
            }
        }

        return string.Empty;
    }

    private static string? BuscarFecha(string[] campos)
    {
        return campos.FirstOrDefault(x =>
            DateTime.TryParseExact((x ?? string.Empty).Trim(), "dd/MM/yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out _));
    }

    private static string? BuscarTipoDocumento(string[] campos)
    {
        return campos.FirstOrDefault(x =>
        {
            var valor = (x ?? string.Empty).Trim();
            return valor is "01" or "03" or "07" or "08";
        });
    }

    private static bool EsSerieCdp(string value)
    {
        if (value.Length != 4)
        {
            return false;
        }

        return char.IsLetter(value[0]) && value.Skip(1).All(char.IsLetterOrDigit);
    }

    private static bool EsNumeroDocumento(string value)
    {
        var numero = NormalizarNumero(value);
        return !string.IsNullOrWhiteSpace(numero) && numero.Length <= 12;
    }

    private static string NormalizarNumero(string? value)
    {
        var digits = new string((value ?? string.Empty).Where(char.IsDigit).ToArray());
        if (string.IsNullOrWhiteSpace(digits))
        {
            return string.Empty;
        }

        var normalized = digits.TrimStart('0');
        return string.IsNullOrWhiteSpace(normalized) ? "0" : normalized;
    }

    private static long ParseNumero(string value)
    {
        return long.TryParse(value, out var parsed) ? parsed : 0;
    }

    private static string CrearClave(string serie, string numeroNormalizado)
    {
        return $"{serie.Trim().ToUpperInvariant()}-{numeroNormalizado}";
    }

    private static List<ValidarComprobanteSunatItem> ExtraerDocumentosParaValidar(JsonElement root)
    {
        var array = ResolverArrayDocumentos(root);
        var documentos = new List<ValidarComprobanteSunatItem>();
        if (array is null)
        {
            return documentos;
        }

        foreach (var item in array.Value.EnumerateArray())
        {
            if (item.ValueKind != JsonValueKind.Object)
            {
                continue;
            }

            documentos.Add(new ValidarComprobanteSunatItem
            {
                Ruc = GetJsonString(item, "ruc", "numRuc"),
                TipoDocumento = GetJsonString(item, "tipoDocumento", "tipoCodigo", "codComp", "tipoDocumentoSunat"),
                Serie = GetJsonString(item, "serie", "docuSerie", "numeroSerie"),
                Numero = GetJsonString(item, "numero", "docuNumero", "numeroNormalizado", "nroComprobante"),
                FechaEmision = GetJsonString(item, "fechaEmision", "fecha", "docuEmision"),
                Monto = GetJsonDecimal(item, "monto", "docuTotal", "total"),
                Original = JsonSerializer.Deserialize<object>(item.GetRawText())
            });
        }

        return documentos;
    }

    private static JsonElement? ResolverArrayDocumentos(JsonElement root)
    {
        if (root.ValueKind == JsonValueKind.Array)
        {
            return root;
        }

        if (root.ValueKind != JsonValueKind.Object)
        {
            return null;
        }

        foreach (var name in new[] { "documentos", "soloEnBd", "soloEnSire", "faltantes", "resultados" })
        {
            if (TryGetPropertyIgnoreCase(root, name, out var value) && value.ValueKind == JsonValueKind.Array)
            {
                return value;
            }
        }

        return null;
    }

    private static string? GetJsonString(JsonElement element, params string[] names)
    {
        foreach (var name in names)
        {
            if (!TryGetPropertyIgnoreCase(element, name, out var value))
            {
                continue;
            }

            if (value.ValueKind == JsonValueKind.String)
            {
                return value.GetString()?.Trim();
            }

            if (value.ValueKind == JsonValueKind.Number)
            {
                return value.ToString();
            }
        }

        return null;
    }

    private static decimal? GetJsonDecimal(JsonElement element, params string[] names)
    {
        foreach (var name in names)
        {
            if (!TryGetPropertyIgnoreCase(element, name, out var value))
            {
                continue;
            }

            if (value.ValueKind == JsonValueKind.Number && value.TryGetDecimal(out var number))
            {
                return number;
            }

            if (value.ValueKind == JsonValueKind.String
                && decimal.TryParse(value.GetString(), NumberStyles.Any, CultureInfo.InvariantCulture, out var parsed))
            {
                return parsed;
            }
        }

        return null;
    }

    private static bool TryGetPropertyIgnoreCase(JsonElement element, string name, out JsonElement value)
    {
        foreach (var property in element.EnumerateObject())
        {
            if (property.Name.Equals(name, StringComparison.OrdinalIgnoreCase))
            {
                value = property.Value;
                return true;
            }
        }

        value = default;
        return false;
    }

    private static bool EsPeriodo(string periodo) =>
        DateTime.TryParseExact(periodo, "yyyyMM", CultureInfo.InvariantCulture, DateTimeStyles.None, out _);

    private sealed class DocumentoComparacion
    {
        public string Origen { get; set; } = string.Empty;
        public string Serie { get; set; } = string.Empty;
        public string Numero { get; set; } = string.Empty;
        public string NumeroNormalizado { get; set; } = string.Empty;
        public long NumeroValor { get; set; }
        public string Clave { get; set; } = string.Empty;
        public string? Fecha { get; set; }
        public string? TipoDocumento { get; set; }
        public string? Monto { get; set; }
        public string? Estado { get; set; }
        public string[]? Raw { get; set; }
    }
}
