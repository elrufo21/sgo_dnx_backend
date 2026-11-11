ALTER PROCEDURE [dbo].[uspGuardarListaPreciosPdfWEB]
    @Productos XML,
    @ProductoUsuario VARCHAR (60)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Filas TABLE (
        Codigo      VARCHAR (300)   NOT NULL,
        Nombre      VARCHAR (1000)  NOT NULL,
        Costo       DECIMAL (18, 4) NOT NULL,
        Observacion VARCHAR (300)   NOT NULL,
        PV          DECIMAL (18, 2) NOT NULL,
        SV          DECIMAL (18, 2) NOT NULL);
    WITH ProductosXml
    AS   (SELECT UPPER(LTRIM(RTRIM(Fila.value('@codigo', 'varchar(300)')))) AS Codigo,
                 UPPER(LTRIM(RTRIM(Fila.value('@nombre', 'varchar(1000)')))) AS Nombre,
                 Fila.value('@costo', 'decimal(18,4)') AS Costo,
                 UPPER(LTRIM(RTRIM(Fila.value('@observacion', 'varchar(300)')))) AS Observacion,
                 Fila.value('@pv', 'decimal(18,2)') AS PV,
                 Fila.value('@sv', 'decimal(18,2)') AS SV
          FROM   @Productos.nodes('/productos/producto') AS Datos(Fila))
    INSERT INTO @Filas (Codigo, Nombre, Costo, Observacion, PV, SV)
    SELECT Codigo,
           REPLACE(CASE WHEN LEFT(Nombre, 4) = 'DXN ' THEN LTRIM(SUBSTRING(Nombre, 5, 1000)) ELSE Nombre END, '''', ''),
           Costo,
           REPLACE(Observacion, ';', ''),
           PV,
           SV
    FROM   ProductosXml;
    IF NOT EXISTS (SELECT 1
                   FROM   @Filas)
        BEGIN
            RAISERROR ('No hay productos para guardar.', 16, 1);
            RETURN;
        END
    IF EXISTS (SELECT 1
               FROM   @Filas
               WHERE  Codigo = ''
                      OR Nombre = '')
        BEGIN
            RAISERROR ('Cada producto debe tener cÃ³digo y nombre.', 16, 1);
            RETURN;
        END
    IF EXISTS (SELECT   Codigo
               FROM     @Filas
               GROUP BY Codigo
               HAVING   COUNT(*) > 1)
        BEGIN
            RAISERROR ('La lista contiene cÃ³digos repetidos.', 16, 1);
            RETURN;
        END
    DECLARE @Actualizados TABLE (
        IdProducto NUMERIC (20, 0) NOT NULL,
        Stock      DECIMAL (18, 2) NOT NULL,
        Costo      DECIMAL (18, 4) NOT NULL);
    DECLARE @Nuevos TABLE (
        Codigo VARCHAR (300) NOT NULL PRIMARY KEY);
    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE Producto
        SET    IdSubLinea        = 1,
               ProductoNombre    = Filas.Nombre,
               ProductoMarca     = 'DXN',
               ProductoUM        = 'UNIDAD',
               ProductoCosto     = Filas.Costo,
               ProductoVenta     = Filas.Costo,
               ProductoINV       = N'S',
               AlmacenId         = 1,
               ProductoUbicacion = '',
               ProductoObs       = Filas.Observacion,
               ProductoUsuario   = @ProductoUsuario,
               ProductoFecha     = GETDATE(),
               ProductoPV        = Filas.PV,
               ProductoSV        = Filas.SV,
               ProductoxCaja     = 1
        OUTPUT INSERTED.IdProducto, INSERTED.ProductoCantidad, INSERTED.ProductoCosto INTO @Actualizados (IdProducto, Stock, Costo)
        FROM   Producto
               INNER JOIN
               @Filas AS Filas
               ON Filas.Codigo = Producto.ProductoCodigo;
        INSERT INTO Producto (IdSubLinea, ProductoCodigo, ProductoNombre, ProductoMarca, ProductoTipoCambio, ProductoCostoDolar, ProductoUM, ProductoCosto, ProductoVenta, AlmacenId, ProductoUbicacion, ProductoCantidad, ProductoObs, ProductoEstado, ProductoUsuario, ProductoFecha, ProductoImagen, ValorCritico, ProductoPV, ProductoSV, ProductoxCaja, ProductoINV, AplicaFB, UltimoINV)
        OUTPUT INSERTED.ProductoCodigo INTO @Nuevos (Codigo)
        SELECT 1,
               Filas.Codigo,
               Filas.Nombre,
               'DXN',
               0,
               0,
               'UNIDAD',
               Filas.Costo,
               Filas.Costo,
               1,
               '',
               0,
               Filas.Observacion,
               'BUENO',
               @ProductoUsuario,
               GETDATE(),
               '',
               0,
               Filas.PV,
               Filas.SV,
               1,
               N'S',
               N'S',
               NULL
        FROM   @Filas AS Filas
        WHERE  NOT EXISTS (SELECT 1
                           FROM   Producto
                           WHERE  Producto.ProductoCodigo = Filas.Codigo);
        COMMIT TRANSACTION;
        SELECT (SELECT COUNT(*)
                FROM   @Nuevos) AS Registrados,
               (SELECT COUNT(*)
                FROM   @Actualizados) AS Actualizados;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK;
        PRINT 'aramirez';
    END CATCH
END
