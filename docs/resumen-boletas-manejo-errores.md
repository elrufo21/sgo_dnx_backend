# Errores del resumen de boletas

Los endpoints de envío (`/Nota/resumen/enviar` y `/Nota/resumen/enviar-baja`) registran el resumen solo cuando SUNAT acepta el envío. Una respuesta rechazada o fallida se devuelve al navegador sin actualizar `DocumentoVenta` ni registrar un resumen.

Para una anulación de boletas, `/Nota/resumen/enviar-baja` normaliza el resumen con `STATUS = 3` y lo envía como resumen RC con `statu = 3`. El cliente debe incluir los importes originales positivos de cada boleta en el detalle y los totales positivos en la cabecera. Al registrar la respuesta aceptada, `uspinsertarRBweb` aplica signo negativo a `SubTotal`, `IGV`, `ICBPER` y `Total`, y guarda el resumen con `ESTADO = 'B'`. Si se omiten los importes, el backend los considera cero y la inversión produce cero; no se debe invertir el signo en el cliente ni en el XML.

En la consulta de ticket (`/Nota/resumen/consultar` y `/Nota/resumen/consultar-baja`), una excepción, una respuesta SOAP de error, un código SUNAT vacío o la ausencia de ticket se muestra como error sin ejecutar procedimientos de retorno ni actualizar la base de datos. Una respuesta válida de SUNAT sí se conserva junto con el CDR para consulta posterior.

La pantalla presenta un solo mensaje de error, sin concatenar el código SUNAT ni información de persistencia. Las respuestas aceptadas mantienen el flujo normal de registro y consulta.

El rango de comprobantes persistido y presentado por la API usa la nomenclatura del escritorio: `BV1-40608 al BV1-40647`. Al registrar un envío se compactan los ceros de la serie y del correlativo; si llega un rango histórico o en formato legado, se normalizan sus extremos sin alterar sus números.

## Listado de boletas pendientes

`uspListaDocumentosWEB` selecciona la fecha pendiente más antigua de la compañía, pero solo entre fechas anteriores a hoy (`DocuEmision < CONVERT(date, GETDATE())`). Las boletas emitidas hoy no se listan para el resumen del día: quedan disponibles desde mañana. La validación del endpoint aplica el mismo límite para impedir el envío manual de boletas del día actual.

Antes de cerrar caja, el backend bloquea si existen boletas anteriores a hoy con `EstadoSunat = 'PENDIENTE'`, boletas anuladas que aún requieren resumen de baja (`DocuEstado = 'ANULADO'` y `EstadoSunat = 'ENVIADO'`), o resúmenes enviados cuyo `CodigoSunat` todavía es nulo, vacío o espacios (aún no consultados). Una vez guardada una respuesta válida de consulta, el código deja de estar vacío y no bloquea por esta condición, aunque SUNAT/OSE haya rechazado el resumen; el rechazo permanece registrado para su regularización. Los documentos de hoy se mantienen fuera de esta validación hasta mañana. El control es por compañía porque el resumen se genera por compañía y fecha, no por caja individual.

La variante convierte `ICBPER` nulo a cero antes de concatenar cada fila; si se concatenara el valor nulo directamente, la fila completa podría desaparecer del resultado. Para bases donde el procedimiento ya fue instalado, usar el script incremental `scripts/sql/20261020_fix_uspListaDocumentosWEB_excluir_hoy.sql`; para instalaciones nuevas, está actualizado `scripts/sql/20261016_uspListaDocumentosWEB_icbper.sql`. El procedimiento de escritorio `uspListaDocumentos` permanece intacto. Ambos scripts evitan `CREATE OR ALTER` y `TRY_CONVERT` para mantener compatibilidad con SQL Server 2008.

El parser del cliente admite el separador de filas `¬` y su variante con mojibake `Â¬`; así el prefijo de codificación no termina pegado al último campo, como `EstadoSunat`.

El procedimiento filtra por tipo de documento y `EstadoSunat = 'PENDIENTE'`; no filtra el estado local `DocuEstado`. Este cambio afecta qué documentos se listan, pero no modifica estados ni los envía al OSE/SUNAT.

Antes de enviar un resumen RC normal (`STATUS = 1`), el backend compara los `docuId` recibidos con todas las boletas `EstadoSunat = 'PENDIENTE'` de la misma compañía y `FECHA_REFERENCIA`; las emitidas hoy siguen habilitándose desde mañana. Para una baja RC (`STATUS = 3`), compara contra las boletas `DocuEstado = 'ANULADO'` y `EstadoSunat = 'ENVIADO'` de la fecha más antigua pendiente, siguiendo la misma regla de `uspListaBajas`. En ambos flujos, si falta, sobra, se repite o dejó de ser elegible algún documento, devuelve conflicto antes de llamar a SUNAT. Así se detectan listas incompletas o desactualizadas sin cambiar los estados de los documentos.

## Bajas de boletas por fecha de emisión

`uspListaBajas` devuelve solo las boletas anuladas/enviadas de la fecha de emisión más antigua pendiente de comunicar. Así, el resumen de baja no mezcla documentos de fechas distintas bajo una misma `FECHA_REFERENCIA`. Ejecutar `scripts/sql/20261006_fix_uspListaBajas_agrupar_fecha.sql` en la base conectada al backend. Después de enviar la baja, consultar su ticket y actualizar la lista antes de enviar la siguiente fecha.
