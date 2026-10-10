# API para corregir demora en listado de Caja

Este paquete actualiza solo la API publicada para Windows x64 (.NET 7). Conserva la fórmula de diferencia de cajas cerradas y agrupa monedas, OBS/IOC y movimientos manuales por caja en una consulta, evitando repetir sumas correlacionadas para cada registro.

## Despliegue en IIS

1. Respaldar la carpeta actual de la API.
2. Detener su sitio o Application Pool.
3. Copiar el contenido de `api/` a la raíz física del sitio de la API, reemplazando los archivos existentes.
4. Conservar los `appsettings*.json` y variables de entorno que ya están configurados en el servidor; este paquete no los incluye.
5. Iniciar el Application Pool y revisar el listado de Control de flujo de caja.

No requiere ejecutar scripts SQL ni desplegar nuevamente la web.

## Alcance y limitación

La consulta ya no ejecuta agregaciones correlacionadas por cada caja. El cambio se compiló en Release, pero no se midió contra la base de producción; confirmar su tiempo de respuesta tras el despliegue.
