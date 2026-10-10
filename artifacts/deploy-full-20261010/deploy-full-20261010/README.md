# Paquete completo de producción — 10/10/2026

Destino: IIS Windows x64, web `http://192.168.1.38:8080`, API `http://192.168.1.38:8081`.

## Contenido

- `web/`: build Vite con configuración de producción y `web.config` para IIS.
- `api/`: publicación Release de la API para Windows x64, dependiente del runtime .NET 7. No incluye `appsettings*.json` para conservar la configuración del servidor.
- `extension/`: extensión Chrome/Edge de producción, sin metadatos `.git`.
- `print-agent/`: agente local de impresión y archivos de instalación para Windows; se excluyeron dependencias instaladas y logs.
- `sql/`: scripts SQL del paquete previo. Esta corrección no modifica procedimientos ni requiere ejecutar SQL.

## Cambio incluido

El listado de cajas cerradas calcula la diferencia con conteo de monedas, monto inicial, OBS, IOC, salidas e ingresos manuales, igual que el detalle. Esto mantiene compatibilidad con registros creados por escritorio, que guarda otros conceptos en `CajaIngresos` y `CajaTotal`.

## Despliegue

1. Respaldar los directorios actuales y detener los sitios o Application Pools de web y API en IIS.
2. Copiar el contenido de `api/` a la carpeta publicada de la API, conservando los `appsettings*.json` ya configurados en el servidor.
3. Copiar el contenido de `web/` a la raíz del sitio web.
4. Iniciar API y web; validar listado y detalle de Control de flujo de caja.
5. Recargar `extension/` desde `chrome://extensions` o `edge://extensions` si se requiere actualizarla.
6. Para el agente, copiar `print-agent/` a cada estación configurada y seguir su `README.md`.

## Construcción

- API: `dotnet publish src/Api/Ecommerce.Api.csproj -c Release -r win-x64 --self-contained false`.
- Web: `npm run build:vercel` con `.env.production` (`VITE_API_BASE_URL=http://192.168.1.38:8081/api/v1/`).
- Extensión y agente: empaquetados desde sus fuentes; no requieren compilación.