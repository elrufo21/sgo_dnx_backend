# Build de producción — 2026-10-14

- `api/`: publicación Release de ASP.NET Core.
- `web/`: build de producción de React/Vite para IIS.
- `sql/20261014_reparar_parser_uspinsertarNotaBweb.sql`: completa el parser de pagos de `uspinsertarNotaBweb` sin reemplazar el procedimiento instalado.
- `sql/20261014_configurar_validacion_asistencia_indicador.sql`: configura el indicador de asistencia.

## Despliegue

Desplegar `api/` y `web/` según `sgo_dnx_backend/docs/despliegue-iis-192.168.1.38.md`.
Ejecutar los scripts SQL en la base que usa la API. El script del parser conserva el resto del procedimiento y es idempotente; el script del indicador se puede volver a ejecutar para conservar/configurar la validación de asistencia. El build no ejecuta scripts SQL.

Antes de desplegar `api/`, configurar su `appsettings.json` con la cadena de conexión del servidor de producción. La configuración del paquete se tomó del workspace actual.
