/* Carga transaccional de la lista de precios PDF. */
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'dbo.uspGuardarListaPreciosPdf', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.uspGuardarListaPreciosPdf AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE dbo.uspGuardarListaPreciosPdf
    @Productos xml,
    @ProductoUsuario varchar(60)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Filas TABLE
    (
        Codigo varchar(300) NOT NULL,
        Nombre varchar(1000) NOT NULL,
        Costo decimal(18,4) NOT NULL,
        Observacion varchar(300) NOT NULL,
        PV decimal(18,2) NOT NULL,
        SV decimal(18,2) NOT NULL
    );

    ;WITH ProductosXml AS
    (
        SELECT
            Codigo = UPPER(LTRIM(RTRIM(Fila.value('@codigo', 'varchar(300)')))),
            Nombre = UPPER(LTRIM(RTRIM(Fila.value('@nombre', 'varchar(1000)')))),
            Costo = Fila.value('@costo', 'decimal(18,4)'),
            Observacion = UPPER(LTRIM(RTRIM(Fila.value('@observacion', 'varchar(300)')))),
            PV = Fila.value('@pv', 'decimal(18,2)'),
            SV = Fila.value('@sv', 'decimal(18,2)')
        FROM @Productos.nodes('/productos/producto') AS Datos(Fila)
    )
    INSERT INTO @Filas (Codigo, Nombre, Costo, Observacion, PV, SV)
    SELECT
        Codigo,
        REPLACE(CASE WHEN LEFT(Nombre, 4) = 'DXN ' THEN LTRIM(SUBSTRING(Nombre, 5, 1000)) ELSE Nombre END, '''', ''),
        Costo,
        REPLACE(Observacion, ';', ''),
        PV,
        SV
    FROM ProductosXml;

    IF NOT EXISTS (SELECT 1 FROM @Filas)
    BEGIN
        RAISERROR('No hay productos para guardar.', 16, 1);
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM @Filas WHERE Codigo = '' OR Nombre = '')
    BEGIN
        RAISERROR('Cada producto debe tener código y nombre.', 16, 1);
        RETURN;
    END;

    IF EXISTS (SELECT Codigo FROM @Filas GROUP BY Codigo HAVING COUNT(*) > 1)
    BEGIN
        RAISERROR('La lista contiene códigos repetidos.', 16, 1);
        RETURN;
    END;

    DECLARE @Actualizados TABLE
    (
        IdProducto numeric(20,0) NOT NULL,
        Stock decimal(18,2) NOT NULL,
        Costo decimal(18,4) NOT NULL
    );
    DECLARE @Nuevos TABLE (Codigo varchar(300) NOT NULL PRIMARY KEY);

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE Producto
        SET
            IdSubLinea = 1,
            ProductoNombre = Filas.Nombre,
            ProductoMarca = 'DXN',
            ProductoUM = 'UNIDAD',
            ProductoCosto = Filas.Costo,
            ProductoVenta = Filas.Costo,
            ProductoINV = N'S',
            AlmacenId = 1,
            ProductoUbicacion = '',
            ProductoObs = Filas.Observacion,
            ProductoUsuario = @ProductoUsuario,
            ProductoFecha = GETDATE(),
            ProductoPV = Filas.PV,
            ProductoSV = Filas.SV,
            ProductoxCaja = 1
        OUTPUT INSERTED.IdProducto, INSERTED.ProductoCantidad, INSERTED.ProductoCosto
            INTO @Actualizados (IdProducto, Stock, Costo)
        FROM Producto
        INNER JOIN @Filas AS Filas ON Filas.Codigo = Producto.ProductoCodigo;

        INSERT INTO Producto
        (
            IdSubLinea, ProductoCodigo, ProductoNombre, ProductoMarca,
            ProductoTipoCambio, ProductoCostoDolar, ProductoUM, ProductoCosto,
            ProductoVenta, AlmacenId, ProductoUbicacion, ProductoCantidad,
            ProductoObs, ProductoEstado, ProductoUsuario, ProductoFecha,
            ProductoImagen, ValorCritico, ProductoPV, ProductoSV, ProductoxCaja,
            ProductoINV, AplicaFB, UltimoINV
        )
        OUTPUT INSERTED.ProductoCodigo INTO @Nuevos (Codigo)
        SELECT
            1, Filas.Codigo, Filas.Nombre, 'DXN',
            0, 0, 'UNIDAD', Filas.Costo,
            Filas.Costo, 1, '', 0,
            Filas.Observacion, 'BUENO', @ProductoUsuario, GETDATE(),
            '', 0, Filas.PV, Filas.SV, 1,
            N'S', N'S', NULL
        FROM @Filas AS Filas
        WHERE NOT EXISTS
        (
            SELECT 1 FROM Producto WHERE Producto.ProductoCodigo = Filas.Codigo
        );

        INSERT INTO Kardex
        (
            IdProducto, KardexFecha, KardexMotivo, KardexDocumento,
            StockInicial, CantidadIngreso, CantidadSalida, PrecioCosto, StockFinal,
            KadexConcepto, Usuario, CLIENTE, CODIGOCLIENTE, NROTRANSAC,
            TipoCodigo, Serie, TipoOperacion, Consideracion, DocuId, CompraId, Estado
        )
        SELECT
            Actualizados.IdProducto, GETDATE(), 'Edita Cantidad', 'Edita Cantidad',
            Actualizados.Stock, 0, 0, Actualizados.Costo, Actualizados.Stock,
            'INGRESO', @ProductoUsuario, '', '', '', '', '', '', 'S', '', '', 'E'
        FROM @Actualizados AS Actualizados;

        INSERT INTO Kardex
        (
            IdProducto, KardexFecha, KardexMotivo, KardexDocumento,
            StockInicial, CantidadIngreso, CantidadSalida, PrecioCosto, StockFinal,
            KadexConcepto, Usuario, CLIENTE, CODIGOCLIENTE, NROTRANSAC,
            TipoCodigo, Serie, TipoOperacion, Consideracion, DocuId, CompraId, Estado
        )
        SELECT
            Producto.IdProducto, GETDATE(), 'Nuevo Registro', 'Nuevo Registro',
            0, 0, 0, Producto.ProductoCosto, 0,
            'INGRESO', @ProductoUsuario, '', '', '', '', '', '', 'S', '', '', 'E'
        FROM Producto
        INNER JOIN @Nuevos AS Nuevos ON Nuevos.Codigo = Producto.ProductoCodigo;

        COMMIT TRANSACTION;

        SELECT
            Registrados = (SELECT COUNT(*) FROM @Nuevos),
            Actualizados = (SELECT COUNT(*) FROM @Actualizados);
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
