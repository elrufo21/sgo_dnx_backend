/*
  Corrige el parser de detalles de dbo.uspinsertarNotaBweb.
  Problema: @detalleCampos conservaba los valores de la primera fila del cursor,
  por lo que todos los detalles se registraban con el primer producto.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @definition nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarNotaBweb'));

IF @definition IS NULL
BEGIN
    RAISERROR('No existe dbo.uspinsertarNotaBweb.', 16, 1);
    RETURN;
END;

IF CHARINDEX(N'DELETE FROM @detalleCampos;', @definition) > 0
BEGIN
    PRINT 'dbo.uspinsertarNotaBweb ya contiene la correccion.';
    RETURN;
END;

SET @definition = REPLACE(@definition, CHAR(13) + CHAR(10), CHAR(10));

DECLARE @oldCursorDeclaration nvarchar(max) = N'        DECLARE @Columna varchar(max);
        OPEN detalle_cursor;';
DECLARE @newCursorDeclaration nvarchar(max) = N'        DECLARE @Columna varchar(max);
        DECLARE @detalleCampos TABLE
        (
            Pos int NOT NULL PRIMARY KEY,
            Valor varchar(max) NULL
        );
        DECLARE @campoPos int;
        OPEN detalle_cursor;';
DECLARE @oldRowStart nvarchar(max) = N'        BEGIN
            DECLARE @detalleCampos TABLE
            (
                Pos int IDENTITY(1,1) NOT NULL,
                Valor varchar(max) NULL
            );

            SET @start = 1;';
DECLARE @newRowStart nvarchar(max) = N'        BEGIN
            DELETE FROM @detalleCampos;
            SET @campoPos = 1;
            SET @start = 1;';
DECLARE @oldInsert nvarchar(max) = N'                INSERT INTO @detalleCampos (Valor)
                VALUES (SUBSTRING(@Columna, @start, @end - @start));

                SET @start = @end + 1;';
DECLARE @newInsert nvarchar(max) = N'                INSERT INTO @detalleCampos (Pos, Valor)
                VALUES (@campoPos, SUBSTRING(@Columna, @start, @end - @start));

                SET @campoPos = @campoPos + 1;
                SET @start = @end + 1;';

IF CHARINDEX(@oldCursorDeclaration, @definition) = 0
   OR CHARINDEX(@oldRowStart, @definition) = 0
   OR CHARINDEX(@oldInsert, @definition) = 0
BEGIN
    RAISERROR('La definicion actual no coincide con la version afectada. No se aplicaron cambios.', 16, 1);
    RETURN;
END;

SET @definition = REPLACE(@definition, @oldCursorDeclaration, @newCursorDeclaration);
SET @definition = REPLACE(@definition, @oldRowStart, @newRowStart);
SET @definition = REPLACE(@definition, @oldInsert, @newInsert);
SET @definition = STUFF(@definition, 1, LEN(N'CREATE PROCEDURE'), N'ALTER PROCEDURE');

EXEC sys.sp_executesql @definition;

IF CHARINDEX(N'DELETE FROM @detalleCampos;', OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarNotaBweb'))) = 0
BEGIN
    RAISERROR('No se pudo validar la correccion de dbo.uspinsertarNotaBweb.', 16, 1);
    RETURN;
END;

PRINT 'dbo.uspinsertarNotaBweb corregido correctamente.';
