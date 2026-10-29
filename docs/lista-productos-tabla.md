# Selección de productos en tabla para captura HTML

## Alcance solicitado

Permitir elegir desde `dbo.Indicador` cómo se seleccionan los productos en `/sales/html_capture/new`. El flag cambia la presentación y selección: no es un procedimiento almacenado ni cambia la fuente SQL, los precios o el catálogo de otro módulo.

El usuario confirmó que la vista anterior debe conservarse tal como estaba: los ajustes del nuevo catálogo se aplican exclusivamente con `ListaProductosTabla = 1`. Con valor 0 o indicador ausente se mantienen el autocomplete, el botón Agregar y la tabla de detalle anterior. No extender cambios de diseño o selección del nuevo catálogo a ese modo.

## Indicador preparado

- Clave por compañía: `CompaniaId`, `Area = 'VENTAS'`, `TipoIndicador = 1`, `IdIndicador IS NULL`, `Descripcion = 'ListaProductosTabla'`.
- `ValorNum = 0`: autocomplete y botón Agregar actuales.
- `ValorNum = 1`: vistas Productos y Detalle sincronizadas, sin pestañas visibles.
- La identidad numérica `Id` no participa en la selección.
- Script: [20261022_configurar_lista_productos_tabla.sql](../scripts/sql/20261022_configurar_lista_productos_tabla.sql). Inserta únicamente los flags que faltan, inicialmente en 0, conserva los valores existentes y detiene la operación si encuentra duplicados o metadatos incompatibles.

## Comportamiento

- Productos utiliza el componente compartido DataTable, con búsqueda por código/nombre, paginación y columnas Código, Descripción, Cantidad, Precio, Stock y PV. No se limita a las 20 sugerencias del autocomplete. El stock en cero se destaca, conservando las reglas existentes de venta.
- Las pestañas no se muestran. Al entrar a una venta manual se abre Productos con todo el catálogo disponible, paginado; el catálogo se carga desde la API aunque ya exista en memoria. La búsqueda permanece visible tanto en Productos como en Detalle.
- Escribir una búsqueda no vacía cambia a Productos y muestra las coincidencias por código/nombre, con las mismas reglas del filtro de DataTable. Una búsqueda parcial puede devolver varias coincidencias. Una búsqueda vacía muestra todo el catálogo disponible y una búsqueda sin coincidencias muestra un mensaje específico.
- Escape cambia a Detalle, limpia la búsqueda y devuelve el foco al buscador para buscar otro producto. Al borrar todo el texto del buscador también vuelve a Detalle y conserva el foco. Escape funciona desde el buscador, las cantidades o los demás campos de la pantalla; no interfiere con diálogos abiertos. Al pulsar Shift sin combinarlo con otra tecla desde un campo editable de Productos o Detalle, el foco vuelve al buscador y se conserva el texto. En otras secciones, Shift+Tab y escribir mayúsculas mantienen su comportamiento normal.
- Con coincidencias, Enter o flecha abajo desde el buscador enfoca la cantidad de la primera coincidencia visible. Con el buscador vacío en Detalle, enfoca la primera cantidad del detalle. Si no hay coincidencias o filas, el foco permanece en el buscador.
- La cantidad de cada producto es absoluta: escribir 3 deja tres unidades, no agrega tres adicionales. Desde el 26/10/2026 solo se admiten enteros al escribir o pegar en Productos y Detalle; el guardado rechaza cantidades fraccionarias de borradores o capturas anteriores sin redondearlas. Los precios conservan sus decimales. Poner 0 o vaciar una cantidad en Productos quita esa fila del detalle.
- Productos y Detalle usan las mismas filas de venta. Cambiar cantidades o quitar un producto desde Detalle actualiza su cantidad en Productos. Desde el 28/10/2026, vaciar o poner cero en Detalle conserva la fila al salir del campo para permitir reescribir la cantidad; se elimina explícitamente con **Quitar** (papelera). El guardado sigue exigiendo enteros positivos. En el catálogo Productos, cero o vacío siguen quitando la selección. Cambiar de vista, buscar o paginar no descarta selecciones.
- El primer producto conserva la pregunta de motivo de venta sin OBS. Aceptar aplica la cantidad indicada; Ignorar no agrega el producto.
- El precio del producto se muestra en Detalle sin permitir editarlo; cantidades, totales, borrador y guardado siguen usando las filas de venta existentes y los datos PV/SV.
- Ventas capturadas de OBS y ventas ya registradas conservan su bloqueo de edición. Se abre Detalle automáticamente para consultar esos documentos.
- Nuevo registro y Limpiar vacían las selecciones; no hay un carrito paralelo al detalle.

## Lectura del indicador

`CompaniaRepository` devuelve `ListaProductosTabla` en `GET /api/v1/Compania/list`, leyéndolo por compañía, área, tipo, descripción y raíz. El store de configuración consume esa propiedad. La ausencia del indicador equivale a 0 y conserva el autocomplete. No se usa el Id físico ni se modifica el indicador al editar una compañía.

El valor se administra en **Configuración > Ventas y boletas > Lista de productos en captura HTML**. El frontend consulta el estado de la compañía y guarda el cambio mediante `PATCH /api/v1/Compania/{id}/lista-productos-tabla`; el backend actualiza o crea únicamente la raíz `VENTAS/ListaProductosTabla` de esa compañía. No requiere cambios de esquema ni un script SQL. El nuevo modo se aplica al volver a abrir la captura de venta.

Con el modo tabla activo se vuelve a consultar el catálogo al entrar al registro de venta; no se reutiliza indefinidamente una lista cargada antes de agregar nuevos códigos. La fuente sigue siendo `GET /api/v1/Productos/list` y sus reglas de estado actuales. Este cambio no garantiza mostrar un producto que la API o el procedimiento instalado en COMAS no devuelvan; ese caso requiere revisar el catálogo del servidor.

El buscador compartido `SearchInput` se extrajo del control existente de DataTable conservando su presentación y callbacks. La captura lo mantiene fuera de las dos vistas para que siga disponible al pulsar Escape; el catálogo filtra mediante un índice local y DataTable conserva la paginación. La navegación se aplica solo con el flag activo. La recarga depende de la entrada de ruta, no de cada tecla ni de cada edición de cantidad.

## Rendimiento de búsqueda

- `SaleProductBrowser` mantiene el texto de búsqueda localmente: escribir no actualiza el estado del formulario de venta/pago. El formulario solo cambia de vista cuando se vuelve de Detalle a Productos; las cantidades siguen en el detalle compartido.
- `productCatalogSearch.ts` prepara una vez por carga del catálogo el texto normalizado de código y nombre. Cada búsqueda compara términos contra ese índice, conservando mayúsculas/minúsculas indiferentes, acentos, separadores y coincidencias de varios términos en cualquier orden. Se mantienen los productos activos y la búsqueda vacía muestra todos los disponibles.
- `SaleProductCatalog` usa `useDeferredValue` y resultados memoizados para dar prioridad a la escritura mientras actualiza la tabla. No hay un retraso fijo por temporizador ni nuevas peticiones por tecla. DataTable recibe las coincidencias con `manualFiltering` para no filtrarlas por segunda vez.
- El contexto de cantidades permanece estable al escribir y los resultados memoizados se reutilizan durante la actualización urgente del buscador. Si una búsqueda coincide con todo el catálogo, también se conserva la referencia de datos para reutilizar el modelo de filas de DataTable. Las ediciones de cantidad sí actualizan los controles del catálogo y el detalle.
- El autocomplete anterior no calcula sugerencias mientras el flag está activo. Con flag 0 se mantiene su comportamiento previo. Limpiar/Nuevo registro reinician la búsqueda local; Escape limpia el texto sin reabrir Productos por una actualización diferida.

Verificación: `node --experimental-strip-types scripts/verify-product-catalog-search.mjs` comprueba equivalencia con el filtro anterior, catálogo completo, acentos, términos múltiples, códigos nuevos, inactivos e índice reutilizado. En la ejecución local con 10.000 productos y 30 búsquedas, el filtrado anterior tomó 258.0 ms y el indexado 7.0 ms; es una medición del filtro en Node, excluye renderizado, red y carga inicial y no garantiza la misma latencia en otras computadoras.

La prueba de navegador usó la pantalla real con 10.000 productos simulados: escritura continua hasta un código exacto, motivo OBS, selección de dos productos, Escape, precio existente conservado al cambiar cantidades (total 1.184,00), paginación, búsqueda desde página 2 y Limpiar con catálogo completo. Las búsquedas y cantidades mantuvieron una sola carga del catálogo. No se guardaron ventas ni se utilizó SQL o impresión. El build Vite y las pruebas de búsqueda/cantidades pasaron; TypeScript conserva los cinco errores existentes en la página y no reportó errores en los nuevos componentes o helper.

## Instalación y activación

Actualizar backend y frontend juntos. El script de inicialización se puede usar para crear el indicador en 0 para las compañías que aún no lo tengan, conservando los valores existentes. También se crea automáticamente si se guarda desde **Configuración > Ventas y boletas**: activado guarda `ValorNum = 1` y desactivado guarda `ValorNum = 0`. Reabrir la captura para aplicar la selección. No se debe ejecutar manualmente el script local de activación en servidores.

El 22/10/2026, por solicitud expresa del usuario para visualizar la funcionalidad, se cambió de 0 a 1 el indicador existente de la compañía 1 (LINO ESPIRITU WILDER) en la base local `localhost\SQLEXPRESS01 / DXNCOMAS2210`. Se verificó el valor 1 tras ejecutar [20261022_activar_lista_productos_tabla_local.sql](../scripts/sql/20261022_activar_lista_productos_tabla_local.sql). Esta activación no corresponde a un despliegue en el servidor remoto de COMAS.

## Comprobación local

`node --experimental-strip-types scripts/verify-sale-product-quantities.mjs` en el frontend comprueba selección, cantidades enteras absolutas, rechazo de decimales y valores inválidos, eliminación, conservación del precio existente al cambiar cantidades y totales, sin consultar SQL ni guardar ventas.

La prueba de navegador utilizó 105 productos simulados y la pantalla real de captura con las peticiones interceptadas por una fixture local. Se comprobaron flag activo, desactivado y ausente; motivo OBS aceptado/cancelado; edición continua sin perder foco; Enter a la siguiente cantidad; sincronización con Detalle; búsqueda, paginación, decimales, eliminación y Limpiar. No se guardaron ventas, no se imprimió y no se accedió a SQL. La fixture temporal y su servidor se retiraron al terminar. Captura de referencia: `artifacts/lista-productos-tabla-20261022.png`.

La compilación Vite y el backend .NET 7 terminaron correctamente, con sus advertencias existentes. El chequeo global de TypeScript sigue fallando por errores del proyecto; al comparar los archivos modificados con HEAD se obtuvieron cinco diagnósticos previos y cinco actuales, sin diagnósticos nuevos, y los dos archivos de código agregados no presentaron errores de tipo.

### Ajuste de navegación del 22/10/2026

Se probó la pantalla real con 105 productos simulados y un contador de consultas: entrada con catálogo previamente cargado, búsqueda de un código, cantidad 2 con motivo OBS, Escape desde cantidad, segunda búsqueda con cantidad 3 y detalle compartido con total 840.00. Salir y volver produjo una nueva consulta; buscar y editar cantidades no consultaron nuevamente la API. Se comprobó búsqueda inexistente y el autocomplete anterior con flag 0. No se guardaron ventas ni se utilizó SQL o impresión. La fixture temporal se eliminó al finalizar las pruebas. La solicitud posterior del mismo día reemplaza el inicio vacío por el listado completo del catálogo disponible, manteniendo el filtro y la navegación con Escape.
