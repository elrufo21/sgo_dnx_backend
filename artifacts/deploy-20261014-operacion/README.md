# Despliegue DNX — 14/10/2026

## Contenido
- `api/`: publicación Release de ASP.NET Core con la corrección de lectura del número de operación y la respuesta de creación de orden.
- `web/`: frontend Vite de producción.
- `sql/20261014_reparar_parser_uspinsertarNotaBweb.sql`: completa el parser instalado para leer el número de operación; es idempotente y conserva el resto del procedimiento.
- `sql/20261014_configurar_validacion_asistencia_indicador.sql`: configuración del indicador de asistencia, incluida como parte del build vigente.

## Pasos
1. Respaldar el despliegue actual y conservar la carpeta de medios del servidor.
2. En la base de datos que usa la API de producción, ejecutar primero `sql/20261014_reparar_parser_uspinsertarNotaBweb.sql`. El script de asistencia puede ejecutarse si esa base todavía no recibió esa configuración.
3. Copiar el contenido de `api/` a la ruta física del sitio SGO API y el contenido de `web/` a la del sitio SGO Web, siguiendo `docs/despliegue-iis-192.168.1.38.md` del repositorio.
4. Conservar el `appsettings.json` que ya está en el servidor (este paquete lo omite deliberadamente); verificar allí la conexión de producción. No copiar configuración de desarrollo.
5. Reiniciar los sitios o grupos de aplicaciones en IIS.

No se ejecutaron scripts SQL en producción ni se modificó IIS al generar este paquete.
