/*
  Sincroniza los procedimientos de DXN_CUSCO_DProduccion hacia DXN_ICA.
  Ambas bases deben estar en localhost\SQLEXPRESS01.

  Alcance:
  - crea procedimientos que existen en Producción y faltan en ICA;
  - actualiza procedimientos con definición distinta;
  - no elimina objetos, no modifica tablas y no toca datos de negocio de ICA.
*/
USE [DXN_ICA];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF DB_ID(N'DXN_CUSCO_DProduccion') IS NULL
        THROW 51000, 'No existe la base fuente DXN_CUSCO_DProduccion.', 1;

    DECLARE @Procedimientos TABLE (Nombre sysname NOT NULL PRIMARY KEY);
    DECLARE @Nombre sysname;
    DECLARE @Definicion nvarchar(max);
    DECLARE @PosicionCreate int;
    DECLARE @Cantidad int;

    INSERT INTO @Procedimientos (Nombre)
    SELECT origen.nombre
    FROM
    (
        SELECT p.name AS nombre, m.definition
        FROM [DXN_CUSCO_DProduccion].sys.procedures p
        INNER JOIN [DXN_CUSCO_DProduccion].sys.schemas s
            ON s.schema_id = p.schema_id
        INNER JOIN [DXN_CUSCO_DProduccion].sys.sql_modules m
            ON m.object_id = p.object_id
        WHERE s.name = N'dbo'
          AND p.name <> N'ingresarProducto'
    ) origen
    LEFT JOIN
    (
        SELECT p.name AS nombre, m.definition
        FROM sys.procedures p
        INNER JOIN sys.schemas s ON s.schema_id = p.schema_id
        INNER JOIN sys.sql_modules m ON m.object_id = p.object_id
        WHERE s.name = N'dbo'
    ) destino
        ON destino.nombre = origen.nombre
    WHERE destino.nombre IS NULL
       OR HASHBYTES(
            'SHA2_256',
            CONVERT(varbinary(max), REPLACE(REPLACE(REPLACE(REPLACE(UPPER(origen.definition), CHAR(13), ''), CHAR(10), ''), N' ', ''), N'ORALTER', ''))
          ) <> HASHBYTES(
            'SHA2_256',
            CONVERT(varbinary(max), REPLACE(REPLACE(REPLACE(REPLACE(UPPER(destino.definition), CHAR(13), ''), CHAR(10), ''), N' ', ''), N'ORALTER', ''))
          );

    SET @Cantidad = @@ROWCOUNT;

    DECLARE procedimientos_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT Nombre FROM @Procedimientos ORDER BY Nombre;

    OPEN procedimientos_cursor;
    FETCH NEXT FROM procedimientos_cursor INTO @Nombre;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @Definicion = m.definition
        FROM [DXN_CUSCO_DProduccion].sys.procedures p
        INNER JOIN [DXN_CUSCO_DProduccion].sys.schemas s
            ON s.schema_id = p.schema_id
        INNER JOIN [DXN_CUSCO_DProduccion].sys.sql_modules m
            ON m.object_id = p.object_id
        WHERE s.name = N'dbo'
          AND p.name = @Nombre;

        SET @PosicionCreate = CHARINDEX(N'CREATE', UPPER(@Definicion));
        IF @PosicionCreate = 0
            THROW 51001, 'La definición fuente no contiene CREATE.', 1;

        SET @Definicion = STUFF(@Definicion, @PosicionCreate + 6, 0, N' OR ALTER');
        EXEC sys.sp_executesql @Definicion;

        FETCH NEXT FROM procedimientos_cursor INTO @Nombre;
    END;

    CLOSE procedimientos_cursor;
    DEALLOCATE procedimientos_cursor;

    /*
      DXN_ICA conserva ProductoVentaB y AplicaINV, columnas que no existen en
      Producción. La fuente inserta sin lista de columnas, por lo que se adapta
      la misma lógica usando una lista explícita y dejando esos dos campos nulos.
    */
    SET @Definicion = N'
CREATE OR ALTER PROCEDURE dbo.ingresarProducto
    @IdSubLinea numeric(20),
    @ProductoCodigo varchar(300),
    @ProductoNombre varchar(max),
    @ProductoMarca varchar(80),
    @ProductoTipoCambio decimal(18,3),
    @ProductoCostoDolar decimal(18,4),
    @ProductoUM varchar(60),
    @ProductoCosto decimal(18,4),
    @ProductoVenta decimal(18,2),
    @ProductoINV nvarchar(1),
    @AlmacenId numeric(20),
    @ProductoUbicacion varchar(80),
    @ProductoCantidad decimal(18,2),
    @ProductoObs varchar(300),
    @ProductoEstado varchar(60),
    @ProductoUsuario varchar(60),
    @ProductoImagen varchar(max),
    @ValorCritico decimal(18,2),
    @ProductoPV decimal(18,2),
    @ProductoSV decimal(18,2),
    @ProductoxCaja decimal(18,2),
    @AplicaFB nvarchar(1)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Producto
    (
        IdSubLinea, ProductoCodigo, ProductoNombre, ProductoMarca,
        ProductoTipoCambio, ProductoCostoDolar, ProductoUM, ProductoCosto,
        ProductoVenta, AlmacenId, ProductoUbicacion, ProductoCantidad,
        ProductoObs, ProductoEstado, ProductoUsuario, ProductoFecha,
        ProductoImagen, ValorCritico, ProductoPV, ProductoSV, ProductoxCaja,
        ProductoINV, AplicaFB, UltimoINV, ProductoVentaB, AplicaINV
    )
    VALUES
    (
        @IdSubLinea, @ProductoCodigo, @ProductoNombre, @ProductoMarca,
        @ProductoTipoCambio, @ProductoCostoDolar, @ProductoUM, @ProductoCosto,
        @ProductoVenta, @AlmacenId, @ProductoUbicacion, @ProductoCantidad,
        @ProductoObs, @ProductoEstado, @ProductoUsuario, GETDATE(),
        @ProductoImagen, @ValorCritico, @ProductoPV, @ProductoSV, @ProductoxCaja,
        @ProductoINV, @AplicaFB, NULL, NULL, NULL
    );

    DECLARE @ProductoId numeric(20) = SCOPE_IDENTITY();

    INSERT INTO dbo.Kardex
    VALUES
    (
        @ProductoId, GETDATE(), ''Nuevo Registro'', ''Nuevo Registro'',
        0, @ProductoCantidad, 0, @ProductoCosto, @ProductoCantidad, ''INGRESO'',
        @ProductoUsuario, '''', '''', '''', '''', '''', '''', ''S'', '''', '''', ''E''
    );

    SELECT @ProductoId;
END;';
    EXEC sys.sp_executesql @Definicion;

    IF EXISTS
    (
        SELECT 1
        FROM [DXN_CUSCO_DProduccion].sys.procedures p
        INNER JOIN [DXN_CUSCO_DProduccion].sys.schemas s
            ON s.schema_id = p.schema_id
        INNER JOIN [DXN_CUSCO_DProduccion].sys.sql_modules origen
            ON origen.object_id = p.object_id
        LEFT JOIN sys.procedures destino_p
            ON destino_p.name = p.name
           AND SCHEMA_NAME(destino_p.schema_id) = s.name
        LEFT JOIN sys.sql_modules destino
            ON destino.object_id = destino_p.object_id
        WHERE s.name = N'dbo'
          AND p.name <> N'ingresarProducto'
          AND
          (
              destino_p.object_id IS NULL
              OR HASHBYTES(
                    'SHA2_256',
                    CONVERT(varbinary(max), REPLACE(REPLACE(REPLACE(REPLACE(UPPER(origen.definition), CHAR(13), ''), CHAR(10), ''), N' ', ''), N'ORALTER', ''))
                 ) <> HASHBYTES(
                    'SHA2_256',
                    CONVERT(varbinary(max), REPLACE(REPLACE(REPLACE(REPLACE(UPPER(destino.definition), CHAR(13), ''), CHAR(10), ''), N' ', ''), N'ORALTER', ''))
                 )
          )
    )
        THROW 51002, 'La verificación de procedimientos no coincidió.', 1;

    COMMIT TRANSACTION;
    SELECT CONCAT('OK|Procedimientos sincronizados: ', @Cantidad) AS Resultado;
END TRY
BEGIN CATCH
    IF CURSOR_STATUS('local', 'procedimientos_cursor') >= 0
    BEGIN
        CLOSE procedimientos_cursor;
        DEALLOCATE procedimientos_cursor;
    END;

    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
