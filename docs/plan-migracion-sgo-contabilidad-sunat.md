# Plan de migración de SGO Contabilidad SUNAT a DNX

## Propósito y alcance

Documenta la integración en DNX de las funciones SUNAT que existen en `sgo_contabilidad`, su alcance y forma de uso.

El alcance encontrado cubre configuración de credenciales por compañía, consultas SIRE de compras y ventas, consulta de periodos RVIE, generación/lectura de registros de ventas con espera por ticket, descarga de archivos, comparación de ventas SIRE con `DocumentoVenta`, validación de comprobantes en SUNAT y exportación de resultados a Excel. La interfaz fuente está enfocada en RVIE ventas; compras tiene endpoint backend, pero no pantalla frontend observada. No se encontró un módulo de contabilidad general ni una funcionalidad de emisión de comprobantes en este proyecto fuente.

## Resumen de la recomendación

- Integrar las páginas dentro del DNX existente, bajo Contabilidad, autenticación actual y permisos por compañía.
- No crear una tabla nueva para credenciales. Reutilizar `dbo.Indicador`, patrón ya usado por DNX para configuraciones por compañía, con claves SUNAT diferenciadas.
- Mantener `dbo.Compania.CompaniaRUC` como dato rector; la página debe mostrar el RUC de la compañía autenticada y no cambiarlo al guardar credenciales SUNAT.
- Adaptar la lectura de ventas a los modelos y bases de datos que usa cada DNX; no copiar `VentasConnection`, `CredencialesSunat` ni el login JWT independiente de la aplicación fuente.
- Antes de persistir secretos, confirmar el alcance de acceso y el mecanismo de protección en reposo disponible. Actualmente el patrón `Indicador` y la configuración CPE guardan valores sensibles como texto; esto debe tratarse como una decisión explícita de seguridad, no como cifrado implícito.

## Inventario y correspondencia

| Función en SGO Contabilidad | Integración propuesta en DNX | Observación |
|---|---|---|
| Configuración SUNAT por compañía | Pantalla bajo Configuración; leer/escribir indicadores usando el `companiaId` del JWT | La pantalla fuente permite cambiar el RUC de `Compania` y también escribe credenciales en otra base. En DNX se debe quitar esa escritura cruzada. |
| Compras SIRE (RCE) | Endpoint autenticado y pantalla si se confirma uso operativo | Existe endpoint backend en la fuente; el README frontend no indica una vista de compras. |
| Ventas SIRE (RVIE) por periodo | Pantalla de Contabilidad reutilizando tabla, estados, toast y llamadas API existentes | Es el flujo principal de la UI fuente. |
| Periodos, consulta de ticket, generación/lectura de registros y descarga | Servicios backend y acciones desde la pantalla RVIE | Respetar espera, cancelación/timeout y límites de paginación de la API SUNAT. |
| Comparación SIRE vs. ventas DNX | Adaptar consulta a `DocumentoVenta` y compañía autenticada | El SQL fuente consulta `DocumentoVenta` y campos como serie, número, fecha, total y estado; validar que esos nombres y reglas coincidan en cada base DXN. |
| Validación de comprobantes | Adaptar el servicio y su autorización al backend DNX; ejecutar en lotes permitidos por SUNAT | La UI fuente selecciona filas para validar y exporta resultados. No trasladar a la respuesta secretos ni datos de autenticación. |
| Exportación Excel de registros, diferencias y validaciones | Reutilizar `exceljs` solo si ya está instalado en DNX; si no, confirmar dependencia existente antes de añadirla | La exportación se realiza en frontend en el proyecto fuente. |

## Estado de DNX que reduce el trabajo

- El backend usa ASP.NET Core, JWT y claims `companiaId`, `userId`, `areaId`; los controladores requieren usuario autenticado globalmente.
- El frontend tiene rutas agrupadas en `features/accounting/routes.tsx`, `MainLayout`, `ModuleAccessGuard` y permisos declarativos. No se necesita una segunda app ni un segundo login.
- DNX ya guarda configuración sensible por compañía en `dbo.Indicador`. La documentación CPE describe indicadores separados por compañía, y existe un script para ampliar `ValorTexto1` a `varchar(max)`.
- `dbo.Indicador` tiene índice por `(CompaniaId, Descripcion)`, pero el esquema observado no impone unicidad. Las escrituras deben tolerar duplicados históricos o incluir una limpieza/revisión previa antes de proponer una restricción.
- La pantalla SIRE puede reutilizar `apiRequest`, `DataTable`/patrones de tablas, `toast`, navegación y guardas existentes. La configuración debe reutilizar controles equivalentes disponibles y no copiar los `input` sueltos del frontend fuente.
- El DNX revisado apunta a .NET 7 y a SQL Server 2008 R2 en scripts de compatibilidad. El backend fuente apunta a .NET 9. El puerto de servicios debe adaptarse al target de DNX y cualquier SQL debe seguir la compatibilidad de producción; no trasladar sin revisar `CREATE OR ALTER`, tipos o sintaxis más recientes.

## Base de datos

### Tablas nuevas

No se recomienda crear una tabla nueva para credenciales. `dbo.Indicador` ya asocia una descripción y un valor con una compañía y se usa para parámetros CPE. Las claves SIRE/API SUNAT deben tener nombres propios, sin sobrescribir parámetros de facturación electrónica existentes.

Propuesta de configuración lógica (nombres finales por acordar en implementación):

| Dato | Fuente de lectura/escritura propuesta |
|---|---|
| RUC | Lectura de `dbo.Compania.CompaniaRUC`; no duplicar ni modificar desde esta pantalla |
| Usuario SOL y clave SOL | Reutilizar indicadores `CPE_USUARIO_SOL` / `CPE_CLAVE_SOL` solo si se confirma que son las mismas credenciales; en caso contrario, crear claves SUNAT específicas en `Indicador` |
| Client ID/secret de SIRE | Indicadores SUNAT dedicados por compañía |
| Client ID/secret de validación de comprobantes | Indicadores SUNAT dedicados por compañía |
| URLs, scopes y plantillas de endpoint SUNAT | Configuración del servidor, no valores editables por compañía |

La columna `ValorTexto1` nació como `varchar(500)`. El script CPE existente la amplía a `varchar(max)`, necesario para certificados CPE grandes, pero no se debe asumir que ese script se ejecutó en todas las bases de datos DNX. Verificar el esquema efectivo de cada base objetivo antes de escribir secretos. No ampliar columnas ni cambiar tablas si el esquema instalado ya permite los valores requeridos.

En implementación, preparar un script SQL idempotente y compatible con SQL Server 2008 R2 solo si la verificación de esquema o una carga inicial de indicadores lo requiere. El plan no incluye cambios SQL aplicados. Si se modifica SQL, entregar al usuario el script resultante junto con el cambio.

### Datos de negocio para comparación

La fuente consulta `DocumentoVenta`, filtrando fechas y opcionalmente serie/tipo y `CompaniaId`, y compara serie/número normalizados con los registros descargados de SIRE. Confirmar para cada base DNX: nombres y tipos de columnas, inclusión/exclusión de anulados, zona horaria/fecha de emisión, códigos de tipo documental, duplicados, documentos de nota de crédito/débito y forma de resolver la compañía. Evitar permitir que el cliente envíe un `CompaniaId` que reemplace el claim del JWT.

## Cambios previstos por capa

### Backend DNX

1. Incorporar opciones SUNAT de servidor y clientes HTTP con timeout/cancelación.
2. Agregar proveedor de credenciales que resuelva la compañía desde el JWT y lea indicadores de esa compañía; nunca usar un `companiaId` libre enviado por el usuario para escoger credenciales.
3. Adaptar autenticación OAuth SUNAT, cliente SIRE, cliente de validación y control de tokens a la versión .NET existente. La caché debe separar tokens por credenciales/compañía y evitar compartir token entre compañías.
4. Añadir endpoints versionados bajo las rutas actuales de DNX para configuración, SIRE, comparación y validación; mantener autenticación global y validar entradas/permisos.
5. Leer documentos desde la conexión de DNX y tablas/procedimientos existentes, sin `VentasConnection` adicional ni `CredencialesSunat` externo.
6. Registrar servicios en `Program.cs` respetando los scopes: proveedor ligado a request/contexto no debe ser singleton si captura estado de compañía.
7. Revisar logs y errores de la fuente: no devolver ni registrar claves, client secrets, tokens ni payloads sensibles de SUNAT. La fuente contiene cadenas de conexión con credenciales en `appsettings.json`; no copiar esos valores. Si eran válidos o se compartieron fuera del entorno local, rotarlos.

### Frontend DNX

1. Agregar las rutas/páginas a `features/accounting/routes.tsx` y a la navegación existente.
2. Definir permisos separados para consultar SIRE/configurar credenciales si el esquema actual de permisos lo requiere; la configuración de secretos debe ser más restringida que la consulta operativa.
3. Reusar `apiRequest` para Bearer JWT, componentes de formulario, tablas y notificaciones DNX. Mantener secretos vacíos al consultar configuración y usar indicadores booleanos para mostrar si ya están configurados.
4. Traer a la UI ventas, comparación, validación por selección y Excel; agregar Compras solo cuando se confirme el flujo de usuario, ya que hoy es endpoint sin UI fuente observada.
5. Integrar ayuda de credenciales de SUNAT en el estilo/documentación DNX, no copiar el shell de login de la aplicación separada.

## Fases recomendadas

1. **Cerrar alcance y datos:** decidir si el primer corte incluye solo RVIE ventas o también RCE compras; confirmar bases DXN activas, permisos y si Usuario/Clave SOL se comparten con CPE.
2. **Preparar credenciales y datos:** revisar esquema de `Indicador`, tamaño de `ValorTexto1`, registros duplicados, cobertura por compañía y política de acceso a secretos. Definir script SQL idempotente únicamente si hace falta.
3. **Backend de credenciales y OAuth:** integrar lectura segura por claim, configuración de servidor, tokens separados por compañía y manejo de errores SUNAT.
4. **SIRE ventas:** migrar consulta por periodo, periodos/tickets/archivo/registros; adaptar DTOs y UI con componentes DNX.
5. **Comparación y validación:** validar filtros y mapeo de `DocumentoVenta`, luego habilitar validación SUNAT con límites y exportación.
6. **Compras SIRE (opcional según alcance):** agregar pantalla RCE y filtros si el negocio confirma que necesita la función del endpoint actual.
7. **Despliegue controlado:** verificar cada base de destino, publicar SQL cuando aplique, habilitar permisos por compañía y probar con credenciales de prueba antes de producción.

## Riesgos y controles

- **Aislamiento entre compañías:** toda consulta/credencial debe depender del claim autenticado. Probar que una compañía no pueda leer ni usar credenciales de otra.
- **Compatibilidad de esquema:** las bases DNX pueden diferir; `ValorTexto1` pudo permanecer en 500 caracteres si no se aplicó la migración CPE.
- **SQL Server antiguo:** mantener scripts compatibles con SQL Server 2008 R2 y probar la consulta real contra cada esquema de despliegue.
- **Actualización parcial de RUC:** el backend fuente actualiza primero `Compania` y después otra base; una falla deja datos incoherentes. DNX debe mantener el RUC como maestro y evitar esa operación distribuida.
- **Credenciales de texto plano:** el patrón actual de indicadores no cifra valores automáticamente. Limitar permisos de edición/lectura, no incluir valores en respuestas/logs y acordar protección en reposo antes de producción.
- **SUNAT no disponible o con límites:** definir timeouts, reintentos seguros, paginación y respuestas parciales; no reintentar solicitudes de generación sin idempotencia confirmada.
- **Código fuente con secretos:** no migrar cadenas de conexión, JWT, claves ni configuración de desarrollo de SGO Contabilidad; sanear/rotar cualquier secreto real expuesto.

## Implementación en DNX

La primera integración está ubicada en:

- Backend: controladores SUNAT/SIRE, proveedor de credenciales por compañía, autenticación OAuth, servicios RVIE/RCE y validación de comprobantes.
- Frontend: Contabilidad > SIRE ventas y Contabilidad > SIRE compras. La pantalla de ventas incluye comparación con `DocumentoVenta`, validación SUNAT y exportación Excel.
- Configuración: Configuración > Credenciales SUNAT, protegida por `CONFIGURACION.FACTURACION`; las consultas requieren `CONTABILIDAD.VER`.

La configuración guarda estos indicadores en `dbo.Indicador` con `Area = 'SUNAT'`: `SUNAT_USUARIO_SOL`, `SUNAT_CLAVE_SOL`, `SUNAT_SIRE_CLIENT_ID`, `SUNAT_SIRE_CLIENT_SECRET`, `SUNAT_VALIDAR_CLIENT_ID` y `SUNAT_VALIDAR_CLIENT_SECRET`. El RUC se lee desde `dbo.Compania.CompaniaRUC`; no se edita desde SUNAT. Los secretos nunca se devuelven al navegador y dejar un campo de clave vacío conserva su valor.

No se agrega tabla ni columna ni se requiere script DDL. La primera vez que se guarda configuración, el backend inserta filas en `dbo.Indicador`; las siguientes veces actualiza las filas existentes. Las URLs y endpoints SUNAT tienen valores por defecto en `SunatOptions` y se pueden reemplazar con variables `Sunat__...` del servidor.

## Criterios de aceptación

- Usuario DNX autenticado accede solo a datos/credenciales de su compañía y una prueba cruzada de compañía falla con autorización.
- Configuración muestra si existe cada secreto sin devolver el secreto; guardarlo vacío conserva el existente.
- Login y permisos usan los mecanismos DNX actuales; no hay sesión/JWT de SGO Contabilidad en paralelo.
- SIRE devuelve registros/archivos para un periodo y la comparación coincide con una muestra validada desde `DocumentoVenta`.
- Validación maneja resultados parciales y errores SUNAT sin exponer credenciales.
- Pantallas usan componentes reutilizables DNX y quedan documentadas junto a cualquier SQL aplicado.
- El despliegue funciona con target .NET y motor SQL soportados por la instalación DNX elegida.

## Referencias revisadas

- `C:\Users\User\Desktop\sgo_contabilidad\SGO_CONTABILIDAD_BACKEND\README.md`
- `C:\Users\User\Desktop\sgo_contabilidad\SGO_CONTABILIDAD_BACKEND\Controllers\SireController.cs`
- `C:\Users\User\Desktop\sgo_contabilidad\SGO_CONTABILIDAD_BACKEND\Controllers\ConfiguracionController.cs`
- `C:\Users\User\Desktop\sgo_contabilidad\SGO_CONTABILIDAD_BACKEND\Services\SunatCredentialsProvider.cs`
- `C:\Users\User\Desktop\sgo_contabilidad\SGO_CONTABILIDAD_FRONTEND\src\SireVentasRegistrosPage.tsx`
- `sgo_dnx_backend\docs\cpe-credenciales-indicador.md`
- `sgo_dnx_backend\scripts\sql\20260918_crear_tabla_indicador.sql`
- `sgo_dnx_backend\scripts\sql\20260924_configuracion_cpe_indicador.sql`
- `sgo_dnx_frontend\src\features\accounting\routes.tsx`
- `sgo_dnx_frontend\src\shared\security\ModuleAccessGuard.tsx`
