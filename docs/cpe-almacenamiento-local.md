# XML y CDR de facturas en almacenamiento local

Las facturas aceptadas guardan su XML firmado y CDR en `LocalMedia:RootPath/cpe`, con nombres únicos. La configuración de COMAS usa `C:\SGO\media`; ICA debe conservar su propia configuración. Las referencias `/media/cpe/<identificador>.xml` o `.zip` se guardan en `DocumentoVentaCpeWeb` y el correo lee el archivo directamente del servidor. El correo sigue aceptando enlaces HTTP de documentos anteriores. Las rutas de trabajo CPE y la configuración del OSE siguen siendo necesarias para generar el XML.

El grupo de aplicaciones de la API necesita permiso de lectura y escritura en la carpeta de medios. Conservarla al actualizar el sitio e incluirla en las copias de seguridad junto con la base de datos. Las rutas de medios se sirven por la API, igual que las imágenes; proteger el acceso de red al servidor. Cada sede mantiene su propia carpeta y copias de seguridad.

La aceptación de SUNAT/OSE y el guardado de archivos son operaciones distintas: si falla el guardado, la factura puede quedar aceptada. Revisar el registro de la API para el aviso `OSE aceptó la factura, pero falló la subida de XML/CDR al storage`. Una vez instalado el backend, verificar una factura nueva, sus dos referencias, los archivos físicos y el correo con ambos adjuntos. No se migran archivos anteriores ni se requiere modificar objetos SQL.

## Recuperar CDR de una factura anterior

El botón **Recuperar CDR** está oculto por ahora mediante `MOSTRAR_RECUPERAR_CDR` en `HtmlCaptureSalePage.tsx`; la API permanece disponible para trabajos posteriores. La API consulta `getStatusCdr` al OSE configurado con las credenciales y ambiente de la compañía del usuario, valida que el CDR corresponda a la serie y número, lo guarda en medios locales y registra su referencia en `DocumentoVentaCpeWeb`. Si ya hay una referencia, la conserva. No reenvía ni modifica el estado de la factura y no recupera el XML de emisión. La acción requiere permisos de ventas y la factura debe pertenecer a la compañía de la sesión.

La consulta envía el `SOAPAction` `http://service.sunat.gob.pe/getStatusCdr` declarado en el WSDL de Nubefact. Ante un error informa el código HTTP o el código de estado del OSE cuando está disponible, sin exponer credenciales. La prueba `dotnet run -c Release --project scripts/verificar-cpe-local/VerificarCpeLocal.csproj` usa un servidor simulado y verifica el encabezado, recuperación y rechazo de respuestas inválidas; no consulta el OSE real.

Cuando el OSE responde HTTP 500 con un error SOAP, el aplicativo muestra el código y descripción del error después de ocultar las credenciales enviadas; si no recibe un SOAP válido, informa el código HTTP. La prueba simulada incluye un error SOAP HTTP 500 y comprueba que no se exponga la clave.
