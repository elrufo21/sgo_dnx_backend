/*
  Limpieza de Cliente.ClienteRazon: primero elimina referencias [EXPdd-mm-aaaa],
  luego elimina los signos . , { } [ ]. Conserva los demás caracteres y quita
  espacios al inicio y al final. Seleccionar la base correcta antes de ejecutar.
  Revisar resultados y respaldo; cambiar @Aplicar a 1 solo para aplicar.
  No identifica referencias EXP que ya hayan perdido los corchetes.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Aplicar bit = 0; -- 0: vista previa; 1: actualizar.
DECLARE @Patron varchar(100) = '%[[]EXP[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9][]]%';

SELECT DB_NAME() AS BaseDeDatos;
IF OBJECT_ID('tempdb..#LimpiezaCliente') IS NOT NULL DROP TABLE #LimpiezaCliente;

SELECT ClienteId, ClienteRazon AS RazonActual, ClienteRazon AS RazonLimpia
INTO #LimpiezaCliente
FROM dbo.Cliente
WHERE CHARINDEX('.', ClienteRazon) > 0 OR CHARINDEX(',', ClienteRazon) > 0
   OR CHARINDEX('{', ClienteRazon) > 0 OR CHARINDEX('}', ClienteRazon) > 0
   OR CHARINDEX('[', ClienteRazon) > 0 OR CHARINDEX(']', ClienteRazon) > 0;

WHILE EXISTS (SELECT 1 FROM #LimpiezaCliente WHERE PATINDEX(@Patron, UPPER(RazonLimpia)) > 0)
BEGIN
    UPDATE #LimpiezaCliente
    SET RazonLimpia = STUFF(RazonLimpia, PATINDEX(@Patron, UPPER(RazonLimpia)), 15, '')
    WHERE PATINDEX(@Patron, UPPER(RazonLimpia)) > 0;
END;

UPDATE #LimpiezaCliente
SET RazonLimpia = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    RazonLimpia, '.', ''), ',', ''), '{', ''), '}', ''), '[', ''), ']', '')));

SELECT ClienteId, RazonActual, RazonLimpia
FROM #LimpiezaCliente
ORDER BY RazonActual;

IF EXISTS (SELECT 1 FROM #LimpiezaCliente WHERE RazonLimpia = '')
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
IF EXISTS (
    SELECT 1 FROM #LimpiezaCliente AS r
    LEFT JOIN dbo.Cliente AS c WITH (UPDLOCK, HOLDLOCK) ON c.ClienteId = r.ClienteId
    WHERE c.ClienteId IS NULL OR c.ClienteRazon <> r.RazonActual OR c.ClienteRazon IS NULL
)
BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR ('Un cliente cambió durante la ejecución. Vuelva a ejecutar el script.', 16, 1);
    RETURN;
END;

UPDATE c
SET c.ClienteRazon = r.RazonLimpia
FROM dbo.Cliente AS c
INNER JOIN #LimpiezaCliente AS r ON r.ClienteId = c.ClienteId;
SELECT @@ROWCOUNT AS ClientesActualizados;
COMMIT TRANSACTION;
