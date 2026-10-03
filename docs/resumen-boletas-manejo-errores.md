# Errores del resumen de boletas

Los endpoints de envío (`/Nota/resumen/enviar` y `/Nota/resumen/enviar-baja`) registran el resumen solo cuando SUNAT acepta el envío. Una respuesta rechazada o fallida se devuelve al navegador sin actualizar `DocumentoVenta` ni registrar un resumen.

Para una anulación de boletas, `/Nota/resumen/enviar-baja` normaliza el resumen con `STATUS = 3` y lo envía como resumen RC con `statu = 3`. Los importes enviados al OSE mantienen los valores originales de las boletas. Al registrar la respuesta aceptada, `uspinsertarRBweb` aplica signo negativo a `SubTotal`, `IGV`, `ICBPER` y `Total`, y guarda el resumen con `ESTADO = 'B'`. No se debe volver a invertir el signo en el controlador ni en el XML.

En la consulta de ticket (`/Nota/resumen/consultar` y `/Nota/resumen/consultar-baja`), una excepción, una respuesta SOAP de error, un código SUNAT vacío o la ausencia de ticket se muestra como error sin ejecutar procedimientos de retorno ni actualizar la base de datos. Una respuesta válida de SUNAT sí se conserva junto con el CDR para consulta posterior.

La pantalla presenta un solo mensaje de error, sin concatenar el código SUNAT ni información de persistencia. Las respuestas aceptadas mantienen el flujo normal de registro y consulta.

El rango de comprobantes persistido y presentado por la API usa la nomenclatura del escritorio: `BV1-40608 al BV1-40647`. Al registrar un envío se compactan los ceros de la serie y del correlativo; si llega un rango histórico o en formato legado, se normalizan sus extremos sin alterar sus números.
