# Mantenimiento de categorías

La API guarda categorías con `dbo.uspInsertarCategoriaWeb`, una copia web del procedimiento de referencia del escritorio. Recibe `IdSublinea|NombreSublinea|CodigoSUNAT`: el ID 0 crea, un ID existente actualiza y `existe` indica nombre duplicado. El listado consulta `Sublinea` sin requerir `IdLinea`; la eliminación usa `dbo.uspEliminarCategoria`.

El error SQL 2812 informado ocurrió porque faltaba `dbo.uspInsertarCategoria` en la base conectada. Para la versión web, el responsable de SQL debe revisar y ejecutar [20261101_instalar_usp_insertar_categoria_web.sql](../scripts/sql/20261101_instalar_usp_insertar_categoria_web.sql) en la base correspondiente antes de publicar la API. Es compatible con SQL Server 2008, crea el procedimiento web solo si falta y no altera el del escritorio. Debe verificar la estructura de `Sublinea` y sus restricciones. El script no se ha ejecutado ni se han probado escrituras.
