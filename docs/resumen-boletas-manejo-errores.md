# Errores del resumen de boletas

Los endpoints de envío (`/Nota/resumen/enviar` y `/Nota/resumen/enviar-baja`) registran el resumen solo cuando SUNAT acepta el envío. Una respuesta rechazada o fallida se devuelve al navegador sin actualizar `DocumentoVenta` ni registrar un resumen.

Para una anulación de boletas, `/Nota/resumen/enviar-baja` normaliza el resumen con `STATUS = 3` y lo envía como resumen RC con `statu = 3`. El cliente debe incluir los importes originales positivos de cada boleta en el detalle y los totales positivos en la cabecera. Al registrar la respuesta aceptada, `uspinsertarRBweb` aplica signo negativo a `SubTotal`, `IGV`, `ICBPER` y `Total`, y guarda el resumen con `ESTADO = 'B'`. Si se omiten los importes, el backend los considera cero y la inversión produce cero; no se debe invertir el signo en el cliente ni en el XML.

En la consulta de ticket (`/Nota/resumen/consultar` y `/Nota/resumen/consultar-baja`), una excepción, una respuesta SOAP de error, un código SUNAT vacío o la ausencia de ticket se muestra como error sin ejecutar procedimientos de retorno ni actualizar la base de datos. Una respuesta válida de SUNAT sí se conserva junto con el CDR para consulta posterior.

La pantalla presenta un solo mensaje de error, sin concatenar el código SUNAT ni información de persistencia. Las respuestas aceptadas mantienen el flujo normal de registro y consulta.

El rango de comprobantes persistido y presentado por la API usa la nomenclatura del escritorio: `BV1-40608 al BV1-40647`. Al registrar un envío se compactan los ceros de la serie y del correlativo; si llega un rango histórico o en formato legado, se normalizan sus extremos sin alterar sus números.

## Listado de boletas pendientes

`uspListaDocumentos` selecciona la fecha pendiente más antigua de la compañía y devuelve las boletas de esa fecha. El límite superior incluye la fecha actual (`DocuEmision <= CONVERT(date, GETDATE())`), por lo que también aparecen las boletas emitidas hoy. Para actualizar una base que aún tenga el filtro anterior (`<`), ejecutar `scripts/sql/20261006_fix_uspListaDocumentos_incluir_hoy.sql` en la base conectada al backend.

El procedimiento filtra por tipo de documento y `EstadoSunat = 'PENDIENTE'`; no filtra el estado local `DocuEstado`. Este cambio afecta qué documentos se listan, pero no modifica estados ni los envía al OSE/SUNAT.

## Bajas de boletas por fecha de emisión

`uspListaBajas` devuelve solo las boletas anuladas/enviadas de la fecha de emisión más antigua pendiente de comunicar. Así, el resumen de baja no mezcla documentos de fechas distintas bajo una misma `FECHA_REFERENCIA`. Ejecutar `scripts/sql/20261006_fix_uspListaBajas_agrupar_fecha.sql` en la base conectada al backend. Después de enviar la baja, consultar su ticket y actualizar la lista antes de enviar la siguiente fecha.
