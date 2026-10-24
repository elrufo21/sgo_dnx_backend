# Análisis de fechas: NotaPedido, DocumentoVenta y TABLAOBS

Fecha: 2026-10-23. Alcance: análisis estático de los SQL, backend y frontend del repositorio. No se conectó a SQL, ejecutó consultas, modificó datos ni cambió código funcional. La versión y los índices realmente instalados en ICA/COMAS requieren comprobación del DBA.

## Formato enviado y almacenamiento

`20261023` representa 23 de octubre de 2026 si se interpreta como `yyyyMMdd`. En SQL se puede interpretar explícitamente mediante `CONVERT(date, '20261023', 112)`. Debe ser una cadena entre comillas; el número entero `20261023` no es un parámetro de fecha equivalente.

Cuando el destino es `date` o `datetime`, SQL almacena un valor temporal, no el formato de presentación introducido. Escribir una fecha válida como `20261023` no reduce el almacenamiento ni acelera por sí solo las búsquedas frente a la misma fecha recibida de otra forma y convertida correctamente. `date` ocupa 3 bytes y `datetime`, 8; guardar ocho caracteres o un entero cambia el tipo, las validaciones y las operaciones disponibles. No se propone ese cambio.

El frontend de los tres listados envía `YYYY-MM-DD`. Conviene conservar ese contrato y usar parámetros SQL temporales. La aceptación del formato compacto por el model binding de .NET no se comprobó; que SQL admita el estilo 112 no implica que las rutas HTTP lo acepten. El endpoint OBS utiliza `DateOnly` y parámetros `SqlDbType.Date`.

## Situación encontrada

| Área | Evidencia local | Evaluación |
| --- | --- | --- |
| NotaPedido | `scripts/sql/bdactual.sql` declara `NotaFecha datetime` y `NotaFechaPago date`. `listaNotaPedido`, también incluido en `scripts/sql/dxncomas-20261019/03_procedimientos_dxncomas.sql`, filtra `NotaFecha >= @FechaInicio AND NotaFecha < DATEADD(day, 1, @FechaFin)`. | El rango incluye todo el día final y mantiene la columna sin transformar. Es una forma adecuada para permitir acceso por índice. La hora de `NotaFecha` se presenta en el listado: convertir esa columna a `date` eliminaría información utilizada. |
| DocumentoVenta | La copia de esquema declara `DocuEmision date` y `DocuRegistro datetime`. `LDdocumentosweb`, en `20261007_pdt_empresa_estado_anulado.sql`, filtra directamente `DocuEmision` con inicio inclusivo y fin exclusivo. | El filtro ya tiene la forma adecuada. Formatear con estilo 103 en el `SELECT` sirve para presentar los resultados; no es el mismo problema que formatear la columna en el `WHERE`. |
| TABLAOBS | `ObsCaptureController.cs` recibe fechas con `DateOnly`, guarda mediante `SqlDbType.Date` y filtra `TipoVenta = @TipoVenta AND FechaTransaccion BETWEEN @FechaInicio AND @FechaFin`. | La API trata la fecha de transacción como día sin hora. No se localizó una definición física suficiente para confirmar el tipo instalado de la columna. Si es `date`, el rango es correcto. Si es `datetime` con horas distintas de medianoche, el límite final actual excluye esas filas del último día. |

Estas son estructuras y procedimientos del repositorio, no una certificación del esquema instalado en ambos servidores.

## Qué cambia realmente el rendimiento

### 1. Índices con claves apropiadas para el filtro

El paquete `scripts/sql/20261020_optimizacion_listados/01_indices_listados.sql`, cuya aplicación el usuario confirmó para ambas bases, define:

- NotaPedido: `(CajaId, NotaTransaccion)`. Atiende cruces de Caja, no aporta una clave inicial de fecha al listado general.
- TABLAOBS: `(NotaTransaccion, TipoVenta) INCLUDE (Importe)`. Atiende cruces por transacción, no el filtro principal de OBS por tipo y rango de fechas.
- DocumentoVenta: `(TipoCodigo, DocuEmision, DocuId)`. Es apropiado para consultas que fijan `TipoCodigo`, como ciertos listados de facturas. `LDdocumentosweb` no fija ese tipo; el índice puede contribuir como recorrido, pero no debe asumirse que brinda la misma búsqueda por fecha que un índice cuya primera clave sea `DocuEmision`.

No se puede concluir que falten índices en producción: pueden existir otros creados por el DBA. Primero revisar claves, columnas incluidas, estadísticas y planes; no crear duplicados por nombre.

Candidatos para evaluar, no DDL autorizado ni aplicado:

| Consulta actual | Claves candidatas | Precaución |
| --- | --- | --- |
| NotaPedido por rango de fecha | `(NotaFecha, NotaId)` | El listado ordena por `NotaId DESC`, por lo que un índice encabezado por fecha puede seguir necesitando ordenamiento cuando incluye varias fechas. |
| Último estado de documento de cada nota | `(NotaId, DocuId DESC)` con `TipoCodigo` y `EstadoSunat` disponibles en el índice | La subconsulta de `listaNotaPedido` busca el último documento de tipo 01/03 por nota. El índice de facturas no empieza por `NotaId`. Medir el coste de esa subconsulta por cada fila. |
| Documentos de todos los tipos por rango | `(DocuEmision)` con las claves adicionales según el plan y orden requerido | El orden actual incluye una concatenación de serie y número; un índice por fecha no garantiza eliminar ese ordenamiento. |
| OBS por tipo y rango | `(TipoVenta, FechaTransaccion, ID)` | Igualdad por tipo primero y rango después. Evaluar las columnas incluidas con el tamaño de la tabla y el coste de las escrituras. |

Si se incorpora un filtro obligatorio de compañía, el diseño del índice debe revisarse según la consulta real; no anteponer `CompaniaId` a un índice cuya consulta actual no lo filtra.

### 2. Filtrar sin convertir cada fecha a texto

Para obtener el 23/10 completo, el patrón recomendado es:

```sql
-- Ejemplo de lectura; no ejecutado.
DECLARE @Inicio date = CONVERT(date, '20261023', 112);
DECLARE @Fin date = @Inicio;

SELECT n.NotaId, n.NotaFecha
FROM dbo.NotaPedido AS n
WHERE n.NotaFecha >= @Inicio
  AND n.NotaFecha < DATEADD(day, 1, @Fin);
```

Evitar transformar la columna a texto en el filtro, por ejemplo `CONVERT(char(8), NotaFecha, 112) = '20261023'`: obliga a evaluar la expresión y dificulta aprovechar un índice ordinario por la fecha. Transformar una constante o parámetro antes de comparar no tiene ese mismo coste por fila. Los listados web principales revisados de notas y documentos ya usan el patrón de rango adecuado; hay SQL históricos con conversiones sobre la columna que no deben confundirse con los procedimientos web actuales.

`BETWEEN` con el mismo día como inicio y fin no cubre todas las horas de un `datetime`. La alternativa de fin exclusivo evita depender de un valor artificial como `23:59:59.997`.

### 3. Cantidad descargada y paginación

- NotaPedido: el store consulta `/Nota/lista-cadena`; `listaNotaPedido` serializa todas las filas del rango mediante `FOR XML PATH`. Además, `NotaPedidoRepository.ListarAsync` recibe `page/pageSize` pero deriva a `ListarCadenaAsync` y no los aplica a esa consulta.
- Documentos/PDT: `/Nota/ld-documentos` obtiene todo el rango serializado por `LDdocumentosweb`.
- OBS: el controlador construye una lista con todas las filas del rango y la devuelve completa.

Los tres componentes de listado revisados usan paginación local de DataTable, sin un callback de paginación remota en esos usos. Por tanto, ver 20 filas en pantalla no significa que SQL haya obtenido solo 20.

Un día con pocas ventas puede responder rápido; varios meses pueden aumentar lecturas, joins, ordenamientos, serialización, transferencia y trabajo del navegador. Cambiar los separadores de la fecha no resuelve esos costes. Para rangos grandes, evaluar paginación real en SQL/API, con totalizadores y exportación que conserven su alcance funcional. Los valores iniciales actuales ya limitan las consultas: notas y OBS al día actual, PDT al mes.

## Fechas con significados diferentes

No equiparar automáticamente `NotaFecha` (registro/emisión de la nota), `NotaFechaPago` (pago), `DocuRegistro` (registro), `DocuEmision` (emisión) y `TABLAOBS.FechaTransaccion` (día de la transacción capturada).

Una transacción OBS de un día anterior puede capturarse o registrarse después. Comparar los tres listados por el mismo día puede producir conjuntos distintos aunque todos sus filtros sean correctos. La regla de negocio debe definir qué fecha se compara.

OBS cruza con NotaPedido solo por `NotaTransaccion`. Si hay varias notas con el mismo número, puede multiplicar filas y alterar importes o tiempos. Antes de agregar una condición de fecha al join o una restricción única, el DBA debe comprobar la unicidad y el alcance por compañía/serie; una condición de fecha añadida sin esa revisión podría ocultar capturas registradas otro día.

`NotaPedido.FechaEdita` aparece como `varchar(60)` en la copia de esquema. Es un asunto distinto: si se requiere ordenar o filtrar masivamente por esa fecha, hay que revisar formatos y datos vacíos antes de proponer una migración. No hace falta cambiarla para mejorar los tres filtros principales analizados.

## Orden de trabajo propuesto

1. DBA: confirmar los tipos instalados y los procedimientos activos en ICA y COMAS; revisar el tipo real de `TABLAOBS.FechaTransaccion`.
2. DBA: inventariar índices equivalentes y capturar planes reales, lecturas y tiempos con rangos de un día y un mes representativos, en un entorno o ventana acordados.
3. Revisar OBS: confirmar si `BETWEEN` es correcto con el tipo real y si el cruce por transacción es único.
4. Evaluar los índices candidatos usando esos planes. Medir el coste adicional de guardar ventas y capturas antes de incorporarlos.
5. Si el volumen transferido sigue siendo alto, diseñar paginación remota preservando totalizadores y exportaciones.

No se propone almacenar fechas como texto ni cambiar `datetime` a `date` en NotaPedido. No se estima un porcentaje de mejora sin mediciones reales.

## Referencias

- Backend: `src/Infrastructure/Repositories/NotaPedidoRepository.cs`, `src/Api/Controllers/ObsCaptureController.cs`.
- SQL: `scripts/sql/bdactual.sql`, `scripts/sql/dxncomas-20261019/03_procedimientos_dxncomas.sql`, `scripts/sql/20261007_pdt_empresa_estado_anulado.sql`, `scripts/sql/20261020_optimizacion_listados/01_indices_listados.sql`.
- Frontend: `src/store/orderNote/orderNote.store.ts`, `src/features/orderNotes/pages/orderNotesList.tsx`, `src/features/accounting/pages/PdtCompanyPage.tsx`, `src/features/sales/pages/ObsCashierCapturePage.tsx`.
- Microsoft: [tipos temporales y almacenamiento](https://learn.microsoft.com/en-us/sql/t-sql/functions/date-and-time-data-types-and-functions-transact-sql), [estilos de conversión](https://learn.microsoft.com/es-es/sql/t-sql/functions/cast-and-convert-transact-sql), [diseño de índices](https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-index-design-guide).
