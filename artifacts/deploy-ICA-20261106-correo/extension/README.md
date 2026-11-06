# SGO DXN Capture - ProducciÃ³n

Extension Chrome/Edge para enviar ventas y resÃºmenes Cash Bill visibles en DXN OBS al SGO web.

## Instalar

1. Abrir `chrome://extensions`.
2. Activar `Developer mode`.
3. Clic en `Load unpacked`.
4. Seleccionar la carpeta `sgo_dnx_extension` para instalar la versiÃ³n de producciÃ³n.

Para desarrollo, carga tambiÃ©n `sgo_dnx_extension_dev`. Puedes tener las dos instaladas y elegir el botÃ³n del entorno: **Enviar a SGO (ProducciÃ³n)** o **Enviar a SGO (Desarrollo)**. La versiÃ³n de desarrollo solo busca pestaÃ±as en `localhost:5173`.

## Uso

1. Abrir el comprobante/venta en `https://obs6.dxn2u.com`.
2. Clic en `Enviar a SGO (ProducciÃ³n)`.
3. La extension enfoca una pestaÃ±a SGO abierta y carga los productos.
4. Si no hay una pestaÃ±a SGO abierta, abre `http://192.168.1.38:8080/sales/html_capture/new`.

La captura queda disponible mientras la venta no se confirme. Cuando SGO registra la venta correctamente, la extensiÃ³n descarta esa captura para que no vuelva a cargar al regresar al formulario.

## Resumen OBS e IOC por cajero

1. En DXN abre el reporte **Centro de servicio - Resumen de Factura** con tipo **Resumen sin mantenimiento de Cash Bill**.
2. Cuando se muestre la tabla, pulsa **Enviar resumen a SGO (ProducciÃ³n)**.
3. La extensiÃ³n abre `http://192.168.1.38:8080/sales/obs_capture` y guarda fecha, miembro, cÃ³digo, transacciÃ³n e importe. Una transacciÃ³n con `RS` es IOC; las demÃ¡s se registran como OBS, igual que el escritorio.

La versiÃ³n de producciÃ³n admite `http://192.168.1.38:8080` y conserva `http://192.168.1.38:8080` durante la transiciÃ³n. La versiÃ³n local tiene su propia carpeta y configuraciÃ³n.

DespuÃ©s de modificar una extensiÃ³n, pulsa **Recargar** en su tarjeta de `chrome://extensions`.

Si el botÃ³n quedara en **Enviando...**, recarga la extensiÃ³n: los errores de entrega ahora devuelven un aviso en lugar de dejar el botÃ³n bloqueado.

