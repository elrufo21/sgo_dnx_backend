/*
  Normaliza la identidad de indicadores de configuración por compañía.
  Compatible con SQL Server 2008 R2. Ejecutar con la base destino seleccionada.
  No modifica valores de negocio ni indicadores jerárquicos de permisos.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.Indicador', N'U') IS NULL
BEGIN
    RAISERROR('No existe dbo.Indicador en la base seleccionada.', 16, 1);
    RETURN;
END;

DECLARE @Catalog TABLE
(
    Descripcion varchar(500) NOT NULL PRIMARY KEY,
    Area varchar(100) NOT NULL,
    TipoIndicador int NOT NULL,
    PadreDescripcion varchar(500) NULL
);

INSERT INTO @Catalog (Descripcion, Area, TipoIndicador, PadreDescripcion)
VALUES
    ('FECHA_RENOVACION', 'CONFIGURACION', 3, NULL),
    ('RENOVACION_OSE', 'CONFIGURACION', 3, NULL),
    ('RENOVACION_FIRMA', 'CONFIGURACION', 3, NULL),
    ('RENOVACION_SOME', 'CONFIGURACION', 3, NULL),
    ('DESCUENTO_MAXIMO', 'VENTAS', 2, NULL),
    ('CORREO_SGO', 'CORREO', 3, NULL),
    ('PASSWORD_CORREO', 'CORREO', 3, NULL),
    ('CORREOS_ADMIN', 'CORREO', 3, NULL),
    ('BOLETA_POR_LOTE', 'VENTAS', 1, NULL),
    ('CAPTURA_HTML', 'VENTAS', 1, NULL),
    ('MULTIPLES_CAJAS', 'CAJA', 1, NULL),
    ('ASISTENCIA', 'CAJA', 1, NULL),
    ('DIAS_MAX_DEPOSITO', 'CAJA', 2, NULL),
    ('TIPO_PROCESO_CPE', 'CPE', 2, NULL),
    ('CPE_USUARIO_SOL', 'CPE', 3, NULL),
    ('CPE_CLAVE_SOL', 'CPE', 3, NULL),
    ('CPE_CERTIFICADO_PFX', 'CPE', 3, NULL),
    ('CPE_CLAVE_CERTIFICADO', 'CPE', 3, NULL),
    ('SUNAT_USUARIO_SOL', 'SUNAT', 3, NULL),
    ('SUNAT_CLAVE_SOL', 'SUNAT', 3, NULL),
    ('SUNAT_VALIDAR_CLIENT_ID', 'SUNAT', 3, NULL),
    ('SUNAT_VALIDAR_CLIENT_SECRET', 'SUNAT', 3, NULL),
    ('SUNAT_SIRE_CLIENT_ID', 'SUNAT', 3, NULL),
    ('SUNAT_SIRE_CLIENT_SECRET', 'SUNAT', 3, NULL),
    ('CONFIGURACION_VENTAS', 'VENTAS', 0, NULL),
    ('DIAS_ANULACION_BOLETA', 'VENTAS', 2, 'CONFIGURACION_VENTAS'),
    ('DIAS_ANULACION_FACTURA', 'VENTAS', 2, 'CONFIGURACION_VENTAS'),
    ('ANULACION_EXCLUIR_DOMINGOS', 'VENTAS', 1, 'CONFIGURACION_VENTAS');

/* Ambigüedades no se resuelven eligiendo un valor arbitrariamente. */
IF EXISTS
(
    SELECT i.CompaniaId, i.Descripcion
    FROM dbo.Indicador i
    INNER JOIN @Catalog c ON c.Descripcion = i.Descripcion
    WHERE i.CompaniaId IS NOT NULL
    GROUP BY i.CompaniaId, i.Descripcion
    HAVING COUNT(*) > 1
)
BEGIN
    SELECT i.CompaniaId, i.Descripcion, COUNT(*) AS Filas
    FROM dbo.Indicador i
    INNER JOIN @Catalog c ON c.Descripcion = i.Descripcion
    WHERE i.CompaniaId IS NOT NULL
    GROUP BY i.CompaniaId, i.Descripcion
    HAVING COUNT(*) > 1;
    RAISERROR('Hay indicadores de configuración duplicados por compañía. Revisar el resultado y resolverlos antes de normalizar.', 16, 1);
    RETURN;
END;

/* Un indicador hijo solo se mueve si su categoría padre es única y está disponible. */
IF EXISTS
(
    SELECT 1
    FROM dbo.Indicador i
    INNER JOIN @Catalog c ON c.Descripcion = i.Descripcion AND c.PadreDescripcion IS NOT NULL
    WHERE i.CompaniaId IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.Indicador p
          WHERE p.CompaniaId = i.CompaniaId
            AND p.Descripcion = c.PadreDescripcion
      )
)
BEGIN
    SELECT i.CompaniaId, i.Descripcion, c.PadreDescripcion AS PadreRequerido
    FROM dbo.Indicador i
    INNER JOIN @Catalog c ON c.Descripcion = i.Descripcion AND c.PadreDescripcion IS NOT NULL
    WHERE i.CompaniaId IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.Indicador p
          WHERE p.CompaniaId = i.CompaniaId
            AND p.Descripcion = c.PadreDescripcion
      );
    RAISERROR('Falta la categoría padre de uno o más indicadores hijos. Completarla antes de normalizar.', 16, 1);
    RETURN;
END;

/* Las opciones configurables son raíces, salvo los plazos que cuelgan de CONFIGURACION_VENTAS. */
IF EXISTS
(
    SELECT 1
    FROM dbo.Indicador i
    INNER JOIN @Catalog c ON c.Descripcion = i.Descripcion AND c.PadreDescripcion IS NULL
    INNER JOIN dbo.Indicador hijo ON hijo.IdIndicador = i.Id
    WHERE NOT EXISTS
    (
        SELECT 1 FROM @Catalog hijoCatalogo
        WHERE hijoCatalogo.PadreDescripcion = i.Descripcion
    )
      AND EXISTS
      (
          SELECT 1
          FROM dbo.Indicador descendiente
          WHERE descendiente.IdIndicador = i.Id
            AND NOT EXISTS
            (
                SELECT 1 FROM @Catalog catalogoDescendiente
                WHERE catalogoDescendiente.Descripcion = descendiente.Descripcion
            )
      )
      AND i.CompaniaId IS NOT NULL
)
BEGIN
    RAISERROR('Una opción de configuración que debería ser raíz tiene indicadores hijos. Revisar antes de normalizar.', 16, 1);
    RETURN;
END;

DECLARE @FilasActualizadas int;
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE i
       SET Area = c.Area,
           TipoIndicador = c.TipoIndicador,
           IdIndicador = NULL
    FROM dbo.Indicador i
    INNER JOIN @Catalog c ON c.Descripcion = i.Descripcion AND c.PadreDescripcion IS NULL
    WHERE i.CompaniaId IS NOT NULL
      AND (ISNULL(i.Area, '') <> c.Area OR ISNULL(i.TipoIndicador, -1) <> c.TipoIndicador
           OR i.IdIndicador IS NOT NULL);

    SET @FilasActualizadas = @@ROWCOUNT;

    UPDATE i
       SET Area = c.Area,
           TipoIndicador = c.TipoIndicador,
           IdIndicador = padre.Id
    FROM dbo.Indicador i
    INNER JOIN @Catalog c ON c.Descripcion = i.Descripcion AND c.PadreDescripcion IS NOT NULL
    INNER JOIN dbo.Indicador padre
      ON padre.CompaniaId = i.CompaniaId
     AND padre.Area = 'VENTAS'
     AND padre.TipoIndicador = 0
     AND padre.IdIndicador IS NULL
     AND padre.Descripcion = c.PadreDescripcion
    WHERE i.CompaniaId IS NOT NULL
      AND (ISNULL(i.Area, '') <> c.Area OR ISNULL(i.TipoIndicador, -1) <> c.TipoIndicador
           OR i.IdIndicador <> padre.Id OR i.IdIndicador IS NULL);

    SET @FilasActualizadas = @FilasActualizadas + @@ROWCOUNT;
    COMMIT TRANSACTION;

    SELECT @FilasActualizadas AS FilasNormalizadas,
           DB_NAME() AS BaseDeDatos,
           'Los valores ValorTexto1, ValorNum y ValorDecimal se conservaron.' AS Resultado;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage nvarchar(4000);
    SELECT @ErrorMessage = ERROR_MESSAGE();
    RAISERROR('%s', 16, 1, @ErrorMessage);
END CATCH;
GO
