# Pagos de venta en Caja Chica

## Alcance

Los pagos de venta se registran en `CajaDetalle` de la caja activa del usuario y se consultan desde Movimiento de Caja Chica.

## Reglas de registro

- La captura HTML envía el usuario que emite la venta como `UsuarioId`; el procedimiento usa ese dato para obtener su caja activa.
- En IOC/Cashbill (`ConceptoOBS = VENTA`), un depósito, tarjeta, Yape o la parte digital de un pago mixto crea una `SALIDA`, igual que el escritorio.
- En Venta Libre (`ConceptoOBS = VENTA LIBRE`) se crea un `INGRESO` por el total; si tiene una parte digital, se crea además su `SALIDA` por el depósito.
- La salida se guarda con `NotaId = 0`, `NotaIdB = NotaId`, estado `D` y el detalle completo de la venta OBS.
- El listado de Movimiento de Caja Chica replica `usplistarDetaCaja`: solo considera movimientos con `NotaId = 0` y `Vista` vacía. Las transacciones asociadas a una nota no se muestran ni se totalizan allí.
- Los movimientos automáticos con estado `D` no se pueden eliminar desde Caja Chica; el escritorio también los bloquea. La tabla mantiene el tachito desactivado y gris, y el backend rechaza la eliminación incluso si se intenta invocar el endpoint directamente.
- Mientras una instancia anterior del backend aún no devuelve el estado, la interfaz reconoce por el detalle las ventas automáticas para mantenerlas bloqueadas.
- El efectivo no crea una fila automática en `CajaDetalle`, como en el escritorio.
- En el listado, un pago en efectivo se muestra solo como `EFECTIVO`; el valor técnico `-` de entidad no se presenta.
- Los pagos de documentos pendientes se conservan en `uspInsertarPagoVarios`, que ya usa la lógica del escritorio.
- El historial de pagos realizados se consulta directamente desde `PagoVarios` por rango de fechas, como el panel histórico del escritorio.
- Eliminar un pago realizado requiere la clave de un administrador y ejecuta `uspEliminarPagoV`, igual que el escritorio: elimina el pago, sus detalles y movimientos de caja, y devuelve los documentos a pendiente.

## Procedimientos involucrados

- `dbo.uspinsertarNotaBweb`: ventas nuevas al contado.
- `dbo.uspInsertarPagoVarios`: pago de documentos pendientes (validado, sin modificación).

## Aplicación

Aplicar primero `20260824_uspinsertarNotaBweb_completo_ubigeo_y_fecha_edita.sql` y después `20260824_uspInsertarPagoVarios_movimientos_caja_chica.sql`.
