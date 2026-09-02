/* Corrige solo las filas ya importadas desde la lista de precios PDF. */
BEGIN TRANSACTION;

UPDATE Producto
SET
    ProductoNombre = REPLACE(CASE
        WHEN LEFT(UPPER(LTRIM(RTRIM(ProductoNombre))), 4) = 'DXN '
            THEN LTRIM(SUBSTRING(UPPER(LTRIM(RTRIM(ProductoNombre))), 5, 1000))
        ELSE UPPER(LTRIM(RTRIM(ProductoNombre)))
    END, '''', ''),
    ProductoMarca = 'DXN',
    ProductoUbicacion = '',
    ProductoxCaja = 1,
    ProductoObs = REPLACE(ProductoObs, ';', '')
WHERE ProductoObs LIKE 'CATEGORIA:%'
  AND UPPER(LTRIM(RTRIM(ProductoEstado))) = 'BUENO';

COMMIT TRANSACTION;
