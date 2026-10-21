using System.Data;
using System.Globalization;
using System.Security.Claims;
using Ecommerce.Api.Security;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/configuracion")]
public sealed class CompanyIndicatorSettingsController : ControllerBase
{
    private readonly string _connectionString;

    public CompanyIndicatorSettingsController(IConfiguration configuration) =>
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Falta ConnectionStrings:DefaultConnection.");

    [HttpGet("ventas-operativas")]
    [RequirePermission("CONFIGURACION.VENTAS_BOLETAS")]
    public async Task<IActionResult> GetSales(CancellationToken cancellationToken)
    {
        if (!TryGetCompanyId(out var companyId)) return Unauthorized();
        const string sql = @"
SELECT
    COALESCE((SELECT TOP (1) ValorDecimal FROM dbo.Indicador
              WHERE CompaniaId = @CompaniaId AND Area = 'VENTAS' AND TipoIndicador = 2
                AND IdIndicador IS NULL AND Descripcion = 'DESCUENTO_MAXIMO'
              ORDER BY FechaActualizacion DESC, Id DESC), 0) AS DescuentoMaximo,
    COALESCE(anulacionBoleta.ValorNum, 2) AS DiasAnulacionBoleta,
    COALESCE(anulacionFactura.ValorNum, 6) AS DiasAnulacionFactura,
    COALESCE(excluirDomingos.ValorNum, 1) AS ExcluirDomingos
FROM (SELECT CompaniaId FROM dbo.Compania WHERE CompaniaId = @CompaniaId) compania
OUTER APPLY (SELECT TOP (1) Id FROM dbo.Indicador
             WHERE CompaniaId = compania.CompaniaId AND Area = 'VENTAS'
               AND TipoIndicador = 0 AND IdIndicador IS NULL
               AND Descripcion = 'CONFIGURACION_VENTAS'
             ORDER BY Id DESC) categoria
OUTER APPLY (SELECT TOP (1) ValorNum FROM dbo.Indicador
             WHERE CompaniaId = compania.CompaniaId AND Area = 'VENTAS'
               AND TipoIndicador = 2 AND IdIndicador = categoria.Id
               AND Descripcion = 'DIAS_ANULACION_BOLETA'
             ORDER BY FechaActualizacion DESC, Id DESC) anulacionBoleta
OUTER APPLY (SELECT TOP (1) ValorNum FROM dbo.Indicador
             WHERE CompaniaId = compania.CompaniaId AND Area = 'VENTAS'
               AND TipoIndicador = 2 AND IdIndicador = categoria.Id
               AND Descripcion = 'DIAS_ANULACION_FACTURA'
             ORDER BY FechaActualizacion DESC, Id DESC) anulacionFactura
OUTER APPLY (SELECT TOP (1) ValorNum FROM dbo.Indicador
             WHERE CompaniaId = compania.CompaniaId AND Area = 'VENTAS'
               AND TipoIndicador = 1 AND IdIndicador = categoria.Id
               AND Descripcion = 'ANULACION_EXCLUIR_DOMINGOS'
             ORDER BY FechaActualizacion DESC, Id DESC) excluirDomingos;";

        await using var connection = new SqlConnection(_connectionString);
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companyId;
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) return NotFound();
        return Ok(new
        {
            descuentoMaximo = Convert.ToDecimal(reader["DescuentoMaximo"], CultureInfo.InvariantCulture),
            diasAnulacionBoleta = Convert.ToInt32(reader["DiasAnulacionBoleta"]),
            diasAnulacionFactura = Convert.ToInt32(reader["DiasAnulacionFactura"]),
            excluirDomingos = Convert.ToInt32(reader["ExcluirDomingos"]) == 1
        });
    }

    [HttpPut("ventas-operativas")]
    [RequirePermission("CONFIGURACION.VENTAS_BOLETAS")]
    public async Task<IActionResult> SaveSales([FromBody] SalesSettingsRequest request, CancellationToken cancellationToken)
    {
        if (!TryGetCompanyId(out var companyId)) return Unauthorized();
        if (request.DescuentoMaximo < 0 || request.DescuentoMaximo > 9999999999999999.99m)
            return BadRequest(new { message = "El descuento máximo debe ser un importe válido mayor o igual a S/ 0." });
        if (request.DiasAnulacionBoleta is < 0 or > 365 || request.DiasAnulacionFactura is < 0 or > 365)
            return BadRequest(new { message = "Los plazos de anulación deben estar entre 0 y 365 días." });

        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);
        if (await CountAsync(connection, transaction, "SELECT COUNT(1) FROM dbo.Compania WHERE CompaniaId = @CompaniaId", companyId, null, cancellationToken) == 0)
            return NotFound();

        await UpsertRootAsync(connection, transaction, companyId, "VENTAS", "DESCUENTO_MAXIMO", 2, null, null, request.DescuentoMaximo, cancellationToken);
        var categoryId = await EnsureSalesCategoryAsync(connection, transaction, companyId, cancellationToken);
        await UpsertChildAsync(connection, transaction, companyId, categoryId, "DIAS_ANULACION_BOLETA", 2, request.DiasAnulacionBoleta, cancellationToken);
        await UpsertChildAsync(connection, transaction, companyId, categoryId, "DIAS_ANULACION_FACTURA", 2, request.DiasAnulacionFactura, cancellationToken);
        await UpsertChildAsync(connection, transaction, companyId, categoryId, "ANULACION_EXCLUIR_DOMINGOS", 1, request.ExcluirDomingos ? 1 : 0, cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return NoContent();
    }

    [HttpGet("renovaciones")]
    [RequirePermission("CONFIGURACION.FACTURACION")]
    public async Task<IActionResult> GetRenewals(CancellationToken cancellationToken)
    {
        if (!TryGetCompanyId(out var companyId)) return Unauthorized();
        const string sql = @"
SELECT clave.Descripcion, indicador.ValorTexto1
FROM (SELECT 'RENOVACION_OSE' AS Descripcion
      UNION ALL SELECT 'RENOVACION_FIRMA'
      UNION ALL SELECT 'RENOVACION_SOME') clave
LEFT JOIN dbo.Indicador indicador
  ON indicador.CompaniaId = @CompaniaId
 AND indicador.Area = 'CONFIGURACION'
 AND indicador.TipoIndicador = 3
 AND indicador.IdIndicador IS NULL
 AND indicador.Descripcion = clave.Descripcion;";
        await using var connection = new SqlConnection(_connectionString);
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companyId;
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var values = new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase);
        while (await reader.ReadAsync(cancellationToken))
            values[reader.GetString(0)] = reader.IsDBNull(1) ? null : reader.GetString(1).Trim();
        return Ok(new
        {
            renovacionOse = values.GetValueOrDefault("RENOVACION_OSE"),
            renovacionFirma = values.GetValueOrDefault("RENOVACION_FIRMA"),
            renovacionSome = values.GetValueOrDefault("RENOVACION_SOME")
        });
    }

    [HttpPut("renovaciones")]
    [RequirePermission("CONFIGURACION.FACTURACION")]
    public async Task<IActionResult> SaveRenewals([FromBody] RenewalSettingsRequest request, CancellationToken cancellationToken)
    {
        if (!TryGetCompanyId(out var companyId)) return Unauthorized();
        Dictionary<string, string?> values;
        try
        {
            values = new Dictionary<string, string?>
            {
                ["RENOVACION_OSE"] = NormalizeDate(request.RenovacionOse),
                ["RENOVACION_FIRMA"] = NormalizeDate(request.RenovacionFirma),
                ["RENOVACION_SOME"] = NormalizeDate(request.RenovacionSome)
            };
        }
        catch (ArgumentException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        await using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);
        if (await CountAsync(connection, transaction, "SELECT COUNT(1) FROM dbo.Compania WHERE CompaniaId = @CompaniaId", companyId, null, cancellationToken) == 0)
            return NotFound();
        foreach (var (key, value) in values)
            await UpsertRootAsync(connection, transaction, companyId, "CONFIGURACION", key, 3, value, null, null, cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return NoContent();
    }

    private async Task<int> EnsureSalesCategoryAsync(SqlConnection connection, SqlTransaction transaction, int companyId, CancellationToken cancellationToken)
    {
        var count = await CountAsync(connection, transaction,
            "SELECT COUNT(1) FROM dbo.Indicador WHERE CompaniaId = @CompaniaId AND Area = 'VENTAS' AND TipoIndicador = 0 AND IdIndicador IS NULL AND Descripcion = 'CONFIGURACION_VENTAS'",
            companyId, null, cancellationToken);
        if (count > 1) throw new InvalidOperationException("La categoría CONFIGURACION_VENTAS está duplicada para esta compañía.");
        if (count == 1)
        {
            await using var read = new SqlCommand(@"SELECT TOP (1) Id FROM dbo.Indicador WITH (UPDLOCK, HOLDLOCK)
WHERE CompaniaId = @CompaniaId AND Area = 'VENTAS' AND TipoIndicador = 0 AND IdIndicador IS NULL AND Descripcion = 'CONFIGURACION_VENTAS' ORDER BY Id;", connection, transaction);
            read.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companyId;
            return Convert.ToInt32(await read.ExecuteScalarAsync(cancellationToken));
        }
        await using var insert = new SqlCommand(@"INSERT INTO dbo.Indicador (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1)
VALUES (@CompaniaId, 'VENTAS', 0, NULL, 'CONFIGURACION_VENTAS', 'Configuración de ventas');
SELECT CAST(SCOPE_IDENTITY() AS int);", connection, transaction);
        insert.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companyId;
        return Convert.ToInt32(await insert.ExecuteScalarAsync(cancellationToken));
    }

    private static async Task UpsertRootAsync(SqlConnection connection, SqlTransaction transaction, int companyId, string area, string description, int type, string? text, int? number, decimal? decimalValue, CancellationToken cancellationToken)
    {
        var count = await CountAsync(connection, transaction,
            "SELECT COUNT(1) FROM dbo.Indicador WHERE CompaniaId = @CompaniaId AND Area = @Area AND TipoIndicador = @TipoIndicador AND IdIndicador IS NULL AND Descripcion = @Descripcion",
            companyId, description, cancellationToken, area, type);
        if (count > 1) throw new InvalidOperationException($"El indicador {description} está duplicado para esta compañía.");
        var sql = count == 0
            ? @"INSERT INTO dbo.Indicador (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum, ValorDecimal, FechaActualizacion)
VALUES (@CompaniaId, @Area, @TipoIndicador, NULL, @Descripcion, @ValorTexto1, @ValorNum, @ValorDecimal, GETDATE());"
            : @"UPDATE dbo.Indicador WITH (UPDLOCK, HOLDLOCK)
SET ValorTexto1 = @ValorTexto1, ValorNum = @ValorNum, ValorDecimal = @ValorDecimal, FechaActualizacion = GETDATE()
WHERE CompaniaId = @CompaniaId AND Area = @Area AND TipoIndicador = @TipoIndicador AND IdIndicador IS NULL AND Descripcion = @Descripcion;";
        await using var command = new SqlCommand(sql, connection, transaction);
        AddIndicatorParameters(command, companyId, area, type, description, text, number, decimalValue);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task UpsertChildAsync(SqlConnection connection, SqlTransaction transaction, int companyId, int parentId, string description, int type, int value, CancellationToken cancellationToken)
    {
        var count = await CountAsync(connection, transaction,
            "SELECT COUNT(1) FROM dbo.Indicador WHERE CompaniaId = @CompaniaId AND Area = 'VENTAS' AND TipoIndicador = @TipoIndicador AND IdIndicador = @ParentId AND Descripcion = @Descripcion",
            companyId, description, cancellationToken, null, type, parentId);
        if (count > 1) throw new InvalidOperationException($"El indicador {description} está duplicado para esta compañía.");
        var sql = count == 0
            ? @"INSERT INTO dbo.Indicador (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorNum, FechaActualizacion)
VALUES (@CompaniaId, 'VENTAS', @TipoIndicador, @ParentId, @Descripcion, @ValorNum, GETDATE());"
            : @"UPDATE dbo.Indicador WITH (UPDLOCK, HOLDLOCK)
SET ValorNum = @ValorNum, FechaActualizacion = GETDATE()
WHERE CompaniaId = @CompaniaId AND Area = 'VENTAS' AND TipoIndicador = @TipoIndicador AND IdIndicador = @ParentId AND Descripcion = @Descripcion;";
        await using var command = new SqlCommand(sql, connection, transaction);
        command.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companyId;
        command.Parameters.Add("@ParentId", SqlDbType.Int).Value = parentId;
        command.Parameters.Add("@TipoIndicador", SqlDbType.Int).Value = type;
        command.Parameters.Add("@Descripcion", SqlDbType.VarChar, 500).Value = description;
        command.Parameters.Add("@ValorNum", SqlDbType.Int).Value = value;
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static void AddIndicatorParameters(SqlCommand command, int companyId, string area, int type, string description, string? text, int? number, decimal? decimalValue)
    {
        command.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companyId;
        command.Parameters.Add("@Area", SqlDbType.VarChar, 100).Value = area;
        command.Parameters.Add("@TipoIndicador", SqlDbType.Int).Value = type;
        command.Parameters.Add("@Descripcion", SqlDbType.VarChar, 500).Value = description;
        command.Parameters.Add("@ValorTexto1", SqlDbType.VarChar, -1).Value = (object?)text ?? DBNull.Value;
        command.Parameters.Add("@ValorNum", SqlDbType.Int).Value = (object?)number ?? DBNull.Value;
        var parameter = command.Parameters.Add("@ValorDecimal", SqlDbType.Decimal);
        parameter.Precision = 18;
        parameter.Scale = 2;
        parameter.Value = (object?)decimalValue ?? DBNull.Value;
    }

    private static async Task<int> CountAsync(SqlConnection connection, SqlTransaction transaction, string sql, int companyId, string? description, CancellationToken cancellationToken, string? area = null, int? type = null, int? parentId = null)
    {
        await using var command = new SqlCommand(sql, connection, transaction);
        command.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companyId;
        if (description is not null) command.Parameters.Add("@Descripcion", SqlDbType.VarChar, 500).Value = description;
        if (area is not null) command.Parameters.Add("@Area", SqlDbType.VarChar, 100).Value = area;
        if (type.HasValue) command.Parameters.Add("@TipoIndicador", SqlDbType.Int).Value = type.Value;
        if (parentId.HasValue) command.Parameters.Add("@ParentId", SqlDbType.Int).Value = parentId.Value;
        return Convert.ToInt32(await command.ExecuteScalarAsync(cancellationToken));
    }

    private bool TryGetCompanyId(out int companyId) =>
        int.TryParse(User.FindFirstValue("companiaId"), out companyId) && companyId > 0;

    private static string? NormalizeDate(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        return DateTime.TryParseExact(value.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsed)
            ? parsed.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
            : throw new ArgumentException("Las fechas deben tener el formato yyyy-MM-dd.");
    }
}

public sealed class SalesSettingsRequest
{
    public decimal DescuentoMaximo { get; set; }
    public int DiasAnulacionBoleta { get; set; }
    public int DiasAnulacionFactura { get; set; }
    public bool ExcluirDomingos { get; set; }
}

public sealed class RenewalSettingsRequest
{
    public string? RenovacionOse { get; set; }
    public string? RenovacionFirma { get; set; }
    public string? RenovacionSome { get; set; }
}
