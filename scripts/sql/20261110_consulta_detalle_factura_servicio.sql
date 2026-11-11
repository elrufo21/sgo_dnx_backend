DECLARE @DocuId bigint = NULL;

DECLARE @Descripcion nvarchar(200) =
    CASE WHEN COL_LENGTH('dbo.DetalleDocumento', 'DetalleDescripcion') IS NOT NULL
         THEN N'COALESCE(NULLIF(LTRIM(RTRIM(dd.DetalleDescripcion)), ''''), p.ProductoNombre, '''')'
         ELSE N'COALESCE(p.ProductoNombre, '''')'
    END;

DECLARE @Consulta nvarchar(max) = N'
SELECT dd.DetalleId, dd.DocuId, dd.IdProducto, p.ProductoCodigo, p.ProductoNombre,
       p.AplicaINV, s.NombreSublinea, s.CodigoSunat, dd.DetalleCantidad,
       dd.DetallPrecio, dd.DetalleImporte, dd.DetalleNotaId, dd.DetalleUM,
       dd.ValorUM, ' + @Descripcion + N' AS DetalleDescripcion
FROM dbo.DetalleDocumento dd
LEFT JOIN dbo.Producto p ON p.IdProducto = dd.IdProducto
LEFT JOIN dbo.Sublinea s ON s.IdSubLinea = p.IdSubLinea
WHERE dd.DocuId = @DocuId
ORDER BY dd.DetalleId ASC;';

EXEC sys.sp_executesql @Consulta, N'@DocuId bigint', @DocuId = @DocuId;
