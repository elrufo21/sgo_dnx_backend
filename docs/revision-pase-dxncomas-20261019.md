# Revisión del pase web a DXNCOMAS — 19/10/2026

## Conclusión

**El paquete SQL quedó actualizado, pero el pase completo todavía tiene pendientes.** La revisión se hizo sobre la copia local `DXNCOMAS` de `localhost\SQLEXPRESS01`, comparada con `DXN_ICA15102026` y con el código actual de la web/API. No se ejecutó la migración sobre ninguna de esas dos bases. No se verificó otro servidor de producción.

El inventario actual de COMAS es de 78 tablas y 370 módulos SQL. Para las llamadas actuales de la web faltan **2 tablas, 14 columnas en tablas existentes y 44 procedimientos** de la referencia. Además, hay **9 contratos llamados desde la web que no están instalados en ninguna de las dos bases**. Las 20 columnas de las dos tablas nuevas están incluidas en sus CREATE TABLE; no se suman como otros 20 ALTER.

Se recorrieron 188 archivos alcanzables, 169 sitios de llamadas HTTP y 134 endpoints distintos. La cadena frontend → endpoint → SQL comprende 105 objetos; no quedaron URLs locales sin resolver en ese inventario. Es una comprobación estática y de metadatos, no una prueba funcional de las pantallas.

## Qué cambió respecto del paquete anterior

| Punto | Ayer / paquete anterior | Revisión actual |
| --- | --- | --- |
| Procedimientos instalables | 43 | 44: se agrega `uspListaDocumentosWEB`, disponible hoy en la referencia. |
| Contratos sin definición instalada | 10 excluidos | 9 excluidos; se conserva su lista explícita. |
| Indicadores | Solo la estructura, sin inicialización | Archivo 04: 24 claves iniciales por compañía; usa valores propios de COMAS y conserva indicadores existentes. |
| Escritorio | Seis INSERT posicionales señalados para revisar | Archivo 00: corrección de listas de columnas, con protección ante cambios de definición. |
| Comprobación del pase | Diagnóstico del inventario anterior | Archivo 05 actualizado a los 105 objetos y 34 columnas del alcance. |
| Índices de documentos | Revisión pendiente | Archivo 06 opcional: dos índices de lectura, sin añadir FK históricas. |
| Ejecución | Archivos separados | Instalador SQLCMD transaccional 00–04, seguido del diagnóstico. |

Los scripts 01 y 02 ya cubrían las dos tablas y las 14 columnas. Las definiciones anteriores de los 43 procedimientos coinciden con la referencia actual. Los cambios de hoy en asistencia del encargado, continuidad de los GET, encabezado de correo, diferencial y productos del informe requieren publicar el código actual; no introducen otras tablas ni columnas.

## Nueve contratos todavía pendientes

No se incorporaron definiciones históricas sin validar para aparentar que el pase está completo. Estos contratos conservan la exclusión del paquete anterior. Encontrar un archivo candidato no acredita que su contrato sea correcto para COMAS.

| Procedimiento | Función alcanzada desde la web | Fuente candidata para revisión |
| --- | --- | --- |
| `uspInsertarCategoria` | Alta de categoría mediante `/Linea/registerlinea`. | Definición individual en `scripts/sql/bdactual.sql`. |
| `uspEliminarCategoria` | Eliminación mediante `/Linea/maintenance/{id}`. | Definición individual en `scripts/sql/bdactual.sql`. |
| `uspEliminarProducto` | Eliminación de producto. | Definición individual en `scripts/sql/bdactual.sql`. |
| `uspGuardarUnidadMedidaProducto` | Guardado de unidades/precios de producto. | `sgo_dnx_frontend/docs/uspGuardarUnidadMedidaProducto.sql`. |
| `uspInsertarProveedor` | Guardado de proveedor mediante `/Proveedor/register`. | Definición individual en `scripts/sql/bdactual.sql`. |
| `uspEliminarProveedor` | Eliminación de proveedor. | Definición individual en `scripts/sql/bdactual.sql`. |
| `uspInsertarCuentaProveedor` | Guardado de cuentas del proveedor. | Definición individual en `scripts/sql/bdactual.sql`. |
| `uspInsertarUsuario` | Edición de perfil mediante `PUT /UsuariosCrud/{id}`. El mantenimiento nuevo de usuarios usa otro contrato. | Definición individual en `scripts/sql/bdactual.sql`. |
| `uspListarComprasweb` | Listado CRUD de compras y consultas del PDT. | `scripts/sql/20260825_uspListarComprasweb.sql`. |

Resolver cada contrato con una definición revisada para sus parámetros, respuesta y reglas, o retirar/coordinadamente cambiar su llamada real. La matriz con endpoints, archivos y líneas está en `artifacts/analisis-dxncomas-20261019/web_procedimientos_faltantes.md`; las fuentes candidatas están en `web_definiciones_candidatas.csv`.

## Configuración y datos de COMAS que requieren atención

| Hallazgo comprobado | Preparación necesaria |
| --- | --- |
| No existe `Indicador`. | Ejecutar estructura e inicialización. El archivo 04 activa asistencia (`1`) y deja CPE en beta (`3`); revisar múltiples cajas (`0`), captura HTML (`0`), boleta por lote (`1`) y descuento (`0`). Reejecutar no sobreescribe valores ya guardados. |
| Las credenciales SOL históricas tienen contenido; `CompaniaPFX` es una referencia a archivo de 16 caracteres. | El archivo 04 copia SOL y clave del certificado de COMAS, pero **no convierte el nombre del archivo en un PFX**. Cargar el PFX/P12 real desde Configuración > Facturación y validar clave, RUC, certificado y entorno. No se comprobaron autenticidad ni vigencia criptográfica de ese archivo. |
| No hay indicadores de destinatarios ni perfiles web. | Configurar `CORREOS_ADMIN`; SMTP usa `EmailSettings:Email` y `EmailSettings:Key` del API. Configurar permisos por área/usuario desde un administrador. Hay 29 usuarios, 10 marcados como administradores; no se elevó a ningún usuario ni se concedieron permisos automáticamente. |
| Hay seis máquinas; falta la columna `SerieBoleta` y una máquina (`LOGISTICA`) tiene `SerieFactura` vacía. | El script agrega la columna, pero no inventa valores. Configurar las series de cada estación emisora y verificar sus correlativos contra el historial real. Revisar si LOGISTICA emitirá facturas. |
| Hay una caja `ACTIVO` y 3535 `CERRADA` en la captura revisada. | Coordinar el corte y el cierre normal de la caja antes de cambiar configuraciones o poner la web en servicio. La web bloquea la edición de Configuración > Caja mientras existe una caja activa. No se cambió ningún estado. |
| El nombre comercial y la razón social actuales dicen `LINO ESPIRITU WILDER`. | Revisar el nombre comercial que COMAS debe mostrar en el encabezado del correo. No aplicar el script que cambia el nombre a DXN ICA: corresponde a otra base. |
| Hay renovaciones OSE, firma y SOME con fechas futuras y `DiasMaxDep = 3`. | El archivo 04 conserva esos valores de COMAS dentro de Indicador; no elimina sus columnas históricas. No se certifica un servicio externo por el solo hecho de tener una fecha futura. |
| `DocumentoVentaCpeWeb` será una tabla nueva vacía. | Definir el acceso a XML/CDR/PDF y los datos de receptor de documentos históricos cuando se requiera reimprimir o consultar sus archivos. No se fabricaron metadatos ni se marcaron documentos como enviados. |

Los controles de usuarios sin Personal, Personal sin compañía, RUC con formato incorrecto y los huérfanos de las relaciones comparadas dieron cero. Esto no sustituye la validación integral de datos ni el respaldo previo al pase.

## Publicación y archivos fuera del SQL

- Configurar `ConnectionStrings:DefaultConnection` del API hacia **DXNCOMAS** en su servidor real. No se cambió la conexión local que usa ICA.
- Publicar el backend y frontend actuales. El API del proyecto apunta a .NET 7; preparar el alojamiento para esa compilación y configurar JWT, CORS, `LocalMedia:RootPath`/`RequestPath` y permisos de las carpetas.
- Compilar el frontend con `VITE_API_BASE_URL` de la API de COMAS; configurar el origen de la extensión y el agente de impresión de cada estación. Revisar el token de consulta DNI/RUC cuando se use ese servicio.
- El envío desde `ServiceInvoiceCreate.tsx` conserva una URL fija hacia `https://www.api-sgo.somee.com/api/v1/Correo/enviar-comprobante`. Debe resolverse ese destino para COMAS antes de habilitar ese flujo; cambiar solo la conexión SQL no redirige esa llamada.
- Migrar o hacer accesibles los archivos necesarios: imágenes, media de depósitos/caja chica, certificados, XML/CDR/PDF. Las rutas UNC o de escritorio no se vuelven accesibles desde la web por instalar tablas.
- La última comprobación general del frontend en esta conversación pasó con Vite, pero `npm run build` quedó bloqueado por errores TypeScript existentes del proyecto. No se repitió esa compilación en esta revisión SQL ni se consideran resueltos esos errores.

No se probaron ni enviaron correos, boletas, facturas o resúmenes SUNAT en esta revisión.

## Diferencias que no se instalan por paridad

`uspCruzeOBS` ya existe en COMAS con una comparación de fecha distinta a ICA; comprobar resultado y rendimiento con fechas representativas antes de decidir cambiarlo. No se reemplaza automáticamente. `Producto.ProductoNombre` admite 300 caracteres en COMAS y MAX en ICA: revisar nombres/importaciones largos; el paquete no amplía ese campo sin una necesidad confirmada.

Se conservan las tablas propias de COMAS. No se crean `BLOQUE`, `DetalleBloque`, `Stock` ni `RentaMensual`, sin cadena web comprobada. Las dos FK adicionales de ICA sobre `DetalleCompra` y `DetallesPVS` tampoco se incorporan por simple paridad; el contrato web no exige reemplazar las reglas históricas de COMAS. El archivo 06 contiene solo las mejoras de índices de lectura adoptadas.

## Validación realizada y orden de pase

1. Respaldo y ensayo sobre una copia de COMAS con datos controlados; definir el corte y completar los nueve contratos según las funciones que se habilitarán.
2. Revisar los valores iniciales del archivo 04 y ejecutar el instalador SQLCMD desde la carpeta del paquete. 00–04 se ejecutan dentro de una transacción. 05 informa los pendientes después del COMMIT; no los oculta ni los corrige. 06 es opcional.
3. Configurar datos empresariales, PFX, entorno CPE, destinatarios, permisos, estaciones y almacenamiento; publicar con las conexiones/orígenes de COMAS.
4. Probar login y permisos de administrador y usuario de área, mantenimiento, ventas y unidades, compras/PDT, asistencia, apertura y cierre para otro encargado, informe final/productos/PDF, correo, resúmenes/CDR y acceso a históricos. La prueba de emisión debe respetar el entorno elegido.

El paquete se probó dos veces en una base temporal vacía reconstruida desde los metadatos de COMAS: transacción, columnas, seis correcciones de compatibilidad, 44 procedimientos, 24 indicadores, preservación de un valor configurado e índices opcionales. `sp_refreshsqlmodule` enlazó los 44 procedimientos sin errores. El diagnóstico se comprobó antes del paquete sobre COMAS (solo SELECT) y después sobre la base temporal. Permanecen los nueve contratos excluidos. La base temporal fue eliminada.

### Corrección para SQL Server 2008

La primera entrega contenía `CREATE OR ALTER`, `THROW` y `SHA2_256`; no era totalmente compatible con SQL Server 2008. Se corrigieron los archivos 00, 03, 04 y el instalador. Se crea un cuerpo vacío solo para SP ausentes y luego se aplica `ALTER PROCEDURE`, sin eliminar objetos ni permisos. Los errores se propagan con `RAISERROR` y los bloques TRY/CATCH conservan el rollback. La comprobación de cambios del archivo 00 procesa toda la definición con una cadena SHA1 por bloques de 7800 bytes, manteniendo cada entrada HASHBYTES por debajo de 8000 bytes.

Los ocho archivos y sus 46 consultas dinámicas literales pasaron el analizador de Microsoft `TSql100Parser`, además del control de funciones posteriores a 2008. La instalación corregida volvió a pasar dos ejecuciones y el enlace de los 44 procedimientos. **El motor local sigue siendo SQL Server 16 con compatibilidad 100; esto no sustituye ejecutar una prueba sobre SQL Server 2008 real.** La evidencia específica es `validacion_sintaxis_sql2008.json`.

También se detectaron consultas directas del backend fuera del paquete que requieren revisión para un despliegue íntegro en 2008: `CONCAT` en `CorreoController` y `NotaController`, `TRY_CONVERT` en `NotaPedidoRepository`, y paginación `OFFSET/FETCH` o `CONCAT` en repositorios CRUD de usuarios, personal, proveedores, cuentas y compras. Algunas rutas CRUD pueden ser heredadas; el inventario de llamadas debe determinar cuáles habilitar. No se cambió el código de esas consultas en esta corrección de los archivos SQL. No debe certificarse toda la web como compatible con 2008 solo porque el paquete pasó el parser.

Referencias: [parser SQL 100 de Microsoft](https://learn.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.transactsql.scriptdom.tsql100parser), [CREATE PROCEDURE](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql) y [límites de HASHBYTES](https://learn.microsoft.com/en-us/sql/t-sql/functions/hashbytes-transact-sql).

La segunda captura de COMAS permite verificar que su esquema y módulos permanecieron sin cambios. La prueba sin datos no demuestra que todas las operaciones comerciales funcionen con el historial real ni que el aplicativo de escritorio sea equivalente funcionalmente después del pase.

## Evidencia y reproducción

Los resultados actuales están en `artifacts/analisis-dxncomas-20261019/`: `web_resumen.json`, `web_objetos_confirmados.csv`, `web_columnas_con_trazabilidad.csv`, `web_procedimientos_faltantes.md`, `diagnostico_comas_antes.txt`, `preparacion_comas_sin_secretos.json`, `validacion_paquete.json` y la captura de comprobación `verificacion-final/DXNCOMAS.json`.

```powershell
# Desde sgo_dnx_backend: captura y traza frontend.
./scripts/analizar-dxncomas/exportar.ps1 -Salida ./artifacts/analisis-dxncomas-20261019
python scripts/analizar-dxncomas/comparar.py --carpeta artifacts/analisis-dxncomas-20261019
node scripts/analizar-dxncomas/trazar-frontend.cjs artifacts/analisis-dxncomas-20261019
# El analizador C# requiere SDK 9; invocarlo desde un directorio fuera del global.json de SDK 7,
# pasando rutas absolutas al proyecto Trazar.csproj, al backend y a backend_metodos.json.
python scripts/analizar-dxncomas/trazar_web.py --carpeta artifacts/analisis-dxncomas-20261019
./scripts/analizar-dxncomas/validar-paquete.ps1
./scripts/analizar-dxncomas/validar-sql2008.ps1
```

`validar-paquete.ps1` reconstruye el esquema capturado en una base temporal de nombre único, usa exclusivamente datos sintéticos para probar la inicialización y elimina esa base al terminar. Requiere permisos de creación/eliminación de bases en la instancia de ensayo; no debe apuntarse a un servidor ajeno al ensayo. No ejecuta procedimientos de venta ni de emisión.
