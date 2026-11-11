using System.Data;
using System.Globalization;
using System.Xml.Linq;
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
        => await ConsultarCodigos(new[] { codigo ?? "" }, fechaInicio, fechaFin, ct);

    public sealed record ConsultaLoteRequest(string[]? Codigos, DateTime? FechaInicio, DateTime? FechaFin);

    [HttpPost("lote")]
    public async Task<IActionResult> ConsultarLote([FromBody] ConsultaLoteRequest request, CancellationToken ct)
        => await ConsultarCodigos(request.Codigos ?? Array.Empty<string>(), request.FechaInicio, request.FechaFin, ct);

    [HttpPost("kardex/lote")]
    public async Task<IActionResult> ConsultarKardexLote([FromBody] ConsultaLoteRequest request, CancellationToken ct)
        => await ConsultarReporte(request, "InventarioKardexLote.sql", ct);

    [HttpPost("reprocesar-reporte")]
    public async Task<IActionResult> ReprocesarReporte([FromBody] ConsultaLoteRequest request, CancellationToken ct)
        => await ConsultarReporte(request, "InventarioReprocesarReporte.sql", ct);

    private async Task<IActionResult> ConsultarReporte(ConsultaLoteRequest request, string sqlResource, CancellationToken ct)
    {
        var codes = (request.Codigos ?? Array.Empty<string>()).Select(code => code?.Trim() ?? "")
            .Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
        if (codes.Length is 0 or > 2000 || codes.Any(code => code.Length is 0 or > 297)
            || request.FechaInicio is not DateTime from || request.FechaFin is not DateTime to
            || from.Date > to.Date || to.Date == DateTime.MaxValue.Date)
            return BadRequest(new { mensaje = "Seleccione productos y un rango de fechas válido." });
        if (!TrySources(out var sources))
            return StatusCode(503, new { mensaje = "Las bases de ICA y COMAS no están configuradas." });

        using var sql = new StreamReader(typeof(InventarioVistaPreviaController).Assembly
            .GetManifestResourceStream(sqlResource)!);
        var query = await sql.ReadToEndAsync();
        var xml = new XElement("codigos", codes.Select(code => new XElement("codigo", code))).ToString(SaveOptions.DisableFormatting);
        var movements = new List<KardexMovement>();
        var coverage = new List<object>();
        foreach (var source in sources)
        {
            await using var connection = new SqlConnection(source.ConnectionString);
            await using var command = new SqlCommand(query, connection) { CommandTimeout = 120 };
            command.Parameters.Add("@Codigos", SqlDbType.Xml).Value = xml;
            command.Parameters.Add("@Desde", SqlDbType.Date).Value = from.Date;
            command.Parameters.Add("@Hasta", SqlDbType.Date).Value = to.Date;
            await connection.OpenAsync(ct);
            await using var reader = await command.ExecuteReaderAsync(ct);
            while (await reader.ReadAsync(ct))
            {
                movements.Add(new KardexMovement(
                    Text(reader, "CodigoBase"), Text(reader, "Codigo"), source.Name == "COMAS" ? "0000" : "0001",
                    ((DateTime)reader["Fecha"]).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                    Text(reader, "Tipo"), Text(reader, "Serie"), Text(reader, "Numero"), Text(reader, "Operacion"),
                    Text(reader, "Descripcion"), (decimal)reader["Entrada"], (decimal)reader["CostoEntrada"],
                    (decimal)reader["TotalEntrada"], (decimal)reader["Salida"], (decimal)reader["CostoSalida"],
                    (decimal)reader["TotalSalida"], (decimal)reader["CostoSaldo"]));
            }
            await reader.NextResultAsync(ct);
            await reader.ReadAsync(ct);
            coverage.Add(new { sede = source.Name, desde = Day(reader["Desde"]), hasta = Day(reader["Hasta"]) });
        }
        // InformeKardex insertaba COMAS antes de ICA y ordenaba por día e ID.
        return Ok(new {
            movimientos = movements.OrderBy(row => row.Fecha, StringComparer.Ordinal),
            cobertura = coverage,
            origen = sqlResource == "InventarioReprocesarReporte.sql" ? "reprocesado" : "registrado"
        });
    }

    private async Task<IActionResult> ConsultarCodigos(string[] input, DateTime? fechaInicio, DateTime? fechaFin, CancellationToken ct)
    {
        if (!TrySources(out var sources)) return StatusCode(503, new { mensaje = "Las bases de ICA y COMAS no están configuradas para la vista previa." });
        var codes = input.Select(code => code?.Trim() ?? "").Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
        if (codes.Length == 0 || codes.Length > 2000 || codes.Any(code => string.IsNullOrEmpty(code) || code.Length > 297) || !fechaInicio.HasValue || !fechaFin.HasValue || fechaInicio.Value.Date > fechaFin.Value.Date || fechaFin.Value.Date == DateTime.MaxValue.Date)
            return BadRequest(new { mensaje = "Seleccione un producto y un rango de fechas válido." });
        var xml = new XDocument(new XElement("codigos", codes.Select(code => new XElement("codigo", code)))).ToString(SaveOptions.DisableFormatting);
        var rows = new List<PreviewMovement>();
        foreach (var source in sources)
        {
            await using var connection = new SqlConnection(source.ConnectionString);
            await using var command = new SqlCommand("""
                DECLARE @CodigosTabla TABLE (Codigo varchar(300) PRIMARY KEY);
                INSERT INTO @CodigosTabla (Codigo)
                SELECT DISTINCT p.Prefijo + x.n.value('(./text())[1]', 'varchar(297)')
                  FROM @Codigos.nodes('/codigos/codigo') AS x(n)
                  CROSS JOIN (VALUES (''), ('191'), ('201'), ('211'), ('221'), ('231'), ('241'), ('251')) AS p(Prefijo);
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
                 WHERE p.ProductoCodigo IN (SELECT Codigo FROM @CodigosTabla)
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
                 WHERE p.ProductoCodigo IN (SELECT Codigo FROM @CodigosTabla)
                   AND c.CompraEmision >= @Desde AND c.CompraEmision < DATEADD(day, 1, @Hasta)
                """, connection) { CommandTimeout = 120 };
            command.Parameters.Add("@Codigos", SqlDbType.Xml).Value = xml;
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
    private static string? Day(object value) => value is DateTime date ? date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) : null;
    private sealed record Source(string Name, string ConnectionString);
    private sealed record PreviewProduct(string Codigo, string Descripcion, List<string> Codigos);
    private sealed record PreviewMovement(string Sede, string Anexo, string Origen, string TipoCodigo, string Operacion, long DocumentoId, long DetalleId, string Fecha, string FechaHora, string Serie, string Numero, string Codigo, string Descripcion, decimal? Cantidad, decimal? Precio, string Estado, string EstadoSunat, bool IncluidoScript, bool IncluidoConsolidado);
    private sealed record KardexMovement(string CodigoBase, string Codigo, string Anexo, string Fecha, string Tipo,
        string Serie, string Numero, string Operacion, string Descripcion, decimal Entrada, decimal CostoEntrada,
        decimal TotalEntrada, decimal Salida, decimal CostoSalida, decimal TotalSalida, decimal CostoSaldo);
}
