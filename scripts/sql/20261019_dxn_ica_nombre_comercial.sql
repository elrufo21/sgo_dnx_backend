/*
   Registra el nombre comercial DXN ICA en la base local de pruebas.
   Conserva CompaniaRazonSocial; el correo prioriza CompaniaComercial.
*/
USE [DXN_ICA15102026];
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.Compania
    WHERE CompaniaId = 1
      AND LTRIM(RTRIM(ISNULL(CompaniaComercial, ''))) IN ('LINO ESPIRITU WILDER', 'DXN ICA')
)
BEGIN
    RAISERROR('No se encontró la compañía esperada para actualizar el nombre comercial.', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
END;

UPDATE dbo.Compania
   SET CompaniaComercial = 'DXN ICA'
 WHERE CompaniaId = 1
   AND LTRIM(RTRIM(ISNULL(CompaniaComercial, ''))) = 'LINO ESPIRITU WILDER';

COMMIT TRANSACTION;
GO

SELECT CompaniaId, CompaniaRazonSocial, CompaniaComercial
FROM dbo.Compania
WHERE CompaniaId = 1;
