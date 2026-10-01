# Publicacion SUNAT/SIRE — 30/09/2026

Paquete para actualizar el API y la web DNX. No contiene credenciales ni archivos `appsettings*.json`; se deben conservar la configuracion y la cadena de conexion ya instaladas en el servidor.

## Contenido

- `api/`: salida de `dotnet publish` Release para Windows x64.
- `web/`: salida Vite de produccion, servida en IIS.
- `sql/20260930_verificar_indicadores_sunat.sql`: verificacion de solo lectura de los seis indicadores SUNAT por RUC.

## SQL

No se requiere migracion DDL ni carga SQL para SUNAT/SIRE. La tabla `dbo.Indicador` ya existe; al guardar desde **Configuracion → Credenciales SUNAT**, el API crea o actualiza las filas para la compania autenticada. El script del paquete solo verifica que las seis filas esten configuradas y no muestra sus valores. Reemplazar `REEMPLAZAR_RUC` antes de ejecutarlo en la base objetivo.

## Despliegue IIS

1. Respaldar las carpetas actuales del API y de la web.
2. Detener los sitios o application pools correspondientes.
3. Copiar `api/` sobre la carpeta publicada del API, preservando `appsettings.json` y cualquier `appsettings.Production.json` del servidor. El paquete los omite para evitar reemplazar configuracion local o secretos.
4. Copiar `web/` sobre la raiz del sitio web.
5. Iniciar los sitios y probar inicio de sesion, **Configuracion → Credenciales SUNAT**, SIRE ventas y SIRE compras.
6. Guardar las credenciales de produccion desde la interfaz web; no usar un script SQL con secretos.

## Construccion y validacion

- API: `dotnet publish src/Api/Ecommerce.Api.csproj -c Release -r win-x64 --self-contained false`.
- Web: `npm run build:vercel`, el comando Vite de produccion configurado en `vercel.json`.
- `npm run build` ejecuta TypeScript antes de Vite, pero actualmente falla por errores preexistentes en otros modulos del frontend; por eso este paquete usa el build Vite que ya declara el proyecto para produccion.

El servidor IIS debe conservar su configuracion de produccion, incluido `ConnectionStrings:DefaultConnection`, y contar con el hosting/runtime .NET requerido por el API.
