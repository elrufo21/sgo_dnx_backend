# Consolidado OBS en flujo de caja

## Propósito

Mantener el flujo de caja web con el mismo cálculo del escritorio: una venta OBS es un cruce para el consolidado, no un ingreso directo obtenido de `NotaPedido.Efectivo`.

## Regla

- Las cajas abiertas muestran los importes persistidos de `Caja`, sin recalcularlos con las ventas del día.
- Al consultar o cerrar una caja, el efectivo esperado se calcula como `Monto inicial + Sistema OBS - Salidas + ingresos adicionales`.
- `Sistema OBS` se obtiene de `TABLAOBS` para las notas de la caja con `TipoVenta = 'OBS'`.
- Las salidas incluyen también las generadas por depósitos de ventas OBS.
- `VENTA LIBRE` e ingresos manuales siguen siendo ingresos adicionales. Las filas técnicas `TOTAL EFECTIVO` y `SENCILLO` no se suman dos veces.

## Aplicación

En una base existente ejecutar [20260826_caja_obs_consolidado.sql](../scripts/sql/20260826_caja_obs_consolidado.sql). El script actualiza `uspObtenerCajaActivaWEB` y `uspCerrarCajaWEB`.
