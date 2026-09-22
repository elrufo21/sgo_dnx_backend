# Eliminación de nota de pedido en la web

La web elimina una nota de pedido de la misma forma que la aplicación de escritorio: borra primero sus filas de `DetallePedido` y luego la cabecera de `NotaPedido`, dentro de una transacción.

La acción está disponible en **Ventas > Nota Pedido**. Solicita confirmación y, fuera del área `GERENCIA Y ADMINISTRACION`, requiere una clave de administrador válida.

Antes de borrar, `DELETE /api/v1/Nota/{notaId}` bloquea la operación si la nota tiene comprobantes emitidos, liquidaciones de pago o guías relacionadas. También bloquea las notas con estado `CANCELADO` o `ACUENTA`. La validación se ejecuta en la API para que no se pueda omitir desde el navegador.

El JWT de inicio de sesión ahora incluye el área del usuario para aplicar la misma regla. Las sesiones anteriores al cambio muestran el campo de clave de administrador; al volver a iniciar sesión, Gerencia puede eliminar solo con la confirmación.
