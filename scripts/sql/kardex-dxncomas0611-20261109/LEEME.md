# Kardex: cambios aplicados en DXNCOMAS0611

Los seis archivos de `aplicacion/` contienen las definiciones aplicadas a la base local `DXNCOMAS0611` el 09/11/2026. Se comentaron las escrituras directas sobre `Kardex`, conservando las actualizaciones de stock. `uspIngresarProducto` y `uspEliminarProducto` no estaban instalados en esa base.

`originales/` contiene el respaldo previo tal como lo devolvió SQL Server. Para restaurar sobre un procedimiento existente se debe cambiar su declaración `CREATE` a `ALTER` y revisar la versión instalada antes de ejecutar.

Para otra base, no ejecutar estos archivos sin compararlos con sus procedimientos vigentes: pueden existir correcciones o dependencias distintas. Revisar también los procedimientos ausentes, disparadores y llamadas indirectas. El cambio local se verificó por compilación y comparación de definiciones, sin pruebas funcionales de venta o productos.
