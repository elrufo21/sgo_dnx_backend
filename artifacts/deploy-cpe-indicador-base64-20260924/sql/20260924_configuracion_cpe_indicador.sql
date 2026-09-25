/*
  Migración CPE WEB a dbo.Indicador.
  Lee la configuración histórica de Compania solo para copiarla una vez.
  No actualiza, inserta ni altera dbo.Compania.
*/
USE [DXN_ICA];
GO

IF OBJECT_ID(N'dbo.Indicador', N'U') IS NULL
BEGIN
    RAISERROR('Debe existir dbo.Indicador antes de migrar la configuración CPE.', 16, 1);
    RETURN;
END;
GO

IF COL_LENGTH(N'dbo.Indicador', N'ValorTexto1') IS NOT NULL
    ALTER TABLE dbo.Indicador ALTER COLUMN ValorTexto1 varchar(max) NULL;
GO

BEGIN TRANSACTION;

INSERT INTO dbo.Indicador
    (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
SELECT c.CompaniaId,
       N'CPE',
       3,
       NULL,
       origen.Descripcion,
       origen.ValorTexto1,
       NULL
FROM dbo.Compania c
CROSS APPLY
(
    VALUES
        (N'CPE_USUARIO_SOL', CAST(c.CompaniaUserSecun AS varchar(max))),
        (N'CPE_CLAVE_SOL', CAST(c.ComapaniaPWD AS varchar(max))),
        (N'CPE_CERTIFICADO_PFX', CAST(c.CompaniaPFX AS varchar(max))),
        (N'CPE_CLAVE_CERTIFICADO', CAST(c.CompaniaClave AS varchar(max)))
) origen (Descripcion, ValorTexto1)
WHERE NULLIF(LTRIM(RTRIM(origen.ValorTexto1)), '') IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.Indicador i
      WHERE i.CompaniaId = c.CompaniaId
        AND i.Descripcion = origen.Descripcion
  );

INSERT INTO dbo.Indicador
    (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
SELECT c.CompaniaId,
       N'CPE',
       2,
       NULL,
       N'TIPO_PROCESO_CPE',
       NULL,
       CASE WHEN c.TIPO_PROCESO IN (1, 2, 3) THEN c.TIPO_PROCESO ELSE 3 END
FROM dbo.Compania c
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Indicador i
    WHERE i.CompaniaId = c.CompaniaId
      AND i.Descripcion = N'TIPO_PROCESO_CPE'
);

COMMIT TRANSACTION;
GO
