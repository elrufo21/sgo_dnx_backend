SELECT IdProducto, ProductoCodigo, ProductoNombre, ProductoCantidad
FROM dbo.Producto
ORDER BY ProductoCodigo, IdProducto;
GO

DECLARE @ProductoId bigint = NULL;
DECLARE @Desde datetime = NULL;
DECLARE @Hasta datetime = NULL;
DECLARE @Codigo varchar(80);

SELECT @Codigo = LTRIM(RTRIM(REPLACE(REPLACE(ProductoCodigo, '191', ''), '201', '')))
FROM dbo.Producto
WHERE IdProducto = @ProductoId;

SELECT k.KardexId, k.KardexFecha, k.TipoCodigo, k.Serie, k.KardexDocumento,
       k.TipoOperacion, p.ProductoNombre, k.CantidadIngreso, k.CantidadSalida,
       k.PrecioCosto, k.StockFinal, k.KadexConcepto
FROM dbo.Kardex k
INNER JOIN dbo.Producto p ON p.IdProducto = k.IdProducto
WHERE (p.ProductoCodigo = @Codigo OR p.ProductoCodigo = '191' + @Codigo OR p.ProductoCodigo = '201' + @Codigo)
  AND k.KardexFecha >= @Desde AND k.KardexFecha < DATEADD(day, 1, @Hasta)
  AND k.KardexMotivo IN ('Salida por Venta', 'Ingreso por Compra') AND k.Estado = 'E'
ORDER BY k.KardexFecha, k.KardexId;
GO
