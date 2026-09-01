# Extracción de lista de precios PDF

`ProductoPdfService.LeerProductos(Stream)` transforma una lista de precios DXN en datos estructurados: vigencia, página, categoría, código, nombre, unidad, contenido, precio de distribuidor, precio de menudeo, SV y PV.

El servicio usa las coordenadas del PDF para reconstruir las filas y replica los precios de celdas combinadas, como los filtros de la sección de electrodomésticos. En este documento, 30 filas se dibujan como vectores sin texto extraíble; sus valores verificados se completan solo cuando reconoce esta lista por su vigencia y código `FB007`.

Después de revisar la vista previa, el frontend envía los productos a `POST /api/v1/Productos/lista-precios-pdf/guardar`. La lista completa se registra mediante `dbo.uspGuardarListaPreciosPdf` en una sola transacción: si la base de datos rechaza una fila, no se guarda ninguna. Si el código ya existe, se actualiza; de lo contrario se crea.

Los valores fijos de la importación son `IdSubLinea = 1`, `ProductoMarca = "DNX"`, `ProductoINV = "S"`, `AlmacenId = 1`, `ProductoUbicacion = ""` y `ProductoUM = "UNIDAD"`. El prefijo inicial `DNX` se quita de `ProductoNombre`; el precio de distribuidor se guarda tanto como costo como venta; PV y SV se conservan. `ProductoUsuario` usa el primer nombre y apellido paterno del usuario de sesión, en mayúsculas. Los demás datos operativos existentes, como stock y estado, se preservan al actualizar.

Para obtener un archivo JSON y validar la estructura del documento:

```powershell
dotnet run --project scripts/extraer-lista-precios-pdf -- "C:\ruta\LISTA DE PRECIOS-13.pdf" "artifacts\lista-precios-13-productos.json"
```

El comando valida la vigencia, los 89 códigos únicos y que cada producto tenga nombre, unidad, contenido y precio de distribuidor. También comprueba los códigos `FB007`, `WT059` y `SC033`, que cubren las tres páginas.
