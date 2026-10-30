# XML y CDR de facturas en almacenamiento local

Las facturas aceptadas guardan su XML firmado y CDR en `LocalMedia:RootPath/cpe`, con nombres únicos. La configuración de COMAS usa `C:\SGO\media`; ICA debe conservar su propia configuración. Las referencias `/media/cpe/<identificador>.xml` o `.zip` se guardan en `DocumentoVentaCpeWeb` y el correo lee el archivo directamente del servidor. El correo sigue aceptando enlaces HTTP de documentos anteriores. Las rutas de trabajo CPE y la configuración del OSE siguen siendo necesarias para generar el XML.

El grupo de aplicaciones de la API necesita permiso de lectura y escritura en la carpeta de medios. Conservarla al actualizar el sitio e incluirla en las copias de seguridad junto con la base de datos. Las rutas de medios se sirven por la API, igual que las imágenes; proteger el acceso de red al servidor. Cada sede mantiene su propia carpeta y copias de seguridad.

La aceptación de SUNAT/OSE y el guardado de archivos son operaciones distintas: si falla el guardado, la factura puede quedar aceptada. Revisar el registro de la API para el aviso `OSE aceptó la factura, pero falló la subida de XML/CDR al storage`. Una vez instalado el backend, verificar una factura nueva, sus dos referencias, los archivos físicos y el correo con ambos adjuntos. No se migran archivos anteriores ni se requiere modificar objetos SQL.
