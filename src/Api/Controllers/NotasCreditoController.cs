using System.Data;
using System.Globalization;
using System.Security.Claims;
using Ecommerce.Api.Security;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Ecommerce.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[RequirePermission("CONTABILIDAD.VER")]
public sealed class NotasCreditoController : ControllerBase
{
    private readonly IConfiguration _configuration;
    public NotasCreditoController(IConfiguration configuration) => _configuration = configuration;

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] DateTime? fechaInicio, [FromQuery] DateTime? fechaFin, CancellationToken ct)
    {
        if (!TryCompany(out var companyId)) return Forbid();
        if (!fechaInicio.HasValue || !fechaFin.HasValue || fechaInicio.Value.Date > fechaFin.Value.Date || fechaFin.Value.Date == DateTime.MaxValue.Date)
            return BadRequest(new { mensaje = "Seleccione un rango de fechas válido." });

        await using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await using var command = new SqlCommand("""
            SELECT d.DocuId, d.DocuSerie, d.DocuNumero, d.DocuEmision, d.DocuNroGuia,
                   d.DocuConcepto, d.DocuEstado, d.EstadoSunat, d.DocuUsuario,
                   d.DocuSubTotal, d.DocuIgv, d.DocuTotal,
                   c.ClienteRazon, c.ClienteRuc, c.ClienteDni,
                   original.DocuSerie AS OriginalSerie, original.DocuNumero AS OriginalNumero
              FROM dbo.DocumentoVenta d
              LEFT JOIN dbo.Cliente c ON c.ClienteId = d.ClienteId
              LEFT JOIN dbo.DocumentoVenta original ON original.DocuId =
                   CASE WHEN LTRIM(RTRIM(d.DocuAsociado)) NOT LIKE '%[^0-9]%' AND LEN(LTRIM(RTRIM(d.DocuAsociado))) BETWEEN 1 AND 38
                        THEN CONVERT(decimal(38,0), LTRIM(RTRIM(d.DocuAsociado))) END AND original.CompaniaId = d.CompaniaId
             WHERE d.CompaniaId = @CompaniaId AND d.TipoCodigo = '07'
               AND d.DocuEmision >= @Desde AND d.DocuEmision < DATEADD(day, 1, @Hasta)
             ORDER BY d.DocuEmision DESC, d.DocuId DESC
            """, connection);
        command.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companyId;
        command.Parameters.Add("@Desde", SqlDbType.DateTime).Value = fechaInicio.Value.Date;
        command.Parameters.Add("@Hasta", SqlDbType.DateTime).Value = fechaFin.Value.Date;
        await connection.OpenAsync(ct);
        await using var reader = await command.ExecuteReaderAsync(ct);
        var items = new List<object>();
        while (await reader.ReadAsync(ct)) items.Add(MapHeader(reader));
        return Ok(items);
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> Obtener(long id, CancellationToken ct)
    {
        if (!TryCompany(out var companyId)) return Forbid();
        await using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await connection.OpenAsync(ct);
        await using var schemaCommand = new SqlCommand("SELECT COL_LENGTH('dbo.DetalleDocumento', 'DetalleDescripcion')", connection);
        var hasDetailDescription = await schemaCommand.ExecuteScalarAsync(ct) is not DBNull;
        var detailDescription = hasDetailDescription ? "NULLIF(LTRIM(RTRIM(dd.DetalleDescripcion)), '')" : "NULL";
        await using var command = new SqlCommand($"""
            SELECT d.DocuId, d.DocuSerie, d.DocuNumero, d.DocuEmision, d.DocuNroGuia,
                   d.DocuConcepto, d.DocuEstado, d.EstadoSunat, d.DocuUsuario,
                   d.DocuSubTotal, d.DocuIgv, d.DocuTotal,
                   c.ClienteRazon, c.ClienteRuc, c.ClienteDni,
                   original.DocuSerie AS OriginalSerie, original.DocuNumero AS OriginalNumero,
                   original.NotaId AS OriginalNotaId
              FROM dbo.DocumentoVenta d
              LEFT JOIN dbo.Cliente c ON c.ClienteId = d.ClienteId
              OUTER APPLY (
                   SELECT MIN(o.DocuId) AS DocuId FROM dbo.DocumentoVenta o
                   WHERE o.CompaniaId = d.CompaniaId AND o.TipoCodigo IN ('01', '03')
                     AND NULLIF(LTRIM(RTRIM(d.DocuNroGuia)), '') = CONCAT(LTRIM(RTRIM(o.DocuSerie)), '-', LTRIM(RTRIM(o.DocuNumero)))
                   HAVING COUNT(*) = 1
              ) ref
              LEFT JOIN dbo.DocumentoVenta original ON original.DocuId = COALESCE(
                   CASE WHEN LTRIM(RTRIM(d.DocuAsociado)) NOT LIKE '%[^0-9]%' AND LEN(LTRIM(RTRIM(d.DocuAsociado))) BETWEEN 1 AND 38 THEN NULLIF(CONVERT(decimal(38,0), LTRIM(RTRIM(d.DocuAsociado))), 0) END,
                   ref.DocuId)
                   AND original.CompaniaId = d.CompaniaId AND original.TipoCodigo IN ('01', '03')
             WHERE d.DocuId = @Id AND d.CompaniaId = @CompaniaId AND d.TipoCodigo = '07';
            SELECT dd.DetalleId, COALESCE(p.ProductoCodigo, matched.ProductoCodigo) AS ProductoCodigo,
                   COALESCE({detailDescription}, p.ProductoNombre, matched.ProductoNombre) AS ProductoNombre,
                   dd.DetalleCantidad, dd.DetallPrecio, dd.DetalleImporte
              FROM dbo.DetalleDocumento dd
              INNER JOIN dbo.DocumentoVenta d ON d.DocuId = dd.DocuId
              LEFT JOIN dbo.Producto p ON p.IdProducto = dd.IdProducto
              OUTER APPLY (
                   SELECT MIN(o.DocuId) AS DocuId FROM dbo.DocumentoVenta o
                   WHERE o.CompaniaId = d.CompaniaId AND o.TipoCodigo IN ('01', '03')
                     AND NULLIF(LTRIM(RTRIM(d.DocuNroGuia)), '') = CONCAT(LTRIM(RTRIM(o.DocuSerie)), '-', LTRIM(RTRIM(o.DocuNumero)))
                   HAVING COUNT(*) = 1
              ) ref
              LEFT JOIN dbo.DocumentoVenta original ON original.DocuId = COALESCE(
                   CASE WHEN LTRIM(RTRIM(d.DocuAsociado)) NOT LIKE '%[^0-9]%' AND LEN(LTRIM(RTRIM(d.DocuAsociado))) BETWEEN 1 AND 38 THEN NULLIF(CONVERT(decimal(38,0), LTRIM(RTRIM(d.DocuAsociado))), 0) END,
                   ref.DocuId)
                   AND original.CompaniaId = d.CompaniaId AND original.TipoCodigo IN ('01', '03')
              OUTER APPLY (
                   SELECT MIN(p2.ProductoCodigo) AS ProductoCodigo, MIN(p2.ProductoNombre) AS ProductoNombre
                   FROM dbo.DetalleDocumento source
                   INNER JOIN dbo.Producto p2 ON p2.IdProducto = source.IdProducto
                   WHERE source.DocuId = original.DocuId
                     AND source.DetalleCantidad = dd.DetalleCantidad AND source.DetallPrecio = dd.DetallPrecio
                   HAVING COUNT(*) = 1
              ) matched
             WHERE d.DocuId = @Id AND d.CompaniaId = @CompaniaId AND d.TipoCodigo = '07'
             ORDER BY dd.DetalleId;
            """, connection);
        command.Parameters.Add("@Id", SqlDbType.BigInt).Value = id;
        command.Parameters.Add("@CompaniaId", SqlDbType.Int).Value = companyId;
        await using var reader = await command.ExecuteReaderAsync(ct);
        if (!await reader.ReadAsync(ct)) return NotFound();
        var nota = MapHeader(reader);
        var ventaNotaId = reader["OriginalNotaId"] == DBNull.Value ? (long?)null : Convert.ToInt64(reader["OriginalNotaId"], CultureInfo.InvariantCulture);
        var detalles = new List<object>();
        await reader.NextResultAsync(ct);
        while (await reader.ReadAsync(ct))
            detalles.Add(new { id = Convert.ToInt64(reader["DetalleId"], CultureInfo.InvariantCulture), codigo = Text(reader, "ProductoCodigo"), descripcion = Text(reader, "ProductoNombre"), cantidad = Amount(reader, "DetalleCantidad"), precio = Amount(reader, "DetallPrecio"), importe = Amount(reader, "DetalleImporte") });
        return Ok(new { nota, detalles, ventaNotaId });
    }

    private bool TryCompany(out int id) => int.TryParse(User.FindFirstValue("companiaId"), out id) && id > 0;
    private static string Text(SqlDataReader reader, string column) => reader[column] == DBNull.Value ? "" : Convert.ToString(reader[column], CultureInfo.InvariantCulture)?.Trim() ?? "";
    private static decimal Amount(SqlDataReader reader, string column) => reader[column] == DBNull.Value ? 0 : Convert.ToDecimal(reader[column], CultureInfo.InvariantCulture);
    private static object MapHeader(SqlDataReader reader) => new
    {
        id = Convert.ToInt64(reader["DocuId"], CultureInfo.InvariantCulture),
        serie = Text(reader, "DocuSerie"), numero = Text(reader, "DocuNumero"),
        fecha = reader["DocuEmision"] == DBNull.Value ? null : Convert.ToDateTime(reader["DocuEmision"], CultureInfo.InvariantCulture).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
        referencia = Reference(reader), concepto = Text(reader, "DocuConcepto"),
        estado = Text(reader, "DocuEstado"), estadoSunat = Text(reader, "EstadoSunat"), usuario = Text(reader, "DocuUsuario"),
        cliente = Text(reader, "ClienteRazon"), ruc = Text(reader, "ClienteRuc"), dni = Text(reader, "ClienteDni"),
        subtotal = Amount(reader, "DocuSubTotal"), igv = Amount(reader, "DocuIgv"), total = Amount(reader, "DocuTotal")
    };

    private static string Reference(SqlDataReader reader)
    {
        var reference = Text(reader, "DocuNroGuia");
        if (!string.IsNullOrWhiteSpace(reference)) return reference;
        return string.Join("-", new[] { Text(reader, "OriginalSerie"), Text(reader, "OriginalNumero") }.Where(part => !string.IsNullOrWhiteSpace(part)));
    }
}
