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

El sitio web incluye `web.config` para redirigir las rutas de React a `index.html`. Requiere tener instalado IIS URL Rewrite.

## Extensión y agente de impresión

- Instalar la extensión desde la carpeta `extension` con **Cargar descomprimida** en Chrome o Edge. Está enlazada a `http://192.168.1.38:8080`.
- Instalar Node.js 20 o superior y ejecutar `npm ci` dentro de `print-agent`.
- Crear una tarea de inicio de sesión que ejecute `run-agent-service.cmd`. El agente usa `127.0.0.1:5174`, por lo que va en cada PC que imprima, no como servicio de red.
