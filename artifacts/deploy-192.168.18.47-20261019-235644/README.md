# Despliegue DNX para 192.168.18.47

- Web: http://192.168.18.47:8080
- API: http://192.168.18.47:8081/api/v1
- Paquete API: ASP.NET Core para Windows x64, framework-dependent (.NET 10 Hosting Bundle requerido).
- IIS: sitios SGO Web en puerto 8080 y SGO API en puerto 8081; grupos de aplicaciones sin código administrado.
- Base prevista: DXNCOMAS. Completar pi/appsettings.json con la cadena de conexión y credenciales autorizadas antes de iniciar IIS.
- Medios: C:\SGO\media; asignar permiso Modificar al grupo de aplicaciones de SGO API.

El ppsettings.json incluido es una plantilla sin secretos. No iniciar el sitio hasta completar la conexión SQL, claves JWT, correo y demás credenciales necesarias. Este paquete no ejecuta scripts SQL ni restaura bases de datos.

En el servidor instalar IIS, URL Rewrite y el .NET 10 Hosting Bundle. La IP estática de LAN usada en este paquete es 192.168.18.47. La regla de firewall debe limitar los puertos de la aplicación a la subred local.

La extensión se publica aparte desde xtension/. Para impresión local, instalar el agente en cada estación que imprime y agregar $webOrigin a llowedOrigins de su gent.config.json; el token debe coincidir con el incluido en la web.
