-- Migración de la versión anterior, solo si InventarioSaldoInicial está vacía.
-- Ejecutar en la base principal tras revisión del administrador de SQL.
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.InventarioSaldoInicial', N'U') IS NULL
        THROW 50001, 'La tabla no existe; use el script de creación.', 1;

    IF COL_LENGTH(N'dbo.InventarioSaldoInicial', N'FechaFin') IS NULL
        THROW 50002, 'La tabla ya no tiene FechaFin; no se necesita esta migración.', 1;

    DECLARE @Filas bigint;
    SELECT @Filas = COUNT_BIG(*) FROM dbo.InventarioSaldoInicial WITH (TABLOCKX, HOLDLOCK);
    IF @Filas <> 0
        THROW 50003, 'La tabla contiene datos; revise posibles conflictos antes de migrar.', 1;

    ALTER TABLE dbo.InventarioSaldoInicial DROP CONSTRAINT CK_InventarioSaldoInicial_Periodo;
    ALTER TABLE dbo.InventarioSaldoInicial DROP CONSTRAINT PK_InventarioSaldoInicial;
    ALTER TABLE dbo.InventarioSaldoInicial DROP COLUMN FechaFin;
    ALTER TABLE dbo.InventarioSaldoInicial ADD CONSTRAINT PK_InventarioSaldoInicial PRIMARY KEY (Codigo, FechaInicio);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
