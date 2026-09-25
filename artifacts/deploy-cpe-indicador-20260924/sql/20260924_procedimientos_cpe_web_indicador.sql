/*
  Procedimientos CPE exclusivos de la WEB.
  Compatible con SQL Server 2008 R2: no usa CREATE OR ALTER.
  No modifica ni depende de los campos CPE de dbo.Compania.
*/
USE [DXN_ICA];
GO

IF OBJECT_ID(N'dbo.Indicador', N'U') IS NULL
BEGIN
    RAISERROR('Debe existir dbo.Indicador antes de crear los procedimientos CPE WEB.', 16, 1);
    RETURN;
END;
GO

IF OBJECT_ID(N'dbo.uspGuardarCredencialesSunatweb', N'P') IS NOT NULL
    DROP PROCEDURE dbo.uspGuardarCredencialesSunatweb;
GO

CREATE PROCEDURE dbo.uspGuardarCredencialesSunatweb
    @CompaniaId int,
    @UsuarioSOL varchar(500),
    @ClaveSOL varchar(500),
    @NombreCertificado varchar(500),
    @ClaveCertificado varchar(500),
    @Entorno int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Compania WHERE CompaniaId = @CompaniaId)
    BEGIN
        RAISERROR('CompaniaId no existe.', 16, 1);
        RETURN;
    END;

    IF @Entorno NOT IN (1, 2, 3)
    BEGIN
        RAISERROR('Entorno CPE inválido.', 16, 1);
        RETURN;
    END;

    BEGIN TRANSACTION;

    DECLARE @Configuracion TABLE
    (
        Descripcion varchar(500) NOT NULL,
        ValorTexto1 varchar(500) NULL,
        ValorNum int NULL,
        TipoIndicador int NOT NULL
    );

    INSERT INTO @Configuracion (Descripcion, ValorTexto1, ValorNum, TipoIndicador)
    VALUES
        ('CPE_USUARIO_SOL', @UsuarioSOL, NULL, 3),
        ('CPE_CLAVE_SOL', @ClaveSOL, NULL, 3),
        ('CPE_CERTIFICADO_PFX', @NombreCertificado, NULL, 3),
        ('CPE_CLAVE_CERTIFICADO', @ClaveCertificado, NULL, 3),
        ('TIPO_PROCESO_CPE', NULL, @Entorno, 2);

    UPDATE i
       SET Area = 'CPE',
           TipoIndicador = c.TipoIndicador,
           ValorTexto1 = c.ValorTexto1,
           ValorNum = c.ValorNum,
           FechaActualizacion = GETDATE()
      FROM dbo.Indicador i
      INNER JOIN @Configuracion c ON c.Descripcion = i.Descripcion
     WHERE i.CompaniaId = @CompaniaId;

    INSERT INTO dbo.Indicador
        (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
    SELECT @CompaniaId, 'CPE', c.TipoIndicador, NULL, c.Descripcion, c.ValorTexto1, c.ValorNum
      FROM @Configuracion c
     WHERE NOT EXISTS
     (
         SELECT 1
           FROM dbo.Indicador i
          WHERE i.CompaniaId = @CompaniaId
            AND i.Descripcion = c.Descripcion
     );

    COMMIT TRANSACTION;
END;
GO

IF OBJECT_ID(N'dbo.uspObtenerCredencialesSunatweb', N'P') IS NOT NULL
    DROP PROCEDURE dbo.uspObtenerCredencialesSunatweb;
GO

CREATE PROCEDURE dbo.uspObtenerCredencialesSunatweb
    @CompaniaId int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        (SELECT TOP 1 ValorTexto1 FROM dbo.Indicador WHERE CompaniaId = @CompaniaId AND Descripcion = 'CPE_USUARIO_SOL' ORDER BY FechaActualizacion DESC, Id DESC) AS UsuarioSOL,
        (SELECT TOP 1 ValorTexto1 FROM dbo.Indicador WHERE CompaniaId = @CompaniaId AND Descripcion = 'CPE_CLAVE_SOL' ORDER BY FechaActualizacion DESC, Id DESC) AS ClaveSOL,
        (SELECT TOP 1 ValorTexto1 FROM dbo.Indicador WHERE CompaniaId = @CompaniaId AND Descripcion = 'CPE_CERTIFICADO_PFX' ORDER BY FechaActualizacion DESC, Id DESC) AS CertificadoPFX,
        (SELECT TOP 1 ValorTexto1 FROM dbo.Indicador WHERE CompaniaId = @CompaniaId AND Descripcion = 'CPE_CLAVE_CERTIFICADO' ORDER BY FechaActualizacion DESC, Id DESC) AS ClaveCertificado,
        COALESCE
        (
            (SELECT TOP 1 ValorNum FROM dbo.Indicador WHERE CompaniaId = @CompaniaId AND Descripcion = 'TIPO_PROCESO_CPE' ORDER BY FechaActualizacion DESC, Id DESC),
            3
        ) AS Entorno
    WHERE EXISTS (SELECT 1 FROM dbo.Compania WHERE CompaniaId = @CompaniaId);
END;
GO
