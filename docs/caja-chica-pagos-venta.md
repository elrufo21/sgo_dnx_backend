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
- Una venta OBS (`ConceptoOBS = VENTA`) no se suma como ingreso en el listado ni en el cierre de caja. Su importe se obtiene desde OBS para formar `TOTAL EFECTIVO`, descontando todas las salidas, igual que el escritorio. `VENTA LIBRE` y los ingresos manuales sí permanecen como ingresos de caja.
- En el listado, un pago en efectivo se muestra solo como `EFECTIVO`; el valor técnico `-` de entidad no se presenta.
- Los pagos de documentos pendientes se conservan en `uspInsertarPagoVarios`, que ya usa la lógica del escritorio.
- Una venta con condición `PAGO/VARIOS` se crea pendiente con depósito cero y no exige número de operación. La operación se registra posteriormente en `uspInsertarPagoVarios` cuando se realiza el pago.
- El historial de pagos realizados se consulta directamente desde `PagoVarios` por rango de fechas, como el panel histórico del escritorio.
- Eliminar un pago realizado requiere la clave de un administrador y ejecuta `uspEliminarPagoV`, igual que el escritorio: elimina el pago, sus detalles y movimientos de caja, y devuelve los documentos a pendiente.

## Procedimientos involucrados

- `dbo.uspinsertarNotaBweb`: ventas nuevas al contado.
- `dbo.uspInsertarPagoVarios`: pago de documentos pendientes (validado, sin modificación).

## Aplicación

En bases que ya tienen el procedimiento completo, aplicar `20260826_uspinsertarNotaBweb_pago_varios_sin_operacion.sql`. Para una instalación desde cero, aplicar `20260824_uspinsertarNotaBweb_completo_ubigeo_y_fecha_edita.sql` y después `20260824_uspInsertarPagoVarios_movimientos_caja_chica.sql`.

Para el cálculo del consolidado OBS en flujo de caja, revisar `caja-flujo-obs.md` y aplicar `20260826_caja_obs_consolidado.sql`.
