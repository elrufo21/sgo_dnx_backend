SELECT ProductoCodigo, ProductoNombre FROM dbo.Producto
 WHERE ProductoEstado = 'BUENO' AND ProductoINV = 'S'
   AND NULLIF(LTRIM(RTRIM(ProductoCodigo)), '') IS NOT NULL
 ORDER BY ProductoCodigo, IdProducto
