ALTER PROCEDURE [dbo].[anularDocumentoWEB]
    @ListaOrden VARCHAR (MAX)
AS
BEGIN
    DECLARE @pos AS INT;
    DECLARE @orden AS VARCHAR (MAX);
    DECLARE @detalle AS VARCHAR (MAX);
    SET @pos = CharIndex('[', @ListaOrden, 0);
    SET @orden = SUBSTRING(@ListaOrden, 1, @pos - 1);
    SET @detalle = SUBSTRING(@ListaOrden, @pos + 1, len(@ListaOrden) - @pos);
    DECLARE @p1 AS INT, @p2 AS INT, @p3 AS INT, @p4 AS INT, @p5 AS INT, @p6 AS INT, @p7 AS INT, @p8 AS INT, @p9 AS INT;
    DECLARE @DocuId AS NUMERIC (38), @NotaId AS NUMERIC (38), @DocuUsuario AS VARCHAR (80), @DetalleId AS NUMERIC (38), @Concepto AS VARCHAR (40), @Documento AS VARCHAR (40), @Transaccion AS VARCHAR (250), @Miembro AS VARCHAR (300), @CodigoCliente AS VARCHAR (80), @FechaFactura AS DATE, @TipoCodigo AS NVARCHAR (10);
    SET @orden = LTRIM(RTrim(@orden));
    SET @p1 = CharIndex('|', @orden, 0);
    SET @p2 = CharIndex('|', @orden, @p1 + 1);
    SET @p3 = CharIndex('|', @orden, @p2 + 1);
    SET @p4 = CharIndex('|', @orden, @p3 + 1);
    SET @p5 = CharIndex('|', @orden, @p4 + 1);
    SET @p6 = CharIndex('|', @orden, @p5 + 1);
    SET @p7 = CharIndex('|', @orden, @p6 + 1);
    SET @p8 = CharIndex('|', @orden, @p7 + 1);
    SET @p9 = Len(@orden) + 1;
    SET @DocuId = CONVERT (NUMERIC (38), SUBSTRING(@orden, 1, @p1 - 1));
    SET @NotaId = CONVERT (NUMERIC (38), SUBSTRING(@orden, @p1 + 1, @p2 - @p1 - 1));
    SET @DocuUsuario = SUBSTRING(@orden, @p2 + 1, @p3 - @p2 - 1);
    SET @Concepto = SUBSTRING(@orden, @p3 + 1, @p4 - @p3 - 1);
    SET @Documento = SUBSTRING(@orden, @p4 + 1, @p5 - @p4 - 1);
    SET @Miembro = SUBSTRING(@orden, @p5 + 1, @p6 - @p5 - 1);
    SET @CodigoCliente = SUBSTRING(@orden, @p6 + 1, @p7 - @p6 - 1);
    SET @Transaccion = SUBSTRING(@orden, @p7 + 1, @p8 - @p7 - 1);
    SET @TipoCodigo = SUBSTRING(@orden, @p8 + 1, @p9 - @p8 - 1);
    IF EXISTS (SELECT d.DocuId
               FROM   DetallePVarios AS d
               WHERE  d.DocuId = @DocuId)
        BEGIN
            SELECT 'PAGO';
        END
    ELSE
        BEGIN
            DECLARE @Valores AS VARCHAR (MAX);
            DECLARE @Entrega AS VARCHAR (80), @ConceptoOBS AS VARCHAR (80);
            DECLARE @c1 AS INT, @c2 AS INT;
            SET @Valores = (SELECT TOP 1 n.ConceptoOBS + '|' + n.NotaEntrega
                            FROM   NotaPedido AS n
                            WHERE  n.NotaId = @NotaId);
            SET @Valores = LTRIM(RTrim(@Valores));
            SET @c1 = CharIndex('|', @Valores, 0);
            SET @c2 = Len(@Valores) + 1;
            SET @ConceptoOBS = SUBSTRING(@Valores, 1, @c1 - 1);
            SET @Entrega = SUBSTRING(@Valores, @c1 + 1, @c2 - @c1 - 1);
            IF (@ConceptoOBS <> 'VENTA')
                BEGIN
                    SET @DetalleId = isnull((SELECT   TOP 1 d.DetalleId
                                             FROM     CajaDetalle AS d
                                             WHERE    d.NotaIdB = @NotaId
                                             ORDER BY d.DetalleId DESC), 0);
                END
            ELSE
                BEGIN
                    SET @DetalleId = isnull((SELECT   TOP 1 d.DetalleId
                                             FROM     CajaDetalle AS d
                                             WHERE    d.NotaId = @NotaId
                                             ORDER BY d.DetalleId DESC), 0);
                END
            SET @FechaFactura = (SELECT TOP 1 d.DocuEmision
                                 FROM   DocumentoVenta AS d
                                 WHERE  NotaId = @NotaId);
            BEGIN TRANSACTION;
            IF (@Documento = 'PROFORMA V')
                BEGIN
                    UPDATE DocumentoVenta
                    SET    DocuEstado    = 'ANULADO',
                           DocuSubTotal  = 0,
                           DocuIgv       = 0,
                           DocuTotal     = 0,
                           DocuSaldo     = 0,
                           DocuAdicional = 0,
                           ICBPER        = 0,
                           Efectivo      = 0,
                           Deposito      = 0
                    WHERE  DocuId = @DocuId;
                END
            ELSE
                BEGIN
                    UPDATE DocumentoVenta
                    SET    DocuEstado = 'ANULADO',
                           Efectivo   = 0,
                           Deposito   = 0
                    WHERE  DocuId = @DocuId;
                END
            UPDATE NotaPedido
            SET    ModificadoPor = @DocuUsuario,
                   NroOperacion  = '',
                   FechaEdita    = GETDATE(),
                   NotaEstado    = 'ANULADO',
                   NotaSaldo     = NotaPagar,
                   NotaAcuenta   = 0,
                   Efectivo      = 0,
                   Deposito      = 0
            WHERE  NotaId = @NotaId;
            IF (@FechaFactura = CONVERT (DATE, GETDATE()))
                BEGIN
                    IF (@Concepto = 'MERCADERIA')
                        BEGIN
                            DELETE CajaDetalle
                            WHERE  DetalleId = @DetalleId;
                            DELETE CajaDetalle
                            WHERE  NotaIdB = @NotaId;
                        END
                END
            DECLARE Tabla CURSOR
                FOR SELECT *
                    FROM   fnSplitString(@detalle, ';');
            OPEN Tabla;
            DECLARE @Columna AS VARCHAR (MAX), @IdProducto AS NUMERIC (20), @Cantidad AS DECIMAL (18, 2), @Precio AS DECIMAL (18, 2), @IniciaStock AS DECIMAL (18, 2), @StockFinal AS DECIMAL (18, 2);
            DECLARE @d1 AS INT, @d2 AS INT, @d3 AS INT;
            FETCH NEXT FROM Tabla INTO @Columna;
            WHILE @@FETCH_STATUS = 0
                BEGIN
                    SET @d1 = CharIndex('|', @Columna, 0);
                    SET @d2 = CharIndex('|', @Columna, @d1 + 1);
                    SET @d3 = Len(@Columna) + 1;
                    SET @IdProducto = CONVERT (NUMERIC (38), SUBSTRING(@Columna, 1, @d1 - 1));
                    SET @Cantidad = CONVERT (DECIMAL (18, 2), SUBSTRING(@Columna, @d1 + 1, @d2 - (@d1 + 1)));
                    SET @Precio = CONVERT (DECIMAL (18, 2), SUBSTRING(@Columna, @d2 + 1, @d3 - (@d2 + 1)));
                    IF (@Entrega = 'INMEDIATA')
                        BEGIN
                            UPDATE producto
                            SET    ProductoCantidad = ProductoCantidad + @Cantidad
                            WHERE  IDProducto = @IdProducto;
                        END
                    ELSE
                        BEGIN
                            SET @DocuId = @DocuId;
                        END
                    FETCH NEXT FROM Tabla INTO @Columna;
                END
            CLOSE Tabla;
            DEALLOCATE Tabla;
            COMMIT TRANSACTION;
            SELECT 'true';
        END
END
GO

ALTER PROCEDURE [dbo].[editarProductoWEB]
    @IdProducto NUMERIC (20),
    @IdSubLinea NUMERIC (20),
    @ProductoCodigo VARCHAR (300),
    @ProductoNombre VARCHAR (MAX),
    @ProductoMarca VARCHAR (80),
    @ProductoTipoCambio DECIMAL (18, 3),
    @ProductoCostoDolar DECIMAL (18, 4),
    @ProductoUM VARCHAR (60),
    @ProductoCosto DECIMAL (18, 4),
    @ProductoVenta DECIMAL (18, 2),
    @ProductoINV NVARCHAR (1),
    @AlmacenId NUMERIC (20),
    @ProductoUbicacion VARCHAR (80),
    @ProductoCantidad DECIMAL (18, 2),
    @ProductoObs VARCHAR (300),
    @ProductoEstado VARCHAR (60),
    @ProductoUsuario VARCHAR (60),
    @ProductoImagen VARCHAR (MAX),
    @ValorCritico DECIMAL (18, 2),
    @ProductoPV DECIMAL (18, 2),
    @ProductoSV DECIMAL (18, 2),
    @AVISO INT,
    @ProductoxCaja DECIMAL (18, 2),
    @AplicaFB NVARCHAR (1)
AS
DECLARE @inicial AS DECIMAL (18, 2);
SET @inicial = (SELECT p.ProductoCantidad
                FROM   Producto AS p
                WHERE  IdProducto = @IdProducto);
IF (@AVISO = 1)
    BEGIN
        UPDATE Producto
        SET    IdSubLinea         = @IdSubLinea,
               ProductoCodigo     = @ProductoCodigo,
               ProductoNombre     = @ProductoNombre,
               ProductoMarca      = @ProductoMarca,
               ProductoTipoCambio = @ProductoTipoCambio,
               ProductoCostoDolar = @ProductoCostoDolar,
               ProductoUM         = @ProductoUM,
               ProductoCosto      = @ProductoCosto,
               ProductoVenta      = @ProductoVenta,
               ProductoINV        = @ProductoINV,
               AlmacenId          = @AlmacenId,
               ProductoUbicacion  = @ProductoUbicacion,
               ProductoCantidad   = ProductoCantidad,
               ProductoObs        = @ProductoObs,
               ProductoEstado     = @ProductoEstado,
               ProductoUsuario    = @ProductoUsuario,
               ProductoFecha      = GETDATE(),
               ProductoImagen     = @ProductoImagen,
               ProductoPV         = @ProductoPV,
               ProductoSV         = @ProductoSV,
               ValorCritico       = @ValorCritico,
               ProductoxCaja      = @ProductoxCaja,
               AplicaFB           = @AplicaFB
        WHERE  IdProducto = @IdProducto;
    END
ELSE
    BEGIN
        UPDATE Producto
        SET    IdSubLinea         = @IdSubLinea,
               ProductoCodigo     = @ProductoCodigo,
               ProductoNombre     = @ProductoNombre,
               ProductoMarca      = @ProductoMarca,
               ProductoTipoCambio = @ProductoTipoCambio,
               ProductoCostoDolar = @ProductoCostoDolar,
               ProductoUM         = @ProductoUM,
               ProductoCosto      = @ProductoCosto,
               ProductoVenta      = @ProductoVenta,
               ProductoINV        = @ProductoINV,
               AlmacenId          = @AlmacenId,
               ProductoUbicacion  = @ProductoUbicacion,
               ProductoCantidad   = @ProductoCantidad,
               ProductoObs        = @ProductoObs,
               ProductoEstado     = @ProductoEstado,
               ProductoUsuario    = @ProductoUsuario,
               ProductoFecha      = Getdate(),
               ProductoImagen     = @ProductoImagen,
               ProductoPV         = @ProductoPV,
               ProductoSV         = @ProductoSV,
               ValorCritico       = @ValorCritico,
               ProductoxCaja      = @ProductoxCaja,
               AplicaFB           = @AplicaFB
        WHERE  IdProducto = @IdProducto;
    END
GO

ALTER PROCEDURE [dbo].[ingresarProductoWEB]
    @IdSubLinea NUMERIC (20),
    @ProductoCodigo VARCHAR (300),
    @ProductoNombre VARCHAR (MAX),
    @ProductoMarca VARCHAR (80),
    @ProductoTipoCambio DECIMAL (18, 3),
    @ProductoCostoDolar DECIMAL (18, 4),
    @ProductoUM VARCHAR (60),
    @ProductoCosto DECIMAL (18, 4),
    @ProductoVenta DECIMAL (18, 2),
    @ProductoINV NVARCHAR (1),
    @AlmacenId NUMERIC (20),
    @ProductoUbicacion VARCHAR (80),
    @ProductoCantidad DECIMAL (18, 2),
    @ProductoObs VARCHAR (300),
    @ProductoEstado VARCHAR (60),
    @ProductoUsuario VARCHAR (60),
    @ProductoImagen VARCHAR (MAX),
    @ValorCritico DECIMAL (18, 2),
    @ProductoPV DECIMAL (18, 2),
    @ProductoSV DECIMAL (18, 2),
    @ProductoxCaja DECIMAL (18, 2),
    @AplicaFB NVARCHAR (1)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT  INTO dbo.Producto (IdSubLinea, ProductoCodigo, ProductoNombre, ProductoMarca, ProductoTipoCambio, ProductoCostoDolar, ProductoUM, ProductoCosto, ProductoVenta, AlmacenId, ProductoUbicacion, ProductoCantidad, ProductoObs, ProductoEstado, ProductoUsuario, ProductoFecha, ProductoImagen, ValorCritico, ProductoPV, ProductoSV, ProductoxCaja, ProductoINV, AplicaFB, UltimoINV, ProductoVentaB, AplicaINV)
    VALUES                   (@IdSubLinea, @ProductoCodigo, @ProductoNombre, @ProductoMarca, @ProductoTipoCambio, @ProductoCostoDolar, @ProductoUM, @ProductoCosto, @ProductoVenta, @AlmacenId, @ProductoUbicacion, @ProductoCantidad, @ProductoObs, @ProductoEstado, @ProductoUsuario, GETDATE(), @ProductoImagen, @ValorCritico, @ProductoPV, @ProductoSV, @ProductoxCaja, @ProductoINV, @AplicaFB, NULL, NULL, NULL);
    DECLARE @ProductoId AS NUMERIC (20) = SCOPE_IDENTITY();
    SELECT @ProductoId;
END
GO

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
GO

ALTER PROCEDURE [dbo].[uspinsertarNC]
    @ListaOrden VARCHAR (MAX)
AS
BEGIN
    DECLARE @pos AS INT;
    DECLARE @orden AS VARCHAR (MAX);
    DECLARE @detalle AS VARCHAR (MAX);
    SET @pos = CharIndex('[', @ListaOrden, 0);
    SET @orden = SUBSTRING(@ListaOrden, 1, @pos - 1);
    SET @detalle = SUBSTRING(@ListaOrden, @pos + 1, len(@ListaOrden) - @pos);
    DECLARE @pos1 AS INT, @pos2 AS INT, @pos3 AS INT, @pos4 AS INT, @pos5 AS INT, @pos6 AS INT, @pos7 AS INT, @pos8 AS INT, @pos9 AS INT, @pos10 AS INT, @pos11 AS INT, @pos12 AS INT, @pos13 AS INT, @pos14 AS INT, @pos15 AS INT, @pos16 AS INT, @pos17 AS INT, @pos18 AS INT, @pos19 AS INT, @pos20 AS INT, @pos21 AS INT, @pos22 AS INT, @pos23 AS INT, @pos24 AS INT, @pos25 AS INT, @pos26 AS INT, @pos27 AS INT, @pos28 AS INT, @pos29 AS INT, @pos30 AS INT, @pos31 AS INT, @pos32 AS INT, @pos33 AS INT;
    DECLARE @CompaniaId AS INT, @NotaId AS NUMERIC (38), @DocuDocumento AS VARCHAR (60), @DocuNumero AS VARCHAR (60), @ClienteId AS NUMERIC (20), @DocuEmision AS DATE, @DocuSubTotal AS DECIMAL (18, 2), @DocuIgv AS DECIMAL (18, 2), @DocuTotal AS DECIMAL (18, 2), @DocuUsuario AS VARCHAR (60), @DocuSerie AS CHAR (4), @TipoCodigo AS NVARCHAR (10), @DocuAdicional AS DECIMAL (18, 2), @DocuAsociado AS VARCHAR (80), @DocuConcepto AS VARCHAR (80), @DocuHASH AS VARCHAR (250), @EstadoSunat AS VARCHAR (80), @Letras AS VARCHAR (60), @NroReferencia AS VARCHAR (80), @DocuId AS NUMERIC (38), @KardexDocu AS VARCHAR (80), @DetalleId AS NUMERIC (38), @Concepto AS VARCHAR (40), @Transaccion AS VARCHAR (250), @Miembro AS VARCHAR (300), @CodigoCliente AS VARCHAR (80), @ICBPER AS DECIMAL (18, 2), @CodigoSunat AS VARCHAR (80), @MensajeSunat AS VARCHAR (MAX), @FechaFactura AS DATE, @DocuGravada AS DECIMAL (18, 2), @ConceptoOBS AS VARCHAR (80), @Entrega AS VARCHAR (80), @FormaPago AS VARCHAR (80), @EntidadBancaria AS VARCHAR (80), @Efectivo AS DECIMAL (18, 2), @Deposito AS DECIMAL (18, 2);
    SET @pos1 = CharIndex('|', @orden, 0);
    SET @pos2 = CharIndex('|', @orden, @pos1 + 1);
    SET @pos3 = CharIndex('|', @orden, @pos2 + 1);
    SET @pos4 = CharIndex('|', @orden, @pos3 + 1);
    SET @pos5 = CharIndex('|', @orden, @pos4 + 1);
    SET @pos6 = CharIndex('|', @orden, @pos5 + 1);
    SET @pos7 = CharIndex('|', @orden, @pos6 + 1);
    SET @pos8 = CharIndex('|', @orden, @pos7 + 1);
    SET @pos9 = CharIndex('|', @orden, @pos8 + 1);
    SET @pos10 = CharIndex('|', @orden, @pos9 + 1);
    SET @pos11 = CharIndex('|', @orden, @pos10 + 1);
    SET @pos12 = CharIndex('|', @orden, @pos11 + 1);
    SET @pos13 = CharIndex('|', @orden, @pos12 + 1);
    SET @pos14 = CharIndex('|', @orden, @pos13 + 1);
    SET @pos15 = CharIndex('|', @orden, @pos14 + 1);
    SET @pos16 = CharIndex('|', @orden, @pos15 + 1);
    SET @pos17 = CharIndex('|', @orden, @pos16 + 1);
    SET @pos18 = CharIndex('|', @orden, @pos17 + 1);
    SET @pos19 = CharIndex('|', @orden, @pos18 + 1);
    SET @pos20 = CharIndex('|', @orden, @pos19 + 1);
    SET @pos21 = CharIndex('|', @orden, @pos20 + 1);
    SET @pos22 = CharIndex('|', @orden, @pos21 + 1);
    SET @pos23 = CharIndex('|', @orden, @pos22 + 1);
    SET @pos24 = CharIndex('|', @orden, @pos23 + 1);
    SET @pos25 = CharIndex('|', @orden, @pos24 + 1);
    SET @pos26 = CharIndex('|', @orden, @pos25 + 1);
    SET @pos27 = CharIndex('|', @orden, @pos26 + 1);
    SET @pos28 = CharIndex('|', @orden, @pos27 + 1);
    SET @pos29 = CharIndex('|', @orden, @pos28 + 1);
    SET @pos30 = CharIndex('|', @orden, @pos29 + 1);
    SET @pos31 = CharIndex('|', @orden, @pos30 + 1);
    SET @pos32 = CharIndex('|', @orden, @pos31 + 1);
    SET @pos33 = Len(@orden) + 1;
    SET @CompaniaId = CONVERT (INT, SUBSTRING(@orden, 1, @pos1 - 1));
    SET @NotaId = CONVERT (NUMERIC (38), SUBSTRING(@orden, @pos1 + 1, @pos2 - @pos1 - 1));
    SET @DocuDocumento = SUBSTRING(@orden, @pos2 + 1, @pos3 - @pos2 - 1);
    SET @DocuNumero = SUBSTRING(@orden, @pos3 + 1, @pos4 - @pos3 - 1);
    SET @ClienteId = CONVERT (NUMERIC (20), SUBSTRING(@orden, @pos4 + 1, @pos5 - @pos4 - 1));
    SET @DocuEmision = CONVERT (DATE, SUBSTRING(@orden, @pos5 + 1, @pos6 - @pos5 - 1));
    SET @DocuSubTotal = CONVERT (DECIMAL (18, 2), SUBSTRING(@orden, @pos6 + 1, @pos7 - @pos6 - 1));
    SET @DocuIgv = CONVERT (DECIMAL (18, 2), SUBSTRING(@orden, @pos7 + 1, @pos8 - @pos7 - 1));
    SET @DocuTotal = CONVERT (DECIMAL (18, 2), SUBSTRING(@orden, @pos8 + 1, @pos9 - @pos8 - 1));
    SET @DocuUsuario = SUBSTRING(@orden, @pos9 + 1, @pos10 - @pos9 - 1);
    SET @DocuSerie = SUBSTRING(@orden, @pos10 + 1, @pos11 - @pos10 - 1);
    SET @TipoCodigo = SUBSTRING(@orden, @pos11 + 1, @pos12 - @pos11 - 1);
    SET @DocuAdicional = CONVERT (DECIMAL (18, 2), SUBSTRING(@orden, @pos12 + 1, @pos13 - @pos12 - 1));
    SET @DocuAsociado = SUBSTRING(@orden, @pos13 + 1, @pos14 - @pos13 - 1);
    SET @DocuConcepto = SUBSTRING(@orden, @pos14 + 1, @pos15 - @pos14 - 1);
    SET @DocuHASH = SUBSTRING(@orden, @pos15 + 1, @pos16 - @pos15 - 1);
    SET @EstadoSunat = SUBSTRING(@orden, @pos16 + 1, @pos17 - @pos16 - 1);
    SET @Letras = SUBSTRING(@orden, @pos17 + 1, @pos18 - @pos17 - 1);
    SET @NroReferencia = SUBSTRING(@orden, @pos18 + 1, @pos19 - @pos18 - 1);
    SET @Concepto = SUBSTRING(@orden, @pos19 + 1, @pos20 - @pos19 - 1);
    SET @Transaccion = SUBSTRING(@orden, @pos20 + 1, @pos21 - @pos20 - 1);
    SET @Miembro = SUBSTRING(@orden, @pos21 + 1, @pos22 - @pos21 - 1);
    SET @CodigoCliente = SUBSTRING(@orden, @pos22 + 1, @pos23 - @pos22 - 1);
    SET @ICBPER = CONVERT (DECIMAL (18, 2), SUBSTRING(@orden, @pos23 + 1, @pos24 - @pos23 - 1));
    SET @CodigoSunat = SUBSTRING(@orden, @pos24 + 1, @pos25 - @pos24 - 1);
    SET @MensajeSunat = SUBSTRING(@orden, @pos25 + 1, @pos26 - @pos25 - 1);
    SET @DocuGravada = SUBSTRING(@orden, @pos26 + 1, @pos27 - @pos26 - 1);
    SET @ConceptoOBS = SUBSTRING(@orden, @pos27 + 1, @pos28 - @pos27 - 1);
    SET @Entrega = SUBSTRING(@orden, @pos28 + 1, @pos29 - @pos28 - 1);
    SET @FormaPago = SUBSTRING(@orden, @pos29 + 1, @pos30 - @pos29 - 1);
    SET @EntidadBancaria = SUBSTRING(@orden, @pos30 + 1, @pos31 - @pos30 - 1);
    SET @Efectivo = CONVERT (DECIMAL (18, 2), SUBSTRING(@orden, @pos31 + 1, @pos32 - @pos31 - 1));
    SET @Deposito = CONVERT (DECIMAL (18, 2), SUBSTRING(@orden, @pos32 + 1, @pos33 - @pos32 - 1));
    IF (@ConceptoOBS <> 'VENTA')
        BEGIN
            SET @DetalleId = isnull((SELECT   TOP 1 d.DetalleId
                                     FROM     CajaDetalle AS d
                                     WHERE    d.NotaIdB = @NotaId
                                     ORDER BY d.DetalleId DESC), 0);
        END
    ELSE
        BEGIN
            SET @DetalleId = isnull((SELECT   TOP 1 d.DetalleId
                                     FROM     CajaDetalle AS d
                                     WHERE    d.NotaId = @NotaId
                                     ORDER BY d.DetalleId DESC), 0);
        END
    SET @FechaFactura = (SELECT TOP 1 d.DocuEmision
                         FROM   DocumentoVenta AS d
                         WHERE  NotaId = @NotaId
                                AND TipoCodigo = '01');
    BEGIN TRANSACTION;
    INSERT  INTO DocumentoVenta
    VALUES (@CompaniaId, @NotaId, @DocuDocumento, @DocuNumero, @ClienteId, GETDATE(), @DocuEmision, 'ALCONTADO', @Letras, @DocuSubTotal, @DocuIgv, @DocuTotal, @DocuGravada, @DocuUsuario, 'EMITIDO', @DocuSerie, @TipoCodigo, @DocuAdicional, @DocuAsociado, @DocuConcepto, @NroReferencia, @DocuHASH, @EstadoSunat, @Concepto, '', @ICBPER, @CodigoSunat, @MensajeSunat, @FormaPago, @EntidadBancaria, '', @Efectivo, @Deposito);
    SET @DocuId = @@identity;
    SET @KardexDocu = 'NC ' + @DocuSerie + '-' + @DocuNumero;
    UPDATE DocumentoVenta
    SET    DocuAsociado = @DocuId
    WHERE  DocuId = @DocuAsociado;
    IF (@DocuConcepto = 'ANULACION DE LA OPERACION')
        BEGIN
            UPDATE NotaPedido
            SET    NotaEstado  = 'ANULADO',
                   NotaAcuenta = 0,
                   NotaSaldo   = NotaPagar
            WHERE  NotaId = @NotaId;
        END
    IF (@FechaFactura = CONVERT (DATE, GETDATE()))
        BEGIN
            IF (@Concepto = 'MERCADERIA')
                BEGIN
                    DELETE CajaDetalle
                    WHERE  DetalleId = @DetalleId;
                    DELETE CajaDetalle
                    WHERE  NotaIdB = @NotaId;
                END
        END
    DECLARE Tabla CURSOR
        FOR SELECT *
            FROM   fnSplitString(@detalle, ';');
    OPEN Tabla;
    DECLARE @Columna AS VARCHAR (MAX), @IdProducto AS NUMERIC (20), @IdProductoB AS NUMERIC (20), @Cantidad AS DECIMAL (18, 2), @Precio AS DECIMAL (18, 2), @Importe AS DECIMAL (18, 2), @DetalleNotaId AS NUMERIC (38), @UM AS VARCHAR (80), @ValorUM AS DECIMAL (18, 4), @StockInicial AS DECIMAL (18, 2), @StockFinal AS DECIMAL (18, 2), @CantidadIng AS DECIMAL (18, 2), @CodigoPro AS VARCHAR (80);
    DECLARE @p1 AS INT, @p2 AS INT, @p3 AS INT, @p4 AS INT, @p5 AS INT, @p6 AS INT, @p7 AS INT, @p8 AS INT;
    FETCH NEXT FROM Tabla INTO @Columna;
    WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @p1 = CharIndex('|', @Columna, 0);
            SET @p2 = CharIndex('|', @Columna, @p1 + 1);
            SET @p3 = CharIndex('|', @Columna, @p2 + 1);
            SET @p4 = CharIndex('|', @Columna, @p3 + 1);
            SET @p5 = CharIndex('|', @Columna, @p4 + 1);
            SET @p6 = CharIndex('|', @Columna, @p5 + 1);
            SET @p7 = CharIndex('|', @Columna, @p6 + 1);
            SET @p8 = Len(@Columna) + 1;
            SET @Cantidad = CONVERT (DECIMAL (18, 2), SUBSTRING(@Columna, 1, @p1 - 1));
            SET @UM = SUBSTRING(@Columna, @p1 + 1, @p2 - (@p1 + 1));
            SET @Precio = CONVERT (DECIMAL (18, 2), SUBSTRING(@Columna, @p2 + 1, @p3 - (@p2 + 1)));
            SET @Importe = CONVERT (DECIMAL (18, 2), SUBSTRING(@Columna, @p3 + 1, @p4 - (@p3 + 1)));
            SET @DetalleNotaId = CONVERT (NUMERIC (38), SUBSTRING(@Columna, @p4 + 1, @p5 - (@p4 + 1)));
            SET @IdProducto = CONVERT (NUMERIC (20), SUBSTRING(@Columna, @p5 + 1, @p6 - (@p5 + 1)));
            SET @ValorUM = CONVERT (DECIMAL (18, 4), SUBSTRING(@Columna, @p6 + 1, @p7 - (@p6 + 1)));
            SET @CodigoPro = SUBSTRING(@Columna, @p7 + 1, @p8 - (@p7 + 1));
            IF (@CodigoPro = 'MD100')
                BEGIN
                    SET @IdProductoB = isnull((SELECT TOP 1 P.IdProducto
                                               FROM   Producto AS P
                                               WHERE  P.ProductoCodigo = @CodigoPro), 0);
                    SET @IdProducto = @IdProductoB;
                END
            INSERT  INTO DetalleDocumento
            VALUES (@DocuId, @IdProducto, @Cantidad, @Precio, @Importe, @DetalleNotaId, @UM, @ValorUM);
            IF (@Entrega = 'INMEDIATA')
                BEGIN
                    SET @StockInicial = (SELECT TOP 1 ProductoCantidad
                                         FROM   Producto WITH (NOLOCK)
                                         WHERE  IdProducto = @IdProducto);
                    SET @CantidadIng = (@Cantidad * @ValorUM);
                    SET @StockFinal = @StockInicial + @CantidadIng;
                    UPDATE Producto
                    SET    ProductoCantidad = ProductoCantidad + @CantidadIng
                    WHERE  IdProducto = @IdProducto;
                END
            ELSE
                BEGIN
                    SET @StockInicial = (SELECT TOP 1 ProductoCantidad
                                         FROM   Producto WITH (NOLOCK)
                                         WHERE  IdProducto = @IdProducto);
                    SET @CantidadIng = (@Cantidad * @ValorUM);
                    SET @StockFinal = @StockInicial + @CantidadIng;
                END
            FETCH NEXT FROM Tabla INTO @Columna;
        END
    CLOSE Tabla;
    DEALLOCATE Tabla;
    COMMIT TRANSACTION;
    SELECT 'true';
END
GO

ALTER PROCEDURE [dbo].[uspinsertarNotaBweb]
    @ListaOrden VARCHAR (MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @pos1 AS INT, @orden AS VARCHAR (MAX), @detalle AS VARCHAR (MAX);
    SET @pos1 = CHARINDEX('[', @ListaOrden, 1);
    IF @pos1 <= 0
        BEGIN
            RAISERROR ('Formato de orden invalido.', 16, 1);
            RETURN;
        END
    SET @orden = SUBSTRING(@ListaOrden, 1, @pos1 - 1);
    SET @detalle = SUBSTRING(@ListaOrden, @pos1 + 1, LEN(@ListaOrden) - @pos1);
    DECLARE @campos TABLE (
        Pos   INT           IDENTITY (1, 1) NOT NULL,
        Valor VARCHAR (MAX) NULL);
    DECLARE @start AS INT, @end AS INT;
    SET @start = 1;
    WHILE @start <= LEN(@orden) + 1
        BEGIN
            SET @end = CHARINDEX('|', @orden, @start);
            IF @end = 0
                SET @end = LEN(@orden) + 1;
            INSERT  INTO @campos (Valor)
            VALUES              (SUBSTRING(@orden, @start, @end - @start));
            SET @start = @end + 1;
        END
    DECLARE @NotaDocu AS VARCHAR (60), @ClienteId AS NUMERIC (20), @NotaUsuario AS VARCHAR (60), @NotaFormaPago AS VARCHAR (60), @NotaCondicion AS VARCHAR (60), @NotaDireccion AS VARCHAR (MAX), @CompaniaUbigeo AS VARCHAR (250), @NotaSubtotal AS DECIMAL (18, 2), @NotaMovilidad AS DECIMAL (18, 2), @NotaDescuento AS DECIMAL (18, 2), @NotaTotal AS DECIMAL (18, 2), @NotaAcuenta AS DECIMAL (18, 2), @NotaSaldo AS DECIMAL (18, 2), @NotaAdicional AS DECIMAL (18, 2), @NotaTarjeta AS DECIMAL (18, 2), @NotaPagar AS DECIMAL (18, 2), @NotaEstado AS VARCHAR (60), @CompaniaId AS INT, @NotaEntrega AS VARCHAR (40), @NotaConcepto AS VARCHAR (60), @Serie AS VARCHAR (60), @Numero AS VARCHAR (60), @NotaGanancia AS DECIMAL (18, 2), @Letra AS VARCHAR (MAX), @DocuAdicional AS DECIMAL (18, 2), @DocuHash AS VARCHAR (250), @EstadoSunat AS VARCHAR (80), @DocuSubtotal AS DECIMAL (18, 2), @DocuIGV AS DECIMAL (18, 2), @UsuarioId AS INT, @NotaTransaccion AS VARCHAR (250), @Miembro AS VARCHAR (300), @CodigoCliente AS VARCHAR (80), @ICBPER AS DECIMAL (18, 2), @DocuGravada AS DECIMAL (18, 2), @ConceptoOBS AS VARCHAR (80), @EstadoOBS AS VARCHAR (20), @PV AS VARCHAR (40), @Image AS VARCHAR (MAX), @CodigoRes AS VARCHAR (80), @Responsable AS VARCHAR (300), @EntidadBancaria AS VARCHAR (80), @Efectivo AS DECIMAL (18, 2), @Deposito AS DECIMAL (18, 2), @NroOperacion AS VARCHAR (80), @ClienteRazon AS VARCHAR (140), @ClienteRuc AS VARCHAR (40), @ClienteDni AS VARCHAR (40), @DireccionFiscal AS VARCHAR (MAX), @TipoCodigo AS CHAR (20), @cod AS VARCHAR (60), @NotaId AS NUMERIC (38), @DocuId AS NUMERIC (38);
    SELECT @NotaDocu = Valor
    FROM   @campos
    WHERE  Pos = 1;
    SELECT @ClienteId = CONVERT (NUMERIC (20), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 2;
    SELECT @NotaUsuario = Valor
    FROM   @campos
    WHERE  Pos = 3;
    SELECT @NotaFormaPago = Valor
    FROM   @campos
    WHERE  Pos = 4;
    SELECT @NotaCondicion = Valor
    FROM   @campos
    WHERE  Pos = 5;
    SELECT @NotaDireccion = Valor
    FROM   @campos
    WHERE  Pos = 6;
    SELECT @NotaSubtotal = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 7;
    SELECT @NotaMovilidad = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 8;
    SELECT @NotaDescuento = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 9;
    SELECT @NotaTotal = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 10;
    SELECT @NotaAcuenta = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 11;
    SELECT @NotaSaldo = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 12;
    SELECT @NotaAdicional = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 13;
    SELECT @NotaTarjeta = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 14;
    SELECT @NotaPagar = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 15;
    SELECT @NotaEstado = Valor
    FROM   @campos
    WHERE  Pos = 16;
    SELECT @CompaniaId = CONVERT (INT, ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 17;
    SELECT @NotaEntrega = Valor
    FROM   @campos
    WHERE  Pos = 18;
    SELECT @NotaConcepto = Valor
    FROM   @campos
    WHERE  Pos = 19;
    SELECT @Serie = Valor
    FROM   @campos
    WHERE  Pos = 20;
    SELECT @Numero = Valor
    FROM   @campos
    WHERE  Pos = 21;
    SELECT @NotaGanancia = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 22;
    SELECT @Letra = Valor
    FROM   @campos
    WHERE  Pos = 23;
    SELECT @DocuAdicional = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 24;
    SELECT @DocuHash = Valor
    FROM   @campos
    WHERE  Pos = 25;
    SELECT @EstadoSunat = Valor
    FROM   @campos
    WHERE  Pos = 26;
    SELECT @DocuSubtotal = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 27;
    SELECT @DocuIGV = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 28;
    SELECT @UsuarioId = CONVERT (INT, ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 29;
    SELECT @NotaTransaccion = Valor
    FROM   @campos
    WHERE  Pos = 30;
    SELECT @Miembro = Valor
    FROM   @campos
    WHERE  Pos = 31;
    SELECT @CodigoCliente = Valor
    FROM   @campos
    WHERE  Pos = 32;
    SELECT @ICBPER = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 33;
    SELECT @DocuGravada = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 34;
    SELECT @ConceptoOBS = Valor
    FROM   @campos
    WHERE  Pos = 35;
    SELECT @EstadoOBS = Valor
    FROM   @campos
    WHERE  Pos = 36;
    SELECT @PV = Valor
    FROM   @campos
    WHERE  Pos = 37;
    SELECT @Image = Valor
    FROM   @campos
    WHERE  Pos = 38;
    SELECT @CodigoRes = Valor
    FROM   @campos
    WHERE  Pos = 39;
    SELECT @Responsable = Valor
    FROM   @campos
    WHERE  Pos = 40;
    SELECT @EntidadBancaria = Valor
    FROM   @campos
    WHERE  Pos = 41;
    SELECT @Efectivo = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 42;
    SELECT @Deposito = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
    FROM   @campos
    WHERE  Pos = 43;
    SELECT @NroOperacion = Valor
    FROM   @campos
    WHERE  Pos = 44;
    IF ISNULL((SELECT CASE WHEN MAX(CASE WHEN ISNULL(i.ValorNum, 1) <> 0 THEN 1 ELSE 0 END) = 0 THEN 0 ELSE 1 END
               FROM   dbo.Usuarios AS u
                      INNER JOIN
                      dbo.Personal AS p
                      ON p.PersonalId = u.PersonalId
                      LEFT OUTER JOIN
                      dbo.Indicador AS i
                      ON i.CompaniaId = p.CompaniaId
                         AND i.Descripcion = 'ASISTENCIA'
               WHERE  u.UsuarioID = @UsuarioId), 1) = 1
       AND NOT EXISTS (SELECT 1
                       FROM   dbo.Asistencia AS a
                              INNER JOIN
                              dbo.Usuarios AS u
                              ON u.PersonalId = a.PersonalId
                       WHERE  u.UsuarioID = @UsuarioId
                              AND a.Fecha = CONVERT (DATE, GETDATE()))
        BEGIN
            SELECT 'NO ASISTIO';
            RETURN;
        END
    SET @NotaEstado = ISNULL(NULLIF (@NotaEstado, ''), 'PENDIENTE');
    SET @CompaniaId = ISNULL(NULLIF (@CompaniaId, 0), 1);
    SET @NotaEntrega = ISNULL(NULLIF (@NotaEntrega, ''), 'INMEDIATA');
    SET @NotaConcepto = ISNULL(NULLIF (@NotaConcepto, ''), 'MERCADERIA');
    SET @Serie = ISNULL(NULLIF (@Serie, ''), CASE WHEN @NotaDocu = 'FACTURA' THEN 'FA01' ELSE 'BA01' END);
    SET @Letra = ISNULL(@Letra, '');
    SET @DocuHash = ISNULL(@DocuHash, '');
    SET @EstadoSunat = ISNULL(NULLIF (@EstadoSunat, ''), 'PENDIENTE');
    SET @NotaTransaccion = ISNULL(@NotaTransaccion, '');
    SET @Miembro = ISNULL(@Miembro, '');
    SET @CodigoCliente = ISNULL(@CodigoCliente, '');
    SET @ConceptoOBS = ISNULL(NULLIF (@ConceptoOBS, ''), 'VENTA');
    SET @EstadoOBS = ISNULL(NULLIF (@EstadoOBS, ''), 'EMITIDO');
    SET @CodigoRes = ISNULL(@CodigoRes, '');
    SET @Responsable = ISNULL(@Responsable, '');
    SET @EntidadBancaria = ISNULL(NULLIF (@EntidadBancaria, ''), '-');
    SET @NroOperacion = ISNULL(@NroOperacion, '');
    IF @NotaDocu = 'FACTURA'
        SET @TipoCodigo = '01';
    ELSE
        IF @NotaDocu = 'PROFORMA V'
            SET @TipoCodigo = '00';
        ELSE
            SET @TipoCodigo = '03';
    SELECT TOP 1 @ClienteRazon = NULLIF (LTRIM(RTRIM(ClienteRazon)), ''),
                 @ClienteRuc = NULLIF (LTRIM(RTRIM(ClienteRuc)), ''),
                 @ClienteDni = NULLIF (LTRIM(RTRIM(ClienteDni)), ''),
                 @DireccionFiscal = NULLIF (LTRIM(RTRIM(ClienteDireccion)), '')
    FROM   Cliente
    WHERE  ClienteId = @ClienteId;
    SET @ClienteRazon = ISNULL(@ClienteRazon, CASE WHEN @Miembro <> '' THEN @Miembro ELSE 'VARIOS' END);
    SET @ClienteRuc = ISNULL(@ClienteRuc, '');
    SET @ClienteDni = ISNULL(@ClienteDni, '');
    IF @NotaDocu = 'BOLETA'
       AND @ClienteRuc = ''
       AND @ClienteDni = ''
        BEGIN
            SET @ClienteDni = '00000000';
        END
    SET @DireccionFiscal = ISNULL(@DireccionFiscal, @NotaDireccion);
    IF NULLIF (@DireccionFiscal, '') IS NULL
        SET @DireccionFiscal = '-';
    IF @NotaFormaPago <> 'EFECTIVO'
        BEGIN
            IF @Efectivo IS NULL
                SET @Efectivo = 0;
            IF @Deposito IS NULL
               OR @Deposito = 0
                SET @Deposito = @NotaPagar;
        END
    ELSE
        BEGIN
            IF @Efectivo IS NULL
               OR @Efectivo = 0
                SET @Efectivo = @NotaPagar;
            IF @Deposito IS NULL
                SET @Deposito = 0;
        END
    IF @NotaCondicion = 'CREDITO'
        BEGIN
            SET @NotaEstado = 'EMITIDO';
            SET @NotaSaldo = @NotaPagar;
            SET @NotaAcuenta = 0;
        END
    ELSE
        IF @NotaDocu <> 'FACTURA'
           AND @NotaDocu <> 'PROFORMA V'
            BEGIN
                SET @NotaEstado = 'CANCELADO';
                SET @NotaSaldo = 0;
                SET @NotaAcuenta = @NotaPagar;
            END
    IF @NotaTransaccion <> ''
       AND EXISTS (SELECT 1
                   FROM   NotaPedido
                   WHERE  NotaTransaccion = @NotaTransaccion
                          AND ISNULL(NotaEstado, '') <> 'ANULADO')
        BEGIN
            SELECT 'EXISTE';
            RETURN;
        END
    IF @Deposito > 0
       AND @NotaCondicion <> 'PAGO/VARIOS'
       AND NULLIF (LTRIM(RTRIM(@NroOperacion)), '') IS NULL
        BEGIN
            SELECT 'OPERACION_REQUERIDA';
            RETURN;
        END
    IF @NroOperacion <> ''
       AND ISNULL(@EntidadBancaria, '-') <> '-'
       AND EXISTS (SELECT 1
                   FROM   NotaPedido
                   WHERE  EntidadBancaria = @EntidadBancaria
                          AND NroOperacion = @NroOperacion
                          AND ISNULL(NotaEstado, '') <> 'ANULADO')
        BEGIN
            SELECT 'OPERACION';
            RETURN;
        END
    DECLARE @CajaId AS NUMERIC (38);
    SELECT   TOP (1) @CajaId = CajaId
    FROM     Caja
    WHERE    CajaEstado = 'ACTIVO'
             AND UsuarioId = @UsuarioId
    ORDER BY CajaId DESC;
    IF ISNULL(@CajaId, 0) = 0
        BEGIN
            SELECT 'false';
            RETURN;
        END
    SELECT @CompaniaUbigeo = NULLIF (LTRIM(RTRIM(CompaniaNomUBG)), '')
    FROM   Compania
    WHERE  CompaniaId = @CompaniaId;
    SET @CompaniaUbigeo = ISNULL(@CompaniaUbigeo, '');
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE Cliente
        SET    ClienteDespacho = @NotaDireccion
        WHERE  ClienteId = @ClienteId;
        SET @NotaDireccion = @CompaniaUbigeo;
        DELETE TemporalVenta
        WHERE  UsuarioID = @UsuarioId;
        SELECT @cod = ISNULL((SELECT TOP 1 dbo.genenerarNroFactura(@Serie, @CompaniaId, @NotaDocu)
                              FROM   DocumentoVenta), '00000001');
        INSERT  INTO NotaPedido (NotaDocu, ClienteId, NotaFecha, NotaUsuario, NotaFormaPago, NotaCondicion, NotaFechaPago, NotaDireccion, NotaSubtotal, NotaMovilidad, NotaDescuento, NotaTotal, NotaAcuenta, NotaSaldo, NotaAdicional, NotaTarjeta, NotaPagar, NotaEstado, CompaniaId, NotaEntrega, ModificadoPor, FechaEdita, NotaConcepto, NotaSerie, NotaNumero, NotaGanancia, CajaId, NotaTransaccion, ICBPER, ConceptoOBS, EstadoOBS, CodigoRes, Responsable, EntidadBancaria, NroOperacion, Efectivo, Deposito)
        VALUES                 (@NotaDocu, @ClienteId, GETDATE(), @NotaUsuario, @NotaFormaPago, @NotaCondicion, GETDATE(), @NotaDireccion, @NotaSubtotal, @NotaMovilidad, @NotaDescuento, @NotaTotal, @NotaAcuenta, @NotaSaldo, @NotaAdicional, @NotaTarjeta, @NotaPagar, @NotaEstado, @CompaniaId, @NotaEntrega, '', '', @NotaConcepto, @Serie, @cod, @NotaGanancia, @CajaId, @NotaTransaccion, @ICBPER, @ConceptoOBS, @EstadoOBS, @CodigoRes, @Responsable, @EntidadBancaria, @NroOperacion, @Efectivo, @Deposito);
        SET @NotaId = SCOPE_IDENTITY();
        INSERT  INTO DocumentoVenta (CompaniaId, NotaId, DocuDocumento, DocuNumero, ClienteId, DocuRegistro, DocuEmision, DocuCondicion, DocuLetras, DocuSubTotal, DocuIgv, DocuTotal, DocuSaldo, DocuUsuario, DocuEstado, DocuSerie, TipoCodigo, DocuAdicional, DocuAsociado, DocuConcepto, DocuNroGuia, DocuHash, EstadoSunat, DocuOperacion, DocuTransaccion, ICBPER, CodigoSunat, MensajeSunat, FormaPago, EntidadBancaria, NroOperacion, Efectivo, Deposito)
        VALUES                     (@CompaniaId, @NotaId, @NotaDocu, @cod, @ClienteId, GETDATE(), GETDATE(), @NotaCondicion, @Letra, @DocuSubtotal, @DocuIGV, @NotaPagar, 0, @NotaUsuario, 'EMITIDO', @Serie, @TipoCodigo, @DocuAdicional, '', 'VENTA', '', @DocuHash, CASE WHEN @NotaDocu = 'PROFORMA V' THEN 'ENVIADO' ELSE @EstadoSunat END, @NotaConcepto, @NotaTransaccion, @ICBPER, '', '', @NotaFormaPago, @EntidadBancaria, @NroOperacion, @Efectivo, @Deposito);
        SET @DocuId = SCOPE_IDENTITY();
        INSERT  INTO dbo.DocumentoVentaCpeWeb (DocuId, ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal, DocuPdfUrl, DocuXmlUrl, DocuCdrUrl, DocuFechaPago)
        VALUES                               (@DocuId, @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal, '', '', '', GETDATE());
        IF @NotaCondicion = 'ALCONTADO'
           AND @NotaDocu <> 'PROFORMA V'
            BEGIN
                IF UPPER(LTRIM(RTRIM(@ConceptoOBS))) = 'VENTA LIBRE'
                    BEGIN
                        INSERT  INTO dbo.CajaDetalle (CajaId, DetalleFecha, NotaId, DetalleMovimiento, DetalleConcepto, DetalleMonto, DetalleEfectivo, DetalleVuelto, RutaImagen, Estado, Vista, NotaIdB, LiquidaId, FormaPago, EntidadBancaria, NroOperacion)
                        VALUES                      (@CajaId, GETDATE(), 0, 'INGRESO', 'VENTA LIBRE DOCUMENTO ' + @Serie + '-' + @cod + ' CODIGO: ' + @CodigoCliente + ' (' + @Miembro + ')' + ' FORMA DE PAGO: ' + @NotaFormaPago, @NotaTotal, @NotaTotal, 0, @Image, 'D', '', @NotaId, '', @NotaFormaPago, @EntidadBancaria, @NroOperacion);
                    END
                IF @Deposito > 0
                   AND UPPER(LTRIM(RTRIM(@ConceptoOBS))) IN ('VENTA', 'IOC', 'CASHBILL', 'VENTA LIBRE')
                    BEGIN
                        INSERT  INTO dbo.CajaDetalle (CajaId, DetalleFecha, NotaId, DetalleMovimiento, DetalleConcepto, DetalleMonto, DetalleEfectivo, DetalleVuelto, RutaImagen, Estado, Vista, NotaIdB, LiquidaId, FormaPago, EntidadBancaria, NroOperacion)
                        VALUES                      (@CajaId, GETDATE(), 0, 'SALIDA', 'VENTA DEL OBS DOCUMENTO ' + @Serie + '-' + @cod + ' CODIGO: ' + @CodigoCliente + ' (' + @Miembro + ')' + ' FORMA DE PAGO: ' + @NotaFormaPago + ' ENTIDAD BANCARIA: ' + @EntidadBancaria + ' NRO OPERACION: ' + @NroOperacion, @Deposito, @Deposito, 0, @Image, 'D', '', @NotaId, '', @NotaFormaPago, @EntidadBancaria, @NroOperacion);
                    END
            END
        DECLARE detalle_cursor CURSOR LOCAL FAST_FORWARD
            FOR SELECT splitdata
                FROM   dbo.fnSplitString(@detalle, ';')
                WHERE  LEN(LTRIM(RTRIM(splitdata))) > 0;
        DECLARE @Columna AS VARCHAR (MAX);
        DECLARE @detalleCampos TABLE (
            Pos   INT           NOT NULL PRIMARY KEY,
            Valor VARCHAR (MAX) NULL);
        DECLARE @campoPos AS INT;
        OPEN detalle_cursor;
        FETCH NEXT FROM detalle_cursor INTO @Columna;
        WHILE @@FETCH_STATUS = 0
            BEGIN
                DELETE @detalleCampos;
                SET @campoPos = 1;
                SET @start = 1;
                WHILE @start <= LEN(@Columna) + 1
                    BEGIN
                        SET @end = CHARINDEX('|', @Columna, @start);
                        IF @end = 0
                            SET @end = LEN(@Columna) + 1;
                        INSERT  INTO @detalleCampos (Pos, Valor)
                        VALUES                     (@campoPos, SUBSTRING(@Columna, @start, @end - @start));
                        SET @campoPos = @campoPos + 1;
                        SET @start = @end + 1;
                    END
                DECLARE @IdProducto AS NUMERIC (20), @DetalleCantidad AS DECIMAL (18, 2), @DetalleUm AS VARCHAR (40), @Descripcion AS VARCHAR (MAX), @DetalleCosto AS DECIMAL (18, 4), @DetallePrecio AS DECIMAL (18, 2), @DetallePV AS DECIMAL (18, 2), @DetalleSV AS DECIMAL (18, 2), @DetalleImporte AS DECIMAL (18, 2), @DetalleEstado AS VARCHAR (60), @ValorUM AS DECIMAL (18, 4), @CantidadSaldo AS DECIMAL (18, 2), @IniciaStock AS DECIMAL (18, 2), @StockFinal AS DECIMAL (18, 2);
                SELECT @IdProducto = CONVERT (NUMERIC (20), ISNULL(NULLIF (Valor, ''), '0'))
                FROM   @detalleCampos
                WHERE  Pos = 1;
                SELECT @DetalleCantidad = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
                FROM   @detalleCampos
                WHERE  Pos = 2;
                SELECT @DetalleUm = Valor
                FROM   @detalleCampos
                WHERE  Pos = 3;
                SELECT @Descripcion = Valor
                FROM   @detalleCampos
                WHERE  Pos = 4;
                SELECT @DetalleCosto = CONVERT (DECIMAL (18, 4), ISNULL(NULLIF (Valor, ''), '0'))
                FROM   @detalleCampos
                WHERE  Pos = 5;
                SELECT @DetallePrecio = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
                FROM   @detalleCampos
                WHERE  Pos = 6;
                SELECT @DetallePV = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
                FROM   @detalleCampos
                WHERE  Pos = 7;
                SELECT @DetalleSV = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
                FROM   @detalleCampos
                WHERE  Pos = 8;
                SELECT @DetalleImporte = CONVERT (DECIMAL (18, 2), ISNULL(NULLIF (Valor, ''), '0'))
                FROM   @detalleCampos
                WHERE  Pos = 9;
                SELECT @DetalleEstado = Valor
                FROM   @detalleCampos
                WHERE  Pos = 10;
                SELECT @ValorUM = CONVERT (DECIMAL (18, 4), ISNULL(NULLIF (Valor, ''), '0'))
                FROM   @detalleCampos
                WHERE  Pos = 11;
                SET @DetalleUm = ISNULL(NULLIF (@DetalleUm, ''), 'UNIDAD');
                SET @Descripcion = ISNULL(@Descripcion, '');
                SET @DetalleEstado = ISNULL(NULLIF (@DetalleEstado, ''), 'PENDIENTE');
                IF @ValorUM IS NULL
                   OR @ValorUM = 0
                    BEGIN
                        SET @ValorUM = 1;
                    END
                IF @NotaEntrega = 'INMEDIATA'
                    SET @CantidadSaldo = 0;
                ELSE
                    SET @CantidadSaldo = @DetalleCantidad;
                INSERT  INTO DetallePedido (NotaId, IdProducto, DetalleCantidad, DetalleUm, DetalleDescripcion, DetalleCosto, DetallePrecio, DetalleImporte, DetalleEstado, CantidadSaldo, ValorUM, DetallePV, DetalleSV)
                VALUES                    (@NotaId, @IdProducto, @DetalleCantidad, @DetalleUm, @Descripcion, @DetalleCosto, @DetallePrecio, @DetalleImporte, @DetalleEstado, @CantidadSaldo, @ValorUM, @DetallePV, @DetalleSV);
                IF @DocuId <> 0
                    BEGIN
                        INSERT  INTO DetalleDocumento (DocuId, IdProducto, DetalleCantidad, DetallPrecio, DetalleImporte, DetalleNotaId, DetalleUM, ValorUM)
                        VALUES                       (@DocuId, @IdProducto, @DetalleCantidad, @DetallePrecio, @DetalleImporte, @NotaId, @DetalleUm, @ValorUM);
                    END
                IF @NotaDocu <> 'FACTURA'
                    BEGIN
                        SELECT TOP 1 @IniciaStock = ProductoCantidad
                        FROM   Producto
                        WHERE  IdProducto = @IdProducto;
                        SET @IniciaStock = ISNULL(@IniciaStock, 0);
                        SET @StockFinal = @IniciaStock - @DetalleCantidad;
                        IF @NotaEntrega = 'INMEDIATA'
                            BEGIN
                                UPDATE Producto
                                SET    ProductoCantidad = ProductoCantidad - @DetalleCantidad
                                WHERE  IdProducto = @IdProducto;
                            END
                    END
                FETCH NEXT FROM detalle_cursor INTO @Columna;
            END
        CLOSE detalle_cursor;
        DEALLOCATE detalle_cursor;
        COMMIT TRANSACTION;
        SELECT CONVERT (VARCHAR (38), @NotaId) + N'¬' + @cod;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'detalle_cursor') > -1
            BEGIN
                CLOSE detalle_cursor;
                DEALLOCATE detalle_cursor;
            END
        IF @@TRANCOUNT > 0
            ROLLBACK;
        DECLARE @ErrMsg AS NVARCHAR (4000), @ErrSeverity AS INT, @ErrState AS INT;
        SELECT @ErrMsg = ERROR_MESSAGE(),
               @ErrSeverity = ERROR_SEVERITY(),
               @ErrState = ERROR_STATE();
        RAISERROR (@ErrMsg, @ErrSeverity, @ErrState);
    END CATCH
END
GO
