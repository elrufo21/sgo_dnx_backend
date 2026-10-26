# Contexto persistente: deploy-dxncomas

Leer este archivo antes de continuar cualquier trabajo de despliegue para DXNCOMAS. Describe el estado confirmado y las restricciones acordadas con el usuario; actualizarlo cuando cambien.

## Dos casos de despliegue: mantener separados

| Caso | Base de datos | Servidor / IP | Frontend | API |
|---|---|---|---|---|
| DXN_ICA | `DXN_ICA` | `192.168.1.38` | `http://192.168.1.38:8080/login` | `http://192.168.1.38:8081/api/v1` |
| DXNCOMAS | `DXNCOMAS` | `SERVER-NEW`, `192.168.18.47` | `http://192.168.18.47:8080` | `http://192.168.18.47:8081/api/v1` |

Estas son instalaciones distintas. No reutilizar entre ellas el ZIP, IP, CORS, `appsettings.json`, conexion de base de datos ni credenciales del otro caso. Los paquetes completos verificados más recientes para ICA y COMAS son los builds regenerados del **2026-10-23**; los del 2026-10-22 y anteriores quedan como referencia histórica. Los paquetes de frontend independiente más recientes son los del **2026-10-24**, con la corrección responsive de Pago Varios documentada al final. Los nuevos paquetes se prepararon y verificaron localmente, sin subirlos a los servidores ni ejecutar SQL.

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

## Builds vigentes de COMAS e ICA — 2026-10-21

- **DXNCOMAS**: `artifacts/deploy-DXNCOMAS-192.168.18.47-20261021-001052-final.zip`. Web `http://192.168.18.47:8080`, API `http://192.168.18.47:8081/api/v1`. SHA-256: `A379C27E5CEC8548C84F98005EF2B963826D79A83F13ADE1C4BFCF693B089F99`.
- **DXN_ICA**: `artifacts/deploy-DXN_ICA-192.168.1.38-20261021-001215-final.zip`. Web `http://192.168.1.38:8080`, API `http://192.168.1.38:8081/api/v1`. SHA-256: `FE5F0553492561A132F09E06B9845EF881D7ABBF85A0B4BE69DE9909FBCE71F3`.

- Ambos incluyen frontend compilado con Vite, API .NET 7 Windows x64 framework-dependent, extension, agente y la carpeta `sql/20261020_optimizacion_listados/` con instrucciones. Los DLL de la API son identicos en ambos paquetes; cada frontend fue compilado por separado con su URL destino.
- Antes de publicar la API nueva, el responsable SQL debe aplicar 01 indices, 02 procedimiento de Caja y 03 procedimiento de Facturas de servicio en la BD de cada destino, si aun no se aplicaron. `04_reversion.sql` no se ejecuta durante la actualizacion.
- No contienen `api/appsettings.json` ni configuraciones de desarrollo: conservar el appsettings actual de cada servidor. La plantilla segura y CORS del destino estan separados en `configuration/appsettings.template.json`. Conservar las carpetas media y keys.
- Verificados dentro de cada ZIP: URL compilada, ausencia de la IP del otro destino, CORS, extension, agente/token consistente, .NET 7, RID win-x64, web.config de IIS y coincidencia exacta de los SQL revisados. Verificacion repetible con `scripts/deploy/verify-package.ps1 -PackagePath <zip> -ServerName <ip>`.
- Se corrigio el generador para excluir .git, dependencias y logs del agente, separar la plantilla de appsettings y adaptar el README/CORS al destino. El proyecto API excluye `tmp-build-*` de la publicacion. Una salida preliminar descartada quedo marcada `NO_USAR.txt` y sus archivos renombrados a `NO-USAR-*.invalid`; no es una entrega valida.
- Reporte local sin secretos: `artifacts/builds-COMAS-ICA-20261021.json`. No se ejecuto SQL ni se desplego en ningun servidor durante esta preparacion. El token de impresion forma parte de los paquetes: mantenerlos en destinos autorizados.

## Paquetes de extensión Firefox — 2026-10-21

- COMAS: `artifacts/firefox-extensions-20261021/SGO-DXN-Capture-Firefox-comas-0.2.0.xpi` (origen `http://192.168.18.47:8080`). SHA-256 `AE8C661D2070C691A10DC30D3E069B57BA33D8BCEB60DB15BAE65EB8677F73DB`.
- ICA: `artifacts/firefox-extensions-20261021/SGO-DXN-Capture-Firefox-ica-0.2.0.xpi` (origen `http://192.168.1.38:8080`). SHA-256 `704CAB0D04D618ECCD169ED2B6DF4DD6A4568A7A3D045EA815923EEEA83C08E3`.
- Incluyen manifest V3 compatible con Firefox (`background.scripts`), Gecko ID y declaración de categorías de datos que la extensión transfiere a SGO. Los paquetes Chrome/Brave no se modificaron.
- Son paquetes sin firma para prueba temporal desde `about:debugging` y se eliminan al cerrar Firefox. La instalación permanente requiere firma Mozilla. No se publicaron ni instalaron en ningún navegador.
- Se verificó el contenido raíz del XPI, URL del destino correcto, ausencia de la IP del otro servidor y sintaxis JavaScript con `node --check`.

### Corrección Firefox COMAS 0.2.1 — 2026-10-21

- Usar `artifacts/firefox-comas-20261021/SGO-DXN-Capture-Firefox-comas-0.2.1.xpi`
  en lugar del paquete COMAS 0.2.0 de arriba. SHA-256
  `C16E895B0CF6C4F8A82DCAEFECDA1AC4FC5E64CB89C26D1FD04A5A651DBBED3B`.
- El 0.2.0 abría SGO pero Firefox ignoraba los patrones con `:8080`, por lo que
  no cargaba el script de entrega. El nuevo manifest usa `http://192.168.18.47/*`
  y restringe el puerto con `include_globs`; background comprueba el origen exacto
  `http://192.168.18.47:8080` después de consultar las pestañas. No reutiliza :8081,
  localhost ni ICA. Además, un READY tardío de Ventas no descarta un resumen OBS.
- Generador compartido: desde `sgo_dnx_extension_dev`, ejecutar
  `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-firefox.ps1 -Target comas`.
  Reutiliza el puente corregido y el extractor/botones de producción. Guía:
  `sgo_dnx_extension_dev/docs/firefox-comas.md`.
- Verificado en Firefox 158.0.1, perfil aislado y datos simulados: pestaña nueva,
  cambios Venta/Resumen y reutilización de cada formulario; también selección
  del origen COMAS y sintaxis JavaScript. No se probó una sesión OBS real ni se
  instaló en el perfil personal. No requiere cambiar web/API, SQL ni agente.
- Cargar temporalmente desde `about:debugging#/runtime/this-firefox`, retirar la
  versión anterior y recargar las pestañas OBS/SGO. Sigue siendo un XPI sin firma;
  la instalación permanente requiere firma Mozilla. ICA 0.2.0 no se ha regenerado.

## Diagnóstico de papel excesivo en estación COMAS — 2026-10-21

- Estación del usuario: perfil `C:\Users\HP 800 G5`. El servicio `DNXPrintAgent` apunta a `Documents\print-agent\dnx-print-agent-service.exe` y usa `LocalSystem`. Un intento de usar la cuenta del usuario falló al iniciar; se regresó a Sistema local. No insistir con credenciales sin revisar el error real.
- El PDF del primer request recibido contiene una página completa de react-pdf, `226 x 836.1 pt` (aprox. `79.7 x 295 mm`), sin la tira extensa en blanco vista en las fotos. El request selecciona `EPSON TM-T20II RECEIPT`; no confundir con la TM-T20IV configurada en el agente de desarrollo.
- El usuario confirma que desde el visor de PDF imprime bien en la estación afectada; desde el agente sale una tira extensa en blanco con el ticket. Esto acota el fallo a la ruta de impresión del agente/servicio y el driver, pero no descarta diferencias entre preferencias de usuario y valores globales.
- Se añadió `printScale` opcional en `dnx-print-agent/src/config.mjs` y se pasa a `pdf-to-printer` en `src/server.mjs`. Vacío conserva el comportamiento anterior. El paquete de prueba local está en `tmp/dnx-print-agent-scale-fit-test.zip`, sin configuración con secretos ni dependencias. Las cinco pruebas unitarias pasaron; no prueban el resultado físico.
- El usuario copió los dos archivos actualizados desde el paquete extraído del escritorio a la carpeta Documents del servicio. Confirmó servicio Running y `printScale=fit`. Después confirmó con fotos que el papel excesivo persiste: **fit no es una solución confirmada**.
- Revisión del código upstream de SumatraPDF `3.4.6rel/src/Print.cpp`: intenta asignar el tamaño de la primera página del PDF, obtiene el papel efectivo del contexto del driver y centra la página con fit/shrink; noscale cambia la colocación, pero no garantiza eliminar avances o longitud de página del driver. No afirmar que omitir paperSize implica que Sumatra nunca solicita el tamaño del PDF.
- Hipótesis principal pendiente de confirmar en la estación: tamaño largo de rollo aceptado por Epson/centrado y/o avance al inicio o fin del documento. Revisar los valores globales de la impresora (Propiedades > Opciones avanzadas > Valores predeterminados de impresión), tamaño de papel y Feed and Cut, comparados con la configuración que funciona desde el visor. El manual oficial Epson TM-T20II distingue configuración por usuario/global y ajustes de avance/corte.
- No se modificaron SQL, frontend ni API en esta investigación. No hacer más cambios de escala ni nuevos builds hasta recoger la configuración efectiva de la impresora o realizar una comparación controlada entre Sumatra en sesión y el servicio.
- Prueba posterior del usuario: reducir 3276 mm no corrigió COMAS y su PC local imprime bien aun usando ese formato. No atribuir el problema únicamente al largo de papel configurado.
- Se preparó la carpeta local `tmp/dnx-print-agent-scale-fit-test` con dependencias mediante `npm.cmd ci`, configuración local con `printScale=fit` y token verificado contra el frontend de desarrollo sin mostrarlo. El ZIP original sigue sin configuración con secretos ni dependencias.
- El usuario instaló esa copia como servicio en su PC de desarrollo; se comprobó `DNXPrintAgent Running`, `StartName=LocalSystem`, apuntando al ejecutable de la carpeta de prueba. El usuario confirmó que imprime bien también como servicio. Ser servicio/LocalSystem por sí solo no reproduce el fallo; falta comparar la misma ejecución en la estación de COMAS.
- En la PC local se verificó con `Win32_Printer`: cola `EPSON TM-T20IV Receipt`, controlador `EPSON TM-T(203dpi) Receipt6`, puerto `TMUSB001`. En COMAS el request usa `EPSON TM-T20II RECEIPT` y las capturas muestran un diálogo con Receipt5; esto sugiere diferencias de controlador, pero se debe obtener DriverName/versión de COMAS antes de concluir o cambiar drivers. El archivo UNIDRV.DLL local es un componente Windows, su versión no equivale a la versión de Epson APD.
- COMAS confirmó por `Win32_Printer`: cola `EPSON TM-T20II Receipt`, DriverName `EPSON TM-T20II Receipt5`, PortName `ESDPRT001`. Son controladores distintos respecto de la PC local; el puerto Epson por sí solo no demuestra una falla y esto no autoriza reemplazar APD5 por APD6.
- El manual Epson Advanced Printer Driver Ver.5, M00062200-2EN Rev.B, apartado Paper Saver Setting (pág.93), ubica el recorte superior/inferior en Paper/Quality > Paper Source. Esa pestaña no se ha recibido aún en las capturas de COMAS. Comprobar el valor en los valores predeterminados globales antes de hacer más cambios de papel, escala o controlador. El agente actual no pasa bin/paper source, por lo que no impone ese ajuste.
- El usuario confirmó luego que ICA también usa EPSON TM-T20II Receipt5 y ESDPRT001 y funciona. El nombre del driver/puerto no basta para explicar COMAS; no atribuir el fallo únicamente a Receipt5 ni recomendar reemplazo por Receipt6 con estos datos.

## Paquete autorizado de captura sin imprimir — 2026-10-21

- El usuario pidió suspender temporalmente la impresión del agente en COMAS para no gastar papel, guardar el PDF exacto recibido y añadir registros. No continuar haciendo ensayos físicos hasta revisar esos archivos.
- Paquete: artifacts/print-agent-diagnostico-comas-20261021-v1.zip. SHA-256: B5382E7DEA78B8B53E37801C3B2683D27B4D1C116D5BCB906E0E9E33FA10DCC2. Contiene cuatro módulos src, configurar-diagnostico.ps1 y README; no incluye tokens, configuración de estación ni dependencias. Actualiza un servicio ya instalado.
- El activador, ejecutado por el usuario como administrador en la PC cliente, descubre la ruta real del servicio DNXPrintAgent, respalda src y agent.config.json, conserva los valores existentes, actualiza el código, activa diagnosticMode true, reinicia y exige que /health confirme build 20261021-diagnostics-v1 y modo activo. Si falla después de parar el servicio, lo deja detenido. No cambia la cuenta del servicio.
- En modo diagnóstico, POST /v1/print guarda bytes originales en diagnostics junto al agente, con un JSON individual y jobs.jsonl. Registra ID, fecha, equipo, usuario Windows, origen, opciones, tamaño y SHA-256, sin token/base64/texto del documento. No consulta ni llama a la impresora, tampoco como respaldo si guardar falla.
- Responde HTTP 409 con captured true y printed false para que el frontend actual muestre el bloqueo con ruta del PDF y no anuncie éxito de impresión. La consulta /health sigue respondiendo 200. No requiere build del front/back ni SQL. Los PDF se guardan en disco local, no hay descarga automática del navegador ni publicación por HTTP.
- Once pruebas automatizadas exitosas: bytes/hash, no llamadas de impresión al capturar o fallar, limpieza normal con impresión simulada, autenticación, CORS, salud, recuperación de cola tras error y respuesta 409. La prueba HTTP usó otro proceso/puerto temporal; no se imprimió papel ni se modificó el servicio local de prueba ya instalado. El script de activación se validó por sintaxis, pendiente de ejecutar por el usuario en COMAS.
- Guía completa: dnx-print-agent/docs/diagnostico-sin-imprimir.md. Para volver a impresión normal se usa el mismo script con -Desactivar, solo después de revisar los archivos.

## Extensión Chrome/Brave independiente COMAS — 2026-10-22

- Paquete: `artifacts/chrome-comas-20261022/SGO-DXN-Capture-Chrome-COMAS-0.2.1.zip`.
- SHA-256: `5834C34117BDD4A0610491BC5A3B9360215FB2D3DBDCB612CD1CF6925432E1F5`.
- Se tomó la extensión del build completo COMAS `deploy-DXNCOMAS-192.168.18.47-20261021-001052`; el manifest limita OBS y SGO a los orígenes previstos y SGO COMAS `http://192.168.18.47:8080`. El nombre visible identifica COMAS y la versión es 0.2.1.
- Instalar: extraer el ZIP y en `chrome://extensions` o `brave://extensions`, activar Modo desarrollador, pulsar **Cargar descomprimida** y seleccionar la carpeta `extension` que contiene `manifest.json`. Recargar las pestañas OBS/SGO. Retirar otra variante si genera botones duplicados.
- El paquete solo fue generado localmente; no se instaló en estaciones ni se modificó frontend/API/SQL.
## Build completo DXN_ICA — 2026-10-22

- Paquete: `artifacts/deploy-192.168.1.38-20261022-120020-final.zip`.
- Frontend: `http://192.168.1.38:8080`; API: `http://192.168.1.38:8081/api/v1`.
- SHA-256: `02E251DC7D5506CDC9FB70506F48818C64670EF64C2FEDC9E591E9978411FB40`.
- Incluye frontend, API Windows x64 framework-dependent (.NET 7), extensión, agente de impresión y los scripts SQL informativos `20261020_optimizacion_listados`. El ZIP omite `api/appsettings.json` para conservar la conexión y secretos propios del servidor.
- El paquete pasó `verify-package.ps1`: URLs y CORS corresponden a ICA, .NET/RID son net7.0/win-x64, no incluye IP de COMAS y la configuración del servidor no se reemplaza. El frontend compiló con una advertencia de bundle grande; la publicación del backend terminó con advertencias de análisis preexistentes.
- Los scripts SQL no se ejecutaron. Antes de publicar la API, el responsable de SQL debe confirmar/aplicar 01, 02 y 03 en la base DXN_ICA si aún están pendientes; `04_reversion.sql` es solo para una reversión autorizada. No se desplegó nada al servidor.
## Build completo DXNCOMAS — 2026-10-22

- Paquete: `artifacts/deploy-192.168.18.47-20261022-121755-final.zip`.
- Frontend: `http://192.168.18.47:8080`; API: `http://192.168.18.47:8081/api/v1`.
- SHA-256: `AA6F5F7E0F7C9B5DB83EB1ACCF7FBBD72DAACA1ACB462B065EE59577A8B7346F`.
- Incluye frontend, API Windows x64 framework-dependent (.NET 7), extensión, agente de impresión y los scripts SQL informativos `20261020_optimizacion_listados`. El ZIP omite `api/appsettings.json` para conservar la conexión y secretos propios del servidor.
- El paquete pasó `verify-package.ps1`: URLs y CORS corresponden a COMAS, .NET/RID son net7.0/win-x64, no incluye IP de ICA y la configuración del servidor no se reemplaza. El frontend compiló con una advertencia de bundle grande; el backend terminó correctamente.
- Los scripts SQL no se ejecutaron. Antes de publicar la API, el responsable de SQL debe confirmar/aplicar 01, 02 y 03 en DXNCOMAS si aún están pendientes; `04_reversion.sql` es solo para una reversión autorizada. No se desplegó nada al servidor.
## Frontend solamente para ICA y COMAS — 2026-10-22

- ICA: `artifacts/front-DXN_ICA-192.168.1.38-20261022-145738-final.zip`; API compilada `http://192.168.1.38:8081/api/v1/`; SHA-256 `D242126EC9418855915EE28517792F4F6AFB80DCDD08819A05FE717A96B954E6`.
- COMAS: `artifacts/front-DXNCOMAS-192.168.18.47-20261022-145738-final.zip`; API compilada `http://192.168.18.47:8081/api/v1/`; SHA-256 `BE910FF6F13D384FD19B70C9D6DE40BF798CB937AA3CDB2D200198377AB54D21`.
- Ambos paquetes contienen solo el frontend compilado bajo `web/` y un README. No incluyen API ni SQL. Se verificó que cada bundle contiene su propia URL de API y no contiene la IP del otro destino.
- Para publicarlos, copiar el contenido de `web/` a la raíz del sitio web correspondiente. Los paquetes se generaron localmente; no se copiaron a los servidores.
## Frontend solamente para ICA y COMAS — 2026-10-23

- DXN_ICA: `artifacts/front-DXN_ICA-192.168.1.38-20261023-123909-final.zip`; API compilada `http://192.168.1.38:8081/api/v1/`; SHA-256 `57D91A605DB942FC259B4B22A0D519AA5DFF00583C6BA24A8458332FE813ADA7`.
- DXNCOMAS: `artifacts/front-DXNCOMAS-192.168.18.47-20261023-123909-final.zip`; API compilada `http://192.168.18.47:8081/api/v1/`; SHA-256 `1E4C2F5DEE9A72825FF24BE4F12F61E375D4C45A2B3E6E95B2B5CD9CC10344CE`.
- Ambos incluyen únicamente frontend compilado bajo `web/` y README. Copiar el contenido de `web/` a la raíz del sitio web correspondiente. No incluyen API ni SQL; no se desplegaron al servidor.
- Verificado que cada bundle incluye su propia URL de API, excluye la IP del otro destino, y que ambos ZIP contienen `web/index.html` y README.
- `npm run build:vercel` completó para ambos. Vite muestra la advertencia preexistente de bundle JavaScript grande (~4.9 MB sin comprimir). El build `build:vercel` no ejecuta TypeScript; el `typecheck` del frontend aún reporta errores preexistentes no relacionados con este empaquetado.
## Despliegue solicitado y paquetes regenerados — 2026-10-23

- El usuario confirmó que el responsable SQL aplicó los scripts 01, 02 y 03 en DXN_ICA y DXNCOMAS. No se ejecutó ni modificó SQL.
- Los ZIP completos con sufijo `20261023-140516-final` no son archivos ZIP válidos. No usarlos. La carpeta COMAS de esa salida también tiene `Ecommerce.Api.runtimeconfig.json` vacío/corrupto; no usar esa carpeta ni el ZIP `20261023-140516-repacked`.
- Se reconstruyeron desde el árbol de trabajo actual con `scripts/deploy/prepare-server-new.ps1`, y ambos pasaron `verify-package.ps1` para URLs, CORS, .NET 7, Windows x64, IIS, configuración separada e impresión:
  - ICA: `artifacts/deploy-192.168.1.38-20261023-rebuild2-final.zip`. SHA-256: `E5E4667758376F3E2C8FBF50AD925915192AFA179EDC40E6940E7B1E95F114DC`.
  - COMAS: `artifacts/deploy-192.168.18.47-20261023-rebuild2-final.zip`. SHA-256: `8DC90545059F230BC34CBF83D58CCC63D834486F98C5191798590CE6798E123C`.
- Los paquetes nuevos aún no se copiaron a los servidores. Desde este equipo no hubo conexión a los puertos 445, 5985, 5986, 22, 21, 3389, 8080 ni 8081 de `192.168.1.38` o `192.168.18.47`; reanudar cuando el equipo tenga ruta de red/VPN y canal autorizado hacia ambos destinos.
- En COMAS, el `ConnectionStrings:DefaultConnection` del `appsettings.json` del servidor figuraba vacío en la última revisión. El paquete conserva ese archivo. La API puede publicarse cuando haya conectividad, pero el inicio de sesión seguirá dependiendo de que el responsable SQL entregue la cadena y cuenta autorizadas y de configurarlas en el servidor.

## Frontend Pago Varios para COMAS e ICA — 2026-10-24

- COMAS: `artifacts/front-DXNCOMAS-192.168.18.47-20261024-135051-final.zip`. API compilada `http://192.168.18.47:8081/api/v1/`. SHA-256: `82FE8C81E5D488476D51307044AEDA4228D1B015A4CCFDC244AB6837669F68CA`.
- ICA: `artifacts/front-DXN_ICA-192.168.1.38-20261024-135051-final.zip`. API compilada `http://192.168.1.38:8081/api/v1/`. SHA-256: `ECB5CA366504D4A9BAD9950FF60D06882163E6A9416DB4E830E1D80A2D34615C`.
- Incluyen el frontend actual con el formulario desplazable y las acciones de Pago Varios fuera de la zona de desplazamiento en escritorio; en móvil el contenido se apila y permite desplazarse. El modal se verificó previamente con datos simulados en 1366×600, 1280×500, 1024×400 y 390×640.
- Ambos ZIP contienen únicamente `web/` y README. Respaldar la web actual y copiar el contenido de `web/` a la raíz del sitio correspondiente; recargar con Ctrl+F5. No requieren actualizar API, SQL, extensión ni agente por esta corrección.
- `npm run build:vercel` pasó para ambos con la advertencia existente de bundle grande. La API activa de cada bundle coincide con su destino y no aparece la IP del otro; se comprobaron assets del index, `web.config` de IIS, la corrección compilada y la consistencia del token de impresión. Los 10 archivos de cada ZIP se leyeron y sus SHA-256 coincidieron con los originales. Registro: `artifacts/front-pago-varios-20261024-135051-verification.json`.
- El build completo conserva los 272 errores TypeScript preexistentes comprobados en el trabajo del modal. No se repitió el typecheck al empaquetar el mismo código. Los paquetes se generaron localmente; no se desplegaron ni se ejecutó SQL. Contienen el token de impresión del frontend: transferir solo a destinos autorizados.

## Build completo con SQL de ConceptoOBS — 2026-10-26

- ICA: `artifacts/deploy-192.168.1.38-20261026-final-final.zip`. SHA-256: `DAEED8984294BC9D1BCCC633020C37B36806A98D42A47938C3CFAEE3C2C52845`.
- COMAS: `artifacts/deploy-192.168.18.47-20261026-final-final.zip`. SHA-256: `A32B7B5B12C2104F7DF86046C7463EA22B97769D68AB7C522995809CCEAB683C`.
- Ambos son paquetes completos con frontend, API .NET 7 para Windows x64, extensión, agente, plantilla segura de configuración y SQL. Cada frontend/API quedó compilado para su destino; se verificaron URLs, CORS, exclusión de la IP contraria, runtime, configuración conservada, agente y coincidencia exacta de los scripts SQL.
- Incluyen `sql/20261026_listaNotaPedido_web.sql` para que el responsable SQL lo revise y aplique por separado en `DXN_ICA` o `DXNCOMAS`, según el paquete. Actualiza `dbo.listaNotaPedidoWEB` para devolver `ConceptoOBS` y conserva el procedimiento del escritorio. También se conserva `sql/20261020_optimizacion_listados/` con sus instrucciones y reversión.
- No se ejecutó SQL, no se modificaron bases de datos ni se desplegaron los ZIP. El paquete contiene el token compartido de impresión; transferirlo solo por canales autorizados. COMAS continúa dependiendo de que el responsable SQL entregue y configure la conexión válida del servidor.
- Compilaciones completadas. Vite mantiene la advertencia existente por el tamaño del bundle; la publicación de API termina con advertencias de análisis ya presentes.

## Builds completos con actualización Pago Varios — 2026-10-26

Estos paquetes reemplazan los builds `20261026-final-final` anteriores e incluyen el cambio para que `YAPE/EFECTIVO` y `YAPE` usen BCP por defecto en Pago Varios.

- ICA: `artifacts/deploy-192.168.1.38-20261026-pago-varios-final-final.zip`. SHA-256: `8B4010560360F5D30BAC3D0D6104EE88FBF63D311F3187CFD83434D64633F70E`.
- COMAS: `artifacts/deploy-192.168.18.47-20261026-pago-varios-final-final.zip`. SHA-256: `584D90FBCD89960BD2B0316DC045138B6497E84FFB8442D01D787FE1F4192061`.
- Incluyen frontend, API .NET 7 para Windows x64, extensión, agente y los scripts SQL informativos: `20261026_listaNotaPedido_web.sql` y la carpeta `20261020_optimizacion_listados/`. Ambos ZIP pasaron `verify-package.ps1` para sus destinos respectivos.
- Se generaron localmente; no se desplegaron ni se ejecutó SQL. Los paquetes contienen el token compartido de impresión: transferirlos solo por canales autorizados.
