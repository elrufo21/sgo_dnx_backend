# Almacenamiento local de imágenes

Las imágenes adjuntas en **Caja Chica** se guardan en la computadora servidor, en `D:\SGO\media`. La API las publica en la ruta `/media`; la base de datos conserva solo la ruta virtual, por ejemplo `/media/caja-chica/2026/09/<archivo>.webp`.

En desarrollo se guardan automáticamente en `src\Api\App_Data\media`, por lo que no se requiere la unidad `D:` local.

## Configuración en IIS

La sección `LocalMedia` del `api/appsettings.json` define el disco y la ruta pública. El Application Pool del sitio **SGO API** debe tener permiso **Modificar** sobre `D:\SGO\media`. La carpeta se crea al iniciar la API.

El sitio web resuelve las rutas `/media/...` de Caja Chica contra la URL de la API. Las URL completas existentes de Cloudinary permanecen compatibles. Los archivos CPE, Productos y Personal continúan en su almacenamiento actual.

## Operación

- Se permiten JPG, PNG y WEBP de hasta 5 MB.
- Cada archivo recibe un UUID; no se usa el nombre enviado por el usuario.
- Incluir `D:\SGO\media` en la copia de seguridad del servidor junto con la base de datos.

## Movimiento de Caja Chica

`POST /api/v1/PettyCashMovement/{id}/image` permite adjuntar una imagen a un movimiento manual existente. Requiere `usuarioId` e `imagen` en `multipart/form-data`, valida JPG/PNG/WEBP hasta 5 MB y solo actualiza `CajaDetalle.RutaImagen` cuando aún está vacía. El registro y sus datos no se editan desde este flujo; la imagen existente tampoco se reemplaza ni se borra. Usa la columna existente y no requiere cambios SQL.
