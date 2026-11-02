# Mantenimiento de categorías

La API guarda categorías con `dbo.uspInsertarCategoriaWeb`, una copia web del procedimiento de referencia del escritorio. Recibe `IdSublinea|NombreSublinea|CodigoSUNAT`: el ID 0 crea, un ID existente actualiza y `existe` indica nombre duplicado. El listado consulta `Sublinea` sin requerir `IdLinea`; la eliminación usa `dbo.uspEliminarCategoria`.

El error SQL 2812 informado ocurrió porque faltaba `dbo.uspInsertarCategoriaWeb` en la base conectada. El [script de instalación](../scripts/sql/20261101_instalar_usp_insertar_categoria_web.sql) es compatible con SQL Server 2008, crea el procedimiento web solo si falta y no altera el del escritorio. Antes de aplicarlo en otra base, el responsable debe verificar la estructura de `Sublinea` y sus restricciones.

El 2026-11-02, con autorización del usuario, se instaló y verificó el procedimiento en la instancia local `DESKTOP-B6B71UA\SQLEXPRESS01`, base `DXNCOMAS2610`, configurada en la API local. No se ejecutó el procedimiento ni se modificaron categorías; otras bases no fueron modificadas.

La eliminación requiere `dbo.uspEliminarCategoria`. El 2026-11-02 se instaló y verificó en `DESKTOP-B6B71UA\SQLEXPRESS01`, base `DXNCOMAS2610`, con autorización del usuario, mediante el [script de instalación](../scripts/sql/20261102_instalar_usp_eliminar_categoria.sql), basado en la definición de `bdactual.sql`. El script crea el procedimiento solo si falta. No se ejecutó el procedimiento ni se eliminaron categorías; otras bases no fueron modificadas. Las restricciones de la base impiden eliminar una categoría referenciada por productos.
