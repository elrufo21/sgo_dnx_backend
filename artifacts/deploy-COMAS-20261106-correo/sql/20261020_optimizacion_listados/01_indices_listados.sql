/* SQL Server 2008 R2. Elegir la BD en SSMS: ICA o COMAS; este archivo no cambia de BD.
   Indices para los joins y filtros de los dos listados. No cambia datos de negocio.
   Omite un indice cuando ya existe otro habilitado, sin filtro, con el mismo prefijo de claves.
   Los CREATE INDEX adquieren bloqueos: ejecutar en la ventana de mantenimiento acordada. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.object_id = OBJECT_ID(N'dbo.Caja') AND i.is_disabled = 0
      AND i.is_hypothetical = 0 AND i.has_filter = 0 AND EXISTS (SELECT 1 FROM sys.index_columns ic
                      INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                        AND ic.key_ordinal = 1 AND c.name = N'CajaFecha')
          AND EXISTS (SELECT 1 FROM sys.index_columns ic
                      INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                        AND ic.key_ordinal = 2 AND c.name = N'CajaId')
)
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Caja') AND name = N'IX_Web20261020_Caja')
    CREATE NONCLUSTERED INDEX [IX_Web20261020_Caja] ON dbo.[Caja] ([CajaFecha], [CajaId])
    INCLUDE ([CajaEncargado], [CajaEstado]);
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.object_id = OBJECT_ID(N'dbo.Monedas') AND i.is_disabled = 0
      AND i.is_hypothetical = 0 AND i.has_filter = 0 AND EXISTS (SELECT 1 FROM sys.index_columns ic
                      INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                        AND ic.key_ordinal = 1 AND c.name = N'CajaId')
)
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Monedas') AND name = N'IX_Web20261020_Monedas')
    CREATE NONCLUSTERED INDEX [IX_Web20261020_Monedas] ON dbo.[Monedas] ([CajaId])
    INCLUDE ([Monto]);
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.object_id = OBJECT_ID(N'dbo.NotaPedido') AND i.is_disabled = 0
      AND i.is_hypothetical = 0 AND i.has_filter = 0 AND EXISTS (SELECT 1 FROM sys.index_columns ic
                      INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                        AND ic.key_ordinal = 1 AND c.name = N'CajaId')
          AND EXISTS (SELECT 1 FROM sys.index_columns ic
                      INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                        AND ic.key_ordinal = 2 AND c.name = N'NotaTransaccion')
)
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.NotaPedido') AND name = N'IX_Web20261020_NotaPedido')
    CREATE NONCLUSTERED INDEX [IX_Web20261020_NotaPedido] ON dbo.[NotaPedido] ([CajaId], [NotaTransaccion]);
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.object_id = OBJECT_ID(N'dbo.TABLAOBS') AND i.is_disabled = 0
      AND i.is_hypothetical = 0 AND i.has_filter = 0 AND EXISTS (SELECT 1 FROM sys.index_columns ic
                      INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                        AND ic.key_ordinal = 1 AND c.name = N'NotaTransaccion')
          AND EXISTS (SELECT 1 FROM sys.index_columns ic
                      INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                        AND ic.key_ordinal = 2 AND c.name = N'TipoVenta')
)
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.TABLAOBS') AND name = N'IX_Web20261020_TABLAOBS')
    CREATE NONCLUSTERED INDEX [IX_Web20261020_TABLAOBS] ON dbo.[TABLAOBS] ([NotaTransaccion], [TipoVenta])
    INCLUDE ([Importe]);
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.object_id = OBJECT_ID(N'dbo.CajaDetalle') AND i.is_disabled = 0
      AND i.is_hypothetical = 0 AND i.has_filter = 0 AND EXISTS (SELECT 1 FROM sys.index_columns ic
                      INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                        AND ic.key_ordinal = 1 AND c.name = N'CajaId')
)
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.CajaDetalle') AND name = N'IX_Web20261020_CajaDetalle')
    CREATE NONCLUSTERED INDEX [IX_Web20261020_CajaDetalle] ON dbo.[CajaDetalle] ([CajaId])
    INCLUDE ([DetalleMovimiento], [NotaId], [DetalleConcepto], [DetalleMonto]);
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.object_id = OBJECT_ID(N'dbo.DocumentoVenta') AND i.is_disabled = 0
      AND i.is_hypothetical = 0 AND i.has_filter = 0 AND EXISTS (SELECT 1 FROM sys.index_columns ic
                      INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                        AND ic.key_ordinal = 1 AND c.name = N'TipoCodigo')
          AND EXISTS (SELECT 1 FROM sys.index_columns ic
                      INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                        AND ic.key_ordinal = 2 AND c.name = N'DocuEmision')
          AND EXISTS (SELECT 1 FROM sys.index_columns ic
                      INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                        AND ic.key_ordinal = 3 AND c.name = N'DocuId')
)
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.DocumentoVenta') AND name = N'IX_Web20261020_DocumentoVenta')
    CREATE NONCLUSTERED INDEX [IX_Web20261020_DocumentoVenta] ON dbo.[DocumentoVenta] ([TipoCodigo], [DocuEmision], [DocuId])
    INCLUDE ([CompaniaId], [EstadoSunat], [DocuDocumento], [DocuCondicion], [DocuAsociado], [DocuNroGuia]);
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.object_id = OBJECT_ID(N'dbo.DetalleDocumento') AND i.is_disabled = 0
      AND i.is_hypothetical = 0 AND i.has_filter = 0 AND EXISTS (SELECT 1 FROM sys.index_columns ic
                      INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                        AND ic.key_ordinal = 1 AND c.name = N'DocuId')
)
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.DetalleDocumento') AND name = N'IX_Web20261020_DetalleDocumento')
    CREATE NONCLUSTERED INDEX [IX_Web20261020_DetalleDocumento] ON dbo.[DetalleDocumento] ([DocuId])
    INCLUDE ([DetalleId], [IdProducto], [DetalleUM]);
GO

