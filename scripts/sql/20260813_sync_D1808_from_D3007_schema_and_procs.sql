/*
  Sincroniza ESTRUCTURA Y PROCEDIMIENTOS desde DXN_CUSCO_D3007 hacia DXN_CUSCO_D1808.
  No copia, elimina ni actualiza ventas, clientes, productos ni movimientos.
  Requiere que ambas bases existan en la misma instancia de SQL Server.
*/
USE [DXN_CUSCO_D1808];
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

IF DB_ID(N'DXN_CUSCO_D3007') IS NULL
BEGIN
    RAISERROR('No existe la base fuente DXN_CUSCO_D3007 en esta instancia.', 16, 1);
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH(N'dbo.Compania', N'TIPO_PROCESO') IS NULL
        ALTER TABLE dbo.Compania ADD TIPO_PROCESO int NULL;

    EXEC sys.sp_executesql N'UPDATE dbo.Compania SET TIPO_PROCESO = 3 WHERE TIPO_PROCESO IS NULL;';

    IF COL_LENGTH(N'dbo.Compania', N'CompaniaPFX') IS NOT NULL
        ALTER TABLE dbo.Compania ALTER COLUMN CompaniaPFX varchar(max) NULL;

    IF COL_LENGTH(N'dbo.Compania', N'DescuentoMax') IS NULL
        ALTER TABLE dbo.Compania ADD DescuentoMax decimal(18,2) NULL;

    EXEC sys.sp_executesql N'UPDATE dbo.Compania SET DescuentoMax = 0 WHERE DescuentoMax IS NULL;';

    IF COL_LENGTH(N'dbo.Compania', N'RenovacionOSE') IS NULL
        ALTER TABLE dbo.Compania ADD RenovacionOSE date NULL;

    IF COL_LENGTH(N'dbo.Compania', N'RenovacionFirma') IS NULL
        ALTER TABLE dbo.Compania ADD RenovacionFirma date NULL;

    IF COL_LENGTH(N'dbo.Compania', N'RenovacionSome') IS NULL
        ALTER TABLE dbo.Compania ADD RenovacionSome date NULL;

    IF COL_LENGTH(N'dbo.Compania', N'CorreoSGO') IS NULL
        ALTER TABLE dbo.Compania ADD CorreoSGO varchar(250) NULL;

    IF COL_LENGTH(N'dbo.Compania', N'PasswordCorreo') IS NULL
        ALTER TABLE dbo.Compania ADD PasswordCorreo varchar(250) NULL;

    IF COL_LENGTH(N'dbo.Compania', N'CorreosAdmin') IS NULL
        ALTER TABLE dbo.Compania ADD CorreosAdmin varchar(max) NULL;

    IF COL_LENGTH(N'dbo.Compania', N'BoletaPorLote') IS NULL
        ALTER TABLE dbo.Compania ADD BoletaPorLote bit NOT NULL
            CONSTRAINT DF_Compania_BoletaPorLote DEFAULT ((1)) WITH VALUES;

    IF COL_LENGTH(N'dbo.Compania', N'FlagCaptura') IS NULL
        ALTER TABLE dbo.Compania ADD FlagCaptura bit NOT NULL
            CONSTRAINT DF_Compania_FlagCaptura DEFAULT ((0)) WITH VALUES;

    IF COL_LENGTH(N'dbo.Usuarios', N'FechaVencimientoClave') IS NULL
        ALTER TABLE dbo.Usuarios ADD FechaVencimientoClave date NULL;

    IF COL_LENGTH(N'dbo.ResumenBoletas', N'CDRBase64') IS NULL
        ALTER TABLE dbo.ResumenBoletas ADD CDRBase64 varchar(max) NULL;

    IF OBJECT_ID(N'dbo.DocumentoVentaCpeWeb', N'U') IS NULL
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
            FechaRegistro datetime NOT NULL
                CONSTRAINT DF_DocumentoVentaCpeWeb_FechaRegistro DEFAULT (GETDATE()),
            CONSTRAINT PK_DocumentoVentaCpeWeb PRIMARY KEY (DocuId)
        );
    END;

    DECLARE @procedimientos TABLE (Nombre sysname NOT NULL PRIMARY KEY);
    INSERT INTO @procedimientos (Nombre)
    VALUES
        (N'dbo.uspEditarRBweb'),
        (N'dbo.uspGuardarCredencialesSunatweb'),
        (N'dbo.uspinsertarNotaBweb'),
        (N'dbo.uspinsertarRBweb'),
        (N'dbo.uspInsertarPagoVarios'),
        (N'dbo.uspObtenerCredencialesSunatweb'),
        (N'dbo.uspResumenFechaweb'),
        (N'dbo.uspValidaUsuarioweb');

    DECLARE @nombre sysname;
    DECLARE @definicion nvarchar(max);
    DECLARE @definicionEsperada nvarchar(max);
    DECLARE @definicionInicial nvarchar(max);
    DECLARE @objetoId int;

    DECLARE procedimientos_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT Nombre FROM @procedimientos ORDER BY Nombre;

    OPEN procedimientos_cursor;
    FETCH NEXT FROM procedimientos_cursor INTO @nombre;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @definicion = m.definition
        FROM DXN_CUSCO_D3007.sys.sql_modules m
        INNER JOIN DXN_CUSCO_D3007.sys.objects o ON o.object_id = m.object_id
        INNER JOIN DXN_CUSCO_D3007.sys.schemas s ON s.schema_id = o.schema_id
        WHERE s.name + N'.' + o.name = @nombre
          AND o.type IN (N'P', N'PC');

        IF @definicion IS NULL
        BEGIN
            RAISERROR('No se encontró el procedimiento fuente %s.', 16, 1, @nombre);
            RETURN;
        END;

        SET @objetoId = OBJECT_ID(@nombre, N'P');
        IF @objetoId IS NULL
        BEGIN
            SET @definicionInicial = N'CREATE PROCEDURE ' + @nombre + N' AS BEGIN SET NOCOUNT ON; END;';
            EXEC sys.sp_executesql @definicionInicial;
        END;

        SET @definicionEsperada = REPLACE(@definicion, N'CREATE PROCEDURE', N'ALTER PROCEDURE');
        SET @definicionEsperada = REPLACE(@definicionEsperada, N'create procedure', N'ALTER PROCEDURE');

        IF CHARINDEX(N'ALTER PROCEDURE', @definicionEsperada) = 0
        BEGIN
            RAISERROR('La definición fuente de %s no tiene un encabezado CREATE PROCEDURE válido.', 16, 1, @nombre);
            RETURN;
        END;

        EXEC sys.sp_executesql @definicionEsperada;

        IF OBJECT_DEFINITION(OBJECT_ID(@nombre, N'P')) <> @definicion
        BEGIN
            RAISERROR('No se pudo validar el procedimiento %s.', 16, 1, @nombre);
            RETURN;
        END;

        FETCH NEXT FROM procedimientos_cursor INTO @nombre;
    END;

    CLOSE procedimientos_cursor;
    DEALLOCATE procedimientos_cursor;

    IF COL_LENGTH(N'dbo.Compania', N'FlagCaptura') IS NULL
       OR COL_LENGTH(N'dbo.Compania', N'BoletaPorLote') IS NULL
       OR COL_LENGTH(N'dbo.ResumenBoletas', N'CDRBase64') IS NULL
       OR COL_LENGTH(N'dbo.Usuarios', N'FechaVencimientoClave') IS NULL
    BEGIN
        RAISERROR('La validación de columnas no fue satisfactoria.', 16, 1);
        RETURN;
    END;

    COMMIT TRANSACTION;
    PRINT 'DXN_CUSCO_D1808 quedó sincronizada en estructura y procedimientos con DXN_CUSCO_D3007.';
END TRY
BEGIN CATCH
    DECLARE @mensajeError nvarchar(4000);
    DECLARE @severidadError int;
    DECLARE @estadoError int;

    SELECT
        @mensajeError = ERROR_MESSAGE(),
        @severidadError = ERROR_SEVERITY(),
        @estadoError = ERROR_STATE();

    IF CURSOR_STATUS('local', 'procedimientos_cursor') >= 0
    BEGIN
        CLOSE procedimientos_cursor;
        DEALLOCATE procedimientos_cursor;
    END;

    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    RAISERROR(@mensajeError, @severidadError, @estadoError);
END CATCH;
