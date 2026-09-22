# Procedimientos web para DXN_ICA

El script [20260919_procedimientos_web_backend.sql](../scripts/sql/20260919_procedimientos_web_backend.sql) adapta `DXN_ICA` a los procedimientos web existentes en `DXN_CUSCO_D2108`, sin modificar el backend C#.

Incluye `LDdocumentosweb`, los procedimientos de caja, resumen, credenciales, validación de usuario, notas y compras que contienen `web` en el nombre. También agrega las columnas y la tabla `DocumentoVentaCpeWeb` requeridas por esos contratos.

Es autónomo, idempotente y finaliza validando los 15 procedimientos. Ejecutar primero un respaldo de `DXN_ICA`; la prueba local del 19 de septiembre de 2026 terminó con `OK` dentro de una transacción revertida.
