/*
  Permite registrar ventas PAGO/VARIOS sin numero de operacion.
  El numero se solicita posteriormente al cancelar los documentos pendientes.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @definition nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarNotaBweb'));

IF @definition IS NULL
BEGIN
    RAISERROR('No existe dbo.uspinsertarNotaBweb.', 16, 1);
    RETURN;
END;

IF CHARINDEX(N'AND @NotaCondicion <> ''PAGO/VARIOS''', @definition) > 0
BEGIN
    PRINT 'dbo.uspinsertarNotaBweb ya permite PAGO/VARIOS sin numero de operacion.';
    RETURN;
END;

SET @definition = REPLACE(@definition, CHAR(13) + CHAR(10), CHAR(10));

DECLARE @oldValidation nvarchar(max) = N'    IF @Deposito > 0
       AND NULLIF(LTRIM(RTRIM(@NroOperacion)), '''') IS NULL';
DECLARE @newValidation nvarchar(max) = N'    IF @Deposito > 0
       AND @NotaCondicion <> ''PAGO/VARIOS''
       AND NULLIF(LTRIM(RTRIM(@NroOperacion)), '''') IS NULL';

IF CHARINDEX(@oldValidation, @definition) = 0
BEGIN
    RAISERROR('La definicion actual no coincide con la version afectada. No se aplicaron cambios.', 16, 1);
    RETURN;
END;

SET @definition = REPLACE(@definition, @oldValidation, @newValidation);
SET @definition = LTRIM(@definition);

IF UPPER(LEFT(@definition, LEN(N'CREATE PROCEDURE'))) = N'CREATE PROCEDURE'
    SET @definition = STUFF(@definition, 1, LEN(N'CREATE PROCEDURE'), N'ALTER PROCEDURE');
ELSE IF UPPER(LEFT(@definition, LEN(N'ALTER PROCEDURE'))) <> N'ALTER PROCEDURE'
BEGIN
    RAISERROR('No se pudo reconocer la declaracion de dbo.uspinsertarNotaBweb.', 16, 1);
    RETURN;
END;

EXEC sys.sp_executesql @definition;

IF CHARINDEX(N'AND @NotaCondicion <> ''PAGO/VARIOS''', OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarNotaBweb'))) = 0
BEGIN
    RAISERROR('No se pudo validar la correccion de dbo.uspinsertarNotaBweb.', 16, 1);
    RETURN;
END;

PRINT 'dbo.uspinsertarNotaBweb corregido correctamente.';
