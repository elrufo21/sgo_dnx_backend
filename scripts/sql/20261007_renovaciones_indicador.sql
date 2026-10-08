/*
   Migra las fechas de renovación de dbo.Compania a dbo.Indicador.
   Ejecutar antes de publicar la API que lee estos valores desde Indicador.
*/
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.Indicador', N'U') IS NULL
    THROW 50001, 'Debe existir dbo.Indicador antes de migrar las renovaciones.', 1;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH(N'dbo.Compania', N'RenovacionOSE') IS NOT NULL
        EXEC(N'UPDATE i
                 SET ValorTexto1 = CONVERT(varchar(10), c.RenovacionOSE, 23),
                     Area = ''CONFIGURACION'', TipoIndicador = 3,
                     FechaActualizacion = SYSDATETIME()
              FROM dbo.Indicador i
              INNER JOIN dbo.Compania c ON c.CompaniaId = i.CompaniaId
              WHERE i.Descripcion = ''RENOVACION_OSE''
                AND NULLIF(LTRIM(RTRIM(i.ValorTexto1)), '''') IS NULL
                AND c.RenovacionOSE IS NOT NULL;');

    IF COL_LENGTH(N'dbo.Compania', N'RenovacionFirma') IS NOT NULL
        EXEC(N'UPDATE i
                 SET ValorTexto1 = CONVERT(varchar(10), c.RenovacionFirma, 23),
                     Area = ''CONFIGURACION'', TipoIndicador = 3,
                     FechaActualizacion = SYSDATETIME()
              FROM dbo.Indicador i
              INNER JOIN dbo.Compania c ON c.CompaniaId = i.CompaniaId
              WHERE i.Descripcion = ''RENOVACION_FIRMA''
                AND NULLIF(LTRIM(RTRIM(i.ValorTexto1)), '''') IS NULL
                AND c.RenovacionFirma IS NOT NULL;');

    IF COL_LENGTH(N'dbo.Compania', N'RenovacionSome') IS NOT NULL
        EXEC(N'UPDATE i
                 SET ValorTexto1 = CONVERT(varchar(10), c.RenovacionSome, 23),
                     Area = ''CONFIGURACION'', TipoIndicador = 3,
                     FechaActualizacion = SYSDATETIME()
              FROM dbo.Indicador i
              INNER JOIN dbo.Compania c ON c.CompaniaId = i.CompaniaId
              WHERE i.Descripcion = ''RENOVACION_SOME''
                AND NULLIF(LTRIM(RTRIM(i.ValorTexto1)), '''') IS NULL
                AND c.RenovacionSome IS NOT NULL;');

    IF COL_LENGTH(N'dbo.Compania', N'RenovacionOSE') IS NOT NULL
        EXEC(N'INSERT INTO dbo.Indicador (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1)
              SELECT c.CompaniaId, ''CONFIGURACION'', 3, NULL, ''RENOVACION_OSE'', CONVERT(varchar(10), c.RenovacionOSE, 23)
              FROM dbo.Compania c
              WHERE NOT EXISTS (SELECT 1 FROM dbo.Indicador i WHERE i.CompaniaId = c.CompaniaId AND i.Descripcion = ''RENOVACION_OSE'');');

    IF COL_LENGTH(N'dbo.Compania', N'RenovacionFirma') IS NOT NULL
        EXEC(N'INSERT INTO dbo.Indicador (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1)
              SELECT c.CompaniaId, ''CONFIGURACION'', 3, NULL, ''RENOVACION_FIRMA'', CONVERT(varchar(10), c.RenovacionFirma, 23)
              FROM dbo.Compania c
              WHERE NOT EXISTS (SELECT 1 FROM dbo.Indicador i WHERE i.CompaniaId = c.CompaniaId AND i.Descripcion = ''RENOVACION_FIRMA'');');

    IF COL_LENGTH(N'dbo.Compania', N'RenovacionSome') IS NOT NULL
        EXEC(N'INSERT INTO dbo.Indicador (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1)
              SELECT c.CompaniaId, ''CONFIGURACION'', 3, NULL, ''RENOVACION_SOME'', CONVERT(varchar(10), c.RenovacionSome, 23)
              FROM dbo.Compania c
              WHERE NOT EXISTS (SELECT 1 FROM dbo.Indicador i WHERE i.CompaniaId = c.CompaniaId AND i.Descripcion = ''RENOVACION_SOME'');');

    IF COL_LENGTH(N'dbo.Compania', N'RenovacionOSE') IS NOT NULL
        ALTER TABLE dbo.Compania DROP COLUMN RenovacionOSE;
    IF COL_LENGTH(N'dbo.Compania', N'RenovacionFirma') IS NOT NULL
        ALTER TABLE dbo.Compania DROP COLUMN RenovacionFirma;
    IF COL_LENGTH(N'dbo.Compania', N'RenovacionSome') IS NOT NULL
        ALTER TABLE dbo.Compania DROP COLUMN RenovacionSome;

    /* Crea los tres indicadores incluso cuando aún no hay fechas configuradas,
       para que el login pueda distinguir "sin vencimiento" de "sin datos". */
    INSERT INTO dbo.Indicador (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion)
    SELECT c.CompaniaId, 'CONFIGURACION', 3, NULL, nombres.Descripcion
    FROM dbo.Compania c
    CROSS JOIN (VALUES ('RENOVACION_OSE'), ('RENOVACION_FIRMA'), ('RENOVACION_SOME')) nombres(Descripcion)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Indicador i
        WHERE i.CompaniaId = c.CompaniaId AND i.Descripcion = nombres.Descripcion
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
