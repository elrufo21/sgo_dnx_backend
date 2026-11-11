-- Ejecutar por sede. Parámetros de la API: @Codigos XML, @Desde date, @Hasta date.
-- Equivale a la lectura de InformeKardex después de consolidar KardexUnion.sql.
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @CodigosLote TABLE (
    Codigo varchar(300) NOT NULL,
    CodigoBase varchar(297) NOT NULL,
    PRIMARY KEY (Codigo, CodigoBase)
);

WITH CodigosBase AS (
    SELECT n.value('(text())[1]', 'varchar(297)') AS CodigoBase
    FROM @Codigos.nodes('/codigos/codigo') AS x(n)
)
INSERT INTO @CodigosLote (Codigo, CodigoBase)
SELECT DISTINCT p.Prefijo + c.CodigoBase, c.CodigoBase
FROM CodigosBase c
CROSS JOIN (VALUES (''), ('191'), ('201'), ('211'), ('221'), ('231'), ('241'), ('251')) p(Prefijo);

SELECT c.CodigoBase, p.ProductoCodigo AS Codigo, p.ProductoNombre AS Descripcion,
       k.KardexFecha AS Fecha, k.TipoCodigo AS Tipo, k.Serie, k.KardexDocumento AS Numero,
       k.TipoOperacion AS Operacion,
       CAST(CAST(k.CantidadIngreso AS money) AS decimal(19,2)) AS Entrada,
       CAST(CAST(CASE WHEN k.TipoOperacion = '02' THEN k.PrecioCosto ELSE 0 END AS money) AS decimal(19,2)) AS CostoEntrada,
       CAST(CAST(CAST(k.CantidadIngreso * k.PrecioCosto AS decimal(18,2)) AS money) AS decimal(19,2)) AS TotalEntrada,
       CAST(CAST(k.CantidadSalida AS money) AS decimal(19,2)) AS Salida,
       CAST(CAST(CASE WHEN k.TipoOperacion = '01' THEN k.PrecioCosto ELSE 0 END AS money) AS decimal(19,2)) AS CostoSalida,
       CAST(CAST(CAST(k.CantidadSalida * k.PrecioCosto AS decimal(18,2)) AS money) AS decimal(19,2)) AS TotalSalida,
       CAST(CAST(CAST(k.PrecioCosto AS decimal(18,2)) AS money) AS decimal(19,2)) AS CostoSaldo
FROM @CodigosLote c
JOIN dbo.Producto p ON p.ProductoCodigo = c.Codigo
JOIN dbo.Sublinea s ON s.IdSubLinea = p.IdSubLinea
JOIN dbo.Kardex k ON k.IdProducto = p.IdProducto
WHERE k.KardexFecha >= @Desde AND k.KardexFecha < DATEADD(day, 1, @Hasta)
  AND k.Estado = 'E' AND k.KardexMotivo IN ('Salida por Venta', 'Ingreso por Compra')
  -- El procedimiento del escritorio omite estas filas al concatenar campos NULL.
  AND k.TipoCodigo IS NOT NULL AND k.Serie IS NOT NULL AND k.KardexDocumento IS NOT NULL
  AND k.TipoOperacion IS NOT NULL AND p.ProductoNombre IS NOT NULL
  AND k.CantidadIngreso IS NOT NULL AND k.CantidadSalida IS NOT NULL
  AND k.PrecioCosto IS NOT NULL AND k.StockFinal IS NOT NULL AND k.KadexConcepto IS NOT NULL
ORDER BY k.KardexFecha, k.KardexId
-- En la copia COMAS, el plan por bucles volvía a recorrer Kardex por código.
OPTION (HASH JOIN, RECOMPILE);

SELECT MIN(KardexFecha) AS Desde, MAX(KardexFecha) AS Hasta
FROM dbo.Kardex;
