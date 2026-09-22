/* Plazos de anulación por compañía. Ejecutar en DXN_ICA. */
USE [DXN_ICA];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.Indicador', N'U') IS NULL
    THROW 51000, 'Debe crear dbo.Indicador antes de configurar la anulación.', 1;

BEGIN TRANSACTION;

INSERT INTO dbo.Indicador
    (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
SELECT c.CompaniaId, 'VENTAS', 0, NULL, 'CONFIGURACION_VENTAS', 'Configuracion de ventas', NULL
FROM dbo.Compania c
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Indicador i
    WHERE i.CompaniaId = c.CompaniaId
      AND i.Area = 'VENTAS'
      AND i.Descripcion = 'CONFIGURACION_VENTAS'
);

INSERT INTO dbo.Indicador
    (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
SELECT c.CompaniaId, 'VENTAS', config.TipoIndicador, padre.Id,
       config.Descripcion, config.Etiqueta, config.ValorNum
FROM dbo.Compania c
CROSS JOIN
(
    VALUES
        (2, 'DIAS_ANULACION_BOLETA', 'Dias para anular boletas', 2),
        (2, 'DIAS_ANULACION_FACTURA', 'Dias para anular facturas', 6),
        (1, 'ANULACION_EXCLUIR_DOMINGOS', 'Excluir domingos del plazo de anulacion', 1)
) config (TipoIndicador, Descripcion, Etiqueta, ValorNum)
CROSS APPLY
(
    SELECT TOP (1) i.Id
    FROM dbo.Indicador i
    WHERE i.CompaniaId = c.CompaniaId
      AND i.Area = 'VENTAS'
      AND i.Descripcion = 'CONFIGURACION_VENTAS'
    ORDER BY i.Id
) padre
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Indicador i
    WHERE i.CompaniaId = c.CompaniaId
      AND i.Area = 'VENTAS'
      AND i.Descripcion = config.Descripcion
);

COMMIT TRANSACTION;
GO
