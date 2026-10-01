using System.Net.Http.Headers;
using System.IO.Compression;
using System.Text;
using System.Text.Json;
using Ecommerce.Api.Interfaces;
using Ecommerce.Api.Options;
using Microsoft.Extensions.Options;

namespace Ecommerce.Api.Services;

public class SireService : ISireService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ISunatAuthService _sunatAuthService;
    private readonly ILogger<SireService> _logger;
    private readonly SunatOptions _options;

    public SireService(
        IHttpClientFactory httpClientFactory,
        ISunatAuthService sunatAuthService,
        IOptions<SunatOptions> options,
        ILogger<SireService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _sunatAuthService = sunatAuthService;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<string> GetAsync(string endpoint)
    {
        using var request = await CreateRequestAsync(HttpMethod.Get, endpoint);
        using var response = await SendAsync(request);
        return await response.Content.ReadAsStringAsync();
    }

    public async Task<string> PostAsync(string endpoint, object body)
    {
        using var request = await CreateRequestAsync(HttpMethod.Post, endpoint);
        request.Content = new StringContent(JsonSerializer.Serialize(body, JsonOptions), Encoding.UTF8, "application/json");

        using var response = await SendAsync(request);
        return await response.Content.ReadAsStringAsync();
    }

    public async Task<byte[]> GetBytesAsync(string endpoint)
    {
        using var request = await CreateRequestAsync(HttpMethod.Get, endpoint);
        using var response = await SendAsync(request);
        return await response.Content.ReadAsByteArrayAsync();
    }

    public Task<string> ObtenerComprasAsync(string periodo)
    {
        var endpoint = BuildConfiguredEndpoint(_options.RceComprasEndpoint, periodo, "Sunat:RceComprasEndpoint");
        return GetAsync(endpoint);
    }

    public Task<string> ObtenerVentasAsync(string periodo)
    {
        var endpoint = BuildConfiguredEndpoint(_options.RvieVentasEndpoint, periodo, "Sunat:RvieVentasEndpoint");
        return GetAsync(endpoint);
    }

    private Task<string> ObtenerVentasAsync(
        string periodo,
        string? fecDocumentoDesde,
        string? fecDocumentoHasta,
        string? mtoTotalDesde,
        string? mtoTotalHasta,
        string? numRucAdquiriente,
        string? numCarSunat,
        string? codTipoCDP,
        string? codTipoInconsistencia)
    {
        var endpoint = BuildConfiguredEndpoint(_options.RvieVentasEndpoint, periodo, "Sunat:RvieVentasEndpoint");
        endpoint = SetQueryValue(endpoint, "fecDocumentoDesde", fecDocumentoDesde);
        endpoint = SetQueryValue(endpoint, "fecDocumentoHasta", fecDocumentoHasta);
        endpoint = SetQueryValue(endpoint, "mtoTotalDesde", mtoTotalDesde);
        endpoint = SetQueryValue(endpoint, "mtoTotalHasta", mtoTotalHasta);
        endpoint = SetQueryValue(endpoint, "numRucAdquiriente", numRucAdquiriente);
        endpoint = SetQueryValue(endpoint, "numCarSunat", numCarSunat);
        endpoint = SetQueryValue(endpoint, "codTipoCDP", codTipoCDP);
        endpoint = SetQueryValue(endpoint, "codTipoInconsistencia", codTipoInconsistencia);
        return GetAsync(endpoint);
    }

    public Task<string> ObtenerPeriodosVentasAsync(string codLibro)
    {
        var endpoint = BuildConfiguredEndpoint(_options.RviePeriodosEndpoint, codLibro, "Sunat:RviePeriodosEndpoint", "{codLibro}");
        return GetAsync(endpoint);
    }

    public Task<string> ConsultarTicketVentasAsync(string perIni, string perFin, string numTicket, int page, int perPage)
    {
        var replacements = new Dictionary<string, string>
        {
            ["{perIni}"] = perIni,
            ["{perFin}"] = perFin,
            ["{page}"] = page.ToString(),
            ["{perPage}"] = perPage.ToString(),
            ["{numTicket}"] = numTicket
        };
        var endpoint = BuildConfiguredEndpoint(_options.RvieTicketEndpoint, replacements, "Sunat:RvieTicketEndpoint");
        return GetAsync(endpoint);
    }

    public Task<byte[]> DescargarArchivoVentasAsync(
        string nomArchivoReporte,
        string codTipoArchivoReporte,
        string codLibro,
        string? perTributario = null,
        string? codProceso = null,
        string? numTicket = null)
    {
        var endpoint = BuildArchivoEndpoint(
            _options.RvieArchivoEndpoint,
            nomArchivoReporte,
            codTipoArchivoReporte,
            codLibro,
            perTributario,
            codProceso,
            numTicket);

        return GetBytesAsync(endpoint);
    }

    private static string BuildArchivoEndpoint(
        string endpointTemplate,
        string nomArchivoReporte,
        string codTipoArchivoReporte,
        string codLibro,
        string? perTributario,
        string? codProceso,
        string? numTicket)
    {
        if (string.IsNullOrWhiteSpace(endpointTemplate))
        {
            throw new InvalidOperationException("Falta configurar Sunat:RvieArchivoEndpoint con el endpoint oficial de SUNAT.");
        }

        var required = new Dictionary<string, string>
        {
            ["nomArchivoReporte"] = nomArchivoReporte,
            ["codTipoArchivoReporte"] = codTipoArchivoReporte,
            ["codLibro"] = codLibro
        };

        foreach (var item in required)
        {
            if (string.IsNullOrWhiteSpace(item.Value))
            {
                throw new ArgumentException($"El valor para {item.Key} es requerido.");
            }
        }

        var endpoint = endpointTemplate
            .Replace("{nomArchivoReporte}", Uri.EscapeDataString(nomArchivoReporte), StringComparison.OrdinalIgnoreCase)
            .Replace("{codTipoArchivoReporte}", Uri.EscapeDataString(codTipoArchivoReporte), StringComparison.OrdinalIgnoreCase)
            .Replace("{codLibro}", Uri.EscapeDataString(codLibro), StringComparison.OrdinalIgnoreCase);

        endpoint = ReplaceOptionalQueryParameter(endpoint, "perTributario", "{perTributario}", perTributario);
        endpoint = ReplaceOptionalQueryParameter(endpoint, "codProceso", "{codProceso}", codProceso);
        endpoint = ReplaceOptionalQueryParameter(endpoint, "numTicket", "{numTicket}", numTicket);

        return endpoint;
    }

    public async Task<object> ObtenerRegistrosVentasAsync(
        string periodo,
        int maxIntentos,
        int segundosEspera,
        string? fecDocumentoDesde = null,
        string? fecDocumentoHasta = null,
        string? mtoTotalDesde = null,
        string? mtoTotalHasta = null,
        string? numRucAdquiriente = null,
        string? numCarSunat = null,
        string? codTipoCDP = null,
        string? codTipoInconsistencia = null)
    {
        if (string.IsNullOrWhiteSpace(periodo))
        {
            throw new ArgumentException("El periodo es requerido.", nameof(periodo));
        }

        var ticketResponse = await ObtenerVentasAsync(
            periodo,
            fecDocumentoDesde,
            fecDocumentoHasta,
            mtoTotalDesde,
            mtoTotalHasta,
            numRucAdquiriente,
            numCarSunat,
            codTipoCDP,
            codTipoInconsistencia);
        var numTicket = FindFirstString(ticketResponse, "numTicket");
        if (string.IsNullOrWhiteSpace(numTicket))
        {
            throw new InvalidOperationException("SUNAT no devolvio numTicket al generar la propuesta RVIE.");
        }

        string? ticketJson = null;
        string? nomArchivoReporte = null;
        string? nomArchivoContenido = null;
        string? codTipoArchivoReporte = null;
        object? ticket = null;

        for (var intento = 1; intento <= maxIntentos; intento++)
        {
            try
            {
                ticketJson = await ConsultarTicketVentasAsync(periodo, periodo, numTicket, 1, 20);
            }
            catch (SunatApiException ex) when (
                ex.StatusCode == System.Net.HttpStatusCode.UnprocessableEntity
                && ex.ResponseBody.Contains("\"cod\":1070", StringComparison.Ordinal)
                && intento < maxIntentos)
            {
                _logger.LogInformation(
                    "Ticket SIRE {NumTicket} aun no disponible. Reintento {Intento}/{MaxIntentos}.",
                    numTicket,
                    intento,
                    maxIntentos);
                await Task.Delay(TimeSpan.FromSeconds(Math.Max(1, segundosEspera)));
                continue;
            }

            using var ticketDocument = JsonDocument.Parse(ticketJson);
            ticket = JsonSerializer.Deserialize<object>(ticketDocument.RootElement.GetRawText(), JsonOptions);

            var archiveInfo = ExtractArchiveInfo(ticketDocument.RootElement);
            nomArchivoReporte = archiveInfo.NomArchivoReporte;
            nomArchivoContenido = archiveInfo.NomArchivoContenido;
            codTipoArchivoReporte = archiveInfo.CodTipoArchivoReporte;

            if (IsTicketFinished(ticketDocument.RootElement) && !string.IsNullOrWhiteSpace(nomArchivoReporte))
            {
                break;
            }

            if (intento < maxIntentos)
            {
                await Task.Delay(TimeSpan.FromSeconds(Math.Max(1, segundosEspera)));
            }
        }

        if (string.IsNullOrWhiteSpace(nomArchivoReporte))
        {
            throw new InvalidOperationException("El ticket SUNAT aun no devolvio archivoReporte.nomArchivoReporte.");
        }

        var perTributario = FindFirstString(ticketJson!, "perTributario") ?? periodo;
        var codProceso = FindFirstString(ticketJson!, "codProceso");
        var bytes = await DescargarArchivoVentasAsync(
            nomArchivoReporte,
            codTipoArchivoReporte ?? "00",
            "140000",
            perTributario,
            codProceso,
            numTicket);
        var archivo = ParseRecordsFile(bytes, nomArchivoReporte, nomArchivoContenido);

        return new
        {
            periodo,
            filtros = new
            {
                fecDocumentoDesde,
                fecDocumentoHasta,
                mtoTotalDesde,
                mtoTotalHasta,
                numRucAdquiriente,
                numCarSunat,
                codTipoCDP,
                codTipoInconsistencia
            },
            numTicket,
            ticket,
            archivo,
            nota = "El backend genero ticket, consulto estado, obtuvo el archivo SUNAT internamente y devolvio los registros como JSON."
        };
    }

    private async Task<HttpRequestMessage> CreateRequestAsync(HttpMethod method, string endpoint)
    {
        if (string.IsNullOrWhiteSpace(endpoint))
        {
            throw new ArgumentException("El endpoint SIRE es requerido.", nameof(endpoint));
        }

        var token = await _sunatAuthService.GetAccessTokenAsync();
        var request = new HttpRequestMessage(method, BuildUri(endpoint));
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

        if (method == HttpMethod.Get)
        {
            request.Content = new StringContent(string.Empty, Encoding.UTF8, "application/json");
        }

        return request;
    }

    private async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request)
    {
        var client = _httpClientFactory.CreateClient("Sire");
        _logger.LogWarning(
            "Enviando request a SIRE. Method: {Method}. Url: {Url}. Accept: {Accept}. AuthorizationScheme: {AuthorizationScheme}. TokenLength: {TokenLength}.",
            request.Method,
            request.RequestUri,
            string.Join(",", request.Headers.Accept.Select(x => x.MediaType)),
            request.Headers.Authorization?.Scheme ?? "(sin authorization)",
            request.Headers.Authorization?.Parameter?.Length ?? 0);

        var response = await client.SendAsync(request);

        if (!response.IsSuccessStatusCode)
        {
            var responseBody = await response.Content.ReadAsStringAsync();
            _logger.LogError(
                "Error HTTP al consumir SIRE. Method: {Method}. Url: {Url}. StatusCode: {StatusCode}. ContentType: {ContentType}. Body: {Body}",
                request.Method,
                request.RequestUri,
                (int)response.StatusCode,
                response.Content.Headers.ContentType?.ToString(),
                responseBody);

            throw new SunatApiException(
                $"SIRE respondio con estado {(int)response.StatusCode}.",
                response.StatusCode,
                responseBody,
                request.RequestUri?.ToString(),
                BuildDebugInfo(request, response, responseBody));
        }

        return response;
    }

    private Uri BuildUri(string endpoint)
    {
        if (Uri.TryCreate(endpoint, UriKind.Absolute, out var absoluteUri))
        {
            return absoluteUri;
        }

        if (string.IsNullOrWhiteSpace(_options.SireBaseUrl))
        {
            throw new InvalidOperationException("Falta configurar Sunat:SireBaseUrl.");
        }

        return new Uri($"{_options.SireBaseUrl.TrimEnd('/')}/{endpoint.TrimStart('/')}");
    }

    private static string BuildConfiguredEndpoint(
        string endpointTemplate,
        string value,
        string settingName,
        string placeholder = "{periodo}")
    {
        if (string.IsNullOrWhiteSpace(endpointTemplate))
        {
            throw new InvalidOperationException(
                $"Falta configurar {settingName} con el endpoint oficial de SUNAT. Puede usar el placeholder {placeholder}.");
        }

        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException($"El valor para {placeholder} es requerido.", nameof(value));
        }

        return endpointTemplate.Replace(placeholder, Uri.EscapeDataString(value), StringComparison.OrdinalIgnoreCase);
    }

    private static string BuildConfiguredEndpoint(
        string endpointTemplate,
        IReadOnlyDictionary<string, string> replacements,
        string settingName)
    {
        if (string.IsNullOrWhiteSpace(endpointTemplate))
        {
            throw new InvalidOperationException($"Falta configurar {settingName} con el endpoint oficial de SUNAT.");
        }

        var endpoint = endpointTemplate;
        foreach (var item in replacements)
        {
            if (string.IsNullOrWhiteSpace(item.Value))
            {
                throw new ArgumentException($"El valor para {item.Key} es requerido.");
            }

            endpoint = endpoint.Replace(item.Key, Uri.EscapeDataString(item.Value), StringComparison.OrdinalIgnoreCase);
        }

        return endpoint;
    }

    private static string? FindFirstString(string json, params string[] propertyNames)
    {
        using var document = JsonDocument.Parse(json);
        return FindFirstString(document.RootElement, propertyNames);
    }

    private static string? FindFirstString(JsonElement element, params string[] propertyNames)
    {
        if (element.ValueKind == JsonValueKind.Object)
        {
            foreach (var name in propertyNames)
            {
                if (element.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String)
                {
                    return value.GetString();
                }
            }

            foreach (var property in element.EnumerateObject())
            {
                var found = FindFirstString(property.Value, propertyNames);
                if (!string.IsNullOrWhiteSpace(found))
                {
                    return found;
                }
            }
        }

        if (element.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in element.EnumerateArray())
            {
                var found = FindFirstString(item, propertyNames);
                if (!string.IsNullOrWhiteSpace(found))
                {
                    return found;
                }
            }
        }

        return null;
    }

    private static string ReplaceOptionalQueryParameter(
        string endpoint,
        string parameterName,
        string placeholder,
        string? value)
    {
        if (!endpoint.Contains(placeholder, StringComparison.OrdinalIgnoreCase))
        {
            return endpoint;
        }

        if (!string.IsNullOrWhiteSpace(value))
        {
            return endpoint.Replace(placeholder, Uri.EscapeDataString(value), StringComparison.OrdinalIgnoreCase);
        }

        var escapedParameterName = Uri.EscapeDataString(parameterName);
        var patterns = new[]
        {
            $"&{escapedParameterName}={placeholder}",
            $"?{escapedParameterName}={placeholder}"
        };

        foreach (var pattern in patterns)
        {
            if (!endpoint.Contains(pattern, StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            var replacement = pattern[0] == '?' ? "?" : string.Empty;
            endpoint = endpoint.Replace(pattern, replacement, StringComparison.OrdinalIgnoreCase);
        }

        return endpoint.TrimEnd('?', '&');
    }

    private static string SetQueryValue(string endpoint, string key, string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return endpoint;
        }

        var parts = endpoint.Split('?', 2);
        if (parts.Length == 1)
        {
            return $"{endpoint}?{Uri.EscapeDataString(key)}={Uri.EscapeDataString(value)}";
        }

        var queryParts = parts[1].Split('&', StringSplitOptions.RemoveEmptyEntries).ToList();
        var encodedKey = Uri.EscapeDataString(key);
        var encodedValue = Uri.EscapeDataString(value);
        var replaced = false;

        for (var i = 0; i < queryParts.Count; i++)
        {
            var pairKey = queryParts[i].Split('=', 2)[0];
            if (!pairKey.Equals(encodedKey, StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            queryParts[i] = $"{encodedKey}={encodedValue}";
            replaced = true;
            break;
        }

        if (!replaced)
        {
            queryParts.Add($"{encodedKey}={encodedValue}");
        }

        return $"{parts[0]}?{string.Join("&", queryParts)}";
    }

    private static bool IsTicketFinished(JsonElement root)
    {
        var estadoProceso = FindFirstString(root, "codEstadoProceso", "codEstadoEnvio");
        var descripcion = FindFirstString(root, "desEstadoProceso", "desEstadoEnvio");

        return estadoProceso == "06"
            || (!string.IsNullOrWhiteSpace(descripcion)
                && descripcion.Contains("Terminado", StringComparison.OrdinalIgnoreCase));
    }

    private static (string? NomArchivoReporte, string? CodTipoArchivoReporte, string? NomArchivoContenido) ExtractArchiveInfo(JsonElement root)
    {
        if (!root.TryGetProperty("registros", out var registros) || registros.ValueKind != JsonValueKind.Array)
        {
            return (null, null, null);
        }

        foreach (var registro in registros.EnumerateArray())
        {
            if (!registro.TryGetProperty("archivoReporte", out var archivos) || archivos.ValueKind != JsonValueKind.Array)
            {
                continue;
            }

            foreach (var archivo in archivos.EnumerateArray())
            {
                var nomArchivoReporte = GetString(archivo, "nomArchivoReporte");
                if (string.IsNullOrWhiteSpace(nomArchivoReporte))
                {
                    continue;
                }

                return (
                    nomArchivoReporte,
                    GetString(archivo, "codTipoArchivoReporte") ?? GetString(archivo, "codTipoAchivoReporte") ?? "00",
                    GetString(archivo, "nomArchivoContenido"));
            }
        }

        return (null, null, null);
    }

    private static object ParseRecordsFile(byte[] bytes, string nomArchivoReporte, string? nomArchivoContenido)
    {
        var (fileName, text) = ReadTextFromSunatFile(bytes, nomArchivoReporte, nomArchivoContenido);
        var lines = text
            .Replace("\r\n", "\n")
            .Replace('\r', '\n')
            .Split('\n', StringSplitOptions.RemoveEmptyEntries)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .ToArray();

        var delimiter = DetectDelimiter(lines);
        var rows = lines.Select(line => SplitLine(line, delimiter)).ToArray();
        var maxColumns = rows.Length == 0 ? 0 : rows.Max(x => x.Length);
        var columns = Enumerable.Range(1, maxColumns)
            .Select(x => $"col{x:000}")
            .ToArray();

        var records = rows
            .Select(values => columns.ToDictionary(
                column => column,
                column =>
                {
                    var index = Array.IndexOf(columns, column);
                    return index >= 0 && index < values.Length ? values[index] : string.Empty;
                }))
            .ToArray();

        return new
        {
            nomArchivoReporte,
            nomArchivoContenido = fileName,
            delimiter = delimiter.ToString(),
            totalRegistros = records.Length,
            columns,
            registros = records
        };
    }

    private static (string FileName, string Text) ReadTextFromSunatFile(byte[] bytes, string nomArchivoReporte, string? nomArchivoContenido)
    {
        if (bytes.Length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B)
        {
            using var stream = new MemoryStream(bytes);
            using var archive = new ZipArchive(stream, ZipArchiveMode.Read);
            var entry = archive.Entries.FirstOrDefault(x =>
                    !string.IsNullOrWhiteSpace(x.Name)
                    && (string.IsNullOrWhiteSpace(nomArchivoContenido)
                        || x.Name.Equals(nomArchivoContenido, StringComparison.OrdinalIgnoreCase)))
                ?? archive.Entries.FirstOrDefault(x => x.Name.EndsWith(".txt", StringComparison.OrdinalIgnoreCase))
                ?? archive.Entries.FirstOrDefault(x => !string.IsNullOrWhiteSpace(x.Name));

            if (entry is null)
            {
                throw new InvalidOperationException("El ZIP devuelto por SUNAT no contiene archivos.");
            }

            using var entryStream = entry.Open();
            using var reader = new StreamReader(entryStream, Encoding.UTF8, detectEncodingFromByteOrderMarks: true);
            return (entry.Name, reader.ReadToEnd());
        }

        return (nomArchivoReporte, Encoding.UTF8.GetString(bytes));
    }

    private static char DetectDelimiter(string[] lines)
    {
        var candidates = new[] { '|', '\t', ';', ',' };
        return candidates
            .Select(candidate => new
            {
                Delimiter = candidate,
                Count = lines.Take(10).Sum(line => line.Count(x => x == candidate))
            })
            .OrderByDescending(x => x.Count)
            .FirstOrDefault(x => x.Count > 0)?.Delimiter ?? '|';
    }

    private static string[] SplitLine(string line, char delimiter)
    {
        return line.Split(delimiter).Select(x => x.Trim()).ToArray();
    }

    private static string? GetString(JsonElement element, string propertyName)
    {
        return element.TryGetProperty(propertyName, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()
            : null;
    }

    private object BuildDebugInfo(HttpRequestMessage request, HttpResponseMessage response, string responseBody)
    {
        var token = request.Headers.Authorization?.Parameter;

        return new
        {
            integration = new
            {
                message = "Diagnostico de integracion SIRE. El token completo solo aparece si Sunat:IncludeSensitiveDebug=true.",
                sireBaseUrl = _options.SireBaseUrl,
                scope = _options.Scope,
                ruc = _options.Ruc,
                usuarioSol = Mask(_options.UsuarioSol),
                clientId = _options.ClientId,
                rceComprasEndpoint = _options.RceComprasEndpoint,
                rvieVentasEndpoint = _options.RvieVentasEndpoint,
                rviePeriodosEndpoint = _options.RviePeriodosEndpoint,
                rvieTicketEndpoint = _options.RvieTicketEndpoint,
                rvieArchivoEndpoint = _options.RvieArchivoEndpoint
            },
            request = new
            {
                method = request.Method.Method,
                url = request.RequestUri?.ToString(),
                accept = request.Headers.Accept.Select(x => x.MediaType).ToArray(),
                authorizationHeaderPresent = request.Headers.Authorization is not null,
                authorizationScheme = request.Headers.Authorization?.Scheme,
                contentType = request.Content?.Headers.ContentType?.ToString(),
                bearerTokenLength = token?.Length ?? 0,
                bearerTokenPreview = Preview(token),
                bearerToken = _options.IncludeSensitiveDebug ? token : null,
                tokenJwtPayload = ReadJwtPayload(token)
            },
            sunatOAuth = _sunatAuthService.GetLastAuthDebug(),
            response = new
            {
                statusCode = (int)response.StatusCode,
                reasonPhrase = response.ReasonPhrase,
                contentType = response.Content.Headers.ContentType?.ToString(),
                bodyPreview = Preview(responseBody, 600),
                headers = response.Headers.ToDictionary(x => x.Key, x => string.Join(",", x.Value))
            },
            expected = new
            {
                successStatus = 200,
                successBody = "SUNAT deberia devolver JSON con numTicket para luego consultar estado y descargar archivo.",
                currentProblem = "SUNAT gateway devuelve HTML 401 antes de llegar a una respuesta JSON de SIRE."
            }
        };
    }

    private static object? ReadJwtPayload(string? token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return null;
        }

        var parts = token.Split('.');
        if (parts.Length < 2)
        {
            return new { error = "El token no tiene formato JWT." };
        }

        try
        {
            var payload = parts[1].Replace('-', '+').Replace('_', '/');
            payload = payload.PadRight(payload.Length + ((4 - payload.Length % 4) % 4), '=');

            using var document = JsonDocument.Parse(Convert.FromBase64String(payload));
            return JsonSerializer.Deserialize<object>(document.RootElement.GetRawText(), JsonOptions);
        }
        catch (Exception ex)
        {
            return new { error = $"No se pudo leer payload JWT: {ex.Message}" };
        }
    }

    private static string? Preview(string? value, int maxLength = 24)
    {
        if (string.IsNullOrEmpty(value))
        {
            return value;
        }

        if (value.Length <= maxLength)
        {
            return value;
        }

        return $"{value[..maxLength]}...";
    }

    private static string Mask(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return "(vacio)";
        }

        var trimmed = value.Trim();
        if (trimmed.Length <= 4)
        {
            return new string('*', trimmed.Length);
        }

        return $"{trimmed[..2]}***{trimmed[^2..]}";
    }
}
