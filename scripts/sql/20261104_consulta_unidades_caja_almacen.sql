-- Consulta de solo lectura utilizada por GET /api/v1/warehouse/units-per-box.
-- No crea ni modifica objetos o datos.
SELECT IdProducto, ProductoxCaja
FROM dbo.Producto;
