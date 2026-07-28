/*
    Parche minimo SUNAT/OSE para DNX.
    Compatible con SQL Server 2008 R2.

    Ejecutar sobre la base destino, por ejemplo:
    sqlcmd -S "localhost\SQLEXPSS_2008" -d "DXN_CUSCO_D" -E -i scripts\sql\20260727_sunat_ose_sql2008.sql
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

PRINT '1/5 Columnas requeridas por Compania'
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

PRINT '2/5 Columnas requeridas por login, resumen y DocumentoVenta'
GO

IF COL_LENGTH('dbo.Usuarios', 'FechaVencimientoClave') IS NULL
    ALTER TABLE dbo.Usuarios ADD FechaVencimientoClave date NULL
GO

IF COL_LENGTH('dbo.ResumenBoletas', 'CDRBase64') IS NULL
    ALTER TABLE dbo.ResumenBoletas ADD CDRBase64 varchar(max) NULL
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'ClienteRazon') IS NULL
    ALTER TABLE dbo.DocumentoVenta ADD ClienteRazon varchar(140) NULL
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'ClienteRuc') IS NULL
    ALTER TABLE dbo.DocumentoVenta ADD ClienteRuc varchar(40) NULL
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'ClienteDni') IS NULL
    ALTER TABLE dbo.DocumentoVenta ADD ClienteDni varchar(40) NULL
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'DireccionFiscal') IS NULL
    ALTER TABLE dbo.DocumentoVenta ADD DireccionFiscal varchar(max) NULL
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'DocuPdfUrl') IS NULL
    ALTER TABLE dbo.DocumentoVenta ADD DocuPdfUrl varchar(500) NULL
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'DocuXmlUrl') IS NULL
    ALTER TABLE dbo.DocumentoVenta ADD DocuXmlUrl varchar(500) NULL
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'DocuCdrUrl') IS NULL
    ALTER TABLE dbo.DocumentoVenta ADD DocuCdrUrl varchar(500) NULL
GO

IF COL_LENGTH('dbo.DocumentoVenta', 'DocuFechaPago') IS NULL
    ALTER TABLE dbo.DocumentoVenta ADD DocuFechaPago date NULL
GO

PRINT '3/6 SP credenciales SUNAT'
GO

IF OBJECT_ID('dbo.uspGuardarCredencialesSunat', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspGuardarCredencialesSunat
GO

CREATE PROCEDURE dbo.uspGuardarCredencialesSunat
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

IF OBJECT_ID('dbo.uspObtenerCredencialesSunat', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspObtenerCredencialesSunat
GO

CREATE PROCEDURE dbo.uspObtenerCredencialesSunat
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

PRINT '4/6 SP resumen boletas: registrar con columnas explicitas'
GO

IF OBJECT_ID('dbo.uspinsertarRB', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspinsertarRB
GO

CREATE PROCEDURE dbo.uspinsertarRB
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

PRINT '5/6 SP resumen boletas: guardar CDRBase64'
GO

IF OBJECT_ID('dbo.uspEditarRB', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspEditarRB
GO

CREATE PROCEDURE dbo.uspEditarRB
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

PRINT '6/6 SP login: devolver credenciales SUNAT/OSE'
GO

IF OBJECT_ID('dbo.uspValidaUsuario', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspValidaUsuario
GO

CREATE PROCEDURE dbo.uspValidaUsuario
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

PRINT 'Verificacion'
GO

SELECT 'Compania.TIPO_PROCESO' AS Objeto, CASE WHEN COL_LENGTH('dbo.Compania', 'TIPO_PROCESO') IS NULL THEN 'FALTA' ELSE 'OK' END AS Estado
UNION ALL SELECT 'Compania.CompaniaPFX varchar(max)', CASE WHEN EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Compania' AND COLUMN_NAME = 'CompaniaPFX' AND DATA_TYPE = 'varchar' AND CHARACTER_MAXIMUM_LENGTH = -1
) THEN 'OK' ELSE 'FALTA' END
UNION ALL SELECT 'ResumenBoletas.CDRBase64', CASE WHEN COL_LENGTH('dbo.ResumenBoletas', 'CDRBase64') IS NULL THEN 'FALTA' ELSE 'OK' END
UNION ALL SELECT 'DocumentoVenta urls CPE', CASE WHEN COL_LENGTH('dbo.DocumentoVenta', 'DocuXmlUrl') IS NULL OR COL_LENGTH('dbo.DocumentoVenta', 'DocuCdrUrl') IS NULL THEN 'FALTA' ELSE 'OK' END
UNION ALL SELECT 'uspGuardarCredencialesSunat', CASE WHEN OBJECT_ID('dbo.uspGuardarCredencialesSunat', 'P') IS NULL THEN 'FALTA' ELSE 'OK' END
UNION ALL SELECT 'uspObtenerCredencialesSunat', CASE WHEN OBJECT_ID('dbo.uspObtenerCredencialesSunat', 'P') IS NULL THEN 'FALTA' ELSE 'OK' END
UNION ALL SELECT 'uspinsertarRB', CASE WHEN OBJECT_ID('dbo.uspinsertarRB', 'P') IS NULL THEN 'FALTA' ELSE 'OK' END
UNION ALL SELECT 'uspEditarRB', CASE WHEN OBJECT_ID('dbo.uspEditarRB', 'P') IS NULL THEN 'FALTA' ELSE 'OK' END
UNION ALL SELECT 'uspValidaUsuario', CASE WHEN OBJECT_ID('dbo.uspValidaUsuario', 'P') IS NULL THEN 'FALTA' ELSE 'OK' END
GO
