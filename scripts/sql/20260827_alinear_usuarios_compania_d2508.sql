/*
  Ejecutar dentro de DXN_CUSCO_D2508.
  Alinea solo las columnas requeridas por los procedimientos web de usuarios
  y copia desde DXN_CUSCO_D2108 las dos definiciones que dependian de ellas.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF COL_LENGTH(N'dbo.Usuarios', N'FechaVencimientoClave') IS NULL
    ALTER TABLE dbo.Usuarios ADD FechaVencimientoClave date NULL;

IF COL_LENGTH(N'dbo.Compania', N'DescuentoMax') IS NULL
    ALTER TABLE dbo.Compania ADD DescuentoMax decimal(18, 2) NULL;

IF COL_LENGTH(N'dbo.Compania', N'TIPO_PROCESO') IS NULL
    ALTER TABLE dbo.Compania ADD TIPO_PROCESO int NULL;

IF COL_LENGTH(N'dbo.Compania', N'BoletaPorLote') IS NULL
    ALTER TABLE dbo.Compania
        ADD BoletaPorLote bit NOT NULL
            CONSTRAINT DF_Compania_BoletaPorLote_D2508 DEFAULT (1) WITH VALUES;

IF COL_LENGTH(N'dbo.Compania', N'FlagCaptura') IS NULL
    ALTER TABLE dbo.Compania
        ADD FlagCaptura bit NOT NULL
            CONSTRAINT DF_Compania_FlagCaptura_D2508 DEFAULT (0) WITH VALUES;

DECLARE @procedimientos TABLE (Nombre sysname NOT NULL PRIMARY KEY);
INSERT INTO @procedimientos (Nombre)
VALUES (N'uspValidaUsuarioweb'), (N'usp_Usuario');

DECLARE @nombre sysname;
DECLARE @definition nvarchar(max);
DECLARE @inicioCreate int;
DECLARE @inicioProcedure int;

DECLARE procedimiento_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT Nombre FROM @procedimientos;

OPEN procedimiento_cursor;
FETCH NEXT FROM procedimiento_cursor INTO @nombre;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @definition = m.definition
    FROM DXN_CUSCO_D2108.sys.procedures p
    INNER JOIN DXN_CUSCO_D2108.sys.sql_modules m ON m.object_id = p.object_id
    WHERE p.schema_id = SCHEMA_ID(N'dbo')
      AND p.name = @nombre;

    IF @definition IS NULL
    BEGIN
        RAISERROR('No se encontro el procedimiento de referencia en DXN_CUSCO_D2108.', 16, 1);
        RETURN;
    END;

    SET @inicioCreate = CHARINDEX(N'CREATE', UPPER(@definition));
    SET @inicioProcedure = CHARINDEX(N'PROCEDURE', UPPER(@definition), @inicioCreate);
    IF @inicioCreate = 0 OR @inicioProcedure = 0
    BEGIN
        RAISERROR('La definicion de referencia no contiene CREATE PROCEDURE.', 16, 1);
        RETURN;
    END;

    SET @definition = STUFF(
        @definition,
        @inicioCreate,
        @inicioProcedure + LEN(N'PROCEDURE') - @inicioCreate,
        N'CREATE OR ALTER PROCEDURE'
    );

    EXEC sys.sp_executesql @definition;
    FETCH NEXT FROM procedimiento_cursor INTO @nombre;
END;

CLOSE procedimiento_cursor;
DEALLOCATE procedimiento_cursor;

IF COL_LENGTH(N'dbo.Usuarios', N'FechaVencimientoClave') IS NULL
   OR COL_LENGTH(N'dbo.Compania', N'DescuentoMax') IS NULL
   OR COL_LENGTH(N'dbo.Compania', N'TIPO_PROCESO') IS NULL
   OR COL_LENGTH(N'dbo.Compania', N'BoletaPorLote') IS NULL
   OR COL_LENGTH(N'dbo.Compania', N'FlagCaptura') IS NULL
BEGIN
    RAISERROR('No se pudo validar la alineacion de columnas.', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'dbo.uspValidaUsuarioweb', N'P') IS NULL
   OR OBJECT_ID(N'dbo.usp_Usuario', N'P') IS NULL
BEGIN
    RAISERROR('No se pudo validar la creacion de procedimientos.', 16, 1);
    RETURN;
END;

PRINT 'DXN_CUSCO_D2508 alineada para procedimientos web de usuarios.';
