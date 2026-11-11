-- Sentencias parametrizadas utilizadas por la API. No ejecutar sin definir parámetros.
-- Lectura de los saldos de una fecha inicial:
SELECT Codigo, Cantidad
FROM dbo.InventarioSaldoInicial
WHERE FechaInicio = @Inicio;

-- Guardado del saldo de un producto y fecha inicial:
SET XACT_ABORT ON;
BEGIN TRANSACTION;
UPDATE dbo.InventarioSaldoInicial WITH (UPDLOCK, SERIALIZABLE)
SET Cantidad = @Cantidad
WHERE Codigo = @Codigo AND FechaInicio = @Inicio;
IF @@ROWCOUNT = 0
    INSERT INTO dbo.InventarioSaldoInicial (Codigo, FechaInicio, Cantidad)
    VALUES (@Codigo, @Inicio, @Cantidad);
COMMIT;
