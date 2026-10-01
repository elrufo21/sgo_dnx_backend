/*
  Verificacion de configuracion SUNAT/SIRE por compania.
  Solo lectura: no crea tablas ni escribe credenciales.
  Reemplazar el RUC antes de ejecutar en cada base de produccion.
*/
SET NOCOUNT ON;

DECLARE @Ruc varchar(11);
SET @Ruc = 'REEMPLAZAR_RUC';

IF OBJECT_ID('dbo.Indicador', 'U') IS NULL
BEGIN
    RAISERROR('No existe dbo.Indicador en esta base de datos.', 16, 1);
    RETURN;
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Compania WHERE CompaniaRUC = @Ruc)
BEGIN
    RAISERROR('No se encontro una compania con el RUC indicado.', 16, 1);
    RETURN;
END;

;WITH ClavesEsperadas AS
(
    SELECT 'SUNAT_USUARIO_SOL' AS Descripcion UNION ALL
    SELECT 'SUNAT_CLAVE_SOL' UNION ALL
    SELECT 'SUNAT_SIRE_CLIENT_ID' UNION ALL
    SELECT 'SUNAT_SIRE_CLIENT_SECRET' UNION ALL
    SELECT 'SUNAT_VALIDAR_CLIENT_ID' UNION ALL
    SELECT 'SUNAT_VALIDAR_CLIENT_SECRET'
)
SELECT
    c.CompaniaRUC,
    k.Descripcion,
    COUNT(i.Id) AS Filas,
    CASE
        WHEN COUNT(i.Id) = 0 THEN 'PENDIENTE'
        WHEN COUNT(i.Id) > 1 THEN 'DUPLICADO'
        WHEN MAX(CASE WHEN NULLIF(LTRIM(RTRIM(i.ValorTexto1)), '') IS NULL THEN 0 ELSE 1 END) = 0 THEN 'PENDIENTE'
        ELSE 'CONFIGURADO'
    END AS Estado
FROM dbo.Compania c
CROSS JOIN ClavesEsperadas k
LEFT JOIN dbo.Indicador i
    ON i.CompaniaId = c.CompaniaId
   AND i.Area = 'SUNAT'
   AND i.Descripcion = k.Descripcion
WHERE c.CompaniaRUC = @Ruc
GROUP BY c.CompaniaRUC, k.Descripcion
ORDER BY k.Descripcion;
