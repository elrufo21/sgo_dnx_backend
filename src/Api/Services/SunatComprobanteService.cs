using System.Globalization;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Ecommerce.Api.Interfaces;
using Ecommerce.Api.Models;
using Ecommerce.Api.Options;
using Microsoft.Extensions.Options;

namespace Ecommerce.Api.Services;

public class SunatComprobanteService : ISunatComprobanteService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<SunatComprobanteService> _logger;
    private readonly SunatOptions _options;
    private readonly ISunatCredentialsProvider _credentialsProvider;
    private string? _accessToken;
    private DateTimeOffset _expiresAtUtc;

    public SunatComprobanteService(
        IHttpClientFactory httpClientFactory,
        IOptions<SunatOptions> options,
        ISunatCredentialsProvider credentialsProvider,
        ILogger<SunatComprobanteService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _options = options.Value;
        _credentialsProvider = credentialsProvider;
        _logger = logger;
    }

    public async Task<IReadOnlyList<ValidarComprobanteSunatResult>> ValidarAsync(
        IReadOnlyList<ValidarComprobanteSunatItem> documentos,
        CancellationToken cancellationToken = default)
    {
        var credentials = await _credentialsProvider.GetCredentialsAsync(cancellationToken);
        var results = new List<ValidarComprobanteSunatResult>();
        foreach (var documento in documentos)
        {
            results.Add(await ValidarUnoAsync(documento, credentials, retryOnUnauthorized: true, cancellationToken));
        }

        return results;
    }

    private async Task<ValidarComprobanteSunatResult> ValidarUnoAsync(
        ValidarComprobanteSunatItem documento,
        SunatCredentials credentials,
        bool retryOnUnauthorized,
        CancellationToken cancellationToken)
    {
        var error = ValidarEntrada(documento);
        if (!string.IsNullOrWhiteSpace(error))
        {
            return new ValidarComprobanteSunatResult
            {
                Documento = documento,
                Error = error
            };
        }

        var token = await GetAccessTokenAsync(credentials, cancellationToken);
        var ruc = credentials.Ruc.Trim();
        var url = $"{_options.ComprobanteBaseUrl.TrimEnd('/')}/v1/contribuyente/contribuyentes/{Uri.EscapeDataString(ruc)}/validarcomprobante";
        var body = new
        {
            numRuc = ruc,
            codComp = documento.TipoDocumento!.Trim(),
            numeroSerie = documento.Serie!.Trim().ToUpperInvariant(),
            numero = NormalizarNumeroParaSunat(documento.Numero),
            fechaEmision = NormalizarFecha(documento.FechaEmision),
            monto = documento.Monto!.Value.ToString("0.00", CultureInfo.InvariantCulture)
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        request.Content = new StringContent(JsonSerializer.Serialize(body, JsonOptions), Encoding.UTF8, "application/json");

        var client = _httpClientFactory.CreateClient("SunatComprobante");
        using var response = await client.SendAsync(request, cancellationToken);
        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);

        if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized && retryOnUnauthorized)
        {
            _accessToken = null;
            return await ValidarUnoAsync(documento, credentials, retryOnUnauthorized: false, cancellationToken);
        }

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError(
                "SUNAT validarcomprobante devolvio error. Url: {Url}. StatusCode: {StatusCode}. Body: {Body}",
                url,
                (int)response.StatusCode,
                responseBody);
        }

        var codigo = ExtraerCodigo(responseBody);
        return new ValidarComprobanteSunatResult
        {
            Documento = documento,
            Consultado = response.IsSuccessStatusCode,
            Codigo = codigo,
            Mensaje = ResolverMensaje(codigo),
            ExisteEnSunat = codigo is "1" or "2" or "3",
            StatusCode = (int)response.StatusCode,
            SunatResponse = responseBody
        };
    }

    private async Task<string> GetAccessTokenAsync(SunatCredentials credentials, CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(_accessToken) && _expiresAtUtc > DateTimeOffset.UtcNow.AddMinutes(2))
        {
            return _accessToken;
        }

        var clientId = credentials.ComprobanteClientId;
        var clientSecret = credentials.ComprobanteClientSecret;

        if (string.IsNullOrWhiteSpace(clientId) || string.IsNullOrWhiteSpace(clientSecret))
        {
            throw new InvalidOperationException("Faltan las credenciales de validación SUNAT para la compañía.");
        }

        var url = $"{credentials.SeguridadBaseUrl.TrimEnd('/')}/v1/clientesextranet/{Uri.EscapeDataString(clientId)}/oauth2/token/";
        using var request = new HttpRequestMessage(HttpMethod.Post, url);
        request.Content = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["grant_type"] = "client_credentials",
            ["scope"] = _options.ComprobanteScope,
            ["client_id"] = clientId,
            ["client_secret"] = clientSecret,
            ["expires_in"] = "432000"
        });

        var client = _httpClientFactory.CreateClient("SunatComprobanteAuth");
        using var response = await client.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new SunatApiException(
                $"SUNAT token validar comprobantes respondio con estado {(int)response.StatusCode}.",
                response.StatusCode,
                body,
                url);
        }

        var token = JsonSerializer.Deserialize<TokenResponse>(body, JsonOptions)
            ?? throw new InvalidOperationException("SUNAT no devolvio token valido para validar comprobantes.");

        _accessToken = token.AccessToken;
        _expiresAtUtc = DateTimeOffset.UtcNow.AddSeconds(Math.Max(60, token.ExpiresIn));
        return _accessToken;
    }

    private static string ValidarEntrada(ValidarComprobanteSunatItem documento)
    {
        if (string.IsNullOrWhiteSpace(documento.TipoDocumento)) return "Falta tipoDocumento/tipoCodigo.";
        if (string.IsNullOrWhiteSpace(documento.Serie)) return "Falta serie.";
        if (string.IsNullOrWhiteSpace(documento.Numero)) return "Falta numero.";
        if (string.IsNullOrWhiteSpace(documento.FechaEmision)) return "Falta fechaEmision/fecha.";
        if (documento.Monto is null) return "Falta monto.";
        return string.Empty;
    }

    private static string NormalizarFecha(string? value)
    {
        var text = (value ?? string.Empty).Trim();
        if (DateTime.TryParseExact(text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var ymd))
        {
            return ymd.ToString("dd/MM/yyyy", CultureInfo.InvariantCulture);
        }

        if (DateTime.TryParseExact(text, "dd/MM/yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out var dmy))
        {
            return dmy.ToString("dd/MM/yyyy", CultureInfo.InvariantCulture);
        }

        return text;
    }

    private static string NormalizarNumeroParaSunat(string? value)
    {
        var digits = new string((value ?? string.Empty).Where(char.IsDigit).ToArray());
        var normalized = digits.TrimStart('0');
        return string.IsNullOrWhiteSpace(normalized) ? digits : normalized;
    }

    private static string ExtraerCodigo(string responseBody)
    {
        if (string.IsNullOrWhiteSpace(responseBody))
        {
            return string.Empty;
        }

        try
        {
            using var document = JsonDocument.Parse(responseBody);
            return BuscarPropiedad(document.RootElement, "estadoCp")
                ?? BuscarPropiedad(document.RootElement, "codRespuesta")
                ?? BuscarPropiedad(document.RootElement, "codigo")
                ?? string.Empty;
        }
        catch
        {
            return string.Empty;
        }
    }

    private static string? BuscarPropiedad(JsonElement element, string propertyName)
    {
        if (element.ValueKind == JsonValueKind.Object)
        {
            foreach (var property in element.EnumerateObject())
            {
                if (property.NameEquals(propertyName))
                {
                    return property.Value.ValueKind == JsonValueKind.String
                        ? property.Value.GetString()
                        : property.Value.ToString();
                }

                var found = BuscarPropiedad(property.Value, propertyName);
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
                var found = BuscarPropiedad(item, propertyName);
                if (!string.IsNullOrWhiteSpace(found))
                {
                    return found;
                }
            }
        }

        return null;
    }

    private static string ResolverMensaje(string codigo)
    {
        return codigo switch
        {
            "0" => "NO EXISTE (Comprobante no informado)",
            "1" => "ACEPTADO (Comprobante aceptado)",
            "2" => "ANULADO (Comunicado en una baja)",
            "3" => "AUTORIZADO (con autorizacion de imprenta)",
            "4" => "NO AUTORIZADO (no autorizado por imprenta)",
            _ => "Sin codigo SUNAT reconocido"
        };
    }
}
