using Ecommerce.Api.Security;
using System.Data;
using System.Globalization;
using System.Security.Claims;
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

    [HttpGet("opening")]
    public async Task<IActionResult> Opening(CancellationToken ct)
    {
        await using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await connection.OpenAsync(ct);
        await using var command = new SqlCommand("SELECT TOP (1) IdApertura, FechaApertura, Usuario FROM dbo.APERTURA_ALMACEN WHERE AperturaEstado = '0' ORDER BY IdApertura DESC", connection);
        await using var reader = await command.ExecuteReaderAsync(ct);
        if (!await reader.ReadAsync(ct)) return Ok(new { opening = (object?)null });
        return Ok(new { opening = new { id = Convert.ToInt64(reader.GetValue(0)), fecha = reader.IsDBNull(1) ? (DateTime?)null : reader.GetDateTime(1), usuario = reader.IsDBNull(2) ? "" : reader.GetString(2) } });
    }

    [HttpPost("opening")]
    public Task<IActionResult> Open([FromBody] WarehouseSave request, CancellationToken ct) => Save(request, null, ct);

    [HttpPost("opening/{id:long}/close")]
    public Task<IActionResult> Close(long id, [FromBody] WarehouseSave request, CancellationToken ct) => Save(request, id, ct);

    private async Task<IActionResult> Save(WarehouseSave request, long? openingId, CancellationToken ct)
    {
        if (!int.TryParse(User.FindFirstValue("userId"), out var userId) || userId <= 0) return Unauthorized();
        if (openingId <= 0 || request.Items is null || request.Items.Count == 0 || request.Items.Select(x => x.ProductId).Distinct().Count() != request.Items.Count || request.Items.Any(x => x.ProductId <= 0 || !Valid(x.Wholesale) || !Valid(x.Dispatch) || !Valid(x.Display)))
            return BadRequest(new { mensaje = "Revise las cantidades ingresadas." });

        await using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await connection.OpenAsync(ct);
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        await using var state = new SqlCommand("SELECT IdApertura, Observacion FROM dbo.APERTURA_ALMACEN WITH (UPDLOCK, HOLDLOCK) WHERE AperturaEstado = '0' ORDER BY IdApertura DESC", connection, transaction);
        long? activeId = null;
        string observation = "";
        await using (var reader = await state.ExecuteReaderAsync(ct))
        {
            if (await reader.ReadAsync(ct))
            {
                activeId = Convert.ToInt64(reader.GetValue(0));
                observation = reader.IsDBNull(1) ? "" : reader.GetString(1);
                if (await reader.ReadAsync(ct)) return Conflict(new { mensaje = "Existe más de una apertura pendiente; revise el almacén antes de continuar." });
            }
        }
        if (openingId != activeId) return Conflict(new { mensaje = "El estado del almacén cambió. Actualice la pantalla." });

        await using var products = new SqlCommand("SELECT IdProducto, ProductoxCaja FROM dbo.Producto", connection, transaction);
        var boxes = new Dictionary<long, decimal?>();
        await using (var reader = await products.ExecuteReaderAsync(ct))
            while (await reader.ReadAsync(ct)) boxes[Convert.ToInt64(reader.GetValue(0))] = reader.IsDBNull(1) ? null : Convert.ToDecimal(reader.GetValue(1));
        if (request.Items.Any(x => !boxes.ContainsKey(x.ProductId) || (x.Wholesale > 0 && !(boxes[x.ProductId] > 0)) || (boxes.ContainsKey(x.ProductId) && (boxes[x.ProductId] ?? 0) > 99999999)))
            return BadRequest(new { mensaje = "Hay productos inválidos o sin unidades por caja." });

        await using var user = new SqlCommand("SELECT UsuarioAlias FROM dbo.Usuarios WHERE UsuarioID = @Id", connection, transaction);
        user.Parameters.Add("@Id", SqlDbType.Int).Value = userId;
        var userName = Convert.ToString(await user.ExecuteScalarAsync(ct))?.Trim();
        if (string.IsNullOrWhiteSpace(userName)) return Unauthorized();
        if (userName.IndexOfAny(new[] { '|', '[', ']' }) >= 0 || observation.IndexOfAny(new[] { '|', '[', ']' }) >= 0)
            return Conflict(new { mensaje = "El usuario o la observación de apertura contienen caracteres no admitidos." });

        static string Number(decimal value) => value.ToString("0.00", CultureInfo.InvariantCulture);
        var rows = request.Items.Select(x =>
        {
            var box = boxes[x.ProductId] ?? 0;
            var total = decimal.Round(x.Wholesale * box + x.Dispatch + x.Display, 2, MidpointRounding.AwayFromZero);
            return $"{x.ProductId}|{Number(x.Wholesale)}|{Number(box)}|{Number(x.Dispatch)}|{Number(x.Display)}|{Number(total)}" + (openingId.HasValue ? "" : "|0.00");
        });
        var header = openingId.HasValue ? $"{userId}|{userName}|{observation}||{openingId.Value}" : $"{userId}|{userName}|";
        await using var save = new SqlCommand(openingId.HasValue ? "dbo.uspInsertarCierre" : "dbo.uspInsertarApertura", connection, transaction) { CommandType = CommandType.StoredProcedure };
        save.Parameters.Add("@ListaOrden", SqlDbType.VarChar, -1).Value = header + "[" + string.Join(";", rows);
        var result = Convert.ToString(await save.ExecuteScalarAsync(ct))?.Trim() ?? "";
        if (!result.Equals("true", StringComparison.OrdinalIgnoreCase))
            return Conflict(new { mensaje = result == "NO ASISTIO" ? "Debe registrar su asistencia antes de continuar." : result.StartsWith('[') ? "Su asistencia requiere una observación antes de continuar." : $"No se pudo registrar la operación: {result}" });
        await transaction.CommitAsync(ct);
        return Ok(new { ok = true });
    }

    private static bool Valid(decimal value) => value >= 0 && value <= 99999999 && decimal.Round(value, 2) == value;
}

public sealed class WarehouseSave { public List<WarehouseSaveItem> Items { get; set; } = new(); }
public sealed class WarehouseSaveItem { public long ProductId { get; set; } public decimal Wholesale { get; set; } public decimal Dispatch { get; set; } public decimal Display { get; set; } }
