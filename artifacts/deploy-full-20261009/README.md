# Paquete completo de producción — 09/10/2026

Destino: IIS Windows x64, web `http://192.168.1.38:8080`, API `http://192.168.1.38:8081`.

## Contenido

- `web/`: build Vite con configuración de producción y `web.config` para IIS.
- `api/`: publicación Release de la API para Windows x64, dependiente del runtime .NET 7.
- `extension/`: extensión Chrome/Edge de producción.
- `print-agent/`: agente local de impresión y archivos de instalación para Windows.
- `sql/`: scripts SQL existentes del repositorio. Este paquete no modifica procedimientos ni requiere ejecutar SQL para la validación de asistencia de Caja.

## Despliegue

1. Respaldar los directorios actuales y detener los sitios o Application Pools de web y API en IIS.
2. Copiar el contenido de `api/` a la carpeta publicada de la API, **omitiendo `appsettings*.json`** para conservar la configuración y credenciales del servidor.
3. Copiar el contenido de `web/` a la raíz del sitio web.
4. Iniciar API y web; comprobar inicio de sesión y operaciones de Caja.
5. Recargar `extension/` desde `chrome://extensions` o `edge://extensions` si se requiere actualizarla.
6. Para actualizar el agente, copiar `print-agent/` a cada estación configurada y seguir su `README.md`.

## Construcción y alcance

- API: `dotnet publish src/Api/Ecommerce.Api.csproj -c Release -r win-x64 --self-contained false` (completado).
- Web: `npm run build:vercel` (Vite, completado).
- `npm run build` del frontend se intentó, pero se detuvo en `tsc -b` por errores de TypeScript. `build:vercel` genera el sitio sin ejecutar ese chequeo.
- Extensión y agente no tienen un paso de compilación; se empaquetan desde sus fuentes actuales. Se excluyeron logs de ejecución y `node_modules` del agente.
