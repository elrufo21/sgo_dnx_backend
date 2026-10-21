# Despliegue DNX para 192.168.18.47

- Web: http://192.168.18.47:8080
- API: http://192.168.18.47:8081/api/v1
- Paquete API: ASP.NET Core para Windows x64, framework-dependent (.NET 7 Hosting Bundle requerido).
- IIS: sitios SGO Web en puerto 8080 y SGO API en puerto 8081; grupos de aplicaciones sin código administrado.
- Base prevista: DXNCOMAS. Completar pi/appsettings.json con la cadena de conexión y credenciales autorizadas antes de iniciar IIS.
- Medios: D:\SGO\media; asignar permiso Modificar al grupo de aplicaciones de SGO API.

El ppsettings.json incluido es una plantilla sin secretos. No iniciar el sitio hasta completar la conexión SQL, claves JWT, correo y demás credenciales necesarias. Este paquete no ejecuta scripts SQL ni restaura bases de datos.

En el servidor instalar IIS, URL Rewrite y el .NET 7 Hosting Bundle. Verificar que SERVER-NEW resuelva desde los equipos cliente; si se usará una IP o dominio distinto, reconstruir con -ServerName usando el host visible por el navegador.

La extensión se publica aparte desde xtension/. Para impresión local, instalar el agente en cada estación que imprime y agregar $webOrigin a llowedOrigins de su gent.config.json; el token debe coincidir con el incluido en la web.
