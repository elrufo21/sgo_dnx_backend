using System.Data;
using System.Globalization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public sealed class ObsCaptureController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public ObsCaptureController(IConfiguration configuration) => _configuration = configuration;

    [HttpGet]
    public async Task<IActionResult> Listar(
        [FromQuery] DateOnly fechaInicio,
        [FromQuery] DateOnly fechaFin,
        [FromQuery] string? tipoVenta,
        CancellationToken cancellationToken)
    {
        if (fechaInicio > fechaFin)
            return BadRequest(new { ok = false, mensaje = "La fecha inicio no puede ser mayor que la fecha fin." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        var tipo = NormalizarTipo(tipoVenta);
        var items = new List<ObsCaptureRow>();
        await using var con = new SqlConnection(connectionString);
        await using var cmd = new SqlCommand("""
            SELECT T.ID, CONVERT(char(10), T.FechaTransaccion, 23) AS Fecha,
                   T.NotaTransaccion, T.CodigoMiembro, T.NombreMiembro, T.Importe,
                   ISNULL(N.NotaUsuario, 'NO EXISTE') AS Usuario,
                   ISNULL(N.NotaEstado, 'NO EXISTE') AS Estado,
                   ISNULL(CONVERT(varchar(30), N.CajaId), 'NO EXISTE') AS CajaId
              FROM TABLAOBS T
              LEFT JOIN NotaPedido N ON N.NotaTransaccion = T.NotaTransaccion
             WHERE T.TipoVenta = @TipoVenta
               AND T.FechaTransaccion BETWEEN @FechaInicio AND @FechaFin
             ORDER BY T.FechaTransaccion, T.ID;
            """, con);
        cmd.Parameters.Add("@FechaInicio", SqlDbType.Date).Value = fechaInicio.ToDateTime(TimeOnly.MinValue);
        cmd.Parameters.Add("@FechaFin", SqlDbType.Date).Value = fechaFin.ToDateTime(TimeOnly.MinValue);
        cmd.Parameters.Add("@TipoVenta", SqlDbType.NVarChar, 3).Value = tipo;

        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            items.Add(new ObsCaptureRow(
                Convert.ToInt64(reader["ID"], CultureInfo.InvariantCulture),
                reader["Fecha"]?.ToString() ?? string.Empty,
                reader["NotaTransaccion"]?.ToString() ?? string.Empty,
                reader["CodigoMiembro"]?.ToString() ?? string.Empty,
                reader["NombreMiembro"]?.ToString() ?? string.Empty,
                Convert.ToDecimal(reader["Importe"], CultureInfo.InvariantCulture),
                reader["Usuario"]?.ToString() ?? string.Empty,
                reader["Estado"]?.ToString() ?? string.Empty,
                reader["CajaId"]?.ToString() ?? string.Empty));
        }

        return Ok(items);
    }

    [HttpPost]
    public async Task<IActionResult> Guardar(
        [FromBody] ObsCaptureRequest? request,
        CancellationToken cancellationToken)
    {
        var tipo = NormalizarTipo(request?.TipoVenta);
        var lines = request?.Lines?
            .Where(line => line is not null)
            .Select(line => new ObsCaptureLine(
                line.Fecha,
                (line.NotaTransaccion ?? string.Empty).Trim(),
                (line.CodigoMiembro ?? string.Empty).Trim(),
                (line.NombreMiembro ?? string.Empty).Trim(),
                line.Importe))
            .Where(line => line.Fecha != default && line.NotaTransaccion.Length > 0 && line.Importe > 0)
            .GroupBy(line => line.NotaTransaccion, StringComparer.OrdinalIgnoreCase)
            .Select(group => group.Last())
            .ToList() ?? new List<ObsCaptureLine>();

        if (lines.Count == 0)
            return BadRequest(new { ok = false, mensaje = $"No se recibieron transacciones {tipo} válidas." });
        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        await using var con = new SqlConnection(connectionString);
        await con.OpenAsync(cancellationToken);
        await using var tx = (SqlTransaction)await con.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);

        foreach (var line in lines)
        {
            await using var cmd = new SqlCommand("""
                UPDATE TABLAOBS
                   SET FechaTransaccion = @Fecha,
                       CodigoMiembro = @Codigo,
                       NombreMiembro = @Miembro,
                       Importe = @Importe,
                       TipoVenta = @TipoVenta
                 WHERE NotaTransaccion = @Transaccion;
                IF @@ROWCOUNT = 0
                    INSERT INTO TABLAOBS
                        (FechaTransaccion, NotaTransaccion, CodigoMiembro, NombreMiembro, Importe, TipoVenta)
                    VALUES (@Fecha, @Transaccion, @Codigo, @Miembro, @Importe, @TipoVenta);
                """, con, tx);
            cmd.Parameters.Add("@Fecha", SqlDbType.Date).Value = line.Fecha.ToDateTime(TimeOnly.MinValue);
            cmd.Parameters.Add("@Transaccion", SqlDbType.VarChar, 250).Value = line.NotaTransaccion;
            cmd.Parameters.Add("@Codigo", SqlDbType.VarChar, 80).Value = line.CodigoMiembro;
            cmd.Parameters.Add("@Miembro", SqlDbType.NVarChar, 140).Value = line.NombreMiembro;
            cmd.Parameters.Add("@TipoVenta", SqlDbType.NVarChar, 3).Value = tipo;
            var importe = cmd.Parameters.Add("@Importe", SqlDbType.Decimal);
            importe.Precision = 18;
            importe.Scale = 2;
            importe.Value = line.Importe;
            await cmd.ExecuteNonQueryAsync(cancellationToken);
        }

        await tx.CommitAsync(cancellationToken);
        return Ok(new { ok = true, cantidad = lines.Count, mensaje = $"Datos {tipo} actualizados correctamente." });
    }

    private static string NormalizarTipo(string? tipo) =>
        string.Equals(tipo?.Trim(), "IOC", StringComparison.OrdinalIgnoreCase) ? "IOC" : "OBS";
}

public sealed record ObsCaptureRequest(List<ObsCaptureLine>? Lines, string? TipoVenta);
public sealed record ObsCaptureLine(DateOnly Fecha, string NotaTransaccion, string CodigoMiembro, string NombreMiembro, decimal Importe);
public sealed record ObsCaptureRow(long Id, string Fecha, string NotaTransaccion, string CodigoMiembro, string NombreMiembro, decimal Importe, string Usuario, string Estado, string CajaId);
