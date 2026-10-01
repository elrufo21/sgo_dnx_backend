using System.Collections.Concurrent;
using System.Text.Json;
using Ecommerce.Api.Interfaces;
using Ecommerce.Api.Models;

namespace Ecommerce.Api.Services;

public class SunatAuthService : ISunatAuthService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ISunatCredentialsProvider _credentialsProvider;
    private readonly ILogger<SunatAuthService> _logger;
    private readonly SemaphoreSlim _tokenLock = new(1, 1);
    private readonly ConcurrentDictionary<string, CachedSunatToken> _tokenCache = new();
    private object? _lastAuthDebug;

    public SunatAuthService(
        IHttpClientFactory httpClientFactory,
        ISunatCredentialsProvider credentialsProvider,
        ILogger<SunatAuthService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _credentialsProvider = credentialsProvider;
        _logger = logger;
    }

    public async Task<string> GetAccessTokenAsync()
    {
        var credentials = await _credentialsProvider.GetCredentialsAsync();
        ValidateCredentials(credentials);

        var cacheKey = BuildCacheKey(credentials);
        if (TryGetValidToken(cacheKey, out var cachedToken, out var cachedExpiresAt))
        {
            _lastAuthDebug = BuildCachedAuthDebug(credentials, BuildTokenUrl(credentials), cachedToken, cachedExpiresAt);
            return cachedToken;
        }

        await _tokenLock.WaitAsync();
        try
        {
            if (TryGetValidToken(cacheKey, out cachedToken, out cachedExpiresAt))
            {
                _lastAuthDebug = BuildCachedAuthDebug(credentials, BuildTokenUrl(credentials), cachedToken, cachedExpiresAt);
                return cachedToken;
            }

            var client = _httpClientFactory.CreateClient("SunatAuth");
            var tokenUrl = BuildTokenUrl(credentials);
            using var content = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["grant_type"] = "password",
                ["scope"] = credentials.Scope,
                ["client_id"] = credentials.ClientId,
                ["client_secret"] = credentials.ClientSecret,
                ["username"] = $"{credentials.Ruc}{credentials.UsuarioSol}",
                ["password"] = credentials.ClaveSol
            });

            using var response = await client.PostAsync(tokenUrl, content);
            var responseBody = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError(
                    "Error HTTP al obtener token SUNAT. StatusCode: {StatusCode}. Body: {Body}",
                    (int)response.StatusCode,
                    responseBody);

                throw new SunatApiException(
                    $"SUNAT OAuth2 respondio con estado {(int)response.StatusCode}.",
                    response.StatusCode,
                    responseBody,
                    tokenUrl.ToString(),
                    BuildHttpAuthDebug(credentials, tokenUrl, response, null, responseBody, false));
            }

            var tokenResponse = JsonSerializer.Deserialize<TokenResponse>(responseBody, JsonOptions);
            if (tokenResponse is null || string.IsNullOrWhiteSpace(tokenResponse.AccessToken))
            {
                _logger.LogError("SUNAT OAuth2 no devolvio access_token. Body: {Body}", responseBody);
                throw new InvalidOperationException("SUNAT OAuth2 no devolvio access_token.");
            }

            var expiresIn = tokenResponse.ExpiresIn > 0 ? tokenResponse.ExpiresIn : 3600;
            var expiresAt = DateTimeOffset.UtcNow.AddSeconds(expiresIn);
            _tokenCache[cacheKey] = new CachedSunatToken
            {
                AccessToken = tokenResponse.AccessToken,
                ExpiresAt = expiresAt
            };

            _lastAuthDebug = BuildHttpAuthDebug(credentials, tokenUrl, response, tokenResponse, responseBody, true, expiresAt);

            _logger.LogWarning(
                "Token SUNAT obtenido correctamente. RUC: {Ruc}. UsuarioSol: {UsuarioSol}. ClientId: {ClientId}. ExpiraEnSegundos: {ExpiresIn}. TokenLength: {TokenLength}. JwtPayload: {JwtPayload}.",
                Mask(credentials.Ruc),
                Mask(credentials.UsuarioSol),
                Mask(credentials.ClientId),
                expiresIn,
                tokenResponse.AccessToken.Length,
                TryReadJwtPayload(tokenResponse.AccessToken));

            return tokenResponse.AccessToken;
        }
        finally
        {
            _tokenLock.Release();
        }
    }

    public object? GetLastAuthDebug()
    {
        return _lastAuthDebug;
    }

    private bool TryGetValidToken(string cacheKey, out string accessToken, out DateTimeOffset expiresAt)
    {
        accessToken = string.Empty;
        expiresAt = default;
        if (!_tokenCache.TryGetValue(cacheKey, out var cachedToken))
        {
            return false;
        }

        if (string.IsNullOrWhiteSpace(cachedToken.AccessToken)
            || DateTimeOffset.UtcNow >= cachedToken.ExpiresAt.AddMinutes(-2))
        {
            return false;
        }

        accessToken = cachedToken.AccessToken;
        expiresAt = cachedToken.ExpiresAt;
        return true;
    }

    private static object BuildCachedAuthDebug(
        SunatCredentials credentials,
        Uri tokenUrl,
        string token,
        DateTimeOffset expiresAt)
    {
        return new
        {
            source = "cache",
            success = true,
            tokenUrl = tokenUrl.ToString(),
            httpStatusCode = 200,
            requestedAtUtc = DateTimeOffset.UtcNow,
            expiresAtUtc = expiresAt,
            tokenLength = token.Length,
            tokenPreview = Preview(token),
            jwtPayload = ReadJwtPayload(token),
            request = BuildSafeTokenRequest(credentials),
            note = "El token SUNAT no se pidio de nuevo porque todavia estaba vigente en cache."
        };
    }

    private static object BuildHttpAuthDebug(
        SunatCredentials credentials,
        Uri tokenUrl,
        HttpResponseMessage response,
        TokenResponse? tokenResponse,
        string responseBody,
        bool success,
        DateTimeOffset? expiresAt = null)
    {
        return new
        {
            source = "sunat-oauth2",
            success,
            tokenUrl = tokenUrl.ToString(),
            httpStatusCode = (int)response.StatusCode,
            reasonPhrase = response.ReasonPhrase,
            responseContentType = response.Content.Headers.ContentType?.ToString(),
            requestedAtUtc = DateTimeOffset.UtcNow,
            expiresIn = tokenResponse?.ExpiresIn,
            expiresAtUtc = expiresAt,
            tokenType = tokenResponse?.TokenType,
            tokenScope = tokenResponse?.Scope,
            tokenLength = tokenResponse?.AccessToken?.Length ?? 0,
            tokenPreview = Preview(tokenResponse?.AccessToken),
            jwtPayload = ReadJwtPayload(tokenResponse?.AccessToken),
            request = BuildSafeTokenRequest(credentials),
            responseBodyPreview = Preview(responseBody, 600)
        };
    }

    private static object BuildSafeTokenRequest(SunatCredentials credentials)
    {
        return new
        {
            grantType = "password",
            scope = credentials.Scope,
            clientId = credentials.ClientId,
            ruc = credentials.Ruc,
            usuarioSol = Mask(credentials.UsuarioSol),
            username = $"{credentials.Ruc}{Mask(credentials.UsuarioSol)}",
            clientSecretSent = !string.IsNullOrWhiteSpace(credentials.ClientSecret),
            passwordSent = !string.IsNullOrWhiteSpace(credentials.ClaveSol)
        };
    }

    private static Uri BuildTokenUrl(SunatCredentials credentials)
    {
        var baseUrl = credentials.SeguridadBaseUrl.TrimEnd('/');
        return new Uri($"{baseUrl}/v1/clientessol/{Uri.EscapeDataString(credentials.ClientId)}/oauth2/token/");
    }

    private static void ValidateCredentials(SunatCredentials credentials)
    {
        var missing = new List<string>();

        if (string.IsNullOrWhiteSpace(credentials.ClientId)) missing.Add("Sunat:ClientId o Compania.ClienIdToken");
        if (string.IsNullOrWhiteSpace(credentials.ClientSecret)) missing.Add("Sunat:ClientSecret o Compania.TokenApi");
        if (string.IsNullOrWhiteSpace(credentials.Ruc)) missing.Add("Sunat:Ruc o Compania.CompaniaRUC");
        if (string.IsNullOrWhiteSpace(credentials.UsuarioSol)) missing.Add("Sunat:UsuarioSol o Compania.CompaniaUserSecun");
        if (string.IsNullOrWhiteSpace(credentials.ClaveSol)) missing.Add("Sunat:ClaveSol o Compania.ComapaniaPWD");
        if (string.IsNullOrWhiteSpace(credentials.Scope)) missing.Add("Sunat:Scope");
        if (string.IsNullOrWhiteSpace(credentials.SeguridadBaseUrl)) missing.Add("Sunat:SeguridadBaseUrl");

        if (missing.Count > 0)
        {
            throw new InvalidOperationException($"Falta configurar: {string.Join(", ", missing)}.");
        }
    }

    private static string BuildCacheKey(SunatCredentials credentials)
    {
        return $"{credentials.ClientId}|{credentials.Ruc}|{credentials.UsuarioSol}";
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

    private static string? Preview(string? value, int maxLength = 24)
    {
        if (string.IsNullOrEmpty(value))
        {
            return value;
        }

        return value.Length <= maxLength ? value : $"{value[..maxLength]}...";
    }

    private static string TryReadJwtPayload(string token)
    {
        var parts = token.Split('.');
        if (parts.Length < 2)
        {
            return "(token no JWT)";
        }

        try
        {
            var payload = parts[1]
                .Replace('-', '+')
                .Replace('_', '/');
            payload = payload.PadRight(payload.Length + ((4 - payload.Length % 4) % 4), '=');

            using var document = JsonDocument.Parse(Convert.FromBase64String(payload));
            var root = document.RootElement;
            var safeClaims = new Dictionary<string, string?>();

            AddClaimIfExists(root, safeClaims, "iss");
            AddClaimIfExists(root, safeClaims, "aud");
            AddClaimIfExists(root, safeClaims, "scope");
            AddClaimIfExists(root, safeClaims, "client_id");
            AddClaimIfExists(root, safeClaims, "exp");

            return JsonSerializer.Serialize(safeClaims, JsonOptions);
        }
        catch
        {
            return "(no se pudo leer payload JWT)";
        }
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
            var payload = parts[1]
                .Replace('-', '+')
                .Replace('_', '/');
            payload = payload.PadRight(payload.Length + ((4 - payload.Length % 4) % 4), '=');

            using var document = JsonDocument.Parse(Convert.FromBase64String(payload));
            return JsonSerializer.Deserialize<object>(document.RootElement.GetRawText(), JsonOptions);
        }
        catch (Exception ex)
        {
            return new { error = $"No se pudo leer payload JWT: {ex.Message}" };
        }
    }

    private static void AddClaimIfExists(JsonElement root, Dictionary<string, string?> claims, string name)
    {
        if (root.TryGetProperty(name, out var value))
        {
            claims[name] = value.ValueKind == JsonValueKind.String ? value.GetString() : value.ToString();
        }
    }

    private sealed class CachedSunatToken
    {
        public string AccessToken { get; set; } = string.Empty;
        public DateTimeOffset ExpiresAt { get; set; }
    }
}

