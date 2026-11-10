ALTER PROCEDURE [dbo].[ingresarProductoWEB]
    @IdSubLinea numeric(20),
    @ProductoCodigo varchar(300),
    @ProductoNombre varchar(max),
    @ProductoMarca varchar(80),
    @ProductoTipoCambio decimal(18,3),
    @ProductoCostoDolar decimal(18,4),
    @ProductoUM varchar(60),
    @ProductoCosto decimal(18,4),
    @ProductoVenta decimal(18,2),
    @ProductoINV nvarchar(1),
    @AlmacenId numeric(20),
    @ProductoUbicacion varchar(80),
    @ProductoCantidad decimal(18,2),
    @ProductoObs varchar(300),
    @ProductoEstado varchar(60),
    @ProductoUsuario varchar(60),
    @ProductoImagen varchar(max),
    @ValorCritico decimal(18,2),
    @ProductoPV decimal(18,2),
    @ProductoSV decimal(18,2),
    @ProductoxCaja decimal(18,2),
    @AplicaFB nvarchar(1)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Producto
    (
        IdSubLinea, ProductoCodigo, ProductoNombre, ProductoMarca,
        ProductoTipoCambio, ProductoCostoDolar, ProductoUM, ProductoCosto,
        ProductoVenta, AlmacenId, ProductoUbicacion, ProductoCantidad,
        ProductoObs, ProductoEstado, ProductoUsuario, ProductoFecha,
        ProductoImagen, ValorCritico, ProductoPV, ProductoSV, ProductoxCaja,
        ProductoINV, AplicaFB, UltimoINV, ProductoVentaB, AplicaINV
    )
    VALUES
    (
        @IdSubLinea, @ProductoCodigo, @ProductoNombre, @ProductoMarca,
        @ProductoTipoCambio, @ProductoCostoDolar, @ProductoUM, @ProductoCosto,
        @ProductoVenta, @AlmacenId, @ProductoUbicacion, @ProductoCantidad,
        @ProductoObs, @ProductoEstado, @ProductoUsuario, GETDATE(),
        @ProductoImagen, @ValorCritico, @ProductoPV, @ProductoSV, @ProductoxCaja,
        @ProductoINV, @AplicaFB, NULL, NULL, NULL
    );

    DECLARE @ProductoId numeric(20) = SCOPE_IDENTITY();

    /* Registro Kardex desactivado para reproceso contable.
INSERT INTO dbo.Kardex
    VALUES
    (
        @ProductoId, GETDATE(), 'Nuevo Registro', 'Nuevo Registro',
        0, @ProductoCantidad, 0, @ProductoCosto, @ProductoCantidad, 'INGRESO',
        @ProductoUsuario, '', '', '', '', '', '', 'S', '', '', 'E'
    );
*/;

    SELECT @ProductoId;
END;
