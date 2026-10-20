# Paquete SQL de migración web para DXNCOMAS

Estos scripts preparan en `DXNCOMAS` los objetos requeridos por los flujos que el frontend actual alcanza y llama. La selección sigue la cadena frontend → endpoint → backend → SQL documentada en [el análisis de alcance](analisis-dxncomas-migracion-web-20261018.md); no toma todos los objetos que quedaron en el backend.

Revisado contra ambas bases y el código actual el **19/10/2026**. Los SQL se entregan por separado, compatibles con SQL Server 2008, y se ejecutan manualmente en el orden indicado abajo. La sintaxis pasó el analizador TSql100Parser; la ejecución de ensayo fue en SQL Server 16 con compatibilidad 100, no en un motor 2008 real. El detalle de pendientes está en [revisión del pase a COMAS](revision-pase-dxncomas-20261019.md). Estos cambios no han sido aplicados a DXNCOMAS.

## Archivos y orden

Los originales están en `scripts/sql/dxncomas-20261019/`. Para entregarlos separados y con nombres claros, están copiados en `artifacts/entregas/DXNCOMAS_SQL_separados_20261019/`. Ejecuta cada archivo manualmente, en este orden, sobre `DXNCOMAS`:

1. `01_compatibilidad_procedimientos_existentes.sql`: explicita las columnas originales en seis procedimientos propios de COMAS. Va primero para que agregar columnas no altere sus inserciones. Conserva cálculos y valores y aborta si las definiciones cambiaron.
2. `02_tablas.sql`: crea `dbo.Indicador` y `dbo.DocumentoVentaCpeWeb`, con claves, relaciones e índices.
3. `03_columnas.sql`: agrega 14 columnas faltantes a tablas existentes. `NotaPedido.Hora` y `NotaPedido.Almacen` son complementarias.
4. `04_procedimientos_web.sql`: instala **44 procedimientos** requeridos por la web.
5. `05_configuracion_inicial.sql`: crea 24 indicadores raíz por compañía, solo si no existen; toma renovaciones, días de depósito y credenciales SOL de la propia COMAS.

`05_diagnostico_dxncomas.sql` es una consulta opcional de solo lectura. `06_indices_web_opcional.sql` agrega dos índices de lectura y también es opcional. No forman parte de los cinco pasos anteriores. **No necesitas ejecutar `instalar_paquete_dxncomas.sql`.**

El ZIP `artifacts/entregas/DXNCOMAS_SQL_separados_SQL2008_20261019.zip` contiene únicamente estos cinco archivos y `ORDEN.txt`.

Antes de ejecutar estos SQL, respaldar COMAS y revisar los valores iniciales de `05_configuracion_inicial.sql`. Cada archivo selecciona DXNCOMAS explícitamente. Se verifican tablas/columnas/índices antes de crear. Para procedimientos se crea un cuerpo vacío únicamente si el objeto no existe y después se usa `ALTER PROCEDURE`, conservando el objeto y sus permisos. Los errores usan `RAISERROR`; las huellas de compatibilidad usan SHA1 por bloques menores de 8000 bytes. No se usa sintaxis posterior a SQL Server 2008 en los scripts entregados. El diagnóstico informa pendientes; no certifica que estén resueltos los nueve contratos excluidos.

## Exclusiones solicitadas

El archivo de procedimientos **no contiene** estos nueve procedimientos que la web llama pero faltan en ambas copias. Conservan la exclusión del paquete anterior; se debe resolver su contrato antes de habilitar las funciones afectadas:

- `uspEliminarCategoria`
- `uspEliminarProducto`
- `uspEliminarProveedor`
- `uspGuardarUnidadMedidaProducto`
- `uspInsertarCategoria`
- `uspInsertarCuentaProveedor`
- `uspInsertarProveedor`
- `uspInsertarUsuario`
- `uspListarComprasweb`

Tampoco instala objetos que solo aparecen en el backend sin consumidor actual, ni crea `BLOQUE`, `DetalleBloque`, `Stock` o `RentaMensual`. `uspCruzeOBS` ya existe en COMAS; su diferencia de definición queda para revisión aparte y no se reemplaza automáticamente.

## Datos y compatibilidad

El paquete no transfiere datos ni configuraciones de ICA. El archivo 04 inserta configuraciones iniciales y copia únicamente valores propios de COMAS dentro de la misma base. No modifica `Compania`, usuarios, asistencia, ventas, cajas, series ni correlativos. Tampoco elimina las columnas históricas de renovación.

Valores iniciales: asistencia exigida (`1`), múltiples cajas desactivado (`0`), captura HTML desactivada (`0`), boleta por lote activada (`1`), descuento `0` y CPE en **beta (`3`)**. Deben revisarse para COMAS. Reejecutar 04 no cambia indicadores existentes; un cambio posterior se hace desde Configuración o mediante un script específico revisado.

Completar PFX real y clave, destinatarios administrativos, SMTP en `EmailSettings`, configuración SUNAT/SIRE, permisos por área, series/correlativos, nombre comercial y almacenamiento. No se conceden permisos automáticamente ni se interpreta el nombre histórico del certificado como su contenido Base64.

El archivo 00 cubre los seis procedimientos antiguos con `INSERT ... VALUES` sin lista de columnas: `ingresarProducto`, `ingresarUsuario`, `InsertarUM`, `uspinsertarNotaB`, `uspInsertarPagoVarios` y `uspinsertarRB`. Se conservan sus definiciones de COMAS; solo se agregan las listas de columnas originales. Esta corrección evita que agregar columnas rompa las inserciones del escritorio.

El paquete se ejecutó dos veces en una base vacía reconstruida desde el esquema de COMAS: pasó la transacción de instalación, la idempotencia, la preservación de configuración y el enlace de los 44 procedimientos mediante `sp_refreshsqlmodule`. La base temporal se eliminó. Esto verifica estructura y compilación; siguen pendientes las pruebas funcionales con datos de ensayo y la resolución de los nueve contratos. Ver la evidencia en `artifacts/analisis-dxncomas-20261019/validacion_paquete.json`.

La compatibilidad de estos archivos no certifica toda la API contra SQL Server 2008: se detectaron consultas directas con funciones posteriores a esa versión, por ejemplo `CONCAT` en el envío de correo y `TRY_CONVERT` en la búsqueda de documentos. Deben adaptarse y probarse antes de poner toda la web contra un motor 2008. Ver el detalle de esta limitación en el informe del pase.
