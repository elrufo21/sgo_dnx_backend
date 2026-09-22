USE [DXN_ICA];
GO

SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.NotaPedido n
    INNER JOIN dbo.DocumentoVenta d ON d.NotaId = n.NotaId
    WHERE n.NotaId = 72702
      AND n.NotaEstado = 'ANULADO'
      AND d.DocuId = 73014
      AND d.DocuEstado = 'ANULADO'
      AND d.DocuSerie = 'BA01'
      AND d.DocuNumero = '00000001'
)
    THROW 50000, 'No coincide la boleta anulada esperada; no se aplicó ningún cambio.', 1;

DELETE FROM dbo.DetalleDocumento WHERE DocuId = 73014;
DELETE FROM dbo.DocumentoVentaCpeWeb WHERE DocuId = 73014;
DELETE FROM dbo.DocumentoVenta WHERE DocuId = 73014 AND NotaId = 72702;
DELETE FROM dbo.DetallePedido WHERE NotaId = 72702;
DELETE FROM dbo.NotaPedido WHERE NotaId = 72702 AND NotaEstado = 'ANULADO';

IF EXISTS
(
    SELECT 1
    FROM dbo.NotaPedido n
    LEFT JOIN dbo.DocumentoVenta d ON d.NotaId = n.NotaId
    WHERE n.NotaId = 72702 OR d.DocuId = 73014
)
    THROW 50001, 'No se eliminaron todos los registros de la boleta anulada.', 1;

COMMIT TRANSACTION;
GO
