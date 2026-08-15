using System.Data;
using System.Globalization;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public sealed class CashFlowController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public CashFlowController(IConfiguration configuration) => _configuration = configuration;

    [HttpGet(Name = "GetCashFlows")]
    public async Task<IActionResult> Listar(CancellationToken cancellationToken)
    {
        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        var items = new List<CashFlowResponse>();
        await using var con = new SqlConnection(connectionString);
        await using var cmd = new SqlCommand("uspListarCajaWEB", con)
        {
            CommandType = CommandType.StoredProcedure
        };

        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            items.Add(new CashFlowResponse(
                Convert.ToInt64(reader["CajaId"], CultureInfo.InvariantCulture),
                reader["FechaApertura"]?.ToString() ?? string.Empty,
                reader["FechaCierre"]?.ToString() ?? string.Empty,
                Convert.ToDecimal(reader["MontoInicial"], CultureInfo.InvariantCulture),
                reader["Encargado"]?.ToString() ?? string.Empty,
                reader["Usuario"]?.ToString() ?? string.Empty,
                reader["Estado"]?.ToString() ?? string.Empty,
                reader["Observacion"]?.ToString() ?? string.Empty));
        }

        return Ok(items);
    }

    [HttpPost("open", Name = "OpenCashFlow")]
    public async Task<IActionResult> Abrir(
        [FromBody] OpenCashFlowRequest request,
        CancellationToken cancellationToken)
    {
        if (request.UsuarioId <= 0 || string.IsNullOrWhiteSpace(request.Encargado) || string.IsNullOrWhiteSpace(request.Usuario))
            return BadRequest(new { ok = false, mensaje = "No se pudo identificar al usuario que abre la caja." });
        if (request.MontoInicial < 0)
            return BadRequest(new { ok = false, mensaje = "El monto inicial no puede ser negativo." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        await using var con = new SqlConnection(connectionString);
        await con.OpenAsync(cancellationToken);

        var data = string.Join("|", new[]
        {
            "0", string.Empty,
            request.MontoInicial.ToString("0.00", CultureInfo.InvariantCulture),
            CajaField(request.Encargado), CajaField(request.Usuario), "ACTIVO",
            "0.00", "0.00", "0.00", "0.00",
            request.UsuarioId.ToString(CultureInfo.InvariantCulture), CajaField(request.Observacion)
        });
        var raw = await EjecutarCajaInsertaCsvAsync(con, null, data, cancellationToken);
        if (!string.Equals(raw, "true", StringComparison.OrdinalIgnoreCase))
            return Conflict(new { ok = false, mensaje = MensajeCajaInserta(raw) });

        await using var cajaCmd = new SqlCommand("""
            SELECT TOP 1 CajaId FROM Caja
             WHERE UsuarioId = @UsuarioId AND CajaEstado = 'ACTIVO'
             ORDER BY CajaId DESC
            """, con);
        cajaCmd.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = request.UsuarioId;
        var cajaId = Convert.ToInt64(await cajaCmd.ExecuteScalarAsync(cancellationToken), CultureInfo.InvariantCulture);
        return Ok(new { ok = true, cajaId, mensaje = "Caja abierta correctamente." });
    }

    [HttpGet("active/{usuarioId:int}", Name = "GetActiveCashFlow")]
    public async Task<IActionResult> ObtenerActiva(int usuarioId, CancellationToken cancellationToken)
    {
        if (usuarioId <= 0)
            return BadRequest(new { ok = false, mensaje = "No se pudo identificar al usuario." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        await using var con = new SqlConnection(connectionString);
        await using var cmd = new SqlCommand("uspObtenerCajaActivaWEB", con)
        {
            CommandType = CommandType.StoredProcedure
        };
        cmd.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;

        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
            return Ok(null);

        var monedas = new List<CashCountResponse>();
        var response = new ActiveCashFlowResponse(
            Convert.ToInt64(reader["CajaId"], CultureInfo.InvariantCulture),
            reader["FechaApertura"]?.ToString() ?? string.Empty,
            Convert.ToDecimal(reader["MontoInicial"], CultureInfo.InvariantCulture),
            reader["Encargado"]?.ToString() ?? string.Empty,
            reader["Usuario"]?.ToString() ?? string.Empty,
            reader["Observacion"]?.ToString() ?? string.Empty,
            Convert.ToDecimal(reader["VentasEfectivo"], CultureInfo.InvariantCulture),
            Convert.ToDecimal(reader["VentasTarjeta"], CultureInfo.InvariantCulture),
            Convert.ToDecimal(reader["VentasDeposito"], CultureInfo.InvariantCulture),
            Convert.ToDecimal(reader["Salidas"], CultureInfo.InvariantCulture),
            Convert.ToDecimal(reader["EfectivoEsperado"], CultureInfo.InvariantCulture),
            monedas);

        if (await reader.NextResultAsync(cancellationToken))
        {
            while (await reader.ReadAsync(cancellationToken))
            {
                monedas.Add(new CashCountResponse(
                    Convert.ToDecimal(reader["Billete"], CultureInfo.InvariantCulture),
                    Convert.ToInt32(reader["Cantidad"], CultureInfo.InvariantCulture)));
            }
        }

        return Ok(response);
    }

    [HttpPost("{cajaId:long}/close", Name = "CloseCashFlow")]
    public async Task<IActionResult> Cerrar(
        long cajaId,
        [FromBody] CloseCashFlowRequest request,
        CancellationToken cancellationToken)
    {
        if (cajaId <= 0 || request.UsuarioId <= 0)
            return BadRequest(new { ok = false, mensaje = "No se pudo identificar la caja o el usuario." });
        if (request.Monedas is null || request.Monedas.Count == 0 || request.Monedas.Any(x => x.Billete <= 0 || x.Cantidad < 0))
            return BadRequest(new { ok = false, mensaje = "Ingrese un conteo válido para las denominaciones." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        await using var con = new SqlConnection(connectionString);
        await con.OpenAsync(cancellationToken);
        await using var tx = (SqlTransaction)await con.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);

        var caja = await ObtenerCajaParaCierreAsync(con, tx, cajaId, request.UsuarioId, cancellationToken);
        if (caja is null)
            return Conflict(new { ok = false, mensaje = "La caja ya no está disponible para cerrar." });

        var efectivoContado = request.Monedas.Sum(x => x.Billete * x.Cantidad);
        foreach (var moneda in request.Monedas)
        {
            await using var monedaCmd = new SqlCommand("""
                UPDATE Monedas
                   SET Efectivo = @Cantidad, Monto = @Monto
                 WHERE CajaId = @CajaId AND Billete = @Billete
                """, con, tx);
            monedaCmd.Parameters.Add("@Cantidad", SqlDbType.Int).Value = moneda.Cantidad;
            var monto = monedaCmd.Parameters.Add("@Monto", SqlDbType.Decimal);
            monto.Precision = 18;
            monto.Scale = 2;
            monto.Value = moneda.Billete * moneda.Cantidad;
            monedaCmd.Parameters.Add("@CajaId", SqlDbType.Decimal).Value = cajaId;
            monedaCmd.Parameters["@CajaId"].Precision = 38;
            monedaCmd.Parameters["@CajaId"].Scale = 0;
            var billete = monedaCmd.Parameters.Add("@Billete", SqlDbType.Decimal);
            billete.Precision = 18;
            billete.Scale = 2;
            billete.Value = moneda.Billete;
            await monedaCmd.ExecuteNonQueryAsync(cancellationToken);
        }

        var data = string.Join("|", new[]
        {
            cajaId.ToString(CultureInfo.InvariantCulture),
            DateTime.Now.ToString("dd/MM/yyyy H:mm:ss", CultureInfo.InvariantCulture),
            caja.MontoInicial.ToString("0.00", CultureInfo.InvariantCulture),
            CajaField(caja.Encargado), CajaField(caja.Usuario), "CERRADA",
            caja.Ingresos.ToString("0.00", CultureInfo.InvariantCulture),
            caja.Depositos.ToString("0.00", CultureInfo.InvariantCulture),
            caja.Salidas.ToString("0.00", CultureInfo.InvariantCulture),
            efectivoContado.ToString("0.00", CultureInfo.InvariantCulture),
            request.UsuarioId.ToString(CultureInfo.InvariantCulture), CajaField(request.Observacion)
        });
        var raw = await EjecutarCajaInsertaCsvAsync(con, tx, data, cancellationToken);
        if (!string.Equals(raw, "true", StringComparison.OrdinalIgnoreCase))
        {
            await tx.RollbackAsync(cancellationToken);
            return Conflict(new { ok = false, mensaje = MensajeCajaInserta(raw) });
        }

        await tx.CommitAsync(cancellationToken);
        var diferencia = efectivoContado - caja.EfectivoEsperado;
        return Ok(new
        {
            ok = true,
            cajaId,
            efectivoEsperado = caja.EfectivoEsperado,
            efectivoContado,
            diferencia,
            mensaje = "Caja cerrada correctamente."
        });
    }

    private static async Task<string> EjecutarCajaInsertaCsvAsync(
        SqlConnection con,
        SqlTransaction? tx,
        string data,
        CancellationToken cancellationToken)
    {
        await using var cmd = new SqlCommand("uspCajaInsertaCsv", con, tx)
        {
            CommandType = CommandType.StoredProcedure
        };
        cmd.Parameters.Add("@Data", SqlDbType.VarChar, -1).Value = data;
        return (await cmd.ExecuteScalarAsync(cancellationToken))?.ToString()?.Trim() ?? string.Empty;
    }

    private static async Task<CajaCloseInfo?> ObtenerCajaParaCierreAsync(
        SqlConnection con,
        SqlTransaction tx,
        long cajaId,
        int usuarioId,
        CancellationToken cancellationToken)
    {
        await using var cmd = new SqlCommand("""
            SELECT c.MontoIniSOl, c.CajaEncargado, c.CajaUsuario,
                   ISNULL((SELECT SUM(ISNULL(n.Efectivo, 0))
                             FROM NotaPedido n
                            WHERE n.CajaId = c.CajaId AND ISNULL(n.NotaEstado, '') <> 'ANULADO'), 0) AS Ingresos,
                   ISNULL((SELECT SUM(ISNULL(n.Deposito, 0))
                             FROM NotaPedido n
                            WHERE n.CajaId = c.CajaId AND ISNULL(n.NotaEstado, '') <> 'ANULADO'), 0) AS Depositos,
                   ISNULL((SELECT SUM(ISNULL(d.DetalleMonto, 0))
                             FROM CajaDetalle d
                            WHERE d.CajaId = c.CajaId AND d.DetalleMovimiento = 'SALIDA' AND ISNULL(d.NotaId, 0) = 0), 0) AS Salidas
              FROM Caja c WITH (UPDLOCK, HOLDLOCK)
             WHERE c.CajaId = @CajaId AND c.UsuarioId = @UsuarioId AND c.CajaEstado = 'ACTIVO'
            """, con, tx);
        cmd.Parameters.Add("@CajaId", SqlDbType.Decimal).Value = cajaId;
        cmd.Parameters["@CajaId"].Precision = 38;
        cmd.Parameters["@CajaId"].Scale = 0;
        cmd.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;

        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) return null;
        var montoInicial = Convert.ToDecimal(reader["MontoIniSOl"], CultureInfo.InvariantCulture);
        var ingresos = Convert.ToDecimal(reader["Ingresos"], CultureInfo.InvariantCulture);
        var salidas = Convert.ToDecimal(reader["Salidas"], CultureInfo.InvariantCulture);
        return new CajaCloseInfo(
            montoInicial,
            reader["CajaEncargado"]?.ToString() ?? string.Empty,
            reader["CajaUsuario"]?.ToString() ?? string.Empty,
            ingresos,
            Convert.ToDecimal(reader["Depositos"], CultureInfo.InvariantCulture),
            salidas,
            montoInicial + ingresos - salidas);
    }

    private static string CajaField(string? value) => (value ?? string.Empty).Replace('|', ' ').Trim();

    private static string MensajeCajaInserta(string raw) => raw.ToUpperInvariant() switch
    {
        "EXISTE" => "Ya existe una caja abierta para este usuario.",
        "NO CERRO" => "No se puede abrir otra caja porque hay cajas pendientes de cierre.",
        _ => string.IsNullOrWhiteSpace(raw) ? "No se pudo registrar la caja." : raw
    };

    private sealed record CajaCloseInfo(
        decimal MontoInicial,
        string Encargado,
        string Usuario,
        decimal Ingresos,
        decimal Depositos,
        decimal Salidas,
        decimal EfectivoEsperado);
}

public sealed record OpenCashFlowRequest(
    int UsuarioId,
    string Encargado,
    string Usuario,
    decimal MontoInicial,
    string? Observacion);

public sealed record CashFlowResponse(
    long CajaId,
    string FechaApertura,
    string FechaCierre,
    decimal MontoInicial,
    string Encargado,
    string Usuario,
    string Estado,
    string Observacion);

public sealed record ActiveCashFlowResponse(
    long CajaId,
    string FechaApertura,
    decimal MontoInicial,
    string Encargado,
    string Usuario,
    string Observacion,
    decimal VentasEfectivo,
    decimal VentasTarjeta,
    decimal VentasDeposito,
    decimal Salidas,
    decimal EfectivoEsperado,
    List<CashCountResponse> Monedas);

public sealed record CashCountResponse(decimal Billete, int Cantidad);

public sealed record CloseCashFlowRequest(int UsuarioId, string? Observacion, List<CashCountRequest>? Monedas);

public sealed record CashCountRequest(
    [property: JsonPropertyName("denominacion")] decimal Billete,
    int Cantidad);
