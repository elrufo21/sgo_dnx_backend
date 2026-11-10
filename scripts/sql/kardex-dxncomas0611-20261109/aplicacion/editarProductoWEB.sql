ALTER PROCEDURE [dbo].[editarProductoWEB]
 @IdProducto numeric(20),
 @IdSubLinea numeric(20),
 @ProductoCodigo varchar(300),
 @ProductoNombre varchar(max),
 @ProductoMarca varchar(80),
 @ProductoTipoCambio decimal (18,3),
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
 @AVISO INT,
 @ProductoxCaja decimal(18,2),
 @AplicaFB nvarchar(1)
 as
 declare @inicial decimal(18,2)
 set @inicial=(select p.ProductoCantidad from Producto p where IdProducto=@IdProducto)
 if(@AVISO=1)
 begin
 update Producto
 set IdSubLinea=@IdSubLinea,ProductoCodigo=@ProductoCodigo,ProductoNombre=@ProductoNombre,
 ProductoMarca=@ProductoMarca,ProductoTipoCambio=@ProductoTipoCambio,ProductoCostoDolar=@ProductoCostoDolar,
 ProductoUM=@ProductoUM,ProductoCosto=@ProductoCosto,ProductoVenta=@ProductoVenta,
 ProductoINV=@ProductoINV,AlmacenId=@AlmacenId,ProductoUbicacion=@ProductoUbicacion,
 ProductoCantidad=ProductoCantidad,ProductoObs=@ProductoObs,ProductoEstado=@ProductoEstado,
 ProductoUsuario=@ProductoUsuario,ProductoFecha=GETDATE(),ProductoImagen=@ProductoImagen,
 ProductoPV=@ProductoPV,ProductoSV=@ProductoSV,
 ValorCritico=@ValorCritico,ProductoxCaja=@ProductoxCaja,AplicaFB=@AplicaFB
 where IdProducto=@IdProducto
 /* Registro Kardex desactivado para reproceso contable.
insert into Kardex values(@IdProducto,Getdate(),'Edita Costo','Edita Costo',
 @inicial,0,0,@ProductoCosto,@inicial,'INGRESO',@ProductoUsuario,'','','','','','','S','','','E')
*/;
 end
 else
 begin
 update Producto
 set IdSubLinea=@IdSubLinea,ProductoCodigo=@ProductoCodigo,ProductoNombre=@ProductoNombre,
 ProductoMarca=@ProductoMarca,ProductoTipoCambio=@ProductoTipoCambio,ProductoCostoDolar=@ProductoCostoDolar,
 ProductoUM=@ProductoUM,ProductoCosto=@ProductoCosto,ProductoVenta=@ProductoVenta,
 ProductoINV=@ProductoINV,AlmacenId=@AlmacenId,ProductoUbicacion=@ProductoUbicacion,
 ProductoCantidad=@ProductoCantidad,ProductoObs=@ProductoObs,ProductoEstado=@ProductoEstado,
 ProductoUsuario=@ProductoUsuario,ProductoFecha=Getdate(),ProductoImagen=@ProductoImagen,
 ProductoPV=@ProductoPV,ProductoSV=@ProductoSV,ValorCritico=@ValorCritico,
 ProductoxCaja=@ProductoxCaja,AplicaFB=@AplicaFB
 where IdProducto=@IdProducto
 /* Registro Kardex desactivado para reproceso contable.
insert into Kardex values(@IdProducto,Getdate(),'Edita Cantidad','Edita Cantidad',
 @inicial,0,0,@ProductoCosto,@ProductoCantidad,'INGRESO',@ProductoUsuario,'','','','','','','S','','','E')
*/;
 end
