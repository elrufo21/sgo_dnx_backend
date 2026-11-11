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
