/* Activa el requisito de asistencia para Caja en la compañía 1 de la BD local de pruebas. */
USE [DXN_ICA15102026];
GO

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.Indicador
    WHERE CompaniaId = 1
      AND Area = 'CAJA'
      AND TipoIndicador = 1
      AND IdIndicador IS NULL
      AND Descripcion = 'ASISTENCIA'
)
BEGIN
    RAISERROR('No se encontró el indicador ASISTENCIA de Caja para la compañía 1.', 16, 1);
    RETURN;
END;
GO

UPDATE dbo.Indicador
   SET ValorNum = 1
 WHERE CompaniaId = 1
   AND Area = 'CAJA'
   AND TipoIndicador = 1
   AND IdIndicador IS NULL
   AND Descripcion = 'ASISTENCIA'
   AND ISNULL(ValorNum, 0) <> 1;
GO

SELECT CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorNum
FROM dbo.Indicador
WHERE CompaniaId = 1
  AND Area = 'CAJA'
  AND TipoIndicador = 1
  AND IdIndicador IS NULL
  AND Descripcion = 'ASISTENCIA';
