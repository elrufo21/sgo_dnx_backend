# Extracción de lista de precios PDF

`ProductoPdfService.LeerProductos(Stream)` transforma una lista de precios DXN en datos estructurados: vigencia, página, categoría, código, nombre, unidad, contenido, precio de distribuidor, precio de menudeo, SV y PV.

El servicio usa las coordenadas del PDF para reconstruir las filas y replica los precios de celdas combinadas, como los filtros de la sección de electrodomésticos. En este documento, 30 filas se dibujan como vectores sin texto extraíble; sus valores verificados se completan solo cuando reconoce esta lista por su vigencia y código `FB007`.

Después de revisar la vista previa, el frontend envía los productos a `POST /api/v1/Productos/lista-precios-pdf/guardar`. El endpoint registra cada fila en la tabla `Producto` mediante el flujo normal del repositorio y conserva el código del PDF (por ejemplo, `FB007`). Si el código ya existe, actualiza ese producto. Guarda código, nombre, observación, usuario y cualquier otro texto en mayúsculas; usa `IdSubLinea = 1` y `ProductoUM = "UNIDAD"`. El precio de distribuidor va a costo, el de menudeo a venta, y PV/SV se conservan en sus campos correspondientes. El resultado informa registrados, actualizados y errores.

Para obtener un archivo JSON y validar la estructura del documento:

```powershell
dotnet run --project scripts/extraer-lista-precios-pdf -- "C:\ruta\LISTA DE PRECIOS-13.pdf" "artifacts\lista-precios-13-productos.json"
```

El comando valida la vigencia, los 89 códigos únicos y que cada producto tenga nombre, unidad, contenido y precio de distribuidor. También comprueba los códigos `FB007`, `WT059` y `SC033`, que cubren las tres páginas.
