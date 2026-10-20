/* Opcional: índices de lectura web. No agrega relaciones ni modifica datos comerciales. */
USE [DXNCOMAS];
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.DetalleDocumento') AND name = N'IX_DetalleDocumento_DocuId')
    CREATE NONCLUSTERED INDEX [IX_DetalleDocumento_DocuId] ON dbo.[DetalleDocumento] ([DocuId])
    INCLUDE ([DetalleId], [IdProducto], [DetalleUM]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.DocumentoVenta') AND name = N'IX_DocumentoVenta_Factura_Fecha')
    CREATE NONCLUSTERED INDEX [IX_DocumentoVenta_Factura_Fecha] ON dbo.[DocumentoVenta] ([TipoCodigo], [DocuDocumento], [DocuEmision], [CompaniaId])
    INCLUDE ([DocuId], [ClienteId], [DocuEstado], [EstadoSunat], [DocuSerie], [DocuNumero], [DocuTotal], [DocuSaldo], [DocuCondicion], [DocuAsociado]);
GO
