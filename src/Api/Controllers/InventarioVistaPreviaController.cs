using System.Data;
using System.Globalization;
using Ecommerce.Api.Security;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

// Esta vista consulta documentos de origen; no ejecuta el reproceso ni escribe Kardex.
[ApiController]
[Route("api/v1/[controller]")]
[RequirePermission("CONTABILIDAD.VER")]
public sealed class InventarioVistaPreviaController : ControllerBase
{
    private static readonly string[] Prefijos = { "191", "201", "211", "221", "231", "241", "251" };
    private readonly IConfiguration _config;
    public InventarioVistaPreviaController(IConfiguration config) => _config = config;

    [HttpGet("productos")]
    public async Task<IActionResult> Productos(CancellationToken ct)
    {
        if (!TrySources(out var sources)) return StatusCode(503, new { mensaje = "Las bases de ICA y COMAS no están configuradas para la vista previa." });
        var products = new Dictionary<string, PreviewProduct>(StringComparer.OrdinalIgnoreCase);
        foreach (var source in sources)
        {
            await using var connection = new SqlConnection(source.ConnectionString);
            await using var command = new SqlCommand("""
                SELECT ProductoCodigo, ProductoNombre FROM dbo.Producto
                 WHERE ProductoEstado = 'BUENO' AND ProductoINV = 'S'
                   AND NULLIF(LTRIM(RTRIM(ProductoCodigo)), '') IS NOT NULL
                 ORDER BY ProductoCodigo, IdProducto
                """, connection);
            await connection.OpenAsync(ct);
            await using var reader = await command.ExecuteReaderAsync(ct);
            while (await reader.ReadAsync(ct))
            {
                var code = Text(reader, "ProductoCodigo");
                var key = BaseCode(code);
                if (!products.TryGetValue(key, out var product))
                    products[key] = product = new PreviewProduct(key, Text(reader, "ProductoNombre"), new List<string>());
                var variant = $"{source.Name}: {code}";
                if (!product.Codigos.Contains(variant, StringComparer.OrdinalIgnoreCase)) product.Codigos.Add(variant);
            }
        }
        return Ok(products.Values.OrderBy(p => p.Codigo, StringComparer.OrdinalIgnoreCase));
    }

    [HttpGet]
    public async Task<IActionResult> Consultar([FromQuery] string? codigo, [FromQuery] DateTime? fechaInicio, [FromQuery] DateTime? fechaFin, CancellationToken ct)
    {
        if (!TrySources(out var sources)) return StatusCode(503, new { mensaje = "Las bases de ICA y COMAS no están configuradas para la vista previa." });
        codigo = codigo?.Trim();
        if (string.IsNullOrEmpty(codigo) || codigo.Length > 297 || !fechaInicio.HasValue || !fechaFin.HasValue || fechaInicio.Value.Date > fechaFin.Value.Date || fechaFin.Value.Date == DateTime.MaxValue.Date)
            return BadRequest(new { mensaje = "Seleccione un producto y un rango de fechas válido." });

        var codes = new[] { codigo }.Concat(Prefijos.Select(prefix => prefix + codigo)).ToArray();
        var rows = new List<PreviewMovement>();
        foreach (var source in sources)
        {
            await using var connection = new SqlConnection(source.ConnectionString);
            await using var command = new SqlCommand("""
                SELECT 'DOCUMENTO' AS Origen, d.DocuId AS DocumentoId, dd.DetalleId,
                       d.DocuEmision AS Fecha, d.TipoCodigo, d.DocuSerie AS Serie, d.DocuNumero AS Numero,
                       d.DocuEstado AS Estado, d.EstadoSunat, d.DocuTotal AS TotalDocumento,
                       p.ProductoCodigo AS Codigo, p.ProductoNombre AS Descripcion,
                       dd.DetalleCantidad AS Cantidad, dd.DetallPrecio AS Precio,
                       CASE WHEN cli.ClienteId IS NULL THEN 0 ELSE 1 END AS ContraparteExiste,
                       CASE WHEN sub.IdSubLinea IS NULL THEN 0 ELSE 1 END AS SublineaExiste
                  FROM dbo.DocumentoVenta d
                  INNER JOIN dbo.DetalleDocumento dd ON dd.DocuId = d.DocuId
                  INNER JOIN dbo.Producto p ON p.IdProducto = dd.IdProducto
                  LEFT JOIN dbo.Cliente cli ON cli.ClienteId = d.ClienteId
                  LEFT JOIN dbo.Sublinea sub ON sub.IdSubLinea = p.IdSubLinea
                 WHERE p.ProductoCodigo IN (@c0,@c1,@c2,@c3,@c4,@c5,@c6,@c7)
                   AND d.DocuEmision >= @Desde AND d.DocuEmision < DATEADD(day, 1, @Hasta)
                UNION ALL
                SELECT 'COMPRA', c.CompraId, dc.DetalleId, c.CompraEmision, c.TipoCodigo,
                       c.CompraSerie, c.CompraNumero, c.CompraEstado, '', c.CompraTotal,
                       p.ProductoCodigo, p.ProductoNombre, dc.DetalleCantidad, dc.PrecioCosto,
                       CASE WHEN prov.ProveedorId IS NULL THEN 0 ELSE 1 END,
                       CASE WHEN sub.IdSubLinea IS NULL THEN 0 ELSE 1 END
                  FROM dbo.Compras c
                  INNER JOIN dbo.DetalleCompra dc ON dc.CompraId = c.CompraId
                  INNER JOIN dbo.Producto p ON p.IdProducto = dc.IdProducto
                  LEFT JOIN dbo.Proveedor prov ON prov.ProveedorId = c.ProveedorId
                  LEFT JOIN dbo.Sublinea sub ON sub.IdSubLinea = p.IdSubLinea
                 WHERE p.ProductoCodigo IN (@c0,@c1,@c2,@c3,@c4,@c5,@c6,@c7)
                   AND c.CompraEmision >= @Desde AND c.CompraEmision < DATEADD(day, 1, @Hasta)
                """, connection) { CommandTimeout = 120 };
            for (var i = 0; i < codes.Length; i++) command.Parameters.Add($"@c{i}", SqlDbType.VarChar, 300).Value = codes[i];
            command.Parameters.Add("@Desde", SqlDbType.DateTime).Value = fechaInicio.Value.Date;
            command.Parameters.Add("@Hasta", SqlDbType.DateTime).Value = fechaFin.Value.Date;
            await connection.OpenAsync(ct);
            await using var reader = await command.ExecuteReaderAsync(ct);
            while (await reader.ReadAsync(ct))
            {
                var origin = Text(reader, "Origen");
                var type = Text(reader, "TipoCodigo");
                var status = Text(reader, "Estado");
                var sunat = Text(reader, "EstadoSunat");
                var isPurchase = origin == "COMPRA";
                var date = Convert.ToDateTime(reader["Fecha"], CultureInfo.InvariantCulture);
                var counterpartyExists = Convert.ToInt32(reader["ContraparteExiste"], CultureInfo.InvariantCulture) == 1;
                var candidate = counterpartyExists && date.Year is >= 2020 and <= 2026 && (isPurchase ? type == "01" : status.Equals("EMITIDO", StringComparison.OrdinalIgnoreCase)
                    && (sunat.Equals("ENVIADO", StringComparison.OrdinalIgnoreCase) || sunat.Equals("PENDIENTE", StringComparison.OrdinalIgnoreCase))
                    && Amount(reader, "TotalDocumento") is decimal total && total != 0);
                var consolidated = candidate && Convert.ToInt32(reader["SublineaExiste"], CultureInfo.InvariantCulture) == 1 && (isPurchase || type != "07");
                var operation = isPurchase ? "Compra" : type == "07" ? "Nota de crédito" : type is "01" or "03" ? "Venta" : "Otro documento";
                rows.Add(new PreviewMovement(source.Name, source.Name == "COMAS" ? "0000" : "0001", origin, type, operation,
                    Convert.ToInt64(reader["DocumentoId"], CultureInfo.InvariantCulture), Convert.ToInt64(reader["DetalleId"], CultureInfo.InvariantCulture),
                    date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                    date.ToString("yyyy-MM-ddTHH:mm:ss.fffffff", CultureInfo.InvariantCulture),
                    Text(reader, "Serie"), Text(reader, "Numero"), Text(reader, "Codigo"), Text(reader, "Descripcion"),
                    Amount(reader, "Cantidad"), Amount(reader, "Precio"), status, sunat, candidate, consolidated));
            }
        }
        return Ok(rows.OrderBy(r => r.Fecha).ThenBy(r => r.Sede).ThenBy(r => r.FechaHora).ThenBy(r => r.Origen == "DOCUMENTO" ? 0 : 1).ThenBy(r => r.DetalleId));
    }

    private bool TrySources(out Source[] sources)
    {
        sources = Array.Empty<Source>();
        var comas = _config["InventarioVistaPrevia:BaseComas"]?.Trim();
        var ica = _config["InventarioVistaPrevia:BaseIca"]?.Trim();
        var connection = _config.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connection) || string.IsNullOrWhiteSpace(comas) || string.IsNullOrWhiteSpace(ica) || comas.Equals(ica, StringComparison.OrdinalIgnoreCase)) return false;
        sources = new[] {
            new Source("COMAS", new SqlConnectionStringBuilder(connection) { InitialCatalog = comas }.ConnectionString),
            new Source("ICA", new SqlConnectionStringBuilder(connection) { InitialCatalog = ica }.ConnectionString)
        };
        return true;
    }

    private static string BaseCode(string code) => Prefijos.Any(prefix => code.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)) && code.Length > 3 ? code[3..] : code;
    private static string Text(SqlDataReader reader, string name) => reader[name] == DBNull.Value ? "" : Convert.ToString(reader[name], CultureInfo.InvariantCulture)?.Trim() ?? "";
    private static decimal? Amount(SqlDataReader reader, string name) => reader[name] == DBNull.Value ? null : Convert.ToDecimal(reader[name], CultureInfo.InvariantCulture);
    private sealed record Source(string Name, string ConnectionString);
    private sealed record PreviewProduct(string Codigo, string Descripcion, List<string> Codigos);
    private sealed record PreviewMovement(string Sede, string Anexo, string Origen, string TipoCodigo, string Operacion, long DocumentoId, long DetalleId, string Fecha, string FechaHora, string Serie, string Numero, string Codigo, string Descripcion, decimal? Cantidad, decimal? Precio, string Estado, string EstadoSunat, bool IncluidoScript, bool IncluidoConsolidado);
}
