# Sincronización de DXN_ICA desde Producción

La base `DXN_CUSCO_DProduccion` es la referencia para procedimientos almacenados de `DXN_ICA`.

El análisis del 21 de septiembre de 2026 encontró que ICA contiene todas las columnas existentes en Producción y conserva 22 tablas adicionales. Por ello la sincronización no elimina tablas, columnas ni datos de ICA. Solo crea procedimientos de Producción que no existan en ICA y actualiza los que tengan una definición diferente.

Ejecutar [20260921_sincronizar_dxn_ica_desde_produccion.sql](../scripts/sql/20260921_sincronizar_dxn_ica_desde_produccion.sql) mientras ambas bases estén en la misma instancia. El script usa una transacción y valida al final que todos los procedimientos `dbo` compatibles con la estructura de ICA coincidan con Producción.

Los procedimientos o tablas exclusivos de ICA se conservan para no retirar funcionalidades ni datos que no existen en Producción. `Producto` contiene además `ProductoVentaB` y `AplicaINV`, que Producción no tiene: `ingresarProducto` se adapta con columnas explícitas y deja esos dos campos nulos para mantener la lógica de Producción sin romper la estructura de ICA.

## Ejecución realizada

El 21 de septiembre de 2026 el script se ejecutó contra `localhost\SQLEXPRESS01` y actualizó 114 procedimientos. La comprobación posterior obtuvo 382 procedimientos fuente, 392 en ICA, 0 faltantes y 0 diferencias en los procedimientos comunes. La diferencia de cantidad corresponde a procedimientos propios de ICA y a la adaptación indicada de `ingresarProducto`.
