DECLARE @Codigos xml = N'<codigos><codigo>FB007</codigo></codigos>';
DECLARE @Desde date = '20261101';
DECLARE @Hasta date = '20261106';

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
DECLARE @CodigosLote TABLE (
    Codigo varchar(300) NOT NULL,
    CodigoBase varchar(297) NOT NULL,
    PRIMARY KEY (Codigo, CodigoBase)
);
INSERT INTO @CodigosLote (Codigo, CodigoBase)
SELECT DISTINCT p.Prefijo + x.n.value('(text())[1]', 'varchar(297)'), x.n.value('(text())[1]', 'varchar(297)')
FROM @Codigos.nodes('/codigos/codigo') AS x(n)
CROSS JOIN (VALUES (''), ('191'), ('201'), ('211'), ('221'), ('231'), ('241'), ('251')) p(Prefijo);

WITH Origen AS (
    SELECT c.CodigoBase, p.ProductoCodigo AS Codigo, p.ProductoNombre AS Descripcion,
           d.DocuEmision AS Fecha, d.TipoCodigo AS Tipo, d.DocuSerie AS Serie, d.DocuNumero AS Numero,
           '01' AS Operacion, CAST(0 AS decimal(18,2)) AS Entrada,
           CAST(l.DetalleCantidad AS decimal(18,2)) AS Salida,
           CAST(l.DetallPrecio / 1.18 AS decimal(18,2)) AS Costo,
           l.DetalleId, 0 AS OrdenOrigen
    FROM dbo.DocumentoVenta d
    JOIN dbo.Cliente cli ON cli.ClienteId = d.ClienteId
    JOIN dbo.DetalleDocumento l ON l.DocuId = d.DocuId
    JOIN dbo.Producto p ON p.IdProducto = l.IdProducto
    JOIN dbo.Sublinea s ON s.IdSubLinea = p.IdSubLinea
    JOIN @CodigosLote c ON c.Codigo = p.ProductoCodigo
    WHERE d.DocuEmision >= @Desde AND d.DocuEmision < DATEADD(day, 1, @Hasta)
      AND YEAR(d.DocuEmision) BETWEEN 2020 AND 2026
      AND d.DocuEstado = 'EMITIDO' AND d.EstadoSunat IN ('ENVIADO','PENDIENTE')
      AND d.DocuTotal <> 0
      AND d.TipoCodigo <> '07'
    UNION ALL
    SELECT c.CodigoBase, p.ProductoCodigo, p.ProductoNombre, d.CompraEmision,
           d.TipoCodigo, d.CompraSerie, d.CompraNumero, '02',
           CAST(l.DetalleCantidad AS decimal(18,2)), CAST(0 AS decimal(18,2)),
           CAST(l.PrecioCosto / 1.18 AS decimal(18,2)), l.DetalleId, 1
    FROM dbo.Compras d
    JOIN dbo.Proveedor prov ON prov.ProveedorId = d.ProveedorId
    JOIN dbo.DetalleCompra l ON l.CompraId = d.CompraId
    JOIN dbo.Producto p ON p.IdProducto = l.IdProducto
    JOIN dbo.Sublinea s ON s.IdSubLinea = p.IdSubLinea
    JOIN @CodigosLote c ON c.Codigo = p.ProductoCodigo
    WHERE d.CompraEmision >= @Desde AND d.CompraEmision < DATEADD(day, 1, @Hasta)
      AND YEAR(d.CompraEmision) BETWEEN 2020 AND 2026 AND d.TipoCodigo = '01'
)
SELECT CodigoBase, Codigo, Descripcion, Fecha, Tipo, Serie, Numero, Operacion,
       Entrada, CASE WHEN Operacion = '02' THEN Costo ELSE 0 END AS CostoEntrada,
       CAST(Entrada * Costo AS decimal(18,2)) AS TotalEntrada,
       Salida, CASE WHEN Operacion = '01' THEN Costo ELSE 0 END AS CostoSalida,
       CAST(Salida * Costo AS decimal(18,2)) AS TotalSalida, Costo AS CostoSaldo
FROM Origen
WHERE Descripcion IS NOT NULL AND Tipo IS NOT NULL AND Serie IS NOT NULL
  AND Numero IS NOT NULL AND Entrada IS NOT NULL AND Salida IS NOT NULL AND Costo IS NOT NULL
ORDER BY Fecha, OrdenOrigen, DetalleId
OPTION (HASH JOIN, RECOMPILE);

SELECT MIN(Fecha) AS Desde, MAX(Fecha) AS Hasta
FROM (
    SELECT MIN(DocuEmision) AS Fecha FROM dbo.DocumentoVenta
    UNION ALL SELECT MAX(DocuEmision) FROM dbo.DocumentoVenta
    UNION ALL SELECT MIN(CompraEmision) FROM dbo.Compras
    UNION ALL SELECT MAX(CompraEmision) FROM dbo.Compras
) FechasOrigen;
