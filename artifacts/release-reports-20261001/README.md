# Paquete de producción: reportes — 01/10/2026

## Contenido

- `api/`: publicación Release para Windows x64, framework-dependent (.NET 7).
- `web/`: build Vite de producción para IIS.

## Despliegue

1. Respaldar y detener los sitios IIS de API y web.
2. Copiar `api/` sobre la carpeta publicada de la API, conservando el `appsettings.json` y `appsettings.Production.json` del servidor.
3. Copiar `web/` sobre la raíz del sitio web.
4. Iniciar los sitios y verificar inicio de sesión, reporte anual y reporte por productos.

El paquete omite `appsettings*.json` para no reemplazar la conexión ni secretos del servidor. No requiere cambios SQL.

## Construcción

- API: `dotnet publish src/Api/Ecommerce.Api.csproj -c Release -r win-x64 --self-contained false`.
- Web: `npm run build:vercel` (Vite). `npm run build` se intentó, pero el chequeo TypeScript falla en varios módulos ajenos a reportes.
