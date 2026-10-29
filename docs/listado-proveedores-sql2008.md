# Listado de proveedores en SQL Server 2008

`GET /api/v1/Proveedor/list` consulta directamente la tabla `Proveedor`, filtra por estado y ordena por identificador descendente. Usa `ROW_NUMBER()` para paginar de forma compatible con SQL Server 2008, sin `OFFSET` ni `FETCH`. La pagina predeterminada contiene 50 registros y el maximo es 100.

La consulta equivalente de solo lectura esta en `scripts/sql/20261029_consulta_proveedores_sql2008.sql`. No se necesita crear ni actualizar procedimientos para este cambio: se publica el backend y se conserva la configuracion del servidor.
