/*
  Complemento autónomo para DXN_ICA: contratos SQL del backend web.
  No modifica código C#.
*/
USE [DXN_ICA];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
GO

/* Esquema mínimo requerido por procedimientos y endpoints web. */
IF COL_LENGTH('dbo.Compania','TIPO_PROCESO') IS NULL
    ALTER TABLE dbo.Compania ADD TIPO_PROCESO int NULL;
IF COL_LENGTH('dbo.Compania','DescuentoMax') IS NULL
    ALTER TABLE dbo.Compania ADD DescuentoMax decimal(18,2) NULL;
IF COL_LENGTH('dbo.Compania','CorreoSGO') IS NULL
    ALTER TABLE dbo.Compania ADD CorreoSGO varchar(250) NULL;
IF COL_LENGTH('dbo.Compania','PasswordCorreo') IS NULL
    ALTER TABLE dbo.Compania ADD PasswordCorreo varchar(250) NULL;
IF COL_LENGTH('dbo.Compania','BoletaPorLote') IS NULL
    ALTER TABLE dbo.Compania ADD BoletaPorLote bit NOT NULL CONSTRAINT DF_Compania_BoletaPorLote DEFAULT(0) WITH VALUES;
IF COL_LENGTH('dbo.Compania','FlagCaptura') IS NULL
    ALTER TABLE dbo.Compania ADD FlagCaptura bit NOT NULL CONSTRAINT DF_Compania_FlagCaptura DEFAULT(0) WITH VALUES;
IF COL_LENGTH('dbo.Usuarios','FechaVencimientoClave') IS NULL
    ALTER TABLE dbo.Usuarios ADD FechaVencimientoClave date NULL;
IF COL_LENGTH('dbo.ResumenBoletas','CDRBase64') IS NULL
    ALTER TABLE dbo.ResumenBoletas ADD CDRBase64 varchar(max) NULL;
IF COL_LENGTH('dbo.UnidadMedida','unidadImagen') IS NULL
    ALTER TABLE dbo.UnidadMedida ADD unidadImagen varchar(255) NULL;
IF COL_LENGTH('dbo.Producto','ProductoVentaB') IS NULL
    ALTER TABLE dbo.Producto ADD ProductoVentaB decimal(18,2) NULL;
IF COL_LENGTH('dbo.Producto','AplicaINV') IS NULL
    ALTER TABLE dbo.Producto ADD AplicaINV varchar(1) NULL;
GO

IF OBJECT_ID('dbo.DocumentoVentaCpeWeb','U') IS NULL
BEGIN
    CREATE TABLE dbo.DocumentoVentaCpeWeb
    (
        DocuId numeric(38,0) NOT NULL,
        ClienteRazon varchar(140) NULL,
        ClienteRuc varchar(40) NULL,
        ClienteDni varchar(40) NULL,
        DireccionFiscal varchar(max) NULL,
        DocuPdfUrl varchar(500) NULL,
        DocuXmlUrl varchar(500) NULL,
        DocuCdrUrl varchar(500) NULL,
        DocuFechaPago date NULL,
        FechaRegistro datetime NOT NULL CONSTRAINT DF_DocumentoVentaCpeWeb_FechaRegistro DEFAULT(GETDATE()),
        CONSTRAINT PK_DocumentoVentaCpeWeb PRIMARY KEY(DocuId)
    );
END;
GO

/* LDdocumentosweb */

-- ============================================================
-- LDdocumentosweb
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.LDdocumentosweb
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Cabecera VARCHAR(MAX) =
        'Fecha|Documento|NroDoc|Cliente|RUC|DNI|SubTotal|IGV|ICBPER|Total|Usuario|Estado|Referencia|Codigo|Mensaje|Condicion|FormaPago|Entidad|NroOperacion|Efectivo|Deposito';

    DECLARE @Anchos VARCHAR(MAX) =
        '85|90|110|250|80|80|115|115|90|115|150|150|110|0|0|0|0|0|0|0|0';

    DECLARE @Detalle VARCHAR(MAX);

    IF @FechaInicio IS NULL
       OR @FechaFin IS NULL
    BEGIN
        SELECT @Cabecera + '¬' + @Anchos;
        RETURN;
    END;

    IF @FechaInicio > @FechaFin
    BEGIN
        DECLARE @FechaTemporal DATE = @FechaInicio;

        SET @FechaInicio = @FechaFin;
        SET @FechaFin = @FechaTemporal;
    END;

    SET @Detalle =
    (
        SELECT STUFF(
        (
            SELECT
                '¬'
                + CONVERT(CHAR(10), d.DocuEmision, 103) + '|'
                + d.DocuDocumento + '|'
                + CONVERT(VARCHAR, d.DocuSerie + '-' + d.DocuNumero) + '|'
                + c.ClienteRazon + '|'
                + ISNULL(c.ClienteRuc, '') + '|'
                + ISNULL(c.ClienteDni, '') + '|'
                + CASE
                    WHEN d.TipoCodigo = '07' THEN '-'
                    ELSE ''
                  END
                + CONVERT(VARCHAR(50), CAST(d.DocuSubTotal AS MONEY), 1) + '|'
                + CASE
                    WHEN d.TipoCodigo = '07' THEN '-'
                    ELSE ''
                  END
                + CONVERT(VARCHAR(50), CAST(d.DocuIgv AS MONEY), 1) + '|'
                + CASE
                    WHEN d.TipoCodigo = '07' THEN '-'
                    ELSE ''
                  END
                + CONVERT(VARCHAR(50), CAST(d.ICBPER AS MONEY), 1) + '|'
                + CASE
                    WHEN d.TipoCodigo = '07' THEN '-'
                    ELSE ''
                  END
                + CONVERT(VARCHAR(50), CAST(d.DocuTotal AS MONEY), 1) + '|'
                + d.DocuUsuario + '|'
                + d.DocuEstado + '|'
                + d.DocuNroGuia + '|'
                + d.CodigoSunat + '|'
                + REPLACE(d.MensajeSunat, '|', ' ') + '|'
                + d.DocuCondicion + '|'
                + d.FormaPago + '|'
                + d.EntidadBancaria + '|'
                + d.NroOperacion + '|'
                + CONVERT(VARCHAR(50), CAST(d.Efectivo AS MONEY), 1) + '|'
                + CONVERT(VARCHAR(50), CAST(d.Deposito AS MONEY), 1)
            FROM DocumentoVenta AS d
            INNER JOIN Cliente AS c
                ON c.ClienteId = d.ClienteId
            WHERE d.DocuEmision >= @FechaInicio
              AND d.DocuEmision < DATEADD(DAY, 1, @FechaFin)
              AND d.DocuDocumento <> 'PROFORMA V'
            ORDER BY
                d.DocuEmision,
                d.DocuSerie + '-' + d.DocuNumero
            FOR XML PATH('')
        ),
        1,
        1,
        '')
    );

    SELECT
        @Cabecera
        + '¬'
        + @Anchos
        + CASE
            WHEN NULLIF(LTRIM(RTRIM(@Detalle)), '') IS NULL
                THEN ''
            ELSE '¬' + @Detalle
          END;
END;
GO

/* uspCajaInsertaCsvWeb */

CREATE OR ALTER PROCEDURE dbo.uspCajaInsertaCsvWeb
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @p1 int, @p2 int, @p3 int, @p4 int, @p5 int, @p6 int,
            @p7 int, @p8 int, @p9 int, @p10 int, @p11 int, @p12 int;
    DECLARE @CajaId numeric(38), @CajaCierre varchar(40), @MontoIniSOl decimal(18, 2),
            @CajaEncargado varchar(60), @CajaUsuario varchar(60), @CajaEstado varchar(40),
            @CajaIngresos decimal(18, 2), @CajaDeposito decimal(18, 2),
            @CajaSalidas decimal(18, 2), @CajaTotal decimal(18, 2), @UsuarioId int,
            @Observacion varchar(max), @CompaniaId int, @FlagCaja bit = 0;

    SET @Data = LTRIM(RTRIM(@Data));
    SET @p1 = CHARINDEX('|', @Data, 0);
    SET @p2 = CHARINDEX('|', @Data, @p1 + 1);
    SET @p3 = CHARINDEX('|', @Data, @p2 + 1);
    SET @p4 = CHARINDEX('|', @Data, @p3 + 1);
    SET @p5 = CHARINDEX('|', @Data, @p4 + 1);
    SET @p6 = CHARINDEX('|', @Data, @p5 + 1);
    SET @p7 = CHARINDEX('|', @Data, @p6 + 1);
    SET @p8 = CHARINDEX('|', @Data, @p7 + 1);
    SET @p9 = CHARINDEX('|', @Data, @p8 + 1);
    SET @p10 = CHARINDEX('|', @Data, @p9 + 1);
    SET @p11 = CHARINDEX('|', @Data, @p10 + 1);
    SET @p12 = LEN(@Data) + 1;

    SET @CajaId = CONVERT(numeric(38), SUBSTRING(@Data, 1, @p1 - 1));
    SET @CajaCierre = SUBSTRING(@Data, @p1 + 1, @p2 - @p1 - 1);
    SET @MontoIniSOl = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p2 + 1, @p3 - @p2 - 1));
    SET @CajaEncargado = SUBSTRING(@Data, @p3 + 1, @p4 - @p3 - 1);
    SET @CajaUsuario = SUBSTRING(@Data, @p4 + 1, @p5 - @p4 - 1);
    SET @CajaEstado = SUBSTRING(@Data, @p5 + 1, @p6 - @p5 - 1);
    SET @CajaIngresos = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p6 + 1, @p7 - @p6 - 1));
    SET @CajaDeposito = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p7 + 1, @p8 - @p7 - 1));
    SET @CajaSalidas = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p8 + 1, @p9 - @p8 - 1));
    SET @CajaTotal = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p9 + 1, @p10 - @p9 - 1));
    SET @UsuarioId = CONVERT(int, SUBSTRING(@Data, @p10 + 1, @p11 - @p10 - 1));
    SET @Observacion = SUBSTRING(@Data, @p11 + 1, @p12 - @p11 - 1);

    IF @CajaId = 0
    BEGIN
        BEGIN TRANSACTION;

        SELECT @CompaniaId = p.CompaniaId
          FROM dbo.Usuarios u WITH (UPDLOCK, HOLDLOCK)
          INNER JOIN dbo.Personal p ON p.PersonalId = u.PersonalId
         WHERE u.UsuarioID = @UsuarioId;

        SELECT @FlagCaja = ISNULL(c.FlagCaja, 0)
          FROM dbo.Compania c WITH (UPDLOCK, HOLDLOCK)
         WHERE c.CompaniaId = @CompaniaId;

        IF ISNULL(@FlagCaja, 0) = 0
           AND EXISTS
           (
               SELECT 1
                 FROM dbo.Caja c WITH (UPDLOCK, HOLDLOCK)
                 INNER JOIN dbo.Usuarios u ON u.UsuarioID = c.UsuarioId
                 INNER JOIN dbo.Personal p ON p.PersonalId = u.PersonalId
                WHERE c.CajaEstado = 'ACTIVO'
                  AND p.CompaniaId = @CompaniaId
           )
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'SOLO_UNA_CAJA';
            RETURN;
        END;

        INSERT INTO dbo.Caja
        VALUES (GETDATE(), @CajaCierre, @MontoIniSOl, @CajaEncargado, @CajaUsuario,
                @CajaEstado, @CajaIngresos, @CajaDeposito, @CajaSalidas, @CajaTotal,
                @UsuarioId, @Observacion);
        SET @CajaId = @@IDENTITY;

        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'TOTAL EFECTIVO', 0, 0, 0, '', 'T', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'VITRINA', 0, 0, 0, '', 'D', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'SENCILLO', 0, 0, 0, '', 'T', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'IOC', 0, 0, 0, '', 'T', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'REVISTAS', 0, 0, 0, '', 'D', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'COPIAS Y OTROS', 0, 0, 0, '', 'D', 'V', 0, '', '', '', '');
        INSERT INTO dbo.Monedas VALUES (0, 0, '200.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '100.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '50.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '20.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '10.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '5.00', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '2.00', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '1.00', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '0.50', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '0.20', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '0.10', 0, 'M', @CajaId);

        COMMIT TRANSACTION;
        SELECT 'true';
        RETURN;
    END;

    IF @CajaEstado = 'CERRADA'
    BEGIN
        DECLARE @Descripcion varchar(max);
        SET @Descripcion = ISNULL((SELECT TOP 1 d.DetalleConcepto + ' TOTAL S/ ' + CONVERT(varchar(max), CAST(d.DetalleMonto AS money), 1)
                                    FROM dbo.CajaDetalle d
                                    WHERE d.RutaImagen LIKE '%file.png%'
                                      AND d.CajaId = @CajaId
                                      AND d.NotaId = 0
                                      AND d.DetalleMonto >= 500000
                                    ORDER BY d.DetalleId ASC), '0');
        IF @Descripcion <> '0'
        BEGIN
            SELECT 'Falta Adjuntar el Archivo de: ' + @Descripcion;
            RETURN;
        END;
    END;

    UPDATE dbo.Caja
       SET CajaCierre = @CajaCierre,
           MontoIniSOl = @MontoIniSOl,
           CajaEncargado = @CajaEncargado,
           CajaUsuario = @CajaUsuario,
           CajaEstado = @CajaEstado,
           CajaIngresos = @CajaIngresos,
           CajaDeposito = @CajaDeposito,
           CajaSalidas = @CajaSalidas,
           CajaTotal = @CajaTotal,
           UsuarioId = @UsuarioId,
           Observacion = @Observacion
     WHERE CajaId = @CajaId;
    SELECT 'true';
END;
GO

/* uspEditarConteoCajaWEB */
CREATE OR ALTER PROCEDURE dbo.uspEditarConteoCajaWEB @ListaOrden varchar(max) AS BEGIN SET NOCOUNT ON; EXEC dbo.uspEditarConteoCaja @ListaOrden = @ListaOrden; END
GO

/* uspEditarRBweb */

CREATE OR ALTER PROCEDURE dbo.uspEditarRBweb
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @p1 int, @p2 int, @p3 int, @p4 int, @p5 int
    DECLARE @ResumenId numeric(38),
            @CodigoSunat varchar(80),
            @MensajeSunat varchar(max),
            @HASHCDR varchar(max),
            @CDRBase64 varchar(max)

    SET @Data = LTRIM(RTRIM(@Data))
    SET @p1 = CHARINDEX('|', @Data, 0)
    SET @p2 = CHARINDEX('|', @Data, @p1 + 1)
    SET @p3 = CHARINDEX('|', @Data, @p2 + 1)
    SET @p4 = CHARINDEX('|', @Data, @p3 + 1)
    SET @p5 = LEN(@Data) + 1

    IF (@p4 = 0) SET @p4 = @p5

    SET @ResumenId = CONVERT(numeric(38), SUBSTRING(@Data, 1, @p1 - 1))
    SET @CodigoSunat = SUBSTRING(@Data, @p1 + 1, @p2 - @p1 - 1)
    SET @MensajeSunat = SUBSTRING(@Data, @p2 + 1, @p3 - @p2 - 1)
    SET @HASHCDR = SUBSTRING(@Data, @p3 + 1, @p4 - @p3 - 1)
    SET @CDRBase64 = CASE WHEN @p4 < @p5 THEN SUBSTRING(@Data, @p4 + 1, @p5 - @p4 - 1) ELSE '' END

    UPDATE dbo.ResumenBoletas
       SET CodigoSunat = @CodigoSunat,
           MensajeSunat = @MensajeSunat,
           HASHCDR = @HASHCDR,
           CDRBase64 = CASE WHEN ISNULL(@CDRBase64, '') = '' THEN CDRBase64 ELSE @CDRBase64 END
     WHERE ResumenId = @ResumenId

    SELECT 'true'
END
GO

/* uspGuardarCredencialesSunatweb */

CREATE OR ALTER PROCEDURE dbo.uspGuardarCredencialesSunatweb
    @CompaniaId int,
    @UsuarioSOL varchar(100),
    @ClaveSOL varchar(100),
    @CertificadoBase64 varchar(max),
    @ClaveCertificado varchar(100),
    @Entorno int
AS
BEGIN
    SET NOCOUNT ON

    IF NOT EXISTS (SELECT 1 FROM dbo.Compania WHERE CompaniaId = @CompaniaId)
    BEGIN
        RAISERROR('CompaniaId no existe.', 16, 1)
        RETURN
    END

    UPDATE dbo.Compania
       SET CompaniaUserSecun = @UsuarioSOL,
           ComapaniaPWD = @ClaveSOL,
           CompaniaPFX = @CertificadoBase64,
           CompaniaClave = @ClaveCertificado,
           TIPO_PROCESO = ISNULL(@Entorno, 3)
     WHERE CompaniaId = @CompaniaId
END
GO

/* uspInsertarConteoCajaWEB */
/* Adaptador WEB: no crea tablas ni modifica procedimientos del escritorio. */
CREATE OR ALTER PROCEDURE dbo.uspInsertarConteoCajaWEB
    @ListaOrden varchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.uspInsertarConteoCaja @ListaOrden = @ListaOrden;
END;
GO

/* uspinsertarNotaBweb */

-- ============================================================
-- uspinsertarNotaBweb
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.uspinsertarNotaBweb     @ListaOrden varchar(max) AS BEGIN     SET NOCOUNT ON;      DECLARE         @pos1 int,         @orden varchar(max),         @detalle varchar(max);      SET @pos1 = CHARINDEX('[', @ListaOrden, 1);      IF @pos1 <= 0     BEGIN         RAISERROR('Formato de orden invalido.', 16, 1);         RETURN;     END;      SET @orden = SUBSTRING(         @ListaOrden,         1,         @pos1 - 1     );      SET @detalle = SUBSTRING(         @ListaOrden,         @pos1 + 1,         LEN(@ListaOrden) - @pos1     );      DECLARE @campos TABLE     (         Pos int IDENTITY(1,1) NOT NULL,         Valor varchar(max) NULL     );      DECLARE         @start int,         @end int;      SET @start = 1;      WHILE @start <= LEN(@orden) + 1     BEGIN         SET @end = CHARINDEX('|', @orden, @start);          IF @end = 0             SET @end = LEN(@orden) + 1;          INSERT INTO @campos         (             Valor         )         VALUES         (             SUBSTRING(                 @orden,                 @start,                 @end - @start             )         );          SET @start = @end + 1;     END;      DECLARE         @NotaDocu varchar(60),         @ClienteId numeric(20),         @NotaUsuario varchar(60),         @NotaFormaPago varchar(60),         @NotaCondicion varchar(60),         @NotaDireccion varchar(max),         @CompaniaUbigeo varchar(250),          @NotaSubtotal decimal(18,2),         @NotaMovilidad decimal(18,2),         @NotaDescuento decimal(18,2),         @NotaTotal decimal(18,2),         @NotaAcuenta decimal(18,2),         @NotaSaldo decimal(18,2),         @NotaAdicional decimal(18,2),         @NotaTarjeta decimal(18,2),         @NotaPagar decimal(18,2),          @NotaEstado varchar(60),         @CompaniaId int,         @NotaEntrega varchar(40),         @NotaConcepto varchar(60),          @Serie varchar(60),         @Numero varchar(60),         @NotaGanancia decimal(18,2),          @Letra varchar(max),         @DocuAdicional decimal(18,2),         @DocuHash varchar(250),         @EstadoSunat varchar(80),         @DocuSubtotal decimal(18,2),         @DocuIGV decimal(18,2),          @UsuarioId int,         @NotaTransaccion varchar(250),         @Miembro varchar(300),         @CodigoCliente varchar(80),          @ICBPER decimal(18,2),         @DocuGravada decimal(18,2),          @ConceptoOBS varchar(80),         @EstadoOBS varchar(20),         @PV varchar(40),         @Image varchar(max),          @CodigoRes varchar(80),         @Responsable varchar(300),          @EntidadBancaria varchar(80),         @Efectivo decimal(18,2),         @Deposito decimal(18,2),         @NroOperacion varchar(80),          @ClienteRazon varchar(140),         @ClienteRuc varchar(40),         @ClienteDni varchar(40),         @DireccionFiscal varchar(max),          @TipoCodigo char(20),         @cod varchar(60),          @NotaId numeric(38),         @DocuId numeric(38);      SELECT @NotaDocu = Valor     FROM @campos     WHERE Pos = 1;      SELECT @ClienteId =         CONVERT(             numeric(20),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 2;      SELECT @NotaUsuario = Valor     FROM @campos     WHERE Pos = 3;      SELECT @NotaFormaPago = Valor     FROM @campos     WHERE Pos = 4;      SELECT @NotaCondicion = Valor     FROM @campos     WHERE Pos = 5;      SELECT @NotaDireccion = Valor     FROM @campos     WHERE Pos = 6;      SELECT @NotaSubtotal =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 7;      SELECT @NotaMovilidad =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 8;      SELECT @NotaDescuento =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 9;      SELECT @NotaTotal =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 10;      SELECT @NotaAcuenta =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 11;      SELECT @NotaSaldo =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 12;      SELECT @NotaAdicional =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 13;      SELECT @NotaTarjeta =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 14;      SELECT @NotaPagar =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 15;      SELECT @NotaEstado = Valor     FROM @campos     WHERE Pos = 16;      SELECT @CompaniaId =         CONVERT(             int,             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 17;      SELECT @NotaEntrega = Valor     FROM @campos     WHERE Pos = 18;      SELECT @NotaConcepto = Valor     FROM @campos     WHERE Pos = 19;      SELECT @Serie = Valor     FROM @campos     WHERE Pos = 20;      SELECT @Numero = Valor     FROM @campos     WHERE Pos = 21;      SELECT @NotaGanancia =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 22;      SELECT @Letra = Valor     FROM @campos     WHERE Pos = 23;      SELECT @DocuAdicional =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 24;      SELECT @DocuHash = Valor     FROM @campos     WHERE Pos = 25;      SELECT @EstadoSunat = Valor     FROM @campos     WHERE Pos = 26;      SELECT @DocuSubtotal =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 27;      SELECT @DocuIGV =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 28;      SELECT @UsuarioId =         CONVERT(             int,             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 29;      SELECT @NotaTransaccion = Valor     FROM @campos     WHERE Pos = 30;      SELECT @Miembro = Valor     FROM @campos     WHERE Pos = 31;      SELECT @CodigoCliente = Valor     FROM @campos     WHERE Pos = 32;      SELECT @ICBPER =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 33;      SELECT @DocuGravada =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 34;      SELECT @ConceptoOBS = Valor     FROM @campos     WHERE Pos = 35;      SELECT @EstadoOBS = Valor     FROM @campos     WHERE Pos = 36;      SELECT @PV = Valor     FROM @campos     WHERE Pos = 37;      SELECT @Image = Valor     FROM @campos     WHERE Pos = 38;      SELECT @CodigoRes = Valor     FROM @campos     WHERE Pos = 39;      SELECT @Responsable = Valor     FROM @campos     WHERE Pos = 40;      SELECT @EntidadBancaria = Valor     FROM @campos     WHERE Pos = 41;      SELECT @Efectivo =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 42;      SELECT @Deposito =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 43;      SELECT @NroOperacion = Valor     FROM @campos     WHERE Pos = 44;      SET @NotaDocu =         ISNULL(             NULLIF(LTRIM(RTRIM(@NotaDocu)), ''),             'BOLETA'         );      SET @NotaUsuario =         ISNULL(@NotaUsuario, '');      SET @NotaFormaPago =         ISNULL(             NULLIF(@NotaFormaPago, ''),             'EFECTIVO'         );      SET @NotaCondicion =         ISNULL(             NULLIF(@NotaCondicion, ''),             'ALCONTADO'         );      SET @NotaDireccion =         ISNULL(             NULLIF(@NotaDireccion, ''),             '-'         );      SET @NotaEstado =         ISNULL(             NULLIF(@NotaEstado, ''),             'PENDIENTE'         );      SET @CompaniaId =         ISNULL(             NULLIF(@CompaniaId, 0),             1         );      SET @NotaEntrega =         ISNULL(             NULLIF(@NotaEntrega, ''),             'INMEDIATA'         );      SET @NotaConcepto =         ISNULL(             NULLIF(@NotaConcepto, ''),             'MERCADERIA'         );      SET @Serie =         ISNULL(             NULLIF(@Serie, ''),             CASE                 WHEN @NotaDocu = 'FACTURA'                     THEN 'FA01'                 ELSE 'BA01'             END         );      SET @Letra = ISNULL(@Letra, '');     SET @DocuHash = ISNULL(@DocuHash, '');      SET @EstadoSunat =         ISNULL(             NULLIF(@EstadoSunat, ''),             'PENDIENTE'         );      SET @NotaTransaccion = ISNULL(@NotaTransaccion, '');     SET @Miembro = ISNULL(@Miembro, '');     SET @CodigoCliente = ISNULL(@CodigoCliente, '');      SET @ConceptoOBS =         ISNULL(             NULLIF(@ConceptoOBS, ''),             'VENTA'         );      SET @EstadoOBS =         ISNULL(             NULLIF(@EstadoOBS, ''),             'EMITIDO'         );      SET @CodigoRes = ISNULL(@CodigoRes, '');     SET @Responsable = ISNULL(@Responsable, '');      SET @EntidadBancaria =         ISNULL(             NULLIF(@EntidadBancaria, ''),             '-'         );      SET @NroOperacion =         ISNULL(@NroOperacion, '');      IF @NotaDocu = 'FACTURA'         SET @TipoCodigo = '01';     ELSE IF @NotaDocu = 'PROFORMA V'         SET @TipoCodigo = '00';     ELSE         SET @TipoCodigo = '03';      SELECT TOP 1         @ClienteRazon =             NULLIF(                 LTRIM(RTRIM(ClienteRazon)),                 ''             ),          @ClienteRuc =             NULLIF(                 LTRIM(RTRIM(ClienteRuc)),                 ''             ),          @ClienteDni =             NULLIF(                 LTRIM(RTRIM(ClienteDni)),                 ''             ),          @DireccionFiscal =             NULLIF(                 LTRIM(RTRIM(ClienteDireccion)),                 ''             )     FROM Cliente     WHERE ClienteId = @ClienteId;      SET @ClienteRazon =         ISNULL(             @ClienteRazon,             CASE                 WHEN @Miembro <> ''                     THEN @Miembro                 ELSE 'VARIOS'             END         );      SET @ClienteRuc = ISNULL(@ClienteRuc, '');     SET @ClienteDni = ISNULL(@ClienteDni, '');      IF @NotaDocu = 'BOLETA'        AND @ClienteRuc = ''        AND @ClienteDni = ''     BEGIN         SET @ClienteDni = '00000000';     END;      SET @DireccionFiscal =         ISNULL(             @DireccionFiscal,             @NotaDireccion         );      IF NULLIF(@DireccionFiscal, '') IS NULL         SET @DireccionFiscal = '-';      IF @NotaFormaPago <> 'EFECTIVO'     BEGIN         IF @Efectivo IS NULL             SET @Efectivo = 0;          IF @Deposito IS NULL            OR @Deposito = 0             SET @Deposito = @NotaPagar;     END;     ELSE     BEGIN         IF @Efectivo IS NULL            OR @Efectivo = 0             SET @Efectivo = @NotaPagar;          IF @Deposito IS NULL             SET @Deposito = 0;     END;      IF @NotaCondicion = 'CREDITO'     BEGIN         SET @NotaEstado = 'EMITIDO';         SET @NotaSaldo = @NotaPagar;         SET @NotaAcuenta = 0;     END;     ELSE IF @NotaDocu <> 'FACTURA'         AND @NotaDocu <> 'PROFORMA V'     BEGIN         SET @NotaEstado = 'CANCELADO';         SET @NotaSaldo = 0;         SET @NotaAcuenta = @NotaPagar;     END;      IF @NotaTransaccion <> ''        AND EXISTS        (             SELECT 1             FROM NotaPedido             WHERE NotaTransaccion = @NotaTransaccion               AND ISNULL(NotaEstado, '') <> 'ANULADO'        )     BEGIN         SELECT 'EXISTE';         RETURN;     END;      IF @Deposito > 0        AND @NotaCondicion <> 'PAGO/VARIOS'        AND NULLIF(LTRIM(RTRIM(@NroOperacion)), '') IS NULL     BEGIN         SELECT 'OPERACION_REQUERIDA';         RETURN;     END;      IF @NroOperacion <> ''        AND ISNULL(@EntidadBancaria, '-') <> '-'        AND EXISTS        (             SELECT 1             FROM NotaPedido             WHERE EntidadBancaria = @EntidadBancaria               AND NroOperacion = @NroOperacion               AND ISNULL(NotaEstado, '') <> 'ANULADO'        )     BEGIN         SELECT 'OPERACION';         RETURN;     END;      DECLARE @CajaId numeric(38);      SELECT TOP (1)         @CajaId = CajaId     FROM Caja     WHERE CajaEstado = 'ACTIVO'       AND UsuarioId = @UsuarioId     ORDER BY CajaId DESC;      IF ISNULL(@CajaId, 0) = 0     BEGIN         SELECT 'false';         RETURN;     END;      SELECT @CompaniaUbigeo = NULLIF(LTRIM(RTRIM(CompaniaNomUBG)), '')     FROM Compania     WHERE CompaniaId = @CompaniaId;      SET @CompaniaUbigeo = ISNULL(@CompaniaUbigeo, '');      BEGIN TRY          BEGIN TRANSACTION;          UPDATE Cliente         SET ClienteDespacho = @NotaDireccion         WHERE ClienteId = @ClienteId;          SET @NotaDireccion = @CompaniaUbigeo;          DELETE FROM TemporalVenta         WHERE UsuarioID = @UsuarioId;          SELECT @cod =             ISNULL(                 (                     SELECT TOP 1                         dbo.genenerarNroFactura(                             @Serie,                             @CompaniaId,                             @NotaDocu                         )                     FROM DocumentoVenta                 ),                 '00000001'             );          INSERT INTO NotaPedido         (             NotaDocu,             ClienteId,             NotaFecha,             NotaUsuario,             NotaFormaPago,             NotaCondicion,             NotaFechaPago,             NotaDireccion,             NotaSubtotal,             NotaMovilidad,             NotaDescuento,             NotaTotal,             NotaAcuenta,             NotaSaldo,             NotaAdicional,             NotaTarjeta,             NotaPagar,             NotaEstado,             CompaniaId,             NotaEntrega,             ModificadoPor,             FechaEdita,             NotaConcepto,             NotaSerie,             NotaNumero,             NotaGanancia,             CajaId,             NotaTransaccion,             ICBPER,             ConceptoOBS,             EstadoOBS,             CodigoRes,             Responsable,             EntidadBancaria,             NroOperacion,             Efectivo,             Deposito         )         VALUES         (             @NotaDocu,             @ClienteId,             GETDATE(),             @NotaUsuario,             @NotaFormaPago,             @NotaCondicion,             GETDATE(),             @NotaDireccion,             @NotaSubtotal,             @NotaMovilidad,             @NotaDescuento,             @NotaTotal,             @NotaAcuenta,             @NotaSaldo,             @NotaAdicional,             @NotaTarjeta,             @NotaPagar,             @NotaEstado,             @CompaniaId,             @NotaEntrega,             '',             '',             @NotaConcepto,             @Serie,             @cod,             @NotaGanancia,             @CajaId,             @NotaTransaccion,             @ICBPER,             @ConceptoOBS,             @EstadoOBS,             @CodigoRes,             @Responsable,             @EntidadBancaria,             @NroOperacion,             @Efectivo,             @Deposito         );          SET @NotaId = SCOPE_IDENTITY();          INSERT INTO DocumentoVenta         (             CompaniaId,             NotaId,             DocuDocumento,             DocuNumero,             ClienteId,             DocuRegistro,             DocuEmision,             DocuCondicion,             DocuLetras,             DocuSubTotal,             DocuIgv,             DocuTotal,             DocuSaldo,             DocuUsuario,             DocuEstado,             DocuSerie,             TipoCodigo,             DocuAdicional,             DocuAsociado,             DocuConcepto,             DocuNroGuia,             DocuHash,             EstadoSunat,             DocuOperacion,             DocuTransaccion,             ICBPER,             CodigoSunat,             MensajeSunat,             FormaPago,             EntidadBancaria,             NroOperacion,             Efectivo,             Deposito         )         VALUES         (             @CompaniaId,             @NotaId,             @NotaDocu,             @cod,             @ClienteId,             GETDATE(),             GETDATE(),             @NotaCondicion,             @Letra,             @DocuSubtotal,             @DocuIGV,             @NotaPagar,             0,             @NotaUsuario,             'EMITIDO',             @Serie,             @TipoCodigo,             @DocuAdicional,             '',             'VENTA',             '',             @DocuHash,              CASE                 WHEN @NotaDocu = 'PROFORMA V'                     THEN 'ENVIADO'                 ELSE @EstadoSunat             END,              @NotaConcepto,             @NotaTransaccion,             @ICBPER,             '',             '',             @NotaFormaPago,             @EntidadBancaria,             @NroOperacion,             @Efectivo,             @Deposito         );          SET @DocuId = SCOPE_IDENTITY();          INSERT INTO dbo.DocumentoVentaCpeWeb         (             DocuId,             ClienteRazon,             ClienteRuc,             ClienteDni,             DireccionFiscal,             DocuPdfUrl,             DocuXmlUrl,             DocuCdrUrl,             DocuFechaPago         )         VALUES         (             @DocuId,             @ClienteRazon,             @ClienteRuc,             @ClienteDni,             @DireccionFiscal,             '',             '',             '',             GETDATE()         );          IF @NotaCondicion = 'ALCONTADO'            AND @NotaDocu <> 'PROFORMA V'         BEGIN             IF UPPER(LTRIM(RTRIM(@ConceptoOBS))) = 'VENTA LIBRE'             BEGIN                 INSERT INTO dbo.CajaDetalle                 (                     CajaId, DetalleFecha, NotaId, DetalleMovimiento,                     DetalleConcepto, DetalleMonto, DetalleEfectivo,                     DetalleVuelto, RutaImagen, Estado, Vista,                     NotaIdB, LiquidaId, FormaPago, EntidadBancaria, NroOperacion                 )                 VALUES                 (                     @CajaId, GETDATE(), 0, 'INGRESO',                     'VENTA LIBRE DOCUMENTO ' + @Serie + '-' + @cod +                     ' CODIGO: ' + @CodigoCliente + ' (' + @Miembro + ')' +                     ' FORMA DE PAGO: ' + @NotaFormaPago,                     @NotaTotal, @NotaTotal, 0, @Image, 'D', '',                     @NotaId, '', @NotaFormaPago, @EntidadBancaria, @NroOperacion                 );             END;              IF @Deposito > 0                AND UPPER(LTRIM(RTRIM(@ConceptoOBS))) IN ('VENTA', 'IOC', 'CASHBILL', 'VENTA LIBRE')             BEGIN                 INSERT INTO dbo.CajaDetalle                 (                     CajaId, DetalleFecha, NotaId, DetalleMovimiento,                     DetalleConcepto, DetalleMonto, DetalleEfectivo,                     DetalleVuelto, RutaImagen, Estado, Vista,                     NotaIdB, LiquidaId, FormaPago, EntidadBancaria, NroOperacion                 )                 VALUES                 (                     @CajaId, GETDATE(), 0, 'SALIDA',                     'VENTA DEL OBS DOCUMENTO ' + @Serie + '-' + @cod +                     ' CODIGO: ' + @CodigoCliente + ' (' + @Miembro + ')' +                     ' FORMA DE PAGO: ' + @NotaFormaPago +        ' ENTIDAD BANCARIA: ' + @EntidadBancaria +                     ' NRO OPERACION: ' + @NroOperacion,                     @Deposito, @Deposito, 0, @Image, 'D', '',                     @NotaId, '', @NotaFormaPago, @EntidadBancaria, @NroOperacion                 );             END;         END;          DECLARE detalle_cursor CURSOR LOCAL FAST_FORWARD         FOR             SELECT splitdata             FROM dbo.fnSplitString(@detalle, ';')             WHERE LEN(LTRIM(RTRIM(splitdata))) > 0;          DECLARE @Columna varchar(max);          DECLARE @detalleCampos TABLE         (             Pos int NOT NULL PRIMARY KEY,             Valor varchar(max) NULL         );          DECLARE @campoPos int;          OPEN detalle_cursor;          FETCH NEXT FROM detalle_cursor         INTO @Columna;          WHILE @@FETCH_STATUS = 0         BEGIN              DELETE FROM @detalleCampos;              SET @campoPos = 1;             SET @start = 1;              WHILE @start <= LEN(@Columna) + 1             BEGIN                  SET @end =                     CHARINDEX(                         '|',                         @Columna,                         @start                     );                  IF @end = 0                     SET @end = LEN(@Columna) + 1;                  INSERT INTO @detalleCampos                 (                     Pos,                     Valor                 )                 VALUES                 (                     @campoPos,                     SUBSTRING(                         @Columna,                         @start,                         @end - @start                     )                 );                  SET @campoPos = @campoPos + 1;                 SET @start = @end + 1;             END;              DECLARE                 @IdProducto numeric(20),                 @DetalleCantidad decimal(18,2),                 @DetalleUm varchar(40),                 @Descripcion varchar(max),                 @DetalleCosto decimal(18,4),                 @DetallePrecio decimal(18,2),                 @DetallePV decimal(18,2),                 @DetalleSV decimal(18,2),                 @DetalleImporte decimal(18,2),                 @DetalleEstado varchar(60),                 @ValorUM decimal(18,4),                 @CantidadSaldo decimal(18,2),                 @IniciaStock decimal(18,2),                 @StockFinal decimal(18,2);              SELECT @IdProducto =                 CONVERT(                     numeric(20),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 1;              SELECT @DetalleCantidad =                 CONVERT(                     decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 2;              SELECT @DetalleUm = Valor             FROM @detalleCampos             WHERE Pos = 3;              SELECT @Descripcion = Valor             FROM @detalleCampos             WHERE Pos = 4;              SELECT @DetalleCosto =                 CONVERT(                     decimal(18,4),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 5;              SELECT @DetallePrecio =                 CONVERT(                     decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 6;              SELECT @DetallePV =                 CONVERT(                     decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 7;              SELECT @DetalleSV =                 CONVERT(                     decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 8;              SELECT @DetalleImporte =                 CONVERT(    decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 9;              SELECT @DetalleEstado = Valor             FROM @detalleCampos             WHERE Pos = 10;              SELECT @ValorUM =                 CONVERT(                     decimal(18,4),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 11;              SET @DetalleUm =                 ISNULL(                     NULLIF(@DetalleUm, ''),                     'UNIDAD'                 );              SET @Descripcion =                 ISNULL(@Descripcion, '');              SET @DetalleEstado =                 ISNULL(                     NULLIF(@DetalleEstado, ''),                     'PENDIENTE'                 );              IF @ValorUM IS NULL                OR @ValorUM = 0             BEGIN                 SET @ValorUM = 1;             END;              IF @NotaEntrega = 'INMEDIATA'                 SET @CantidadSaldo = 0;             ELSE                 SET @CantidadSaldo = @DetalleCantidad;              INSERT INTO DetallePedido             (                 NotaId,                 IdProducto,                 DetalleCantidad,                 DetalleUm,                 DetalleDescripcion,                 DetalleCosto,                 DetallePrecio,                 DetalleImporte,                 DetalleEstado,                 CantidadSaldo,                 ValorUM,                 DetallePV,                 DetalleSV             )             VALUES             (                 @NotaId,                 @IdProducto,                 @DetalleCantidad,                 @DetalleUm,                 @Descripcion,                 @DetalleCosto,                 @DetallePrecio,                 @DetalleImporte,                 @DetalleEstado,                 @CantidadSaldo,                 @ValorUM,                 @DetallePV,                 @DetalleSV             );              IF @DocuId <> 0             BEGIN                  INSERT INTO DetalleDocumento                 (                     DocuId,                     IdProducto,                     DetalleCantidad,                     DetallPrecio,                     DetalleImporte,                     DetalleNotaId,                     DetalleUM,                     ValorUM                 )                 VALUES                 (                     @DocuId,                     @IdProducto,                     @DetalleCantidad,                     @DetallePrecio,                     @DetalleImporte,                     @NotaId,                     @DetalleUm,                     @ValorUM                 );              END;              IF @NotaDocu <> 'FACTURA'             BEGIN                  SELECT TOP 1                     @IniciaStock = ProductoCantidad                 FROM Producto                 WHERE IdProducto = @IdProducto;                  SET @IniciaStock =                     ISNULL(@IniciaStock, 0);                  SET @StockFinal =                     @IniciaStock - @DetalleCantidad;                  INSERT INTO Kardex                 (                     IdProducto,                     KardexFecha,                     KardexMotivo,                     KardexDocumento,                     StockInicial,                     CantidadIngreso,                     CantidadSalida,                     PrecioCosto,                     StockFinal,                     KadexConcepto,                     Usuario,                     CLIENTE,                     CODIGOCLIENTE,                     NROTRANSAC,                     TipoCodigo,                     Serie,                     TipoOperacion,                     Consideracion,                     DocuId,                     CompraId,                     Estado                 )                 VALUES                 (                     @IdProducto,                     GETDATE(),               'Salida por Venta',                     @cod,                     @IniciaStock,                     0,                     @DetalleCantidad,                     @DetalleCosto,                     @StockFinal,                     'SALIDA',                     @NotaUsuario,                     @Miembro,                     @CodigoCliente,                     @NotaTransaccion,                     @TipoCodigo,                     @Serie,                     '01',                      CASE                         WHEN @NotaEntrega = 'INMEDIATA'                             THEN 'S'                         ELSE 'N'                     END,                      CONVERT(varchar(40), @DocuId),                     '',                     'E'                 );                  IF @NotaEntrega = 'INMEDIATA'                 BEGIN                      UPDATE Producto                     SET ProductoCantidad =                         ProductoCantidad - @DetalleCantidad                     WHERE IdProducto = @IdProducto;                  END;              END;              FETCH NEXT FROM detalle_cursor             INTO @Columna;          END;          CLOSE detalle_cursor;         DEALLOCATE detalle_cursor;          COMMIT TRANSACTION;          SELECT             CONVERT(varchar(38), @NotaId)             + N'¬'             + @cod;      END TRY      BEGIN CATCH          IF CURSOR_STATUS('local', 'detalle_cursor') > -1         BEGIN             CLOSE detalle_cursor;             DEALLOCATE detalle_cursor;         END;          IF @@TRANCOUNT > 0             ROLLBACK TRANSACTION;          DECLARE             @ErrMsg nvarchar(4000),             @ErrSeverity int,             @ErrState int;          SELECT             @ErrMsg = ERROR_MESSAGE(),             @ErrSeverity = ERROR_SEVERITY(),             @ErrState = ERROR_STATE();          RAISERROR(             @ErrMsg,             @ErrSeverity,             @ErrState         );      END CATCH;  END;
GO

/* uspinsertarRBweb */

CREATE OR ALTER PROCEDURE dbo.uspinsertarRBweb
    @ListaOrden varchar(max)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @pos int
    DECLARE @orden varchar(max)
    DECLARE @detalle varchar(max)

    SET @pos = CHARINDEX('[', @ListaOrden, 0)
    SET @orden = SUBSTRING(@ListaOrden, 1, @pos - 1)
    SET @detalle = SUBSTRING(@ListaOrden, @pos + 1, LEN(@ListaOrden) - @pos)

    DECLARE @c1 int, @c2 int, @c3 int, @c4 int,
            @c5 int, @c6 int, @c7 int, @c8 int,
            @c9 int, @c10 int, @c11 int, @c12 int,
            @c13 int, @c14 int

    DECLARE @CompaniaId int, @ResumenSerie varchar(250),
            @Secuencia numeric(38), @FechaReferencia date,
            @SubTotal decimal(18,2), @IGV decimal(18,2),
            @Total decimal(18,2), @ResumenTiket varchar(250),
            @CodigoSunat varchar(80), @HASHCDR varchar(max),
            @Usuario varchar(80), @Status int, @Estado char(1),
            @RangoNumero varchar(80), @ICBPER decimal(18,2)

    SET @c1 = CHARINDEX('|', @orden, 0)
    SET @c2 = CHARINDEX('|', @orden, @c1 + 1)
    SET @c3 = CHARINDEX('|', @orden, @c2 + 1)
    SET @c4 = CHARINDEX('|', @orden, @c3 + 1)
    SET @c5 = CHARINDEX('|', @orden, @c4 + 1)
    SET @c6 = CHARINDEX('|', @orden, @c5 + 1)
    SET @c7 = CHARINDEX('|', @orden, @c6 + 1)
    SET @c8 = CHARINDEX('|', @orden, @c7 + 1)
    SET @c9 = CHARINDEX('|', @orden, @c8 + 1)
    SET @c10 = CHARINDEX('|', @orden, @c9 + 1)
    SET @c11 = CHARINDEX('|', @orden, @c10 + 1)
    SET @c12 = CHARINDEX('|', @orden, @c11 + 1)
    SET @c13 = CHARINDEX('|', @orden, @c12 + 1)
    SET @c14 = LEN(@orden) + 1

    SET @CompaniaId = CONVERT(int, SUBSTRING(@orden, 1, @c1 - 1))
    SET @ResumenSerie = SUBSTRING(@orden, @c1 + 1, @c2 - @c1 - 1)
    SET @Secuencia = CONVERT(numeric(38), SUBSTRING(@orden, @c2 + 1, @c3 - @c2 - 1))
    SET @FechaReferencia = CONVERT(date, SUBSTRING(@orden, @c3 + 1, @c4 - @c3 - 1))
    SET @SubTotal = CONVERT(decimal(18,2), SUBSTRING(@orden, @c4 + 1, @c5 - @c4 - 1))
    SET @IGV = CONVERT(decimal(18,2), SUBSTRING(@orden, @c5 + 1, @c6 - @c5 - 1))
    SET @Total = CONVERT(decimal(18,2), SUBSTRING(@orden, @c6 + 1, @c7 - @c6 - 1))
    SET @ResumenTiket = SUBSTRING(@orden, @c7 + 1, @c8 - @c7 - 1)
    SET @CodigoSunat = SUBSTRING(@orden, @c8 + 1, @c9 - @c8 - 1)
    SET @HASHCDR = SUBSTRING(@orden, @c9 + 1, @c10 - @c9 - 1)
    SET @Usuario = SUBSTRING(@orden, @c10 + 1, @c11 - @c10 - 1)
    SET @Status = CONVERT(int, SUBSTRING(@orden, @c11 + 1, @c12 - @c11 - 1))
    SET @RangoNumero = SUBSTRING(@orden, @c12 + 1, @c13 - @c12 - 1)
    SET @ICBPER = CONVERT(decimal(18,2), SUBSTRING(@orden, @c13 + 1, @c14 - @c13 - 1))

    IF (@Status = 3)
    BEGIN
        SET @SubTotal = 0 - @SubTotal
        SET @IGV = 0 - @IGV
        SET @ICBPER = 0 - @ICBPER
        SET @Total = 0 - @Total
        SET @Estado = 'B'
    END
    ELSE
    BEGIN
        SET @Estado = 'E'
    END

    BEGIN TRANSACTION

    INSERT INTO dbo.ResumenBoletas
    (
        CompaniaId, ResumenSerie, Secuencia, FechaReferencia, FechaEnvio,
        SubTotal, IGV, Total, ResumenTiket, CodigoSunat, HASHCDR, MensajeSunat,
        Usuario, ESTADO, RangoNumero, ICBPER, CDRBase64
    )
    VALUES
    (
        @CompaniaId, @ResumenSerie, @Secuencia, @FechaReferencia, GETDATE(),
        @SubTotal, @IGV, @Total, @ResumenTiket, @CodigoSunat, @HASHCDR, '',
        @Usuario, @Estado, @RangoNumero, @ICBPER, ''
    )

    DECLARE Tabla CURSOR FOR SELECT * FROM dbo.fnSplitString(@detalle, ';')
    OPEN Tabla

    DECLARE @Columna varchar(max), @DocuId numeric(38)
    DECLARE @p1 int

    FETCH NEXT FROM Tabla INTO @Columna
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @p1 = LEN(@Columna) + 1
        SET @DocuId = CONVERT(numeric(38), SUBSTRING(@Columna, 1, @p1 - 1))

        IF (@Status = 1)
        BEGIN
            UPDATE dbo.DocumentoVenta
               SET DocuHash = @HASHCDR,
                   EstadoSunat = 'ENVIADO',
                   CodigoSunat = NULL,
                   MensajeSunat = NULL
             WHERE DocuId = @DocuId
        END
        ELSE
        BEGIN
            UPDATE dbo.DocumentoVenta
               SET DocuHash = @HASHCDR,
                   DocuEstado = 'BAJA',
                   EstadoSunat = 'ENVIADO',
                   DocuSubTotal = 0,
                   DocuIgv = 0,
                   DocuTotal = 0,
                   ICBPER = 0,
                   CodigoSunat = NULL,
                   MensajeSunat = NULL
             WHERE DocuId = @DocuId
        END

        FETCH NEXT FROM Tabla INTO @Columna
    END

    CLOSE Tabla
    DEALLOCATE Tabla

    COMMIT TRANSACTION

    SELECT ISNULL((
        SELECT STUFF((
            SELECT '¬' + CONVERT(varchar, r.ResumenId) + '|' + CONVERT(varchar, r.CompaniaId) + '|' +
                   ISNULL(CONVERT(varchar, r.FechaReferencia, 103), '') + '|' +
                   ISNULL(CONVERT(varchar, r.FechaEnvio, 103), '') + ' ' + ISNULL(SUBSTRING(CONVERT(varchar, r.FechaEnvio, 114), 1, 8), '') + '|' +
                   r.ResumenSerie + '-' + CONVERT(varchar, r.Secuencia) + '|' + ISNULL(r.RangoNumero, '') + '|' +
                   CONVERT(varchar(50), CAST(r.SubTotal AS money), 1) + '|' +
                   CONVERT(varchar(50), CAST(r.IGV AS money), 1) + '|' +
                   CONVERT(varchar(50), CAST(r.ICBPER AS money), 1) + '|' +
                   CONVERT(varchar(50), CAST(r.Total AS money), 1) + '|' +
                   ISNULL(r.ResumenTiket, '') + '|' + ISNULL(r.CodigoSunat, '') + '|' +
                   ISNULL(r.HASHCDR, '') + '|' + ISNULL(r.MensajeSunat, '') + '|' +
                   ISNULL(r.Usuario, '') + '|' + ISNULL(c.CompaniaRUC, '') + '|' +
                   ISNULL(c.CompaniaUserSecun, '') + '|' + ISNULL(c.ComapaniaPWD, '') + '|' +
                   ISNULL(r.Estado, '') + '||' + ISNULL(c.TokenApi, '') + '|' + ISNULL(c.ClienIdToken, '')
            FROM dbo.ResumenBoletas r
            INNER JOIN dbo.Compania c ON c.CompaniaId = r.CompaniaId
            WHERE MONTH(r.FechaReferencia) = MONTH(GETDATE())
              AND YEAR(r.FechaReferencia) = YEAR(GETDATE())
            ORDER BY r.CompaniaId, r.FechaEnvio ASC
            FOR XML PATH('')
        ), 1, 1, '')
    ), '~')
END
GO

/* uspListarCajaWEB */

CREATE OR ALTER PROCEDURE dbo.uspListarCajaWEB
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CONVERT(BIGINT, CajaId) AS CajaId,
        CONVERT(VARCHAR(19), CajaFecha, 126) AS FechaApertura,
        ISNULL(CajaCierre, '') AS FechaCierre,
        ISNULL(MontoIniSOl, 0) AS MontoInicial,
        ISNULL(CajaEncargado, '') AS Encargado,
        ISNULL(CajaUsuario, '') AS Usuario,
        ISNULL(CajaEstado, '') AS Estado,
        ISNULL(Observacion, '') AS Observacion
    FROM dbo.Caja
    ORDER BY CajaId DESC;
END;
GO

/* uspListarComprasweb */

-- ============================================================
-- uspListarComprasweb
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.uspListarComprasweb
    @Estado VARCHAR(60) = NULL,
    @Page INT = 1,
    @PageSize INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    SET @Page =
        CASE
            WHEN @Page < 1 THEN 1
            ELSE @Page
        END;

    SET @PageSize =
        CASE
            WHEN @PageSize < 1 THEN 50
            WHEN @PageSize > 500 THEN 500
            ELSE @PageSize
        END;

    SELECT
        CompraId,
        CompraCorrelativo,
        ProveedorId,
        CompraRegistro,
        CompraEmision,
        CompraComputo,
        TipoCodigo,
        CompraSerie,
        CompraNumero,
        CompraCondicion,
        CompraMoneda,
        CompraTipoCambio,
        CompraDias,
        CompraFechaPago,
        CompraUsuario,
        CompraTipoIgv,
        CompraValorVenta,
        CompraDescuento,
        CompraSubtotal,
        CompraIgv,
        CompraTotal,
        CompraEstado,
        CompraAsociado,
        CompraSaldo,
        CompraOBS,
        CompraTipoSunat,
        CompraConcepto,
        CAST(NULL AS DECIMAL(18, 2)) AS CompraPercepcion
    FROM Compras
    WHERE @Estado IS NULL
       OR CompraEstado = @Estado
    ORDER BY CompraId DESC
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO

/* uspObtenerCajaActivaWEB */

-- ============================================================
-- uspObtenerCajaActivaWEB
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.uspObtenerCajaActivaWEB
    @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CajaId NUMERIC(38);

    SELECT TOP (1)
        @CajaId = CajaId
    FROM dbo.Caja
    WHERE UsuarioId = @UsuarioId
      AND CajaEstado = 'ACTIVO'
    ORDER BY CajaId DESC;

    IF ISNULL(@CajaId, 0) = 0
        RETURN;

    DECLARE
        @MontoInicial DECIMAL(18, 2),
        @Ingresos DECIMAL(18, 2),
        @Tarjeta DECIMAL(18, 2),
        @Depositos DECIMAL(18, 2),
        @Salidas DECIMAL(18, 2);

    SELECT
        @MontoInicial = ISNULL(MontoIniSOl, 0)
    FROM dbo.Caja
    WHERE CajaId = @CajaId;

    SELECT
        @Ingresos = ISNULL(SUM(ISNULL(Efectivo, 0)), 0),
        @Tarjeta = ISNULL(
            SUM(
                CASE
                    WHEN UPPER(ISNULL(NotaFormaPago, '')) LIKE '%TARJETA%'
                        THEN ISNULL(Deposito, 0)
                    ELSE 0
                END
            ),
            0
        ),
        @Depositos = ISNULL(
            SUM(
                CASE
                    WHEN UPPER(ISNULL(NotaFormaPago, '')) NOT LIKE '%TARJETA%'
                        THEN ISNULL(Deposito, 0)
                    ELSE 0
                END
            ),
            0
        )
    FROM dbo.NotaPedido
    WHERE CajaId = @CajaId
      AND ISNULL(NotaEstado, '') <> 'ANULADO';

    SELECT
        @Salidas = ISNULL(
            SUM(ISNULL(DetalleEfectivo, DetalleMonto)),
            0
        )
    FROM dbo.CajaDetalle
    WHERE CajaId = @CajaId
      AND DetalleMovimiento = 'SALIDA'
      AND ISNULL(NotaId, 0) = 0;

    SELECT
        CONVERT(BIGINT, c.CajaId) AS CajaId,
        CONVERT(VARCHAR(19), c.CajaFecha, 126) AS FechaApertura,
        ISNULL(c.MontoIniSOl, 0) AS MontoInicial,
        ISNULL(c.CajaEncargado, '') AS Encargado,
        ISNULL(c.CajaUsuario, '') AS Usuario,
        ISNULL(c.Observacion, '') AS Observacion,
        @Ingresos AS VentasEfectivo,
        @Tarjeta AS VentasTarjeta,
        @Depositos AS VentasDeposito,
        @Salidas AS Salidas,
        @MontoInicial + @Ingresos - @Salidas AS EfectivoEsperado
    FROM dbo.Caja c
    WHERE c.CajaId = @CajaId;

    SELECT
        Billete,
        ISNULL(Efectivo, 0) AS Cantidad
    FROM dbo.Monedas
    WHERE CajaId = @CajaId
    ORDER BY CONVERT(DECIMAL(18, 2), Billete) DESC;
END;
GO

/* uspObtenerCredencialesSunatweb */

CREATE OR ALTER PROCEDURE dbo.uspObtenerCredencialesSunatweb
    @CompaniaId int
AS
BEGIN
    SET NOCOUNT ON

    SELECT CompaniaUserSecun AS UsuarioSOL,
           ComapaniaPWD AS ClaveSOL,
           CompaniaPFX AS CertificadoPFX,
           CompaniaClave AS ClaveCertificado,
           ISNULL(TIPO_PROCESO, 3) AS Entorno
      FROM dbo.Compania
     WHERE CompaniaId = @CompaniaId
END
GO

/* uspResumenFechaweb */

CREATE OR ALTER PROCEDURE dbo.uspResumenFechaweb
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @p1 int, @p2 int
    DECLARE @fechainicio date, @fechafin date
    DECLARE @sep char(1)
    SET @sep = CHAR(172)

    SET @Data = LTRIM(RTRIM(@Data))
    SET @p1 = CHARINDEX('|', @Data, 0)
    SET @p2 = LEN(@Data) + 1

    SET @fechainicio = CONVERT(date, SUBSTRING(@Data, 1, @p1 - 1), 120)
    SET @fechafin = CONVERT(date, SUBSTRING(@Data, @p1 + 1, @p2 - @p1 - 1), 120)

    SELECT
        'Id|Compania|FechaEmision|FechaEnvio|Serie|RangoNumeros|SubTotal|IGV|ICBPER|Total|Ticket|CDSunat|HASHCDR|Mensaje|Usuario|RUC|UserSol|ClaveSol|ESTADO|Intentos|TokenApi|IdToken|TieneCDR|CDRBase64'
        + @sep +
        '100|100|100|100|100|100|110|110|110|100|100|100|100|100|100|100|100|100|100|100|100|100|80|300'
        + @sep +
        'String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String'
        + @sep +
        ISNULL((
            SELECT STUFF((
                SELECT @sep + CONVERT(varchar, r.ResumenId) + '|' + CONVERT(varchar, r.CompaniaId) + '|' +
                       ISNULL(CONVERT(varchar, r.FechaReferencia, 103), '') + '|' +
                       ISNULL(CONVERT(varchar, r.FechaEnvio, 103), '') + ' ' + ISNULL(SUBSTRING(CONVERT(varchar, r.FechaEnvio, 114), 1, 8), '') + '|' +
                       ISNULL(r.ResumenSerie, '') + '-' + CONVERT(varchar, r.Secuencia) + '|' +
                       ISNULL(r.RangoNumero, '') + '|' +
                       CONVERT(varchar(50), CAST(r.SubTotal AS money), 1) + '|' +
                       CONVERT(varchar(50), CAST(r.IGV AS money), 1) + '|' +
                       CONVERT(varchar(50), CAST(r.ICBPER AS money), 1) + '|' +
                       CONVERT(varchar(50), CAST(r.Total AS money), 1) + '|' +
                       ISNULL(r.ResumenTiket, '') + '|' +
                       REPLACE(ISNULL(r.CodigoSunat, ''), '|', ' ') + '|' +
                       REPLACE(ISNULL(r.HASHCDR, ''), '|', ' ') + '|' +
                       REPLACE(ISNULL(r.MensajeSunat, ''), '|', ' ') + '|' +
                       REPLACE(ISNULL(r.Usuario, ''), '|', ' ') + '|' +
                       ISNULL(c.CompaniaRUC, '') + '|' +
                       ISNULL(c.CompaniaUserSecun, '') + '|' +
                       ISNULL(c.ComapaniaPWD, '') + '|' +
                       ISNULL(r.Estado, '') + '||' +
                       ISNULL(c.TokenApi, '') + '|' +
                       ISNULL(c.ClienIdToken, '') + '|' +
                       CASE WHEN ISNULL(r.CDRBase64, '') = '' THEN 'NO' ELSE 'SI' END + '|' +
                       REPLACE(ISNULL(r.CDRBase64, ''), '|', ' ')
                FROM dbo.ResumenBoletas r
                INNER JOIN dbo.Compania c ON c.CompaniaId = r.CompaniaId
                WHERE r.FechaReferencia BETWEEN @fechainicio AND @fechafin
                ORDER BY r.CompaniaId, r.FechaEnvio ASC
                FOR XML PATH('')
            ), 1, 1, '')
        ), '~')
END
GO

/* uspValidaCantCajasWeb */

CREATE OR ALTER PROCEDURE dbo.uspValidaCantCajasWeb
    @CajaId numeric(38, 0),
    @UsuarioId int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompaniaId int, @FlagCaja bit = 0;

    SELECT @CompaniaId = p.CompaniaId
      FROM dbo.Usuarios u
      INNER JOIN dbo.Personal p ON p.PersonalId = u.PersonalId
     WHERE u.UsuarioID = @UsuarioId;

    SELECT @FlagCaja = ISNULL(c.FlagCaja, 0)
      FROM dbo.Compania c
     WHERE c.CompaniaId = @CompaniaId;

    IF ISNULL(@FlagCaja, 0) = 1
    BEGIN
        SELECT 'true';
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
          FROM dbo.Caja c WITH (UPDLOCK, HOLDLOCK)
          INNER JOIN dbo.Usuarios u ON u.UsuarioID = c.UsuarioId
          INNER JOIN dbo.Personal p ON p.PersonalId = u.PersonalId
         WHERE c.CajaEstado = 'ACTIVO'
           AND p.CompaniaId = @CompaniaId
           AND c.CajaId <> @CajaId
    )
    BEGIN
        SELECT 'SOLO_UNA_CAJA';
        RETURN;
    END;

    SELECT 'true';
END;
GO

/* uspValidaUsuarioweb */

-- ============================================================
-- uspValidaUsuarioweb
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.uspValidaUsuarioweb
    @Data VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @p1 INT,
        @p2 INT;

    DECLARE
        @Usuario VARCHAR(150),
        @Clave VARCHAR(150);

    SET @Data = LTRIM(RTRIM(@Data));

    SET @p1 = CHARINDEX('|', @Data, 0);
    SET @p2 = CHARINDEX('|', @Data, @p1 + 1);

    IF @p2 = 0
        SET @p2 = LEN(@Data) + 1;

    SET @Usuario = SUBSTRING(
        @Data,
        1,
        @p1 - 1
    );

    SET @Clave = SUBSTRING(
        @Data,
        @p1 + 1,
        @p2 - @p1 - 1
    );

    SELECT ISNULL(
        (
            SELECT STUFF(
            (
                SELECT TOP 1
                    '¬'
                    + CONVERT(VARCHAR, U.UsuarioID) + '|'
                    + CONVERT(VARCHAR, p.PersonalId) + '|'
                    + ISNULL(a.AreaNombre, '') + '|'
                    + (
                        SUBSTRING(
                            ISNULL(p.PersonalNombres, '') + ' ',
                            1,
                            CHARINDEX(
                                ' ',
                                ISNULL(p.PersonalNombres, '') + ' '
                            ) - 1
                        )
                        + ' '
                        + SUBSTRING(
                            ISNULL(p.PersonalApellidos, '') + ' ',
                            1,
                            CHARINDEX(
                                ' ',
                                ISNULL(p.PersonalApellidos, '') + ' '
                            ) - 1
                        )
                    ) + '|'
                    + CONVERT(VARCHAR, p.CompaniaId) + '|'
                    + ISNULL(c.CompaniaRazonSocial, '') + '|'
                    + ISNULL(CONVERT(VARCHAR(10), U.FechaVencimientoClave, 23), '') + '|'
                    + ISNULL(CONVERT(VARCHAR(20), c.DescuentoMax), '0') + '|'
                    + ISNULL(c.CompaniaRUC, '') + '|'
                    + ISNULL(c.CompaniaNomUBG, '') + '|'
                    + ISNULL(c.CompaniaComercial, '') + '|'
                    + ISNULL(c.CompaniaDirecSunat, '') + '|'
                    + ISNULL(c.CompaniaUserSecun, '') + '|'
                    + ISNULL(c.ComapaniaPWD, '') + '|'
                    + ISNULL(c.CompaniaPFX, '') + '|'
                    + ISNULL(c.CompaniaClave, '') + '|'
                    + ISNULL(CONVERT(VARCHAR, c.TIPO_PROCESO), '3') + '|'
                    + ISNULL(c.CompaniaTelefono, '') + '|'
                    + ISNULL(CONVERT(VARCHAR, c.BoletaPorLote), '1') + '|'
                    + ISNULL(CONVERT(VARCHAR, c.FlagCaptura), '0')
                FROM dbo.Usuarios U
                INNER JOIN dbo.Personal p
                    ON p.PersonalId = U.PersonalId
                INNER JOIN dbo.Area a
                    ON a.AreaId = p.AreaId
                INNER JOIN dbo.Compania c
                    ON c.CompaniaId = p.CompaniaId
                WHERE U.UsuarioAlias = @Usuario
                  AND dbo.desincrectar(U.UsuarioClave) = @Clave
                  AND U.UsuarioEstado = 'ACTIVO'
                  AND p.PersonalEstado = 'ACTIVO'
                FOR XML PATH('')
            ),
            1,
            1,
            '')
        ),
        '~'
    );
END;
GO



IF EXISTS
(
    SELECT 1 FROM (VALUES
        ('LDdocumentosweb'),('uspCajaInsertaCsvWeb'),('uspEditarConteoCajaWEB'),
        ('uspEditarRBweb'),('uspGuardarCredencialesSunatweb'),('uspInsertarConteoCajaWEB'),
        ('uspinsertarNotaBweb'),('uspinsertarRBweb'),('uspListarCajaWEB'),
        ('uspListarComprasweb'),('uspObtenerCajaActivaWEB'),('uspObtenerCredencialesSunatweb'),
        ('uspResumenFechaweb'),('uspValidaCantCajasWeb'),('uspValidaUsuarioweb')
    ) p(Nombre)
    WHERE OBJECT_ID(N'dbo.'+p.Nombre,N'P') IS NULL
)
    THROW 51010,'No se crearon todos los procedimientos web requeridos.',1;

COMMIT TRANSACTION;

SELECT 'OK' Estado,15 ProcedimientosWeb;
GO
