using System.Data;
using System.Security.Claims;
using Ecommerce.Api.Security;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/configuracion/sunat")]
[RequirePermission("CONFIGURACION.FACTURACION")]
public sealed class SunatConfigurationController : ControllerBase
{
    private static readonly string[] SecretKeys =
    {
        "SUNAT_CLAVE_SOL",
        "SUNAT_SIRE_CLIENT_SECRET",
        "SUNAT_VALIDAR_CLIENT_SECRET"
    };
    private readonly string _connectionString;

    public SunatConfigurationController(IConfiguration configuration) =>
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Falta ConnectionStrings:DefaultConnection.");

    [HttpGet]
    public async Task<IActionResult> Get(CancellationToken cancellationToken)
    {
        if (!TryGetCompanyId(out var companyId)) return Unauthorized();
        await using var connection = new SqlConnection(_connectionString);
        await using var command = new SqlCommand(@"
SELECT c.CompaniaRUC, i.Descripcion, i.ValorTexto1
FROM dbo.Compania c
LEFT JOIN dbo.Indicador i ON i.CompaniaId = c.CompaniaId AND i.Area = 'SUNAT'
WHERE c.CompaniaId = @CompaniaId
ORDER BY i.FechaActualizacion DESC, i.Id DESC;", connection);
        command.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companyId;
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) return NotFound();

        var ruc = reader["CompaniaRUC"]?.ToString()?.Trim() ?? string.Empty;
        var values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        do
        {
            if (reader["Descripcion"] == DBNull.Value) continue;
            var key = reader["Descripcion"]!.ToString()!;
            values.TryAdd(key, reader["ValorTexto1"] == DBNull.Value ? string.Empty : reader["ValorTexto1"]!.ToString()!.Trim());
        } while (await reader.ReadAsync(cancellationToken));

        return Ok(new
        {
            ruc,
            usuarioSol = values.GetValueOrDefault("SUNAT_USUARIO_SOL", string.Empty),
            sireClientId = values.GetValueOrDefault("SUNAT_SIRE_CLIENT_ID", string.Empty),
            comprobanteClientId = values.GetValueOrDefault("SUNAT_VALIDAR_CLIENT_ID", string.Empty),
            tieneClaveSol = HasValue("SUNAT_CLAVE_SOL"),
            tieneSireClientSecret = HasValue("SUNAT_SIRE_CLIENT_SECRET"),
            tieneComprobanteClientSecret = HasValue("SUNAT_VALIDAR_CLIENT_SECRET")
        });

        bool HasValue(string key) => !string.IsNullOrWhiteSpace(values.GetValueOrDefault(key));
    }

    [HttpPut]
    public async Task<IActionResult> Put(GuardarConfiguracionSunat request, CancellationToken cancellationToken)
    {
        if (!TryGetCompanyId(out var companyId)) return Unauthorized();
        request.UsuarioSol = request.UsuarioSol?.Trim() ?? string.Empty;
        request.SireClientId = request.SireClientId?.Trim() ?? string.Empty;
        request.ComprobanteClientId = request.ComprobanteClientId?.Trim() ?? string.Empty;
        request.ClaveSol = Clean(request.ClaveSol);
        request.SireClientSecret = Clean(request.SireClientSecret);
        request.ComprobanteClientSecret = Clean(request.ComprobanteClientSecret);

        if (request.UsuarioSol.Length is 0 or > 250 || request.SireClientId.Length is 0 or > 250 || request.ComprobanteClientId.Length is 0 or > 250)
            return BadRequest(new { message = "Usuario SOL y ambos Client ID son obligatorios y no deben superar 250 caracteres." });
        if (request.ClaveSol.Length > 500 || request.SireClientSecret.Length > 500 || request.ComprobanteClientSecret.Length > 500)
            return BadRequest(new { message = "Una clave supera los 500 caracteres permitidos." });

        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);

        var companyExists = await ScalarAsync(connection, transaction,
            "SELECT COUNT(1) FROM dbo.Compania WHERE CompaniaId = @CompaniaId;", companyId, cancellationToken);
        if (companyExists == 0) return NotFound();

        var configured = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        await using (var read = new SqlCommand(@"
SELECT Descripcion
FROM dbo.Indicador WITH (UPDLOCK, HOLDLOCK)
WHERE CompaniaId = @CompaniaId AND Area = 'SUNAT' AND Descripcion IN
('SUNAT_CLAVE_SOL','SUNAT_SIRE_CLIENT_SECRET','SUNAT_VALIDAR_CLIENT_SECRET')
  AND NULLIF(LTRIM(RTRIM(ValorTexto1)), '') IS NOT NULL;", connection, transaction))
        {
            read.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companyId;
            await using var reader = await read.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken)) configured.Add(reader.GetString(0));
        }

        if (SecretKeys.Any(key => !configured.Contains(key)) &&
            (string.IsNullOrWhiteSpace(request.ClaveSol) || string.IsNullOrWhiteSpace(request.SireClientSecret) || string.IsNullOrWhiteSpace(request.ComprobanteClientSecret)))
            return BadRequest(new { message = "Completa las tres claves la primera vez. Luego puedes dejar una clave vacía para conservarla." });

        var values = new Dictionary<string, string>
        {
            ["SUNAT_USUARIO_SOL"] = request.UsuarioSol,
            ["SUNAT_CLAVE_SOL"] = request.ClaveSol,
            ["SUNAT_SIRE_CLIENT_ID"] = request.SireClientId,
            ["SUNAT_SIRE_CLIENT_SECRET"] = request.SireClientSecret,
            ["SUNAT_VALIDAR_CLIENT_ID"] = request.ComprobanteClientId,
            ["SUNAT_VALIDAR_CLIENT_SECRET"] = request.ComprobanteClientSecret
        };

        foreach (var (key, value) in values)
        {
            await using var command = new SqlCommand(@"
IF EXISTS (SELECT 1 FROM dbo.Indicador WITH (UPDLOCK, HOLDLOCK) WHERE CompaniaId = @CompaniaId AND Descripcion = @Descripcion)
    UPDATE dbo.Indicador
       SET Area = 'SUNAT', TipoIndicador = 3,
           ValorTexto1 = CASE WHEN @PreserveEmpty = 1 AND NULLIF(@Valor, '') IS NULL THEN ValorTexto1 ELSE @Valor END,
           FechaActualizacion = GETDATE()
     WHERE CompaniaId = @CompaniaId AND Descripcion = @Descripcion;
ELSE
    INSERT INTO dbo.Indicador (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1)
    VALUES (@CompaniaId, 'SUNAT', 3, NULL, @Descripcion, @Valor);", connection, transaction);
            command.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companyId;
            command.Parameters.Add("@Descripcion", SqlDbType.VarChar, 500).Value = key;
            command.Parameters.Add("@Valor", SqlDbType.VarChar, 500).Value = string.IsNullOrEmpty(value) ? DBNull.Value : value;
            command.Parameters.Add("@PreserveEmpty", SqlDbType.Bit).Value = SecretKeys.Contains(key, StringComparer.OrdinalIgnoreCase);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        await transaction.CommitAsync(cancellationToken);
        return NoContent();
    }

    private bool TryGetCompanyId(out int companyId) =>
        int.TryParse(User.FindFirstValue("companiaId"), out companyId) && companyId > 0;

    private static string Clean(string? value) => value?.Trim() ?? string.Empty;

    private static async Task<int> ScalarAsync(SqlConnection connection, SqlTransaction transaction, string sql, int companyId, CancellationToken cancellationToken)
    {
        await using var command = new SqlCommand(sql, connection, transaction);
        command.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companyId;
        return Convert.ToInt32(await command.ExecuteScalarAsync(cancellationToken));
    }
}

public sealed class GuardarConfiguracionSunat
{
    public string? UsuarioSol { get; set; }
    public string? ClaveSol { get; set; }
    public string? SireClientId { get; set; }
    public string? SireClientSecret { get; set; }
    public string? ComprobanteClientId { get; set; }
    public string? ComprobanteClientSecret { get; set; }
}
