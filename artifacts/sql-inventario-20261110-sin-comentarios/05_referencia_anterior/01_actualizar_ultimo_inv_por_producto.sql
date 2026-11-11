UPDATE dbo.Producto
SET UltimoINV = @Cantidad
WHERE IdProducto = @IdProducto;
