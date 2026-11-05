/*
  Limpieza de Cliente.ClienteRazon: elimina . , { } [ ].
  Seleccionar primero la base de datos correcta (COMAS o ICA) en SSMS.
  Revisar la vista previa y contar con respaldo. Para aplicar, cambiar @Aplicar a 1.
  El script se entrega para el administrador de SQL; no se ejecuta desde la aplicación.
  No modifica mayúsculas, espacios ni otros caracteres.
  Si existen referencias [EXPdd-mm-aaaa], ejecutar primero
  limpiar-referencia-exp-cliente.sql para no perder sus delimitadores.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Aplicar bit = 0; -- 0 = solo vista previa; 1 = aplicar cambios.

SELECT DB_NAME() AS BaseDeDatos;

-- Vista previa de todos los clientes que cambiarían.
SELECT c.ClienteId, c.ClienteRazon AS RazonActual, x.RazonLimpia
FROM dbo.Cliente AS c
CROSS APPLY (SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    c.ClienteRazon, '.', ''), ',', ''), '{', ''), '}', ''), '[', ''), ']', '') AS RazonLimpia) AS x
WHERE CHARINDEX('.', c.ClienteRazon) > 0 OR CHARINDEX(',', c.ClienteRazon) > 0
   OR CHARINDEX('{', c.ClienteRazon) > 0 OR CHARINDEX('}', c.ClienteRazon) > 0
   OR CHARINDEX('[', c.ClienteRazon) > 0 OR CHARINDEX(']', c.ClienteRazon) > 0;

-- No dejar una razón social vacía. Corregir manualmente estos casos antes de continuar.
IF EXISTS (
    SELECT 1
    FROM dbo.Cliente AS c
    CROSS APPLY (SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        c.ClienteRazon, '.', ''), ',', ''), '{', ''), '}', ''), '[', ''), ']', '') AS RazonLimpia) AS x
    WHERE (CHARINDEX('.', c.ClienteRazon) > 0 OR CHARINDEX(',', c.ClienteRazon) > 0
        OR CHARINDEX('{', c.ClienteRazon) > 0 OR CHARINDEX('}', c.ClienteRazon) > 0
        OR CHARINDEX('[', c.ClienteRazon) > 0 OR CHARINDEX(']', c.ClienteRazon) > 0)
      AND LTRIM(RTRIM(x.RazonLimpia)) = ''
)
BEGIN
    RAISERROR ('Hay clientes cuya razón social quedaría vacía. Revisar la vista previa y corregirlos antes de continuar.', 16, 1);
    RETURN;
END;

IF @Aplicar = 0
BEGIN
    PRINT 'Vista previa: no se modificaron registros. Cambie @Aplicar a 1 para aplicar.';
    RETURN;
END;

BEGIN TRANSACTION;
UPDATE c
SET ClienteRazon = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    c.ClienteRazon, '.', ''), ',', ''), '{', ''), '}', ''), '[', ''), ']', '')
FROM dbo.Cliente AS c
WHERE CHARINDEX('.', c.ClienteRazon) > 0 OR CHARINDEX(',', c.ClienteRazon) > 0
   OR CHARINDEX('{', c.ClienteRazon) > 0 OR CHARINDEX('}', c.ClienteRazon) > 0
   OR CHARINDEX('[', c.ClienteRazon) > 0 OR CHARINDEX(']', c.ClienteRazon) > 0;
SELECT @@ROWCOUNT AS ClientesActualizados;
COMMIT TRANSACTION;
