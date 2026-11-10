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

    [HttpGet("productos")]
    public async Task<IActionResult> Productos(CancellationToken ct)
    {
        await using var con = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await using var cmd = new SqlCommand("""
            SELECT IdProducto, ProductoCodigo, ProductoNombre
              FROM dbo.Producto
             WHERE ProductoEstado = 'BUENO' AND ProductoINV = 'S'
             ORDER BY ProductoCodigo, IdProducto
            """, con);
        await con.OpenAsync(ct);
        await using var reader = await cmd.ExecuteReaderAsync(ct);
        var productos = new List<object>();
        while (await reader.ReadAsync(ct))
            productos.Add(new { id = Convert.ToInt64(reader["IdProducto"], CultureInfo.InvariantCulture), codigo = Text(reader, "ProductoCodigo"), descripcion = Text(reader, "ProductoNombre") });
        return Ok(productos);
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
              FROM dbo.Producto WHERE IdProducto = @ProductoId AND ProductoEstado = 'BUENO' AND ProductoINV = 'S';
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
