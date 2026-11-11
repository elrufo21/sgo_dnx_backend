ALTER PROCEDURE [dbo].[editarProductoWEB]
    @IdProducto NUMERIC (20),
    @IdSubLinea NUMERIC (20),
    @ProductoCodigo VARCHAR (300),
    @ProductoNombre VARCHAR (MAX),
    @ProductoMarca VARCHAR (80),
    @ProductoTipoCambio DECIMAL (18, 3),
    @ProductoCostoDolar DECIMAL (18, 4),
    @ProductoUM VARCHAR (60),
    @ProductoCosto DECIMAL (18, 4),
    @ProductoVenta DECIMAL (18, 2),
    @ProductoINV NVARCHAR (1),
    @AlmacenId NUMERIC (20),
    @ProductoUbicacion VARCHAR (80),
    @ProductoCantidad DECIMAL (18, 2),
    @ProductoObs VARCHAR (300),
    @ProductoEstado VARCHAR (60),
    @ProductoUsuario VARCHAR (60),
    @ProductoImagen VARCHAR (MAX),
    @ValorCritico DECIMAL (18, 2),
    @ProductoPV DECIMAL (18, 2),
    @ProductoSV DECIMAL (18, 2),
    @AVISO INT,
    @ProductoxCaja DECIMAL (18, 2),
    @AplicaFB NVARCHAR (1)
AS
DECLARE @inicial AS DECIMAL (18, 2);
SET @inicial = (SELECT p.ProductoCantidad
                FROM   Producto AS p
                WHERE  IdProducto = @IdProducto);
IF (@AVISO = 1)
    BEGIN
        UPDATE Producto
        SET    IdSubLinea         = @IdSubLinea,
               ProductoCodigo     = @ProductoCodigo,
               ProductoNombre     = @ProductoNombre,
               ProductoMarca      = @ProductoMarca,
               ProductoTipoCambio = @ProductoTipoCambio,
               ProductoCostoDolar = @ProductoCostoDolar,
               ProductoUM         = @ProductoUM,
               ProductoCosto      = @ProductoCosto,
               ProductoVenta      = @ProductoVenta,
               ProductoINV        = @ProductoINV,
               AlmacenId          = @AlmacenId,
               ProductoUbicacion  = @ProductoUbicacion,
               ProductoCantidad   = ProductoCantidad,
               ProductoObs        = @ProductoObs,
               ProductoEstado     = @ProductoEstado,
               ProductoUsuario    = @ProductoUsuario,
               ProductoFecha      = GETDATE(),
               ProductoImagen     = @ProductoImagen,
               ProductoPV         = @ProductoPV,
               ProductoSV         = @ProductoSV,
               ValorCritico       = @ValorCritico,
               ProductoxCaja      = @ProductoxCaja,
               AplicaFB           = @AplicaFB
        WHERE  IdProducto = @IdProducto;
    END
ELSE
    BEGIN
        UPDATE Producto
        SET    IdSubLinea         = @IdSubLinea,
               ProductoCodigo     = @ProductoCodigo,
               ProductoNombre     = @ProductoNombre,
               ProductoMarca      = @ProductoMarca,
               ProductoTipoCambio = @ProductoTipoCambio,
               ProductoCostoDolar = @ProductoCostoDolar,
               ProductoUM         = @ProductoUM,
               ProductoCosto      = @ProductoCosto,
               ProductoVenta      = @ProductoVenta,
               ProductoINV        = @ProductoINV,
               AlmacenId          = @AlmacenId,
               ProductoUbicacion  = @ProductoUbicacion,
               ProductoCantidad   = @ProductoCantidad,
               ProductoObs        = @ProductoObs,
               ProductoEstado     = @ProductoEstado,
               ProductoUsuario    = @ProductoUsuario,
               ProductoFecha      = Getdate(),
               ProductoImagen     = @ProductoImagen,
               ProductoPV         = @ProductoPV,
               ProductoSV         = @ProductoSV,
               ValorCritico       = @ValorCritico,
               ProductoxCaja      = @ProductoxCaja,
               AplicaFB           = @AplicaFB
        WHERE  IdProducto = @IdProducto;
    END
