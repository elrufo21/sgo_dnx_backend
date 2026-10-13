# Despliegue IIS: 192.168.1.38

## Puertos definidos

- Web: `http://192.168.1.38:8080`.
- API: `http://192.168.1.38:8081`.

El frontend de producción usa `http://192.168.1.38:8081/api/v1/`. El API permite peticiones desde `http://192.168.1.38:8080` y, para pruebas locales en el servidor, desde `http://localhost:8080`.

## IIS

1. Instalar el **.NET 7 Hosting Bundle** en el servidor.
2. Crear el sitio **SGO API** con ruta física `api`, binding HTTP en el puerto 8081 y grupo de aplicaciones **Sin código administrado**. El `web.config` publicado inicia `Ecommerce.Api.dll` mediante el módulo de ASP.NET Core.
3. Crear el sitio **SGO Web** con ruta física `web`, binding HTTP en el puerto 8080 y grupo de aplicaciones **Sin código administrado**.
4. El `api/appsettings.json` publicado usa autenticación SQL local. Verificar que la base `DXN_ICA` esté restaurada en la instancia predeterminada de SQL Server antes de iniciar el sitio.
5. Crear o conservar `D:\SGO\media` y otorgar permiso **Modificar** a la identidad del Application Pool de **SGO API**. La API publica esa carpeta como `http://192.168.1.38:8081/media/...`; incluirla en el respaldo del servidor.

El sitio web incluye `web.config` para redirigir las rutas de React a `index.html`. Requiere tener instalado IIS URL Rewrite.

## Extensión y agente de impresión

- Instalar la extensión desde la carpeta `extension` con **Cargar descomprimida** en Chrome o Edge. Está enlazada a `http://192.168.1.38:8080`.
- El agente debe instalarse en cada PC donde se abra DNX y se imprima. Si el propio servidor también es una estación de impresión, puede instalarse allí como servicio de Windows; escucha solo en `127.0.0.1:5174` y no como servicio de red.
- Para instalarlo como servicio, instalar Node.js 20 o superior para todo el equipo, ejecutar `npm ci` en `print-agent`, configurar `agent.config.json` y ejecutar `install-service.ps1` desde PowerShell como administrador.
- Si el servidor no imprime desde una sesión de navegador local, no necesita el agente. Para retirar una instalación anterior, seguir `dnx-print-agent/docs/servicio-windows-y-desinstalacion.md` y ejecutar `uninstall-agent.ps1` en la carpeta del agente del servidor.
