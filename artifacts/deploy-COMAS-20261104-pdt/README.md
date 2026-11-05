# Despliegue DNX para 192.168.18.47

- Web: http://192.168.18.47:8080
- API: http://192.168.18.47:8081/api/v1
- Paquete API: ASP.NET Core para Windows x64, framework-dependent (.NET 7 Hosting Bundle requerido).
- IIS: sitios SGO Web en puerto 8080 y SGO API en puerto 8081; grupos de aplicaciones sin código administrado.
- Base prevista: DXNCOMAS. Conservar `api/appsettings.json` del servidor con su conexión y credenciales actuales.
- Medios: `C:\SGO\media`; asignar permiso Modificar al grupo de aplicaciones de SGO API.

El paquete no contiene `api/appsettings.json`: no reemplaza conexión, claves ni credenciales existentes. `configuration/appsettings.template.json` es solo una plantilla sin secretos para instalaciones nuevas; completarla antes de iniciar IIS. Conservar también las carpetas `media` y `keys` del servidor. Este paquete no ejecuta scripts SQL ni restaura bases de datos.

Antes de publicar esta API, el responsable SQL debe aplicar en la base destino los archivos 01, 02 y 03 de `sql/20261020_optimizacion_listados/`, en ese orden. La carpeta incluye instrucciones y reversión; el archivo 04 es solo para revertir y no debe ejecutarse durante la actualización.

Para que el listado Nota Pedido muestre ConceptoOBS, el responsable SQL debe revisar y aplicar `sql/20261026_listaNotaPedido_web.sql` en DXNCOMAS antes de publicar esta API. El script crea o actualiza únicamente `dbo.listaNotaPedidoWEB`; conserva `dbo.listaNotaPedido` para el aplicativo de escritorio. Este paquete solo entrega el SQL, no lo ejecuta.

En el servidor instalar IIS, URL Rewrite y el .NET 7 Hosting Bundle. La IP estática de LAN usada en este paquete es 192.168.18.47. La regla de firewall debe limitar los puertos de la aplicación a la subred local.

La extensión se publica aparte desde `extension/`. Para impresión local, instalar el agente en cada estación que imprime y agregar `http://192.168.18.47:8080` a `allowedOrigins` de su `agent.config.json`; el token debe coincidir con el incluido en la web.

IMPORTANTE: revisar sql/20261104/LEEME.txt y sql/dependencias-20261102/LEEME.txt antes de publicar. Almacén permanece oculto en producción. Los SQL se entregan para el responsable y no se ejecutaron.
