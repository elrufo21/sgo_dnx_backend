using System.Data;
using System.Globalization;
using System.Text.Json.Serialization;
using Ecommerce.Application.Contracts.Usuarios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public sealed class CashFlowController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly IUsuariosCrud _usuariosCrud;

    public CashFlowController(IConfiguration configuration, IUsuariosCrud usuariosCrud)
    {
        _configuration = configuration;
        _usuariosCrud = usuariosCrud;
    }

    [HttpGet(Name = "GetCashFlows")]
    public async Task<IActionResult> Listar(
        [FromQuery] DateOnly? fechaInicio,
        [FromQuery] DateOnly? fechaFin,
        CancellationToken cancellationToken)
    {
        if (fechaInicio.HasValue != fechaFin.HasValue)
            return BadRequest(new { ok = false, mensaje = "Seleccione fecha inicio y fecha fin." });
        if (fechaInicio > fechaFin)
            return BadRequest(new { ok = false, mensaje = "La fecha inicio no puede ser mayor que la fecha fin." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        var items = new List<CashFlowResponse>();
        await using var con = new SqlConnection(connectionString);
        await using var cmd = new SqlCommand(fechaInicio.HasValue ? "listarCajaFecha" : "listarCaja", con)
        {
            CommandType = CommandType.StoredProcedure
        };
        if (fechaInicio.HasValue)
        {
            cmd.Parameters.Add("@fechainicio", SqlDbType.Date).Value = fechaInicio.Value.ToDateTime(TimeOnly.MinValue);
            cmd.Parameters.Add("@fechafin", SqlDbType.Date).Value = fechaFin!.Value.ToDateTime(TimeOnly.MinValue);
        }

        await con.OpenAsync(cancellationToken);
        await using (var reader = await cmd.ExecuteReaderAsync(cancellationToken))
        {
            while (await reader.ReadAsync(cancellationToken))
            {
                items.Add(new CashFlowResponse(
                    Convert.ToInt64(reader["CajaId"], CultureInfo.InvariantCulture),
                    reader["CajaFecha"]?.ToString() ?? string.Empty,
                    reader["CajaCierre"]?.ToString() ?? string.Empty,
                    Convert.ToDecimal(reader["MontoIniSol"], CultureInfo.InvariantCulture),
                    Convert.ToDecimal(reader["CajaIngresos"], CultureInfo.InvariantCulture),
                    Convert.ToDecimal(reader["CajaSalidas"], CultureInfo.InvariantCulture),
                    Convert.ToDecimal(reader["CajaTotal"], CultureInfo.InvariantCulture),
                    reader["CajaEncargado"]?.ToString() ?? string.Empty,
                    reader["CajaUsuario"]?.ToString() ?? string.Empty,
                    reader["CajaEstado"]?.ToString() ?? string.Empty,
                    reader["Observacion"]?.ToString() ?? string.Empty));
            }
        }

        return Ok(items);
    }

    [HttpPost("open", Name = "OpenCashFlow")]
    public async Task<IActionResult> Abrir(
        [FromBody] OpenCashFlowRequest request,
        CancellationToken cancellationToken)
    {
        if (request.UsuarioId <= 0)
            return BadRequest(new { ok = false, mensaje = "No se pudo identificar al usuario que abre la caja." });
        if (request.MontoInicial < 0)
            return BadRequest(new { ok = false, mensaje = "El monto inicial no puede ser negativo." });

        var usuario = await _usuariosCrud.ObtenerPorIdConPersonalAsync(request.UsuarioId, cancellationToken);
        var encargado = string.Join(' ', new[]
        {
            usuario?.Personal?.PersonalNombres?.Split(' ', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault(),
            usuario?.Personal?.PersonalApellidos?.Split(' ', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault()
        }.Where(value => !string.IsNullOrWhiteSpace(value)));
        if (string.IsNullOrWhiteSpace(encargado))
            return BadRequest(new { ok = false, mensaje = "El usuario no tiene nombre y apellido paterno registrados." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        await using var con = new SqlConnection(connectionString);
        await con.OpenAsync(cancellationToken);

        var data = string.Join("|", new[]
        {
            "0", string.Empty,
            request.MontoInicial.ToString("0.00", CultureInfo.InvariantCulture),
            CajaField(encargado), CajaField(encargado), "ACTIVO",
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
            monedas,
            "ACTIVO",
            string.Empty);

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

    [HttpGet("{cajaId:long}/detail", Name = "GetCashFlowDetail")]
    public async Task<IActionResult> ObtenerDetalle(long cajaId, CancellationToken cancellationToken)
    {
        if (cajaId <= 0) return BadRequest(new { ok = false, mensaje = "Caja inválida." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        await using var con = new SqlConnection(connectionString);
        await using var cmd = new SqlCommand("""
            SELECT c.CajaId, CONVERT(varchar(19), c.CajaFecha, 126) AS FechaApertura,
                   ISNULL(c.CajaCierre, '') AS FechaCierre, ISNULL(c.CajaEstado, '') AS Estado,
                   ISNULL(c.MontoIniSOl, 0) AS MontoInicial, ISNULL(c.CajaEncargado, '') AS Encargado,
                   ISNULL(c.CajaUsuario, '') AS Usuario, ISNULL(c.Observacion, '') AS Observacion,
                   ISNULL((SELECT SUM(ISNULL(n.Efectivo, 0)) FROM NotaPedido n WHERE n.CajaId = c.CajaId AND ISNULL(n.NotaEstado, '') <> 'ANULADO'), 0) AS VentasEfectivo,
                   ISNULL((SELECT SUM(CASE WHEN UPPER(ISNULL(n.NotaFormaPago, '')) LIKE '%TARJETA%' THEN ISNULL(n.Deposito, 0) ELSE 0 END) FROM NotaPedido n WHERE n.CajaId = c.CajaId AND ISNULL(n.NotaEstado, '') <> 'ANULADO'), 0) AS VentasTarjeta,
                   ISNULL((SELECT SUM(CASE WHEN UPPER(ISNULL(n.NotaFormaPago, '')) LIKE '%TARJETA%' THEN 0 ELSE ISNULL(n.Deposito, 0) END) FROM NotaPedido n WHERE n.CajaId = c.CajaId AND ISNULL(n.NotaEstado, '') <> 'ANULADO'), 0) AS VentasDeposito,
                   ISNULL((SELECT SUM(ISNULL(T.Importe, 0)) FROM TABLAOBS T LEFT JOIN NotaPedido n ON n.NotaTransaccion = T.NotaTransaccion WHERE T.TipoVenta = 'OBS' AND n.CajaId = c.CajaId), 0) AS SistemaObs,
                   ISNULL((SELECT SUM(ISNULL(d.DetalleMonto, 0)) FROM CajaDetalle d WHERE d.CajaId = c.CajaId AND d.DetalleMovimiento = 'INGRESO' AND ISNULL(d.NotaId, 0) = 0 AND ISNULL(d.DetalleConcepto, '') NOT IN ('TOTAL EFECTIVO', 'SENCILLO')), 0) AS IngresosCajaChica,
                   ISNULL((SELECT SUM(ISNULL(d.DetalleMonto, 0)) FROM CajaDetalle d WHERE d.CajaId = c.CajaId AND d.DetalleMovimiento = 'SALIDA' AND ISNULL(d.NotaId, 0) = 0), 0) AS Salidas
              FROM Caja c
             WHERE c.CajaId = @CajaId;
            SELECT CONVERT(decimal(18,2), Billete) AS Billete, ISNULL(Efectivo, 0) AS Cantidad
              FROM Monedas WHERE CajaId = @CajaId ORDER BY CONVERT(decimal(18,2), Billete) DESC;
            """, con);
        cmd.Parameters.Add("@CajaId", SqlDbType.Decimal).Value = cajaId;
        cmd.Parameters["@CajaId"].Precision = 38;
        cmd.Parameters["@CajaId"].Scale = 0;

        await con.OpenAsync(cancellationToken);
        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) return Ok(null);

        var monedas = new List<CashCountResponse>();
        var montoInicial = Convert.ToDecimal(reader["MontoInicial"], CultureInfo.InvariantCulture);
        var sistemaObs = Convert.ToDecimal(reader["SistemaObs"], CultureInfo.InvariantCulture);
        var ventasEfectivo = Convert.ToDecimal(reader["VentasEfectivo"], CultureInfo.InvariantCulture);
        var ingresosCajaChica = Convert.ToDecimal(reader["IngresosCajaChica"], CultureInfo.InvariantCulture);
        var salidas = Convert.ToDecimal(reader["Salidas"], CultureInfo.InvariantCulture);
        var response = new ActiveCashFlowResponse(
            Convert.ToInt64(reader["CajaId"], CultureInfo.InvariantCulture), reader["FechaApertura"]?.ToString() ?? string.Empty,
            montoInicial, reader["Encargado"]?.ToString() ?? string.Empty, reader["Usuario"]?.ToString() ?? string.Empty,
            reader["Observacion"]?.ToString() ?? string.Empty, ventasEfectivo,
            Convert.ToDecimal(reader["VentasTarjeta"], CultureInfo.InvariantCulture),
            Convert.ToDecimal(reader["VentasDeposito"], CultureInfo.InvariantCulture), salidas,
            montoInicial + sistemaObs - salidas + ingresosCajaChica, monedas,
            reader["Estado"]?.ToString() ?? string.Empty,
            reader["FechaCierre"]?.ToString() ?? string.Empty);

        if (await reader.NextResultAsync(cancellationToken))
            while (await reader.ReadAsync(cancellationToken))
                monedas.Add(new CashCountResponse(Convert.ToDecimal(reader["Billete"], CultureInfo.InvariantCulture), Convert.ToInt32(reader["Cantidad"], CultureInfo.InvariantCulture)));

        return Ok(response);
    }

    [HttpGet("{cajaId:long}/products", Name = "GetCashFlowProducts")]
    public async Task<IActionResult> ListarProductos(long cajaId, CancellationToken cancellationToken)
    {
        if (cajaId <= 0) return BadRequest("Caja inválida.");

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, "No se encontró la cadena de conexión.");

        await using var con = new SqlConnection(connectionString);
        await using var cmd = new SqlCommand("listarDetaCaja", con)
        {
            CommandType = CommandType.StoredProcedure
        };
        var parameter = cmd.Parameters.Add("@CajaId", SqlDbType.Decimal);
        parameter.Precision = 38;
        parameter.Scale = 0;
        parameter.Value = cajaId;

        await con.OpenAsync(cancellationToken);
        return Ok((await cmd.ExecuteScalarAsync(cancellationToken))?.ToString() ?? "~");
    }

    [HttpGet("{cajaId:long}/movements", Name = "GetCashFlowMovements")]
    public async Task<IActionResult> ListarMovimientos(long cajaId, CancellationToken cancellationToken)
    {
        if (cajaId <= 0) return BadRequest("Caja inválida.");

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, "No se encontró la cadena de conexión.");

        await using var con = new SqlConnection(connectionString);
        await using var cmd = new SqlCommand("uspTraerGastosA", con)
        {
            CommandType = CommandType.StoredProcedure
        };
        var parameter = cmd.Parameters.Add("@CajaId", SqlDbType.Decimal);
        parameter.Precision = 38;
        parameter.Scale = 0;
        parameter.Value = cajaId;

        await con.OpenAsync(cancellationToken);
        return Ok((await cmd.ExecuteScalarAsync(cancellationToken))?.ToString() ?? "~[~[~[~");
    }

    [HttpGet("{cajaId:long}/obs-total", Name = "GetCashFlowObsTotal")]
    public async Task<IActionResult> ObtenerTotalObs(long cajaId, CancellationToken cancellationToken)
    {
        if (cajaId <= 0) return BadRequest("Caja inválida.");

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, "No se encontró la cadena de conexión.");

        await using var con = new SqlConnection(connectionString);
        await using var cmd = new SqlCommand("""
            SELECT ISNULL(SUM(T.Importe), CONVERT(decimal(18,2), 0))
              FROM TABLAOBS T
              LEFT JOIN NotaPedido n ON n.NotaTransaccion = T.NotaTransaccion
             WHERE T.TipoVenta = 'OBS' AND n.CajaId = @CajaId;
            """, con);
        var parameter = cmd.Parameters.Add("@CajaId", SqlDbType.Decimal);
        parameter.Precision = 38;
        parameter.Scale = 0;
        parameter.Value = cajaId;

        await con.OpenAsync(cancellationToken);
        var total = Convert.ToDecimal(await cmd.ExecuteScalarAsync(cancellationToken), CultureInfo.InvariantCulture);
        return Ok(new { total });
    }

    [HttpPut("{cajaId:long}/manual-income", Name = "UpdateCashFlowManualIncome")]
    public async Task<IActionResult> ActualizarIngresosManuales(
        long cajaId,
        [FromBody] UpdateCashFlowManualIncomeRequest request,
        CancellationToken cancellationToken)
    {
        if (cajaId <= 0 || request.Movimientos is null || request.Movimientos.Count == 0 ||
            request.Movimientos.Any(x => x.DetalleId <= 0 || x.Importe < 0) ||
            request.Movimientos.Select(x => x.DetalleId).Distinct().Count() != request.Movimientos.Count)
            return BadRequest(new { ok = false, mensaje = "Los importes de ingreso no son válidos." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        await using var con = new SqlConnection(connectionString);
        await con.OpenAsync(cancellationToken);
        await using var tx = (SqlTransaction)await con.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);
        foreach (var movimiento in request.Movimientos)
        {
            await using var cmd = new SqlCommand("""
                UPDATE CajaDetalle
                   SET DetalleMonto = @Importe
                 WHERE CajaId = @CajaId AND DetalleId = @DetalleId
                   AND DetalleMovimiento = 'INGRESO'
                   AND DetalleConcepto IN ('VITRINA', 'SENCILLO', 'REVISTAS', 'COPIAS Y OTROS')
                """, con, tx);
            var importe = cmd.Parameters.Add("@Importe", SqlDbType.Decimal);
            importe.Precision = 18;
            importe.Scale = 2;
            importe.Value = movimiento.Importe;
            cmd.Parameters.Add("@CajaId", SqlDbType.Decimal).Value = cajaId;
            cmd.Parameters["@CajaId"].Precision = 38;
            cmd.Parameters["@CajaId"].Scale = 0;
            cmd.Parameters.Add("@DetalleId", SqlDbType.Decimal).Value = movimiento.DetalleId;
            cmd.Parameters["@DetalleId"].Precision = 38;
            cmd.Parameters["@DetalleId"].Scale = 0;
            if (await cmd.ExecuteNonQueryAsync(cancellationToken) != 1)
            {
                await tx.RollbackAsync(cancellationToken);
                return BadRequest(new { ok = false, mensaje = "No se encontró un ingreso editable de esta caja." });
            }
        }

        await tx.CommitAsync(cancellationToken);
        return Ok(new { ok = true, mensaje = "Ingresos actualizados correctamente." });
    }

    [HttpDelete("{cajaId:long}", Name = "DeleteCashFlow")]
    public async Task<IActionResult> Eliminar(long cajaId, CancellationToken cancellationToken)
    {
        if (cajaId <= 0) return BadRequest(new { ok = false, mensaje = "Caja inválida." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        await using var con = new SqlConnection(connectionString);
        await con.OpenAsync(cancellationToken);
        await using var tx = (SqlTransaction)await con.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);

        await using (var existsCmd = new SqlCommand("SELECT 1 FROM Caja WITH (UPDLOCK, HOLDLOCK) WHERE CajaId = @CajaId", con, tx))
        {
            var parameter = existsCmd.Parameters.Add("@CajaId", SqlDbType.Decimal);
            parameter.Precision = 38;
            parameter.Scale = 0;
            parameter.Value = cajaId;
            if (await existsCmd.ExecuteScalarAsync(cancellationToken) is null)
                return NotFound(new { ok = false, mensaje = "La caja ya no existe." });
        }

        await using (var productsCmd = new SqlCommand("""
            SELECT TOP 1 1
            FROM NotaPedido n
            INNER JOIN DetallePedido d ON d.NotaId = n.NotaId
            WHERE n.CajaId = @CajaId
            """, con, tx))
        {
            var parameter = productsCmd.Parameters.Add("@CajaId", SqlDbType.Decimal);
            parameter.Precision = 38;
            parameter.Scale = 0;
            parameter.Value = cajaId;
            if (await productsCmd.ExecuteScalarAsync(cancellationToken) is not null)
                return Conflict(new { ok = false, mensaje = "Esta caja no se puede eliminar porque ya tiene productos registrados. Así protegemos las ventas realizadas." });
        }

        await using (var deleteCmd = new SqlCommand("""
            DELETE FROM CajaDetalle WHERE CajaId = @CajaId;
            DELETE FROM Monedas WHERE CajaId = @CajaId;
            DELETE FROM Caja WHERE CajaId = @CajaId;
            """, con, tx))
        {
            var parameter = deleteCmd.Parameters.Add("@CajaId", SqlDbType.Decimal);
            parameter.Precision = 38;
            parameter.Scale = 0;
            parameter.Value = cajaId;
            await deleteCmd.ExecuteNonQueryAsync(cancellationToken);
        }

        await tx.CommitAsync(cancellationToken);
        return Ok(new { ok = true, mensaje = "La caja fue eliminada correctamente." });
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

        var caja = await ObtenerCajaParaCierreAsync(con, tx, cajaId, cancellationToken);
        if (caja is null)
            return Conflict(new { ok = false, mensaje = "La caja ya no está disponible para cerrar." });
        if (request.MontoInicial is < 0)
            return BadRequest(new { ok = false, mensaje = "El sencillo no puede ser negativo." });

        var montoInicial = request.MontoInicial ?? caja.MontoInicial;
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
            montoInicial.ToString("0.00", CultureInfo.InvariantCulture),
            CajaField(caja.Encargado), CajaField(caja.Usuario), "CERRADA",
            (montoInicial + caja.Ingresos + caja.IngresosManuales).ToString("0.00", CultureInfo.InvariantCulture),
            caja.Depositos.ToString("0.00", CultureInfo.InvariantCulture),
            caja.Salidas.ToString("0.00", CultureInfo.InvariantCulture),
            efectivoContado.ToString("0.00", CultureInfo.InvariantCulture),
            caja.UsuarioId.ToString(CultureInfo.InvariantCulture), CajaField(request.Observacion)
        });
        var raw = await EjecutarCajaInsertaCsvAsync(con, tx, data, cancellationToken);
        if (!string.Equals(raw, "true", StringComparison.OrdinalIgnoreCase))
        {
            await tx.RollbackAsync(cancellationToken);
            return Conflict(new { ok = false, mensaje = MensajeCajaInserta(raw) });
        }

        await tx.CommitAsync(cancellationToken);
        var efectivoEsperado = montoInicial + caja.Ingresos + caja.IngresosManuales;
        var diferencia = efectivoContado - efectivoEsperado;
        return Ok(new
        {
            ok = true,
            cajaId,
            efectivoEsperado,
            efectivoContado,
            diferencia,
            mensaje = "Caja cerrada correctamente."
        });
    }

    [HttpPut("{cajaId:long}/state", Name = "UpdateCashFlowState")]
    public async Task<IActionResult> ActualizarEstado(
        long cajaId,
        [FromBody] UpdateCashFlowStateRequest request,
        CancellationToken cancellationToken)
    {
        var estado = request.Estado?.Trim().ToUpperInvariant();
        if (cajaId <= 0 || estado is not ("ACTIVO" or "CERRADA"))
            return BadRequest(new { ok = false, mensaje = "El estado de caja no es válido." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { ok = false, mensaje = "No se encontró la cadena de conexión." });

        await using var con = new SqlConnection(connectionString);
        await con.OpenAsync(cancellationToken);
        await using var tx = (SqlTransaction)await con.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);

        var caja = await ObtenerCajaParaActualizarAsync(con, tx, cajaId, cancellationToken);
        if (caja is null)
            return NotFound(new { ok = false, mensaje = "No se encontró la caja." });
        if (request.MontoInicial is < 0)
            return BadRequest(new { ok = false, mensaje = "El sencillo no puede ser negativo." });

        var montoInicial = request.MontoInicial ?? caja.MontoInicial;
        var observacion = request.Observacion ?? caja.Observacion;

        if (estado == "ACTIVO")
        {
            await using var validarCmd = new SqlCommand("uspValidaCantCajas", con, tx)
            {
                CommandType = CommandType.StoredProcedure
            };
            var cajaIdParameter = validarCmd.Parameters.Add("@CajaId", SqlDbType.Decimal);
            cajaIdParameter.Precision = 38;
            cajaIdParameter.Scale = 0;
            cajaIdParameter.Value = cajaId;
            validarCmd.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = caja.UsuarioId;
            var validacion = (await validarCmd.ExecuteScalarAsync(cancellationToken))?.ToString()?.Trim().ToUpperInvariant();

            if (validacion == "USUARIO_ACTIVO")
            {
                await tx.RollbackAsync(cancellationToken);
                return Conflict(new { ok = false, mensaje = "No puedes activar esta caja cerrada porque el usuario ya tiene una caja abierta." });
            }
            if (validacion == "NO CERRO")
            {
                await tx.RollbackAsync(cancellationToken);
                return Conflict(new { ok = false, mensaje = "Ya hay tres cajas abiertas. Cierra una antes de activar otra." });
            }
        }

        var data = string.Join("|", new[]
        {
            cajaId.ToString(CultureInfo.InvariantCulture), CajaField(estado == "ACTIVO" ? string.Empty : caja.FechaCierre),
            montoInicial.ToString("0.00", CultureInfo.InvariantCulture),
            CajaField(caja.Encargado), CajaField(caja.Usuario), estado,
            caja.Ingresos.ToString("0.00", CultureInfo.InvariantCulture),
            caja.Depositos.ToString("0.00", CultureInfo.InvariantCulture),
            caja.Salidas.ToString("0.00", CultureInfo.InvariantCulture),
            caja.Total.ToString("0.00", CultureInfo.InvariantCulture),
            caja.UsuarioId.ToString(CultureInfo.InvariantCulture), CajaField(observacion)
        });
        var raw = await EjecutarCajaInsertaCsvAsync(con, tx, data, cancellationToken);
        if (!string.Equals(raw, "true", StringComparison.OrdinalIgnoreCase))
        {
            await tx.RollbackAsync(cancellationToken);
            return Conflict(new { ok = false, mensaje = MensajeCajaInserta(raw) });
        }

        await tx.CommitAsync(cancellationToken);
        return Ok(new { ok = true, cajaId, estado, mensaje = "Caja actualizada correctamente." });
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
        CancellationToken cancellationToken)
    {
        await using var cmd = new SqlCommand("""
            SELECT c.MontoIniSOl, c.CajaEncargado, c.CajaUsuario, c.UsuarioId,
                   ISNULL((SELECT SUM(ISNULL(T.Importe, 0))
                             FROM TABLAOBS T
                             LEFT JOIN NotaPedido n ON n.NotaTransaccion = T.NotaTransaccion
                            WHERE T.TipoVenta = 'OBS' AND n.CajaId = c.CajaId), 0) AS SistemaObs,
                   ISNULL((SELECT SUM(ISNULL(n.Deposito, 0))
                             FROM NotaPedido n
                            WHERE n.CajaId = c.CajaId AND ISNULL(n.NotaEstado, '') <> 'ANULADO'), 0) AS Depositos,
                   ISNULL((SELECT SUM(ISNULL(d.DetalleMonto, 0))
                             FROM CajaDetalle d
                            WHERE d.CajaId = c.CajaId AND d.DetalleMovimiento = 'INGRESO'
                              AND ISNULL(d.NotaId, 0) = 0
                              AND ISNULL(d.DetalleConcepto, '') NOT IN ('TOTAL EFECTIVO', 'SENCILLO')), 0) AS IngresosManuales,
                   ISNULL((SELECT SUM(ISNULL(d.DetalleMonto, 0))
                             FROM CajaDetalle d
                            WHERE d.CajaId = c.CajaId AND d.DetalleMovimiento = 'SALIDA' AND ISNULL(d.NotaId, 0) = 0), 0) AS Salidas
              FROM Caja c WITH (UPDLOCK, HOLDLOCK)
             WHERE c.CajaId = @CajaId AND c.CajaEstado = 'ACTIVO'
            """, con, tx);
        cmd.Parameters.Add("@CajaId", SqlDbType.Decimal).Value = cajaId;
        cmd.Parameters["@CajaId"].Precision = 38;
        cmd.Parameters["@CajaId"].Scale = 0;

        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) return null;
        var montoInicial = Convert.ToDecimal(reader["MontoIniSOl"], CultureInfo.InvariantCulture);
        var sistemaObs = Convert.ToDecimal(reader["SistemaObs"], CultureInfo.InvariantCulture);
        var ingresosManuales = Convert.ToDecimal(reader["IngresosManuales"], CultureInfo.InvariantCulture);
        var salidas = Convert.ToDecimal(reader["Salidas"], CultureInfo.InvariantCulture);
        return new CajaCloseInfo(
            montoInicial,
            reader["CajaEncargado"]?.ToString() ?? string.Empty,
            reader["CajaUsuario"]?.ToString() ?? string.Empty,
            Convert.ToInt32(reader["UsuarioId"], CultureInfo.InvariantCulture),
            sistemaObs - salidas,
            ingresosManuales,
            Convert.ToDecimal(reader["Depositos"], CultureInfo.InvariantCulture),
            salidas,
            montoInicial + sistemaObs - salidas + ingresosManuales);
    }

    private static async Task<CajaUpdateInfo?> ObtenerCajaParaActualizarAsync(
        SqlConnection con,
        SqlTransaction tx,
        long cajaId,
        CancellationToken cancellationToken)
    {
        await using var cmd = new SqlCommand("""
            SELECT ISNULL(CajaCierre, '') AS CajaCierre, ISNULL(MontoIniSOl, 0) AS MontoInicial,
                   ISNULL(CajaEncargado, '') AS Encargado, ISNULL(CajaUsuario, '') AS Usuario,
                   ISNULL(CajaIngresos, 0) AS Ingresos, ISNULL(CajaDeposito, 0) AS Depositos,
                   ISNULL(CajaSalidas, 0) AS Salidas, ISNULL(CajaTotal, 0) AS Total,
                   ISNULL(UsuarioId, 0) AS UsuarioId, ISNULL(Observacion, '') AS Observacion
              FROM Caja WITH (UPDLOCK, HOLDLOCK)
             WHERE CajaId = @CajaId
            """, con, tx);
        cmd.Parameters.Add("@CajaId", SqlDbType.Decimal).Value = cajaId;
        cmd.Parameters["@CajaId"].Precision = 38;
        cmd.Parameters["@CajaId"].Scale = 0;

        await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) return null;
        return new CajaUpdateInfo(
            reader["CajaCierre"]?.ToString() ?? string.Empty,
            Convert.ToDecimal(reader["MontoInicial"], CultureInfo.InvariantCulture),
            reader["Encargado"]?.ToString() ?? string.Empty,
            reader["Usuario"]?.ToString() ?? string.Empty,
            Convert.ToDecimal(reader["Ingresos"], CultureInfo.InvariantCulture),
            Convert.ToDecimal(reader["Depositos"], CultureInfo.InvariantCulture),
            Convert.ToDecimal(reader["Salidas"], CultureInfo.InvariantCulture),
            Convert.ToDecimal(reader["Total"], CultureInfo.InvariantCulture),
            Convert.ToInt32(reader["UsuarioId"], CultureInfo.InvariantCulture),
            reader["Observacion"]?.ToString() ?? string.Empty);
    }

    private static string CajaField(string? value) => (value ?? string.Empty).Replace('|', ' ').Trim();

    private static string MensajeCajaInserta(string raw) => raw.ToUpperInvariant() switch
    {
        "EXISTE" => "Ya tienes una caja abierta. Ciérrala antes de abrir una nueva.",
        "NO CERRO" => "Hay cajas pendientes de cierre. Ciérralas antes de abrir una nueva.",
        _ => string.IsNullOrWhiteSpace(raw) ? "No se pudo registrar la caja." : raw
    };

    private sealed record CajaCloseInfo(
        decimal MontoInicial,
        string Encargado,
        string Usuario,
        int UsuarioId,
        decimal Ingresos,
        decimal IngresosManuales,
        decimal Depositos,
        decimal Salidas,
        decimal EfectivoEsperado);

    private sealed record CajaUpdateInfo(
        string FechaCierre,
        decimal MontoInicial,
        string Encargado,
        string Usuario,
        decimal Ingresos,
        decimal Depositos,
        decimal Salidas,
        decimal Total,
        int UsuarioId,
        string Observacion);
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
    decimal Ingresos,
    decimal Salidas,
    decimal Diferencia,
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
    List<CashCountResponse> Monedas,
    string Estado,
    string FechaCierre);

public sealed record CashCountResponse(decimal Billete, int Cantidad);

public sealed record CloseCashFlowRequest(int UsuarioId, decimal? MontoInicial, string? Observacion, List<CashCountRequest>? Monedas);

public sealed record UpdateCashFlowStateRequest(string? Estado, decimal? MontoInicial, string? Observacion);

public sealed record UpdateCashFlowManualIncomeRequest(List<CashFlowManualIncomeRequest>? Movimientos);

public sealed record CashFlowManualIncomeRequest(
    [property: JsonPropertyName("id")] int DetalleId,
    decimal Importe);

public sealed record CashCountRequest(
    [property: JsonPropertyName("denominacion")] decimal Billete,
    int Cantidad);
