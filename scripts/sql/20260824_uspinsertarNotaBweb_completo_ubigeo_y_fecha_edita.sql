ALTER PROCEDURE dbo.uspinsertarNotaBweb
    @ListaOrden varchar(max)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @pos1 int,
        @orden varchar(max),
        @detalle varchar(max);

    SET @pos1 = CHARINDEX('[', @ListaOrden, 1);

    IF @pos1 <= 0
    BEGIN
        RAISERROR('Formato de orden invalido.', 16, 1);
        RETURN;
    END;

    SET @orden = SUBSTRING(
        @ListaOrden,
        1,
        @pos1 - 1
    );

    SET @detalle = SUBSTRING(
        @ListaOrden,
        @pos1 + 1,
        LEN(@ListaOrden) - @pos1
    );

    DECLARE @campos TABLE
    (
        Pos int IDENTITY(1,1) NOT NULL,
        Valor varchar(max) NULL
    );

    DECLARE
        @start int,
        @end int;

    SET @start = 1;

    WHILE @start <= LEN(@orden) + 1
    BEGIN
        SET @end = CHARINDEX('|', @orden, @start);

        IF @end = 0
            SET @end = LEN(@orden) + 1;

        INSERT INTO @campos
        (
            Valor
        )
        VALUES
        (
            SUBSTRING(
                @orden,
                @start,
                @end - @start
            )
        );

        SET @start = @end + 1;
    END;

    DECLARE
        @NotaDocu varchar(60),
        @ClienteId numeric(20),
        @NotaUsuario varchar(60),
        @NotaFormaPago varchar(60),
        @NotaCondicion varchar(60),
        @NotaDireccion varchar(max),
        @CompaniaUbigeo varchar(250),

        @NotaSubtotal decimal(18,2),
        @NotaMovilidad decimal(18,2),
        @NotaDescuento decimal(18,2),
        @NotaTotal decimal(18,2),
        @NotaAcuenta decimal(18,2),
        @NotaSaldo decimal(18,2),
        @NotaAdicional decimal(18,2),
        @NotaTarjeta decimal(18,2),
        @NotaPagar decimal(18,2),

        @NotaEstado varchar(60),
        @CompaniaId int,
        @NotaEntrega varchar(40),
        @NotaConcepto varchar(60),

        @Serie varchar(60),
        @Numero varchar(60),
        @NotaGanancia decimal(18,2),

        @Letra varchar(max),
        @DocuAdicional decimal(18,2),
        @DocuHash varchar(250),
        @EstadoSunat varchar(80),
        @DocuSubtotal decimal(18,2),
        @DocuIGV decimal(18,2),

        @UsuarioId int,
        @NotaTransaccion varchar(250),
        @Miembro varchar(300),
        @CodigoCliente varchar(80),

        @ICBPER decimal(18,2),
        @DocuGravada decimal(18,2),

        @ConceptoOBS varchar(80),
        @EstadoOBS varchar(20),
        @PV varchar(40),
        @Image varchar(max),

        @CodigoRes varchar(80),
        @Responsable varchar(300),

        @EntidadBancaria varchar(80),
        @Efectivo decimal(18,2),
        @Deposito decimal(18,2),
        @NroOperacion varchar(80),

        @ClienteRazon varchar(140),
        @ClienteRuc varchar(40),
        @ClienteDni varchar(40),
        @DireccionFiscal varchar(max),

        @TipoCodigo char(20),
        @cod varchar(60),

        @NotaId numeric(38),
        @DocuId numeric(38);

    SELECT @NotaDocu = Valor
    FROM @campos
    WHERE Pos = 1;

    SELECT @ClienteId =
        CONVERT(
            numeric(20),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 2;

    SELECT @NotaUsuario = Valor
    FROM @campos
    WHERE Pos = 3;

    SELECT @NotaFormaPago = Valor
    FROM @campos
    WHERE Pos = 4;

    SELECT @NotaCondicion = Valor
    FROM @campos
    WHERE Pos = 5;

    SELECT @NotaDireccion = Valor
    FROM @campos
    WHERE Pos = 6;

    SELECT @NotaSubtotal =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 7;

    SELECT @NotaMovilidad =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 8;

    SELECT @NotaDescuento =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 9;

    SELECT @NotaTotal =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 10;

    SELECT @NotaAcuenta =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 11;

    SELECT @NotaSaldo =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 12;

    SELECT @NotaAdicional =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 13;

    SELECT @NotaTarjeta =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 14;

    SELECT @NotaPagar =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 15;

    SELECT @NotaEstado = Valor
    FROM @campos
    WHERE Pos = 16;

    SELECT @CompaniaId =
        CONVERT(
            int,
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 17;

    SELECT @NotaEntrega = Valor
    FROM @campos
    WHERE Pos = 18;

    SELECT @NotaConcepto = Valor
    FROM @campos
    WHERE Pos = 19;

    SELECT @Serie = Valor
    FROM @campos
    WHERE Pos = 20;

    SELECT @Numero = Valor
    FROM @campos
    WHERE Pos = 21;

    SELECT @NotaGanancia =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 22;

    SELECT @Letra = Valor
    FROM @campos
    WHERE Pos = 23;

    SELECT @DocuAdicional =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 24;

    SELECT @DocuHash = Valor
    FROM @campos
    WHERE Pos = 25;

    SELECT @EstadoSunat = Valor
    FROM @campos
    WHERE Pos = 26;

    SELECT @DocuSubtotal =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 27;

    SELECT @DocuIGV =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 28;

    SELECT @UsuarioId =
        CONVERT(
            int,
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 29;

    SELECT @NotaTransaccion = Valor
    FROM @campos
    WHERE Pos = 30;

    SELECT @Miembro = Valor
    FROM @campos
    WHERE Pos = 31;

    SELECT @CodigoCliente = Valor
    FROM @campos
    WHERE Pos = 32;

    SELECT @ICBPER =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 33;

    SELECT @DocuGravada =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 34;

    SELECT @ConceptoOBS = Valor
    FROM @campos
    WHERE Pos = 35;

    SELECT @EstadoOBS = Valor
    FROM @campos
    WHERE Pos = 36;

    SELECT @PV = Valor
    FROM @campos
    WHERE Pos = 37;

    SELECT @Image = Valor
    FROM @campos
    WHERE Pos = 38;

    SELECT @CodigoRes = Valor
    FROM @campos
    WHERE Pos = 39;

    SELECT @Responsable = Valor
    FROM @campos
    WHERE Pos = 40;

    SELECT @EntidadBancaria = Valor
    FROM @campos
    WHERE Pos = 41;

    SELECT @Efectivo =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 42;

    SELECT @Deposito =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 43;

    SELECT @NroOperacion = Valor
    FROM @campos
    WHERE Pos = 44;

    SET @NotaDocu =
        ISNULL(
            NULLIF(LTRIM(RTRIM(@NotaDocu)), ''),
            'BOLETA'
        );

    SET @NotaUsuario =
        ISNULL(@NotaUsuario, '');

    SET @NotaFormaPago =
        ISNULL(
            NULLIF(@NotaFormaPago, ''),
            'EFECTIVO'
        );

    SET @NotaCondicion =
        ISNULL(
            NULLIF(@NotaCondicion, ''),
            'ALCONTADO'
        );

    SET @NotaDireccion =
        ISNULL(
            NULLIF(@NotaDireccion, ''),
            '-'
        );

    SET @NotaEstado =
        ISNULL(
            NULLIF(@NotaEstado, ''),
            'PENDIENTE'
        );

    SET @CompaniaId =
        ISNULL(
            NULLIF(@CompaniaId, 0),
            1
        );

    SET @NotaEntrega =
        ISNULL(
            NULLIF(@NotaEntrega, ''),
            'INMEDIATA'
        );

    SET @NotaConcepto =
        ISNULL(
            NULLIF(@NotaConcepto, ''),
            'MERCADERIA'
        );

    SET @Serie =
        ISNULL(
            NULLIF(@Serie, ''),
            CASE
                WHEN @NotaDocu = 'FACTURA'
                    THEN 'FA01'
                ELSE 'BA01'
            END
        );

    SET @Letra = ISNULL(@Letra, '');
    SET @DocuHash = ISNULL(@DocuHash, '');

    SET @EstadoSunat =
        ISNULL(
            NULLIF(@EstadoSunat, ''),
            'PENDIENTE'
        );

    SET @NotaTransaccion = ISNULL(@NotaTransaccion, '');
    SET @Miembro = ISNULL(@Miembro, '');
    SET @CodigoCliente = ISNULL(@CodigoCliente, '');

    SET @ConceptoOBS =
        ISNULL(
            NULLIF(@ConceptoOBS, ''),
            'VENTA'
        );

    SET @EstadoOBS =
        ISNULL(
            NULLIF(@EstadoOBS, ''),
            'EMITIDO'
        );

    SET @CodigoRes = ISNULL(@CodigoRes, '');
    SET @Responsable = ISNULL(@Responsable, '');

    SET @EntidadBancaria =
        ISNULL(
            NULLIF(@EntidadBancaria, ''),
            '-'
        );

    SET @NroOperacion =
        ISNULL(@NroOperacion, '');

    IF @NotaDocu = 'FACTURA'
        SET @TipoCodigo = '01';
    ELSE IF @NotaDocu = 'PROFORMA V'
        SET @TipoCodigo = '00';
    ELSE
        SET @TipoCodigo = '03';

    SELECT TOP 1
        @ClienteRazon =
            NULLIF(
                LTRIM(RTRIM(ClienteRazon)),
                ''
            ),

        @ClienteRuc =
            NULLIF(
                LTRIM(RTRIM(ClienteRuc)),
                ''
            ),

        @ClienteDni =
            NULLIF(
                LTRIM(RTRIM(ClienteDni)),
                ''
            ),

        @DireccionFiscal =
            NULLIF(
                LTRIM(RTRIM(ClienteDireccion)),
                ''
            )
    FROM Cliente
    WHERE ClienteId = @ClienteId;

    SET @ClienteRazon =
        ISNULL(
            @ClienteRazon,
            CASE
                WHEN @Miembro <> ''
                    THEN @Miembro
                ELSE 'VARIOS'
            END
        );

    SET @ClienteRuc = ISNULL(@ClienteRuc, '');
    SET @ClienteDni = ISNULL(@ClienteDni, '');

    IF @NotaDocu = 'BOLETA'
       AND @ClienteRuc = ''
       AND @ClienteDni = ''
    BEGIN
        SET @ClienteDni = '00000000';
    END;

    SET @DireccionFiscal =
        ISNULL(
            @DireccionFiscal,
            @NotaDireccion
        );

    IF NULLIF(@DireccionFiscal, '') IS NULL
        SET @DireccionFiscal = '-';

    IF @NotaFormaPago <> 'EFECTIVO'
    BEGIN
        IF @Efectivo IS NULL
            SET @Efectivo = 0;

        IF @Deposito IS NULL
           OR @Deposito = 0
            SET @Deposito = @NotaPagar;
    END;
    ELSE
    BEGIN
        IF @Efectivo IS NULL
           OR @Efectivo = 0
            SET @Efectivo = @NotaPagar;

        IF @Deposito IS NULL
            SET @Deposito = 0;
    END;

    IF @NotaCondicion = 'CREDITO'
    BEGIN
        SET @NotaEstado = 'EMITIDO';
        SET @NotaSaldo = @NotaPagar;
        SET @NotaAcuenta = 0;
    END;
    ELSE IF @NotaDocu <> 'FACTURA'
        AND @NotaDocu <> 'PROFORMA V'
    BEGIN
        SET @NotaEstado = 'CANCELADO';
        SET @NotaSaldo = 0;
        SET @NotaAcuenta = @NotaPagar;
    END;

    IF @NotaTransaccion <> ''
       AND EXISTS
       (
            SELECT 1
            FROM NotaPedido
            WHERE NotaTransaccion = @NotaTransaccion
              AND ISNULL(NotaEstado, '') <> 'ANULADO'
       )
    BEGIN
        SELECT 'EXISTE';
        RETURN;
    END;

    IF @Deposito > 0
       AND NULLIF(LTRIM(RTRIM(@NroOperacion)), '') IS NULL
    BEGIN
        SELECT 'OPERACION_REQUERIDA';
        RETURN;
    END;

    IF @NroOperacion <> ''
       AND ISNULL(@EntidadBancaria, '-') <> '-'
       AND EXISTS
       (
            SELECT 1
            FROM NotaPedido
            WHERE EntidadBancaria = @EntidadBancaria
              AND NroOperacion = @NroOperacion
              AND ISNULL(NotaEstado, '') <> 'ANULADO'
       )
    BEGIN
        SELECT 'OPERACION';
        RETURN;
    END;

    DECLARE @CajaId numeric(38);

    SELECT TOP (1)
        @CajaId = CajaId
    FROM Caja
    WHERE CajaEstado = 'ACTIVO'
      AND UsuarioId = @UsuarioId
    ORDER BY CajaId DESC;

    IF ISNULL(@CajaId, 0) = 0
    BEGIN
        SELECT 'false';
        RETURN;
    END;

    SELECT @CompaniaUbigeo = NULLIF(LTRIM(RTRIM(CompaniaNomUBG)), '')
    FROM Compania
    WHERE CompaniaId = @CompaniaId;

    SET @CompaniaUbigeo = ISNULL(@CompaniaUbigeo, '');

    BEGIN TRY

        BEGIN TRANSACTION;

        UPDATE Cliente
        SET ClienteDespacho = @NotaDireccion
        WHERE ClienteId = @ClienteId;

        SET @NotaDireccion = @CompaniaUbigeo;

        DELETE FROM TemporalVenta
        WHERE UsuarioID = @UsuarioId;

        SELECT @cod =
            ISNULL(
                (
                    SELECT TOP 1
                        dbo.genenerarNroFactura(
                            @Serie,
                            @CompaniaId,
                            @NotaDocu
                        )
                    FROM DocumentoVenta
                ),
                '00000001'
            );

        INSERT INTO NotaPedido
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
        );

        SET @NotaId = SCOPE_IDENTITY();

        INSERT INTO DocumentoVenta
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

            CASE
                WHEN @NotaDocu = 'PROFORMA V'
                    THEN 'ENVIADO'
                ELSE @EstadoSunat
            END,

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
        );

        SET @DocuId = SCOPE_IDENTITY();

        INSERT INTO dbo.DocumentoVentaCpeWeb
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
        );

        IF @NotaCondicion = 'ALCONTADO'
           AND @NotaDocu <> 'PROFORMA V'
        BEGIN
            IF UPPER(LTRIM(RTRIM(@ConceptoOBS))) = 'VENTA LIBRE'
            BEGIN
                INSERT INTO dbo.CajaDetalle
                (
                    CajaId, DetalleFecha, NotaId, DetalleMovimiento,
                    DetalleConcepto, DetalleMonto, DetalleEfectivo,
                    DetalleVuelto, RutaImagen, Estado, Vista,
                    NotaIdB, LiquidaId, FormaPago, EntidadBancaria, NroOperacion
                )
                VALUES
                (
                    @CajaId, GETDATE(), 0, 'INGRESO',
                    'VENTA LIBRE DOCUMENTO ' + @Serie + '-' + @cod +
                    ' CODIGO: ' + @CodigoCliente + ' (' + @Miembro + ')' +
                    ' FORMA DE PAGO: ' + @NotaFormaPago,
                    @NotaTotal, @NotaTotal, 0, @Image, 'D', '',
                    @NotaId, '', @NotaFormaPago, @EntidadBancaria, @NroOperacion
                );
            END;

            IF @Deposito > 0
               AND UPPER(LTRIM(RTRIM(@ConceptoOBS))) IN ('VENTA', 'IOC', 'CASHBILL', 'VENTA LIBRE')
            BEGIN
                INSERT INTO dbo.CajaDetalle
                (
                    CajaId, DetalleFecha, NotaId, DetalleMovimiento,
                    DetalleConcepto, DetalleMonto, DetalleEfectivo,
                    DetalleVuelto, RutaImagen, Estado, Vista,
                    NotaIdB, LiquidaId, FormaPago, EntidadBancaria, NroOperacion
                )
                VALUES
                (
                    @CajaId, GETDATE(), 0, 'SALIDA',
                    'VENTA DEL OBS DOCUMENTO ' + @Serie + '-' + @cod +
                    ' CODIGO: ' + @CodigoCliente + ' (' + @Miembro + ')' +
                    ' FORMA DE PAGO: ' + @NotaFormaPago +
                    ' ENTIDAD BANCARIA: ' + @EntidadBancaria +
                    ' NRO OPERACION: ' + @NroOperacion,
                    @Deposito, @Deposito, 0, @Image, 'D', '',
                    @NotaId, '', @NotaFormaPago, @EntidadBancaria, @NroOperacion
                );
            END;
        END;

        DECLARE detalle_cursor CURSOR LOCAL FAST_FORWARD
        FOR
            SELECT splitdata
            FROM dbo.fnSplitString(@detalle, ';')
            WHERE LEN(LTRIM(RTRIM(splitdata))) > 0;

        DECLARE @Columna varchar(max);

        DECLARE @detalleCampos TABLE
        (
            Pos int NOT NULL PRIMARY KEY,
            Valor varchar(max) NULL
        );

        DECLARE @campoPos int;

        OPEN detalle_cursor;

        FETCH NEXT FROM detalle_cursor
        INTO @Columna;

        WHILE @@FETCH_STATUS = 0
        BEGIN

            DELETE FROM @detalleCampos;

            SET @campoPos = 1;
            SET @start = 1;

            WHILE @start <= LEN(@Columna) + 1
            BEGIN

                SET @end =
                    CHARINDEX(
                        '|',
                        @Columna,
                        @start
                    );

                IF @end = 0
                    SET @end = LEN(@Columna) + 1;

                INSERT INTO @detalleCampos
                (
                    Pos,
                    Valor
                )
                VALUES
                (
                    @campoPos,
                    SUBSTRING(
                        @Columna,
                        @start,
                        @end - @start
                    )
                );

                SET @campoPos = @campoPos + 1;
                SET @start = @end + 1;
            END;

            DECLARE
                @IdProducto numeric(20),
                @DetalleCantidad decimal(18,2),
                @DetalleUm varchar(40),
                @Descripcion varchar(max),
                @DetalleCosto decimal(18,4),
                @DetallePrecio decimal(18,2),
                @DetallePV decimal(18,2),
                @DetalleSV decimal(18,2),
                @DetalleImporte decimal(18,2),
                @DetalleEstado varchar(60),
                @ValorUM decimal(18,4),
                @CantidadSaldo decimal(18,2),
                @IniciaStock decimal(18,2),
                @StockFinal decimal(18,2);

            SELECT @IdProducto =
                CONVERT(
                    numeric(20),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 1;

            SELECT @DetalleCantidad =
                CONVERT(
                    decimal(18,2),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 2;

            SELECT @DetalleUm = Valor
            FROM @detalleCampos
            WHERE Pos = 3;

            SELECT @Descripcion = Valor
            FROM @detalleCampos
            WHERE Pos = 4;

            SELECT @DetalleCosto =
                CONVERT(
                    decimal(18,4),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 5;

            SELECT @DetallePrecio =
                CONVERT(
                    decimal(18,2),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 6;

            SELECT @DetallePV =
                CONVERT(
                    decimal(18,2),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 7;

            SELECT @DetalleSV =
                CONVERT(
                    decimal(18,2),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 8;

            SELECT @DetalleImporte =
                CONVERT(
                    decimal(18,2),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 9;

            SELECT @DetalleEstado = Valor
            FROM @detalleCampos
            WHERE Pos = 10;

            SELECT @ValorUM =
                CONVERT(
                    decimal(18,4),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 11;

            SET @DetalleUm =
                ISNULL(
                    NULLIF(@DetalleUm, ''),
                    'UNIDAD'
                );

            SET @Descripcion =
                ISNULL(@Descripcion, '');

            SET @DetalleEstado =
                ISNULL(
                    NULLIF(@DetalleEstado, ''),
                    'PENDIENTE'
                );

            IF @ValorUM IS NULL
               OR @ValorUM = 0
            BEGIN
                SET @ValorUM = 1;
            END;

            IF @NotaEntrega = 'INMEDIATA'
                SET @CantidadSaldo = 0;
            ELSE
                SET @CantidadSaldo = @DetalleCantidad;

            INSERT INTO DetallePedido
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
            );

            IF @DocuId <> 0
            BEGIN

                INSERT INTO DetalleDocumento
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
                );

            END;

            IF @NotaDocu <> 'FACTURA'
            BEGIN

                SELECT TOP 1
                    @IniciaStock = ProductoCantidad
                FROM Producto
                WHERE IdProducto = @IdProducto;

                SET @IniciaStock =
                    ISNULL(@IniciaStock, 0);

                SET @StockFinal =
                    @IniciaStock - @DetalleCantidad;

                INSERT INTO Kardex
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

                    CASE
                        WHEN @NotaEntrega = 'INMEDIATA'
                            THEN 'S'
                        ELSE 'N'
                    END,

                    CONVERT(varchar(40), @DocuId),
                    '',
                    'E'
                );

                IF @NotaEntrega = 'INMEDIATA'
                BEGIN

                    UPDATE Producto
                    SET ProductoCantidad =
                        ProductoCantidad - @DetalleCantidad
                    WHERE IdProducto = @IdProducto;

                END;

            END;

            FETCH NEXT FROM detalle_cursor
            INTO @Columna;

        END;

        CLOSE detalle_cursor;
        DEALLOCATE detalle_cursor;

        COMMIT TRANSACTION;

        SELECT
            CONVERT(varchar(38), @NotaId)
            + N'¬'
            + @cod;

    END TRY

    BEGIN CATCH

        IF CURSOR_STATUS('local', 'detalle_cursor') > -1
        BEGIN
            CLOSE detalle_cursor;
            DEALLOCATE detalle_cursor;
        END;

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE
            @ErrMsg nvarchar(4000),
            @ErrSeverity int,
            @ErrState int;

        SELECT
            @ErrMsg = ERROR_MESSAGE(),
            @ErrSeverity = ERROR_SEVERITY(),
            @ErrState = ERROR_STATE();

        RAISERROR(
            @ErrMsg,
            @ErrSeverity,
            @ErrState
        );

    END CATCH;

END;
