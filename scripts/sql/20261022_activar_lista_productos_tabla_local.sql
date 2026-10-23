-- Activacion local solicitada: DXNCOMAS2210, compania 1. Valor anterior: 0.
-- Para revertir, usar ValorNum = 0 con el mismo filtro.
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'DXNCOMAS2210'
BEGIN
    RAISERROR('Ejecutar solo en DXNCOMAS2210.', 16, 1);
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    IF (SELECT COUNT(*) FROM dbo.Indicador WITH (UPDLOCK, HOLDLOCK)
        WHERE CompaniaId = 1 AND Descripcion = 'ListaProductosTabla') <> 1
    BEGIN
        RAISERROR('Se requiere exactamente un indicador para la compania 1.', 16, 1);
    END;

    UPDATE dbo.Indicador
    SET ValorNum = 1
    WHERE CompaniaId = 1 AND Descripcion = 'ListaProductosTabla'
      AND Area = 'VENTAS' AND TipoIndicador = 1 AND IdIndicador IS NULL
      AND ValorNum IN (0, 1);

    IF @@ROWCOUNT <> 1
        RAISERROR('El indicador tiene metadatos o valor incompatibles.', 16, 1);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @Mensaje nvarchar(4000);
    SET @Mensaje = ERROR_MESSAGE();
    RAISERROR('%s', 16, 1, @Mensaje);
    RETURN;
END CATCH;

SELECT CompaniaId, Descripcion, ValorNum
FROM dbo.Indicador
WHERE CompaniaId = 1 AND Descripcion = 'ListaProductosTabla';
