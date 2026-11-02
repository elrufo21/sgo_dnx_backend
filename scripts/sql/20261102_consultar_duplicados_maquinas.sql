-- Diagnóstico de solo lectura; seleccionar primero la base que se va a revisar.
SELECT 'Nombre' AS Campo, UPPER(LTRIM(RTRIM(Maquina))) AS Valor, COUNT(*) AS Cantidad
FROM dbo.MAQUINAS
WHERE NULLIF(LTRIM(RTRIM(Maquina)), '') IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(Maquina)))
HAVING COUNT(*) > 1
UNION ALL
SELECT 'SerieFactura', UPPER(LTRIM(RTRIM(SerieFactura))), COUNT(*)
FROM dbo.MAQUINAS
WHERE NULLIF(LTRIM(RTRIM(SerieFactura)), '') IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(SerieFactura)))
HAVING COUNT(*) > 1;
