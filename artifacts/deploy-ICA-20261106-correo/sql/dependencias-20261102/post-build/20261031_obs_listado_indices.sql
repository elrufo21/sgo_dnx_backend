/* PROPUESTA para SQL Server 2008 R2. No ejecutada por Codex.
   El administrador debe revisar el diagnostico, plan de ejecucion, espacio,
   indices equivalentes y ventana de mantenimiento antes de aplicar.
   Crear indices puede bloquear tablas y aumentar el costo de escrituras.
   Seleccionar expresamente la base de datos de la sede en SSMS. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes AS i
    WHERE i.object_id = OBJECT_ID(N'dbo.TABLAOBS')
      AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.has_filter = 0
      AND EXISTS (SELECT 1 FROM sys.index_columns AS ic
                  INNER JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                  WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                    AND ic.key_ordinal = 1 AND c.name = N'TipoVenta')
      AND EXISTS (SELECT 1 FROM sys.index_columns AS ic
                  INNER JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                  WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                    AND ic.key_ordinal = 2 AND c.name = N'FechaTransaccion')
)
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.TABLAOBS') AND name = N'IX_WebObs_TipoFecha')
    CREATE NONCLUSTERED INDEX IX_WebObs_TipoFecha ON dbo.TABLAOBS (TipoVenta, FechaTransaccion);
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes AS i
    WHERE i.object_id = OBJECT_ID(N'dbo.NotaPedido')
      AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.has_filter = 0
      AND EXISTS (SELECT 1 FROM sys.index_columns AS ic
                  INNER JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                  WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                    AND ic.key_ordinal = 1 AND c.name = N'NotaTransaccion')
)
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.NotaPedido') AND name = N'IX_WebObs_NotaTransaccion')
    CREATE NONCLUSTERED INDEX IX_WebObs_NotaTransaccion ON dbo.NotaPedido (NotaTransaccion);
GO

/* Reversion, solo si se desea retirar indices creados por este archivo:
DROP INDEX IX_WebObs_TipoFecha ON dbo.TABLAOBS;
DROP INDEX IX_WebObs_NotaTransaccion ON dbo.NotaPedido;
*/
