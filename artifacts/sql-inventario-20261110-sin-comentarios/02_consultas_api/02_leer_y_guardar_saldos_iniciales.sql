SELECT Codigo, Cantidad
FROM dbo.InventarioSaldoInicial
WHERE FechaInicio = @Inicio;


SET XACT_ABORT ON;
BEGIN TRANSACTION;
UPDATE dbo.InventarioSaldoInicial WITH (UPDLOCK, SERIALIZABLE)
SET Cantidad = @Cantidad
WHERE Codigo = @Codigo AND FechaInicio = @Inicio;
IF @@ROWCOUNT = 0
    INSERT INTO dbo.InventarioSaldoInicial (Codigo, FechaInicio, Cantidad)
    VALUES (@Codigo, @Inicio, @Cantidad);
COMMIT;
