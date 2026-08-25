# Clasificación de resumen OBS e IOC

## Regla

El escritorio clasifica cada venta por el número de transacción: si contiene `RS`, es IOC; de lo contrario es OBS/Cash Bill.

## Aplicación

La extensión conserva la columna correcta del importe según el diseño del reporte. El backend vuelve a calcular el tipo antes de guardar en `TABLAOBS`, por lo que no depende de la clasificación enviada por el navegador.

## Corrección de datos

Ejecutar `scripts/sql/20260825_reclasificar_tablaobs_por_transaccion.sql` para alinear los registros existentes con la misma regla.
