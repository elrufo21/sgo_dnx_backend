using System.Data;
using System.Globalization;
using Ecommerce.Api.Security;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[RequirePermission("CONTABILIDAD.VER")]
public sealed class InventarioValorizadoController : ControllerBase
{
    private readonly IConfiguration _configuration;
    public InventarioValorizadoController(IConfiguration configuration) => _configuration = configuration;

    public sealed record SaldoGrupoRequest(string? Codigo, DateTime? FechaInicio, decimal? Cantidad);

    [HttpGet("saldos-iniciales")]
    public async Task<IActionResult> SaldosIniciales([FromQuery] DateTime? fechaInicio, CancellationToken ct)
    {
        if (!fechaInicio.HasValue)
            return BadRequest(new { mensaje = "Seleccione una fecha inicial válida." });
        await using var con = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await using var cmd = new SqlCommand("SELECT Codigo, Cantidad FROM dbo.InventarioSaldoInicial WHERE FechaInicio = @Inicio", con);
        cmd.Parameters.Add("@Inicio", SqlDbType.Date).Value = fechaInicio.Value.Date;
        await con.OpenAsync(ct);
        await using var reader = await cmd.ExecuteReaderAsync(ct);
        var saldos = new List<object>();
        while (await reader.ReadAsync(ct)) saldos.Add(new { codigo = Text(reader, "Codigo"), cantidad = Convert.ToDecimal(reader["Cantidad"], CultureInfo.InvariantCulture) });
        return Ok(saldos);
    }

    [HttpPut("saldos-iniciales")]
    [RequirePermission("MANTENIMIENTO.PRODUCTOS")]
    public async Task<IActionResult> GuardarSaldoGrupo([FromBody] SaldoGrupoRequest request, CancellationToken ct)
    {
        var code = request.Codigo?.Trim().ToUpperInvariant();
        if (string.IsNullOrEmpty(code) || code.Length > 297 || !request.FechaInicio.HasValue || !request.Cantidad.HasValue || request.Cantidad.Value > 90000000000000m || request.Cantidad.Value < -90000000000000m || decimal.Round(request.Cantidad.Value, 2) != request.Cantidad.Value)
            return BadRequest(new { mensaje = "Ingrese un producto, fecha inicial y cantidad válidos." });
        await using var con = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await using var cmd = new SqlCommand("""
            SET XACT_ABORT ON;
            BEGIN TRANSACTION;
            UPDATE dbo.InventarioSaldoInicial WITH (UPDLOCK, SERIALIZABLE) SET Cantidad = @Cantidad
             WHERE Codigo = @Codigo AND FechaInicio = @Inicio;
            IF @@ROWCOUNT = 0
                INSERT INTO dbo.InventarioSaldoInicial (Codigo, FechaInicio, Cantidad) VALUES (@Codigo, @Inicio, @Cantidad);
            COMMIT;
            """, con);
        cmd.Parameters.Add("@Codigo", SqlDbType.VarChar, 297).Value = code;
        cmd.Parameters.Add("@Inicio", SqlDbType.Date).Value = request.FechaInicio.Value.Date;
        var amount = cmd.Parameters.Add("@Cantidad", SqlDbType.Decimal);
        amount.Precision = 18;
        amount.Scale = 2;
        amount.Value = request.Cantidad.Value;
        await con.OpenAsync(ct);
        await cmd.ExecuteNonQueryAsync(ct);
        return Ok(new { codigo = code, cantidad = request.Cantidad.Value });
    }

    [HttpGet("productos")]
    public async Task<IActionResult> Productos(CancellationToken ct)
    {
        await using var con = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await using var cmd = new SqlCommand("""
            SELECT IdProducto, ProductoCodigo, ProductoNombre, ProductoCantidad, UltimoINV
              FROM dbo.Producto
             ORDER BY ProductoCodigo, IdProducto
            """, con);
        await con.OpenAsync(ct);
        await using var reader = await cmd.ExecuteReaderAsync(ct);
        var productos = new List<object>();
        while (await reader.ReadAsync(ct))
            productos.Add(new { id = Convert.ToInt64(reader["IdProducto"], CultureInfo.InvariantCulture), codigo = Text(reader, "ProductoCodigo"), descripcion = Text(reader, "ProductoNombre"), stockActual = reader["ProductoCantidad"] == DBNull.Value ? (decimal?)null : Convert.ToDecimal(reader["ProductoCantidad"], CultureInfo.InvariantCulture), ultimoInv = reader["UltimoINV"] == DBNull.Value ? (decimal?)null : Convert.ToDecimal(reader["UltimoINV"], CultureInfo.InvariantCulture) });
        return Ok(productos);
    }

    public sealed record SaldoInicialRequest(decimal? Cantidad);

    [HttpPut("productos/{id:long}/saldo-inicial")]
    [RequirePermission("MANTENIMIENTO.PRODUCTOS")]
    public async Task<IActionResult> GuardarSaldoInicial(long id, [FromBody] SaldoInicialRequest request, CancellationToken ct)
    {
        if (id <= 0 || (request.Cantidad.HasValue && (request.Cantidad.Value > 90000000000000m || request.Cantidad.Value < -90000000000000m || decimal.Round(request.Cantidad.Value, 2) != request.Cantidad.Value)))
            return BadRequest(new { mensaje = "Ingrese una cantidad con hasta dos decimales." });
        await using var con = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await using var cmd = new SqlCommand("UPDATE dbo.Producto SET UltimoINV = @Cantidad WHERE IdProducto = @IdProducto", con);
        cmd.Parameters.Add("@IdProducto", SqlDbType.BigInt).Value = id;
        var cantidad = cmd.Parameters.Add("@Cantidad", SqlDbType.Decimal);
        cantidad.Precision = 18;
        cantidad.Scale = 2;
        cantidad.Value = (object?)request.Cantidad ?? DBNull.Value;
        await con.OpenAsync(ct);
        if (await cmd.ExecuteNonQueryAsync(ct) == 0) return NotFound(new { mensaje = "Producto no encontrado." });
        return Ok(new { id, cantidad = request.Cantidad });
    }

    [HttpGet]
    public async Task<IActionResult> Consultar([FromQuery] long productoId, [FromQuery] DateTime? fechaInicio, [FromQuery] DateTime? fechaFin, CancellationToken ct)
    {
        if (productoId <= 0 || !fechaInicio.HasValue || !fechaFin.HasValue || fechaInicio.Value.Date > fechaFin.Value.Date || fechaFin.Value.Date == DateTime.MaxValue.Date)
            return BadRequest(new { mensaje = "Seleccione un producto y un rango de fechas válido." });

        await using var con = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await using var cmd = new SqlCommand("""
            DECLARE @Codigo varchar(80);
            SELECT @Codigo = LTRIM(RTRIM(REPLACE(REPLACE(ProductoCodigo, '191', ''), '201', '')))
              FROM dbo.Producto WHERE IdProducto = @ProductoId;
            SELECT k.KardexId, k.KardexFecha, k.TipoCodigo, k.Serie, k.KardexDocumento,
                   k.TipoOperacion, p.ProductoNombre, k.CantidadIngreso, k.CantidadSalida,
                   k.PrecioCosto, k.StockFinal, k.KadexConcepto
              FROM dbo.Kardex k
              INNER JOIN dbo.Producto p ON p.IdProducto = k.IdProducto
             WHERE (p.ProductoCodigo = @Codigo OR p.ProductoCodigo = '191' + @Codigo OR p.ProductoCodigo = '201' + @Codigo)
               AND k.KardexFecha >= @Desde AND k.KardexFecha < DATEADD(day, 1, @Hasta)
               AND k.KardexMotivo IN ('Salida por Venta', 'Ingreso por Compra') AND k.Estado = 'E'
             ORDER BY k.KardexFecha, k.KardexId
            """, con);
        cmd.Parameters.Add("@ProductoId", SqlDbType.BigInt).Value = productoId;
        cmd.Parameters.Add("@Desde", SqlDbType.DateTime).Value = fechaInicio.Value.Date;
        cmd.Parameters.Add("@Hasta", SqlDbType.DateTime).Value = fechaFin.Value.Date;
        await con.OpenAsync(ct);
        await using var reader = await cmd.ExecuteReaderAsync(ct);
        var movimientos = new List<object>();
        while (await reader.ReadAsync(ct))
        {
            var entrada = Amount(reader, "CantidadIngreso");
            var salida = Amount(reader, "CantidadSalida");
            var costo = Amount(reader, "PrecioCosto");
            var stock = Amount(reader, "StockFinal");
            var operacion = Text(reader, "TipoOperacion");
            movimientos.Add(new {
                id = Convert.ToInt64(reader["KardexId"], CultureInfo.InvariantCulture),
                fecha = reader["KardexFecha"] == DBNull.Value ? "" : Convert.ToDateTime(reader["KardexFecha"], CultureInfo.InvariantCulture).ToString("dd/MM/yyyy", CultureInfo.InvariantCulture),
                tipo = Text(reader, "TipoCodigo"), serie = Text(reader, "Serie"), numero = Text(reader, "KardexDocumento"), operacion,
                descripcion = Text(reader, "ProductoNombre"), entrada = Round(entrada), costoEntrada = operacion == "02" ? Round(costo) : 0, totalEntrada = Round(entrada * costo),
                salida = Round(salida), costoSalida = operacion == "01" ? Round(costo) : 0, totalSalida = Round(salida * costo),
                stock = Round(stock), costoSaldo = Round(costo), totalSaldo = Round(stock * costo), concepto = Text(reader, "KadexConcepto")
            });
        }
        return Ok(movimientos);
    }

    private static string Text(SqlDataReader reader, string column) => reader[column] == DBNull.Value ? "" : Convert.ToString(reader[column], CultureInfo.InvariantCulture)?.Trim() ?? "";
    private static decimal Amount(SqlDataReader reader, string column) => reader[column] == DBNull.Value ? 0 : Convert.ToDecimal(reader[column], CultureInfo.InvariantCulture);
    private static decimal Round(decimal value) => Math.Round(value, 2, MidpointRounding.AwayFromZero);
}
