/* Solo lectura. Ejecutar en la base de datos de la sede afectada.
   Revisar tipos e indices antes de decidir si aplicar la propuesta de indices. */
SELECT OBJECT_NAME(c.object_id) AS Tabla, c.name AS Columna,
       TYPE_NAME(c.user_type_id) AS Tipo, c.max_length, c.precision, c.scale
FROM sys.columns AS c
WHERE (c.object_id = OBJECT_ID(N'dbo.TABLAOBS')
       AND c.name IN (N'TipoVenta', N'FechaTransaccion', N'NotaTransaccion'))
   OR (c.object_id = OBJECT_ID(N'dbo.NotaPedido')
       AND c.name = N'NotaTransaccion')
ORDER BY Tabla, Columna;

SELECT OBJECT_NAME(i.object_id) AS Tabla, i.name AS Indice, i.is_disabled,
       i.has_filter, ic.key_ordinal, ic.is_included_column, c.name AS Columna
FROM sys.indexes AS i
INNER JOIN sys.index_columns AS ic
    ON ic.object_id = i.object_id AND ic.index_id = i.index_id
INNER JOIN sys.columns AS c
    ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id IN (OBJECT_ID(N'dbo.TABLAOBS'), OBJECT_ID(N'dbo.NotaPedido'))
ORDER BY Tabla, Indice, ic.key_ordinal, ic.index_column_id;

/* Medicion opcional de solo lectura: habilitar el plan de ejecucion real en
   SSMS, completar el rango afectado y comparar tiempo y lecturas antes y
   despues de cualquier cambio aprobado. Usa los mismos tipos que la API.

DECLARE @FechaInicio date = '20261031', @FechaFin date = '20261031';
DECLARE @TipoVenta nvarchar(3) = N'OBS';
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT T.ID, CONVERT(char(10), T.FechaTransaccion, 23) AS Fecha,
       T.NotaTransaccion, T.CodigoMiembro, T.NombreMiembro, T.Importe,
       ISNULL(N.NotaUsuario, 'NO EXISTE') AS Usuario,
       ISNULL(N.NotaEstado, 'NO EXISTE') AS Estado,
       ISNULL(CONVERT(varchar(30), N.CajaId), 'NO EXISTE') AS CajaId
FROM dbo.TABLAOBS AS T
LEFT JOIN dbo.NotaPedido AS N ON N.NotaTransaccion = T.NotaTransaccion
WHERE T.TipoVenta = @TipoVenta
  AND T.FechaTransaccion BETWEEN @FechaInicio AND @FechaFin
ORDER BY T.FechaTransaccion, T.ID;
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
*/
