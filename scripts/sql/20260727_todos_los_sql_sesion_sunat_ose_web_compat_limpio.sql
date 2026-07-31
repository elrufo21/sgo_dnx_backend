SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF COL_LENGTH('dbo.Compania', 'TIPO_PROCESO') IS NULL
    ALTER TABLE dbo.Compania ADD TIPO_PROCESO int NULL
GO

UPDATE dbo.Compania
   SET TIPO_PROCESO = 3
 WHERE TIPO_PROCESO IS NULL
GO

IF COL_LENGTH('dbo.Compania', 'CompaniaPFX') IS NOT NULL
    ALTER TABLE dbo.Compania ALTER COLUMN CompaniaPFX varchar(max) NULL
GO

IF COL_LENGTH('dbo.Compania', 'DescuentoMax') IS NULL
    ALTER TABLE dbo.Compania ADD DescuentoMax decimal(18,2) NULL
GO

UPDATE dbo.Compania
   SET DescuentoMax = 0
 WHERE DescuentoMax IS NULL
GO

IF COL_LENGTH('dbo.Compania', 'RenovacionOSE') IS NULL
    ALTER TABLE dbo.Compania ADD RenovacionOSE date NULL
GO

IF COL_LENGTH('dbo.Compania', 'RenovacionFirma') IS NULL
    ALTER TABLE dbo.Compania ADD RenovacionFirma date NULL
GO

IF COL_LENGTH('dbo.Compania', 'RenovacionSome') IS NULL
    ALTER TABLE dbo.Compania ADD RenovacionSome date NULL
GO

IF COL_LENGTH('dbo.Compania', 'CorreoSGO') IS NULL
    ALTER TABLE dbo.Compania ADD CorreoSGO varchar(250) NULL
GO

IF COL_LENGTH('dbo.Compania', 'PasswordCorreo') IS NULL
    ALTER TABLE dbo.Compania ADD PasswordCorreo varchar(250) NULL
GO

IF COL_LENGTH('dbo.Compania', 'CorreosAdmin') IS NULL
    ALTER TABLE dbo.Compania ADD CorreosAdmin varchar(max) NULL
GO

IF COL_LENGTH('dbo.Compania', 'BoletaPorLote') IS NULL
    ALTER TABLE dbo.Compania ADD BoletaPorLote bit NOT NULL CONSTRAINT DF_Compania_BoletaPorLote DEFAULT ((1))
GO
IF COL_LENGTH('dbo.Usuarios', 'FechaVencimientoClave') IS NULL
    ALTER TABLE dbo.Usuarios ADD FechaVencimientoClave date NULL
GO

IF COL_LENGTH('dbo.ResumenBoletas', 'CDRBase64') IS NULL
    ALTER TABLE dbo.ResumenBoletas ADD CDRBase64 varchar(max) NULL
GO

IF OBJECT_ID('dbo.DocumentoVentaCpeWeb', 'U') IS NULL
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
        FechaRegistro datetime NOT NULL CONSTRAINT DF_DocumentoVentaCpeWeb_FechaRegistro DEFAULT (GETDATE()),
        CONSTRAINT PK_DocumentoVentaCpeWeb PRIMARY KEY (DocuId)
    )
END
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'ClienteRazon') IS NOT NULL
   AND COL_LENGTH('dbo.DocumentoVenta', 'ClienteRuc') IS NOT NULL
   AND COL_LENGTH('dbo.DocumentoVenta', 'ClienteDni') IS NOT NULL
   AND COL_LENGTH('dbo.DocumentoVenta', 'DireccionFiscal') IS NOT NULL
   AND COL_LENGTH('dbo.DocumentoVenta', 'DocuPdfUrl') IS NOT NULL
   AND COL_LENGTH('dbo.DocumentoVenta', 'DocuXmlUrl') IS NOT NULL
   AND COL_LENGTH('dbo.DocumentoVenta', 'DocuCdrUrl') IS NOT NULL
   AND COL_LENGTH('dbo.DocumentoVenta', 'DocuFechaPago') IS NOT NULL
BEGIN
    EXEC('
        UPDATE w
           SET w.ClienteRazon = d.ClienteRazon,
               w.ClienteRuc = d.ClienteRuc,
               w.ClienteDni = d.ClienteDni,
               w.DireccionFiscal = d.DireccionFiscal,
               w.DocuPdfUrl = d.DocuPdfUrl,
               w.DocuXmlUrl = d.DocuXmlUrl,
               w.DocuCdrUrl = d.DocuCdrUrl,
               w.DocuFechaPago = d.DocuFechaPago
        FROM dbo.DocumentoVentaCpeWeb w
        INNER JOIN dbo.DocumentoVenta d ON d.DocuId = w.DocuId;

        INSERT INTO dbo.DocumentoVentaCpeWeb
        (
            DocuId, ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal,
            DocuPdfUrl, DocuXmlUrl, DocuCdrUrl, DocuFechaPago
        )
        SELECT
            d.DocuId, d.ClienteRazon, d.ClienteRuc, d.ClienteDni, d.DireccionFiscal,
            d.DocuPdfUrl, d.DocuXmlUrl, d.DocuCdrUrl, d.DocuFechaPago
        FROM dbo.DocumentoVenta d
        WHERE d.DocuId IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM dbo.DocumentoVentaCpeWeb w WHERE w.DocuId = d.DocuId);
    ')
END
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'ClienteRazon') IS NOT NULL
    ALTER TABLE dbo.DocumentoVenta DROP COLUMN ClienteRazon
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'ClienteRuc') IS NOT NULL
    ALTER TABLE dbo.DocumentoVenta DROP COLUMN ClienteRuc
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'ClienteDni') IS NOT NULL
    ALTER TABLE dbo.DocumentoVenta DROP COLUMN ClienteDni
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'DireccionFiscal') IS NOT NULL
    ALTER TABLE dbo.DocumentoVenta DROP COLUMN DireccionFiscal
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'DocuPdfUrl') IS NOT NULL
    ALTER TABLE dbo.DocumentoVenta DROP COLUMN DocuPdfUrl
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'DocuXmlUrl') IS NOT NULL
    ALTER TABLE dbo.DocumentoVenta DROP COLUMN DocuXmlUrl
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'DocuCdrUrl') IS NOT NULL
    ALTER TABLE dbo.DocumentoVenta DROP COLUMN DocuCdrUrl
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'DocuFechaPago') IS NOT NULL
    ALTER TABLE dbo.DocumentoVenta DROP COLUMN DocuFechaPago
GO
IF OBJECT_ID('dbo.uspGuardarCredencialesSunatweb', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspGuardarCredencialesSunatweb
GO

CREATE PROCEDURE dbo.uspGuardarCredencialesSunatweb
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

IF OBJECT_ID('dbo.uspObtenerCredencialesSunatweb', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspObtenerCredencialesSunatweb
GO

CREATE PROCEDURE dbo.uspObtenerCredencialesSunatweb
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
IF OBJECT_ID('dbo.uspinsertarRBweb', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspinsertarRBweb
GO

CREATE PROCEDURE dbo.uspinsertarRBweb
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
IF OBJECT_ID('dbo.uspEditarRBweb', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspEditarRBweb
GO

CREATE PROCEDURE dbo.uspEditarRBweb
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
IF OBJECT_ID('dbo.uspValidaUsuarioweb', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspValidaUsuarioweb
GO

CREATE PROCEDURE dbo.uspValidaUsuarioweb
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @p1 int, @p2 int
    DECLARE @Usuario varchar(150), @Clave varchar(150)

    SET @Data = LTRIM(RTRIM(@Data))
    SET @p1 = CHARINDEX('|', @Data, 0)
    SET @p2 = CHARINDEX('|', @Data, @p1 + 1)
    IF (@p2 = 0) SET @p2 = LEN(@Data) + 1

    SET @Usuario = SUBSTRING(@Data, 1, @p1 - 1)
    SET @Clave = SUBSTRING(@Data, @p1 + 1, @p2 - @p1 - 1)

    SELECT ISNULL((
        SELECT STUFF((
            SELECT TOP 1
                '¬' + CONVERT(varchar, U.UsuarioID) + '|' +
                CONVERT(varchar, p.PersonalId) + '|' +
                ISNULL(a.AreaNombre, '') + '|' +
                (
                    SUBSTRING(ISNULL(p.PersonalNombres, '') + ' ', 1, CHARINDEX(' ', ISNULL(p.PersonalNombres, '') + ' ') - 1) + ' ' +
                    SUBSTRING(ISNULL(p.PersonalApellidos, '') + ' ', 1, CHARINDEX(' ', ISNULL(p.PersonalApellidos, '') + ' ') - 1)
                ) + '|' +
                CONVERT(varchar, p.CompaniaId) + '|' +
                ISNULL(c.CompaniaRazonSocial, '') + '|' +
                ISNULL(CONVERT(varchar(10), U.FechaVencimientoClave, 23), '') + '|' +
                ISNULL(CONVERT(varchar(20), c.DescuentoMax), '0') + '|' +
                ISNULL(c.CompaniaRUC, '') + '|' +
                ISNULL(c.CompaniaNomUBG, '') + '|' +
                ISNULL(c.CompaniaComercial, '') + '|' +
                ISNULL(c.CompaniaDirecSunat, '') + '|' +
                ISNULL(c.CompaniaUserSecun, '') + '|' +
                ISNULL(c.ComapaniaPWD, '') + '|' +
                ISNULL(c.CompaniaPFX, '') + '|' +
                ISNULL(c.CompaniaClave, '') + '|' +
                ISNULL(CONVERT(varchar, c.TIPO_PROCESO), '3') + '|' +
                ISNULL(c.CompaniaTelefono, '') + '|' +
                ISNULL(CONVERT(varchar, c.BoletaPorLote), '1')
            FROM dbo.Usuarios U
            INNER JOIN dbo.Personal p ON p.PersonalId = U.PersonalId
            INNER JOIN dbo.Area a ON a.AreaId = p.AreaId
            INNER JOIN dbo.Compania c ON c.CompaniaId = p.CompaniaId
            WHERE U.UsuarioAlias = @Usuario
              AND dbo.desincrectar(U.UsuarioClave) = @Clave
              AND U.UsuarioEstado = 'ACTIVO'
              AND p.PersonalEstado = 'ACTIVO'
            FOR XML PATH('')
        ), 1, 1, '')
    ), '~')
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.uspResumenFechaweb', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspResumenFechaweb
GO

CREATE PROCEDURE dbo.uspResumenFechaweb
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
IF OBJECT_ID('dbo.uspinsertarNotaBweb', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspinsertarNotaBweb;
GO

CREATE PROCEDURE dbo.uspinsertarNotaBweb
    @ListaOrden varchar(max)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @pos1 int;
    DECLARE @orden varchar(max);
    DECLARE @detalle varchar(max);

    SET @pos1 = CHARINDEX('[', @ListaOrden, 1);
    IF @pos1 <= 0
    BEGIN
        RAISERROR('Formato de orden invalido.', 16, 1);
        RETURN;
    END

    SET @orden = SUBSTRING(@ListaOrden, 1, @pos1 - 1);
    SET @detalle = SUBSTRING(@ListaOrden, @pos1 + 1, LEN(@ListaOrden) - @pos1);

    DECLARE @campos TABLE
    (
        Pos int IDENTITY(1,1) NOT NULL,
        Valor varchar(max) NULL
    );

    DECLARE @start int;
    DECLARE @end int;

    SET @start = 1;
    WHILE @start <= LEN(@orden) + 1
    BEGIN
        SET @end = CHARINDEX('|', @orden, @start);
        IF @end = 0 SET @end = LEN(@orden) + 1;

        INSERT INTO @campos (Valor)
        VALUES (SUBSTRING(@orden, @start, @end - @start));

        SET @start = @end + 1;
    END

    DECLARE
        @NotaDocu varchar(60),
        @ClienteId numeric(20),
        @NotaUsuario varchar(60),
        @NotaFormaPago varchar(60),
        @NotaCondicion varchar(60),
        @NotaDireccion varchar(max),
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

    SELECT @NotaDocu = Valor FROM @campos WHERE Pos = 1;
    SELECT @ClienteId = CONVERT(numeric(20), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 2;
    SELECT @NotaUsuario = Valor FROM @campos WHERE Pos = 3;
    SELECT @NotaFormaPago = Valor FROM @campos WHERE Pos = 4;
    SELECT @NotaCondicion = Valor FROM @campos WHERE Pos = 5;
    SELECT @NotaDireccion = Valor FROM @campos WHERE Pos = 6;
    SELECT @NotaSubtotal = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 7;
    SELECT @NotaMovilidad = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 8;
    SELECT @NotaDescuento = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 9;
    SELECT @NotaTotal = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 10;
    SELECT @NotaAcuenta = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 11;
    SELECT @NotaSaldo = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 12;
    SELECT @NotaAdicional = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 13;
    SELECT @NotaTarjeta = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 14;
    SELECT @NotaPagar = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 15;
    SELECT @NotaEstado = Valor FROM @campos WHERE Pos = 16;
    SELECT @CompaniaId = CONVERT(int, ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 17;
    SELECT @NotaEntrega = Valor FROM @campos WHERE Pos = 18;
    SELECT @NotaConcepto = Valor FROM @campos WHERE Pos = 19;
    SELECT @Serie = Valor FROM @campos WHERE Pos = 20;
    SELECT @Numero = Valor FROM @campos WHERE Pos = 21;
    SELECT @NotaGanancia = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 22;
    SELECT @Letra = Valor FROM @campos WHERE Pos = 23;
    SELECT @DocuAdicional = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 24;
    SELECT @DocuHash = Valor FROM @campos WHERE Pos = 25;
    SELECT @EstadoSunat = Valor FROM @campos WHERE Pos = 26;
    SELECT @DocuSubtotal = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 27;
    SELECT @DocuIGV = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 28;
    SELECT @UsuarioId = CONVERT(int, ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 29;
    SELECT @NotaTransaccion = Valor FROM @campos WHERE Pos = 30;
    SELECT @Miembro = Valor FROM @campos WHERE Pos = 31;
    SELECT @CodigoCliente = Valor FROM @campos WHERE Pos = 32;
    SELECT @ICBPER = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 33;
    SELECT @DocuGravada = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 34;
    SELECT @ConceptoOBS = Valor FROM @campos WHERE Pos = 35;
    SELECT @EstadoOBS = Valor FROM @campos WHERE Pos = 36;
    SELECT @PV = Valor FROM @campos WHERE Pos = 37;
    SELECT @Image = Valor FROM @campos WHERE Pos = 38;
    SELECT @CodigoRes = Valor FROM @campos WHERE Pos = 39;
    SELECT @Responsable = Valor FROM @campos WHERE Pos = 40;
    SELECT @EntidadBancaria = Valor FROM @campos WHERE Pos = 41;
    SELECT @Efectivo = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 42;
    SELECT @Deposito = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @campos WHERE Pos = 43;
    SELECT @NroOperacion = Valor FROM @campos WHERE Pos = 44;

    SET @NotaDocu = ISNULL(NULLIF(LTRIM(RTRIM(@NotaDocu)), ''), 'BOLETA');
    SET @NotaUsuario = ISNULL(@NotaUsuario, '');
    SET @NotaFormaPago = ISNULL(NULLIF(@NotaFormaPago, ''), 'EFECTIVO');
    SET @NotaCondicion = ISNULL(NULLIF(@NotaCondicion, ''), 'ALCONTADO');
    SET @NotaDireccion = ISNULL(NULLIF(@NotaDireccion, ''), '-');
    SET @NotaEstado = ISNULL(NULLIF(@NotaEstado, ''), 'PENDIENTE');
    SET @CompaniaId = ISNULL(NULLIF(@CompaniaId, 0), 1);
    SET @NotaEntrega = ISNULL(NULLIF(@NotaEntrega, ''), 'INMEDIATA');
    SET @NotaConcepto = ISNULL(NULLIF(@NotaConcepto, ''), 'MERCADERIA');
    SET @Serie = ISNULL(NULLIF(@Serie, ''), CASE WHEN @NotaDocu = 'FACTURA' THEN 'FA01' ELSE 'BA01' END);
    SET @Letra = ISNULL(@Letra, '');
    SET @DocuHash = ISNULL(@DocuHash, '');
    SET @EstadoSunat = ISNULL(NULLIF(@EstadoSunat, ''), 'PENDIENTE');
    SET @NotaTransaccion = ISNULL(@NotaTransaccion, '');
    SET @Miembro = ISNULL(@Miembro, '');
    SET @CodigoCliente = ISNULL(@CodigoCliente, '');
    SET @ConceptoOBS = ISNULL(NULLIF(@ConceptoOBS, ''), 'VENTA');
    SET @EstadoOBS = ISNULL(NULLIF(@EstadoOBS, ''), 'EMITIDO');
    SET @CodigoRes = ISNULL(@CodigoRes, '');
    SET @Responsable = ISNULL(@Responsable, '');
    SET @EntidadBancaria = ISNULL(NULLIF(@EntidadBancaria, ''), '-');
    SET @NroOperacion = ISNULL(@NroOperacion, '');

    IF @NotaDocu = 'FACTURA' SET @TipoCodigo = '01';
    ELSE IF @NotaDocu = 'PROFORMA V' SET @TipoCodigo = '00';
    ELSE SET @TipoCodigo = '03';

    SELECT TOP 1
        @ClienteRazon = NULLIF(LTRIM(RTRIM(ClienteRazon)), ''),
        @ClienteRuc = NULLIF(LTRIM(RTRIM(ClienteRuc)), ''),
        @ClienteDni = NULLIF(LTRIM(RTRIM(ClienteDni)), ''),
        @DireccionFiscal = NULLIF(LTRIM(RTRIM(ClienteDireccion)), '')
    FROM Cliente
    WHERE ClienteId = @ClienteId;

    SET @ClienteRazon = ISNULL(@ClienteRazon, CASE WHEN @Miembro <> '' THEN @Miembro ELSE 'VARIOS' END);
    SET @ClienteRuc = ISNULL(@ClienteRuc, '');
    SET @ClienteDni = ISNULL(@ClienteDni, '');
    IF @NotaDocu = 'BOLETA' AND @ClienteRuc = '' AND @ClienteDni = '' SET @ClienteDni = '00000000';
    SET @DireccionFiscal = ISNULL(@DireccionFiscal, @NotaDireccion);
    IF NULLIF(@DireccionFiscal, '') IS NULL SET @DireccionFiscal = '-';

    IF @NotaFormaPago <> 'EFECTIVO'
    BEGIN
        IF @Efectivo IS NULL SET @Efectivo = 0;
        IF @Deposito IS NULL OR @Deposito = 0 SET @Deposito = @NotaPagar;
    END
    ELSE
    BEGIN
        IF @Efectivo IS NULL OR @Efectivo = 0 SET @Efectivo = @NotaPagar;
        IF @Deposito IS NULL SET @Deposito = 0;
    END

    IF @NotaCondicion = 'CREDITO'
    BEGIN
        SET @NotaEstado = 'EMITIDO';
        SET @NotaSaldo = @NotaPagar;
        SET @NotaAcuenta = 0;
    END
    ELSE IF @NotaDocu <> 'FACTURA' AND @NotaDocu <> 'PROFORMA V'
    BEGIN
        SET @NotaEstado = 'CANCELADO';
        SET @NotaSaldo = 0;
        SET @NotaAcuenta = @NotaPagar;
    END

    IF @NotaTransaccion <> ''
       AND EXISTS (SELECT 1 FROM NotaPedido WHERE NotaTransaccion = @NotaTransaccion)
    BEGIN
        SELECT 'EXISTE';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Cliente
           SET ClienteDespacho = @NotaDireccion
         WHERE ClienteId = @ClienteId;

        DELETE FROM TemporalVenta
         WHERE UsuarioID = @UsuarioId;

        SELECT @cod = ISNULL(
            (SELECT TOP 1 dbo.genenerarNroFactura(@Serie, @CompaniaId, @NotaDocu) FROM DocumentoVenta),
            '00000001'
        );

        INSERT INTO NotaPedido
        (
            NotaDocu, ClienteId, NotaFecha, NotaUsuario, NotaFormaPago,
            NotaCondicion, NotaFechaPago, NotaDireccion, NotaSubtotal,
            NotaMovilidad, NotaDescuento, NotaTotal, NotaAcuenta, NotaSaldo,
            NotaAdicional, NotaTarjeta, NotaPagar, NotaEstado, CompaniaId,
            NotaEntrega, ModificadoPor, FechaEdita, NotaConcepto, NotaSerie,
            NotaNumero, NotaGanancia, CajaId, NotaTransaccion, ICBPER,
            ConceptoOBS, EstadoOBS, CodigoRes, Responsable, EntidadBancaria,
            NroOperacion, Efectivo, Deposito
        )
        VALUES
        (
            @NotaDocu, @ClienteId, GETDATE(), @NotaUsuario, @NotaFormaPago,
            @NotaCondicion, GETDATE(), @NotaDireccion, @NotaSubtotal,
            @NotaMovilidad, @NotaDescuento, @NotaTotal, @NotaAcuenta, @NotaSaldo,
            @NotaAdicional, @NotaTarjeta, @NotaPagar, @NotaEstado, @CompaniaId,
            @NotaEntrega, '', NULL, @NotaConcepto, @Serie,
            @cod, @NotaGanancia, NULL, @NotaTransaccion, @ICBPER,
            @ConceptoOBS, @EstadoOBS, @CodigoRes, @Responsable, @EntidadBancaria,
            @NroOperacion, @Efectivo, @Deposito
        );

        SET @NotaId = SCOPE_IDENTITY();

        INSERT INTO DocumentoVenta
        (
            CompaniaId, NotaId, DocuDocumento, DocuNumero, ClienteId,
            DocuRegistro, DocuEmision, DocuCondicion, DocuLetras,
            DocuSubTotal, DocuIgv, DocuTotal, DocuSaldo, DocuUsuario,
            DocuEstado, DocuSerie, TipoCodigo, DocuAdicional, DocuAsociado,
            DocuConcepto, DocuNroGuia, DocuHash, EstadoSunat, DocuOperacion,
            DocuTransaccion, ICBPER, CodigoSunat, MensajeSunat, FormaPago,
            EntidadBancaria, NroOperacion, Efectivo, Deposito
        )
        VALUES
        (
            @CompaniaId, @NotaId, @NotaDocu, @cod, @ClienteId,
            GETDATE(), GETDATE(), @NotaCondicion, @Letra,
            @DocuSubtotal, @DocuIGV, @NotaPagar, 0, @NotaUsuario,
            'EMITIDO', @Serie, @TipoCodigo, @DocuAdicional, '',
            'VENTA', '', @DocuHash,
            CASE WHEN @NotaDocu = 'PROFORMA V' THEN 'ENVIADO' ELSE @EstadoSunat END,
            @NotaConcepto, @NotaTransaccion, @ICBPER, '', '', @NotaFormaPago,
            @EntidadBancaria, @NroOperacion, @Efectivo, @Deposito
        );

        SET @DocuId = SCOPE_IDENTITY();

        INSERT INTO dbo.DocumentoVentaCpeWeb
        (
            DocuId, ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal,
            DocuPdfUrl, DocuXmlUrl, DocuCdrUrl, DocuFechaPago
        )
        VALUES
        (
            @DocuId, @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal,
            '', '', '', GETDATE()
        );

        DECLARE detalle_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT splitdata
            FROM dbo.fnSplitString(@detalle, ';')
            WHERE LEN(LTRIM(RTRIM(splitdata))) > 0;

        DECLARE @Columna varchar(max);
        OPEN detalle_cursor;
        FETCH NEXT FROM detalle_cursor INTO @Columna;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @detalleCampos TABLE
            (
                Pos int IDENTITY(1,1) NOT NULL,
                Valor varchar(max) NULL
            );

            SET @start = 1;
            WHILE @start <= LEN(@Columna) + 1
            BEGIN
                SET @end = CHARINDEX('|', @Columna, @start);
                IF @end = 0 SET @end = LEN(@Columna) + 1;

                INSERT INTO @detalleCampos (Valor)
                VALUES (SUBSTRING(@Columna, @start, @end - @start));

                SET @start = @end + 1;
            END

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

            SELECT @IdProducto = CONVERT(numeric(20), ISNULL(NULLIF(Valor, ''), '0')) FROM @detalleCampos WHERE Pos = 1;
            SELECT @DetalleCantidad = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @detalleCampos WHERE Pos = 2;
            SELECT @DetalleUm = Valor FROM @detalleCampos WHERE Pos = 3;
            SELECT @Descripcion = Valor FROM @detalleCampos WHERE Pos = 4;
            SELECT @DetalleCosto = CONVERT(decimal(18,4), ISNULL(NULLIF(Valor, ''), '0')) FROM @detalleCampos WHERE Pos = 5;
            SELECT @DetallePrecio = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @detalleCampos WHERE Pos = 6;
            SELECT @DetallePV = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @detalleCampos WHERE Pos = 7;
            SELECT @DetalleSV = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @detalleCampos WHERE Pos = 8;
            SELECT @DetalleImporte = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''), '0')) FROM @detalleCampos WHERE Pos = 9;
            SELECT @DetalleEstado = Valor FROM @detalleCampos WHERE Pos = 10;
            SELECT @ValorUM = CONVERT(decimal(18,4), ISNULL(NULLIF(Valor, ''), '0')) FROM @detalleCampos WHERE Pos = 11;

            SET @DetalleUm = ISNULL(NULLIF(@DetalleUm, ''), 'UNIDAD');
            SET @Descripcion = ISNULL(@Descripcion, '');
            SET @DetalleEstado = ISNULL(NULLIF(@DetalleEstado, ''), 'PENDIENTE');
            IF @ValorUM IS NULL OR @ValorUM = 0 SET @ValorUM = 1;
            IF @NotaEntrega = 'INMEDIATA' SET @CantidadSaldo = 0;
            ELSE SET @CantidadSaldo = @DetalleCantidad;

            INSERT INTO DetallePedido
            (
                NotaId, IdProducto, DetalleCantidad, DetalleUm,
                DetalleDescripcion, DetalleCosto, DetallePrecio,
                DetalleImporte, DetalleEstado, CantidadSaldo, ValorUM,
                DetallePV, DetalleSV
            )
            VALUES
            (
                @NotaId, @IdProducto, @DetalleCantidad, @DetalleUm,
                @Descripcion, @DetalleCosto, @DetallePrecio,
                @DetalleImporte, @DetalleEstado, @CantidadSaldo, @ValorUM,
                @DetallePV, @DetalleSV
            );

            IF @DocuId <> 0
            BEGIN
                INSERT INTO DetalleDocumento
                (
                    DocuId, IdProducto, DetalleCantidad, DetallPrecio,
                    DetalleImporte, DetalleNotaId, DetalleUM, ValorUM
                )
                VALUES
                (
                    @DocuId, @IdProducto, @DetalleCantidad, @DetallePrecio,
                    @DetalleImporte, @NotaId, @DetalleUm, @ValorUM
                );
            END

            IF @NotaDocu <> 'FACTURA'
            BEGIN
                SELECT TOP 1 @IniciaStock = ProductoCantidad
                FROM Producto
                WHERE IdProducto = @IdProducto;

                SET @IniciaStock = ISNULL(@IniciaStock, 0);
                SET @StockFinal = @IniciaStock - @DetalleCantidad;

                INSERT INTO Kardex
                (
                    IdProducto, KardexFecha, KardexMotivo, KardexDocumento,
                    StockInicial, CantidadIngreso, CantidadSalida, PrecioCosto,
                    StockFinal, KadexConcepto, Usuario, CLIENTE, CODIGOCLIENTE,
                    NROTRANSAC, TipoCodigo, Serie, TipoOperacion,
                    Consideracion, DocuId, CompraId, Estado
                )
                VALUES
                (
                    @IdProducto, GETDATE(), 'Salida por Venta', @cod,
                    @IniciaStock, 0, @DetalleCantidad, @DetalleCosto,
                    @StockFinal, 'SALIDA', @NotaUsuario, @Miembro, @CodigoCliente,
                    @NotaTransaccion, @TipoCodigo, @Serie, '01',
                    CASE WHEN @NotaEntrega = 'INMEDIATA' THEN 'S' ELSE 'N' END,
                    CONVERT(varchar(40), @DocuId), '', 'E'
                );

                IF @NotaEntrega = 'INMEDIATA'
                BEGIN
                    UPDATE Producto
                       SET ProductoCantidad = ProductoCantidad - @DetalleCantidad
                     WHERE IdProducto = @IdProducto;
                END
            END

            FETCH NEXT FROM detalle_cursor INTO @Columna;
        END

        CLOSE detalle_cursor;
        DEALLOCATE detalle_cursor;

        COMMIT TRANSACTION;

        SELECT CONVERT(varchar(38), @NotaId) + N'¬' + @cod;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'detalle_cursor') > -1
        BEGIN
            CLOSE detalle_cursor;
            DEALLOCATE detalle_cursor;
        END

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @ErrMsg nvarchar(4000);
        DECLARE @ErrSeverity int;
        DECLARE @ErrState int;

        SELECT
            @ErrMsg = ERROR_MESSAGE(),
            @ErrSeverity = ERROR_SEVERITY(),
            @ErrState = ERROR_STATE();

        RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
    END CATCH
END;
GO
