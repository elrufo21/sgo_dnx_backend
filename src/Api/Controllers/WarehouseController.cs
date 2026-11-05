using Ecommerce.Api.Security;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/warehouse")]
[RequirePermission("MANTENIMIENTO.PRODUCTOS")]
public sealed class WarehouseController : ControllerBase
{
    private readonly IConfiguration _configuration;
    public WarehouseController(IConfiguration configuration) => _configuration = configuration;

    [HttpGet("units-per-box")]
    public async Task<IActionResult> UnitsPerBox(CancellationToken cancellationToken)
    {
        const string sql = "SELECT IdProducto, ProductoxCaja FROM dbo.Producto";
        await using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await using var command = new SqlCommand(sql, connection);
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var items = new List<object>();
        while (await reader.ReadAsync(cancellationToken))
        {
            var boxSize = reader.IsDBNull(1) ? (decimal?)null : Convert.ToDecimal(reader.GetValue(1));
            items.Add(new { productId = Convert.ToInt64(reader.GetValue(0)), unitsPerBox = boxSize });
        }
        return Ok(items);
    }
}
