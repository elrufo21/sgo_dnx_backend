/*
  Completa el cambio de estado de ventas PAGO/VARIOS que el listado y la
  validación de caja consideran pendientes: estado EMITIDO, sin pago registrado
  y NotaFecha anterior al 2026-10-01.
  Solo cambia NotaEstado; no registra pagos ni modifica saldos o movimientos.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @FechaCorte date = '20261001';
DECLARE @CantidadEsperada int = 251;
DECLARE @CantidadEncontrada int;
DECLARE @CantidadActualizada int;
DECLARE @Actualizados table (NotaId numeric(18, 0) NOT NULL);

BEGIN TRY
    BEGIN TRANSACTION;

    SELECT @CantidadEncontrada = COUNT(*)
    FROM dbo.NotaPedido AS n WITH (UPDLOCK, HOLDLOCK)
    WHERE LTRIM(RTRIM(ISNULL(n.NotaCondicion, ''))) = 'PAGO/VARIOS'
      AND n.NotaFecha < @FechaCorte
      AND UPPER(LTRIM(RTRIM(ISNULL(n.NotaEstado, '')))) = 'EMITIDO'
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.DetallePVarios AS dp WITH (HOLDLOCK)
          WHERE dp.NotaId = n.NotaId
      );

    IF @CantidadEncontrada <> @CantidadEsperada
    BEGIN
        RAISERROR('La cantidad de registros EMITIDO cambió desde la revisión. No se aplicó ninguna actualización.', 16, 1);
    END;

    UPDATE n
       SET NotaEstado = 'CANCELADO'
    OUTPUT inserted.NotaId INTO @Actualizados (NotaId)
    FROM dbo.NotaPedido AS n
    WHERE LTRIM(RTRIM(ISNULL(n.NotaCondicion, ''))) = 'PAGO/VARIOS'
      AND n.NotaFecha < @FechaCorte
      AND UPPER(LTRIM(RTRIM(ISNULL(n.NotaEstado, '')))) = 'EMITIDO'
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
