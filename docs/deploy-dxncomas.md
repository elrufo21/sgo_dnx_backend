# Contexto persistente: deploy-dxncomas

Leer este archivo antes de continuar cualquier trabajo de despliegue para DXNCOMAS. Describe el estado confirmado y las restricciones acordadas con el usuario; actualizarlo cuando cambien.

## Dos casos de despliegue: mantener separados

| Caso | Base de datos | Servidor / IP | Frontend | API |
|---|---|---|---|---|
| DXN_ICA | `DXN_ICA` | `192.168.1.38` | `http://192.168.1.38:8080/login` | `http://192.168.1.38:8081/api/v1` |
| DXNCOMAS | `DXNCOMAS` | `SERVER-NEW`, `192.168.18.47` | `http://192.168.18.47:8080` | `http://192.168.18.47:8081/api/v1` |

Estas son instalaciones distintas. No reutilizar entre ellas el ZIP, IP, CORS, `appsettings.json`, conexión de base de datos ni credenciales del otro caso. Para DXN_ICA, el ZIP corregido del 2026-10-20 es `artifacts/deploy-DXN_ICA-192.168.1.38-20261020-210610-final.zip`. El ZIP generado con `192.168.18.47` para DXN_ICA está supersedido y no debe usarse. Para DXNCOMAS, el contexto del servidor y sus pasos pendientes están documentados abajo; no hay que asumir que el paquete de DXN_ICA sirve para esa máquina.
## Servidor y alcance de DXNCOMAS

- Servidor destino: `SERVER-NEW`, Windows Server 2022 Standard, x64.
- Servirá el sistema a las PCs de la LAN; no se planeó exposición a Internet.
- IP manual: `192.168.18.47/24`; gateway `192.168.18.1`.
- Rutas del despliegue: web `C:\SGO\web`, API `C:\SGO\api`, medios `C:\SGO\media`.
- IIS está instalado y `W3SVC` está activo. También se instaló IIS URL Rewrite.
- Sitio `SGO Web`: binding `http 192.168.18.47:8080`, ruta `C:\SGO\web`.
- Sitio `SGO API`: binding `http 192.168.18.47:8081`, ruta `C:\SGO\api`.
- Los sitios y grupos de aplicaciones se crearon. Para probar la web usar `http://192.168.18.47:8080`; `localhost:8080` devuelve `400 Invalid Hostname` porque el binding es específico a la IP.
- El Hosting Bundle ASP.NET Core `7.0.20` x64 ya se instaló. Se confirmó el runtime en `C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App\7.0.20` y `W3SVC` quedó iniciado.

## Versiones: conservar sin cambios

- El backend original usa `net7.0` y `global.json` fija SDK `7.0.410`.
- No actualizar framework, SDK ni paquetes como parte de este despliegue sin que el usuario lo solicite expresamente. Un intento previo cambió a .NET 10 sin autorización; los `.csproj` y `global.json` fueron restaurados a .NET 7.
- No usar los paquetes `deploy-192.168.18.47-20261019-235644.zip` ni `deploy-192.168.18.47-20261019-235819.zip`: se generaron con `net10.0`.
- Paquete histórico generado con `net7.0`: `artifacts/deploy-192.168.18.47-20261020-000405.zip`. Fue copiado y extraído bajo `C:\SGO`; para una actualización completa usar el paquete limpio más reciente documentado abajo.
- Ese ZIP se creó antes de corregir el `LocalMedia:RootPath`; su `api/appsettings.json` podría volver a poner `D:\SGO\media` si se extrae otra vez. No volver a extraerlo encima del despliegue actual. El generador y la plantilla locales ya se corrigieron; regenerar un paquete antes de un redeploy completo.
- .NET 7 ya no tiene soporte de Microsoft. Registrar este riesgo y mantenerlo visible, pero no actualizar la versión sin autorización; cualquier migración futura debe ser un trabajo separado y probado.

## Estaciones cliente de DXNCOMAS: extensión y agente

- Después de desplegar la actualización completa, usar `extension/` y `print-agent/` del paquete COMAS más reciente indicado abajo. El paquete anterior sigue en `C:\SGO` hasta que se actualice; no mezclar sus archivos con los del build nuevo. No usar las carpetas del paquete DXN_ICA: son destinos distintos.
- Instalar la extensión de producción en cada navegador Brave/Chrome que use DXN: abrir `brave://extensions` o `chrome://extensions`, activar modo desarrollador, elegir **Cargar descomprimida** y seleccionar la carpeta `extension` con `manifest.json`. El manifest incluye el origen de COMAS `http://192.168.18.47:8080`.
- Instalar `print-agent/` en cada PC que tenga impresora. Requiere Node.js 20 o superior; ejecutar `npm.cmd ci` dentro de la carpeta y luego `powershell -ExecutionPolicy Bypass -File .\install-service.ps1` desde PowerShell como administrador. `npm.cmd` evita el bloqueo de `npm.ps1` por la política de scripts de PowerShell. La configuración ya preparada contiene el origen COMAS y el token que debe corresponder al frontend; conservarla sin publicar el token.
- Comprobar en cada PC con `Invoke-WebRequest http://127.0.0.1:5174/health`. El agente es local a cada estación y debe estar activo en la PC desde la cual se imprime. Si el servicio no ve una impresora instalada solo para el usuario, configurar el servicio para iniciar con una cuenta que tenga acceso a esa impresora.
- De este ZIP tomar únicamente las carpetas del agente y la extensión para las estaciones. Su configuración de API no es un paquete de actualización seguro para volver a extraer completo sobre el servidor.
## SQL: no tocar

- El usuario indicó expresamente que otra persona se encarga de SQL y que por ahora no se toque.
- SQL Server instalado: instancia predeterminada `MSSQLSERVER`, SQL Server 2008 R2 Standard (versión observada `10.50.1600.1`). La base `DXNCOMAS` estaba `ONLINE`, compatibilidad `100`.
- No restaurar bases, cambiar configuración/servicios/compatibilidad, ejecutar scripts, migraciones, ni hacer pruebas de escritura. Para configurar la aplicación, pedir al responsable SQL los datos y permisos autorizados; eso no autoriza modificar la base.
- Excepción puntual autorizada el 2026-10-20: en la instancia local `DESKTOP-B6B71UA\SQLEXPRESS01`, base `DXNCOMASWEB`, se procesaron los cuatro scripts incrementales entregados: se actualizaron los procedimientos `dbo.usp_Maquina` y `dbo.uspListaDocumentosWEB`; el parche de impresoras no encontró índice/restricción que quitar; la normalización de indicadores abortó en su prevalidación por duplicados. No se ejecutaron en `SERVER-NEW` ni en `DXNCOMAS`.
- Antes de los cambios se guardaron las definiciones anteriores en `artifacts/entregas/rollback_DXNCOMASWEB_20261020/`. La verificación posterior confirmó que `usp_Maquina` admite series repetidas y mantiene único el nombre de máquina; `uspListaDocumentosWEB` excluye las boletas del día actual y conserva la columna ICBPER.
- Se intentó `20261020_normalizar_indicadores_configuracion.sql`, pero la validación previa abortó antes de modificar filas al detectar 11 descripciones duplicadas para `CompaniaId = 1`. Revisar y resolver esos duplicados antes de volver a normalizar. También se ejecutó `20261020_maquinas_permitir_impresora_repetida.sql`; no encontró una restricción ni índice único sobre `Tiketera`, por lo que no hizo cambios.
- La captura de SSMS muestra SQL Authentication con el login `sa`; no recomendar `sa` para la aplicación. Solicitar una cuenta de aplicación con permisos necesarios.

## Build completo de actualización DXNCOMAS — 2026-10-20

- Paquete: `artifacts/deploy-DXNCOMAS-192.168.18.47-20261020-223558-final.zip`.
- Incluye frontend, API .NET 7 para Windows x64, extensión y agente, más los cuatro parches SQL incrementales del 2026-10-20.
- El frontend, la API, CORS, la extensión y `agent.config.json` se verificaron con el destino COMAS `192.168.18.47`; extensión y agente no conservan orígenes de DXN_ICA.
- El ZIP no incluye `api/appsettings.json`; mantiene separada `configuration/appsettings.template.json` para no sobrescribir la cadena de conexión ni secretos del servidor.
- Compilación Vite y publicación .NET 7 exitosas; se mantiene una advertencia de bundle grande en frontend y advertencias preexistentes del backend.
- Los SQL se incluyen solo para el DBA. Ninguno se ejecutó y no se hizo despliegue al servidor.
- El normalizador de indicadores conserva filas y valores (`ValorTexto1`, `ValorNum`, `ValorDecimal`); actualiza metadatos y aborta sin cambios si encuentra duplicados o relaciones inválidas. Verificar DXNCOMAS por separado antes de ejecutarlo.
- SHA-256: `0138EA34A61DB258FE890A58100F010940BB0DF697BCB702EE8057E6B361EA19`.
- El build incluye un token compartido para el agente. Tratar el ZIP como confidencial y mantener juntos el agente y el frontend del mismo build.
## Paquete de actualización DXN_ICA — 2026-10-20

- El servidor DXN_ICA indicado por el usuario es `192.168.1.38`: frontend `http://192.168.1.38:8080/login`, API `http://192.168.1.38:8081/api/v1`.
- El primer ZIP se generó por error con `192.168.18.47` (la IP de `SERVER-NEW`) y queda **supersedido; no usarlo para DXN_ICA**.
- Paquete corregido: `artifacts/deploy-DXN_ICA-192.168.1.38-20261020-210610-final.zip`.
- Compilación verificada: frontend Vite exitoso; API publicada como ASP.NET Core Windows x64 framework-dependent, .NET 7; el runtimeconfig confirma .NET 7. El frontend conserva una advertencia de tamaño del bundle y la API presenta advertencias preexistentes, sin errores de compilación.
- El ZIP incluye frontend, API, extensión, agente de impresión y los cuatro scripts SQL incrementales del 2026-10-20. No contiene `.git`, carpetas `tmp-build-*` ni `api/appsettings.json`.
- La plantilla segura está en `configuration/appsettings.template.json`. En el servidor se debe conservar su `api/appsettings.json` actual para no reemplazar conexión ni secretos. La plantilla contiene CORS para `http://192.168.1.38:8080`.
- Los scripts SQL se entregan para revisión del responsable de SQL y no se ejecutaron durante la preparación del paquete. El script de indicadores no elimina filas ni cambia `ValorTexto1`, `ValorNum` o `ValorDecimal`; cambia solo `Area`, `TipoIndicador` e `IdIndicador` tras validar datos y aborta si detecta duplicados o relaciones inválidas.
- El paquete solo fue generado localmente: no se copió ni desplegó en el servidor y no se hicieron escrituras en ninguna base de datos.
- SHA-256 del ZIP corregido: `A8C760A71BBA3FDCC318B0668981DA31AF9C6203E48258592E7CE21460E5055D`.
- El ZIP contiene un token compartido para extensión/agente de impresión; transferirlo solo a destinos autorizados.
## Configuración de SERVER-NEW (192.168.18.47 / DXNCOMAS)

- El `appsettings.json` desplegado tenía `ConnectionStrings:DefaultConnection` vacío; por tanto, el API no está conectado a `DXNCOMAS` y el inicio de sesión no puede completarse.
- También estaban vacíos correo y servicios externos; no asumir que esas funciones están configuradas.
- `JwtSettings:Key` vacío provoca un error explícito durante el arranque en `src/Api/Program.cs`. Se generó una clave localmente en el servidor y se reinició el grupo de aplicaciones `SGO API`. No mostrar ni copiar esa clave en documentación o chat.
- `LocalMedia:RootPath` se corrigió en el servidor a `C:\SGO\media`. También se corrigió la plantilla y `scripts/deploy/prepare-server-new.ps1` para que paquetes futuros usen esa ruta.
- La configuración del correo emisor ahora puede guardar su contraseña de aplicación protegida en `dbo.Indicador`. Antes de usar esa pantalla en producción, configurar `DataProtection__KeysPath=C:\SGO\keys`, crear la carpeta y dar permisos de lectura/escritura a la identidad del Application Pool `SGO API`; conservar y respaldar esa carpeta durante futuras publicaciones.
- CORS está configurado para `http://192.168.18.47:8080` y `http://localhost:8080`. Usar la URL con IP para pruebas desde otras PCs.
- El preflight CORS `500` visto previamente podía deberse a que el API no arrancaba por la clave JWT vacía. Después de generar la clave no se ha confirmado todavía el resultado del nuevo preflight.
- La ruta de acceso es `POST /api/v1/User/acceso`. Cuando el preflight funcione, el POST seguirá sin poder consultar usuarios hasta que el responsable SQL entregue una cadena de conexión autorizada.
- Patrón de cadena esperado, completar solo con datos del responsable SQL y guardar el secreto únicamente en el servidor:
  `Server=192.168.18.47;Database=DXNCOMAS;User Id=<usuario_app>;Password=<secreto>;Encrypt=True;TrustServerCertificate=True;MultipleActiveResultSets=True;`
- El proveedor actual es `Microsoft.Data.SqlClient` 5.0.1. SQL 2008 R2 es legado: si aparece un error TLS/cifrado, no desactivar cifrado ni modificar SQL a ciegas; coordinarlo con el responsable de la BD.

## Próximos pasos de SERVER-NEW

1. Confirmar desde el navegador que `OPTIONS` (preflight) a `/api/v1/User/acceso` ya responde `200` o `204` y permite el origen `http://192.168.18.47:8080`.
2. Solicitar al responsable SQL la cadena de conexión y la cuenta autorizada de aplicación. No pedir que se pegue la contraseña en el chat.
3. Guardar la conexión en `C:\SGO\api\appsettings.json`, reiniciar únicamente el grupo `SGO API` y probar el acceso.
4. Configurar credenciales de correo y servicios externos cuando sus responsables las proporcionen.

## Seguridad del paquete

El paquete contiene un token compartido para la extensión/agente de impresión. Tratar los ZIP como confidenciales y transferirlos solo al servidor y a estaciones autorizadas.







## Pendiente para la siguiente publicacion: optimizacion de listados

El codigo nuevo de Caja y Facturas de servicio requiere aplicar previamente los archivos 01, 02 y 03 de `scripts/sql/20261020_optimizacion_listados/` en la BD de cada destino. No se aplicaron en ninguna base ni estan incluidos en los ZIP historicos documentados arriba. La carpeta contiene indices, dos procedimientos nuevos y reversion separada; conserva los datos de Indicador y los SP anteriores. Ver [detalle y orden](../scripts/sql/20261020_optimizacion_listados/README.md).

El generador `prepare-server-new.ps1` copia esta carpeta SQL a los paquetes futuros y avisa del requisito. No ejecuta los scripts. API y frontend deben actualizarse juntos una vez aplicados los SP. Se mantiene .NET 7, las IP y la separacion entre ICA y COMAS.
