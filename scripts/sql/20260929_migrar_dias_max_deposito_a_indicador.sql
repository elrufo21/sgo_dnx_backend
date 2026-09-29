
UPDATE i
   SET i.Area = 'CAJA',
       i.TipoIndicador = 2,
       i.ValorNum = COALESCE(i.ValorNum, c.DiasMaxDep, 7),
       i.ValorTexto1 = NULL,
       i.ValorDecimal = NULL,
       i.FechaActualizacion = SYSDATETIME()
  FROM dbo.Indicador i
  INNER JOIN dbo.Compania c ON c.CompaniaId = i.CompaniaId
 WHERE i.Descripcion = 'DIAS_MAX_DEPOSITO';

INSERT dbo.Indicador (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum, ValorDecimal)
SELECT c.CompaniaId, 'CAJA', 2, NULL, 'DIAS_MAX_DEPOSITO', NULL, COALESCE(c.DiasMaxDep, 7), NULL
  FROM dbo.Compania c
 WHERE NOT EXISTS (
       SELECT 1 FROM dbo.Indicador i
        WHERE i.CompaniaId = c.CompaniaId AND i.Descripcion = 'DIAS_MAX_DEPOSITO'
 );

UPDATE c
   SET c.DiasMaxDep = i.ValorNum
  FROM dbo.Compania c
  INNER JOIN dbo.Indicador i ON i.CompaniaId = c.CompaniaId
 WHERE i.Descripcion = 'DIAS_MAX_DEPOSITO'
   AND i.ValorNum IS NOT NULL;

GO
