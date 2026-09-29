# Errores del resumen de boletas

Los endpoints de envío (`/Nota/resumen/enviar` y `/Nota/resumen/enviar-baja`) registran el resumen solo cuando SUNAT acepta el envío. Una respuesta rechazada o fallida se devuelve al navegador sin actualizar `DocumentoVenta` ni registrar un resumen.

En la consulta de ticket (`/Nota/resumen/consultar` y `/Nota/resumen/consultar-baja`), una excepción, una respuesta SOAP de error, un código SUNAT vacío o la ausencia de ticket se muestra como error sin ejecutar procedimientos de retorno ni actualizar la base de datos. Una respuesta válida de SUNAT sí se conserva junto con el CDR para consulta posterior.

La pantalla presenta un solo mensaje de error, sin concatenar el código SUNAT ni información de persistencia. Las respuestas aceptadas mantienen el flujo normal de registro y consulta.
