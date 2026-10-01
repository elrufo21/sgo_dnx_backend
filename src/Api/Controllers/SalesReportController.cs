using System.Data;
using Ecommerce.Api.Security;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[RequirePermission("VENTAS.VER")]
public sealed class SalesReportController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public SalesReportController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    [HttpGet("monthly")]
    public async Task<IActionResult> Monthly([FromQuery] int year, CancellationToken cancellationToken)
    {
        if (year < 1753 || year > DateTime.Today.Year)
            return BadRequest(new { mensaje = "El año debe estar entre 1753 y el año actual." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { mensaje = "No se encontró la cadena de conexión." });

        const string sql = """
            WITH Meses AS (
                SELECT * FROM (VALUES
                    (1, N'Enero'), (2, N'Febrero'), (3, N'Marzo'), (4, N'Abril'),
                    (5, N'Mayo'), (6, N'Junio'), (7, N'Julio'), (8, N'Agosto'),
                    (9, N'Septiembre'), (10, N'Octubre'), (11, N'Noviembre'), (12, N'Diciembre')
                ) AS M(Numero, Nombre)
            ), Ventas AS (
                SELECT MONTH(NotaFecha) AS Numero, SUM(NotaPagar) AS Total
                FROM NotaPedido
                WHERE NotaFecha >= @Inicio AND NotaFecha < @Fin
                  AND NotaEstado = 'CANCELADO'
                GROUP BY MONTH(NotaFecha)
            )
            SELECT M.Numero, M.Nombre, COALESCE(V.Total, 0) AS Total
            FROM Meses M LEFT JOIN Ventas V ON V.Numero = M.Numero
            ORDER BY M.Numero;
            """;

        var months = new List<object>(12);
        decimal total = 0;
        await using var connection = new SqlConnection(connectionString);
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.Add("@Inicio", SqlDbType.DateTime).Value = new DateTime(year, 1, 1);
        command.Parameters.Add("@Fin", SqlDbType.DateTime).Value = new DateTime(year + 1, 1, 1);

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var amount = reader.GetDecimal(2);
            total += amount;
            months.Add(new { month = reader.GetInt32(0), monthName = reader.GetString(1), total = amount });
        }

        return Ok(new { year, total, months });
    }

    [HttpGet("products/monthly")]
    public async Task<IActionResult> ProductMonthly(
        [FromQuery] int year,
        [FromQuery] long productId,
        CancellationToken cancellationToken)
    {
        if (year < 1753 || year > DateTime.Today.Year)
            return BadRequest(new { mensaje = "El año debe estar entre 1753 y el año actual." });
        if (productId <= 0)
            return BadRequest(new { mensaje = "Seleccione un producto válido." });

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            return StatusCode(500, new { mensaje = "No se encontró la cadena de conexión." });

        const string sql = """
            WITH Meses AS (
                SELECT * FROM (VALUES
                    (1, N'Enero'), (2, N'Febrero'), (3, N'Marzo'), (4, N'Abril'),
                    (5, N'Mayo'), (6, N'Junio'), (7, N'Julio'), (8, N'Agosto'),
                    (9, N'Septiembre'), (10, N'Octubre'), (11, N'Noviembre'), (12, N'Diciembre')
                ) AS M(Numero, Nombre)
            ), Ventas AS (
                SELECT MONTH(N.NotaFecha) AS Numero,
                       SUM(ISNULL(D.DetalleCantidad, 0) *
                           CASE WHEN ISNULL(D.ValorUM, 0) > 0 THEN D.ValorUM ELSE 1 END) AS Cantidad,
                       SUM(ISNULL(D.DetalleImporte, 0)) AS Importe
                FROM NotaPedido N
                INNER JOIN DetallePedido D ON D.NotaId = N.NotaId
                WHERE N.NotaFecha >= @Inicio AND N.NotaFecha < @Fin
                  AND N.NotaEstado = 'CANCELADO'
                  AND N.NotaConcepto = 'MERCADERIA'
                  AND D.IdProducto = @ProductoId
                GROUP BY MONTH(N.NotaFecha)
            )
            SELECT P.IdProducto, P.ProductoNombre, P.ProductoUM,
                   M.Numero, M.Nombre,
                   COALESCE(V.Cantidad, 0) AS Cantidad,
                   COALESCE(V.Importe, 0) AS Importe
            FROM Producto P
            CROSS JOIN Meses M
            LEFT JOIN Ventas V ON V.Numero = M.Numero
            WHERE P.IdProducto = @ProductoId
            ORDER BY M.Numero;
            """;

        var months = new List<object>(12);
        string? productName = null;
        string? productUnit = null;
        decimal totalQuantity = 0;
        decimal totalSales = 0;
        await using var connection = new SqlConnection(connectionString);
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.Add("@Inicio", SqlDbType.DateTime).Value = new DateTime(year, 1, 1);
        command.Parameters.Add("@Fin", SqlDbType.DateTime).Value = new DateTime(year + 1, 1, 1);
        command.Parameters.Add("@ProductoId", SqlDbType.BigInt).Value = productId;

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            productName ??= reader["ProductoNombre"]?.ToString();
            productUnit ??= reader["ProductoUM"]?.ToString();
            var quantity = Convert.ToDecimal(reader["Cantidad"], System.Globalization.CultureInfo.InvariantCulture);
            var amount = Convert.ToDecimal(reader["Importe"], System.Globalization.CultureInfo.InvariantCulture);
            totalQuantity += quantity;
            totalSales += amount;
            months.Add(new
            {
                month = reader.GetInt32(3),
                monthName = reader.GetString(4),
                quantity,
                amount
            });
        }

        if (productName is null)
            return NotFound(new { mensaje = "No se encontró el producto seleccionado." });

        return Ok(new { year, productId, productName, productUnit, totalQuantity, totalSales, months });
    }
}
