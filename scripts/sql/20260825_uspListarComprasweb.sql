CREATE OR ALTER PROCEDURE dbo.uspListarComprasweb
    @Estado varchar(60) = NULL,
    @Page int = 1,
    @PageSize int = 50
AS
BEGIN
    SET NOCOUNT ON;

    SET @Page = CASE WHEN @Page < 1 THEN 1 ELSE @Page END;
    SET @PageSize = CASE WHEN @PageSize < 1 THEN 50 WHEN @PageSize > 500 THEN 500 ELSE @PageSize END;

    SELECT CompraId,
           CompraCorrelativo,
           ProveedorId,
           CompraRegistro,
           CompraEmision,
           CompraComputo,
           TipoCodigo,
           CompraSerie,
           CompraNumero,
           CompraCondicion,
           CompraMoneda,
           CompraTipoCambio,
           CompraDias,
           CompraFechaPago,
           CompraUsuario,
           CompraTipoIgv,
           CompraValorVenta,
           CompraDescuento,
           CompraSubtotal,
           CompraIgv,
           CompraTotal,
           CompraEstado,
           CompraAsociado,
           CompraSaldo,
           CompraOBS,
           CompraTipoSunat,
           CompraConcepto,
           CAST(NULL AS decimal(18, 2)) AS CompraPercepcion
    FROM Compras
    WHERE @Estado IS NULL OR CompraEstado = @Estado
    ORDER BY CompraId DESC
    OFFSET (@Page - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END
