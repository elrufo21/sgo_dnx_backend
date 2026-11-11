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
  AND c.CompraEmision >= @Desde AND c.CompraEmision < DATEADD(day, 1, @Hasta);
