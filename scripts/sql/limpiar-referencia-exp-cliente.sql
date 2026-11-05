/*
  Elimina referencias con el formato exacto [EXPdd-mm-aaaa] de ClienteRazon.
  Seleccionar la base de datos correcta. Revisar la vista previa y el respaldo.
  0 = solo vista previa; 1 = aplicar. El administrador debe ejecutar el script.
  Ejecutar antes del script de limpieza de signos, que elimina los corchetes.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Aplicar bit = 0;
DECLARE @Patron varchar(100) = '%[[]EXP[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9][]]%';

SELECT DB_NAME() AS BaseDeDatos;

-- Se guardan los valores originales para detectar cambios simultáneos.
IF OBJECT_ID('tempdb..#ReferenciasExp') IS NOT NULL DROP TABLE #ReferenciasExp;
SELECT ClienteId, ClienteRazon AS RazonActual, ClienteRazon AS RazonLimpia
INTO #ReferenciasExp
FROM dbo.Cliente
WHERE PATINDEX(@Patron, UPPER(ClienteRazon)) > 0;

-- También elimina varias referencias del mismo nombre, si las hubiera.
WHILE EXISTS (SELECT 1 FROM #ReferenciasExp WHERE PATINDEX(@Patron, UPPER(RazonLimpia)) > 0)
BEGIN
    UPDATE #ReferenciasExp
    SET RazonLimpia = STUFF(RazonLimpia, PATINDEX(@Patron, UPPER(RazonLimpia)), 15, '')
    WHERE PATINDEX(@Patron, UPPER(RazonLimpia)) > 0;
END;

UPDATE #ReferenciasExp SET RazonLimpia = LTRIM(RTRIM(RazonLimpia));

SELECT ClienteId, RazonActual, RazonLimpia
FROM #ReferenciasExp
ORDER BY RazonActual;

IF EXISTS (SELECT 1 FROM #ReferenciasExp WHERE RazonLimpia = '')
BEGIN
    RAISERROR ('Hay clientes cuya razón social quedaría vacía. Revisarlos antes de continuar.', 16, 1);
    RETURN;
END;

IF @Aplicar = 0
BEGIN
    PRINT 'Vista previa: no se modificaron clientes. Cambie @Aplicar a 1 para aplicar.';
    RETURN;
END;

BEGIN TRANSACTION;

-- Bloquea las filas y cancela si cambiaron después de generar la vista previa.
IF EXISTS (
    SELECT 1 FROM #ReferenciasExp AS r
    LEFT JOIN dbo.Cliente AS c WITH (UPDLOCK, HOLDLOCK) ON c.ClienteId = r.ClienteId
    WHERE c.ClienteId IS NULL OR c.ClienteRazon <> r.RazonActual OR c.ClienteRazon IS NULL
)
BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR ('Un cliente cambió durante la revisión. Vuelva a ejecutar el script.', 16, 1);
    RETURN;
END;

UPDATE c
SET c.ClienteRazon = r.RazonLimpia
FROM dbo.Cliente AS c
INNER JOIN #ReferenciasExp AS r ON r.ClienteId = c.ClienteId;
SELECT @@ROWCOUNT AS ClientesActualizados;
COMMIT TRANSACTION;
