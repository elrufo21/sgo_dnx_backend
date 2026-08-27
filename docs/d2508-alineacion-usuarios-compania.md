# Alineacion de usuarios y compania en D2508

`DXN_CUSCO_D2508` debe contener las columnas `FechaVencimientoClave`, `DescuentoMax`, `TIPO_PROCESO`, `BoletaPorLote` y `FlagCaptura` para que funcionen los procedimientos web de validacion y mantenimiento de usuarios.

El script `20260827_alinear_usuarios_compania_d2508.sql` agrega solo las columnas ausentes, conserva los datos actuales y toma de `DXN_CUSCO_D2108` las definiciones de `uspValidaUsuarioweb` y `usp_Usuario`.
