# SGO DXN Capture

Extension Chrome/Edge para enviar ventas y resúmenes Cash Bill visibles en DXN OBS al SGO web.

## Instalar

1. Abrir `chrome://extensions`.
2. Activar `Developer mode`.
3. Clic en `Load unpacked`.
4. Seleccionar esta carpeta: `C:\Users\User\Desktop\desarrollo_dnx\sgo_dnx_extension`.

## Uso

1. Abrir el comprobante/venta en `https://obs6.dxn2u.com`.
2. Clic en `Enviar a SGO`.
3. La extension enfoca una pestaña SGO abierta y carga los productos.
4. Si no hay una pestaña SGO abierta, abre `http://192.168.1.38:8080/sales/html_capture/new`.

La captura queda disponible mientras la venta no se confirme. Cuando SGO registra la venta correctamente, la extensión descarta esa captura para que no vuelva a cargar al regresar al formulario.

## Resumen OBS e IOC por cajero

1. En DXN abre el reporte **Centro de servicio - Resumen de Factura** con tipo **Resumen sin mantenimiento de Cash Bill**.
2. Cuando se muestre la tabla, pulsa **Enviar resumen a SGO**.
3. La extensión abre `http://192.168.1.38:8080/sales/obs_capture` y guarda fecha, miembro, código, transacción e importe. Una transacción con `RS` es IOC; las demás se registran como OBS, igual que el escritorio.

La extensión funciona en producción con `http://192.168.1.38:8080` y también en desarrollo local con `http://localhost:5173`. En producción sigue abriendo la dirección del servidor si no existe una pestaña SGO abierta; para probar localmente, abre primero la pantalla de captura en `localhost:5173`.

Después de modificar o actualizar la extensión, pulsa **Recargar** en `chrome://extensions` para que Chrome aplique los permisos nuevos de `localhost`.

Si el botón quedara en **Enviando...**, recarga la extensión: los errores de entrega ahora devuelven un aviso en lugar de dejar el botón bloqueado.
