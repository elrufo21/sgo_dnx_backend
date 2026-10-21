# Mantenimientos para DXN_ICA

El script [20260920_mantenimientos_backend.sql](../scripts/sql/20260920_mantenimientos_backend.sql) instala los procedimientos `usp_Area`, `usp_Feriado`, `usp_Maquina`, `usp_Personal` y `usp_Usuario` desde `DXN_CUSCO_D2108`.

Son los contratos SQL usados por los endpoints de mantenimiento del backend. El script es autónomo e idempotente.

`usp_Maquina` valida que el nombre de equipo no se repita, pero permite reutilizar series de factura, nota de crédito y boleta. El nombre, las tres series y la ticketera son los campos del registro; la ticketera puede quedar vacía y `Registro` se asigna al crear.
