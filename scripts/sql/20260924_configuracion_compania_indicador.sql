
IF OBJECT_ID(N'dbo.Indicador', N'U') IS NULL
    THROW 51000, 'Debe ejecutar primero 20260924_estructura_dxn_ica2409_sin_compania.sql.', 1;

BEGIN TRANSACTION;

INSERT INTO dbo.Indicador
    (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum, ValorDecimal)
SELECT c.CompaniaId,
       configuracion.Area,
       configuracion.TipoIndicador,
       NULL,
       configuracion.Descripcion,
       configuracion.ValorTexto1,
       configuracion.ValorNum,
       configuracion.ValorDecimal
FROM dbo.Compania c
CROSS JOIN
(
    VALUES
        ('CONFIGURACION', 3, 'FECHA_RENOVACION', NULL, NULL, CAST(NULL AS decimal(18, 2))),
        ('VENTAS',        2, 'DESCUENTO_MAXIMO', NULL, NULL, CAST(0 AS decimal(18, 2))),
        ('CORREO',        3, 'CORREO_SGO', NULL, NULL, CAST(NULL AS decimal(18, 2))),
        ('CORREO',        3, 'PASSWORD_CORREO', NULL, NULL, CAST(NULL AS decimal(18, 2))),
        ('CORREO',        3, 'CORREOS_ADMIN', NULL, NULL, CAST(NULL AS decimal(18, 2))),
        ('CPE',           2, 'TIPO_PROCESO_CPE', NULL, 3, CAST(NULL AS decimal(18, 2))),
        ('VENTAS',        1, 'BOLETA_POR_LOTE', NULL, 1, CAST(NULL AS decimal(18, 2))),
        ('VENTAS',        1, 'CAPTURA_HTML', NULL, 0, CAST(NULL AS decimal(18, 2))),
        ('CAJA',          1, 'MULTIPLES_CAJAS', NULL, 0, CAST(NULL AS decimal(18, 2)))
) configuracion (Area, TipoIndicador, Descripcion, ValorTexto1, ValorNum, ValorDecimal)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Indicador i
    WHERE i.CompaniaId = c.CompaniaId
      AND i.Descripcion = configuracion.Descripcion
);

COMMIT TRANSACTION;
GO
