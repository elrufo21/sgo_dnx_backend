# Despliegue DNX para 192.168.18.47

- Web: http://192.168.18.47:8080
- API: http://192.168.18.47:8081/api/v1
- Paquete API: ASP.NET Core para Windows x64, framework-dependent (.NET 7 Hosting Bundle requerido).
- IIS: sitios SGO Web en puerto 8080 y SGO API en puerto 8081; grupos de aplicaciones sin código administrado.
- Base prevista para esta actualización: DXN_ICA. El paquete no incluye `api/appsettings.json` para evitar reemplazar la conexión y las claves actuales del servidor.
- Medios: `C:\SGO\media`; asignar permiso Modificar al grupo de aplicaciones de SGO API.

La plantilla sin secretos está en `configuration/appsettings.template.json`; no la copies encima del archivo activo del servidor. Conserva la configuración actual al actualizar. Este paquete no ejecuta scripts SQL ni restaura bases de datos.

## SQL incluido para DXN_ICA

La carpeta `sql/` contiene los cuatro parches incrementales del 2026-10-20, compatibles con SQL Server 2008 R2. Revísalos y aplícalos por separado con el responsable de SQL, únicamente si falta cada cambio. `sql/ORDEN_DXN_ICA.txt` explica el orden y el alcance.

El parche de indicadores no borra filas ni cambia `ValorTexto1`, `ValorNum` o `ValorDecimal`: solo normaliza `Area`, `TipoIndicador` e `IdIndicador`. Si detecta duplicados, aborta antes de actualizar. No resuelve ni elimina duplicados automáticamente.

En el servidor instalar IIS, URL Rewrite y el .NET 7 Hosting Bundle. La IP estática de LAN usada en este paquete es 192.168.18.47. La regla de firewall debe limitar los puertos de la aplicación a la subred local.

La extensión se publica aparte desde `extension/`. Para impresión local, instalar el agente en cada estación que imprime y agregar `http://192.168.18.47:8080` a `allowedOrigins` de su `agent.config.json`; el token debe coincidir con el incluido en la web.
