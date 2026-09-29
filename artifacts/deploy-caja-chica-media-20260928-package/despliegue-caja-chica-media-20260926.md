# Despliegue: imágenes locales de Caja Chica

Este cambio aplica únicamente al módulo **Movimiento de Caja Chica**. No requiere scripts SQL.

## Antes de desplegar

1. Respaldar las carpetas actuales de API y Web.
2. Crear `D:\SGO\media` en el servidor si aún no existe.
3. Otorgar permiso **Modificar** a la identidad del Application Pool `SGO_DXN_Backend` sobre `D:\SGO\media`.

## API

1. Detener el Application Pool `SGO_DXN_Backend`.
2. Copiar el contenido de la carpeta `api` del paquete al directorio físico del sitio API, sin reemplazar el `appsettings.json` de producción.
3. Agregar al `appsettings.json` de producción:

```json
"LocalMedia": {
  "RootPath": "D:\\SGO\\media",
  "RequestPath": "/media"
}
```

4. Iniciar el Application Pool.

## Web

1. Copiar el contenido de la carpeta `web` al directorio físico del sitio web IIS.
2. Recargar la página en el navegador con `Ctrl+F5`.

## Verificación

Registrar un movimiento de Caja Chica con imagen. Debe crearse un archivo en `D:\SGO\media\caja-chica\...`, guardarse una ruta `/media/caja-chica/...` en `CajaDetalle.RutaImagen` y mostrarse desde la web. Abrir un movimiento manual existente sin imagen, seleccionar un archivo, elegir otro antes de guardar y confirmar con **Guardar comprobante**; comprobar que solo la imagen confirmada queda guardada. En otro movimiento que ya tenga imagen, confirmar que no aparece la opción de adjuntar y que la API rechaza un segundo intento. No requiere scripts SQL.
