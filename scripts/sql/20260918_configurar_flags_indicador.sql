/* Configuración inicial de flags por compañía en dbo.Indicador. */
USE [DXN_ICA];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF COL_LENGTH(N'dbo.Indicador', N'CompaniaId') IS NULL
    ALTER TABLE dbo.Indicador ADD CompaniaId int NULL;
GO

BEGIN TRANSACTION;

IF NOT EXISTS
(
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_Indicador_Compania'
      AND parent_object_id = OBJECT_ID(N'dbo.Indicador')
)
    ALTER TABLE dbo.Indicador WITH CHECK
    ADD CONSTRAINT FK_Indicador_Compania
        FOREIGN KEY (CompaniaId) REFERENCES dbo.Compania (CompaniaId);

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_Indicador_Compania_Descripcion'
      AND object_id = OBJECT_ID(N'dbo.Indicador')
)
    CREATE INDEX IX_Indicador_Compania_Descripcion
        ON dbo.Indicador (CompaniaId, Descripcion);

/* Categorías raíz. TipoIndicador = 0 identifica una categoría. */
INSERT INTO dbo.Indicador
    (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
SELECT c.CompaniaId, raiz.Area, 0, NULL, raiz.Descripcion, raiz.Etiqueta, NULL
FROM dbo.Compania c
CROSS JOIN
(
    VALUES
        ('CAJA',   'CONFIGURACION_CAJA',   'Configuración de caja'),
        ('VENTAS', 'CONFIGURACION_VENTAS', 'Configuración de ventas')
) raiz (Area, Descripcion, Etiqueta)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Indicador i
    WHERE i.CompaniaId = c.CompaniaId
      AND i.Descripcion = raiz.Descripcion
);

/* TipoIndicador = 1 identifica un flag booleano: ValorNum 0 = no, 1 = sí. */
INSERT INTO dbo.Indicador
    (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
SELECT c.CompaniaId, flag.Area, 1, padre.Id, flag.Descripcion, flag.Etiqueta, 0
FROM dbo.Compania c
INNER JOIN
(
    VALUES
        ('CAJA',   'CONFIGURACION_CAJA',   'MULTIPLES_CAJAS', 'Permitir múltiples cajas abiertas'),
        ('VENTAS', 'CONFIGURACION_VENTAS', 'CAPTURA_HTML',    'Habilitar captura HTML de ventas'),
        ('VENTAS', 'CONFIGURACION_VENTAS', 'BOLETA_POR_LOTE', 'Habilitar emisión de boletas por lote')
) flag (Area, DescripcionPadre, Descripcion, Etiqueta)
    ON 1 = 1
INNER JOIN dbo.Indicador padre
    ON padre.CompaniaId = c.CompaniaId
   AND padre.Descripcion = flag.DescripcionPadre
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Indicador i
    WHERE i.CompaniaId = c.CompaniaId
      AND i.Descripcion = flag.Descripcion
);

COMMIT TRANSACTION;
GO
