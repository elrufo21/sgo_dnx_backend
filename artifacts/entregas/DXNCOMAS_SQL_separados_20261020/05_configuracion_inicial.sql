

DECLARE @TipoProcesoCpe int = 3;
DECLARE @MultiplesCajas int = 0;
DECLARE @CapturaHtml int = 0;
DECLARE @BoletaPorLote int = 1;

IF OBJECT_ID(N'dbo.Indicador', N'U') IS NULL
    BEGIN
        RAISERROR('Ejecutar primero 01_tablas_dxncomas.sql.', 16, 1);
        RETURN;
    END;
IF @TipoProcesoCpe NOT IN (1, 2, 3)
    BEGIN
        RAISERROR('Tipo de proceso CPE inválido.', 16, 1);
        RETURN;
    END;
IF @MultiplesCajas NOT IN (0, 1) OR @CapturaHtml NOT IN (0, 1) OR @BoletaPorLote NOT IN (0, 1)
    BEGIN
        RAISERROR('Los flags de configuración deben ser 0 o 1.', 16, 1);
        RETURN;
    END;

BEGIN TRY
    BEGIN TRANSACTION;

    IF EXISTS
    (
        SELECT CompaniaId, Descripcion
        FROM dbo.Indicador
        WHERE IdIndicador IS NULL
        GROUP BY CompaniaId, Descripcion
        HAVING COUNT(*) > 1
    )
        BEGIN
            RAISERROR('Hay indicadores raíz duplicados. Revisar antes de inicializar.', 16, 1);
            RETURN;
        END;

    INSERT INTO dbo.Indicador
        (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum, ValorDecimal)
    SELECT c.CompaniaId, v.Area, v.TipoIndicador, NULL, v.Descripcion,
           v.ValorTexto1, v.ValorNum, v.ValorDecimal
    FROM dbo.Compania c
    CROSS APPLY
    (
        VALUES
        ('CAJA', 1, 'ASISTENCIA', CAST('Exigir asistencia en ventas y caja' AS varchar(max)), 1, CAST(NULL AS decimal(18,2))),
        ('CAJA', 1, 'MULTIPLES_CAJAS', NULL, @MultiplesCajas, NULL),
        ('CAJA', 2, 'DIAS_MAX_DEPOSITO', NULL, c.DiasMaxDep, NULL),
        ('VENTAS', 1, 'CAPTURA_HTML', NULL, @CapturaHtml, NULL),
        ('VENTAS', 1, 'BOLETA_POR_LOTE', NULL, @BoletaPorLote, NULL),
        ('VENTAS', 2, 'DESCUENTO_MAXIMO', NULL, NULL, CAST(0 AS decimal(18,2))),
        ('CONFIGURACION', 3, 'FECHA_RENOVACION', NULL, NULL, NULL),
        ('CONFIGURACION', 3, 'RENOVACION_OSE', CONVERT(varchar(10), c.RenovacionOSE, 23), NULL, NULL),
        ('CONFIGURACION', 3, 'RENOVACION_FIRMA', CONVERT(varchar(10), c.RenovacionFirma, 23), NULL, NULL),
        ('CONFIGURACION', 3, 'RENOVACION_SOME', CONVERT(varchar(10), c.RenovacionSome, 23), NULL, NULL),
        ('CORREO', 3, 'CORREO_SGO', NULL, NULL, NULL),
        ('CORREO', 3, 'PASSWORD_CORREO', NULL, NULL, NULL),
        ('CORREO', 3, 'CORREOS_ADMIN', NULL, NULL, NULL),
        ('CPE', 2, 'TIPO_PROCESO_CPE', NULL, @TipoProcesoCpe, NULL),
        ('CPE', 3, 'CPE_USUARIO_SOL', CAST(NULLIF(LTRIM(RTRIM(c.CompaniaUserSecun)), '') AS varchar(max)), NULL, NULL),
        ('CPE', 3, 'CPE_CLAVE_SOL', CAST(NULLIF(LTRIM(RTRIM(c.ComapaniaPWD)), '') AS varchar(max)), NULL, NULL),
        ('CPE', 3, 'CPE_CERTIFICADO_PFX', NULL, NULL, NULL),
        ('CPE', 3, 'CPE_CLAVE_CERTIFICADO', CAST(NULLIF(LTRIM(RTRIM(c.CompaniaClave)), '') AS varchar(max)), NULL, NULL),
        ('SUNAT', 3, 'SUNAT_USUARIO_SOL', NULL, NULL, NULL),
        ('SUNAT', 3, 'SUNAT_CLAVE_SOL', NULL, NULL, NULL),
        ('SUNAT', 3, 'SUNAT_VALIDAR_CLIENT_ID', NULL, NULL, NULL),
        ('SUNAT', 3, 'SUNAT_VALIDAR_CLIENT_SECRET', NULL, NULL, NULL),
        ('SUNAT', 3, 'SUNAT_SIRE_CLIENT_ID', NULL, NULL, NULL),
        ('SUNAT', 3, 'SUNAT_SIRE_CLIENT_SECRET', NULL, NULL, NULL)
    ) v (Area, TipoIndicador, Descripcion, ValorTexto1, ValorNum, ValorDecimal)
    WHERE NOT EXISTS
    (
        SELECT 1 FROM dbo.Indicador i WITH (UPDLOCK, HOLDLOCK)
        WHERE i.CompaniaId = c.CompaniaId
          AND i.Area = v.Area
          AND i.TipoIndicador = v.TipoIndicador
          AND i.IdIndicador IS NULL
          AND i.Descripcion = v.Descripcion
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
    SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    RETURN;
END CATCH;

SELECT N'Configuración inicial creada. Completar PFX, destinatarios, permisos, series y entorno antes del pase.' AS Resultado;
GO
