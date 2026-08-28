# Sincronización DXN CUSCO Producción

El script `scripts/sql/20260827_sync_DXN_CUSCO_DProduccion_from_D2108.sql` sincroniza la estructura y los procedimientos de `DXN_CUSCO_D2108` hacia `DXN_CUSCO_DProduccion`, sin modificar datos existentes.

Los procedimientos `dbo.uspinsertarRB` y `dbo.ingresarUsuario` insertan sus valores indicando las columnas de sus tablas. Esto permite agregar `CDRBase64` y `FechaVencimientoClave` sin romper los procedimientos y deja esos campos en `NULL` cuando el proceso existente no los envía.
