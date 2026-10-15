/*
  Marca como CANCELADO únicamente el estado de ventas PAGO/VARIOS pendientes
  con NotaFecha anterior al 2026-10-01.
  No registra pagos ni modifica saldos, documentos o movimientos de caja.
  La ejecución se detiene si el conjunto ya no coincide con la revisión previa.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @FechaCorte date = '20261001';
DECLARE @CantidadEsperada int = 788;
DECLARE @CantidadEncontrada int;
DECLARE @CantidadActualizada int;
DECLARE @Actualizados table (NotaId numeric(18, 0) NOT NULL);

BEGIN TRY
    BEGIN TRANSACTION;

    SELECT @CantidadEncontrada = COUNT(*)
    FROM dbo.NotaPedido AS n WITH (UPDLOCK, HOLDLOCK)
    WHERE LTRIM(RTRIM(ISNULL(n.NotaCondicion, ''))) = 'PAGO/VARIOS'
      AND n.NotaFecha < @FechaCorte
      AND UPPER(LTRIM(RTRIM(ISNULL(n.NotaEstado, '')))) = 'PENDIENTE'
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.DetallePVarios AS dp WITH (HOLDLOCK)
          WHERE dp.NotaId = n.NotaId
      );

    IF @CantidadEncontrada <> @CantidadEsperada
    BEGIN
        RAISERROR('La cantidad de pendientes cambió desde la revisión. No se aplicó ninguna actualización.', 16, 1);
    END;

    UPDATE n
       SET NotaEstado = 'CANCELADO'
    OUTPUT inserted.NotaId INTO @Actualizados (NotaId)
    FROM dbo.NotaPedido AS n
    WHERE LTRIM(RTRIM(ISNULL(n.NotaCondicion, ''))) = 'PAGO/VARIOS'
      AND n.NotaFecha < @FechaCorte
      AND UPPER(LTRIM(RTRIM(ISNULL(n.NotaEstado, '')))) = 'PENDIENTE'
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.DetallePVarios AS dp
          WHERE dp.NotaId = n.NotaId
      );

    SET @CantidadActualizada = @@ROWCOUNT;

    IF @CantidadActualizada <> @CantidadEsperada
    BEGIN
        RAISERROR('La cantidad actualizada no coincide con la revisión. Se revierte la transacción.', 16, 1);
    END;

    COMMIT TRANSACTION;

    SELECT @CantidadActualizada AS CantidadActualizada,
           MIN(n.NotaFecha) AS FechaDesde,
           MAX(n.NotaFecha) AS FechaHasta
    FROM @Actualizados AS a
    INNER JOIN dbo.NotaPedido AS n ON n.NotaId = a.NotaId;
END TRY
BEGIN CATCH
    DECLARE @MensajeError nvarchar(4000) = ERROR_MESSAGE();

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    RAISERROR('%s', 16, 1, @MensajeError);
END CATCH;
