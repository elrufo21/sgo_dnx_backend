ALTER PROCEDURE [dbo].[ingresarProductoWEB]
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
    @ProductoxCaja DECIMAL (18, 2),
    @AplicaFB NVARCHAR (1)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT  INTO dbo.Producto (IdSubLinea, ProductoCodigo, ProductoNombre, ProductoMarca, ProductoTipoCambio, ProductoCostoDolar, ProductoUM, ProductoCosto, ProductoVenta, AlmacenId, ProductoUbicacion, ProductoCantidad, ProductoObs, ProductoEstado, ProductoUsuario, ProductoFecha, ProductoImagen, ValorCritico, ProductoPV, ProductoSV, ProductoxCaja, ProductoINV, AplicaFB, UltimoINV, ProductoVentaB, AplicaINV)
    VALUES                   (@IdSubLinea, @ProductoCodigo, @ProductoNombre, @ProductoMarca, @ProductoTipoCambio, @ProductoCostoDolar, @ProductoUM, @ProductoCosto, @ProductoVenta, @AlmacenId, @ProductoUbicacion, @ProductoCantidad, @ProductoObs, @ProductoEstado, @ProductoUsuario, GETDATE(), @ProductoImagen, @ValorCritico, @ProductoPV, @ProductoSV, @ProductoxCaja, @ProductoINV, @AplicaFB, NULL, NULL, NULL);
    DECLARE @ProductoId AS NUMERIC (20) = SCOPE_IDENTITY();
    SELECT @ProductoId;
END
