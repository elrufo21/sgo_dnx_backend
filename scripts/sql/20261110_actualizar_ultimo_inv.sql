-- Operación parametrizada utilizada por la API; ejecutar solo con valores revisados.
UPDATE dbo.Producto
SET UltimoINV = @Cantidad
WHERE IdProducto = @IdProducto;
