# Mantenimiento de categorías

Las rutas de mantenimiento de `LineaController` usan el mismo flujo que el escritorio para categorías:

- Guardar: `dbo.uspInsertarCategoria` con `IdSublinea|NombreSublinea|CodigoSUNAT`.
- Listar: consulta de `Sublinea` sin requerir `IdLinea`.
- Eliminar: `dbo.uspEliminarCategoria`.

`IdLinea` no se solicita ni se valida en este módulo, porque una categoría puede registrarse sin asociarla a una línea.
