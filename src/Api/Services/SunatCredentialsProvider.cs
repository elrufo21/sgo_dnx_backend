using System.Security.Claims;
using Ecommerce.Api.Interfaces;
using Ecommerce.Api.Models;
using Ecommerce.Api.Options;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;

namespace Ecommerce.Api.Services;

public sealed class SunatCredentialsProvider : ISunatCredentialsProvider
{
    private readonly IConfiguration _configuration;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly SunatOptions _options;

    public SunatCredentialsProvider(
        IConfiguration configuration,
        IHttpContextAccessor httpContextAccessor,
        IOptions<SunatOptions> options)
    {
        _configuration = configuration;
        _httpContextAccessor = httpContextAccessor;
        _options = options.Value;
    }

    public async Task<SunatCredentials> GetCredentialsAsync(CancellationToken cancellationToken = default)
    {
        var claim = _httpContextAccessor.HttpContext?.User.FindFirstValue("companiaId");
        if (!int.TryParse(claim, out var companiaId) || companiaId <= 0)
            throw new InvalidOperationException("El token no contiene una compañía válida.");

        var connectionString = _configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Falta ConnectionStrings:DefaultConnection.");
        await using var connection = new SqlConnection(connectionString);
        await using var command = new SqlCommand(@"
SELECT c.CompaniaRUC, i.Descripcion, i.ValorTexto1
FROM dbo.Compania c
LEFT JOIN dbo.Indicador i ON i.CompaniaId = c.CompaniaId AND i.Area = 'SUNAT'
WHERE c.CompaniaId = @CompaniaId
ORDER BY i.FechaActualizacion DESC, i.Id DESC;", connection);
        command.Parameters.Add("@CompaniaId", System.Data.SqlDbType.Int).Value = companiaId;
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
            throw new InvalidOperationException("No se encontró la compañía autenticada.");

        var values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        var ruc = string.Empty;
        do
        {
            ruc = reader["CompaniaRUC"]?.ToString()?.Trim() ?? string.Empty;
            if (reader["Descripcion"] != DBNull.Value)
            {
                var key = reader["Descripcion"]!.ToString()!;
                values.TryAdd(key, reader["ValorTexto1"] == DBNull.Value ? string.Empty : reader["ValorTexto1"]!.ToString()!.Trim());
            }
        } while (await reader.ReadAsync(cancellationToken));

        var credentials = new SunatCredentials
        {
            Ruc = ruc,
            UsuarioSol = Get("SUNAT_USUARIO_SOL"),
            ClaveSol = Get("SUNAT_CLAVE_SOL"),
            ClientId = Get("SUNAT_SIRE_CLIENT_ID"),
            ClientSecret = Get("SUNAT_SIRE_CLIENT_SECRET"),
            ComprobanteClientId = Get("SUNAT_VALIDAR_CLIENT_ID"),
            ComprobanteClientSecret = Get("SUNAT_VALIDAR_CLIENT_SECRET"),
            SireBaseUrl = _options.SireBaseUrl,
            Scope = _options.Scope,
            SeguridadBaseUrl = _options.SeguridadBaseUrl
        };

        var missing = new List<string>();
        if (string.IsNullOrWhiteSpace(credentials.Ruc)) missing.Add("RUC de la compañía");
        if (string.IsNullOrWhiteSpace(credentials.UsuarioSol)) missing.Add("Usuario SOL");
        if (string.IsNullOrWhiteSpace(credentials.ClaveSol)) missing.Add("Clave SOL");
        if (string.IsNullOrWhiteSpace(credentials.ClientId)) missing.Add("Client ID SIRE");
        if (string.IsNullOrWhiteSpace(credentials.ClientSecret)) missing.Add("Client Secret SIRE");
        if (missing.Count > 0)
            throw new InvalidOperationException($"Configura en SUNAT: {string.Join(", ", missing)}.");

        return credentials;

        string Get(string key) => values.GetValueOrDefault(key, string.Empty);
    }
}
