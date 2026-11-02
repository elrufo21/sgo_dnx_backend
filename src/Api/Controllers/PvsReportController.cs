using System.Data;
using System.Globalization;
using Ecommerce.Api.Security;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[RequirePermission("VENTAS.VER")]
public sealed class PvsReportController : ControllerBase
{
    private readonly IConfiguration _configuration;
    public PvsReportController(IConfiguration configuration) => _configuration = configuration;

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] long clienteId, [FromQuery] DateOnly? fechaInicio,
        [FromQuery] DateOnly? fechaFin, CancellationToken cancellationToken)
    {
        if (clienteId <= 0 || !fechaInicio.HasValue || !fechaFin.HasValue || fechaInicio > fechaFin)
            return BadRequest(new { mensaje = "Seleccione un cliente y un rango de fechas válido." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { mensaje = "No se encontró la cadena de conexión." });

        await using var connection = new SqlConnection(connectionString);
        await using var command = new SqlCommand("""
            SELECT n.NotaId, n.NotaFechaPago, n.NotaTransaccion, c.ClienteCodigo, c.ClienteRazon,
                   CAST(COALESCE(SUM(d.DetallePV), 0) AS decimal(19, 2)) AS PV,
                   CAST(COALESCE(SUM(d.DetalleSV), 0) AS decimal(19, 2)) AS SV,
                   CAST(n.NotaPagar AS decimal(19, 2)) AS Importe
            FROM dbo.NotaPedido n
            INNER JOIN dbo.Cliente c ON c.ClienteId = n.ClienteId
            INNER JOIN dbo.DetallePedido d ON d.NotaId = n.NotaId
            WHERE n.ClienteId = @ClienteId AND n.NotaEstado = 'CANCELADO'
              AND n.NotaFechaPago >= @FechaInicio AND n.NotaFechaPago <= @FechaFin
            GROUP BY n.NotaId, n.NotaFechaPago, n.NotaTransaccion, c.ClienteCodigo, c.ClienteRazon, n.NotaPagar
            ORDER BY n.NotaId DESC
            """, connection);
        var clientParameter = command.Parameters.Add("@ClienteId", SqlDbType.Decimal);
        clientParameter.Precision = 20;
        clientParameter.Scale = 0;
        clientParameter.Value = clienteId;
        command.Parameters.Add("@FechaInicio", SqlDbType.Date).Value = fechaInicio.Value.ToDateTime(TimeOnly.MinValue);
        command.Parameters.Add("@FechaFin", SqlDbType.Date).Value = fechaFin.Value.ToDateTime(TimeOnly.MinValue);
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var rows = new List<PvsReportRow>();
        while (await reader.ReadAsync(cancellationToken))
            rows.Add(new PvsReportRow(
                Convert.ToInt64(reader["NotaId"], CultureInfo.InvariantCulture),
                Convert.ToDateTime(reader["NotaFechaPago"], CultureInfo.InvariantCulture).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                reader["NotaTransaccion"]?.ToString() ?? "", reader["ClienteCodigo"]?.ToString() ?? "",
                reader["ClienteRazon"]?.ToString() ?? "",
                Convert.ToDecimal(reader["PV"], CultureInfo.InvariantCulture),
                Convert.ToDecimal(reader["SV"], CultureInfo.InvariantCulture),
                reader["Importe"] is DBNull ? 0 : Convert.ToDecimal(reader["Importe"], CultureInfo.InvariantCulture)));
        return Ok(rows);
    }
}

public sealed record PvsReportRow(long NotaId, string Fecha, string Transaccion, string Codigo,
    string Cliente, decimal Pv, decimal Sv, decimal Importe);
