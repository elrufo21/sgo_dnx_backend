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
    INNER JOIN dbo.CajaDetalle c ON c.NotaIdB = n.NotaId
    WHERE n.NotaId = 72702
      AND n.NotaEstado = 'ANULADO'
      AND d.DocuId = 73014
      AND d.DocuEstado = 'ANULADO'
      AND c.CajaId = 2324
      AND c.DetalleId = 77911
      AND c.DetalleMovimiento = 'INGRESO'
      AND c.DetalleMonto = 104.00
)
    THROW 50000, 'No se encontró el movimiento esperado de la boleta anulada; no se aplicó ningún cambio.', 1;

DELETE FROM dbo.CajaDetalle
WHERE DetalleId = 77911
  AND CajaId = 2324
  AND NotaIdB = 72702;

IF @@ROWCOUNT <> 1
    THROW 50001, 'La corrección debía eliminar un único movimiento de caja.', 1;

COMMIT TRANSACTION;
GO
