/* Reversion: publicar primero la version anterior de API y frontend.
   Elimina solo los procedimientos e indices con nombres nuevos de esta entrega.
   No modifica registros de negocio, Indicador ni los SP anteriores. */
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Caja') AND name = N'IX_Web20261020_Caja')
    DROP INDEX [IX_Web20261020_Caja] ON dbo.[Caja];
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Monedas') AND name = N'IX_Web20261020_Monedas')
    DROP INDEX [IX_Web20261020_Monedas] ON dbo.[Monedas];
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.NotaPedido') AND name = N'IX_Web20261020_NotaPedido')
    DROP INDEX [IX_Web20261020_NotaPedido] ON dbo.[NotaPedido];
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.TABLAOBS') AND name = N'IX_Web20261020_TABLAOBS')
    DROP INDEX [IX_Web20261020_TABLAOBS] ON dbo.[TABLAOBS];
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.CajaDetalle') AND name = N'IX_Web20261020_CajaDetalle')
    DROP INDEX [IX_Web20261020_CajaDetalle] ON dbo.[CajaDetalle];
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.DocumentoVenta') AND name = N'IX_Web20261020_DocumentoVenta')
    DROP INDEX [IX_Web20261020_DocumentoVenta] ON dbo.[DocumentoVenta];
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.DetalleDocumento') AND name = N'IX_Web20261020_DetalleDocumento')
    DROP INDEX [IX_Web20261020_DetalleDocumento] ON dbo.[DetalleDocumento];
GO
IF OBJECT_ID(N'dbo.uspListarControlCajaWeb', N'P') IS NOT NULL DROP PROCEDURE dbo.[uspListarControlCajaWeb];
GO
IF OBJECT_ID(N'dbo.uspListarFacturasServicioWeb', N'P') IS NOT NULL DROP PROCEDURE dbo.[uspListarFacturasServicioWeb];
GO
