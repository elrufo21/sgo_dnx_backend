

GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'dbo.uspinsertarNotaBweb', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.uspinsertarNotaBweb AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.uspinsertarNotaBweb
@ListaOrden VARCHAR (MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE
        @pos1 AS INT,
        @orden AS VARCHAR (MAX),
        @detalle AS VARCHAR (MAX);
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
    DECLARE
        @start AS INT,
        @end AS INT;
    SET @start = 1;
    WHILE @start <= LEN(@orden) + 1
        BEGIN
            SET @end = CHARINDEX('|', @orden, @start);
            IF @end = 0
                SET @end = LEN(@orden) + 1;
            INSERT  INTO @campos
            (
                Valor
            )
            VALUES
            (
                SUBSTRING(@orden, @start, @end - @start)
            )
            SET @start = @end + 1;
        END
    DECLARE
        @NotaDocu AS VARCHAR (60),
        @ClienteId AS NUMERIC (20),
        @NotaUsuario AS VARCHAR (60),
        @NotaFormaPago AS VARCHAR (60),
        @NotaCondicion AS VARCHAR (60),
        @NotaDireccion AS VARCHAR (MAX),
        @CompaniaUbigeo AS VARCHAR (250),
        @NotaSubtotal AS DECIMAL (18, 2),
        @NotaMovilidad AS DECIMAL (18, 2),
        @NotaDescuento AS DECIMAL (18, 2),
        @NotaTotal AS DECIMAL (18, 2),
        @NotaAcuenta AS DECIMAL (18, 2),
        @NotaSaldo AS DECIMAL (18, 2),
        @NotaAdicional AS DECIMAL (18, 2),
        @NotaTarjeta AS DECIMAL (18, 2),
        @NotaPagar AS DECIMAL (18, 2),
        @NotaEstado AS VARCHAR (60),
        @CompaniaId AS INT,
        @NotaEntrega AS VARCHAR (40),
        @NotaConcepto AS VARCHAR (60),
        @Serie AS VARCHAR (60),
        @Numero AS VARCHAR (60),
        @NotaGanancia AS DECIMAL (18, 2),
        @Letra AS VARCHAR (MAX),
        @DocuAdicional AS DECIMAL (18, 2),
        @DocuHash AS VARCHAR (250),
        @EstadoSunat AS VARCHAR (80),
        @DocuSubtotal AS DECIMAL (18, 2),
        @DocuIGV AS DECIMAL (18, 2),
        @UsuarioId AS INT,
        @NotaTransaccion AS VARCHAR (250),
        @Miembro AS VARCHAR (300),
        @CodigoCliente AS VARCHAR (80),
        @ICBPER AS DECIMAL (18, 2),
        @DocuGravada AS DECIMAL (18, 2),
        @ConceptoOBS AS VARCHAR (80),
        @EstadoOBS AS VARCHAR (20),
        @PV AS VARCHAR (40),
        @Image AS VARCHAR (MAX),
        @CodigoRes AS VARCHAR (80),
        @Responsable AS VARCHAR (300),
        @EntidadBancaria AS VARCHAR (80),
        @Efectivo AS DECIMAL (18, 2),
        @Deposito AS DECIMAL (18, 2),
        @NroOperacion AS VARCHAR (80),
        @ClienteRazon AS VARCHAR (140),
        @ClienteRuc AS VARCHAR (40),
        @ClienteDni AS VARCHAR (40),
        @DireccionFiscal AS VARCHAR (MAX),
        @TipoCodigo AS CHAR (20),
        @cod AS VARCHAR (60),
        @NotaId AS NUMERIC (38),
        @DocuId AS NUMERIC (38);
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
        INSERT  INTO NotaPedido
        (
            NotaDocu,
            ClienteId,
            NotaFecha,
            NotaUsuario,
            NotaFormaPago,
            NotaCondicion,
            NotaFechaPago,
            NotaDireccion,
            NotaSubtotal,
            NotaMovilidad,
            NotaDescuento,
            NotaTotal,
            NotaAcuenta,
            NotaSaldo,
            NotaAdicional,
            NotaTarjeta,
            NotaPagar,
            NotaEstado,
            CompaniaId,
            NotaEntrega,
            ModificadoPor,
            FechaEdita,
            NotaConcepto,
            NotaSerie,
            NotaNumero,
            NotaGanancia,
            CajaId,
            NotaTransaccion,
            ICBPER,
            ConceptoOBS,
            EstadoOBS,
            CodigoRes,
            Responsable,
            EntidadBancaria,
            NroOperacion,
            Efectivo,
            Deposito
        )
        VALUES
        (
            @NotaDocu,
            @ClienteId,
            GETDATE(),
            @NotaUsuario,
            @NotaFormaPago,
            @NotaCondicion,
            GETDATE(),
            @NotaDireccion,
            @NotaSubtotal,
            @NotaMovilidad,
            @NotaDescuento,
            @NotaTotal,
            @NotaAcuenta,
            @NotaSaldo,
            @NotaAdicional,
            @NotaTarjeta,
            @NotaPagar,
            @NotaEstado,
            @CompaniaId,
            @NotaEntrega,
            '',
            '',
            @NotaConcepto,
            @Serie,
            @cod,
            @NotaGanancia,
            @CajaId,
            @NotaTransaccion,
            @ICBPER,
            @ConceptoOBS,
            @EstadoOBS,
            @CodigoRes,
            @Responsable,
            @EntidadBancaria,
            @NroOperacion,
            @Efectivo,
            @Deposito
        )
        SET @NotaId = SCOPE_IDENTITY();
        INSERT  INTO DocumentoVenta
        (
            CompaniaId,
            NotaId,
            DocuDocumento,
            DocuNumero,
            ClienteId,
            DocuRegistro,
            DocuEmision,
            DocuCondicion,
            DocuLetras,
            DocuSubTotal,
            DocuIgv,
            DocuTotal,
            DocuSaldo,
            DocuUsuario,
            DocuEstado,
            DocuSerie,
            TipoCodigo,
            DocuAdicional,
            DocuAsociado,
            DocuConcepto,
            DocuNroGuia,
            DocuHash,
            EstadoSunat,
            DocuOperacion,
            DocuTransaccion,
            ICBPER,
            CodigoSunat,
            MensajeSunat,
            FormaPago,
            EntidadBancaria,
            NroOperacion,
            Efectivo,
            Deposito
        )
        VALUES
        (
            @CompaniaId,
            @NotaId,
            @NotaDocu,
            @cod,
            @ClienteId,
            GETDATE(),
            GETDATE(),
            @NotaCondicion,
            @Letra,
            @DocuSubtotal,
            @DocuIGV,
            @NotaPagar,
            0,
            @NotaUsuario,
            'EMITIDO',
            @Serie,
            @TipoCodigo,
            @DocuAdicional,
            '',
            'VENTA',
            '',
            @DocuHash,
            CASE WHEN @NotaDocu = 'PROFORMA V' THEN 'ENVIADO' ELSE @EstadoSunat END,
            @NotaConcepto,
            @NotaTransaccion,
            @ICBPER,
            '',
            '',
            @NotaFormaPago,
            @EntidadBancaria,
            @NroOperacion,
            @Efectivo,
            @Deposito
        )
        SET @DocuId = SCOPE_IDENTITY();
        INSERT  INTO dbo.DocumentoVentaCpeWeb
        (
            DocuId,
            ClienteRazon,
            ClienteRuc,
            ClienteDni,
            DireccionFiscal,
            DocuPdfUrl,
            DocuXmlUrl,
            DocuCdrUrl,
            DocuFechaPago
        )
        VALUES
        (
            @DocuId,
            @ClienteRazon,
            @ClienteRuc,
            @ClienteDni,
            @DireccionFiscal,
            '',
            '',
            '',
            GETDATE()
        )
        IF @NotaCondicion = 'ALCONTADO'
           AND @NotaDocu <> 'PROFORMA V'
            BEGIN
                IF UPPER(LTRIM(RTRIM(@ConceptoOBS))) = 'VENTA LIBRE'
                    BEGIN
                        INSERT  INTO dbo.CajaDetalle
                        (
                            CajaId,
                            DetalleFecha,
                            NotaId,
                            DetalleMovimiento,
                            DetalleConcepto,
                            DetalleMonto,
                            DetalleEfectivo,
                            DetalleVuelto,
                            RutaImagen,
                            Estado,
                            Vista,
                            NotaIdB,
                            LiquidaId,
                            FormaPago,
                            EntidadBancaria,
                            NroOperacion
                        )
                        VALUES
                        (
                            @CajaId,
                            GETDATE(),
                            0,
                            'INGRESO',
                            'VENTA LIBRE DOCUMENTO ' + @Serie + '-' + @cod + ' CODIGO: ' + @CodigoCliente + ' (' + @Miembro + ')' + ' FORMA DE PAGO: ' + @NotaFormaPago,
                            @NotaTotal,
                            @NotaTotal,
                            0,
                            @Image,
                            'D',
                            '',
                            @NotaId,
                            '',
                            @NotaFormaPago,
                            @EntidadBancaria,
                            @NroOperacion
                        )
                    END
                IF @Deposito > 0
                   AND UPPER(LTRIM(RTRIM(@ConceptoOBS))) IN ('VENTA', 'IOC', 'CASHBILL', 'VENTA LIBRE')
                    BEGIN
                        INSERT  INTO dbo.CajaDetalle
                        (
                            CajaId,
                            DetalleFecha,
                            NotaId,
                            DetalleMovimiento,
                            DetalleConcepto,
                            DetalleMonto,
                            DetalleEfectivo,
                            DetalleVuelto,
                            RutaImagen,
                            Estado,
                            Vista,
                            NotaIdB,
                            LiquidaId,
                            FormaPago,
                            EntidadBancaria,
                            NroOperacion
                        )
                        VALUES
                        (
                            @CajaId,
                            GETDATE(),
                            0,
                            'SALIDA',
                            'VENTA DEL OBS DOCUMENTO ' + @Serie + '-' + @cod + ' CODIGO: ' + @CodigoCliente + ' (' + @Miembro + ')' + ' FORMA DE PAGO: ' + @NotaFormaPago + ' ENTIDAD BANCARIA: ' + @EntidadBancaria + ' NRO OPERACION: ' + @NroOperacion,
                            @Deposito,
                            @Deposito,
                            0,
                            @Image,
                            'D',
                            '',
                            @NotaId,
                            '',
                            @NotaFormaPago,
                            @EntidadBancaria,
                            @NroOperacion
                        )
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
                        INSERT  INTO @detalleCampos
                        (
                            Pos,
                            Valor
                        )
                        VALUES
                        (
                            @campoPos,
                            SUBSTRING(@Columna, @start, @end - @start)
                        )
                        SET @campoPos = @campoPos + 1;
                        SET @start = @end + 1;
                    END
                DECLARE
                    @IdProducto AS NUMERIC (20),
                    @DetalleCantidad AS DECIMAL (18, 2),
                    @DetalleUm AS VARCHAR (40),
                    @Descripcion AS VARCHAR (MAX),
                    @DetalleCosto AS DECIMAL (18, 4),
                    @DetallePrecio AS DECIMAL (18, 2),
                    @DetallePV AS DECIMAL (18, 2),
                    @DetalleSV AS DECIMAL (18, 2),
                    @DetalleImporte AS DECIMAL (18, 2),
                    @DetalleEstado AS VARCHAR (60),
                    @ValorUM AS DECIMAL (18, 4),
                    @CantidadSaldo AS DECIMAL (18, 2),
                    @IniciaStock AS DECIMAL (18, 2),
                    @StockFinal AS DECIMAL (18, 2);
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
                INSERT  INTO DetallePedido
                (
                    NotaId,
                    IdProducto,
                    DetalleCantidad,
                    DetalleUm,
                    DetalleDescripcion,
                    DetalleCosto,
                    DetallePrecio,
                    DetalleImporte,
                    DetalleEstado,
                    CantidadSaldo,
                    ValorUM,
                    DetallePV,
                    DetalleSV
                )
                VALUES
                (
                    @NotaId,
                    @IdProducto,
                    @DetalleCantidad,
                    @DetalleUm,
                    @Descripcion,
                    @DetalleCosto,
                    @DetallePrecio,
                    @DetalleImporte,
                    @DetalleEstado,
                    @CantidadSaldo,
                    @ValorUM,
                    @DetallePV,
                    @DetalleSV
                )
                IF @DocuId <> 0
                    BEGIN
                        INSERT  INTO DetalleDocumento
                        (
                            DocuId,
                            IdProducto,
                            DetalleCantidad,
                            DetallPrecio,
                            DetalleImporte,
                            DetalleNotaId,
                            DetalleUM,
                            ValorUM
                        )
                        VALUES
                        (
                            @DocuId,
                            @IdProducto,
                            @DetalleCantidad,
                            @DetallePrecio,
                            @DetalleImporte,
                            @NotaId,
                            @DetalleUm,
                            @ValorUM
                        )
                    END
                IF @NotaDocu <> 'FACTURA'
                    BEGIN
                        SELECT TOP 1 @IniciaStock = ProductoCantidad
                        FROM   Producto
                        WHERE  IdProducto = @IdProducto;
                        SET @IniciaStock = ISNULL(@IniciaStock, 0);
                        SET @StockFinal = @IniciaStock - @DetalleCantidad;
                        INSERT  INTO Kardex
                        (
                            IdProducto,
                            KardexFecha,
                            KardexMotivo,
                            KardexDocumento,
                            StockInicial,
                            CantidadIngreso,
                            CantidadSalida,
                            PrecioCosto,
                            StockFinal,
                            KadexConcepto,
                            Usuario,
                            CLIENTE,
                            CODIGOCLIENTE,
                            NROTRANSAC,
                            TipoCodigo,
                            Serie,
                            TipoOperacion,
                            Consideracion,
                            DocuId,
                            CompraId,
                            Estado
                        )
                        VALUES
                        (
                            @IdProducto,
                            GETDATE(),
                            'Salida por Venta',
                            @cod,
                            @IniciaStock,
                            0,
                            @DetalleCantidad,
                            @DetalleCosto,
                            @StockFinal,
                            'SALIDA',
                            @NotaUsuario,
                            @Miembro,
                            @CodigoCliente,
                            @NotaTransaccion,
                            @TipoCodigo,
                            @Serie,
                            '01',
                            CASE WHEN @NotaEntrega = 'INMEDIATA' THEN 'S' ELSE 'N' END,
                            CONVERT (VARCHAR (40), @DocuId),
                            '',
                            'E'
                        )
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
        DECLARE
            @ErrMsg AS NVARCHAR (4000),
            @ErrSeverity AS INT,
            @ErrState AS INT;
        SELECT @ErrMsg = ERROR_MESSAGE(),
               @ErrSeverity = ERROR_SEVERITY(),
               @ErrState = ERROR_STATE();
        RAISERROR (@ErrMsg, @ErrSeverity, @ErrState);
    END CATCH
END
GO
