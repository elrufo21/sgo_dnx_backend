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
