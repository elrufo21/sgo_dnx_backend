USE [DXN_CUSCO_DBP];
GO

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH(N'dbo.Compania', N'FlagCaptura') IS NULL
    ALTER TABLE dbo.Compania ADD FlagCaptura bit NOT NULL CONSTRAINT DF_Compania_FlagCaptura DEFAULT ((0)) WITH VALUES;

IF COL_LENGTH(N'dbo.Compania', N'TIPO_PROCESO') IS NULL
    ALTER TABLE dbo.Compania ADD TIPO_PROCESO int NULL;

IF COL_LENGTH(N'dbo.Compania', N'DescuentoMax') IS NULL
    ALTER TABLE dbo.Compania ADD DescuentoMax decimal(18,2) NULL;

IF COL_LENGTH(N'dbo.Compania', N'RenovacionOSE') IS NULL
    ALTER TABLE dbo.Compania ADD RenovacionOSE date NULL;

IF COL_LENGTH(N'dbo.Compania', N'RenovacionFirma') IS NULL
    ALTER TABLE dbo.Compania ADD RenovacionFirma date NULL;

IF COL_LENGTH(N'dbo.Compania', N'RenovacionSome') IS NULL
    ALTER TABLE dbo.Compania ADD RenovacionSome date NULL;

IF COL_LENGTH(N'dbo.Compania', N'CorreoSGO') IS NULL
    ALTER TABLE dbo.Compania ADD CorreoSGO varchar(250) NULL;

IF COL_LENGTH(N'dbo.Compania', N'PasswordCorreo') IS NULL
    ALTER TABLE dbo.Compania ADD PasswordCorreo varchar(250) NULL;

IF COL_LENGTH(N'dbo.Compania', N'CorreosAdmin') IS NULL
    ALTER TABLE dbo.Compania ADD CorreosAdmin varchar(max) NULL;

IF COL_LENGTH(N'dbo.Compania', N'BoletaPorLote') IS NULL
    ALTER TABLE dbo.Compania ADD BoletaPorLote bit NOT NULL CONSTRAINT DF_Compania_BoletaPorLote DEFAULT ((1)) WITH VALUES;

IF COL_LENGTH(N'dbo.Compania', N'CompaniaPFX') IS NOT NULL
   AND EXISTS
   (
       SELECT 1
       FROM sys.columns
       WHERE object_id = OBJECT_ID(N'dbo.Compania')
         AND name = N'CompaniaPFX'
         AND max_length <> -1
   )
    ALTER TABLE dbo.Compania ALTER COLUMN CompaniaPFX varchar(max) NULL;

IF COL_LENGTH(N'dbo.Usuarios', N'FechaVencimientoClave') IS NULL
    ALTER TABLE dbo.Usuarios ADD FechaVencimientoClave date NULL;

IF COL_LENGTH(N'dbo.ResumenBoletas', N'CDRBase64') IS NULL
    ALTER TABLE dbo.ResumenBoletas ADD CDRBase64 varchar(max) NULL;

IF OBJECT_ID(N'dbo.DocumentoVentaCpeWeb', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DocumentoVentaCpeWeb
    (
        DocuId numeric(38,0) NOT NULL,
        ClienteRazon varchar(140) NULL,
        ClienteRuc varchar(40) NULL,
        ClienteDni varchar(40) NULL,
        DireccionFiscal varchar(max) NULL,
        DocuPdfUrl varchar(500) NULL,
        DocuXmlUrl varchar(500) NULL,
        DocuCdrUrl varchar(500) NULL,
        DocuFechaPago date NULL,
        FechaRegistro datetime NOT NULL CONSTRAINT DF_DocumentoVentaCpeWeb_FechaRegistro DEFAULT (getdate()),
        CONSTRAINT PK_DocumentoVentaCpeWeb PRIMARY KEY CLUSTERED (DocuId)
    );
END;
GO
IF OBJECT_ID(N'dbo.AcuentaPedido', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[AcuentaPedido] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[AcuentaPedido]
@NotaId numeric(38)
as
begin
select
'NroCaja|Fecha|Movimiento|Efectivo|Monto|Vuelto¬100|140|110|120|120|120¬String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.DetalleFecha,103)+' '+Convert(char(8),c.DetalleFecha,114)+'|'+
c.DetalleMovimiento+'|'+CONVERT(VarChar(50),cast(c.DetalleEfectivo as money ), 1)+'|'+
CONVERT(VarChar(50),cast(c.DetalleMonto as money ), 1)+'|'+
CONVERT(VarChar(50),cast(c.DetalleVuelto as money ), 1)
from CajaDetalle c
where c.NotaId=@NotaId
order by DetalleId asc
FOR XML PATH('')),1,1,'')),'~')+'['+
'FechaPago|Liquidacion|Documento|SaldoDocu|Acuenta|SaldoActual¬110|125|120|120|120|120¬String|String|String|String|String|String¬'+
isnull((select stuff((select '¬'+ Convert(char(10),d.FechaPago,103)+'|'+'LQ '+l.LiquidacionNumero+'|'+
n.NotaSerie+'-'+n.NotaNumero+'|'+
CONVERT(VarChar(50),cast(d.SaldoDocu as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.AcuentaGeneral as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.SaldoActual as money ), 1)
from DetaLiquidaVenta d
inner join LiquidacionVenta l
on l.LiquidacionId=d.LiquidacionId
inner join NotaPedido n
on  n.NotaId=d.NotaId
where d.NotaId=@NotaId
order by d.DetalleId asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.anularDocumento', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[anularDocumento] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[anularDocumento]
@ListaOrden varchar(Max)
as
begin
Declare @pos int
Declare @orden varchar(max)
Declare @detalle varchar(max)
Set @pos = CharIndex('[',@ListaOrden,0)
Set @orden = SUBSTRING(@ListaOrden,1,@pos-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos+1,len(@ListaOrden)-@pos)
declare @p1 int,@p2 int,
        @p3 int,@p4 int,@p5 int,
        @p6 int,@p7 int,@p8 int,
        @p9 int
declare @DocuId numeric(38),
@NotaId numeric(38),
@DocuUsuario varchar(80),
@DetalleId numeric(38),
@Concepto varchar(40),
@Documento varchar(40),
@Transaccion varchar(250),
@Miembro varchar(300),
@CodigoCliente varchar(80),
@FechaFactura date,
@TipoCodigo nvarchar(10)

Set @orden= LTRIM(RTrim(@orden))
Set @p1 = CharIndex('|',@orden,0)
Set @p2 = CharIndex('|',@orden,@p1+1)
Set @p3 = CharIndex('|',@orden,@p2+1)
Set @p4= CharIndex('|',@orden,@p3+1)
Set @p5 = CharIndex('|',@orden,@p4+1)
Set @p6= CharIndex('|',@orden,@p5+1)
Set @p7= CharIndex('|',@orden,@p6+1)
Set @p8= CharIndex('|',@orden,@p7+1)
Set @p9 = Len(@orden)+1
Set @DocuId=convert(numeric(38),SUBSTRING(@orden,1,@p1-1))
Set @NotaId=convert(numeric(38),SUBSTRING(@orden,@p1+1,@p2-@p1-1))
Set @DocuUsuario=SUBSTRING(@orden,@p2+1,@p3-@p2-1)
set @Concepto=SUBSTRING(@orden,@p3+1,@p4-@p3-1)
set @Documento=SUBSTRING(@orden,@p4+1,@p5-@p4-1)
set @Miembro=SUBSTRING(@orden,@p5+1,@p6-@p5-1)
set @CodigoCliente=SUBSTRING(@orden,@p6+1,@p7-@p6-1)
set @Transaccion=SUBSTRING(@orden,@p7+1,@p8-@p7-1)
set @TipoCodigo=SUBSTRING(@orden,@p8+1,@p9-@p8-1)

IF EXISTS(select d.DocuId from DetallePVarios d where d.DocuId=@DocuId)
BEGIN
select 'PAGO'
END
ELSE
BEGIN

Declare @Valores varchar(max)
Declare @Entrega varchar(80),@ConceptoOBS varchar(80)
Declare @c1 int,@c2 int

set @Valores=(select top 1 n.ConceptoOBS+'|'+n.NotaEntrega 
from NotaPedido n where n.NotaId=@NotaId)

Set @Valores= LTRIM(RTrim(@Valores))
Set @c1 = CharIndex('|',@Valores,0)
Set @c2 = Len(@Valores)+1

Set @ConceptoOBS=SUBSTRING(@Valores,1,@c1-1)
Set @Entrega=SUBSTRING(@Valores,@c1+1,@c2-@c1-1)

if(@ConceptoOBS<>'VENTA')
begin

set @DetalleId=isnull((select top 1 d.DetalleId from CajaDetalle d
where d.NotaIdB=@NotaId 
order by d.DetalleId desc),0)

end
else
begin

set @DetalleId=isnull((select top 1 d.DetalleId from CajaDetalle d
where d.NotaId=@NotaId 
order by d.DetalleId desc),0)

end

set @FechaFactura=(select top 1 d.DocuEmision from DocumentoVenta d
where NotaId=@NotaId)

Begin Transaction

if(@Documento='PROFORMA V')
BEGIN
update DocumentoVenta
set DocuEstado='ANULADO',DocuSubTotal=0,DocuIgv=0,DocuTotal=0,DocuSaldo=0,DocuAdicional=0,ICBPER=0,Efectivo=0,Deposito=0
where DocuId=@DocuId
END
ELSE
BEGIN
update DocumentoVenta
set DocuEstado='ANULADO',Efectivo=0,Deposito=0 
where DocuId=@DocuId
END

update NotaPedido set ModificadoPor=@DocuUsuario,NroOperacion='',
FechaEdita=GETDATE(),NotaEstado='ANULADO',
NotaSaldo=NotaPagar,NotaAcuenta=0,Efectivo=0,Deposito=0 
where NotaId=@NotaId

if(@FechaFactura=CONVERT(date,GETDATE()))
begin
	if(@Concepto='MERCADERIA')
	begin
	delete from CajaDetalle
	where DetalleId=@DetalleId
	delete from CajaDetalle
	where NotaIdB=@NotaId
	end
end
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max),
		@IdProducto numeric(20),
		@Cantidad decimal(18,2),
		@Precio decimal(18,2),
		@IniciaStock decimal(18,2),
		@StockFinal decimal(18,2)--,@CodigoPro varchar(80)
Declare @d1 int,@d2 int,@d3 int
Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	Begin
Set @d1 = CharIndex('|',@Columna,0)
Set @d2 = CharIndex('|',@Columna,@d1+1)
Set @d3 = Len(@Columna)+1
Set @IdProducto=Convert(numeric(38),SUBSTRING(@Columna,1,@d1-1))
Set @Cantidad=Convert(decimal(18,2),SUBSTRING(@Columna,@d1+1,@d2-(@d1+1)))
Set @Precio=Convert(decimal(18,2),SUBSTRING(@Columna,@d2+1,@d3-(@d2+1)))

if(@Entrega='INMEDIATA')
begin
 --   set @CodigoPro=isnull((select top 1 ProductoCodigo from Producto
 --   where IdProducto=@IdProducto),'0')
 --   if(@CodigoPro='PEKIT-3')
 --   begin
    	
	--update producto 
	--set  ProductoCantidad =ProductoCantidad + @Cantidad
	--where IDProducto=7
		
 --   END
       
	update producto 
	set  ProductoCantidad =ProductoCantidad + @Cantidad
	where IDProducto=@IdProducto
	
	delete from Kardex
	where DocuId=convert(varchar,@DocuId)
end
else
begin
	delete from Kardex
	where DocuId=convert(varchar,@DocuId)
end

Fetch Next From Tabla INTO @Columna
end
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
select 'true'
END
END
GO

IF OBJECT_ID(N'dbo.ap_insertarCanje', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ap_insertarCanje] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ap_insertarCanje]
@LetraId  numeric(38),
@CompraId numeric(38),
@Documento varchar(60),
@Moneda varchar(60),
@Monto    varchar(80)
as
begin
insert into DocumentoCanje values(@LetraId,@CompraId,@Documento,@Moneda,@Monto)
end
GO

IF OBJECT_ID(N'dbo.ap_Reimprimir', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ap_Reimprimir] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ap_Reimprimir] 
@NotaId numeric(38),
@Usuario varchar(60)
as
begin
begin
update DetallePedido
set DetalleEstado='PENDIENTE'
where NotaId=@NotaId
end
begin
update NotaPedido
set NotaDocu='PROFORMA V',NotaEstado='PENDIENTE',
NotaSerie='',NotaNumero='',ModificadoPor=@Usuario
where NotaId=@NotaId
end
end
GO

IF OBJECT_ID(N'dbo.ap_xEntregar', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ap_xEntregar] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ap_xEntregar]
as
begin
select 
'Codigo|RazonSocial|Direccion|Telefono¬80|355|80|80¬String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,c.ClienteId)+'|'+c.ClienteRazon+'|'+c.ClienteDespacho+'|'+c.ClienteTelefono
from DetallePedido d
inner join NotaPedido n
on n.NotaId=d.NotaId
inner join cliente c
on c.ClienteId=n.ClienteId
where d.cantidadSaldo>0 and (n.NotaEstado<>'ANULADO' and n.NotaEntrega='POR ENTREGAR')
group by c.ClienteId,c.ClienteRazon,c.ClienteDespacho,c.ClienteTelefono
order by c.ClienteRazon asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.aumentarStockCompra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[aumentarStockCompra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[aumentarStockCompra]
@IdProducto numeric(38),
@Cantidad decimal(18,2),
@Costo decimal(18,4),
@costoDolar decimal(18,4),
@TipoCambio decimal(18,3),
@Estado varchar(40),
@Documento varchar(80),
@usuario varchar(80),
@TipoCodigo nvarchar(10),
@Serie nvarchar(10),
@FechaEmision datetime,
@Codigo varchar(80),
@CompraId varchar(40)
as
begin
Declare @CodigoPro varchar(80)

declare @IniciaStock decimal(18,2),
        @stockFinal decimal(18,2)
    
    set @CodigoPro=isnull((select top 1 ProductoCodigo 
    from Producto where IdProducto=@IdProducto),'0')
    
    if(@CodigoPro='PEKIT-3')
    begin
          
    set @IniciaStock=(select top 1 ProductoCantidad 
    from Producto where IdProducto=7)
    
	set @StockFinal=@IniciaStock+@Cantidad
	
	insert into Kardex values(7,@FechaEmision,'Ingreso por Compra',
	@Documento,@IniciaStock,@Cantidad,0,57,@StockFinal,'INGRESO',@Usuario,
	'',@Codigo,'',@TipoCodigo,@Serie,'02','S','',@CompraId,'E')
	
	update Producto 
	set ProductoCantidad=ProductoCantidad+@Cantidad
	where IdProducto=7
	
	
	end
	
	set @IniciaStock=(select top 1 p.ProductoCantidad from Producto p 
    where p.IdProducto=@IdProducto)

    set @stockFinal=@IniciaStock+@Cantidad
    
	if(@Estado='BONIFICACION')
	begin
	
	update Producto 
	set ProductoCantidad=ProductoCantidad+@Cantidad
	where IdProducto=@IdProducto 
	
	end
	
	else
	begin
	
	update Producto 
	set ProductoCantidad=ProductoCantidad+@Cantidad,ProductoCosto=@Costo,
	ProductoCostoDolar=@costoDolar,ProductoTipoCambio=@TipoCambio
	where IdProducto=@IdProducto 
	
	end
	insert into Kardex values(@IdProducto,@FechaEmision,'Ingreso por Compra',
	@Documento,@IniciaStock,@Cantidad,0,@Costo,@StockFinal,'INGRESO',@Usuario,
	'',@Codigo,'',@TipoCodigo,@Serie,'02','S','',@CompraId,'E')
end
GO

IF OBJECT_ID(N'dbo.aumentaSaldo', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[aumentaSaldo] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[aumentaSaldo]
@Cantidad decimal(18,2),
@IdDetalle numeric(38)
as
update DetallePedido
set CantidadSaldo=CantidadSaldo+@Cantidad
where DetalleId=@IdDetalle
GO

IF OBJECT_ID(N'dbo.aumentaServicio', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[aumentaServicio] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[aumentaServicio]
@Cantidad decimal(18,2),
@IdProducto numeric(38)
as
update Stock
set Cantidad=Cantidad+@Cantidad
where IdProducto=@IdProducto
GO

IF OBJECT_ID(N'dbo.buscarProducto', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[buscarProducto] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[buscarProducto]  
as  
begin  
select  
'Id|Codigo|Descripcion|Cantidad|Precio|Inventario|PV|SV|ValorUM|ValorCritico¬100|120|380|100|100|120|100|100|100|100¬String|String|String|String|String|String|String|String|String|String¬'+  
isnull((select STUFF ((select '¬'+  
convert(varchar,p.IdProducto)+'|'+p.ProductoCodigo+'|'+  
p.ProductoNombre+' '+p.ProductoMarca+'|'+''+'|'+  
CONVERT(VarChar(50), cast(p.ProductoCosto as money ), 1)+'|'+  
CONVERT(VarChar(50), cast(p.ProductoCantidad as money ), 1)+'|'+  
CONVERT(VarChar(50), cast(p.ProductoPV as money ), 1)+'|'+  
CONVERT(VarChar(50), cast(p.ProductoSV as money ), 1)+'|'+  
'1'+'|'+convert(varchar,p.ValorCritico)  
from Producto p  
where p.ProductoEstado='BUENO'  
order by p.ProductoCodigo asc  
for xml path('')),1,1,'')),'~')  
end
GO

IF OBJECT_ID(N'dbo.buscarProductoB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[buscarProductoB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[buscarProductoB] 
@Descripcion varchar(80)
as
begin
SELECT top 200 p.IdProducto,l.NombreLinea,s.NombreSublinea,p.ProductoCodigo,p.ProductoNombre,
p.ProductoMarca,p.ProductoNombre+' '+p.ProductoMarca as Descripcion,CONVERT(VarChar(50), cast(p.ProductoCantidad as money ), 1) as ProductoCantidad, 
p.ProductoUM,CONVERT(VarChar(50), cast(p.ProductoVenta as money ), 1)as ProductoVenta,
p.ProductoINV,p.ProductoCosto,ProductoCostoDolar,ProductoTipoCambio, 
a.AlmacenNombre,p.ProductoUbicacion,p.ProductoObs,p.ProductoEstado,p.ProductoUsuario,p.ProductoFecha,p.ProductoImagen,p.ValorCritico
FROM Producto p (nolock)
INNER JOIN Sublinea s
ON p.IdSubLinea =s.IdSubLinea 
INNER JOIN Linea l (nolock)
ON s.IdLinea =l.IdLinea 
INNER JOIN Almacen a (nolock)
ON p.AlmacenId =a.AlmacenId
where (p.ProductoNombre+' '+p.ProductoMarca like'%'+@Descripcion+'%') and 
p.ProductoEstado='BUENO'
order by 7 asc
end
GO

IF OBJECT_ID(N'dbo.buscarProductoC', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[buscarProductoC] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[buscarProductoC]
as
begin
select
'Id|Codigo|Descripcion|Cantidad|Precio|Inventario|PV|SV|ValorUM|ValorCritico|Imagen¬100|120|380|100|100|120|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+
convert(varchar,p.IdProducto)+'|'+p.ProductoCodigo+'|'+p.ProductoMarca+' '+p.ProductoNombre+'|'+''+'|'+
CONVERT(VarChar(50), cast(p.ProductoCosto as money ), 1)+'|'+
CONVERT(VarChar(50), cast(p.ProductoCantidad as money ), 1)+'|'+
CONVERT(VarChar(50), cast(p.ProductoPV as money ), 1)+'|'+
CONVERT(VarChar(50), cast(p.ProductoSV as money ), 1)+'|'+
'1'+'|'+convert(varchar,p.ValorCritico)+'|'+p.ProductoImagen
from Producto p
where p.ProductoEstado='BUENO' and p.IdProducto NOT IN (SELECT IdProducto FROM Stock)
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.buscarProductoD', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[buscarProductoD] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[buscarProductoD]
as
begin
select
'Id|Codigo|Descripcion|Cantidad|Precio|Stock|PV|SV|ValorUM|ValorCritico¬100|120|380|100|100|110|110|110|100|100¬String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+
convert(varchar,p.IdProducto)+'|'+p.ProductoCodigo+'|'+
p.ProductoNombre+' '+p.ProductoMarca+'|'+''+'|'+
CONVERT(VarChar(50), cast(p.ProductoCosto as money ), 1)+'|'+
CONVERT(VarChar(50), cast(p.ProductoCantidad as money ), 1)+'|'+
CONVERT(VarChar(50), cast(p.ProductoPV as money ), 1)+'|'+
CONVERT(VarChar(50), cast(p.ProductoSV as money ), 1)+'|'+
'1'+'|'+convert(varchar,p.ValorCritico)
from Producto p
where p.ProductoEstado='BUENO'
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.buscaValorCritico', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[buscaValorCritico] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[buscaValorCritico] @Descripcion varchar(80)
as
begin
select top 200 p.IdProducto,p.ProductoCodigo as Codigo,p.ProductoNombre+' '+p.ProductoMarca as Descripcion,
CONVERT(VarChar(50), cast(p.ProductoCantidad as money ), 1) as Stock,
p.ProductoUM as UM,p.ProductoCosto as Costo,p.ProductoCostoDolar as CostoDolar
from Producto p
where p.ProductoNombre+' '+p.ProductoMarca like '%'+@Descripcion+'%' and (p.ProductoCantidad < = p.ValorCritico)
order by 3 asc
end
GO

IF OBJECT_ID(N'dbo.cajaPrincipal', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[cajaPrincipal] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[cajaPrincipal]
as
begin
select
'ID|Concepto|CajaId|Fecha|Descripcion|Monto|Usuario|Imagen¬90|100|80|136|373|120|100|90¬String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen 
from CajaPincipal c 
where c.CajaConcepto='INGRESO' and c.IdGeneral=0
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')+'['+
'ID|Concepto|CajaId|Fecha|Descripcion|Monto|Usuario|Imagen¬90|100|80|135|435|125|100|90¬String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen 
from CajaPincipal c 
where c.CajaConcepto='SALIDA' and c.IdGeneral=0
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')+'['+
'Codigo|FechaCierre|Usuario|Ingresos|Salidas|Total¬100|200|250|130|130|130¬String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+ CONVERT(varchar,c.IdGeneral)+'|'+
(IsNull(convert(varchar,c.FechaCierre,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,c.FechaCierre,114),1,8),''))+'|'+c.Usuario+'|'+
CONVERT(varchar(50),cast(c.Ingresos as money),1)+'|'+CONVERT(varchar(50),cast(c.Salidas as money),1)+'|'+
CONVERT(varchar(50),cast(c.Total as money),1)
from CajaGeneral c
order by c.IdGeneral desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.canjearGuia', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[canjearGuia] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[canjearGuia] 
@ProveedorId numeric(38)
as
begin
select
'CompraId|FechaEmision|Documento|Moneda|Saldo|Monto|Estado¬100|110|150|90|120|120|150¬String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+ convert(varchar,c.CompraId)+'|'+(Convert(char(10),c.CompraEmision,103))+'|'+
SUBSTRING(t.TipoDescripcion,1,1)+'C '+ c.CompraSerie+'-'+c.CompraNumero+'|'+c.CompraMoneda+'|'+
(convert(varchar(50), CAST(c.CompraSaldo as money), -1))+'|'+
(convert(varchar(50), CAST(c.CompraTotal as money), -1))+'|'+
c.CompraEstado
from Compras c
inner join TipoComprobante t
on t.TipoCodigo=c.TipoCodigo
where c.ProveedorId=@ProveedorId and c.TipoCodigo='09'
order by c.CompraEmision desc
for xml path('')),1,1,'')),'~')	
end
GO

IF OBJECT_ID(N'dbo.CanjeFacturaFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[CanjeFacturaFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[CanjeFacturaFecha]
@fechainicio date,
@fechafin date
as
begin
SELECT dbo.GuiaCanje.*, dbo.Compras.CompraMoneda as Moneda,(convert(varchar(50), CAST(dbo.Compras.CompraValorVenta as money), -1))as Total,
(SUBSTRING(dbo.Compras.CompraMoneda,1,1)+'/.  '+(convert(varchar(50), CAST(dbo.Compras.CompraTotal as money), -1)))as Monto,dbo.Proveedor.ProveedorRazon as Proveedor
FROM dbo.GuiaCanje INNER JOIN dbo.Compras ON dbo.GuiaCanje.CompraId = dbo.Compras.CompraId inner join dbo.Proveedor on dbo.Proveedor.ProveedorId=dbo.Compras.ProveedorId 
where (Convert(char(10),dbo.GuiaCanje.CanjeFecha,103) BETWEEN @fechainicio AND @fechafin) 
order by dbo.GuiaCanje.CanjeId desc
end
GO

IF OBJECT_ID(N'dbo.CantidadVendidas', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[CantidadVendidas] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[CantidadVendidas] 
@MES INT,
@ANNO INT
as
begin
select 'Id|SubLinea¬0|300¬'+
(select STUFF((select '¬'+ convert(varchar,s.IdSubLinea)+'|'+s.NombreSublinea
from Sublinea s
for XMl path('')),1,1,''))+'_'+
'Descripcion|Cantidad|UM|Venta|Ganancia¬520|125|100|125|125¬'+
(select STUFF((select '¬'+ p.ProductoNombre+' '+p.ProductoMarca+'|'+
convert(varchar(50),cast(sum(d.DetalleCantidad)as money),1)+'|'+p.ProductoUM+'|'+
convert(varchar(50),cast(SUM(d.DetalleImporte)as money),1)+'|'+
convert(varchar(50),cast(sum((d.DetallePrecio-d.DetalleCosto)* d.DetalleCantidad)as money),1)+'|'+convert(varchar,p.IdSubLinea)
from NotaPedido n
inner join DetallePedido d
on d.NotaId=n.NotaId
inner join Producto p
on p.IdProducto=d.IdProducto
where n.NotaEstado='CANCELADO' and 
(MONTH(n.NotaFecha)=@MES and year(n.NotaFecha)=@ANNO)
group by p.IdSubLinea,p.IdProducto,p.ProductoNombre,p.ProductoMarca,p.ProductoUM
order by p.IdSubLinea asc,sum(d.DetalleCantidad) desc
for XMl path('')),1,1,''))
end
GO

IF OBJECT_ID(N'dbo.cargaPrincipal', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[cargaPrincipal] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[cargaPrincipal]
as
begin
select
isnull((select STUFF((select '¬'+ convert(varchar,c.CompaniaId)+'|'+
c.CompaniaRazonSocial
from Compania c 
order by c.CompaniaId asc 
FOR XML PATH('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ t.TipoCodigo+'|'+
t.TipoDescripcion
from TipoComprobante t
order by t.TipoCodigo asc
FOR XML PATH('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ convert(varchar,a.AreaId)+'|'+
a.AreaNombre 
from Area a
order by a.AreaNombre asc
FOR XML PATH('')),1,1,'')),'~')+'['+
isnull((select STUFF((select ';'+ p.PersonalEmail 
from Personal p
inner join Usuarios u
on p.PersonalId=u.PersonalId
where u.Administrador=1 and p.PersonalEmail<>''
order by p.PersonalId asc
FOR XML PATH('')),1,1,'')),'')
end
GO

IF OBJECT_ID(N'dbo.ClientesAtendidos', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ClientesAtendidos] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ClientesAtendidos]
@ANNO INT,
@VENDEDOR VARCHAR(40)
as
begin
select MONTH(N.NotaFecha)as Numero,
(DATENAME(month,n.NotaFecha)) as Mes,n.NotaUsuario as Usuario,
COUNT(ClienteId) as Clientes
from NotaPedido n
where YEAR(n.NotaFecha)=@ANNO and (n.NotaUsuario=@VENDEDOR and n.NotaEstado='CANCELADO')
group by MONTH(N.NotaFecha),(DATENAME(month,n.NotaFecha)),n.NotaUsuario
order by 1 asc
end
GO

IF OBJECT_ID(N'dbo.CorrelativoCompra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[CorrelativoCompra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[CorrelativoCompra]
@CompaniaId int,@anno int,@mes int
as
begin
select top 1 c.CompraCorrelativo as Correlativo from Compras c
where CompaniaId=@CompaniaId and (year(CompraComputo)=@anno and MONTH(CompraComputo)=@mes)
order by c.CompraCorrelativo desc
end
GO

IF OBJECT_ID(N'dbo.CorrelativoLiquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[CorrelativoLiquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[CorrelativoLiquida]
as
begin
declare @cod varchar(12)
select @cod=dbo.geneneraIdLiquida('001-')
SELECT TOP 1 @cod  AS ID FROM Liquidacion
end
GO

IF OBJECT_ID(N'dbo.CorrelativoLiVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[CorrelativoLiVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[CorrelativoLiVenta]
as
begin
declare @cod varchar(12)
set @cod=ISNULL(dbo.geneneraIdLiVenta('001-'),'001-00000001')
SELECT @cod
end
GO

IF OBJECT_ID(N'dbo.correlativoNroFactura', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[correlativoNroFactura] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[correlativoNroFactura]@dato varchar(20),@CompaniaId int,@DocuDocumento varchar(40)
as
begin
declare @cod varchar(13)
select @cod=dbo.genenerarNroFactura(@dato,@CompaniaId,@DocuDocumento)
SELECT TOP 1 @cod  AS ID FROM DocumentoVenta
end
GO

IF OBJECT_ID(N'dbo.correlativoNroGuia', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[correlativoNroGuia] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[correlativoNroGuia] 
@dato varchar(20)
as
begin
declare @cod varchar(11)
select @cod=dbo.genenerarNroGuia(@dato)
SELECT TOP 1 isnull(@cod,'0001-000001')  AS ID FROM GuiaRemision
end
GO

IF OBJECT_ID(N'dbo.CuentaCorrienteCliente', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[CuentaCorrienteCliente] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[CuentaCorrienteCliente]
as
begin
select
'Codigo|Responsable|SaldoSol¬130|430|120¬String|String|String¬'+
isnull((select stuff((select '¬'+ convert(varchar,n.CodigoRes)+'|'+
n.Responsable+'|'+
CONVERT(VarChar(50), cast(sum(n.NotaSaldo)as money ), 1)
from NotaPedido n
inner join Cliente c
on c.ClienteId=n.ClienteId
where n.NotaConcepto='MERCADERIA' and(n.NotaSaldo>0 and n.NotaEstado<>'CANCELADO' and n.NotaEstado<>'ANULADO') and n.NotaCondicion='CREDITO'
group by n.CodigoRes,n.Responsable
order by n.Responsable asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.CuentaCorrienteProCom', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[CuentaCorrienteProCom] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[CuentaCorrienteProCom] 
@CompaniaId varchar(40)
as
begin
select isnull(SC.ProveedorId,ISNULL(DC.ProveedorId,ISNULL(LS.ProveedorId,LD.ProveedorId))) as ProveedorId
,isnull(SC.RazonSocial,ISNULL(DC.RazonSocial,ISNULL(LS.RazonSocial,LD.RazonSocial))) as ProveedorRazon,
convert(varchar(50),cast((isnull(Sum(DC.SaldoDol),0)+ isnull(sum(LD.SaldoDolLe),0))as money),1)as SaldoDol,
convert(varchar(50),cast((isnull(Sum(SC.SaldoSol),0)+ isnull(sum(LS.SaldoSolLe),0))as money),1)as SaldoSol
from
(
    select p.ProveedorId,p.ProveedorRazon as RazonSocial,Sum(c.CompraSaldo)as SaldoSol
	from Proveedor p
	inner join Compras c
	on c.ProveedorId=p.ProveedorId
	where c.CompaniaId=@CompaniaId and (c.CompraMoneda='SOLES' and c.CompraEstado='PENDIENTE DE PAGO')
	group by p.ProveedorId,p.ProveedorRazon
) SC
full join(
  select p.ProveedorId,p.ProveedorRazon as RazonSocial,Sum(c.CompraSaldo)as SaldoDol
	from Proveedor p
	inner join Compras c
	on c.ProveedorId=p.ProveedorId
	where c.CompaniaId=@CompaniaId and (c.CompraMoneda='DOLARES' and c.CompraEstado='PENDIENTE DE PAGO')
	group by p.ProveedorId,p.ProveedorRazon
)DC ON SC.ProveedorId=DC.ProveedorId
full join(
select p.ProveedorId,p.ProveedorRazon as RazonSocial,
		Sum(d.DetalleSaldo)as SaldoSolLe
	from Proveedor p
	inner join Letra l
	on l.ProveedorId=p.ProveedorId
	inner join DetalleLetra d
	on d.LetraId=l.LetraId
	where l.CompaniaId=@CompaniaId and(l.LetraMoneda='SOLES' and d.DetalleEstado='PENDIENTE')
group by p.ProveedorId,p.ProveedorRazon
)LS ON LS.ProveedorId=SC.ProveedorId
full join(
select p.ProveedorId,p.ProveedorRazon as RazonSocial,
		Sum(d.DetalleSaldo)as SaldoDolLe
	from Proveedor p
	inner join Letra l
	on l.ProveedorId=p.ProveedorId
	inner join DetalleLetra d
	on d.LetraId=l.LetraId
	where l.CompaniaId=@CompaniaId and (l.LetraMoneda='DOLARES' and d.DetalleEstado='PENDIENTE')
group by p.ProveedorId,p.ProveedorRazon
)LD ON LS.ProveedorId=LD.ProveedorId
GROUP BY SC.ProveedorId,DC.ProveedorId,LS.ProveedorId,LD.ProveedorId,
		 SC.RazonSocial,DC.RazonSocial,LS.RazonSocial,LD.RazonSocial
order by 2 asc
end
GO

IF OBJECT_ID(N'dbo.CuentaCorrienteProveedor', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[CuentaCorrienteProveedor] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[CuentaCorrienteProveedor]
as
begin
select isnull(SC.ProveedorId,ISNULL(DC.ProveedorId,ISNULL(LS.ProveedorId,LD.ProveedorId))) as ProveedorId
,isnull(SC.RazonSocial,ISNULL(DC.RazonSocial,ISNULL(LS.RazonSocial,LD.RazonSocial))) as ProveedorRazon,
convert(varchar(50),cast((isnull(Sum(DC.SaldoDol),0)+ isnull(sum(LD.SaldoDolLe),0))as money),1)as SaldoDol,
convert(varchar(50),cast((isnull(Sum(SC.SaldoSol),0)+ isnull(sum(LS.SaldoSolLe),0))as money),1)as SaldoSol
from
(
    select p.ProveedorId,p.ProveedorRazon as RazonSocial,Sum(c.CompraSaldo)as SaldoSol
	from Proveedor p
	inner join Compras c
	on c.ProveedorId=p.ProveedorId
	where c.CompraMoneda='SOLES' and c.CompraEstado='PENDIENTE DE PAGO'
	group by p.ProveedorId,p.ProveedorRazon
) SC
full join(
  select p.ProveedorId,p.ProveedorRazon as RazonSocial,Sum(c.CompraSaldo)as SaldoDol
	from Proveedor p
	inner join Compras c
	on c.ProveedorId=p.ProveedorId
	where c.CompraMoneda='DOLARES' and c.CompraEstado='PENDIENTE DE PAGO'
	group by p.ProveedorId,p.ProveedorRazon
)DC ON SC.ProveedorId=DC.ProveedorId
full join(
select p.ProveedorId,p.ProveedorRazon as RazonSocial,
		Sum(d.DetalleSaldo)as SaldoSolLe
	from Proveedor p
	inner join Letra l
	on l.ProveedorId=p.ProveedorId
	inner join DetalleLetra d
	on d.LetraId=l.LetraId
	where l.LetraMoneda='SOLES' and d.DetalleEstado='PENDIENTE'
group by p.ProveedorId,p.ProveedorRazon
)LS ON LS.ProveedorId=SC.ProveedorId
full join(
select p.ProveedorId,p.ProveedorRazon as RazonSocial,
		Sum(d.DetalleSaldo)as SaldoDolLe
	from Proveedor p
	inner join Letra l
	on l.ProveedorId=p.ProveedorId
	inner join DetalleLetra d
	on d.LetraId=l.LetraId
	where l.LetraMoneda='DOLARES' and d.DetalleEstado='PENDIENTE'
group by p.ProveedorId,p.ProveedorRazon
)LD ON LS.ProveedorId=LD.ProveedorId
GROUP BY SC.ProveedorId,DC.ProveedorId,LS.ProveedorId,LD.ProveedorId,
		 SC.RazonSocial,DC.RazonSocial,LS.RazonSocial,LD.RazonSocial
order by 2 asc
end
GO

IF OBJECT_ID(N'dbo.CuentasCorreienteCompania', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[CuentasCorreienteCompania] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[CuentasCorreienteCompania]
as
begin
select 
isnull(SC.CompaniaId,ISNULL(DC.CompaniaId,ISNULL(LS.CompaniaId,LD.CompaniaId))) as CompaniaId
,isnull(SC.RazonSocial,ISNULL(DC.RazonSocial,ISNULL(LS.RazonSocial,LD.RazonSocial))) as RazonSocial,
convert(varchar(50),cast((isnull(Sum(DC.SaldoDol),0)+ isnull(sum(LD.SaldoDolLe),0))as money),1)as SaldoDol,
convert(varchar(50),cast((isnull(Sum(SC.SaldoSol),0)+ isnull(sum(LS.SaldoSolLe),0))as money),1)as SaldoSol
from
(
select co.CompaniaId,co.CompaniaRazonSocial as RazonSocial,
sum(c.CompraSaldo)SaldoSol
from Compania co
inner join Compras c
on c.CompaniaId=co.CompaniaId
where c.CompraMoneda='SOLES' AND c.CompraEstado='PENDIENTE DE PAGO'
group by co.CompaniaId,co.CompaniaRazonSocial
) SC
FULL JOIN 
(
select co.CompaniaId,co.CompaniaRazonSocial as RazonSocial,
sum(c.CompraSaldo)as SaldoDol
from Compania co
inner join Compras c
on c.CompaniaId=co.CompaniaId
where c.CompraMoneda='DOLARES' AND c.CompraEstado='PENDIENTE DE PAGO'
group by co.CompaniaId,co.CompaniaRazonSocial
)DC ON DC.CompaniaId=SC.CompaniaId
full join
(
select l.CompaniaId,co.CompaniaRazonSocial as RazonSocial,SUM(d.DetalleSaldo) as SaldoSolLe
from DetalleLetra d
inner join Letra l
on l.LetraId=d.LetraId
inner join Compania co
on co.CompaniaId=l.CompaniaId
where d.DetalleEstado='PENDIENTE' and l.LetraMoneda='SOLES'
group by l.CompaniaId,co.CompaniaRazonSocial
)LS on LS.CompaniaId=SC.CompaniaId
full join(
select l.CompaniaId,co.CompaniaRazonSocial as RazonSocial,SUM(d.DetalleSaldo) as SaldoDolLe
from DetalleLetra d
inner join Letra l
on l.LetraId=d.LetraId
inner join Compania co
on co.CompaniaId=l.CompaniaId
where d.DetalleEstado='PENDIENTE' and l.LetraMoneda='DOLARES'
group by l.CompaniaId,co.CompaniaRazonSocial
)LD on LD.CompaniaId=LS.CompaniaId
GROUP BY SC.CompaniaId,DC.CompaniaId,LS.CompaniaId,LD.CompaniaId,
		 SC.RazonSocial,DC.RazonSocial,LS.RazonSocial,LD.RazonSocial
order by 2 asc
end
GO

IF OBJECT_ID(N'dbo.desminuirSaldo', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[desminuirSaldo] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[desminuirSaldo]
@Cantidad decimal(18,2),
@IdProducto numeric(38)
as
update Stock
set Cantidad=Cantidad-@Cantidad
where IdProducto=@IdProducto
GO

IF OBJECT_ID(N'dbo.desminuirServicio', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[desminuirServicio] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[desminuirServicio]
@Cantidad decimal(18,2),
@IdProducto numeric(38)
as
update Stock
set Cantidad=Cantidad-@Cantidad
where IdProducto=@IdProducto
GO

IF OBJECT_ID(N'dbo.DeudaCliente', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[DeudaCliente] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[DeudaCliente]
@Codigo nvarchar(80)
as
begin
select
'Codigo|Cliente|FechaEmision|Documento|SaldoDocu|TotalDocu¬110|275|110|120|110|110¬String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,n.CodigoRes)+'|'+c.ClienteRazon+'|'+
(Convert(char(10),n.NotaFecha,103))+'|'+
n.NotaSerie+'-'+n.NotaNumero+'|'+
convert(varchar(max),cast(n.NotaSaldo as money),1)+'|'+
convert(varchar(max),cast(n.NotaPagar as money),1) 
from NotaPedido n
inner join Cliente c
on c.ClienteId=n.ClienteId
where  n.NotaConcepto='MERCADERIA' and(n.CodigoRes=@Codigo and ((n.NotaSaldo>0 and n.NotaEstado<>'CANCELADO' and n.NotaEstado<>'ANULADO') and n.NotaCondicion='CREDITO'))
order by n.NotaId desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.DeudasProveedor', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[DeudasProveedor] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[DeudasProveedor] @ProveedorId numeric(38)
as
begin
select c.ProveedorId,c.CompraId,
(Convert(char(10),c.CompraEmision,103)) as CompraEmision,
substring(t.TipoDescripcion,1,1)+'C '+c.CompraSerie+'-'+c.CompraNumero as Documento,
(Convert(char(10),c.CompraFechaPago,103)) as Vencimiento,
c.CompraMoneda as Moneda,
c.CompraTipoCambio as TipoCambio,
convert(varchar(50),cast(c.CompraSaldo as money),1) as SaldoDoc,
convert(varchar(50),cast(c.CompraTotal as money),1) as MontoDoc
from Compras c
inner join TipoComprobante t
on t.TipoCodigo=c.TipoCodigo
where c.ProveedorId=@ProveedorId and c.CompraEstado='PENDIENTE DE PAGO'
union all
select l.ProveedorId,d.LetraId,(Convert(char(10),l.LetraFechaGiro,103))as LetraFechaGiro,
'LT '+d.LetraCanje as Documento,(Convert(char(10),d.LetraVencimiento,103))as LetraVencimiento,
l.LetraMoneda,'3.276' as TipoCambio,
convert(varchar(50),cast(d.DetalleSaldo as money),1) as DetalleSaldo,
convert(varchar(50),cast(d.DetalleMonto as money),1) as DetalleMonto
from DetalleLetra d
inner join Letra l
on l.LetraId=d.LetraId
where l.ProveedorId=@ProveedorId and d.DetalleEstado='PENDIENTE'
end
GO

IF OBJECT_ID(N'dbo.DeudasProveedorA', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[DeudasProveedorA] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[DeudasProveedorA]
as
begin
select c.CompraId,(Convert(char(10),c.CompraEmision,103)) as CompraEmision,substring(t.TipoDescripcion,1,1)+'C '+c.CompraSerie+'-'+c.CompraNumero as Documento,
(Convert(char(10),c.CompraFechaPago,103)) as Vencimiento,c.CompraMoneda as Moneda,c.CompraTipoCambio as TipoCambio,
CONVERT(VarChar(50),cast(c.CompraSaldo as money ), 1) as SaldoDoc,CONVERT(VarChar(50),cast(c.CompraTotal as money ), 1) as MontoDoc
from Compras c
inner join TipoComprobante t
on t.TipoCodigo=c.TipoCodigo
where c.CompraEstado='PENDIENTE DE PAGO'
order by c.CompraFechaPago asc
end
GO

IF OBJECT_ID(N'dbo.DeudasProveedorC', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[DeudasProveedorC] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[DeudasProveedorC] 
@CompaniaId varchar(40),
@ProveedorId numeric(38)
as
begin
select c.ProveedorId,c.CompraId,
(Convert(char(10),c.CompraEmision,103)) as CompraEmision,
substring(t.TipoDescripcion,1,1)+'C '+c.CompraSerie+'-'+c.CompraNumero as Documento,
(Convert(char(10),c.CompraFechaPago,103)) as Vencimiento,
c.CompraMoneda as Moneda,
c.CompraTipoCambio as TipoCambio,
convert(varchar(50),cast(c.CompraSaldo as money),1) as SaldoDoc,
convert(varchar(50),cast(c.CompraTotal as money),1) as MontoDoc
from Compras c
inner join TipoComprobante t
on t.TipoCodigo=c.TipoCodigo
where (c.CompaniaId=@CompaniaId and c.ProveedorId=@ProveedorId) and c.CompraEstado='PENDIENTE DE PAGO'
union all
select l.ProveedorId,d.LetraId,(Convert(char(10),l.LetraFechaGiro,103))as LetraFechaGiro,
'LT '+d.LetraCanje as Documento,(Convert(char(10),d.LetraVencimiento,103))as LetraVencimiento,
l.LetraMoneda,'3.276' as TipoCambio,
convert(varchar(50),cast(d.DetalleSaldo as money),1) as DetalleSaldo,
convert(varchar(50),cast(d.DetalleMonto as money),1) as DetalleMonto
from DetalleLetra d
inner join Letra l
on l.LetraId=d.LetraId
where (l.CompaniaId=@CompaniaId and l.ProveedorId=@ProveedorId) and d.DetalleEstado='PENDIENTE'
end
GO

IF OBJECT_ID(N'dbo.editaDescontinuado', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editaDescontinuado] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editaDescontinuado]
@Data varchar(max)
as
Set @Data =LTRIM(RTrim(@Data))
	Declare @pos1 int
	declare @IdProducto numeric(20)
Set @pos1 = Len(@Data)+1
Set @IdProducto=convert(numeric(20),SUBSTRING(@Data,1,@pos1-1))
begin
	update Producto
	set ProductoEstado='BUENO'
	where IdProducto=@IdProducto
	select isnull((select STUFF((select '¬'+convert(varchar,p.IdProducto)+'|'+p.ProductoCodigo+'|'+
	p.ProductoNombre+' '+p.ProductoMarca+'|'+convert(varchar(50),cast(p.ProductoCantidad as money),1)+'|'+ 
	p.ProductoUM+'|'+convert(varchar(50),cast(p.ProductoVenta as money),1)+'|'+
	convert(varchar(50),cast(p.ProductoVenta as money),1)+'|'+convert(varchar,p.ProductoCosto)+'|'+
	convert(varchar,ProductoCostoDolar)+'|'+convert(varchar,ProductoTipoCambio)+'|'+
	p.ProductoEstado+'|'+p.ProductoUsuario+'|'+p.ProductoImagen
	FROM Producto p with(nolock)
	where p.ProductoEstado='DESCONTINUADO'
	order by p.ProductoNombre+' '+p.ProductoMarca asc
	for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.editaDetaCompra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editaDetaCompra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editaDetaCompra]
@Data varchar(max)
as
begin
Declare @pos1 int
Declare @pos2 int
Declare @pos3 int
Declare @pos4 int
Declare @pos5 int
Declare @pos6 int
declare @Id numeric(38),
@cantidad decimal(18,2),
@precioCosto decimal(18,4),
@Descuento decimal(18,4),
@importe decimal(18,2),
@CompraId numeric(38)
Set @Data = LTRIM(RTrim(@Data))
Set @pos1 = CharIndex('|',@Data,0)
Set @Id =convert(numeric(38),SUBSTRING(@Data,1,@pos1-1))
Set @pos2 = CharIndex('|',@Data,@pos1+1)
Set @cantidad=convert(decimal(18,2),SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1))
Set @pos3 = CharIndex('|',@Data,@pos2+1)
Set @precioCosto=convert(decimal(18,4),SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1))
Set @pos4 = CharIndex('|',@Data,@pos3+1)
Set @Descuento=convert(decimal(18,4),SUBSTRING(@Data,@pos3+1,@pos4-@pos3-1))
Set @pos5= CharIndex('|',@Data,@pos4+1)
Set @importe=convert(decimal(18,4),SUBSTRING(@Data,@pos4+1,@pos5-@pos4-1))
Set @pos6 =Len(@Data)+1
Set @CompraId=convert(numeric(38),SUBSTRING(@Data,@pos5+1,@pos6-@pos5-1))
update DetalleCompra
set DetalleCantidad=@cantidad,PrecioCosto=@precioCosto,
DetalleDescuento=@Descuento,DetalleImporte=@importe
where DetalleId=@Id
select isnull((select STUFF ((select '¬'+convert(varchar,u.IdUm)+'|'+convert(varchar,u.IdProducto)+'|'+
u.UMDescripcion+'|'+CONVERT(VarChar(50), cast(u.ValorUM as money ), 1)+'|'+
convert(varchar,d.PrecioCosto)
from UnidadMedida u
inner join DetalleCompra d
on d.IdProducto=u.IdProducto
where d.CompraId=@CompraId
order by u.ValorUM asc
for xml path('')),1,1,'')),'true')
end
GO

IF OBJECT_ID(N'dbo.editaDetaLiVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editaDetaLiVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editaDetaLiVenta]
@DetalleId numeric(38),
@EntidadBanco varchar(80),
@NroOperacion varchar(80),
@FechaPago varchar(60)
as
begin
update DetaLiquidaVenta
set EntidadBanco=@EntidadBanco,NroOperacion=@NroOperacion,FechaPago=@FechaPago
where DetalleId=@DetalleId
end
GO

IF OBJECT_ID(N'dbo.editaGuiacanje', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editaGuiacanje] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editaGuiacanje]
@CanjeId numeric(38),
@CompraId numeric(38),
@CompaniaId int,
@CanjeFecha date,
@CanjeRegistro datetime,
@CanjeSerie varchar(80),
@CanjeNumero varchar(80),
@CanjeEmision date,
@CanjeComputo date,
@CanjeCorrelativo varchar(80),
@CanjeTipo varchar(80),
@CanjeOBS varchar(max),
@TCSunat decimal(18,3),
@Usuario varchar(80),
@Subtotal decimal(18,2),
@Igv decimal(18,2),
@Total decimal(18,2)
as
begin
update GuiaCanje
set CompaniaId=@CompaniaId,CanjeFecha=@CanjeFecha,CanjeRegistro=@CanjeRegistro,
CanjeSerie=@CanjeSerie,CanjeNumero=@CanjeNumero,CanjeEmision=@CanjeEmision,CanjeComputo=@CanjeComputo,
CanjeCorrelativo=@CanjeCorrelativo,CanjeTipo=@CanjeTipo,CanjeOBS=@CanjeOBS,TCSunat=@TCSunat,CanjeUsuario=@Usuario
where CanjeId=@CanjeId
begin
update Compras
set CompaniaId=@CompaniaId,CompraSerie=@CanjeSerie,CompraNumero=@CanjeNumero,CompraEmision=@CanjeEmision,
CompraComputo=@CanjeComputo,CompraCorrelativo=@CanjeCorrelativo,CompraTipoIgv=@CanjeTipo,CompraOBS=@CanjeOBS,
CompraTipoSunat=@TCSunat,CompraUsuario=@Usuario,CompraSubtotal=@Subtotal,CompraIgv=@Igv,CompraTotal=@Total
where CompraId=@CompraId
end
end
GO

IF OBJECT_ID(N'dbo.editaNotaLD', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editaNotaLD] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editaNotaLD]
@Data varchar(max)
as
begin
declare @p0 int,@p1 int,@p2 int,
		@p3 int,@p4 int,@p5 int,
		@p6 int,@p7 int
declare @DetalleId numeric(38),
		@Cantidad decimal(18,2),
		@Costo decimal(18,2),
		@PrecioUni decimal(18,2),
		@DetallePV decimal(18,2),
		@DetalleSV decimal(18,2),
		@Importe decimal(18,2),
		@Ganancia decimal(18,2),
		@NotaId numeric(38)		
Set @Data= LTRIM(RTrim(@Data))
set @p0 = CharIndex('|',@Data,0)
Set @p1 = CharIndex('|',@Data,@p0+1)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 = CharIndex('|',@Data,@p2+1)
Set @p4 = CharIndex('|',@Data,@p3+1)
Set @p5 = CharIndex('|',@Data,@p4+1)
Set @p6 = CharIndex('|',@Data,@p5+1)
Set @p7=Len(@Data)+1
Set @DetalleId=Convert(numeric(38),SUBSTRING(@Data,1,@p0-1))
Set @Cantidad=Convert(decimal(18,2),SUBSTRING(@Data,@p0+1,@p1-(@p0+1)))
Set @Costo= Convert(decimal(18,2),SUBSTRING(@Data,@p1+1,@p2-(@p1+1)))
Set @PrecioUni= Convert(decimal(18,2),SUBSTRING(@Data,@p2+1,@p3-(@p2+1)))
Set @DetallePV= Convert(decimal(18,2),SUBSTRING(@Data,@p3+1,@p4-(@p3+1)))
Set @DetalleSV= Convert(decimal(18,2),SUBSTRING(@Data,@p4+1,@p5-(@p4+1)))
Set @Importe= Convert(decimal(18,2),SUBSTRING(@Data,@p5+1,@p6-(@p5+1)))
Set @Ganancia= Convert(decimal(18,2),SUBSTRING(@Data,@p6+1,@p7-@p6-1))
set @NotaId=(select NotaId from DetallePedido where DetalleId=@DetalleId)
begin
	update DetallePedido 
	set DetalleCantidad=@Cantidad,DetalleCosto=@Costo,
	DetallePrecio=@PrecioUni,DetalleImporte=@Importe,
	DetallePV=@DetallePV,DetalleSV=@DetalleSV
	where DetalleId=@DetalleId
	update NotaPedido
	set NotaGanancia=@Ganancia
	where NotaId=@NotaId
	select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.editaProductoCosto', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editaProductoCosto] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editaProductoCosto] 
@IdProducto numeric(38),
@Costo decimal(18,4),
@costoDolar decimal(18,4),
@TipoCambio decimal(18,3),
@Estado varchar(40),
@Condicion varchar(60),
@DescuentoB decimal(18,4),
@DetalleId numeric(38)
as
begin
if(@Estado<>'BONIFICACION')
begin
update Producto 
set ProductoCosto=@Costo,ProductoCostoDolar=@costoDolar,ProductoTipoCambio=@TipoCambio
where IdProducto=@IdProducto 
if (@Condicion='NOTA CREDITO')
begin
update DetalleCompra
set DescuentoB=@DescuentoB
where DetalleId=@DetalleId
end
end
end
GO

IF OBJECT_ID(N'dbo.editaprueba', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editaprueba] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editaprueba]
@ListaOrden varchar(Max)
as
begin
Declare @detalle varchar(max)
Set @detalle =@ListaOrden
Begin Transaction
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
        Declare @Columna varchar(max)
		declare @IdProducto numeric(20)
	    declare @xCaja decimal(18,2)
		Declare @p1 int
		declare @p2 int
Fetch Next From Tabla INTO @Columna
While @@FETCH_STATUS = 0
Begin
	    Set @p1 = CharIndex('|',@Columna,0)
		Set @p2 =Len(@Columna)+1
        Set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,1,@p1-1))
		Set @xCaja=convert(decimal(18,2),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
		update DetalleApertura
		set xCaja=@xCaja
		where IdProducto=@IdProducto
Fetch Next From Tabla INTO @Columna
End
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
	Select 'true';
End
GO

IF OBJECT_ID(N'dbo.editapruebaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editapruebaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editapruebaB]
@ListaOrden varchar(Max)
as
begin
Declare @detalle varchar(max)
Set @detalle =@ListaOrden
Begin Transaction
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
        Declare @Columna varchar(max)
		declare @IdProducto numeric(20)
	    declare @xCaja decimal(18,2)
		Declare @p1 int
		declare @p2 int
Fetch Next From Tabla INTO @Columna
While @@FETCH_STATUS = 0
Begin
	    Set @p1 = CharIndex('|',@Columna,0)
		Set @p2 =Len(@Columna)+1
        Set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,1,@p1-1))
		Set @xCaja=convert(decimal(18,2),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
		update DetalleCierre
		set xCaja=@xCaja
		where IdProducto=@IdProducto
Fetch Next From Tabla INTO @Columna
End
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
	Select 'true';
End
GO

IF OBJECT_ID(N'dbo.editapruebaz', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editapruebaz] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editapruebaz]
@ListaOrden varchar(Max)
as
begin
Declare @detalle varchar(max)
Set @detalle =@ListaOrden
Begin Transaction
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
        Declare @Columna varchar(max)
		declare @DocuAsociado varchar(40)
Fetch Next From Tabla INTO @Columna
While @@FETCH_STATUS = 0
Begin
        Set @DocuAsociado=@Columna
        update Kardex
        set Estado='B'
        where DocuId=@DocuAsociado
Fetch Next From Tabla INTO @Columna
End
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
	Select 'true';
End
GO

IF OBJECT_ID(N'dbo.editarCajaPri', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editarCajaPri] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editarCajaPri]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,
		@p3 int,@p4 int,
		@p5 int,@p6 int
declare @CajaConcepto varchar(80),
		@CajaDescripcion varchar(250),
		@CajaMonto decimal(18,2),
		@CajaUsuario varchar(20),
		@RutaImagen varchar(max),
		@IdCaja numeric(38)
Set @Data = LTRIM(RTrim(@Data))
		Set @p1 = CharIndex('|',@Data,0)
		Set @p2 = CharIndex('|',@Data,@p1+1)
		Set @p3 = CharIndex('|',@Data,@p2+1)
		Set @p4 = CharIndex('|',@Data,@p3+1)
		Set @p5= CharIndex('|',@Data,@p4+1)
		Set @p6= Len(@Data)+1
		Set @CajaConcepto=SUBSTRING(@Data,1,@p1-1)
		Set @CajaDescripcion=SUBSTRING(@Data,@p1+1,@p2-@p1-1)
		Set @CajaMonto=convert(decimal(18,2),SUBSTRING(@Data,@p2+1,@p3-@p2-1))
		Set @CajaUsuario=SUBSTRING(@Data,@p3+1,@p4-@p3-1)
		Set @RutaImagen=SUBSTRING(@Data,@p4+1,@p5-@p4-1)
		Set @IdCaja=convert(numeric(38),SUBSTRING(@Data,@p5+1,@p6-@p5-1))		
update CajaPincipal
set CajaConcepto=@CajaConcepto,CajaFecha=GETDATE(),
CajaDescripcion=@CajaDescripcion,CajaMonto=@CajaMonto,
RutaImagen=@RutaImagen,CajaUsuario=@CajaUsuario
where IdCaja=@IdCaja
select isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen  
from CajaPincipal c 
where c.CajaConcepto='INGRESO' and c.IdGeneral=0
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen  
from CajaPincipal c 
where c.CajaConcepto='SALIDA' and c.IdGeneral=0
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.editarCanje', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editarCanje] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editarCanje]
@temporalId numeric(38),
@temporalCanje varchar(80),
@temporalDias int,
@temporalVencimiento varchar(20),
@temporalMonto decimal(18,2)
as
begin
update TemporalCanje
set temporalCanje=@temporalCanje,temporalDias=@temporalDias,
temporalVencimiento=@temporalVencimiento,temporalMonto=@temporalMonto
where temporalId=@temporalId
end
GO

IF OBJECT_ID(N'dbo.editarCompania', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editarCompania] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editarCompania]
@CompaniaId int,
@CompaniaRazonSocial varchar(140),
@CompaniaRUC varchar(20),
@CompaniaDireccion varchar(max),
@CompaniaTelefono varchar(80),
@CompaniaEmail varchar(100),
@CompaniaIniFecha varchar(100)
as
begin
update Compania
set CompaniaRazonSocial=@CompaniaRazonSocial,
CompaniaRUC=@CompaniaRUC,CompaniaDireccion=@CompaniaDireccion,
CompaniaTelefono=@CompaniaTelefono,CompaniaEmail=@CompaniaEmail,
CompaniaIniFecha=@CompaniaIniFecha
where CompaniaId=@CompaniaId
end
GO

IF OBJECT_ID(N'dbo.editarCompra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editarCompra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editarCompra]
@CompraId numeric(38),
@CompaniaId int,
@CompraCorrelativo varchar(80),
@ProveedorId numeric(38),
@CompraEmision date,
@CompraComputo date,
@TipoCodigo char(20),
@CompraSerie varchar(60),
@CompraNumero varchar(80),
@CompraCondicion varchar(60),
@CompraMoneda varchar(60),
@CompraTipoCambio decimal(18,3),
@CompraDias int,
@CompraFechaPago date,
@CompraUsuario varchar(80),
@CompraTipoIgv varchar(60),
@CompraValorVenta decimal(18,2),
@CompraDescuento decimal(18,2),
@CompraSubtotal decimal(18,2),
@CompraIgv decimal(18,2),
@CompraTotal decimal(18,2),
@CompraEstado varchar(60),
@CompraAsociado varchar(60),
@compraSaldo decimal(18,2),
@CompraOBS varchar(max),
@CompraTipoSunat decimal(18,3)
as 
begin
update Compras
set CompaniaId=@CompaniaId,CompraCorrelativo=@CompraCorrelativo,ProveedorId=@ProveedorId,
CompraRegistro=GETDATE(),CompraEmision=@CompraEmision,CompraComputo=@CompraComputo,
TipoCodigo=@TipoCodigo,CompraSerie=@CompraSerie,CompraNumero=@CompraNumero,CompraCondicion=@CompraCondicion,
CompraMoneda=@CompraMoneda,CompraTipoCambio=@CompraTipoCambio,CompraDias=@CompraDias,CompraFechaPago=@CompraFechaPago,
CompraUsuario=@CompraUsuario,CompraTipoIgv=@CompraTipoIgv,CompraValorVenta=@CompraValorVenta,
CompraDescuento=@CompraDescuento,CompraSubtotal=@CompraSubtotal,CompraIgv=@CompraIgv,CompraTotal=@CompraTotal,
CompraEstado=@CompraEstado,CompraAsociado=@CompraAsociado,CompraSaldo=@compraSaldo,CompraOBS=@CompraOBS,
CompraTipoSunat=@CompraTipoSunat
where CompraId=@CompraId
end
GO

IF OBJECT_ID(N'dbo.editarDetaLiquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editarDetaLiquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editarDetaLiquida]
@DetalleId numeric(38),
@EntidadBanco varchar(80),
@NroOperacion varchar(80),
@FechaPago varchar(60)
as
begin
update DetalleLiquida
set EntidadBanco=@EntidadBanco,NroOperacion=@NroOperacion,FechaPago=@FechaPago
where DetalleId=@DetalleId
end
GO

IF OBJECT_ID(N'dbo.editarLiquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editarLiquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editarLiquida]
@LiquidacionId numeric(38),
@LiquidacionRegistro datetime,
@LiquidacionFecha date,
@LiquidacionDescripcion varchar(250),
@LiquidacionCambio decimal(18,3),
@LiquidaEfectivoSol decimal(18,2),
@LiquidaDepositoSol decimal(18,2),
@LiquidaTotalSol decimal(18,2),
@LiquidaEfectivoDol decimal(18,2),
@LiquidaDepositoDol decimal(18,2),
@LiquidaTotalDol decimal(18,2),
@LiquidaUsuario varchar(60)
as
begin
update Liquidacion
set LiquidacionRegistro=@LiquidacionRegistro,LiquidacionFecha=@LiquidacionFecha,
LiquidacionDescripcion=@LiquidacionDescripcion,LiquidacionCambio=@LiquidacionCambio,
LiquidaEfectivoSol=@LiquidaEfectivoSol,LiquidaDepositoSol=@LiquidaDepositoSol,
LiquidaTotalSol=@LiquidaTotalSol,LiquidaEfectivoDol=@LiquidaEfectivoDol,
LiquidaDepositoDol=@LiquidaDepositoDol,LiquidaTotalDol=@LiquidaTotalDol,
LiquidaUsuario=@LiquidaUsuario
where LiquidacionId=@LiquidacionId
end
GO

IF OBJECT_ID(N'dbo.editarLiquidaVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editarLiquidaVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editarLiquidaVenta]
@LiquidacionId numeric(38),
@LiquidacionRegistro datetime,
@LiquidacionFecha date,
@LiquidacionDescripcion varchar(250),
@LiquidacionCambio decimal(18,3),
@LiquidaEfectivoSol decimal(18,2),
@LiquidaDepositoSol decimal(18,2),
@LiquidaTotalSol decimal(18,2),
@LiquidaEfectivoDol decimal(18,2),
@LiquidaDepositoDol decimal(18,2),
@LiquidaTotalDol decimal(18,2),
@LiquidaUsuario varchar(60)
as
begin
update LiquidacionVenta
set LiquidacionRegistro=@LiquidacionRegistro,LiquidacionFecha=@LiquidacionFecha,
LiquidacionDescripcion=@LiquidacionDescripcion,LiquidacionCambio=@LiquidacionCambio,
LiquidaEfectivoSol=@LiquidaEfectivoSol,LiquidaDepositoSol=@LiquidaDepositoSol,
LiquidaTotalSol=@LiquidaTotalSol,LiquidaEfectivoDol=@LiquidaEfectivoDol,
LiquidaDepositoDol=@LiquidaDepositoDol,LiquidaTotalDol=@LiquidaTotalDol,
LiquidaUsuario=@LiquidaUsuario
where LiquidacionId=@LiquidacionId
end
GO

IF OBJECT_ID(N'dbo.editarNOta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editarNOta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editarNOta]
@NotaId numeric(38),
@NotaDocu varchar(60),
@ClienteId numeric(20),
@NotaFecha datetime,
@NotaUsuario varchar(60),
@NotaSubtotal decimal(8,2),
@NotaDescuento decimal(18,2),
@NotaTotal decimal(18,2),
@NotaEstado varchar(60)
as
begin
update NotaPedido
set NotaDocu=@NotaDocu,ClienteId=@ClienteId,NotaFecha=@NotaFecha,NotaUsuario=@NotaUsuario,NotaSubtotal=@NotaSubtotal,NotaDescuento=@NotaDescuento,NotaTotal=@NotaTotal,NotaEstado=@NotaEstado
where NotaId=@NotaId
end
GO

IF OBJECT_ID(N'dbo.editarPersonal', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editarPersonal] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editarPersonal]
@PersonalId numeric(20),
@PersonalNombres varchar(140),
@PersonalApellidos varchar(140),
@AreaId numeric(20),
@PersonalCodigo varchar (80),
@PersonalNacimiento date,
@PersonalIngreso varchar(20),
@PersonalDNI varchar(20),
@PersonalDireccion varchar(140),
@PersonalTelefono varchar(40),
@PersonalTelefonoAsi varchar(40),
@PersonalEmail varchar(100),
@PersonalSueldo decimal(18,2),
@PersonalEstado varchar(60),
@PersonalBajaFecha varchar(60),
@PersonalRuc varchar(20),
@PersonalImagen varchar(max),
@CompaniaId int
as
begin
update Personal
set PersonalNombres=@PersonalNombres,PersonalApellidos=@PersonalApellidos,AreaId=@AreaId,PersonalCodigo=@PersonalCodigo,PersonalNacimiento=@PersonalNacimiento,
PersonalIngreso=@PersonalIngreso,PersonalDNI=@PersonalDNI,PersonalDireccion=@PersonalDireccion,PersonalTelefono=@PersonalTelefono,
PersonalTelefonoAsi=@PersonalTelefonoAsi,PersonalEmail=@PersonalEmail,PersonalSueldo=@PersonalSueldo,PersonalEstado=@PersonalEstado,
PersonalBajaFecha=@PersonalBajaFecha,PersonalRuc=@PersonalRuc,PersonalImagen=@PersonalImagen,CompaniaId=@CompaniaId
where PersonalId=@PersonalId
end
GO

IF OBJECT_ID(N'dbo.editarProducto', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editarProducto] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editarProducto]
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
 insert into Kardex values(@IdProducto,Getdate(),'Edita Costo','Edita Costo',
 @inicial,0,0,@ProductoCosto,@inicial,'INGRESO',@ProductoUsuario,'','','','','','','S','','','E')
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
 insert into Kardex values(@IdProducto,Getdate(),'Edita Cantidad','Edita Cantidad',
 @inicial,0,0,@ProductoCosto,@ProductoCantidad,'INGRESO',@ProductoUsuario,'','','','','','','S','','','E')
 end
GO

IF OBJECT_ID(N'dbo.editarTemLiquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editarTemLiquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editarTemLiquida] 
@TemporalId numeric(38),
@EfectivoSoles decimal(18,2),
@EfectivoDolar decimal(18,2),
@DepositoSoles decimal(18,2),
@DepositoDolar decimal(18,2),
@TipoCambio decimal(18,3),
@EntidadBanco varchar(80),
@NroOperacion varchar(80),
@AcuentaGeneral decimal(18,2),
@TemporalFecha varchar(60)
as
begin
update TemporalLiquida
set EfectivoSoles=@EfectivoSoles,EfectivoDolar=@EfectivoDolar,
DepositoSoles=@DepositoSoles,DepositoDolar=@DepositoDolar,
TipoCambio=@TipoCambio,EntidadBanco=@EntidadBanco,NroOperacion=@NroOperacion,
AcuentaGeneral=@AcuentaGeneral,TemporalFecha=@TemporalFecha
where TemporalId=@TemporalId
end
GO

IF OBJECT_ID(N'dbo.editarTemLiVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editarTemLiVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editarTemLiVenta] 
@TemporalId numeric(38),
@EfectivoSoles decimal(18,2),
@EfectivoDolar decimal(18,2),
@DepositoSoles decimal(18,2),
@DepositoDolar decimal(18,2),
@TipoCambio decimal(18,3),
@EntidadBanco varchar(80),
@NroOperacion varchar(80),
@AcuentaGeneral decimal(18,2),
@TemporalFecha varchar(60)
as
begin
update TemporalLiVenta
set EfectivoSoles=@EfectivoSoles,EfectivoDolar=@EfectivoDolar,
DepositoSoles=@DepositoSoles,DepositoDolar=@DepositoDolar,
TipoCambio=@TipoCambio,EntidadBanco=@EntidadBanco,NroOperacion=@NroOperacion,
AcuentaGeneral=@AcuentaGeneral,TemporalFecha=@TemporalFecha
where TemporalId=@TemporalId
end
GO

IF OBJECT_ID(N'dbo.editarUsuario', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[editarUsuario] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[editarUsuario] 
@UsuarioId int,
@UsuarioAlias varchar(60),
@UsuarioClave varchar(40),
@UsuarioEstado varchar(40)
as
begin
update Usuarios 
set UsuarioAlias=@UsuarioAlias,UsuarioClave=dbo.encriptar(@UsuarioClave),
UsuarioFechaReg=GETDATE(),Usuarioestado=@UsuarioEstado
where UsuarioID=@UsuarioId
end
GO

IF OBJECT_ID(N'dbo.eliminaCuenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminaCuenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminaCuenta]
@Data varchar(max)
as
begin
    Set @Data = LTRIM(RTrim(@Data))
	Declare @pos1 int,@pos2 int
	declare @CuentaId numeric(38),@ProveedorId numeric(38)
	declare @contador int
Set @pos1 = CharIndex('|',@Data,0)
Set @CuentaId=convert(numeric(38),SUBSTRING(@Data,1,@pos1-1))
Set @pos2 =Len(@Data)+1
Set @ProveedorId=convert(numeric(38),SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1))
	delete from CuentaProveedor
	where CuentaId=@CuentaId
set @contador=(select COUNT(*) from CuentaProveedor where ProveedorId=@ProveedorId)	
if 	@contador<=0
begin
	select 'true'
end
else
begin
	select isnull((select STUFF ((select '¬'+ CONVERT(varchar,c.CuentaId)+'|'+c.Entidad+'|'+
	c.TipoCuenta+'|'+c.Moneda+'|'+c.NroCuenta
	from CuentaProveedor c
	where c.ProveedorId=@ProveedorId
	order by c.CuentaId desc
	for xml path('')),1,1,'')),'~')
end
end
GO

IF OBJECT_ID(N'dbo.eliminaDetaCaja', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminaDetaCaja] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminaDetaCaja]
@DetalleId numeric(38),
@NotaId numeric(38),
@Monto decimal(18,2)
as
begin
declare @Acuenta decimal(18,2),@EstadoDocu varchar(80)
update NotaPedido
set NotaSaldo=NotaSaldo + @Monto,NotaAcuenta=NotaAcuenta-@Monto
where NotaId=@NotaId
set @Acuenta=(select NotaAcuenta from NotaPedido where NotaId=@NotaId)
set @EstadoDocu=(select top 1 DocuEstado from DocumentoVenta where NotaId=@NotaId)
if @EstadoDocu='ANULADO'
begin
update NotaPedido 
set NotaEstado='ANULADO'
where NotaId=@NotaId
end
else
begin
if @Acuenta<=0
begin
update NotaPedido 
set NotaEstado='PENDIENTE'
where NotaId=@NotaId
end
else
begin
update NotaPedido 
set NotaEstado='ACUENTA'
where NotaId=@NotaId
end
end
delete from CajaDetalle 
where DetalleId=@DetalleId
end
GO

IF OBJECT_ID(N'dbo.eliminaDetaLiquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminaDetaLiquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminaDetaLiquida] 
@DetalleId numeric(38),
@CompraId numeric(18,2),
@Acuenta decimal(18,2),
@Concepto varchar(40)
as
begin
if(@Concepto='LETRA')
begin
update DetalleLetra
set DetalleSaldo=DetalleSaldo+@Acuenta,DetalleEstado='PENDIENTE DE PAGO'
where DetalleId=@CompraId
end
else
begin
update Compras
set CompraSaldo=CompraSaldo+@Acuenta,CompraEstado='PENDIENTE DE PAGO'
where CompraId=@CompraId
end
begin
delete from DetalleLiquida
where DetalleId=@DetalleId
end
end
GO

IF OBJECT_ID(N'dbo.eliminaDetaLiVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminaDetaLiVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminaDetaLiVenta] @DetalleId numeric(38),@DocuId numeric(38),@NotaId numeric(38),@Acuenta decimal(18,2)
as
BEGIN TRANSACTION
update DocumentoVenta
set DocuSaldo=DocuSaldo+@Acuenta,DocuEstado='EMITIDO'
where DocuId=@DocuId
update NotaPedido
set NotaSaldo=NotaSaldo + @Acuenta,NotaEstado='EMITIDO'
where NotaId=@NotaId
delete from DetaLiquidaVenta
where DetalleId=@DetalleId
commit
GO

IF OBJECT_ID(N'dbo.eliminaDetaNota', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminaDetaNota] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminaDetaNota]
@Data varchar(max)
as
begin
declare @p0 int, 
        @p1 int
declare @DetalleId numeric(38),
        @Ganancia decimal(18,2),
        @NotaId numeric(38),
        @Estado varchar(80)
Set @Data= LTRIM(RTrim(@Data))
set @p0 = CharIndex('|',@Data,0)
Set @p1 = Len(@Data)+1
Set @DetalleId=Convert(numeric(38),SUBSTRING(@Data,1,@p0-1))
Set @Ganancia= Convert(decimal(18,2),SUBSTRING(@Data,@p0+1,@p1-@p0-1))
set @NotaId=(select NotaId from DetallePedido where DetalleId=@DetalleId)
begin
	delete from DetallePedido 
	where DetalleId=@DetalleId
	update NotaPedido
	set NotaGanancia=NotaGanancia-@Ganancia
	where NotaId=@NotaId
set @Estado=(select top 1 n.NotaEstado from NotaPedido n where n.NotaId=@NotaId)
select
isnull((select stuff((select '¬'+convert(varchar,d.DetalleId)+'|'+convert(varchar,d.NotaId)+'|'+
convert(varchar,d.IdProducto)+'|'+p.ProductoCodigo+'|'+
CONVERT(VarChar(50), cast(d.DetalleCantidad as money ), 1)+'|'+
d.DetalleUm+'|'+d.DetalleDescripcion+'|'+
case when @Estado='PENDIENTE' then 
CONVERT(VarChar(50), cast((p.ProductoCosto * d.ValorUm) as money ), 1)
else
CONVERT(VarChar(50), cast(d.DetalleCosto as money ), 1)
end+'|'+
CONVERT(VarChar(50), cast(d.DetallePrecio as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetallePV as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleSV as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleImporte as money ), 1)+'|'+
p.ProductoImagen+'|'+CONVERT(varchar,d.ValorUM)+'|'+
convert(varchar,convert(decimal(18,2),d.DetallePrecio/1.18))+'|'+
convert(varchar,(d.DetalleImporte - convert(decimal(18,2),d.DetalleImporte/1.18)))+'|'+
convert(varchar,convert(decimal(18,2),d.DetalleImporte/1.18))+'|'+
convert(varchar,p.ProductoPV)+'|'+convert(varchar,p.ProductoSV)+'|'+
s.NombreSublinea+'|'+p.AplicaFB
from DetallePedido d
inner join Producto p
on p.IdProducto=d.IdProducto
inner join Sublinea s
on s.IdSubLinea=p.IdSubLinea
where d.NotaId=@NotaId
order by d.DetalleId asc
FOR XML PATH('')), 1, 1, '')),'~')
end
end
GO

IF OBJECT_ID(N'dbo.eliminaGuiaRe', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminaGuiaRe] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminaGuiaRe]
@GuiaId numeric(38),
@NotaId numeric(38)
as
begin
begin
update GuiaRemision
set GuiaEstado=''
where GuiaId=@GuiaId
end
begin
delete from GuiaRelacion
where NotaId=@NotaId
end
end
GO

IF OBJECT_ID(N'dbo.eliminarCajaPrin', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminarCajaPrin] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminarCajaPrin]
@Data varchar(max)
as
begin
Declare @p1 int
Declare @IdCaja numeric(38)
Set @Data = LTRIM(RTrim(@Data))
Set @p1= Len(@Data)+1
Set @IdCaja=convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
begin
delete from CajaPincipal 
where IdCaja=@IdCaja
select isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen  
from CajaPincipal c 
where c.CajaConcepto='INGRESO' and c.IdGeneral=0
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen 
from CajaPincipal c 
where c.CajaConcepto='SALIDA' and c.IdGeneral=0
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')
end
end
GO

IF OBJECT_ID(N'dbo.eliminarCanje', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminarCanje] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminarCanje]
@CanjeId numeric(38),@CompraId numeric(38),@GTCSunat decimal(18,3),
@GCompania int,@GSerie varchar(80),
@GNumero varchar(80),@GEmision date,
@GComputo date,@GCorrelativo varchar(80),
@GTipo varchar(80),@GOBS varchar(max),
@Usuario varchar(60),@Monto decimal(18,2)
as
declare @Subtotal decimal(18,2),@Igv decimal(18,2),@Total decimal(18,2)
IF @GTipo ='DISGREGADO'
begin
set @Subtotal=@Monto
set @Igv=@Subtotal * 0.18
set @Total=@Subtotal + @Igv
end   
ELSE If @GTipo='INCLUIDO'
begin
set @Subtotal=@Monto/1.18
set @Igv=@Monto-(@Monto/1.18)
set @Total=@Monto
end
Else
begin
set @Subtotal=@Monto
set @Igv=0
set @Total=@Monto
end
begin
update Compras
set CompaniaId=@GCompania,CompraTipoSunat=@GTCSunat,CompraSerie=@GSerie,CompraNumero=@GNumero,CompraEmision=@GEmision,
CompraComputo=@GComputo,CompraCorrelativo=@GCorrelativo,CompraTipoIgv=@GTipo,CompraOBS=@GOBS,TipoCodigo='09',CompraUsuario=@Usuario,
CompraSubtotal=@Subtotal,CompraIgv=@Igv,CompraTotal=@Total
where CompraId=@CompraId
begin
delete from GuiaCanje
where CanjeId=@CanjeId
end
end
GO

IF OBJECT_ID(N'dbo.eliminarCompra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminarCompra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminarCompra] 
@CompraId numeric(38)
as
begin
delete from DetalleCompra 
where CompraId=@CompraId
end
begin
delete from Compras
where CompraId=@CompraId
end
GO

IF OBJECT_ID(N'dbo.eliminarDocumento', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminarDocumento] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminarDocumento]
@DocuId numeric(38)
as
begin
delete from DetalleDocumento 
where DocuId=@DocuId
end
begin
delete from DocumentoVenta
where DocuId=@DocuId
end
GO

IF OBJECT_ID(N'dbo.eliminarGeneral', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminarGeneral] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminarGeneral]
@Data varchar(max)
as
begin
Declare @IdGeneral numeric(38)
set @IdGeneral=@Data
	delete from CajaGeneral
	where IdGeneral=@IdGeneral
	update CajaPincipal
	set IdGeneral=0
	where IdGeneral=@IdGeneral
end
begin
select isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen  
from CajaPincipal c 
where c.CajaConcepto='INGRESO' and c.IdGeneral=0
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen 
from CajaPincipal c 
where c.CajaConcepto='SALIDA' and c.IdGeneral=0
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')+'['+
isnull((select STUFF ((select '¬'+ CONVERT(varchar,c.IdGeneral)+'|'+
(IsNull(convert(varchar,c.FechaCierre,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,c.FechaCierre,114),1,8),''))+'|'+c.Usuario+'|'+
CONVERT(varchar(50),cast(c.Ingresos as money),1)+'|'+CONVERT(varchar(50),cast(c.Salidas as money),1)+'|'+
CONVERT(varchar(50),cast(c.Total as money),1)
from CajaGeneral c
order by c.IdGeneral desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.eliminarGuia', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminarGuia] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminarGuia] 
@GuiaId numeric(38)
as
begin
delete from DetalleGuia
where GuiaId=@GuiaId
end
begin
delete from GuiaRemision
where GuiaId=@GuiaId
end
GO

IF OBJECT_ID(N'dbo.eliminarletra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminarletra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminarletra] @LetraId numeric(38)
as
begin
delete from DocumentoCanje
where LetraId=@LetraId
begin
delete from DetalleLetra
where LetraId=@LetraId
begin
delete from Letra
where LetraId=@LetraId
end
end
end
GO

IF OBJECT_ID(N'dbo.eliminarliquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminarliquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminarliquida]
@LiquidacionId numeric(38),
@CompraId numeric(18,2),
@Acuenta decimal(18,2),
@Concepto varchar(40)
as
begin
if(@Concepto='LETRA')
begin
update DetalleLetra
set DetalleSaldo=DetalleSaldo+@Acuenta,DetalleEstado='PENDIENTE DE PAGO'
where DetalleId=@CompraId
end
else
begin
update Compras
set CompraSaldo=CompraSaldo+@Acuenta,CompraEstado='PENDIENTE DE PAGO'
where CompraId=@CompraId
end
end
begin
delete from DetalleLiquida
where LiquidacionId=@LiquidacionId
end
begin
delete from Liquidacion
where LiquidacionId=@LiquidacionId
end
GO

IF OBJECT_ID(N'dbo.eliminarNotaPedido', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminarNotaPedido] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminarNotaPedido] 
@NotaId numeric(38)
as
begin
delete from DetallePedido
where NotaId=@NotaId
end
begin
delete from NotaPedido
where NotaId=@NotaId
end
GO

IF OBJECT_ID(N'dbo.eliminarRenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminarRenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminarRenta] 
@Data varchar(max)
as
begin
Declare @RentaId numeric(38),
@Cantidad int
Set @Data = LTRIM(RTrim(@Data))
Set @RentaId=convert(numeric(38),@Data)
delete from RentaMensual
where RentaId=@RentaId
set @Cantidad=(select COUNT(r.RentaId) from RentaMensual r)
if @Cantidad<=0
begin
select 'true'
end
else
begin
(select STUFF((select '¬'+convert(varchar,r.RentaId)+'|'+convert(varchar,r.CompaniaId)+'|'+convert(varchar,r.RentaANNO)+'|'+
convert(varchar,r.RentaMes)+'|'+dbo.MesNombre(r.RentaMes)+' '+convert(varchar,r.RentaANNO)+'|'+
CONVERT(VarChar(50), cast((r.IGV) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.Renta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.SaldoIGV) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.SaldoRenta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.InteresIgv) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.InteresRenta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.TributoIgv) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.TributoRenta) as money ), 1)+'|'+
CONVERT(char(1),r.FormaPago)+'|'+convert(varchar,r.FechaCancelacion,103)+'|'+r.EntidadBancaria+'|'+r.NroOperacion+'|'+
CONVERT(VarChar(50), cast((r.PagoTotal) as money ), 1)
from RentaMensual r
where year(r.FechaCancelacion)=year(getdate())
order by r.RentaId desc
for xml path('')),1,1,''))
end
end
GO

IF OBJECT_ID(N'dbo.eliminartemporales', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminartemporales] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminartemporales] @usuarioId int
as
begin
delete from temporalLetra
where UsuarioId=@usuarioId
begin
delete from TemporalCanje
where UsuarioId=@usuarioId
end
end
GO

IF OBJECT_ID(N'dbo.eliminarUM', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminarUM] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminarUM]
@Data varchar(max)
as
begin
    Set @Data = LTRIM(RTrim(@Data))
	Declare @pos1 int,@pos2 int
	declare @IdUm int,@IdProducto numeric(20)
	declare @contador int
Set @pos1 = CharIndex('|',@Data,0)
Set @IdUm =convert(int,SUBSTRING(@Data,1,@pos1-1))
Set @pos2 =Len(@Data)+1
Set @IdProducto=convert(numeric,SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1))
	delete from UnidadMedida
	where IdUm=@IdUm
set @contador=(select COUNT(*) from UnidadMedida where IdProducto=@IdProducto)	
if 	@contador<=0
begin
	select 'true'
end
else
begin
	(select STUFF ((select '¬'+convert(varchar,m.IdUm)+'|'+CONVERT(varchar,m.IdProducto)+'|'+m.UMDescripcion+'|'+
	CONVERT(VarChar(50), cast(m.ValorUM as money ),2)+'|'+CONVERT(VarChar(50),cast(m.PrecioVenta as money ), 1)+'|'+CONVERT(VarChar(50), cast(m.PrecioVentaB as money ), 1)+'|'+
	CONVERT(varchar(50),m.PrecioCosto)
	from UnidadMedida m
	where m.IdProducto=@IdProducto
	order by m.ValorUM asc
	for xml path('')),1,1,''))
end
end
GO

IF OBJECT_ID(N'dbo.eliminaTipoCambio', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[eliminaTipoCambio] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[eliminaTipoCambio]
@Data varchar(max)
as
begin
    Set @Data = LTRIM(RTrim(@Data))
	declare @IdTipo numeric(38)
	declare @contador int
	set @IdTipo=convert(numeric(38),@Data)
	delete from TipoCambio where IdTipo=@IdTipo
    set @contador=(select COUNT(t.IdTipo)
    from TipoCambio t 
    where MONTH(t.TipoFecha)=MONTH(GETDATE()) and YEAR(t.TipoFecha)=YEAR(GETDATE()))
if @contador<=0
begin
	select 'true'
end
else
begin
    select isnull((select STUFF((select '¬'+ convert(varchar,t.IdTipo),+'|'+
	(Convert(char(10),t.TipoFecha,103))+'|'+convert(varchar,t.TipoCompra)+'|'+
	convert(varchar,t.TipoVenta)+'|'+
	convert(varchar,t.TipoEmpresa) 
	from TipoCambio t 
	where MONTH(t.TipoFecha)=MONTH(GETDATE()) and YEAR(t.TipoFecha)=YEAR(GETDATE()) 
	order by t.TipoFecha desc
	for xml path('')),1,1,'')),'~')	
end
end
GO

IF OBJECT_ID(N'dbo.equivalenteProducto', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[equivalenteProducto] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[equivalenteProducto]
as
begin
select 'IdPro|Descripcion|UM|Valor|UB|PrecioVenta|PrecioVentaB|PrecioCosto¬100|450|100|100|100|100|100|100¬String|String|String|Decimal|String|Decimal|Decimal|Decimal¬'+
isnull((select STUFF ((select '¬'+convert(varchar,p.IdProducto)+'|'+
p.ProductoNombre+' '+p.ProductoMarca+'|'+u.UMDescripcion+'|'+
convert(varchar,u.ValorUM)+'|'+p.ProductoUM+'|'+
convert(varchar,u.PrecioVenta)+'|'+
convert(varchar,u.PrecioVentaB)+'|'+
convert(varchar,u.PrecioCosto)
from UnidadMedida u
inner join Producto p
on p.IdProducto=u.IdProducto
order by p.ProductoNombre+' '+p.ProductoMarca asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.ingresarCompra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ingresarCompra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ingresarCompra]
@CompaniaId int,
@CompraCorrelativo varchar(80),
@ProveedorId numeric(38),
@CompraEmision date,
@CompraComputo date,
@TipoCodigo char(20),
@CompraSerie varchar(60),
@CompraNumero varchar(80),
@CompraCondicion varchar(60),
@CompraMoneda varchar(60),
@CompraTipoCambio decimal(18,3),
@CompraDias int,
@CompraFechaPago date,
@CompraUsuario varchar(80),
@CompraTipoIgv varchar(60),
@CompraValorVenta decimal(18,2),
@CompraDescuento decimal(18,2),
@CompraSubtotal decimal(18,2),
@CompraIgv decimal(18,2),
@CompraTotal decimal(18,2),
@CompraEstado varchar(60),
@CompraAsociado varchar(60),
@compraSaldo decimal(18,2),
@CompraOBS varchar(max),
@CompraTipoSunat decimal(18,3),
@CompraConcepto varchar(60)
as
begin
insert into Compras values(@CompaniaId,@CompraCorrelativo,@ProveedorId,GETDATE(),
@CompraEmision,@CompraComputo,@TipoCodigo,@CompraSerie,@CompraNumero,@CompraCondicion,
@CompraMoneda,@CompraTipoCambio,@CompraDias,@CompraFechaPago,@CompraUsuario,@CompraTipoIgv,
@CompraValorVenta,@CompraDescuento,@CompraSubtotal,@CompraIgv,@CompraTotal,@CompraEstado,
@CompraAsociado,@compraSaldo,@CompraOBS,@CompraTipoSunat,@CompraConcepto)
select @@identity
end
------
GO

IF OBJECT_ID(N'dbo.ingresarDetaCajaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ingresarDetaCajaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ingresarDetaCajaB]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,
		@p3 int,@p4 int,
		@p5 int,@p6 int,
		@p7 int,@p8 int,
		@p9 int,@p10 int,
		@p11 int,@p12 int
Declare @CajaId numeric(38),@NotaId numeric(38),
		@Movimiento varchar(80),
		@Concepto varchar(MAX),@Monto decimal(18,2),
		@Efectivo decimal(18,2),@Vuelto decimal(18,2),
		@DetalleId numeric(38),@RutaImagen varchar(max),
		@FormaPago varchar(80),@EntidadBancaria varchar(80),
		@NroOperacion varchar(80)
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 = CharIndex('|',@Data,@p2+1)
Set @p4 = CharIndex('|',@Data,@p3+1)
Set @p5 = CharIndex('|',@Data,@p4+1)
Set @p6 =CharIndex('|',@Data,@p5+1)
Set @p7 = CharIndex('|',@Data,@p6+1)
Set @p8 = CharIndex('|',@Data,@p7+1)
Set @p9= CharIndex('|',@Data,@p8+1)
Set @p10 = CharIndex('|',@Data,@p9+1)
Set @p11 = CharIndex('|',@Data,@p10+1)
Set @p12= Len(@Data)+1
Set @CajaId =convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
Set @NotaId=convert(numeric(38),SUBSTRING(@Data,@p1+1,@p2-@p1-1))
Set @Movimiento=SUBSTRING(@Data,@p2+1,@p3-@p2-1)
Set @Concepto=SUBSTRING(@Data,@p3+1,@p4-@p3-1)
Set @Monto=convert(decimal(18,2),SUBSTRING(@Data,@p4+1,@p5-@p4-1))
Set @Efectivo=convert(decimal(18,2),SUBSTRING(@Data,@p5+1,@p6-@p5-1))
Set @Vuelto=convert(decimal(18,2),SUBSTRING(@Data,@p6+1,@p7-@p6-1))
Set @DetalleId=convert(numeric(38),SUBSTRING(@Data,@p7+1,@p8-@p7-1))
Set @RutaImagen=SUBSTRING(@Data,@p8+1,@p9-@p8-1)
Set @FormaPago=SUBSTRING(@Data,@p9+1,@p10-@p9-1)
Set @EntidadBancaria=SUBSTRING(@Data,@p10+1,@p11-@p10-1)
Set @NroOperacion=SUBSTRING(@Data,@p11+1,@p12-@p11-1)
if(@DetalleId=0)
begin
IF EXISTS(select L.NroOperacion
from LiquidacionVenta L
where L.EntidadBancaria=@EntidadBancaria and L.EntidadBancaria<>'-' and L.NroOperacion=@NroOperacion and L.NroOperacion<>'')
begin
select 'EXISTE'
end
ELSE IF EXISTS(select c.NroOperacion
from CajaDetalle c
where c.EntidadBancaria=@EntidadBancaria and c.EntidadBancaria<>'-' and c.NroOperacion=@NroOperacion and c.NroOperacion<>'')
begin
select 'EXISTE'
end
else
begin

if(@Movimiento='INGRESO' and @FormaPago<>'EFECTIVO')
begin
insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,'INGRESO',
@Concepto+' ENTIDAD BANCARIA: '+@EntidadBancaria+' NRO OPERACION: '+@NroOperacion,@Monto,@Efectivo,@Vuelto,@RutaImagen,'T','',0,'',@FormaPago,
@EntidadBancaria,@NroOperacion)
insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,'SALIDA',
@Concepto+' ENTIDAD BANCARIA: '+@EntidadBancaria+' NRO OPERACION: '+@NroOperacion,
@Monto,@Efectivo,@Vuelto,@RutaImagen,'T','',0,'',@FormaPago,
@EntidadBancaria,@NroOperacion)
select 'true'
end

else if(@Movimiento='SALIDA' and @FormaPago<>'EFECTIVO')
begin
insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,'SALIDA',
@Concepto+' ENTIDAD BANCARIA: '+@EntidadBancaria+' NRO OPERACION: '+@NroOperacion,
@Monto,@Efectivo,@Vuelto,@RutaImagen,'T','',0,'',@FormaPago,
@EntidadBancaria,@NroOperacion)
select 'true'
end

else
begin
insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,@Movimiento,
@Concepto,@Monto,@Efectivo,@Vuelto,@RutaImagen,'T','',0,'',@FormaPago,
@EntidadBancaria,@NroOperacion)
select 'true'
end

end
end
else
begin
update CajaDetalle
set RutaImagen=@RutaImagen
where DetalleId=@DetalleId
select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.ingresarPersonal', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ingresarPersonal] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ingresarPersonal]
@PersonalNombres varchar(140),
@PersonalApellidos varchar(140),
@AreaId numeric(20),
@PersonalCodigo varchar (80),
@PersonalNacimiento date,
@PersonalIngreso varchar(20),
@PersonalDNI varchar(20),
@PersonalDireccion varchar(140),
@PersonalTelefono varchar(40),
@PersonalTelefonoAsi varchar(40),
@PersonalEmail varchar(100),
@PersonalSueldo decimal(18,2),
@PersonalEstado varchar(60),
@PersonalBajaFecha varchar(60),
@PersonalRuc varchar(20),
@PersonalImagen varchar(max),
@CompaniaId int
as
begin
insert into Personal values
(@PersonalNombres,@PersonalApellidos,@AreaId,@PersonalCodigo,
@PersonalNacimiento,@PersonalIngreso,@PersonalDNI,@PersonalDireccion,
@PersonalTelefono,@PersonalTelefonoAsi,@PersonalEmail,
@PersonalSueldo,@PersonalEstado,@PersonalBajaFecha,@PersonalRuc,
@PersonalImagen,@CompaniaId,'')
end
GO

IF OBJECT_ID(N'dbo.ingresarProducto', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ingresarProducto] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ingresarProducto]
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
 @ProductoxCaja decimal(18,2),
 @AplicaFB nvarchar(1)
 as
 begin
 insert into Producto values(
 @IdSubLinea,@ProductoCodigo,@ProductoNombre,
 @ProductoMarca,@ProductoTipoCambio,@ProductoCostoDolar,
 @ProductoUM,@ProductoCosto,@ProductoVenta,
 @AlmacenId,@ProductoUbicacion,
 @ProductoCantidad,@ProductoObs,@ProductoEstado,
 @ProductoUsuario,GETDATE(),@ProductoImagen,@ValorCritico,@ProductoPV,
 @ProductoSV,@ProductoxCaja,@ProductoINV,@AplicaFB,null)
 select @@identity
 begin
 insert into Kardex values(@@identity,GETDATE(),'Nuevo Registro','Nuevo Registro',
 0,@ProductoCantidad,0,@ProductoCosto,@ProductoCantidad,'INGRESO',
 @ProductoUsuario,'','','','','','','S','','','E')
 end
 end
GO

IF OBJECT_ID(N'dbo.ingresarProveedor', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ingresarProveedor] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ingresarProveedor]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,
		@p3 int,@p4 int,
		@p5 int,@p6 int,
		@p7 int,@p8 int,
		@p9 int	
Declare @ProveedorId numeric(38),
        @Razon varchar(250),
		@Ruc varchar(20),
		@Contacto varchar(140),
		@Celular varchar(140),
		@Telefono varchar(140),
		@Correo varchar(140),
		@Direccion varchar(140),
		@Estado varchar(40)
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 = CharIndex('|',@Data,@p2+1)
Set @p4 = CharIndex('|',@Data,@p3+1)
Set @p5 = CharIndex('|',@Data,@p4+1)
Set @p6 = CharIndex('|',@Data,@p5+1)
Set @p7 = CharIndex('|',@Data,@p6+1)
Set @p8 = CharIndex('|',@Data,@p7+1)
Set @p9 =Len(@Data)+1
set @ProveedorId=convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
set @Razon=SUBSTRING(@Data,@p1+1,@p2-@p1-1)
set @Ruc=SUBSTRING(@Data,@p2+1,@p3-@p2-1)
set @Contacto=SUBSTRING(@Data,@p3+1,@p4-@p3-1)
set @Celular=SUBSTRING(@Data,@p4+1,@p5-@p4-1)
set @Telefono=SUBSTRING(@Data,@p5+1,@p6-@p5-1)
set @Correo=SUBSTRING(@Data,@p6+1,@p7-@p6-1)
set @Direccion=SUBSTRING(@Data,@p7+1,@p8-@p7-1)
set @Estado=SUBSTRING(@Data,@p8+1,@p9-@p8-1)
if @ProveedorId=0
begin
insert into Proveedor values(@Razon,@Ruc,@Contacto,@Celular,@Telefono,@Correo,@Direccion,@Estado)
end
else
begin
update Proveedor
set ProveedorRazon=@Razon,ProveedorRuc=@Ruc,ProveedorContacto=@Contacto,
ProveedorCelular=@Celular,ProveedorTelefono=@Telefono,ProveedorCorreo=@Correo,
ProveedorDireccion=@Direccion,ProveedorEstado=@Estado
where ProveedorId=@ProveedorId
end
	select isnull((select stuff((SELECT '¬'+ CONVERT(varchar,p.ProveedorId)+'|'+p.ProveedorRazon+'|'+p.ProveedorRuc+'|'+
	p.ProveedorContacto+'|'+p.ProveedorCelular+'|'+p.ProveedorTelefono+'|'+p.ProveedorCorreo+'|'+
	p.ProveedorDireccion+'|'+p.ProveedorEstado
	from Proveedor p
	order by p.ProveedorId desc
	for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.ingresarUsuario', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ingresarUsuario] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ingresarUsuario]
@PersonalId numeric(20),
@UsuarioAlias varchar(60),
@UsuarioClave varchar(40),
@UsuarioEstado varchar(40)
as
begin
insert into Usuarios values(@PersonalId,@UsuarioAlias,
dbo.encriptar(@UsuarioClave),GETDATE(),@UsuarioEstado,
'',0,0,0,0,'','',0,'','','')
end
GO

IF OBJECT_ID(N'dbo.insertaClienteLD', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertaClienteLD] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertaClienteLD]    
@Columna varchar(max)     
 as    
 begin    
 declare @p0 int, @p1 int,@p2 int,    
   @p3 int,@p4 int,@p5 int,    
   @p6 int,@p7 int,@p8 int,    
   @p9 int,@p10 int,@p11 int,  
   @p12 int    
Declare @ClienteId numeric(20),     
  @ClienteRazon varchar(140),    
  @ClienteRuc varchar(40),    
  @ClienteDni varchar(40),    
  @ClienteDireccion varchar(max),    
  @ClienteMovil varchar(80),    
  @ClienteTelefono varchar(80),    
  @ClienteCorreo varchar(80),    
  @Usuario varchar(80),    
  @ClienteEstado varchar(40),    
  @ClienteDespacho varchar(max),    
  @ClienteCodigo varchar(80),    
  @ClienteDocu varchar(40)    
 Set @Columna= LTRIM(RTrim(@Columna))    
 set @p0 = CharIndex('|',@Columna,0)    
 Set @p1 = CharIndex('|',@Columna,@p0+1)    
 Set @p2 = CharIndex('|',@Columna,@p1+1)    
 Set @p3 = CharIndex('|',@Columna,@p2+1)    
 Set @p4 = CharIndex('|',@Columna,@p3+1)    
 Set @p5 = CharIndex('|',@Columna,@p4+1)    
 Set @p6 = CharIndex('|',@Columna,@p5+1)    
 Set @p7 = CharIndex('|',@Columna,@p6+1)    
 Set @p8= CharIndex('|',@Columna,@p7+1)    
 Set @p9 = CharIndex('|',@Columna,@p8+1)    
 Set @p10 = CharIndex('|',@Columna,@p9+1)    
 Set @p11 = CharIndex('|',@Columna,@p10+1)    
 Set @p12= Len(@Columna)+1    
 Set @ClienteId=Convert(numeric(20),SUBSTRING(@Columna,1,@p0-1))    
 Set @ClienteRazon=SUBSTRING(@Columna,@p0+1,@p1-(@p0+1))    
 Set @ClienteRuc=SUBSTRING(@Columna,@p1+1,@p2-(@p1+1))    
 Set @ClienteDni=SUBSTRING(@Columna,@p2+1,@p3-(@p2+1))    
 Set @ClienteDireccion=SUBSTRING(@Columna,@p3+1,@p4-(@p3+1))    
 Set @ClienteMovil=SUBSTRING(@Columna,@p4+1,@p5-(@p4+1))    
 Set @ClienteTelefono=SUBSTRING(@Columna,@p5+1,@p6-(@p5+1))    
 Set @ClienteCorreo=SUBSTRING(@Columna,@p6+1,@p7-(@p6+1))    
 Set @Usuario=SUBSTRING(@Columna,@p7+1,@p8-(@p7+1))    
 Set @ClienteEstado=SUBSTRING(@Columna,@p8+1,@p9-(@p8+1))    
 Set @ClienteDespacho=SUBSTRING(@Columna,@p9+1,@p10-@p9-1)    
 Set @ClienteCodigo=SUBSTRING(@Columna,@p10+1,@p11-@p10-1)    
 Set @ClienteDocu=SUBSTRING(@Columna,@p11+1,@p12-@p11-1) 
 
IF(@ClienteId=0)    
BEGIN  
   
   IF EXISTS(select top 1 C.ClienteCodigo 
             from cliente c where c.ClienteCodigo=@ClienteCodigo AND c.ClienteCodigo<>'')
   BEGIN
		select 'CODIGO' 
   END

   --ELSE IF EXISTS(select top 1 c.ClienteDni
   --               from Cliente c where c.ClienteDni=@ClienteDni and ClienteDni<>'')
   -- BEGIN
   --     SELECT 'DNI'
   -- END

    ELSE IF EXISTS(select top 1 c.ClienteRuc
                   from Cliente c where c.ClienteRuc=@ClienteRuc and ClienteRuc<>'')
    BEGIN
        SELECT 'RUC'
    END
	ELSE
	BEGIN
	
	  insert into Cliente values(@ClienteRazon,@ClienteRuc,@ClienteDni,@ClienteDireccion,    
	  @ClienteMovil,@ClienteTelefono,@ClienteCorreo,@ClienteEstado,    
      @ClienteDespacho,@ClienteCodigo,@ClienteDocu,@Usuario,GETDATE())    
   
      Select 'true'  
	
	END 
END   
ELSE    
BEGIN    
   
   IF EXISTS(select top 1 C.ClienteCodigo from cliente c   
             where c.ClienteCodigo=@ClienteCodigo AND (c.ClienteCodigo<>''and ClienteId<>@ClienteId))
   BEGIN
		select 'CODIGO' 
   END

   --ELSE IF EXISTS(select top 1 c.ClienteDni
   --               from Cliente c where c.ClienteDni=@ClienteDni and (ClienteDni<>'' and ClienteId<>@ClienteId))
   -- BEGIN
   --     SELECT 'DNI'
   -- END

    ELSE IF EXISTS(select top 1 c.ClienteRuc
                   from Cliente c where c.ClienteRuc=@ClienteRuc and (ClienteRuc<>'' and ClienteId<>@ClienteId))
    BEGIN
        SELECT 'RUC'
    END

	ELSE
	BEGIN

      update Cliente    
	  set ClienteRazon=@ClienteRazon,ClienteRuc=@ClienteRuc,ClienteDni=@ClienteDni,ClienteDireccion=@ClienteDireccion,    
	  ClienteMovil=@ClienteMovil,ClienteTelefono=@ClienteTelefono,ClienteCorreo=@ClienteCorreo,ClienteUsuario=@Usuario,    
	  clienteEstado=@ClienteEstado,ClienteDespacho=@ClienteDespacho,ClienteCodigo=@ClienteCodigo,    
	  ClienteDocu=@ClienteDocu,ClienteFecha=GETDATE()    
	  where ClienteId=@ClienteId    
   
      Select 'true'
	  
	END

END    
End
GO

IF OBJECT_ID(N'dbo.insertaDetaLiquiVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertaDetaLiquiVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertaDetaLiquiVenta]
@LiquidacionId numeric(38),
@DocuId numeric(38),
@NotaId numeric(38),
@SaldoDocu decimal(18,2),
@EfectivoSoles decimal(18, 2),
@EfectivoDolar decimal(18, 2),
@DepositoSoles decimal(18, 2),
@DepositoDolar decimal(18, 2),
@TipoCambio decimal(18, 3),
@EntidadBanco varchar(80),
@NroOperacion varchar(80),
@AcuentaGeneral decimal(18, 2),
@SaldoActual decimal(18, 2),
@FechaPago varchar(60),
@DocuEstado varchar(60)
as
BEGIN TRANSACTION
insert into DetaLiquidaVenta values(
@LiquidacionId,@DocuId,@NotaId,@SaldoDocu,@EfectivoSoles,
@EfectivoDolar,@DepositoSoles,@DepositoDolar,
@TipoCambio,@EntidadBanco,@NroOperacion,
@AcuentaGeneral,@SaldoActual,@FechaPago
)
update NotaPedido
set NotaAcuenta=NotaAcuenta+@AcuentaGeneral,
NotaSaldo=NotaSaldo-@AcuentaGeneral,NotaEstado=@DocuEstado
where NotaId=@NotaId
commit
GO

IF OBJECT_ID(N'dbo.insertaGuiaCanje', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertaGuiaCanje] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertaGuiaCanje]
@CompraId numeric(38),
@CompaniaId int,
@CanjeFecha date,
@CanjeRegistro datetime,
@CanjeSerie varchar(80),
@CanjeNumero varchar(80),
@CanjeEmision date,
@CanjeComputo date,
@CanjeCorrelativo varchar(80),
@CanjeTipo varchar(80),
@CanjeOBS varchar(max),
@TCSunat decimal(18,3),
@GCompania int,
@GSerie varchar(80),
@GNumero varchar(80),
@GEmision date,
@GCanjeComputo date,
@GCanjeCorrelativo varchar(80),
@GCanjeTipo varchar(80),
@GCanjeOBS varchar(max),
@GTCSunat decimal(18,3),
@CanjeUsuario varchar(60),
@Subtotal decimal(18,2),
@Igv decimal(18,2),
@Total decimal(18,2)
as
begin
insert into GuiaCanje values(@CompraId,@CompaniaId,@CanjeFecha,@CanjeRegistro,@CanjeSerie,@CanjeNumero,
@CanjeEmision,@CanjeComputo,@CanjeCorrelativo,@CanjeTipo,@CanjeOBS,@TCSunat,@GCompania,@GSerie,@GNumero,@GEmision,
@GCanjeComputo,@GCanjeCorrelativo,@GCanjeTipo,@GCanjeOBS,@GTCSunat,@CanjeUsuario)
begin
update Compras
set CompaniaId=@CompaniaId,CompraTipoSunat=@TCSunat,CompraSerie=@CanjeSerie,CompraNumero=@CanjeNumero,CompraEmision=@CanjeEmision,
CompraComputo=@CanjeComputo,CompraCorrelativo=@CanjeCorrelativo,CompraTipoIgv=@CanjeTipo,CompraOBS=@CanjeOBS,TipoCodigo='01',
CompraSubtotal=@Subtotal,CompraIgv=@Igv,CompraTotal=@Total
where CompraId=@CompraId
end
end
GO

IF OBJECT_ID(N'dbo.insertarAlmacen', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarAlmacen] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarAlmacen]
@Data varchar(max)
as
begin
Declare @pos1 int
Declare @pos2 int
Declare @pos3 int
Declare @pos4 int
Declare @pos5 int
Declare @pos6 int
Declare @pos7 int
Declare @AlmacenId numeric(20)
Declare @AlmacenNombre varchar(80)
Declare @AlmacenDepartamento varchar(80)
Declare @AlmacenProvincia varchar(80)
Declare @AlmacenDistrito varchar(80)
Declare @AlmacenDireccion varchar(300)
Declare @AlmacenEstado varchar(20)
Declare @AlmacenBD varchar(80)
Set @Data = LTRIM(RTrim(@Data))
Set @pos1 = CharIndex('|',@Data,0)
Set @AlmacenId =convert(numeric,SUBSTRING(@Data,1,@pos1-1))
Set @pos2 = CharIndex('|',@Data,@pos1+1)
Set @AlmacenNombre = SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1)
Set @pos3 = CharIndex('|',@Data,@pos2+1)
Set @AlmacenDepartamento=SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1)
Set @pos4 = CharIndex('|',@Data,@pos3+1)
Set @AlmacenProvincia=SUBSTRING(@Data,@pos3+1,@pos4-@pos3-1)
Set @pos5 = CharIndex('|',@Data,@pos4+1)
Set @AlmacenDistrito=SUBSTRING(@Data,@pos4+1,@pos5-@pos4-1)
Set @pos6 =CharIndex('|',@Data,@pos5+1)
Set @AlmacenDireccion=SUBSTRING(@Data,@pos5+1,@pos6-@pos5-1)
Set @pos7 = Len(@Data)+1
Set @AlmacenEstado=SUBSTRING(@Data,@pos6+1,@pos7-@pos6-1)
set @AlmacenBD=(select top 1 a.AlmacenNombre from Almacen a where AlmacenNombre=@AlmacenNombre)
if @AlmacenId=0
begin
if(@AlmacenBD=@AlmacenNombre)
begin
select 'existe'
end
else
begin
insert into Almacen values(@AlmacenNombre,@AlmacenDepartamento,@AlmacenProvincia,@AlmacenDistrito,@AlmacenDireccion,@AlmacenEstado)
(select STUFF((select '¬'+ convert(varchar,a.AlmacenId)+'|'+a.AlmacenNombre+'|'+a.AlmacenDepartamento+'|'+
a.AlmacenProvincia+'|'+a.AlmacenDistrito+'|'+a.AlmacenDireccion+'|'+a.AlmacenEstado
from Almacen a
order by AlmacenId desc
for xml path('')),1,1,''))
end
end
else
begin
update Almacen
set AlmacenNombre=@AlmacenNombre,AlmacenDepartamento=@AlmacenDepartamento,AlmacenProvincia=@AlmacenProvincia,AlmacenDistrito=@AlmacenDistrito,AlmacenDireccion=@AlmacenDireccion,AlmacenEstado=@AlmacenEstado
where AlmacenId=@AlmacenId
(select STUFF((select '¬'+ convert(varchar,a.AlmacenId)+'|'+a.AlmacenNombre+'|'+a.AlmacenDepartamento+'|'+
a.AlmacenProvincia+'|'+a.AlmacenDistrito+'|'+a.AlmacenDireccion+'|'+a.AlmacenEstado
from Almacen a
order by AlmacenId desc
for xml path('')),1,1,''))
end
end
GO

IF OBJECT_ID(N'dbo.insertarCajaPri', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarCajaPri] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarCajaPri]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,
		@p3 int,@p4 int,
		@p5 int,@p6 int,
		@p7 int
declare @CajaConcepto varchar(80),
		@CajaId numeric(38),
		@CajaDescripcion varchar(250),
		@CajaMonto decimal(18,2),
		@CajaUsuario varchar(20),
		@Aviso char(1),
		@RutaImagen varchar(max)
Set @Data = LTRIM(RTrim(@Data))
		Set @p1 = CharIndex('|',@Data,0)
		Set @p2 = CharIndex('|',@Data,@p1+1)
		Set @p3 = CharIndex('|',@Data,@p2+1)
		Set @p4 = CharIndex('|',@Data,@p3+1)
		Set @p5= CharIndex('|',@Data,@p4+1)
		Set @p6= CharIndex('|',@Data,@p5+1)
		Set @p7= Len(@Data)+1
		Set @CajaConcepto=SUBSTRING(@Data,1,@p1-1)
		Set @CajaId=convert(numeric(38),SUBSTRING(@Data,@p1+1,@p2-@p1-1))
		Set @CajaDescripcion=SUBSTRING(@Data,@p2+1,@p3-@p2-1)
		Set @CajaMonto=convert(decimal(18,2),SUBSTRING(@Data,@p3+1,@p4-@p3-1))
		Set @CajaUsuario=SUBSTRING(@Data,@p4+1,@p5-@p4-1)
		Set @Aviso=SUBSTRING(@Data,@p5+1,@p6-@p5-1)
		Set @RutaImagen=SUBSTRING(@Data,@p6+1,@p7-@p6-1)		
begin
IF EXISTS(select CajaId from CajaPincipal where CajaId=@CajaId and CajaId<>0)
begin
	update CajaPincipal
	set CajaConcepto=@CajaConcepto,CajaFecha=GETDATE(),
	CajaDescripcion=@CajaDescripcion,CajaMonto=@CajaMonto,
	CajaUsuario=@CajaUsuario
	where CajaId=@CajaId
end
else
begin
	insert into CajaPincipal values(@CajaConcepto,GETDATE(),
	@CajaId,@CajaDescripcion,@CajaMonto,@CajaUsuario,0,@RutaImagen)
end
if @Aviso='1'
begin
select isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen  
from CajaPincipal c 
where c.CajaConcepto='INGRESO' and c.IdGeneral=0
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen  
from CajaPincipal c 
where c.CajaConcepto='SALIDA' and c.IdGeneral=0
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')
end
else
begin
select 'true'
end
end
end
GO

IF OBJECT_ID(N'dbo.insertarCanje', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarCanje] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarCanje]
@temporalCanje varchar(80),
@temporalDias int,
@temporalVencimiento varchar(20),
@temporalMonto decimal(18,2),
@usuarioId int
as
begin
insert into TemporalCanje values(@temporalCanje,
@temporalDias,@temporalVencimiento,@temporalMonto,@usuarioId)
end
GO

IF OBJECT_ID(N'dbo.insertarDetaLetra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarDetaLetra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarDetaLetra]
@LetraId  numeric(38),
@LetraCanje varchar(80),
@LetraDias int,
@LetraVencimiento date,
@DetalleSaldo decimal(18,2),
@DetalleMonto decimal(18,2),
@DetalleEstado varchar(60)
as
begin
insert into DetalleLetra values(@LetraId,@LetraCanje,
@LetraDias,@LetraVencimiento,@DetalleMonto,
@DetalleSaldo,@DetalleEstado)
end
GO

IF OBJECT_ID(N'dbo.insertarDetaLiquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarDetaLiquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarDetaLiquida]
@LiquidacionId numeric(38),
@CompraId numeric(38),
@SaldoDocu decimal(18,2),
@EfectivoSoles decimal(18, 2),
@EfectivoDolar decimal(18, 2),
@DepositoSoles decimal(18, 2),
@DepositoDolar decimal(18, 2),
@TipoCambio decimal(18, 3),
@EntidadBanco varchar(80),
@NroOperacion varchar(80),
@AcuentaGeneral decimal(18, 2),
@SaldoActual decimal(18, 2),
@FechaPago varchar(60),
@Numero varchar(60),
@Proveedor varchar(255),
@Moneda varchar(20),
@Concepto varchar(40),
@CompraEstado varchar(60)
as
begin
insert into DetalleLiquida values(
@LiquidacionId,@CompraId,@SaldoDocu,@EfectivoSoles,@EfectivoDolar,@DepositoSoles,
@DepositoDolar,@TipoCambio,@EntidadBanco,@NroOperacion,@AcuentaGeneral,@SaldoActual,@FechaPago,@Numero,
@Proveedor,@Moneda,@Concepto
)
begin
if(@Concepto='COMPRA')
begin
update Compras
set CompraSaldo=CompraSaldo - @AcuentaGeneral,CompraEstado=@CompraEstado
where CompraId=@CompraId
end
else
begin
update DetalleLetra
set DetalleSaldo=DetalleSaldo-@AcuentaGeneral,DetalleEstado=@CompraEstado
where DetalleId=@CompraId
end
end
end
GO

IF OBJECT_ID(N'dbo.insertarDetalleCompra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarDetalleCompra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarDetalleCompra]
@CompraId numeric(38),
@IdProducto numeric(20),
@DetalleCodigo varchar(80),
@Descripcion varchar(255),
@DetalleUM   varchar(60),
@DetalleCantidad decimal(18,2),
@PrecioCosto  decimal(18,4),
@DetalleImprte decimal(18,4),
@DetalleDescuento decimal(18,4),
@DetalleEstado varchar(60)
as
begin
insert into DetalleCompra values(@CompraId,@IdProducto,@DetalleCodigo,
@Descripcion,@DetalleUM,@DetalleCantidad,@PrecioCosto,@DetalleImprte,
@DetalleDescuento,@DetalleEstado,0,'',1)
end
GO

IF OBJECT_ID(N'dbo.insertarDetalleNota', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarDetalleNota] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarDetalleNota]
@NotaId numeric(38),
@IdProducto numeric(20),
@DetalleCantidad decimal(18,2),
@DetalleUm varchar(40),
@DetalleDescripcion varchar(140),
@DetalleCosto decimal(18,2), 
@DetallePrecio decimal(18,2),
@DetalleImporte decimal(18,2),
@DetalleEstado varchar(60),
@CantidadSaldo decimal(18,2),
@ValorUM decimal(18,4),
@DetallePV decimal(18,2),
@DetalleSV decimal(18,2),
@DocuId numeric(38)=0
as
begin
declare @DetalleNotaId numeric(38)       
begin
insert into DetallePedido values(@NotaId,@IdProducto,@DetalleCantidad,
@DetalleUm,@DetalleDescripcion,@DetalleCosto, @DetallePrecio,
@DetalleImporte,@DetalleEstado,@CantidadSaldo,@ValorUM,@DetallePV,@DetalleSV)
set @DetalleNotaId=(select @@IDENTITY)
end
if(@DocuId<>'0')
begin
insert into DetalleDocumento values
(@DocuId,@IdProducto,@DetalleCantidad,@DetallePrecio,@DetalleImporte,
@DetalleNotaId,@DetalleUm,@ValorUM)
end
end
GO

IF OBJECT_ID(N'dbo.insertarGeneral', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarGeneral] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarGeneral]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,
		@p3 int,@p4 int,
		@p5 int
Declare
		@IdGeneral numeric(38),
		@Usuario varchar(80),
		@Ingresos decimal(18,2),
		@Salidas decimal(18,2),
		@Total decimal(18,2),
		@Codigo numeric(38)
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 = CharIndex('|',@Data,@p2+1)
Set @p4 = CharIndex('|',@Data,@p3+1)
Set @p5 =Len(@Data)+1
set @IdGeneral=convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
set @Usuario=SUBSTRING(@Data,@p1+1,@p2-@p1-1)
set @Ingresos=convert(decimal(18,2),SUBSTRING(@Data,@p2+1,@p3-@p2-1))
set @Salidas=convert(decimal(18,2),SUBSTRING(@Data,@p3+1,@p4-@p3-1))
set @Total=convert(decimal(18,2),SUBSTRING(@Data,@p4+1,@p5-@p4-1))
if(@IdGeneral=0)
begin
insert into CajaGeneral values(GETDATE(),@Usuario,@Ingresos,@Salidas,@Total)
set @Codigo=(select @@IDENTITY)
update CajaPincipal
set IdGeneral=@Codigo
where IdGeneral=0
end
else
begin
update CajaGeneral
set FechaCierre=GETDATE(),Ingresos=@Ingresos,Salidas=@Salidas,Total=@Total,Usuario=@Usuario
where IdGeneral=@IdGeneral
end
begin
select isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen 
from CajaPincipal c 
where c.CajaConcepto='INGRESO' and c.IdGeneral=0
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen 
from CajaPincipal c 
where c.CajaConcepto='SALIDA' and c.IdGeneral=0
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')+'['+
isnull((select STUFF ((select '¬'+ CONVERT(varchar,c.IdGeneral)+'|'+
(IsNull(convert(varchar,c.FechaCierre,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,c.FechaCierre,114),1,8),''))+'|'+c.Usuario+'|'+
CONVERT(varchar(50),cast(c.Ingresos as money),1)+'|'+CONVERT(varchar(50),cast(c.Salidas as money),1)+'|'+
CONVERT(varchar(50),cast(c.Total as money),1)
from CajaGeneral c
order by c.IdGeneral desc
for xml path('')),1,1,'')),'~')
end
end
GO

IF OBJECT_ID(N'dbo.insertarGR', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarGR] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarGR]
@GuiaId numeric(38),
@NotaId numeric(38)
as
begin
begin
insert into GuiaRelacion values(@GuiaId,@NotaId)
end
begin
update GuiaRemision
set GuiaEstado='CANJEADO'
where GuiaId=@GuiaId
end
end
GO

IF OBJECT_ID(N'dbo.insertarKardexB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarKardexB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarKardexB]
	 @IdProducto numeric(20),
	 @KardexMotivo  varchar(60),
	 @KardexDocumento varchar(60),
	 @CantidadIngreso decimal(18, 2),
	 @CantidadSalida decimal(18, 2),
	 @PrecioCosto decimal(18,4),
	 @Usuario varchar(60),
	 @Aviso char(1),
	 @TipoCodigo nvarchar(10),
	 @Serie nvarchar(10),
     @TipoOperacion nvarchar(10),
     @CompraId varchar(40)
	as
	begin
	declare @IniciaStock decimal(18,2),
    @StockFinal decimal(18,2),@Concepto varchar(40)
    
	Declare @CodigoPro varchar(80)
	set @CodigoPro=isnull((select top 1 ProductoCodigo from Producto
    where IdProducto=@IdProducto),'0')
    
    if(@CodigoPro='PEKIT-3')
    begin
         
    update producto 
	set  ProductoCantidad =ProductoCantidad - @CantidadSalida
	where IDProducto=7
	
	end
	
	update producto 
	set  ProductoCantidad =ProductoCantidad - @CantidadSalida
	where IDProducto=@IdProducto
	
	delete from Kardex
	where CompraId=@CompraId
	
	end
GO

IF OBJECT_ID(N'dbo.insertarLetra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarLetra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarLetra]
@ProveedorId numeric(38),
@LetraFechaReg datetime,
@LetraFechaGiro date,
@LetraMoneda varchar(40),
@LetraSaldo decimal(18,2),
@LetraTotal decimal(18,2),
@letraUsuario varchar(60),
@LetraEstado varchar(60),
@CompaniaId INT 
as
begin
insert into Letra values(@ProveedorId,@LetraFechaReg,@LetraFechaGiro,
@LetraMoneda,@LetraSaldo,@LetraTotal,@letraUsuario,@LetraEstado,@CompaniaId)
select @@identity
end
GO

IF OBJECT_ID(N'dbo.insertarLiquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarLiquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarLiquida]
@LiquidacionNumero varchar(80),
@LiquidacionRegistro datetime,
@LiquidacionFecha date,
@LiquidacionDescripcion varchar(250),
@LiquidacionCambio decimal(18,3),
@LiquidaEfectivoSol decimal(18,2),
@LiquidaDepositoSol decimal(18,2),
@LiquidaTotalSol decimal(18,2),
@LiquidaEfectivoDol decimal(18,2),
@LiquidaDepositoDol decimal(18,2),
@LiquidaTotalDol decimal(18,2),
@LiquidaUsuario varchar(60)
as
begin
insert into Liquidacion values(@LiquidacionNumero,
@LiquidacionRegistro,@LiquidacionFecha,@LiquidacionDescripcion,
@LiquidacionCambio,@LiquidaEfectivoSol,@LiquidaDepositoSol,
@LiquidaTotalSol,@LiquidaEfectivoDol,@LiquidaDepositoDol,
@LiquidaTotalDol,@LiquidaUsuario)
select @@identity
end
GO

IF OBJECT_ID(N'dbo.insertarRenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarRenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarRenta] 
@Data varchar(max)
as
declare @existe int
		Declare @pos1 int,@pos2 int,@pos3 int,@pos4 int,
		@pos5 int,@pos6 int,@pos7 int,@pos8 int,@pos9 int,
		@pos10 int,@pos11 int,@pos12 int,@pos13 int,@pos14 int,
		@pos15 int,@pos16 int,@pos17 int,@pos18 int
Declare @RentaId numeric(38),@CompaniaId int,@RentaUsuario varchar(80),
		@RentaANNO int,@RentaMes int,@IGV decimal(18,2),@Renta decimal(18,2),
		@SaldoIGV decimal(18,2),@SaldoRenta decimal(18,2),@InteresIgv decimal(18,2),
		@InteresRenta decimal(18,2),@TributoIgv decimal(18,2),@TributoRenta decimal(18,2),
		@FormaPago bit,@FechaCancelacion datetime,@EntidadBancaria varchar(80),
		@NroOperacion varchar(80),@PagoTotal decimal(18,2)
Set @Data = LTRIM(RTrim(@Data))
Set @pos1 = CharIndex('|',@Data,0)
Set @RentaId=convert(numeric(38),SUBSTRING(@Data,1,@pos1-1))
Set @pos2 = CharIndex('|',@Data,@pos1+1)
Set @CompaniaId= convert(int,SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1))
Set @pos3 = CharIndex('|',@Data,@pos2+1)
Set @RentaUsuario=SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1)
Set @pos4 = CharIndex('|',@Data,@pos3+1)
Set @RentaANNO=convert(int,SUBSTRING(@Data,@pos3+1,@pos4-@pos3-1))
Set @pos5 = CharIndex('|',@Data,@pos4+1)
Set @RentaMes=convert(int,SUBSTRING(@Data,@pos4+1,@pos5-@pos4-1))
Set @pos6 =CharIndex('|',@Data,@pos5+1)
Set @IGV=convert(decimal(18,2),SUBSTRING(@Data,@pos5+1,@pos6-@pos5-1))
Set @pos7 =CharIndex('|',@Data,@pos6+1)
Set @Renta=convert(decimal(18,2),SUBSTRING(@Data,@pos6+1,@pos7-@pos6-1))
Set @pos8 =CharIndex('|',@Data,@pos7+1)
Set @SaldoIGV=convert(decimal(18,2),SUBSTRING(@Data,@pos7+1,@pos8-@pos7-1))
Set @pos9 =CharIndex('|',@Data,@pos8+1)
Set @SaldoRenta=convert(decimal(18,2),SUBSTRING(@Data,@pos8+1,@pos9-@pos8-1))
Set @pos10=CharIndex('|',@Data,@pos9+1)
Set @InteresIgv=convert(decimal(18,2),SUBSTRING(@Data,@pos9+1,@pos10-@pos9-1))
Set @pos11=CharIndex('|',@Data,@pos10+1)
Set @InteresRenta=convert(decimal(18,2),SUBSTRING(@Data,@pos10+1,@pos11-@pos10-1))
Set @pos12=CharIndex('|',@Data,@pos11+1)
Set @TributoIgv=convert(decimal(18,2),SUBSTRING(@Data,@pos11+1,@pos12-@pos11-1))
Set @pos13=CharIndex('|',@Data,@pos12+1)
Set @TributoRenta=convert(decimal(18,2),SUBSTRING(@Data,@pos12+1,@pos13-@pos12-1))
Set @pos14=CharIndex('|',@Data,@pos13+1)
Set @FormaPago=convert(bit,SUBSTRING(@Data,@pos13+1,@pos14-@pos13-1))
Set @pos15=CharIndex('|',@Data,@pos14+1)
Set @FechaCancelacion=convert(date,SUBSTRING(@Data,@pos14+1,@pos15-@pos14-1))
Set @pos16=CharIndex('|',@Data,@pos15+1)
Set @EntidadBancaria=SUBSTRING(@Data,@pos15+1,@pos16-@pos15-1)
Set @pos17=CharIndex('|',@Data,@pos16+1)
Set @NroOperacion=SUBSTRING(@Data,@pos16+1,@pos17-@pos16-1)
Set @pos18= Len(@Data)+1
Set @PagoTotal=convert(decimal(18,2),SUBSTRING(@Data,@pos17+1,@pos18-@pos17-1))
set @existe=(select count(RentaId)as Codigo from RentaMensual
             where CompaniaId=@CompaniaId and(RentaANNO=@RentaANNO and RentaMes=@RentaMes))
begin
if @RentaId=0
begin  
if @existe=0
begin
insert into RentaMensual values
(@CompaniaId,@RentaUsuario,
@RentaANNO,@RentaMes,@IGV,@Renta,@SaldoIGV,
@SaldoRenta,@InteresIgv,@InteresRenta,@TributoIgv,@TributoRenta,@FormaPago,@FechaCancelacion,
@EntidadBancaria,@NroOperacion,@PagoTotal
)
(select STUFF((select '¬'+convert(varchar,r.RentaId)+'|'+convert(varchar,r.CompaniaId)+'|'+convert(varchar,r.RentaANNO)+'|'+
convert(varchar,r.RentaMes)+'|'+dbo.MesNombre(r.RentaMes)+' '+convert(varchar,r.RentaANNO)+'|'+
CONVERT(VarChar(50), cast((r.IGV) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.Renta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.SaldoIGV) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.SaldoRenta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.InteresIgv) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.InteresRenta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.TributoIgv) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.TributoRenta) as money ), 1)+'|'+
CONVERT(char(1),r.FormaPago)+'|'+convert(varchar,r.FechaCancelacion,103)+'|'+r.EntidadBancaria+'|'+r.NroOperacion+'|'+
CONVERT(VarChar(50), cast((r.PagoTotal) as money ), 1)
from RentaMensual r
where year(r.FechaCancelacion)=year(getdate())
order by r.RentaId desc
for xml path('')),1,1,''))
end
else
begin
select 'existe'
end
end
else
begin
update RentaMensual
set IGV=@IGV,Renta=@Renta,SaldoIGV=@SaldoIGV,SaldoRenta=@SaldoRenta,InteresIgv=@InteresIgv,
InteresRenta=@InteresRenta,TributoIgv=@TributoIgv,TributoRenta=@TributoRenta,FormaPago=@FormaPago,
FechaCancelacion=@FechaCancelacion,EntidadBancaria=@EntidadBancaria,NroOperacion=@NroOperacion,PagoTotal=@PagoTotal
where RentaId=@RentaId
(select STUFF((select '¬'+convert(varchar,r.RentaId)+'|'+convert(varchar,r.CompaniaId)+'|'+convert(varchar,r.RentaANNO)+'|'+
convert(varchar,r.RentaMes)+'|'+dbo.MesNombre(r.RentaMes)+' '+convert(varchar,r.RentaANNO)+'|'+
CONVERT(VarChar(50), cast((r.IGV) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.Renta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.SaldoIGV) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.SaldoRenta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.InteresIgv) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.InteresRenta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.TributoIgv) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.TributoRenta) as money ), 1)+'|'+
CONVERT(char(1),r.FormaPago)+'|'+convert(varchar,r.FechaCancelacion,103)+'|'+r.EntidadBancaria+'|'+r.NroOperacion+'|'+
CONVERT(VarChar(50), cast((r.PagoTotal) as money ), 1)
from RentaMensual r
where year(r.FechaCancelacion)=year(getdate())
order by r.RentaId desc
for xml path('')),1,1,''))
end
end
GO

IF OBJECT_ID(N'dbo.insertartemLetra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertartemLetra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertartemLetra]
@CompraId numeric(38),
@ProveedorId numeric(38),
@TemporalDocumento varchar(60),
@TemporalMoneda varchar(20),
@TemporalMonto decimal(18,2),
@UsuarioId int,
@TemporalCanje varchar(80)
as
begin
insert into temporalLetra values(@CompraId,@ProveedorId,@TemporalDocumento,@TemporalMoneda,
@TemporalMonto,@UsuarioId,@TemporalCanje)
end
GO

IF OBJECT_ID(N'dbo.insertarTempCompra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarTempCompra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarTempCompra]
@UsuarioID int,
@IdProducto numeric(20),
@DetalleCodigo varchar(80),
@Descripcion varchar(255),
@DetalleUM   varchar(60),
@DetalleCantidad decimal(18,2),
@PrecioCosto  decimal(18,4),
@DetalleImporte decimal(18,2),
@DetalleDescuento decimal(18,4),
@DetalleEstado varchar(40)
--@ValorUM decimal(18,4)
as
begin
insert into TemporalCompra values(@UsuarioID,@IdProducto,@DetalleCodigo,
@Descripcion,@DetalleUM,@DetalleCantidad,@PrecioCosto,@DetalleImporte,
@DetalleDescuento,@DetalleEstado,1)
end
GO

IF OBJECT_ID(N'dbo.insertarTempCompraB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarTempCompraB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarTempCompraB]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,
        @p3 int,@p4 int,
        @p5 int,@p6 int,
        @p7 int,@p8 int,
        @p9 int,@p10 int,
        @p11 int
Declare @UsuarioID int,@IdProducto numeric(20),
		@DetalleCodigo varchar(80),@Descripcion varchar(255),
		@DetalleUM varchar(60),@DetalleCantidad decimal(18,2),
		@PrecioCosto  decimal(18,4),@DetalleImporte decimal(18,2),
		@DetalleDescuento decimal(18,4),@DetalleEstado varchar(40),
		@ValorUM decimal(18,4)
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3= CharIndex('|',@Data,@p2+1)
Set @p4= CharIndex('|',@Data,@p3+1)
Set @p5= CharIndex('|',@Data,@p4+1)
Set @p6= CharIndex('|',@Data,@p5+1)
Set @p7= CharIndex('|',@Data,@p6+1)
Set @p8= CharIndex('|',@Data,@p7+1)
Set @p9= CharIndex('|',@Data,@p8+1)
Set @p10= CharIndex('|',@Data,@p9+1)
Set @p11 = Len(@Data)+1
Set @UsuarioID =convert(int,SUBSTRING(@Data,1,@p1-1))
Set @IdProducto=convert(numeric(20),SUBSTRING(@Data,@p1+1,@p2-@p1-1))
Set @DetalleCodigo=SUBSTRING(@Data,@p2+1,@p3-@p2-1)
Set @Descripcion=SUBSTRING(@Data,@p3+1,@p4-@p3-1)
Set @DetalleUM=SUBSTRING(@Data,@p4+1,@p5-@p4-1)
Set @DetalleCantidad=convert(decimal(18,2),SUBSTRING(@Data,@p5+1,@p6-@p5-1))
Set @PrecioCosto=convert(decimal(18,4),SUBSTRING(@Data,@p6+1,@p7-@p6-1))
Set @DetalleImporte=convert(decimal(18,2),SUBSTRING(@Data,@p7+1,@p8-@p7-1))
Set @DetalleDescuento=convert(decimal(18,4),SUBSTRING(@Data,@p8+1,@p9-@p8-1))
Set @DetalleEstado=SUBSTRING(@Data,@p9+1,@p10-@p9-1)
Set @ValorUM=convert(decimal(18,4),SUBSTRING(@Data,@p10+1,@p11-@p10-1))
insert into TemporalCompra values(@UsuarioID,@IdProducto,@DetalleCodigo,
@Descripcion,@DetalleUM,@DetalleCantidad,@PrecioCosto,@DetalleImporte,
@DetalleDescuento,@DetalleEstado,@ValorUM)
select
isnull((select STUFF ((select '¬'+convert(varchar,t.TemporalId)+'|'+convert(varchar,t.IdProducto)+'|'+
t.DetalleCodigo+'|'+t.Descripcion+'|'+t.DetalleUM+'|'+
CONVERT(VarChar(50),cast(t.DetalleCantidad as money ), 1)+'|'+
convert(varchar,t.PrecioCosto)+'|'+convert(varchar,t.DetalleDescuento)
+'|'+convert(varchar,t.DetalleImporte)+'|'+CONVERT(varchar,t.ValorUM)+'|'+
t.DetalleEstado
from TemporalCompra t 
inner join Producto p 
on p.IdProducto=t.IdProducto 
where t.UsuarioID=@UsuarioID
order by t.TemporalId asc
for xml path('')),1,1,'')),'~')+'['+
isnull((select STUFF ((select '¬'+convert(varchar,u.IdUm)+'|'+convert(varchar,u.IdProducto)+'|'+
u.UMDescripcion+'|'+CONVERT(VarChar(50), cast(u.ValorUM as money ), 1)+'|'+
convert(varchar,t.PrecioCosto)
from UnidadMedida u
inner join TemporalCompra t
on t.IdProducto=u.IdProducto
where t.UsuarioID=@UsuarioID
order by u.ValorUM asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.insertarTempoGuia', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarTempoGuia] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarTempoGuia]
@UsuarioID int,
@IdProducto numeric(20),
@cantidad decimal(18,2),
@precioventa decimal(18,2),
@importe decimal(18,2),
@Concepto varchar(60),
@CantidadSaldo decimal(18,2),
@ClienteId numeric(20),
@DetalleId numeric(38),
@DetalleUM varchar(40),
@ValorUM decimal(18,4)
as
begin
insert into TemporalGuia values(@UsuarioID,@IdProducto,@cantidad,
@precioventa,@importe,@Concepto,@CantidadSaldo,@ClienteId,@DetalleId,@DetalleUM,@ValorUM)
end
GO

IF OBJECT_ID(N'dbo.insertarTempoVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarTempoVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarTempoVenta]
	@UsuarioID int,
	@IdProducto numeric(20),
	@cantidad decimal(18,2),
	@precioventa decimal(18,2),
	@importe decimal(18,2),
	@ValorUM decimal(18,4),
	@UniMedida varchar(40)
	as
	begin
	insert into TemporalVenta values(@UsuarioID,@IdProducto,@cantidad,@precioventa,@importe,@ValorUM,@UniMedida)
	end
GO

IF OBJECT_ID(N'dbo.insertarTemUMGuia', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarTemUMGuia] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarTemUMGuia]
@Data varchar(max)
as
	Declare @pos1 int
	Declare @pos2 int
	Declare @pos3 int
	Declare @pos4 int
	Declare @pos5 int
	Declare @pos6 int
	Declare @pos7 int
	Declare @pos8 int
Declare 
@UsuarioID int,
@IdProducto numeric(20),
@cantidad decimal(18,2),
@precioventa decimal(18,2),
@importe decimal(18,2),
@Concepto varchar(60),
@DetalleUM varchar(40),
@ValorUM decimal(18,4)
Set @Data = LTRIM(RTrim(@Data))
Set @pos1 = CharIndex('|',@Data,0)
Set @UsuarioID=convert(int,SUBSTRING(@Data,1,@pos1-1))
Set @pos2 = CharIndex('|',@Data,@pos1+1)
Set @IdProducto=convert(numeric(20),SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1))
Set @pos3 = CharIndex('|',@Data,@pos2+1)
Set @cantidad=convert(decimal(18,2),SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1))
Set @pos4 = CharIndex('|',@Data,@pos3+1)
Set @precioventa=convert(decimal(18,2),SUBSTRING(@Data,@pos3+1,@pos4-@pos3-1))
Set @pos5 = CharIndex('|',@Data,@pos4+1)
Set @importe=convert(decimal(18,2),SUBSTRING(@Data,@pos4+1,@pos5-@pos4-1))
Set @pos6 =CharIndex('|',@Data,@pos5+1)
Set @Concepto=SUBSTRING(@Data,@pos5+1,@pos6-@pos5-1)
Set @pos7=CharIndex('|',@Data,@pos6+1)
Set @DetalleUM=SUBSTRING(@Data,@pos6+1,@pos7-@pos6-1)
Set @pos8= Len(@Data)+1
Set @ValorUM=convert(decimal(18,4),SUBSTRING(@Data,@pos7+1,@pos8-@pos7-1))
IF EXISTS(select t.DetalleUM from TemporalGuia t where (t.IdProducto=@IdProducto and t.DetalleUM=@DetalleUM)and t.UsuarioID=@UsuarioID)
begin
select 'UM'
end
else
begin
insert into TemporalGuia values(@UsuarioID,@IdProducto,@cantidad,
@precioventa,@importe,@Concepto,0,0,0,@DetalleUM,@ValorUM)
select 'true'
end
GO

IF OBJECT_ID(N'dbo.insertarTemVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertarTemVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertarTemVenta]
	@UsuarioID int,
	@IdProducto numeric(20),
	@cantidad decimal(18,2),
	@precioventa decimal(18,2),
	@importe decimal(18,2),
	@ValorUM decimal(18,2),
	@UniMedida varchar(40)
	as
	begin
	insert into TemporalVenta values(@UsuarioID,@IdProducto,@cantidad,@precioventa,@importe,@ValorUM,@UniMedida)
	end
GO

IF OBJECT_ID(N'dbo.InsertarUM', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[InsertarUM] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[InsertarUM]
@Data varchar(max)
as
begin
Declare @pos1 int
Declare @pos2 int
Declare @pos3 int
Declare @pos4 int
Declare @pos5 int
Declare @pos6 int
Declare @pos7 int
declare @IdUm int,
@IdProducto numeric(20),
@UMDescripcion varchar(80),
@ValorUM decimal(18,4),
@PrecioVenta decimal(18,2),
@PrecioVentaB decimal(18,2),
@PrecioCosto decimal(18,4)
Set @Data = LTRIM(RTrim(@Data))
Set @pos1 = CharIndex('|',@Data,0)
Set @pos2 = CharIndex('|',@Data,@pos1+1)
Set @pos3 = CharIndex('|',@Data,@pos2+1)
Set @pos4 = CharIndex('|',@Data,@pos3+1)
Set @pos5 = CharIndex('|',@Data,@pos4+1)
Set @pos6 =CharIndex('|',@Data,@pos5+1)
Set @pos7 = Len(@Data)+1
Set @IdUm =convert(int,SUBSTRING(@Data,1,@pos1-1))
Set @IdProducto=convert(numeric,SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1))
Set @UMDescripcion=SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1)
Set @ValorUM=convert(decimal(18,4),SUBSTRING(@Data,@pos3+1,@pos4-@pos3-1))
Set @PrecioVenta=convert(decimal(18,2),SUBSTRING(@Data,@pos4+1,@pos5-@pos4-1))
Set @PrecioVentaB=convert(decimal(18,2),SUBSTRING(@Data,@pos5+1,@pos6-@pos5-1))
Set @PrecioCosto=convert(decimal(18,4),SUBSTRING(@Data,@pos6+1,@pos7-@pos6-1))
declare @CostoPro decimal(18,4),@costoTotal decimal(18,4)
set @CostoPro=(select top 1 p.ProductoCosto from Producto p where p.IdProducto=@IdProducto)
set @costoTotal=@ValorUM * @CostoPro
if @IdUm=0
begin
IF EXISTS(select u.UMDescripcion from UnidadMedida u where u.IdProducto=@IdProducto and u.UMDescripcion=@UMDescripcion)
select 'UM'
else IF EXISTS(select u.ValorUM from UnidadMedida u where u.IdProducto=@IdProducto and u.ValorUM=@ValorUM)
select 'VALOR'
else
begin
insert into UnidadMedida values(@IdProducto,@UMDescripcion,@ValorUM,@PrecioVenta,@PrecioVentaB,@costoTotal)
(select STUFF ((select '¬'+convert(varchar,m.IdUm)+'|'+CONVERT(varchar,m.IdProducto)+'|'+m.UMDescripcion+'|'+
CONVERT(VarChar(50),cast(m.ValorUM as money ),2)+'|'+CONVERT(VarChar(50),cast(m.PrecioVenta as money ), 1)+'|'+CONVERT(VarChar(50), cast(m.PrecioVentaB as money ), 1)+'|'+
CONVERT(varchar(50),m.PrecioCosto)
from UnidadMedida m
where m.IdProducto=@IdProducto
order by m.ValorUM asc
for xml path('')),1,1,''))
end
end
else
begin
update UnidadMedida
set PrecioVenta=@PrecioVenta,PrecioVentaB=@PrecioVentaB,PrecioCosto=@PrecioCosto
where IdUm=@IdUm
select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.insertaTemLiVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertaTemLiVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertaTemLiVenta]
@DocuId numeric(38),
@NotaId numeric(38),
@UsuarioId int,
@SaldoDocu decimal(18,2),
@TipoCambio decimal(18,3),
@EfectivoSoles decimal(18,2),
@EfectivoDolar decimal(18,2),
@DepositoSoles decimal(18,2),
@DepositoDolar decimal(18,2),
@EntidadBanco varchar(80),
@NroOperacion varchar(80),
@AcuentaGeneral decimal(18,2),
@TemporalFecha varchar(60)
as
begin
insert into TemporalLiVenta values(@DocuId,@NotaId,@UsuarioId,@SaldoDocu,@TipoCambio,@EfectivoSoles,
@EfectivoDolar,@DepositoSoles,@DepositoDolar,@EntidadBanco,@NroOperacion,@AcuentaGeneral,
@TemporalFecha)
end
GO

IF OBJECT_ID(N'dbo.insertaTempoLiquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertaTempoLiquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertaTempoLiquida]
@IdDeuda numeric(38, 0),
@Numero varchar(60),
@Proveedor varchar(255),
@SaldoDocu decimal(18, 2),
@Moneda varchar(20),
@TipoCambio decimal(18, 3),
@EfectivoSoles decimal(18, 2),
@EfectivoDolar decimal(18, 2),
@DepositoSoles decimal(18, 2),
@DepositoDolar decimal(18, 2),
@EntidadBanco varchar(80),
@NroOperacion varchar(80),
@AcuentaGeneral decimal(18, 2),
@TemporalFecha varchar(60),
@UsuarioId int,
@Concepto varchar(40)
as
begin
insert into TemporalLiquida values
(@IdDeuda,@Numero,@Proveedor,@SaldoDocu,@Moneda,@TipoCambio,
@EfectivoSoles,@EfectivoDolar,@DepositoSoles,@DepositoDolar,
@EntidadBanco,@NroOperacion,@AcuentaGeneral,@TemporalFecha,@UsuarioId,@Concepto)
end
GO

IF OBJECT_ID(N'dbo.insertaTipoCambio', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[insertaTipoCambio] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[insertaTipoCambio]
@Data varchar(max)
as
begin
	Declare @pos1 int
	Declare @pos2 int
	Declare @pos3 int
	Declare @pos4 int
	Declare @pos5 int
declare @IdTipo numeric(38),@TipoFecha date,@TipoCompra decimal(18,3),
@TipoVenta decimal(18,3),@TipoEmpresa decimal(18,3)
Set @Data = LTRIM(RTrim(@Data))
Set @pos1 = CharIndex('|',@Data,0)
Set @IdTipo =convert(numeric(38),SUBSTRING(@Data,1,@pos1-1))
Set @pos2 = CharIndex('|',@Data,@pos1+1)
Set @TipoFecha=convert(date,SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1))
Set @pos3 = CharIndex('|',@Data,@pos2+1)
Set @TipoCompra=convert(decimal(18,3),SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1))
Set @pos4 = CharIndex('|',@Data,@pos3+1)
Set @TipoVenta=convert(decimal(18,3),SUBSTRING(@Data,@pos3+1,@pos4-@pos3-1))
Set @pos5= Len(@Data)+1
Set @TipoEmpresa=convert(decimal(18,3),SUBSTRING(@Data,@pos4+1,@pos5-@pos4-1))
if(@IdTipo=0)
begin
IF EXISTS(select * from TipoCambio where TipoFecha=@TipoFecha)
	select 'false'
else
begin
	insert TipoCambio values(@TipoFecha,@TipoCompra,@TipoVenta,@TipoEmpresa)
	select isnull((select STUFF((select '¬'+ convert(varchar,t.IdTipo),+'|'+
	(Convert(char(10),t.TipoFecha,103))+'|'+convert(varchar,t.TipoCompra)+'|'+
	convert(varchar,t.TipoVenta)+'|'+
	convert(varchar,t.TipoEmpresa) 
	from TipoCambio t 
	where MONTH(t.TipoFecha)=MONTH(GETDATE()) and YEAR(t.TipoFecha)=YEAR(GETDATE()) 
	order by t.TipoFecha desc
	for xml path('')),1,1,'')),'~')	
end
end
else
begin
update TipoCambio
set TipoFecha=@TipoFecha,TipoCompra=@TipoCompra,TipoVenta=@TipoVenta,TipoEmpresa=@TipoEmpresa
where IdTipo=@IdTipo
select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.KardeProveedor', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[KardeProveedor] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[KardeProveedor]
@IdProducto numeric(20),
@fechainicio date,
@fechafin date
as
begin
select p.ProveedorId,p.ProveedorRazon,(Convert(char(10),c.CompraEmision,103)) as FechaEmision,
substring(t.TipoDescripcion,1,1)+'-C  '+c.CompraSerie+'-'+c.CompraNumero as Numero,
c.CompraTipoCambio as TipoCambio,CONVERT(VarChar(50), cast(d.DetalleCantidad as money ), 1)as Cantidad,
substring(d.DetalleUM,1,3) as UM,	
case when(CompraMoneda='DOLARES')then 
case when(CompraTipoIgv='DISGREGADO')then
cast((((((d.DetalleImporte-d.DetalleDescuento)/d.DetalleCantidad)*1)*1.18)- d.DescuentoB) as decimal(18,4))
else
cast(((cast(((d.DetalleImporte-d.DetalleDescuento)/d.DetalleCantidad)as decimal(18,4))-d.DescuentoB)*1) as decimal(18,4))
end
else
case when(CompraTipoIgv='DISGREGADO') then
cast(((((d.DetalleImporte-d.DetalleDescuento)/d.DetalleCantidad)*1.18)-d.DescuentoB) as decimal(18,4))
else 
cast((((d.DetalleImporte-d.DetalleDescuento)/d.DetalleCantidad)-d.DescuentoB)as decimal(18,4)) 
end end as CostoSoles,
------
case when(CompraMoneda='DOLARES')then 
case when(CompraTipoIgv='DISGREGADO')then
cast(((((d.DetalleImporte-d.DetalleDescuento)/d.DetalleCantidad)*1.18)-d.DescuentoB) as decimal(18,4))
else 
cast((((d.DetalleImporte-d.DetalleDescuento)/d.DetalleCantidad)-d.DescuentoB) as decimal(18,4))
end
else 
case when(CompraTipoIgv='DISGREGADO')then 
cast((((((d.DetalleImporte-d.DetalleDescuento)/d.DetalleCantidad)/1)*1.18)-d.DescuentoB) as decimal(18,4))
else 
cast(((((d.DetalleImporte-d.DetalleDescuento)/d.DetalleCantidad)/1)-d.DescuentoB) as decimal(18,4))
end end as CostoDolar
from DetalleCompra d
inner join Compras c
on c.CompraId=d.CompraId
inner join Proveedor p
on p.ProveedorId=c.ProveedorId
inner join TipoComprobante t
on t.TipoCodigo=c.TipoCodigo
where(Convert(char(10),c.CompraEmision,101) BETWEEN @fechainicio AND @fechafin) and d.IdProducto=@IdProducto
order by 1 desc,c.CompraEmision desc
end
GO

IF OBJECT_ID(N'dbo.kardexCompra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[kardexCompra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[kardexCompra] 
@ProveedorId numeric(38),
@Asociado varchar(60),
@CompraId numeric(38)
as
begin
select (Convert(char(10),c.CompraEmision,103)) as FechaPago,c.CompraId,
'NC '+c.CompraSerie+'-'+c.CompraNumero as Documento,c.CompraMoneda as Moneda,
CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1)as Acuenta,c.CompraTotal
from Compras c
where (c.ProveedorId=@ProveedorId and (c.CompraAsociado)=@Asociado)
union all
select d.FechaPago,d.CompraId,'LQ '+l.LiquidacionNumero as Documento,c.CompraMoneda as Moneda,
CONVERT(VarChar(50), cast(d.AcuentaGeneral as money ), 1)as Acuenta,d.AcuentaGeneral
from DetalleLiquida d
inner join Liquidacion l
on l.LiquidacionId=d.LiquidacionId
inner join Compras c
on c.CompraId=d.CompraId
where c.CompraId=@CompraId
order by 6 desc
end
GO

IF OBJECT_ID(N'dbo.Ld_listaAlmacen', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[Ld_listaAlmacen] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[Ld_listaAlmacen]
as
begin
select 
'Id|Almacen|Departamento|Provincia|Distrito|Direccion|Estado¬80|435|100|100|100|100|100¬String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+ convert(varchar,a.AlmacenId)+'|'+a.AlmacenNombre+'|'+a.AlmacenDepartamento+'|'+
a.AlmacenProvincia+'|'+a.AlmacenDistrito+'|'+a.AlmacenDireccion+'|'+a.AlmacenEstado
from Almacen a
order by AlmacenId desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.ldBloques', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ldBloques] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ldBloques]
as
begin
declare @fechaReferencia date
set @fechaReferencia=(select top 1 n.NotaFecha from NotaPedido n
where (n.NotaCondicion='ALCONTADO' and n.NotaEntrega='INMEDIATA' and n.NotaFormaPago='EFECTIVO')and
(n.NotaEstado<>'ANULADO'and(n.NotaConcepto='MERCADERIA' and(((n.NotaEstado<>'CANCELADO' and n.NotaAcuenta<=0) AND n.NotaDocu <>'PROFORMA'))))
group by n.NotaFecha
order by n.NotaFecha asc)
select
'NotaId|Usuario|FechaEmision|Documento|ClienteRazon|Saldo|Total¬100|150|150|135|400|120|120¬String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,n.NotaId)+'|'+n.NotaUsuario+'|'+
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
n.NotaDocu+'|'+c.ClienteRazon+'|'+
CONVERT(VarChar(50), cast(n.NotaSaldo as money ), 1)+'|'+
CONVERT(VarChar(50), cast(n.NotaPagar as money ), 1)
from NotaPedido n
inner join Cliente c
on c.ClienteId=n.ClienteId
where convert(date,n.NotaFecha)=@fechaReferencia and(n.NotaCondicion='ALCONTADO' and n.NotaEntrega='INMEDIATA' and n.NotaFormaPago='EFECTIVO')and
(n.NotaEstado<>'ANULADO'and(n.NotaConcepto='MERCADERIA' and(((n.NotaEstado<>'CANCELADO' and n.NotaAcuenta<=0) AND n.NotaDocu <>'PROFORMA'))))
order by n.NotaId asc
FOR XML path ('')),1,1,'')),'~')+'_'+
'NotaId|FechaEmision|Documento|Vendedor|IdPro|Cantidad|UM|Descripcion|PrecioVenta|PrecioCosto|Importe|ValorUM¬95|153|105|150|70|100|60|330|100|100|110|100¬String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF(( select '¬'+ convert(varchar,d.NotaId)+'|'+
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
n.NotaDocu+'|'+n.NotaUsuario+'|'+
convert(varchar,d.IdProducto)+'|'+
CONVERT(VarChar(50), cast(d.DetalleCantidad as money ), 1)+'|'+
d.DetalleUm+'|'+d.DetalleDescripcion+'|'+
CONVERT(VarChar(50), cast(d.DetallePrecio as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleCosto as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleImporte as money ), 1)+'|'+
CONVERT(varchar,d.ValorUM)
from DetallePedido d
inner join NotaPedido n
on n.NotaId=d.NotaId
where convert(date,n.NotaFecha)=@fechaReferencia and(n.NotaCondicion='ALCONTADO' and n.NotaEntrega='INMEDIATA' and n.NotaFormaPago='EFECTIVO')and
(n.NotaEstado<>'ANULADO'and(n.NotaConcepto='MERCADERIA' and(((n.NotaEstado<>'CANCELADO' and n.NotaAcuenta<=0) AND n.NotaDocu <>'PROFORMA'))))
order by n.NotaId asc
FOR XML PATH('')), 1, 1, '')),'~')+'_'+
isnull((select STUFF((select '¬'+CONVERT(varchar,c.CajaId)
from Caja c
where CajaEstado='ACTIVO'
FOR XML path ('')),1,1,'')),'0')+'_'+
isnull((select top 15 STUFF((select top 15 '¬'+convert(varchar,b.BloqueId)+'|'+
(IsNull(convert(varchar,b.BloqueFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,b.BloqueFecha,114),1,8),''))
from Bloque b
order by b.BloqueId desc
FOR XML path ('')),1,1,'')),'')
end
GO

IF OBJECT_ID(N'dbo.LDdocumentos', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[LDdocumentos] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[LDdocumentos]
@Data varchar(max)
as
Declare @p1 int,@p2 int
Declare @fechainicio date,
        @fechafin date
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2= Len(@Data)+1
Set @fechainicio=convert(date,SUBSTRING(@Data,1,@p1-1))
Set @fechafin=convert(date,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
begin
select 'Fecha|Documento|NroDoc|Cliente|RUC|DNI|SubTotal|IGV|ICBPER|Total|Usuario|Estado|Referencia|Codigo|Mensaje|Condicion|FormaPago|Entidad|NroOperacion|Efectivo|Deposito¬85|90|110|250|80|80|115|115|90|115|150|150|110|0|0|0|0|0|0|0|0¬'+
isnull((select STUFF((select '¬'+(Convert(char(10),d.DocuEmision,103))+'|'+
d.DocuDocumento+'|'+
convert(varchar,d.DocuSerie+'-'+d.DocuNumero)+'|'+
c.ClienteRazon+'|'+isnull(c.ClienteRuc,'')+'|'+isnull(c.ClienteDni,'')+'|'+
case when(d.TipoCodigo='07')then 
'-'+CONVERT(VarChar(50), cast(d.DocuSubTotal as money ), 1)
else
CONVERT(VarChar(50), cast(d.DocuSubTotal as money ), 1)end+'|'+
case when (d.TipoCodigo='07')then
'-'+CONVERT(VarChar(50), cast(d.DocuIgv as money), 1)
else
CONVERT(VarChar(50), cast(d.DocuIgv as money), 1)end+'|'+
case when (d.TipoCodigo='07')then
'-'+CONVERT(VarChar(50), cast(d.ICBPER as money), 1)
else
CONVERT(VarChar(50), cast(d.ICBPER as money), 1)end+'|'+
case when (d.TipoCodigo='07')then
'-'+CONVERT(VarChar(50), cast(d.DocuTotal as money ), 1)
else
CONVERT(VarChar(50), cast(d.DocuTotal as money ), 1)end+'|'+
d.DocuUsuario+'|'+d.DocuEstado+'|'+d.DocuNroGuia+'|'+d.CodigoSunat+'|'+Replace(d.MensajeSunat,'|',' ')+'|'+
d.DocuCondicion+'|'+d.FormaPago+'|'+d.EntidadBancaria+'|'+d.NroOperacion+'|'+
CONVERT(VarChar(50), cast(d.Efectivo as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.Deposito as money ), 1)
from DocumentoVenta d
inner join Cliente c
on c.ClienteId=d.ClienteId
where (Convert(char(10),d.DocuEmision,101) BETWEEN @fechainicio AND @fechafin) and d.DocuDocumento<>'PROFORMA V'
--where (Convert(char(10),d.DocuEmision,101) BETWEEN @fechainicio AND @fechafin) --and d.DocuDocumento<>'PROFORMA V'
order by d.DocuEmision asc,d.DocuSerie+'-'+d.DocuNumero asc
FOR XML PATH('')), 1, 1, '')),'~')
end
GO

IF OBJECT_ID(N'dbo.LdGanancia', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[LdGanancia] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[LdGanancia] 
@NotaId numeric(38)
as
begin
declare @Estado varchar(80)
set @Estado=(select top 1 n.NotaEstado from NotaPedido n where n.NotaId=@NotaId)
select 
'FechaEmision|Vendedor|Descripcion|Cantidad|UM|PrecioUni|PreCosto|GXUnidad|Importe|Ganancia¬150|150|385|110|70|110|110|110|0|120¬'+
(select STUFF((select '¬'+(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
n.NotaUsuario+'|'+d.DetalleDescripcion+'|'+
CONVERT(VarChar(50), cast((d.DetalleCantidad) as money ), 1)+'|'+d.DetalleUm+'|'+
CONVERT(VarChar(50), cast(d.DetallePrecio as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleCosto as money ), 1)+'|'+
CONVERT(VarChar(50), cast((d.DetallePrecio-d.DetalleCosto) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((d.DetalleImporte) as money ), 1)+'|'+
CONVERT(VarChar(50), cast(((d.DetallePrecio-d.DetalleCosto)* d.DetalleCantidad) as money ), 1)
from DetallePedido d (noLOCK) 
inner join NotaPedido n (noLOCK)
on n.NotaId=d.NotaId
where d.NotaId=@NotaId
order by d.DetalleId asc
for xml path('')),1,1,''))
end
GO

IF OBJECT_ID(N'dbo.LDrptCompra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[LDrptCompra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[LDrptCompra]
@Data varchar(max)
as
Declare @p1 int,@p2 int
Declare @fechainicio date,
        @fechafin date
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2= Len(@Data)+1
Set @fechainicio=convert(date,SUBSTRING(@Data,1,@p1-1))
Set @fechafin=convert(date,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
begin
Select
'Compania|FechaEmision|Documento|RUC|RazonSocial|Tipo|BaseImp|IGV|Total|Moneda|TipoSunat|Monto|Referencia¬
68|95|110|90|330|45|105|105|105|85|75|105|110¬'+
isnull((select stuff((select '¬'+CONVERT(varchar,c.CompaniaId)+'|'+(Convert(char(10),c.CompraEmision,103))+'|'+
(c.CompraSerie+'-'+c.CompraNumero)+'|'+
p.ProveedorRuc+'|'+p.ProveedorRazon+'|'+c.TipoCodigo+'|'+
case when c.CompraMoneda='DOLARES' THEN
case when c.TipoCodigo='07' then
'-'+CONVERT(VarChar(50), cast((c.CompraTotal/1.18)*c.CompraTipoSunat as money ), 1)
else
 CONVERT(VarChar(50), cast((c.CompraTotal/1.18)*c.CompraTipoSunat as money ), 1)end
else  
case when c.TipoCodigo='07' then
'-'+CONVERT(VarChar(50), cast((c.CompraTotal/1.18) as money ), 1)
else
CONVERT(VarChar(50), cast((c.CompraTotal/1.18) as money ), 1)end
end+'|'+
case when c.CompraMoneda='DOLARES' then
case when c.TipoCodigo='07' then
'-'+CONVERT(VarChar(50), cast((c.CompraTotal-(c.CompraTotal/1.18))*c.CompraTipoSunat as money ), 1)
else
 CONVERT(VarChar(50), cast((c.CompraTotal-(c.CompraTotal/1.18))*c.CompraTipoSunat as money ), 1)end
else 
case when c.TipoCodigo='07' then
'-'+CONVERT(VarChar(50), cast((c.CompraTotal-(c.CompraTotal/1.18))as money ), 1)
else
CONVERT(VarChar(50), cast((c.CompraTotal-(c.CompraTotal/1.18))as money ), 1)end
end+'|'+
case when c.CompraMoneda='DOLARES' then
case when c.TipoCodigo='07' then
'-'+CONVERT(VarChar(50), cast((c.CompraTotal *c.CompraTipoSunat) as money ), 1)
else
CONVERT(VarChar(50), cast((c.CompraTotal *c.CompraTipoSunat) as money ), 1) end
else 
case when c.TipoCodigo='07' then
'-'+CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1)
else
CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1)end
end+'|'+
c.CompraMoneda+'|'+convert(varchar,c.CompraTipoSunat)+'|'+
case when c.TipoCodigo='07' then
'-'+CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1)
else
CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1)
end+'|'+CompraAsociado
from Compras c
inner join Proveedor p
on p.ProveedorId=c.ProveedorId
where (Convert(char(10),c.CompraComputo,101) BETWEEN @fechainicio AND @fechafin) and(c.TipoCodigo='01' or c.TipoCodigo='07')
order by c.CompraEmision asc
FOR XML PATH('')), 1, 1, '')),'~')
end
GO

IF OBJECT_ID(N'dbo.ldTraerDetalle', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ldTraerDetalle] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ldTraerDetalle]
@Data varchar(max)
as
begin
declare @p0 int, 
        @p1 int
declare @IdProducto numeric(20),
		@NotaId numeric(38),
		@Ganancia decimal(18,2),
		@PV decimal(18,2),
		@SV decimal(18,2)
		set @p0 = CharIndex('|',@Data,0)
        Set @p1 = Len(@Data)+1
	Set @IdProducto=Convert(numeric(20),SUBSTRING(@Data,1,@p0-1))
	Set @NotaId= Convert(numeric(38),SUBSTRING(@Data,@p0+1,@p1-@p0-1))
	set @Ganancia=(select top 1 (d.DetallePrecio - d.DetalleCosto) 
	from DetallePedido d where d.IdProducto=@IdProducto and d.NotaId=@NotaId)
	set @PV=(select top 1 p.ProductoPV from Producto p where p.IdProducto=@IdProducto)
	set @SV=(select top 1 p.ProductoSV from Producto p where p.IdProducto=@IdProducto)
begin
	update DetallePedido 
	set DetalleCantidad=DetalleCantidad + 1,
	DetalleImporte=((DetalleCantidad + 1)* DetallePrecio),
	DetallePV=((DetalleCantidad + 1)* @PV),
	DetalleSV=((DetalleCantidad + 1)* @SV)
	where IdProducto=@IdProducto and NotaId=@NotaId
	update NotaPedido
	set NotaGanancia=NotaGanancia+@Ganancia
	where NotaId=@NotaId
	select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.LetrasVencidas', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[LetrasVencidas] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[LetrasVencidas] 
as
begin
select p.ProveedorRazon as RazonSocial,'LT '+d.LetraCanje as Documento,
substring(l.LetraMoneda,1,1)+'/  '+CONVERT(VarChar(50),cast(d.DetalleSaldo as money ), 1) as SaldoDoc,
(Convert(char(10),d.LetraVencimiento,103)) as Vencimiento,
convert(char(10),(dateadd(DAY,6,d.LetraVencimiento)),103) as FinVencimiento,
case when ((dateadd(DAY,6,d.LetraVencimiento))<= CONVERT(date,GETDATE())) then
'VENCIDO'
else
case when (CONVERT(date,GETDATE())>=(d.LetraVencimiento)) then
'POR VENCER'
else
'PENDIENTE'
end end as Estado
from DetalleLetra d
inner join Letra l
on l.LetraId=d.LetraId
inner join Proveedor p
on p.ProveedorId=l.ProveedorId
where (d.DetalleEstado<>'TOTALMENTE PAGADO') and ((dateadd(DAY,-6,d.LetraVencimiento))<= CONVERT(date,GETDATE()))
union all
select p.ProveedorRazon as RazonSocial,substring(t.TipoDescripcion,1,1)+'C '+C.CompraSerie+' '+c.CompraNumero as Documento,
substring(c.CompraMoneda,1,1)+'/  '+CONVERT(VarChar(50),cast(c.CompraSaldo as money ), 1) as SaldoDoc,
(Convert(char(10),c.CompraFechaPago,103))as Vencimiento,(Convert(char(10),c.CompraFechaPago,103)) as FinVencimiento,
case when (CONVERT(date,GETDATE())>=(c.CompraFechaPago)) then
'VENCIDO'
else
case when ((dateadd(DAY,-2,c.CompraFechaPago))<= CONVERT(date,GETDATE())) then
'POR VENCER'
else
'PENDIENTE'
end end as Estado
from Compras c
inner join Proveedor p
on c.ProveedorId=p.ProveedorId
inner join TipoComprobante t
on t.TipoCodigo=c.TipoCodigo
where c.CompraEstado='PENDIENTE DE PAGO' and ((dateadd(DAY,-6,c.CompraFechaPago))<= CONVERT(date,GETDATE()))
end
GO

IF OBJECT_ID(N'dbo.LetrasVencidasR', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[LetrasVencidasR] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[LetrasVencidasR]
as
begin
select Row_number() over(order by d.LetraVencimiento asc)as Item,p.ProveedorRazon as RazonSocial,'LT '+d.LetraCanje as LetraCanje,
l.LetraMoneda as Moneda,CONVERT(VarChar(50),cast(d.DetalleSaldo as money ), 1) as SaldoDoc,
(Convert(char(10),d.LetraVencimiento,103)) as Vencimiento,
convert(char(10),(dateadd(DAY,6,d.LetraVencimiento)),103) as FinVencimiento,
case when ((dateadd(DAY,6,d.LetraVencimiento))<= CONVERT(date,GETDATE())) then
'VENCIDO'
else
case when ((dateadd(DAY,-6,d.LetraVencimiento))<= CONVERT(date,GETDATE())) then
'POR VENCER'
else 
'PENDIENTE'
end end as Estado
from DetalleLetra d
inner join Letra l
on l.LetraId=d.LetraId
inner join Proveedor p
on p.ProveedorId=l.ProveedorId
where (d.DetalleEstado<>'TOTALMENTE PAGADO')
order by d.LetraVencimiento asc
end
GO

IF OBJECT_ID(N'dbo.listaAperturaAlmacen', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaAperturaAlmacen] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaAperturaAlmacen]  
as  
begin  
select  a.IdApertura as ID,  
convert(varchar,a.FechaApertura,103)+' '+ SUBSTRING(convert(varchar,a.FechaApertura,114),1,8) as FechaApertura,  
a.FechaCierre,a.UsuarioID,a.Usuario,a.Observacion,  
case when (a.AperturaEstado='0')then  
'APERTURA'  
else 'CIERRE' end as Estado,a.ObservacionCierre as ObservacionC  
from APERTURA_ALMACEN a  
where Month(a.FechaApertura)=Month(GETDATE())and year(a.FechaApertura)=YEAR(Getdate())  
order by a.IdApertura desc  
end
GO

IF OBJECT_ID(N'dbo.listaAperturaFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaAperturaFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaAperturaFecha]
@fechainicio date,
@fechafin date
as
begin
select  a.IdApertura as ID,
convert(varchar,a.FechaApertura,103)+' '+ SUBSTRING(convert(varchar,a.FechaApertura,114),1,8) as FechaApertura,
a.FechaCierre,a.UsuarioID,a.Usuario,a.Observacion,
case when (a.AperturaEstado='0')then
'APERTURA'
else 'CIERRE' end as Estado,a.ObservacionCierre as ObservacionC
from APERTURA_ALMACEN a
where (Convert(char(10),a.FechaApertura,101) BETWEEN @fechainicio AND @fechafin) 
order by a.IdApertura desc
end
GO

IF OBJECT_ID(N'dbo.listaBloque', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaBloque] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaBloque]
@BloqueId numeric(38)
as
begin
select
'NotaId|Usuario|FechaEmision|Documento|ClienteRazon|Saldo|Total¬100|150|150|135|400|120|120¬String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,b.NotaId)+'|'+
n.NotaUsuario+'|'+
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
n.NotaDocu+'|'+
c.ClienteRazon+'|'+
CONVERT(VarChar(50), cast(n.NotaSaldo as money ), 1)+'|'+
CONVERT(VarChar(50), cast(n.NotaPagar as money ), 1)+'|'+
convert(varchar,b.BloqueId)
from DetalleBloque b
inner join NotaPedido n
on  n.NotaId=b.NotaId
inner join Cliente c
on c.ClienteId=n.ClienteId
where b.BloqueId=@BloqueId
FOR XML path ('')),1,1,'')),'~')+'_'+
'NotaId|FechaEmision|Documento|Vendedor|IdPro|Cantidad|UM|Descripcion|PrecioVenta|PrecioCosto|Importe|ValorUM¬95|153|105|150|70|100|60|330|100|100|110|100¬String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF(( select '¬'+ convert(varchar,d.NotaId)+'|'+
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
n.NotaDocu+'|'+n.NotaUsuario+'|'+
convert(varchar,d.IdProducto)+'|'+
CONVERT(VarChar(50), cast(d.DetalleCantidad as money ), 1)+'|'+
d.DetalleUm+'|'+d.DetalleDescripcion+'|'+
CONVERT(VarChar(50), cast(d.DetallePrecio as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleCosto as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleImporte as money ), 1)+'|'+
CONVERT(varchar,d.ValorUm)
from DetalleBloque b
inner join DetallePedido d
on d.NotaId=b.NotaId
inner join NotaPedido n
on n.NotaId=d.NotaId
where b.BloqueId=@BloqueId
FOR XML PATH('')), 1, 1, '')),'~')
end
GO

IF OBJECT_ID(N'dbo.listaCanjeFactura', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaCanjeFactura] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaCanjeFactura]
as
begin
SELECT dbo.GuiaCanje.*, dbo.Compras.CompraMoneda as Moneda,(convert(varchar(50), CAST(dbo.Compras.CompraValorVenta as money), -1))as Total,
(SUBSTRING(dbo.Compras.CompraMoneda,1,1)+'/.  '+(convert(varchar(50), CAST(dbo.Compras.CompraTotal as money), -1)))as Monto,dbo.Proveedor.ProveedorRazon as Proveedor
FROM dbo.GuiaCanje INNER JOIN dbo.Compras ON dbo.GuiaCanje.CompraId = dbo.Compras.CompraId inner join dbo.Proveedor on dbo.Proveedor.ProveedorId=dbo.Compras.ProveedorId 
where year(dbo.GuiaCanje.CanjeFecha)=YEAR(GETDATE())
order by dbo.GuiaCanje.CanjeId desc
end
GO

IF OBJECT_ID(N'dbo.listaCompraComputo', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaCompraComputo] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaCompraComputo]
@f1 date,
@f2 date
as
begin
select c.CompraId,c.CompraCorrelativo,c.CompaniaId,c.CompraRegistro,Convert(char(10),c.CompraComputo,103)as CompraComputo,Convert(char(10),c.CompraEmision,103)as CompraEmision,p.ProveedorRazon,
p.ProveedorRuc,c.TipoCodigo,c.CompraSerie,c.CompraNumero,c.CompraCondicion,c.CompraMoneda,CompraTipoCambio,c.CompraDias,Convert(char(10),c.CompraFechaPago,103) as CompraFechaPago,
c.CompraTipoIgv,CONVERT(VarChar(50), cast(c.CompraValorVenta as money ), 1) as ValorVenta,CONVERT(VarChar(50), cast(c.CompraDescuento as money ), 1)as Descuento,CONVERT(VarChar(50), 
cast(c.CompraSubtotal as money ), 1) as Subtotal,CONVERT(VarChar(50), cast(c.CompraIgv as money ), 1) as Igv,CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1) as Total,
CONVERT(VarChar(50), cast(c.compraSaldo as money ), 1) as CompraSaldo,c.CompraUsuario,co.CompaniaRazonSocial,
c.CompraEstado,c.ProveedorId,t.TipoDescripcion,c.CompraAsociado as Asociado,CompraOBS,CompraTipoSunat as TipoSunat,CompraConcepto as Concepto
from Compras c
inner join Proveedor p
on p.ProveedorId=c.ProveedorId
inner join Compania co
on co.CompaniaId=c.CompaniaId
inner join TipoComprobante t
on t.TipoCodigo=c.TipoCodigo
where(c.TipoCodigo<>'07' and c.TipoCodigo<>'101')and(Convert(char(10),c.CompraComputo, 101) BETWEEN @f1 AND @f2)
order by c.CompraEmision asc
end
GO

IF OBJECT_ID(N'dbo.listaCompraEmision', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaCompraEmision] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaCompraEmision] 
@f1 date,
@f2 date
as
begin
select c.CompraId,c.CompraCorrelativo,c.CompaniaId,c.CompraRegistro,Convert(char(10),c.CompraComputo,103)as CompraComputo,Convert(char(10),c.CompraEmision,103)as CompraEmision,p.ProveedorRazon,
p.ProveedorRuc,c.TipoCodigo,c.CompraSerie,c.CompraNumero,c.CompraCondicion,c.CompraMoneda,CompraTipoCambio,c.CompraDias,Convert(char(10),c.CompraFechaPago,103) as CompraFechaPago,
c.CompraTipoIgv,CONVERT(VarChar(50), cast(c.CompraValorVenta as money ), 1) as ValorVenta,CONVERT(VarChar(50), cast(c.CompraDescuento as money ), 1)as Descuento,CONVERT(VarChar(50), 
cast(c.CompraSubtotal as money ), 1) as Subtotal,CONVERT(VarChar(50), cast(c.CompraIgv as money ), 1) as Igv,CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1) as Total,
CONVERT(VarChar(50), cast(c.compraSaldo as money ), 1) as CompraSaldo,c.CompraUsuario,co.CompaniaRazonSocial,
c.CompraEstado,c.ProveedorId,t.TipoDescripcion,c.CompraAsociado as Asociado,CompraOBS,CompraTipoSunat as TipoSunat,CompraConcepto as Concepto
from Compras c
inner join Proveedor p
on p.ProveedorId=c.ProveedorId
inner join Compania co
on co.CompaniaId=c.CompaniaId
inner join TipoComprobante t
on t.TipoCodigo=c.TipoCodigo
where(c.TipoCodigo<>'07' and c.TipoCodigo<>'101') and
(Convert(char(10),c.CompraEmision, 101) BETWEEN @f1 AND @f2)
order by c.CompraEmision asc
end
GO

IF OBJECT_ID(N'dbo.listaDetaGeneral', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaDetaGeneral] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaDetaGeneral] 
@IdGeneral numeric(38)
as
select
'ID|Concepto|CajaId|Fecha|Descripcion|Monto|Usuario|Imagen¬90|100|80|136|373|120|100|90¬String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen 
from CajaPincipal c 
where c.CajaConcepto='INGRESO' and c.IdGeneral=@IdGeneral
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')+'['+
'ID|Concepto|CajaId|Fecha|Descripcion|Monto|Usuario|Imagen¬90|100|80|135|435|125|100|90¬String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+ convert(varchar,c.IdCaja)+'|'+c.CajaConcepto+'|'+convert(varchar,c.CajaId)+'|'+
Convert(char(10),c.CajaFecha,103)+' '+Convert(char(8),c.CajaFecha,114) 
+'|'+c.CajaDescripcion+'|'+CONVERT(VarChar(50),cast(c.CajaMonto as money), 1)+'|'+
c.CajaUsuario+'|'+c.RutaImagen 
from CajaPincipal c 
where c.CajaConcepto='SALIDA' and c.IdGeneral=@IdGeneral
order by c.IdCaja desc
for xml path('')),1,1,'')),'~')
GO

IF OBJECT_ID(N'dbo.listaDetaliquiVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaDetaliquiVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaDetaliquiVenta] 
@LiquidacionId numeric(38)
as
begin
select d.DetalleId,d.LiquidacionId,n.NotaId as DocuId,n.NotaSerie+'-'+n.NotaNumero as Numero,
c.ClienteRazon,CONVERT(VarChar(50), cast(d.SaldoDocu as money ), 1) as Saldo,'SOLES' as Moneda,d.EfectivoSoles,
d.EfectivoDolar,d.DepositoSoles,d.DepositoDolar,d.TipoCambio,d.EntidadBanco,d.NroOperacion,
CONVERT(VarChar(50), cast(d.AcuentaGeneral as money ), 1) as Acuenta,
d.FechaPago,CONVERT(VarChar(50), cast(d.SaldoActual as money ), 1)as SaldoActual,d.NotaId 
from DetaLiquidaVenta d
inner join NotaPedido n
on n.NotaId=d.NotaId
inner join Cliente c
on c.ClienteId=n.ClienteId
where d.LiquidacionId=@LiquidacionId
order by 1 asc
end
GO

IF OBJECT_ID(N'dbo.listaDetalleCompra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaDetalleCompra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaDetalleCompra]
@CompraId varchar(60)
as
begin
select
'DetalleId|IdProducto|DetalleCodigo|Descripcion|UM|Cantidad|PrecioCosto|Descuento|Importe|ValorUM|Estado¬100|100|100|420|80|90|100|100|110|100|100¬String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,d.DetalleId)+'|'+convert(varchar,d.IdProducto)+'|'+
d.DetalleCodigo+'|'+d.Descripcion+'|'+d.DetalleUM+'|'+CONVERT(VarChar(50),cast(d.DetalleCantidad as money ),1)+'|'+
convert(varchar,d.PrecioCosto)+'|'+convert(varchar,d.detalleDescuento)+'|'+
CONVERT(VarChar(50),cast(d.DetalleImporte as money ), 2)+'|'+CONVERT(varchar,d.ValorUM)+'|'+d.DetalleEstado
from DetalleCompra d
where d.CompraId=@CompraId
order by d.DetalleId asc
for xml path('')),1,1,'')),'~')+'['+
'IdUm|IdProducto|UNIDAD M|Valor|Costo¬100|100|100|100|100¬String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,u.IdUm)+'|'+convert(varchar,u.IdProducto)+'|'+
u.UMDescripcion+'|'+CONVERT(VarChar(50), cast(u.ValorUM as money ), 1)+'|'+
convert(varchar,d.PrecioCosto)
from UnidadMedida u
inner join DetalleCompra d
on d.IdProducto=u.IdProducto
where d.CompraId=@CompraId
order by u.ValorUM asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.listaDetalleDocu', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaDetalleDocu] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaDetalleDocu]    
@DocuId numeric(38)    
as    
begin    
Select    
'Id|DocuId|IdProducto|Codigo|Cantidad|Unidad|Descripcion|Precio|PV|SV|Importe¬100|100|100|100|100|90|365|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String¬'+    
isnull((select STUFF ((select '¬'+convert(varchar,d.DetalleId)+'|'+convert(varchar,d.DetalleNotaId)+'|'+    
convert(varchar,d.IdProducto)+'|'+p.ProductoCodigo+'|'+convert(varchar(50),cast(d.DetalleCantidad as money),1)+'|'+    
d.DetalleUM+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+convert(varchar(50),cast(d.DetallPrecio as money),1)+'|'+    
convert(varchar(50),CAST(d.DetalleCantidad *p.ProductoPV as money),1)+'|'+    
convert(varchar(50),CAST(d.DetalleCantidad *p.ProductoSV as money),1)+'|'+   
(convert(varchar(50),CAST(d.DetalleImporte as money),1))   
from DetalleDocumento d    
inner join Producto p    
on p.IdProducto=d.IdProducto    
where DocuId=@DocuId    
order by 1 asc    
for xml path('')),1,1,'')),'~')    
end
GO

IF OBJECT_ID(N'dbo.listaDetalleGuiaSP', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaDetalleGuiaSP] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaDetalleGuiaSP]
@GuiaId nvarchar(38)
as
begin
select
'DetalleId|NotaId|IdProducto|Codigo|Cantidad|UM|Descripcion|PrecioCosto|PrecioUni|PV|SV|Importe|Imagen|ValorUM|PrecioSunat|IGVPrecio|ImporteSunat|PVUNI|SVUNI|Linea¬100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select stuff((select '¬'+convert(varchar,d.DetalleId)+'|'+convert(varchar,d.GuiaId)+'|'+
convert(varchar,d.IdProducto)+'|'+p.ProductoCodigo+'|'+
CONVERT(VarChar(50), cast(d.DetalleCantidad as money ), 1)+'|'+
p.ProductoUM+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
CONVERT(VarChar(50), cast(d.DetalleCosto as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetallePrecio as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetallePV as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleSV as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleImporte as money ), 1)+'|'+
p.ProductoImagen+'|1|'+
convert(varchar,convert(decimal(18,2),d.DetallePrecio/1.18))+'|'+
convert(varchar,(d.DetalleImporte - convert(decimal(18,2),d.DetalleImporte/1.18)))+'|'+
convert(varchar,convert(decimal(18,2),d.DetalleImporte/1.18))+'|'+
convert(varchar,p.ProductoPV)+'|'+convert(varchar,p.ProductoSV)+'|'+
s.NombreSublinea
from DetalleGuia d
inner join Producto p
on p.IdProducto=d.IdProducto
inner join Sublinea s
on s.IdSubLinea=p.IdSubLinea
where d.GuiaId=@GuiaId
order by d.DetalleId asc
FOR XML PATH('')), 1, 1, '')),'~')
end
GO

IF OBJECT_ID(N'dbo.listaDetalleNota', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaDetalleNota] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaDetalleNota]
@Data varchar(max)
as
begin
DECLARE @NotaId numeric(20),
        @Estado varchar(80)
DECLARE @p1 int,@p2 int
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = Len(@Data)+1
Set @NotaId=convert(numeric(20),SUBSTRING(@Data,1,@p1-1))
Set @Estado=SUBSTRING(@Data,@p1+1,@p2-@p1-1)
select
'DetalleId|NotaId|IdProducto|Cantidad|UMedida|Descripcion|PrecioCosto|PrecioUni|Importe|Estado|ValorUM|PrecioSunat|IGVPrecio|ImporteSunat|PV|SV|Codigo|CodigoSunat|Linea¬100|100|100|100|100|487|100|115|120|100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,d.DetalleId)+'|'+convert(varchar,d.NotaId)+'|'+convert(varchar,d.IdProducto)+'|'+
convert(varchar(50),cast(d.DetalleCantidad as money),1)+'|'+d.DetalleUm+'|'+d.DetalleDescripcion+'|'+convert(varchar,d.DetalleCosto)+'|'+
convert(varchar(50),cast(d.DetallePrecio as money),1)+'|'+convert(varchar(50),cast(d.DetalleImporte as money),1)+'|'+
d.DetalleEstado+'|'+CONVERT(varchar,d.ValorUM)+'|'+

convert(varchar,convert(decimal(18,6),d.DetallePrecio/1.18))+'|'+
convert(varchar,(convert(decimal(18,6),d.DetallePrecio/1.18)* d.DetalleCantidad)*0.18)+'|'+
convert(varchar,convert(decimal(18,6),d.DetallePrecio/1.18)* d.DetalleCantidad) +'|'+

convert(varchar(50),CAST(d.DetalleCantidad *p.ProductoPV as money),1)+'|'+
convert(varchar(50),CAST(d.DetalleCantidad *p.ProductoSV as money),1)+'|'+
p.ProductoCodigo+'|'+s.CodigoSunat+'|'+s.NombreSublinea
from DetallePedido d
inner join Producto p
on p.IdProducto=d.IdProducto
inner join Sublinea s
on s.IdSubLinea=p.IdSubLinea
where d.NotaId=@NotaId and d.DetalleEstado=@Estado
order by d.DetalleId asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.listaDetalleNotaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaDetalleNotaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaDetalleNotaB]
@NotaId numeric(38)
as
begin
Declare @CountP int
declare @Estado varchar(80)
set @Estado=(select top 1 n.NotaEstado from NotaPedido n where n.NotaId=@NotaId)
set @CountP=isnull((select COUNT(*) from DetallesPVS where NotaId=@NotaId),0)
select
'DetalleId|NotaId|IdProducto|Codigo|Cantidad|UM|Descripcion|PrecioCosto|PrecioUni|PV|SV|Importe|Imagen|ValorUM|PrecioSunat|IGVPrecio|ImporteSunat|PVUNI|SVUNI|Linea|AplicaFB¬100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select stuff((select '¬'+convert(varchar,d.DetalleId)+'|'+convert(varchar,d.NotaId)+'|'+
convert(varchar,d.IdProducto)+'|'+p.ProductoCodigo+'|'+
CONVERT(VarChar(50), cast(d.DetalleCantidad as money ), 1)+'|'+
d.DetalleUm+'|'+d.DetalleDescripcion+'|'+
case when @Estado='PENDIENTE' then 
CONVERT(VarChar(50), cast((p.ProductoCosto * d.ValorUm) as money ), 1)
else
CONVERT(VarChar(50), cast(d.DetalleCosto as money ), 1)
end+'|'+
CONVERT(VarChar(50), cast(d.DetallePrecio as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetallePV as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleSV as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleImporte as money ), 1)+'|'+
p.ProductoImagen+'|'+CONVERT(varchar,d.ValorUM)+'|'+
convert(varchar,convert(decimal(18,2),d.DetallePrecio/1.18))+'|'+
convert(varchar,(d.DetalleImporte - convert(decimal(18,2),d.DetalleImporte/1.18)))+'|'+
convert(varchar,convert(decimal(18,2),d.DetalleImporte/1.18))+'|'+
convert(varchar,p.ProductoPV)+'|'+convert(varchar,p.ProductoSV)+'|'+
s.NombreSublinea+'|'+p.AplicaFB
from DetallePedido d
inner join Producto p
on p.IdProducto=d.IdProducto
inner join Sublinea s
on s.IdSubLinea=p.IdSubLinea
where d.NotaId=@NotaId
order by d.DetalleId asc
FOR XML PATH('')), 1, 1, '')),'~')+'['+
isnull((select STUFF((select '¬'+ convert(varchar,r.GuiaId)+'|'+g.GuiaNumero
from GuiaRelacion r
inner join GuiaRemision g
on g.GuiaId=r.GuiaId
where r.NotaId=@NotaId
order by r.DetalleId asc
FOR XML PATH('')), 1, 1, '')),'~')+'['+convert(varchar,@CountP)
end
GO

IF OBJECT_ID(N'dbo.listaDocuCompania', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaDocuCompania] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaDocuCompania]      
@CompaniaId int,      
@fechainicio date,      
@fechafin date      
as      
begin      
select d.DocuId,d.CompaniaId,d.NotaId,d.DocuDocumento,d.docuSerie+'-'+d.DocuNumero as DocuNumero,c.ClienteCodigo as Codigo,      
c.ClienteRazon,c.ClienteRuc,c.ClienteDni,c.ClienteDireccion,d.DocuNumero as Numero,      
(Convert(char(10),d.DocuEmision,103))as FechaEmision,d.DocuCondicion as DocuCondicion,      
d.DocuSerie as Serie,(Convert(char(10),d.DocuRegistro,103)) as FechaPago,d.DocuTransaccion,      
d.DocuLetras,(convert(varchar(50), CAST(d.DocuSubTotal as money), -1))as DocuSubTotal,      
(convert(varchar(50), CAST(d.DocuIgv as money), -1)) as DocuIgv,      
(convert(varchar(50), CAST(d.ICBPER as money), -1)) as ICBPER,      
(convert(varchar(50), CAST(d.DocuTotal as money), -1))as DocuTotal,d.DocuUsuario,      
d.DocuEstado as DocuEstado,co.CompaniaRazonSocial as compania,d.DocuOperacion,      
d.EstadoSunat as Estado,      
(convert(varchar(50), CAST(d.DocuAdicional as money), -1)) as MDC,      
d.DocuHash,co.CompaniaRUC,c.ClienteCorreo,      
c.ClienteId,(convert(varchar(50), CAST(d.DocuSaldo as money), -1)) as GRAVADA,      
d.FormaPago,d.EntidadBancaria,d.NroOperacion,      
(convert(varchar(50), CAST(d.Efectivo as money), -1)) as Efectivo,      
(convert(varchar(50), CAST(d.Deposito as money), -1)) as Deposito,    
SUBSTRING(convert(varchar,d.DocuRegistro,114),1,8) as Hora,        
case when n.NotaDescuento>0 then        
(convert(varchar(50), CAST(n.NotaDescuento/1.18 as money), -1))        
else '0.00' end as Descuento,d.DocuNroGuia      
from DocumentoVenta d            
inner join Compania co            
on co.CompaniaId=d.CompaniaId        
inner join NotaPedido n        
on n.NotaId=d.NotaId        
inner join Cliente c            
on c.ClienteId=d.ClienteId    
where d.CompaniaId=@CompaniaId and(Convert(char(10),d.DocuEmision,101) BETWEEN @fechainicio AND @fechafin)      
order by d.DocuId desc      
end
GO

IF OBJECT_ID(N'dbo.listaDocumentos', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaDocumentos] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaDocumentos]      
as      
begin      
select d.DocuId,d.CompaniaId,d.NotaId,d.DocuDocumento,d.docuSerie+'-'+d.DocuNumero as DocuNumero,c.ClienteCodigo as Codigo,      
c.ClienteRazon,c.ClienteRuc,c.ClienteDni,c.ClienteDireccion,d.DocuNumero as Numero,      
(Convert(char(10),d.DocuEmision,103))as FechaEmision,d.DocuCondicion as DocuCondicion,      
d.DocuSerie as Serie,(Convert(char(10),d.DocuRegistro,103)) as FechaPago,d.DocuTransaccion,      
d.DocuLetras,(convert(varchar(50), CAST(d.DocuSubTotal as money), -1))as DocuSubTotal,      
(convert(varchar(50), CAST(d.DocuIgv as money), -1)) as DocuIgv,      
(convert(varchar(50), CAST(d.ICBPER as money), -1)) as ICBPER,      
(convert(varchar(50), CAST(d.DocuTotal as money), -1))as DocuTotal,d.DocuUsuario,      
d.DocuEstado as DocuEstado,co.CompaniaRazonSocial as compania,d.DocuOperacion,      
d.EstadoSunat as Estado,      
(convert(varchar(50), CAST(d.DocuAdicional as money), -1)) as MDC,      
d.DocuHash,co.CompaniaRUC,c.ClienteCorreo,      
c.ClienteId,(convert(varchar(50), CAST(d.DocuSaldo as money), -1)) as GRAVADA,      
d.FormaPago,d.EntidadBancaria,d.NroOperacion,      
(convert(varchar(50), CAST(d.Efectivo as money), -1)) as Efectivo,      
(convert(varchar(50), CAST(d.Deposito as money), -1)) as Deposito,    
SUBSTRING(convert(varchar,d.DocuRegistro,114),1,8) as Hora,        
case when n.NotaDescuento>0 then        
(convert(varchar(50), CAST(n.NotaDescuento/1.18 as money), -1))        
else '0.00' end as Descuento,d.DocuNroGuia      
from DocumentoVenta d            
inner join Compania co            
on co.CompaniaId=d.CompaniaId        
inner join NotaPedido n        
on n.NotaId=d.NotaId        
inner join Cliente c            
on c.ClienteId=d.ClienteId       
where Month(d.DocuEmision)=Month(GETDATE())and year(d.DocuEmision)=YEAR(Getdate())      
order by d.DocuId desc      
end
GO

IF OBJECT_ID(N'dbo.listaGeneralFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaGeneralFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaGeneralFecha] 
@fechainicio date,@fechafin date
as
begin 
select
isnull((select STUFF ((select '¬'+ CONVERT(varchar,c.IdGeneral)+'|'+
(IsNull(convert(varchar,c.FechaCierre,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,c.FechaCierre,114),1,8),''))+'|'+c.Usuario+'|'+
CONVERT(varchar(50),cast(c.Ingresos as money),1)+'|'+CONVERT(varchar(50),cast(c.Salidas as money),1)+'|'+
CONVERT(varchar(50),cast(c.Total as money),1)
from CajaGeneral c
where (Convert(char(10),c.FechaCierre,101) BETWEEN @fechainicio AND @fechafin) 
order by c.IdGeneral desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.listaLiquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaLiquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaLiquida]
as
begin
select l.LiquidacionId,l.LiquidacionNumero,l.LiquidacionRegistro,
(Convert(char(10),l.LiquidacionFecha,103))as LiquidacionFecha,
l.LiquidacionDescripcion,l.LiquidacionCambio,
CONVERT(VarChar(50), cast(l.LiquidaEfectivoSol as money ), 1)as LiquidaEfectivoSol,
CONVERT(VarChar(50), cast(l.LiquidaDepositoSol as money ), 1)as LiquidaDepositoSol,
CONVERT(VarChar(50), cast(l.LiquidaEfectivoDol as money ), 1)as LiquidaEfectivoDol,
CONVERT(VarChar(50), cast(l.LiquidaDepositoDol as money ), 1)as LiquidaDepositoDol,
CONVERT(VarChar(50), cast(l.LiquidaTotalDol as money ), 1)as LiquidaTotalDol,
CONVERT(VarChar(50), cast(l.LiquidaTotalSol as money ), 1)as LiquidaTotalSol,
l.LiquidaUsuario
from Liquidacion l
where(month(l.LiquidacionFecha)=MONTH(GETDATE()) and YEAR(l.LiquidacionFecha)=YEAR(GETDATE()))
order by 1 desc
end
GO

IF OBJECT_ID(N'dbo.listaliquidafecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaliquidafecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaliquidafecha] @fechainicio date,@fechafin date
as
begin
select l.LiquidacionId,LiquidacionNumero,l.LiquidacionRegistro,
(Convert(char(10),l.LiquidacionFecha,103))as LiquidacionFecha,
l.LiquidacionDescripcion,l.LiquidacionCambio,
CONVERT(VarChar(50), cast(l.LiquidaEfectivoSol as money ), 1)as LiquidaEfectivoSol,
CONVERT(VarChar(50), cast(l.LiquidaDepositoSol as money ), 1)as LiquidaDepositoSol,
CONVERT(VarChar(50), cast(l.LiquidaEfectivoDol as money ), 1)as LiquidaEfectivoDol,
CONVERT(VarChar(50), cast(l.LiquidaDepositoDol as money ), 1)as LiquidaDepositoDol,
CONVERT(VarChar(50), cast(l.LiquidaTotalDol as money ), 1)as LiquidaTotalDol,
CONVERT(VarChar(50), cast(l.LiquidaTotalSol as money ), 1)as LiquidaTotalSol,
l.LiquidaUsuario
from Liquidacion l
where (Convert(char(10),l.LiquidacionFecha,103) BETWEEN @fechainicio AND @fechafin)
order by 1 desc
end
GO

IF OBJECT_ID(N'dbo.listaliquidafechaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaliquidafechaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaliquidafechaB] 
@fechainicio date,
@fechafin date
as
begin
select l.LiquidacionId,LiquidacionNumero,l.LiquidacionRegistro,
(Convert(char(10),l.LiquidacionFecha,103))as LiquidacionFecha,
l.LiquidacionDescripcion,l.LiquidacionCambio,
CONVERT(VarChar(50), cast(l.LiquidaEfectivoSol as money ), 1)as LiquidaEfectivoSol,
CONVERT(VarChar(50), cast(l.LiquidaDepositoSol as money ), 1)as LiquidaDepositoSol,
CONVERT(VarChar(50), cast(l.LiquidaEfectivoDol as money ), 1)as LiquidaEfectivoDol,
CONVERT(VarChar(50), cast(l.LiquidaDepositoDol as money ), 1)as LiquidaDepositoDol,
CONVERT(VarChar(50), cast(l.LiquidaTotalDol as money ), 1)as LiquidaTotalDol,
CONVERT(VarChar(50), cast(l.LiquidaTotalSol as money ), 1)as LiquidaTotalSol,
l.LiquidaUsuario,l.EntidadBancaria,l.NroOperacion,l.FormaPago
from LiquidacionVenta l
where (Convert(char(10),l.LiquidacionFecha,101) BETWEEN @fechainicio AND @fechafin)
order by 1 desc
end
GO

IF OBJECT_ID(N'dbo.listaLiquidaVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaLiquidaVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaLiquidaVenta]
as
begin
select l.LiquidacionId,l.LiquidacionNumero,l.LiquidacionRegistro,
(Convert(char(10),l.LiquidacionFecha,103))as LiquidacionFecha,
l.LiquidacionDescripcion,l.LiquidacionCambio,
CONVERT(VarChar(50), cast(l.LiquidaEfectivoSol as money ), 1)as LiquidaEfectivoSol,
CONVERT(VarChar(50), cast(l.LiquidaDepositoSol as money ), 1)as LiquidaDepositoSol,
CONVERT(VarChar(50), cast(l.LiquidaEfectivoDol as money ), 1)as LiquidaEfectivoDol,
CONVERT(VarChar(50), cast(l.LiquidaDepositoDol as money ), 1)as LiquidaDepositoDol,
CONVERT(VarChar(50), cast(l.LiquidaTotalDol as money ), 1)as LiquidaTotalDol,
CONVERT(VarChar(50), cast(l.LiquidaTotalSol as money ), 1)as LiquidaTotalSol,
l.LiquidaUsuario,l.EntidadBancaria,l.NroOperacion,l.FormaPago
from LiquidacionVenta l
where(month(l.LiquidacionFecha)=MONTH(GETDATE()) and YEAR(l.LiquidacionFecha)=YEAR(GETDATE()))
order by 1 desc
end
GO

IF OBJECT_ID(N'dbo.listaNotaComC', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaNotaComC] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaNotaComC] @f1 date,@f2 date
as
begin
select c.CompraId,c.CompraCorrelativo,c.CompaniaId,c.CompraRegistro,Convert(char(10),c.CompraComputo,103)as CompraComputo,Convert(char(10),c.CompraEmision,103)as CompraEmision,p.ProveedorRazon,
p.ProveedorRuc,c.TipoCodigo,c.CompraSerie,c.CompraNumero,c.CompraCondicion,c.CompraMoneda,CompraTipoCambio,c.CompraDias,Convert(char(10),c.CompraFechaPago,103) as CompraFechaPago,
c.CompraTipoIgv,CONVERT(VarChar(50), cast(c.CompraValorVenta as money ), 1) as ValorVenta,CONVERT(VarChar(50), cast(c.CompraDescuento as money ), 1)as Descuento,CONVERT(VarChar(50), 
cast(c.CompraSubtotal as money ), 1) as Subtotal,CONVERT(VarChar(50), cast(c.CompraIgv as money ), 1) as Igv,CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1) as Total,
CONVERT(VarChar(50), cast(c.compraSaldo as money ), 1) as CompraSaldo,c.CompraUsuario,co.CompaniaRazonSocial,
c.CompraEstado,c.ProveedorId,t.TipoDescripcion,c.CompraAsociado as Asociado,CompraOBS,CompraTipoSunat as TipoSunat
from Compras c
inner join Proveedor p
on p.ProveedorId=c.ProveedorId
inner join Compania co
on co.CompaniaId=c.CompaniaId
inner join TipoComprobante t
on t.TipoCodigo=c.TipoCodigo
where (c.TipoCodigo='07' or c.TipoCodigo='101') and(Convert(char(10),c.CompraComputo, 103) BETWEEN @f1 AND @f2)
order by c.CompraId desc
end
GO

IF OBJECT_ID(N'dbo.listaNotaComE', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaNotaComE] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaNotaComE] @f1 date,@f2 date
as
begin
select c.CompraId,c.CompraCorrelativo,c.CompaniaId,c.CompraRegistro,Convert(char(10),c.CompraComputo,103)as CompraComputo,Convert(char(10),c.CompraEmision,103)as CompraEmision,p.ProveedorRazon,
p.ProveedorRuc,c.TipoCodigo,c.CompraSerie,c.CompraNumero,c.CompraCondicion,c.CompraMoneda,CompraTipoCambio,c.CompraDias,Convert(char(10),c.CompraFechaPago,103) as CompraFechaPago,
c.CompraTipoIgv,CONVERT(VarChar(50), cast(c.CompraValorVenta as money ), 1) as ValorVenta,CONVERT(VarChar(50), cast(c.CompraDescuento as money ), 1)as Descuento,CONVERT(VarChar(50), 
cast(c.CompraSubtotal as money ), 1) as Subtotal,CONVERT(VarChar(50), cast(c.CompraIgv as money ), 1) as Igv,CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1) as Total,
CONVERT(VarChar(50), cast(c.compraSaldo as money ), 1) as CompraSaldo,c.CompraUsuario,co.CompaniaRazonSocial,
c.CompraEstado,c.ProveedorId,t.TipoDescripcion,c.CompraAsociado as Asociado,CompraOBS,CompraTipoSunat as TipoSunat
from Compras c
inner join Proveedor p
on p.ProveedorId=c.ProveedorId
inner join Compania co
on co.CompaniaId=c.CompaniaId
inner join TipoComprobante t
on t.TipoCodigo=c.TipoCodigo
where (c.TipoCodigo='07' or c.TipoCodigo='101') and(Convert(char(10),c.CompraEmision,103) BETWEEN @f1 AND @f2)
order by c.CompraId desc
end
GO

IF OBJECT_ID(N'dbo.listaNotaCompra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaNotaCompra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaNotaCompra] 
as
begin
select c.CompraId,c.CompraCorrelativo,c.CompaniaId,c.CompraRegistro,Convert(char(10),c.CompraComputo,103)as CompraComputo,Convert(char(10),c.CompraEmision,103)as CompraEmision,p.ProveedorRazon,
p.ProveedorRuc,c.TipoCodigo,c.CompraSerie,c.CompraNumero,c.CompraCondicion,c.CompraMoneda,CompraTipoCambio,c.CompraDias,Convert(char(10),c.CompraFechaPago,103) as CompraFechaPago,
c.CompraTipoIgv,CONVERT(VarChar(50), cast(c.CompraValorVenta as money ), 1) as ValorVenta,CONVERT(VarChar(50), cast(c.CompraDescuento as money ), 1)as Descuento,CONVERT(VarChar(50), 
cast(c.CompraSubtotal as money ), 1) as Subtotal,CONVERT(VarChar(50), cast(c.CompraIgv as money ), 1) as Igv,CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1) as Total,
CONVERT(VarChar(50), cast(c.compraSaldo as money ), 1) as CompraSaldo,c.CompraUsuario,co.CompaniaRazonSocial,
c.CompraEstado,c.ProveedorId,t.TipoDescripcion,c.CompraAsociado as Asociado,CompraOBS,CompraTipoSunat as TipoSunat
from Compras c
inner join Proveedor p
on p.ProveedorId=c.ProveedorId
inner join Compania co
on co.CompaniaId=c.CompaniaId
inner join TipoComprobante t
on t.TipoCodigo=c.TipoCodigo
where (c.TipoCodigo='07' or c.TipoCodigo='101')and(Month(c.CompraComputo)=Month(GETDATE()) and year(c.CompraComputo)=year(GETDATE()))
order by c.CompraId desc
end
GO

IF OBJECT_ID(N'dbo.listaPedidosFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaPedidosFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaPedidosFecha]  
@fechainicio date,  
@fechafin date  
as  
begin  
select n.NotaId,n.NotaDocu,  
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),'')) as NotaFecha,  
n.ClienteId,c.ClienteCodigo as Codigo,c.ClienteRazon,c.ClienteRuc,c.ClienteDni,  
n.NotaCondicion,n.NotaFormaPago,(Convert(char(10),n.NotaFechaPago,103))as NotaFechaPago,  
CONVERT(VarChar(50), cast(n.NotaPagar as money ), 1)as TotalPagar,  
CONVERT(VarChar(50), cast(n.NotaSaldo as money ), 1)as SaldoDocumento,  
CONVERT(VarChar(50), cast(n.NotaAcuenta as money ), 1)as NotaAcuenta,  
CONVERT(VarChar(50), cast(n.NotaSubtotal as money ), 1)as NotaSubtotal,  
CONVERT(VarChar(50), cast(n.NotaTotal as money ), 1)as OpGravada,  
CONVERT(VarChar(50), cast(n.NotaAdicional as money ), 1)as NotaAdicional,  
CONVERT(VarChar(50), cast(n.NotaTarjeta as money ), 1)as TotalTarjeta,  
n.NotaUsuario,n.NotaEstado,co.CompaniaRazonSocial as compania,  
c.ClienteDireccion as Direccion,n.NotaEntrega as Entrega,n.ModificadoPor,  
n.FechaEdita,n.NotaConcepto,n.NotaSerie,n.NotaNumero,n.NotaTransaccion,  
CONVERT(VarChar(50), cast(n.NotaDescuento as money ), 1)as Descuento,  
n.ConceptoOBS,n.CodigoRes,n.Responsable,EntidadBancaria as Entidad,  
CONVERT(VarChar(50), cast(n.Efectivo as money ), 1) as Efectivo,  
CONVERT(VarChar(50), cast(n.Deposito as money ), 1) as Deposito,  
n.NroOperacion,n.Entrega as Despacho,
(IsNull(convert(varchar,n.Hora,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.Hora,114),1,8),'')) as Hora,
n.Almacen  
from NotaPedido n with(nolock)     
inner join Cliente c  
on c.ClienteId=n.ClienteId  
inner join Compania co  
on co.CompaniaId=n.CompaniaId  
where (Convert(char(10),n.NotaFecha,101) BETWEEN @fechainicio AND @fechafin)  
order by n.NotaId desc  
end
GO

IF OBJECT_ID(N'dbo.listaProveedor', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaProveedor] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaProveedor]
 as
 begin
 select
 'Codigo|RazonSocial|RUC|Contacto|Celular|Telefono|Correo|Direccion|Estado¬90|400|105|200|150|150|150|250|100¬String|String|String|String|String|String|String|String|String¬'+
 isnull((select stuff((SELECT '¬'+ CONVERT(varchar,p.ProveedorId)+'|'+p.ProveedorRazon+'|'+p.ProveedorRuc+'|'+
 p.ProveedorContacto+'|'+p.ProveedorCelular+'|'+p.ProveedorTelefono+'|'+p.ProveedorCorreo+'|'+
 p.ProveedorDireccion+'|'+p.ProveedorEstado
 from Proveedor p
 order by p.ProveedorId desc
 for xml path('')),1,1,'')),'~')
 end
GO

IF OBJECT_ID(N'dbo.listarCaja', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarCaja] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarCaja]
as
begin
select c.CajaId,c.CajaFecha,c.CajaCierre,
CONVERT(VarChar(50), cast(c.MontoIniSOl as money ), 1)as MontoIniSol,
CONVERT(VarChar(50), cast(c.CajaIngresos as money ), 1)as CajaIngresos,
CONVERT(VarChar(50), cast(c.CajaDeposito as money ), 1)as CajaDeposito,
CONVERT(VarChar(50), cast(c.CajaSalidas as money ), 1)as  CajaSalidas,
CONVERT(VarChar(50), cast(c.CajaTotal as money ), 1)as  CajaTotal,
c.CajaEncargado,c.CajaUsuario,c.CajaEstado,c.Observacion
from Caja c
where Month(c.CajaFecha)=Month(GETDATE()) and year(c.CajaFecha)=year(GETDATE())
order by 2 desc
end
GO

IF OBJECT_ID(N'dbo.listarCajaFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarCajaFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarCajaFecha] 
@fechainicio date,
@fechafin date
as
begin
select c.CajaId,c.CajaFecha,c.CajaCierre,
CONVERT(VarChar(50), cast(c.MontoIniSOl as money ), 1)as MontoIniSol,
CONVERT(VarChar(50), cast(c.CajaIngresos as money ), 1)as CajaIngresos,
CONVERT(VarChar(50), cast(c.CajaDeposito as money ), 1)as CajaDeposito,
CONVERT(VarChar(50), cast(c.CajaSalidas as money ), 1)as  CajaSalidas,
CONVERT(VarChar(50), cast(c.CajaTotal as money ), 1)as  CajaTotal,
c.CajaEncargado,c.CajaUsuario,c.CajaEstado,c.Observacion
from Caja c
where (Convert(char(10),c.CajaFecha,101) BETWEEN @fechainicio AND @fechafin)
order by 2 desc
end
GO

IF OBJECT_ID(N'dbo.listarClienteB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarClienteB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarClienteB]    
as    
begin    
select    
'ClienteId|Codigo|RazonSocial|RUC|DNI|Direccion|Telefono|Correo|Fecha|Usuario|Direc|Documento¬90|90|90|95|90|90|90|90|90|90|90|90¬String|String|String|String|String|String|String|String|String|String|String|String|String¬'+    
isnull((select stuff((SELECT '¬'+ convert(varchar,c.ClienteId)+'|'+c.ClienteCodigo    
+'|'+c.ClienteRazon+'|'+isnull(c.ClienteRuc,'')+'|'+    
isnull(c.ClienteDni,'')+'|'+isnull(c.ClienteDespacho,'')+'|'+    
isnull(c.ClienteTelefono,'')+'|'+isnull(c.ClienteCorreo,'')+'|'+    
(IsNull(convert(varchar,c.clienteFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,c.clienteFecha,114),1,8),''))+'|'+    
convert(varchar,c.ClienteUsuario)+'|'+isnull(c.ClienteDireccion,'')+'|'+c.ClienteDocu    
FROM Cliente c  
where c.ClienteEstado='ACTIVO'  
order by c.ClienteId desc    
for xml path('')),1,1,'')),'~')    
end
GO

IF OBJECT_ID(N'dbo.listarCompras', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarCompras] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarCompras] 
as
begin
select c.CompraId,c.CompraCorrelativo,c.CompaniaId,c.CompraRegistro,Convert(char(10),c.CompraComputo,103)as CompraComputo,Convert(char(10),c.CompraEmision,103)as CompraEmision,p.ProveedorRazon,
p.ProveedorRuc,c.TipoCodigo,c.CompraSerie,c.CompraNumero,c.CompraCondicion,c.CompraMoneda,CompraTipoCambio,c.CompraDias,Convert(char(10),c.CompraFechaPago,103) as CompraFechaPago,
c.CompraTipoIgv,CONVERT(VarChar(50), cast(c.CompraValorVenta as money ), 1) as ValorVenta,CONVERT(VarChar(50), cast(c.CompraDescuento as money ), 1)as Descuento,CONVERT(VarChar(50), 
cast(c.CompraSubtotal as money ), 1) as Subtotal,CONVERT(VarChar(50), cast(c.CompraIgv as money ), 1) as Igv,CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1) as Total,
CONVERT(VarChar(50), cast(c.compraSaldo as money ), 1) as CompraSaldo,c.CompraUsuario,co.CompaniaRazonSocial,
c.CompraEstado,c.ProveedorId,t.TipoDescripcion,c.CompraAsociado as Asociado,CompraOBS,CompraTipoSunat as TipoSunat,CompraConcepto as Concepto
from Compras c
inner join Proveedor p
on p.ProveedorId=c.ProveedorId
inner join Compania co
on co.CompaniaId=c.CompaniaId
inner join TipoComprobante t
on t.TipoCodigo=c.TipoCodigo
where (c.TipoCodigo<>'07' and c.TipoCodigo<>'101') and
(Month(c.CompraComputo)=Month(GETDATE()) and 
year(c.CompraComputo)=year(GETDATE()))
order by c.CompraId desc
end
GO

IF OBJECT_ID(N'dbo.listarDetaCaja', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarDetaCaja] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarDetaCaja]
@CajaId numeric(38)
as
begin
select
'Id|CajaId|Fecha|NroNota|Movimiento|Concepto|Efectivo|Monto|Vuelto|DetalleEfectivo|Entrega¬80|100|145|85|100|100|95|95|95|100|118¬String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select stuff((select '¬'+
convert(varchar,d.DetalleId)+'|'+convert(varchar,d.CajaId)+'|'+
(IsNull(convert(varchar,d.DetalleFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,d.DetalleFecha,114),1,8),''))+'|'+
convert(varchar,d.NotaId)+'|'+d.DetalleMovimiento+'|'+d.DetalleConcepto+'|'+
CONVERT(VarChar(50), cast(d.DetalleEfectivo as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleMonto as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleVuelto as money ), 1)+'|'+
convert(varchar,d.DetalleEfectivo)+'|'+ISNULL(n.NotaEntrega,'INMEDIATA')
from CajaDetalle d
left join NotaPedido n
on n.NotaId=d.NotaId
where d.CajaId=@CajaId and d.Vista=''
order by d.DetalleId desc
for xml path('')),1,1,'')),'~')+'['+ 
'Codigo|Descripcion|Cantidad|UM|PVTotal|SVTotal|Importe¬110|370|105|90|105|105|105¬String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+p.ProductoCodigo+'|'+
d.DetalleDescripcion+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetalleCantidad) as money ), 1)+'|'+d.DetalleUm+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetallePV) as money ), 1)+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetalleSV) as money ), 1)+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetalleImporte) as money ), 1)
from NotaPedido n
inner join DetallePedido d
on d.NotaId=n.NotaId
inner join Producto p
on p.IdProducto=d.IdProducto
where CajaId=@CajaId and(n.NotaEstado='CANCELADO' and n.NotaConcepto='MERCADERIA') 
group by p.ProductoCodigo,d.DetalleDescripcion,d.DetalleUm
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.listarDetaLetra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarDetaLetra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarDetaLetra] @LetraId numeric(38)
as
begin
select d.DetalleId,d.LetraId,d.LetraCanje,d.LetraDias,(Convert(char(10),d.LetraVencimiento,103)) as Vencimeinto,
CONVERT(VarChar(50), cast(d.DetalleSaldo as money ), 1) as SaldoLetra,
CONVERT(VarChar(50), cast(d.DetalleMonto as money ), 1) as DetalleMonto,d.DetalleEstado
from DetalleLetra d
where d.LetraId=@LetraId 
order by 1 asc
end
GO

IF OBJECT_ID(N'dbo.listarDetaliquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarDetaliquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarDetaliquida] @LiquidacionId numeric(38)
as
begin
select d.DetalleId,d.LiquidacionId,d.CompraId,d.Numero as Numero,
d.Proveedor,CONVERT(VarChar(50), cast(d.SaldoDocu as money ), 1) as Saldo,d.Moneda,d.EfectivoSoles,
d.EfectivoDolar,d.DepositoSoles,d.DepositoDolar,d.TipoCambio,d.EntidadBanco,d.NroOperacion,
CONVERT(VarChar(50), cast(d.AcuentaGeneral as money ), 1) as Acuenta,
d.FechaPago,CONVERT(VarChar(50), cast(d.SaldoActual as money ), 1)as SaldoActual,d.Concepto
from DetalleLiquida d
where d.LiquidacionId=@LiquidacionId
order by 1 asc
end
GO

IF OBJECT_ID(N'dbo.listarKardex', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarKardex] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarKardex] 
@IdProducto numeric(20)
as
begin
	select 
	'KardexId|IdProducto|FechaMovimiento|Cliente|Codigo|Transaccion|Motivo|Documento|StockInicial|CantidadIngre|CantidadSali|PrecioCosto|StockFinal|Concepto|Responsable¬100|100|145|250|100|200|150|145|115|115|115|115|115|100|160¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
	isnull((select STUFF ((select '¬'+convert(varchar,k.KardexId)+'|'+CONVERT(varchar,k.IdProducto)+'|'+
	(IsNull(convert(varchar,k.KardexFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,k.KardexFecha,114),1,8),''))+'|'+
	k.CLIENTE+'|'+k.CODIGOCLIENTE+'|'+k.NROTRANSAC+'|'+k.KardexMotivo+'|'+k.KardexDocumento+'|'+
	CONVERT(VarChar(50), cast(k.StockInicial as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(k.CantidadIngreso as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(k.CantidadSalida as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(k.PrecioCosto as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(k.StockFinal as money ), 1)+'|'+
	K.KadexConcepto+'|'+k.Usuario
	from Kardex k with(nolock)
	where k.IdProducto=@IdProducto and k.Consideracion='S'
	 and (Month(k.KardexFecha)=Month(GETDATE()) and YEAR(k.kardexFecha)=year(getdate()))
	order by k.KardexId desc
	for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.listarKardexFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarKardexFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarKardexFecha]
@Id numeric(20),
@fechainicio date,
@fechafin date
as
begin
select 
	'KardexId|IdProducto|FechaMovimiento|Cliente|Codigo|Transaccion|Motivo|Documento|StockInicial|CantidadIngre|CantidadSali|PrecioCosto|StockFinal|Concepto|Responsable¬100|100|145|250|100|200|150|145|115|115|115|115|115|100|160¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
	isnull((select STUFF ((select '¬'+convert(varchar,k.KardexId)+'|'+CONVERT(varchar,k.IdProducto)+'|'+
	(IsNull(convert(varchar,k.KardexFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,k.KardexFecha,114),1,8),''))+'|'+
	k.CLIENTE+'|'+k.CODIGOCLIENTE+'|'+k.NROTRANSAC+'|'+k.KardexMotivo+'|'+k.KardexDocumento+'|'+
	CONVERT(VarChar(50), cast(k.StockInicial as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(k.CantidadIngreso as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(k.CantidadSalida as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(k.PrecioCosto as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(k.StockFinal as money ), 1)+'|'+
	K.KadexConcepto+'|'+k.Usuario
	from Kardex k with(nolock)
	where k.IdProducto=@Id and k.Consideracion='S' and 
	(Convert(char(10),k.KardexFecha,101) BETWEEN @fechainicio AND @fechafin)
	order by k.KardexId desc
    for xml path('')),1,1,'')),'~')
order by 1 desc
end
GO

IF OBJECT_ID(N'dbo.listarLetraFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarLetraFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarLetraFecha] @fechainicio date,@fechafin date
as
begin
select l.LetraId, l.ProveedorId,p.ProveedorRazon,l.LetraFechaReg,(Convert(char(10),l.LetraFechaGiro,103)) as FechaGiro,
l.LetraMoneda as Moneda,CONVERT(VarChar(50), cast(l.LetraSaldo as money ), 1)as SaldoLetras,CONVERT(VarChar(50), cast(l.LetraTotal as money ), 1)as TotalLetras,l.LetraUsuario,l.LetraEstado as Estado
from Letra l
inner join Proveedor p
on p.ProveedorId=l.ProveedorId
where (Convert(char(10),l.LetraFechaGiro,103) BETWEEN @fechainicio AND @fechafin)
order by 1 desc
end
GO

IF OBJECT_ID(N'dbo.listarLetras', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarLetras] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarLetras]
as
begin
select l.LetraId, l.ProveedorId,p.ProveedorRazon,l.LetraFechaReg,(Convert(char(10),l.LetraFechaGiro,103)) as FechaGiro,l.LetraMoneda as Moneda,
CONVERT(VarChar(50), cast(l.LetraSaldo as money ), 1)as SaldoLetras,CONVERT(VarChar(50), cast(l.LetraTotal as money ), 1)as TotalLetras,
l.LetraUsuario,l.LetraEstado as Estado,l.CompaniaId
from Letra l
inner join Proveedor p
on p.ProveedorId=l.ProveedorId
where year(LetraFechaGiro)=YEAR(GETDATE())
order by 1 desc
end
GO

IF OBJECT_ID(N'dbo.listarPedidos', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarPedidos] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarPedidos]  
as  
begin  
(select n.NotaId,n.NotaDocu,  
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),'')) as NotaFecha,  
n.ClienteId,c.ClienteCodigo as Codigo,c.ClienteRazon,c.ClienteRuc,c.ClienteDni,  
n.NotaCondicion,n.NotaFormaPago,(Convert(char(10),n.NotaFechaPago,103))as NotaFechaPago,  
CONVERT(VarChar(50), cast(n.NotaPagar as money ), 1)as TotalPagar,  
CONVERT(VarChar(50), cast(n.NotaSaldo as money ), 1)as SaldoDocumento,  
CONVERT(VarChar(50), cast(n.NotaAcuenta as money ), 1)as NotaAcuenta,  
CONVERT(VarChar(50), cast(n.NotaSubtotal as money ), 1)as NotaSubtotal,  
CONVERT(VarChar(50), cast(n.NotaTotal as money ), 1)as OpGravada,  
CONVERT(VarChar(50), cast(n.NotaAdicional as money ), 1)as NotaAdicional,  
CONVERT(VarChar(50), cast(n.NotaTarjeta as money ), 1)as TotalTarjeta,  
n.NotaUsuario,n.NotaEstado,co.CompaniaRazonSocial as compania,  
c.ClienteDireccion as Direccion,n.NotaEntrega as Entrega,n.ModificadoPor,  
n.FechaEdita,n.NotaConcepto,n.NotaSerie,n.NotaNumero,n.NotaTransaccion,  
CONVERT(VarChar(50), cast(n.NotaDescuento as money ), 1)as Descuento,  
n.ConceptoOBS,n.CodigoRes,n.Responsable,EntidadBancaria as Entidad,  
CONVERT(VarChar(50), cast(n.Efectivo as money ), 1) as Efectivo,  
CONVERT(VarChar(50), cast(n.Deposito as money ), 1) as Deposito,  
n.NroOperacion,n.Entrega as Despacho,
(IsNull(convert(varchar,n.Hora,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.Hora,114),1,8),'')) as Hora,
n.Almacen  
from NotaPedido n with(nolock)     
inner join Cliente c  
on c.ClienteId=n.ClienteId  
inner join Compania co  
on co.CompaniaId=n.CompaniaId  
where(Day(n.NotaFecha)=Day(GETDATE()) and month(n.NotaFecha)=month(GETDATE())and year(n.NotaFecha)=year(GETDATE()))  
)  
union all  
(select n.NotaId,n.NotaDocu,  
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),'')) as NotaFecha,  
n.ClienteId,c.ClienteCodigo as Codigo,c.ClienteRazon,c.ClienteRuc,c.ClienteDni,  
n.NotaCondicion,n.NotaFormaPago,(Convert(char(10),n.NotaFechaPago,103))as NotaFechaPago,  
CONVERT(VarChar(50), cast(n.NotaPagar as money ), 1)as TotalPagar,  
CONVERT(VarChar(50), cast(n.NotaSaldo as money ), 1)as SaldoDocumento,  
CONVERT(VarChar(50), cast(n.NotaAcuenta as money ), 1)as NotaAcuenta,  
CONVERT(VarChar(50), cast(n.NotaSubtotal as money ), 1)as NotaSubtotal,  
CONVERT(VarChar(50), cast(n.NotaTotal as money ), 1)as OpGravada,  
CONVERT(VarChar(50), cast(n.NotaAdicional as money ), 1)as NotaAdicional,  
CONVERT(VarChar(50), cast(n.NotaTarjeta as money ), 1)as TotalTarjeta,  
n.NotaUsuario,n.NotaEstado,co.CompaniaRazonSocial as compania,  
c.ClienteDireccion as Direccion,n.NotaEntrega as Entrega,n.ModificadoPor,  
n.FechaEdita,n.NotaConcepto,n.NotaSerie,n.NotaNumero,n.NotaTransaccion,  
CONVERT(VarChar(50), cast(n.NotaDescuento as money ), 1)as Descuento,  
n.ConceptoOBS,n.CodigoRes,n.Responsable,EntidadBancaria as Entidad,  
CONVERT(VarChar(50), cast(n.Efectivo as money ), 1) as Efectivo,  
CONVERT(VarChar(50), cast(n.Deposito as money ), 1) as Deposito,  
n.NroOperacion,n.Entrega as Despacho,
(IsNull(convert(varchar,n.Hora,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.Hora,114),1,8),'')) as Hora,
n.Almacen  
from NotaPedido n with(nolock)   
inner join Cliente c  
on c.ClienteId=n.ClienteId  
inner join Compania co  
on co.CompaniaId=n.CompaniaId  
where n.NotaEstado<>'ANULADO'and(n.NotaConcepto='MERCADERIA' and n.Entrega<>'ENTREGADO' 
and((n.NotaEstado<>'CANCELADO')and convert(date,n.NotaFecha) < convert(date,getdate()))))  
union all  
(select n.NotaId,n.NotaDocu,  
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),'')) as NotaFecha,  
n.ClienteId,c.ClienteCodigo as Codigo,c.ClienteRazon,c.ClienteRuc,c.ClienteDni,  
n.NotaCondicion,n.NotaFormaPago,(Convert(char(10),n.NotaFechaPago,103))as NotaFechaPago,  
CONVERT(VarChar(50), cast(n.NotaPagar as money ), 1)as TotalPagar,  
CONVERT(VarChar(50), cast(n.NotaSaldo as money ), 1)as SaldoDocumento,  
CONVERT(VarChar(50), cast(n.NotaAcuenta as money ), 1)as NotaAcuenta,  
CONVERT(VarChar(50), cast(n.NotaSubtotal as money ), 1)as NotaSubtotal,  
CONVERT(VarChar(50), cast(n.NotaTotal as money ), 1)as OpGravada,  
CONVERT(VarChar(50), cast(n.NotaAdicional as money ), 1)as NotaAdicional,  
CONVERT(VarChar(50), cast(n.NotaTarjeta as money ), 1)as TotalTarjeta,  
n.NotaUsuario,n.NotaEstado,co.CompaniaRazonSocial as compania,  
c.ClienteDireccion as Direccion,n.NotaEntrega as Entrega,n.ModificadoPor,  
n.FechaEdita,n.NotaConcepto,n.NotaSerie,n.NotaNumero,n.NotaTransaccion,  
CONVERT(VarChar(50), cast(n.NotaDescuento as money ), 1)as Descuento,  
n.ConceptoOBS,n.CodigoRes,n.Responsable,EntidadBancaria as Entidad,  
CONVERT(VarChar(50), cast(n.Efectivo as money ), 1) as Efectivo,  
CONVERT(VarChar(50), cast(n.Deposito as money ), 1) as Deposito,  
n.NroOperacion,n.Entrega as Despacho,
(IsNull(convert(varchar,n.Hora,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.Hora,114),1,8),'')) as Hora,
n.Almacen  
from NotaPedido n with(nolock)   
inner join Cliente c  
on c.ClienteId=n.ClienteId  
inner join Compania co  
on co.CompaniaId=n.CompaniaId  
where n.NotaCondicion='ALCONTADO' and NotaEntrega='INMEDIATA' and 
n.NotaTransaccion='' and  ConceptoOBS='POR PASAR AL OBS'  and    
(n.NotaConcepto='MERCADERIA' and n.NotaEstado<>'ANULADO' and n.Entrega<>'ENTREGADO')and   
convert(date,n.NotaFecha) < convert(date,getdate()))  
order by 1 desc  
end
GO

IF OBJECT_ID(N'dbo.listarPersonal', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarPersonal] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarPersonal]
as
begin
SELECT p.PersonalId,p.PersonalCodigo,p.PersonalNombres,p.PersonalApellidos,
p.PersonalApellidos+' '+p.PersonalNombres as Nombres,a.AreaNombre, 
p.PersonalDNI,p.PersonalRuc,p.PersonalTelefono,p.PersonalTelefonoAsi,p.PersonalIngreso,
p.PersonalBajaFecha,Convert(char(10),p.PersonalNacimiento,103) as PersonalNacimiento,
(select dbo.CalcularEdad(p.personalNacimiento))AS Edad,p.PersonalDireccion,
p.PersonalSueldo,p.PersonalEmail,c.CompaniaRazonSocial,p.PersonalEstado,p.PersonalImagen
FROM Personal p 
INNER JOIN Area a 
ON a.AreaId =p.AreaId
inner join Compania c
on c.CompaniaId=p.CompaniaId
where p.PersonalEstado='ACTIVO'
order by p.PersonalApellidos asc
end
GO

IF OBJECT_ID(N'dbo.listarProducto', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarProducto] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarProducto]
as
begin
SELECT p.IdProducto,l.NombreLinea,s.NombreSublinea,p.ProductoCodigo,p.ProductoNombre,
p.ProductoMarca,p.ProductoNombre+' '+p.ProductoMarca as Descripcion,
p.ProductoCantidad as Stock,p.ProductoUM as UM,p.ProductoVenta,
p.ProductoPV,p.ProductoSV,p.ProductoINV,p.ProductoCosto,
p.ProductoUbicacion as Ubicacion,p.ProductoObs,
p.ProductoEstado as Estado,p.ProductoUsuario as Usuario,
p.ProductoFecha as Fecha,p.ProductoImagen as Imagen,
(convert(varchar(60),cast((p.ProductoCantidad * p.ProductoCosto) as money),-1))as Inversion,
(convert(varchar(60),cast((p.ProductoCantidad *p.ProductoVenta) as money),-1))as VentaNeta,
(convert(varchar(60),cast(((p.ProductoCantidad *p.ProductoVenta)-(p.ProductoCantidad * p.ProductoCosto)) as money),-1))as MargenUtilidad,
p.ValorCritico,p.ProductoxCaja as xCaja,p.AplicaFB
FROM Producto p with(nolock)
INNER JOIN Sublinea s
ON p.IdSubLinea =s.IdSubLinea 
INNER JOIN Linea l
ON s.IdLinea =l.IdLinea
where p.ProductoEstado='BUENO'
order by p.ProductoCodigo asc
end
GO

IF OBJECT_ID(N'dbo.listarRenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarRenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarRenta]
as
begin
select 
'ID|Compania|Anno|Mes|Declaracion|Igv|Renta|SaldoIgv|SaldoRenta|InteresIgv|InteresRenta|TotalIgv|TotalRenta|FormaPago|FechaPago|Entidad|NroOperacion|PagoTotal¬
80|90|80|80|145|120|120|120|120|120|120|120|110|70|120|100|100|120¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,r.RentaId)+'|'+convert(varchar,r.CompaniaId)+'|'+convert(varchar,r.RentaANNO)+'|'+
convert(varchar,r.RentaMes)+'|'+dbo.MesNombre(r.RentaMes)+' '+convert(varchar,r.RentaANNO)+'|'+
CONVERT(VarChar(50), cast((r.IGV) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.Renta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.SaldoIGV) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.SaldoRenta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.InteresIgv) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.InteresRenta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.TributoIgv) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.TributoRenta) as money ), 1)+'|'+
CONVERT(char(1),r.FormaPago)+'|'+convert(varchar,r.FechaCancelacion,103)+'|'+r.EntidadBancaria+'|'+r.NroOperacion+'|'+
CONVERT(VarChar(50), cast((r.PagoTotal) as money ), 1)
from RentaMensual r
where year(r.FechaCancelacion)=year(getdate())
order by r.RentaId desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.listarRentaFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarRentaFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarRentaFecha] 
@fechainicio date,@fechafin date
as
begin
select 
'ID|Compania|Anno|Mes|Declaracion|Igv|Renta|SaldoIgv|SaldoRenta|InteresIgv|InteresRenta|TotalIgv|TotalRenta|FormaPago|FechaPago|Entidad|NroOperacion|PagoTotal¬
80|90|80|80|145|120|120|120|120|120|120|120|110|70|120|100|100|120¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,r.RentaId)+'|'+convert(varchar,r.CompaniaId)+'|'+convert(varchar,r.RentaANNO)+'|'+
convert(varchar,r.RentaMes)+'|'+dbo.MesNombre(r.RentaMes)+' '+convert(varchar,r.RentaANNO)+'|'+
CONVERT(VarChar(50), cast((r.IGV) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.Renta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.SaldoIGV) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.SaldoRenta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.InteresIgv) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.InteresRenta) as money ), 1)+'|'+
CONVERT(VarChar(50), cast((r.TributoIgv) as money ), 1)+'|'+CONVERT(VarChar(50), cast((r.TributoRenta) as money ), 1)+'|'+
CONVERT(char(1),r.FormaPago)+'|'+convert(varchar,r.FechaCancelacion,103)+'|'+r.EntidadBancaria+'|'+r.NroOperacion+'|'+
CONVERT(VarChar(50), cast((r.PagoTotal) as money ), 1)
from RentaMensual r
where (Convert(char(10),r.FechaCancelacion,103) BETWEEN @fechainicio AND @fechafin)
order by r.RentaMes desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.listarSaldos', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarSaldos] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarSaldos] 
@ClienteId numeric(20)
as
begin
select
'DetalleId|NroNota|Idproducto|Codigo|Descripcion|Cantidad|Saldo|UM|Stock|UnidadM|CantInicial|critico|ClienteId|PrecioVenta|valorUM¬100|90|100|100|450|100|100|90|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,d.DetalleId)+'|'+convert(varchar,d.NotaId)+'|'+
convert(varchar,d.IdProducto)+'|'+p.ProductoCodigo+'|'+d.DetalleDescripcion+'|'+''+'|'+
convert(varchar(50),cast(d.CantidadSaldo as money),1)+'|'+d.DetalleUm+'|'+
convert(varchar(50),cast(p.ProductoCantidad as money),1)+'|'+p.ProductoUM+'|'+
convert(varchar(50),cast(d.DetalleCantidad as money),1)+'|'+
convert(varchar,p.ValorCritico)+'|'+convert(varchar,n.ClienteId)+'|'+
convert(varchar,d.DetallePrecio)+'|'+convert(varchar,d.ValorUM)
from DetallePedido d
inner join NotaPedido n
on n.NotaId=d.NotaId
inner join Producto p
on p.IdProducto=d.IdProducto
where n.ClienteId=@ClienteId and d.cantidadSaldo>0
order by n.NotaId desc,d.DetalleId asc
for xml path('')),1,1,'')),'~')+'_'+
isnull((select STUFF ((select '¬' +CONVERT(VarChar(50), cast(sum(n.NotaSaldo) as money ), 1)
from NotaPedido n
where n.ClienteId=@ClienteId and n.NotaEntrega='POR ENTREGAR'
for xml path('')),1,1,'')),'0')
end
GO

IF OBJECT_ID(N'dbo.listarSaldosB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarSaldosB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarSaldosB] @NotaId numeric(38)
as
begin
select d.DetalleId,d.NotaId,d.IdProducto,p.ProductoCodigo as Codigo,d.DetalleDescripcion as Descripcion,
d.CantidadSaldo as CantidadSaldo,p.ProductoCantidad as Stock,substring(p.ProductoUM,1,3) as UM,d.DetalleCantidad as CantidadInicial,
p.ValorCritico,n.ClienteId,d.DetallePrecio as PrecioCosto
from DetallePedido d
inner join NotaPedido n
on n.NotaId=d.NotaId
inner join Producto p
on p.IdProducto=d.IdProducto
where d.NotaId=@NotaId and d.cantidadSaldo>0
order by 1 asc
end
GO

IF OBJECT_ID(N'dbo.listarSublinea', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarSublinea] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarSublinea]
as
begin
select s.IdSubLinea,s.NombreSublinea,l.NombreLinea from Sublinea s
inner join Linea l
on l.IdLinea=s.IdLinea
order by IdSubLinea desc
end
GO

IF OBJECT_ID(N'dbo.listarUM', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarUM] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarUM] 
@IdProducto numeric(20)
as
begin
select
'IdUm|IdProducto|UNIDAD M|Valor|PreVenta|PreVentaB|PreCosto¬80|80|110|100|100|100|100¬String|String|String|Decimal|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,m.IdUm)+'|'+CONVERT(varchar,m.IdProducto)+'|'+m.UMDescripcion+'|'+
convert(varchar,m.ValorUM)+'|'+CONVERT(VarChar(50),cast(m.PrecioVenta as money ), 1)+'|'+CONVERT(VarChar(50), cast(m.PrecioVentaB as money ), 1)+'|'+
CONVERT(varchar(50),m.PrecioCosto)
from UnidadMedida m
where m.IdProducto=@IdProducto
order by m.ValorUM asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.listarUsuario', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listarUsuario] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listarUsuario]
as
begin
select u.UsuarioID,p.PersonalId,(((SUBSTRING(p.PersonalNombres+' ',1,CHARINDEX(' ',p.PersonalNombres+' ')-1))))+' '+ p.PersonalApellidos as Personal,u.UsuarioAlias,dbo.desincrectar(u.UsuarioClave)as UsuarioClave,a.AreaNombre,u.UsuarioFechaReg,u.Usuarioestado
from Usuarios u
inner join Personal p
on p.PersonalId=u.PersonalId
inner join Area a
on a.AreaId=p.AreaId
where u.UsuarioEstado='ACTIVO'
order by u.UsuarioID desc
end
GO

IF OBJECT_ID(N'dbo.listasMarca', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listasMarca] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listasMarca]
as
begin
select
isnull((select STUFF((select '¬'+ p.ProductoMarca
from Producto p
group by ProductoMarca
order by p.ProductoMarca asc 
FOR XML PATH('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ p.ProductoUM
from Producto p
group by ProductoUM
order by p.ProductoUM asc
FOR XML PATH('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ p.ProductoUbicacion
from Producto p
group by ProductoUbicacion
order by p.ProductoUbicacion asc
FOR XML PATH('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ convert(varchar,a.AlmacenId)+'|'+a.AlmacenNombre
from Almacen a
order by a.AlmacenNombre asc
FOR XML PATH('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.listaTempoCompra', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaTempoCompra] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaTempoCompra]
@UsuarioID int
as
begin
select
'Id|IdProducto|Codigo|Descripcion|UM|Cantidad|PrecioCosto|Descuento|Importe|ValorUM|Estado¬100|100|100|420|80|90|100|100|110|100|100¬String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,t.TemporalId)+'|'+convert(varchar,t.IdProducto)+'|'+
t.DetalleCodigo+'|'+t.Descripcion+'|'+t.DetalleUM+'|'+
CONVERT(VarChar(50),cast(t.DetalleCantidad as money ), 1)+'|'+
convert(varchar,t.PrecioCosto)+'|'+convert(varchar,t.DetalleDescuento)
+'|'+convert(varchar,t.DetalleImporte)+'|'+CONVERT(varchar,t.ValorUM)+'|'+
t.DetalleEstado
from TemporalCompra t 
inner join Producto p 
on p.IdProducto=t.IdProducto 
where t.UsuarioID=@UsuarioID
order by t.TemporalId asc
for xml path('')),1,1,'')),'~')+'['+
'IdUm|IdProducto|UnidadM|Valor|Costo¬100|100|100|100|100¬String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,u.IdUm)+'|'+convert(varchar,u.IdProducto)+'|'+
u.UMDescripcion+'|'+CONVERT(VarChar(50), cast(u.ValorUM as money ), 1)+'|'+
convert(varchar,t.PrecioCosto)
from UnidadMedida u
inner join TemporalCompra t
on t.IdProducto=u.IdProducto
where t.UsuarioID=@UsuarioID
order by u.ValorUM asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.listaTempoGuia', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaTempoGuia] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaTempoGuia] 
@UsuarioID int,
@Concepto varchar(60)
as
select t.temporalId,t.UsuarioID,t.IdProducto,p.ProductoCodigo as Codigo,
t.cantidad as Cantidad,t.DetalleUM as UM,p.ProductoNombre+' '+p.ProductoMarca as Descripcion,
cast((p.ProductoCosto* t.ValorUM) as decimal(18,2)) as ProductoCosto,
t.precioventa,t.importe,t.Concepto,p.ProductoCantidad as Stock,
t.CantidadSaldo as Saldo,t.ClienteId,t.DetalleId,
t.ValorUM
from TemporalGuia t
inner join Producto p
on p.IdProducto=t.IdProducto
where t.UsuarioID=@UsuarioID and t.Concepto=@Concepto
order by t.temporalId asc
GO

IF OBJECT_ID(N'dbo.listaTempoLiquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaTempoLiquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaTempoLiquida] @UsuarioId Int
as
begin
select t.TemporalId,t.IdDeuda,t.Numero,t.Proveedor,
CONVERT(VarChar(50), cast(t.SaldoDocu as money ), 1) as CompraSaldo,t.Moneda,t.TipoCambio,t.EfectivoSoles,t.EfectivoDolar,t.DepositoSoles,t.DepositoDolar,t.EntidadBanco,
t.NroOperacion,CONVERT(VarChar(50), cast(t.AcuentaGeneral as money ), 1) as AcuentaGeneral,
t.UsuarioId,t.TemporalFecha,CONVERT(VarChar(50), cast(t.SaldoDocu - t.AcuentaGeneral as money ), 1) as SaldoActual,t.Concepto
from TemporalLiquida t
where UsuarioId=@UsuarioId
order by 1 asc
end
GO

IF OBJECT_ID(N'dbo.listaTempoLiVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaTempoLiVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaTempoLiVenta]
@UsuarioId Int
as
begin
select t.TemporalId,n.NotaId as DocuId,
n.NotaSerie+'-'+n.NotaNumero as Numero,
c.ClienteRazon,
CONVERT(VarChar(50), cast(t.SaldoDocu as money ), 1) as DocuSaldo,'SOLES' as Moneda,t.TipoCambio,
t.EfectivoSoles,t.EfectivoDolar,t.DepositoSoles,t.DepositoDolar,t.EntidadBanco,
t.NroOperacion,CONVERT(VarChar(50), cast(t.AcuentaGeneral as money ), 1) as AcuentaGeneral,
t.UsuarioId,t.TemporalFecha,CONVERT(VarChar(50), cast(t.SaldoDocu - t.AcuentaGeneral as money ), 1) as SaldoActual,t.NotaId
from TemporalLiVenta t
inner join NotaPedido n
on n.NotaId=t.NotaId
inner join Cliente c
on c.ClienteId=n.ClienteId
where t.UsuarioId=@UsuarioId
order by 1 asc
end
GO

IF OBJECT_ID(N'dbo.listaTempoVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaTempoVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaTempoVenta] @UsuarioID int
	as
	select t.temporalId,t.UsuarioID,t.IdProducto,p.ProductoCodigo as Codigo,t.cantidad as Cantidad,
	t.UniMedida as UM,p.ProductoNombre+' '+p.ProductoMarca as Descripcion,
	cast((p.ProductoCosto* t.ValorUM) as decimal(18,2)) as ProductoCosto,t.precioventa,t.importe,p.ProductoImagen as Imagen,
	t.ValorUM,convert(decimal(18,2),t.precioventa/1.18) as PrecioSunat,
	(t.importe - convert(decimal(18,2),t.importe/1.18)) as IGVPrecio,
	convert(decimal(18,2),t.importe/1.18)as ImporteSunat
	from TemporalVenta t
	inner join Producto p
	on p.IdProducto=t.IdProducto
	where t.UsuarioID=@UsuarioID 
	order by t.temporalId asc
GO

IF OBJECT_ID(N'dbo.listaTempoVentaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaTempoVentaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaTempoVentaB]
@UsuarioID int
as
select
'DetalleId|NotaId|IdProducto|Codigo|Cantidad|UM|Descripcion|PrecioCosto|PrecioUni|PV|SV|Importe|Imagen|ValorUM|PrecioSunat|IGVPrecio|ImporteSunat|PVUNI|SVUNI|Linea|AplicaFB¬100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
    isnull((select STUFF ((select '¬'+convert(varchar,t.temporalId)+'|'+CONVERT(varchar,t.UsuarioId)+'|'+convert(varchar,t.IdProducto)+'|'+
    p.ProductoCodigo+'|'+convert(varchar,t.cantidad)+'|'+t.UniMedida+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
	convert(varchar,cast((p.ProductoCosto* t.ValorUM) as decimal(18,2)))+'|'+
	convert(varchar,t.precioventa)+'|'+
    CONVERT(VarChar(50), cast((t.cantidad*p.ProductoPV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast((t.cantidad*p.ProductoSV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(t.importe as money ), 1)+'|'+
	p.ProductoImagen+'|'+
	convert(varchar,t.ValorUM)+'|'+
	convert(varchar,convert(decimal(18,2),t.precioventa/1.18))+'|'+
	convert(varchar,(t.importe - convert(decimal(18,2),t.importe/1.18)))+'|'+
	convert(varchar,convert(decimal(18,2),t.importe/1.18))+'|'+
	convert(varchar,p.ProductoPV)+'|'+convert(varchar,p.ProductoSV)+'|'+
	s.NombreSublinea+'|'+p.AplicaFB
	from TemporalVenta t
	inner join Producto p
	on p.IdProducto=t.IdProducto
	inner join Sublinea s
	on s.IdSubLinea=p.IdSubLinea
	where t.UsuarioID=@UsuarioID 
	order by t.temporalId asc
	for xml path('')),1,1,'')),'~')
GO

IF OBJECT_ID(N'dbo.listaTempoVentaSP', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaTempoVentaSP] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaTempoVentaSP]
@GuiaId numeric(38)
as
begin
Declare @Data varchar(max)
Declare @NotaTransaccion varchar(300)
Declare @Descuento decimal(18,2)
declare @c1 int,@c2 int
set @Data=isnull((select top 1 g.NotaTransaccion+'|'+
CONVERT(VarChar(50), cast(g.Descuento as money ), 1) from GuiaRemision g 
where g.GuiaId=@GuiaId
order by g.GuiaId desc),'|0.00')
Set @c1 = CharIndex('|',@Data,0)
Set @c2= Len(@Data)+1
set @NotaTransaccion=SUBSTRING(@Data,1,@c1-1)
Set @Descuento=convert(decimal(18,2),SUBSTRING(@Data,@c1+1,@c2-@c1-1)) 
select
'DetalleId|NotaId|IdProducto|Codigo|Cantidad|UM|Descripcion|PrecioCosto|PrecioUni|PV|SV|Importe|Imagen|ValorUM|PrecioSunat|IGVPrecio|ImporteSunat|PVUNI|SVUNI|Linea¬100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
    isnull((select STUFF ((select '¬'+convert(varchar,t.DetalleId)+'|'+CONVERT(varchar,t.GuiaId)+'|'+convert(varchar,t.IdProducto)+'|'+
    p.ProductoCodigo+'|'+convert(varchar,t.DetalleCantidad)+'|'+p.ProductoUM+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
	convert(varchar,cast((t.DetalleCosto) as decimal(18,2)))+'|'+
	convert(varchar,t.DetallePrecio)+'|'+
    CONVERT(VarChar(50), cast(t.DetallePV as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(t.DetalleSV as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(t.DetalleImporte as money ), 1)+'|'+
	p.ProductoImagen+'|1.00|'+
	convert(varchar,convert(decimal(18,2),t.DetallePrecio/1.18))+'|'+
	convert(varchar,(t.DetalleImporte - convert(decimal(18,2),t.DetalleImporte/1.18)))+'|'+
	convert(varchar,convert(decimal(18,2),t.DetalleImporte/1.18))+'|'+
	convert(varchar,p.ProductoPV)+'|'+convert(varchar,p.ProductoSV)+'|'+
	s.NombreSublinea
	from DetalleGuia t
	inner join Producto p
	on p.IdProducto=t.IdProducto
	inner join Sublinea s
	on s.IdSubLinea=p.IdSubLinea
	where t.GuiaId=@GuiaId 
	order by t.DetalleId asc
	for xml path('')),1,1,'')),'~')+'['+@NotaTransaccion+'['+CONVERT(varchar,@Descuento)
	end
GO

IF OBJECT_ID(N'dbo.listaTipoCambio', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaTipoCambio] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaTipoCambio]
as
begin
select
'ID|Fecha|COMPRA|VENTA|EMPRESA¬90|110|108|108|117¬String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+ convert(varchar,t.IdTipo),+'|'+
(Convert(char(10),t.TipoFecha,103))+'|'+convert(varchar,t.TipoCompra)+'|'+
convert(varchar,t.TipoVenta)+'|'+
convert(varchar,t.TipoEmpresa) 
from TipoCambio t 
where MONTH(t.TipoFecha)=MONTH(GETDATE()) and YEAR(t.TipoFecha)=YEAR(GETDATE()) 
order by t.TipoFecha desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.listaValorCritico', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[listaValorCritico] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[listaValorCritico] @IdSubLinea numeric(20)
as
begin
select p.IdProducto,p.ProductoCodigo as Codigo,p.ProductoNombre+' '+p.ProductoMarca as Descripcion,
CONVERT(VarChar(50), cast(p.ProductoCantidad as money ), 1) as Stock,
p.ProductoUM as UM,p.ProductoCosto as Costo,p.ProductoCostoDolar as CostoDolar
from Producto p
where p.IdSubLinea=@IdSubLinea and (p.ProductoCantidad < = p.ValorCritico)
order by 3 asc
end
GO

IF OBJECT_ID(N'dbo.LuisDuenas', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[LuisDuenas] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[LuisDuenas]
as
begin
select 'SubLinea|Codigo|Descipcion|Stock|UM|Costo|CostoDolar¬295|130|470|105|105|105|105¬'+
isnull((select STUFF((select'¬'+s.NombreSublinea+'|'+p.ProductoCodigo+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
CONVERT(VarChar(50), cast(p.ProductoCantidad as money ), 1)+'|'+
p.ProductoUM+'|'+CONVERT(VarChar(50), cast(p.ProductoCosto as money ), 1)+'|'+CONVERT(VarChar(50), cast(p.ProductoCostoDolar as money ), 1)
from Producto p
inner join Sublinea s
on s.IdSubLinea=p.IdSubLinea
where p.ProductoCantidad < = p.ValorCritico
order by p.ProductoNombre+' '+p.ProductoMarca asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.LuisDuenasB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[LuisDuenasB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[LuisDuenasB] 
@Mes int,
@Anno int
as
begin
select 'Fecha|Vendedor|Descripcion|UM|Cantidad|PrecioUni|Costo|GXUnidad|Ganancia¬130|150|400|65|110|110|110|110|115¬'+
(select STUFF((select '¬'+
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))
+'|'+n.NotaUsuario+'|'+
d.DetalleDescripcion+'|'+d.DetalleUm+'|'+
CONVERT(VarChar(50), cast((d.DetalleCantidad) as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetallePrecio as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleCosto as money ), 1) +'|'+
CONVERT(VarChar(50), cast((d.DetallePrecio-d.DetalleCosto) as money ), 1)+'|'+
CONVERT(VarChar(50), cast(((d.DetallePrecio-d.DetalleCosto)* d.DetalleCantidad) as money ), 1)
	 from DetallePedido d (noLOCK) 
	 inner join NotaPedido n (noLOCK)
	 on n.NotaId=d.NotaId
	 where (MONTH(n.NotaFecha)=@Mes and year(n.NotaFecha)=@Anno) and n.NotaEstado='CANCELADO'
	 order by n.NotaFecha desc
	 for xml path('')),1,1,''))
 end
GO

IF OBJECT_ID(N'dbo.MRDuenas', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[MRDuenas] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[MRDuenas]
as
begin
select 'SubLineas|Productos['+
isnull((select STUFF((select '¬'+ convert(varchar,s.IdSubLinea)+'|'+s.NombreSublinea
from Sublinea s
for XMl path('')),1,1,'')),'~')+'['+
'Descripcion|Cantidad|UM|PreVenta|PreCosto¬400|115|80|115|115¬'+
isnull((select STUFF((select '¬'+convert(varchar,p.ProductoNombre+' '+p.ProductoMarca)+'|'+CONVERT(varchar,p.ProductoCantidad)
+'|'+p.ProductoUM+'|'+CONVERT(varchar,p.ProductoVenta)+
'|'+CONVERT(varchar,p.ProductoCosto)+'|'+convert(varchar,p.IdSubLinea)
from Producto p
for XMl path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.permisoElimina', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[permisoElimina] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[permisoElimina]
@Codigo varchar(60)
as
begin
select top 1 (((SUBSTRING(p.PersonalNombres+' ',1,CHARINDEX(' ',p.PersonalNombres+' ')-1)))+' '+ ((SUBSTRING(p.PersonalApellidos+' ',1,CHARINDEX(' ',p.PersonalApellidos+' ')-1))))as USUARIO 
from Personal p
where PersonalCodigo=@Codigo and (AreaId=6 or AreaId=7)
end
GO

IF OBJECT_ID(N'dbo.prueba', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[prueba] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[prueba]
as
begin
select
'Id|xCaja¬100|100¬String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,p.IdProducto)+'|'+
convert(varchar,p.ProductoxCaja)
from Producto p
inner join DetalleApertura d
on p.IdProducto=d.IdProducto
group by p.IdProducto,p.ProductoxCaja
for XML path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.pruebaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[pruebaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[pruebaB]
as
begin
select
'Id|xCaja¬100|100¬String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,p.IdProducto)+'|'+
convert(varchar,p.ProductoxCaja)
from Producto p
inner join DetalleCierre d
on p.IdProducto=d.IdProducto
group by p.IdProducto,p.ProductoxCaja
for XML path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.reporteGanancia', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[reporteGanancia] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[reporteGanancia] 
@anno int
as
begin
select 'Numero|Mes|Ventas|G_Ventas|Gastos|G_Liquida¬80|100|110|110|105|110¬String|String|String|String|String|String¬'+
(select STUFF((select '¬'+ convert(varchar,isnull(a.Numero,g.Numero))+'|'+convert(varchar,ISNULL(a.Mes,g.Mes))+'|'+
	CONVERT(VarChar(50), cast(isnull(a.Ventas,0) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(isnull(a.Ganancia,0)as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(isnull(g.Gastos,0) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast((isnull(a.Ganancia,0)-isnull(g.Gastos,0)) as money ), 1)
	from	
(select month(n.NotaFecha) as Numero,DATENAME(month,n.NotaFecha) as Mes,sum(n.NotaPagar) as Ventas,
sum(n.NotaGanancia)- SUM(n.NotaDescuento)as Ganancia --GANANCIA
from 
	NotaPedido n(noLOCK) 
	where n.NotaEstado='CANCELADO' and YEAR(n.NotaFecha)=@anno
	group by month(n.NotaFecha),DATENAME(month,n.NotaFecha))a
full join(
	select month(g.GastoFecha) as Numero,DATENAME(month,g.GastoFecha) as Mes,SUM(g.GstoMonto) as Gastos 
	from GastosFijos g (noLOCK) --GASTOS
	where YEAR(g.GastoFecha)=@anno
	group by month(g.GastoFecha),DATENAME(month,g.GastoFecha)
)g on a.Numero=g.Numero
order by a.Numero desc,g.Numero desc
FOR XML PATH('')),1,1,''))
end
GO

IF OBJECT_ID(N'dbo.reporteGananciaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[reporteGananciaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[reporteGananciaB] 
@Mes int,
@anno int
as
begin
select isnull(a.Numero,g.Numero) as Numero,ISNULL(a.Mes,g.Mes) as Mes,
CONVERT(VarChar(50), cast(isnull(v.TotalVenta,0) as money ), 1) as TotalVenta,
CONVERT(VarChar(50), cast((isnull(a.Ganancia,0))as money ), 1) as G_Ventas,
CONVERT(VarChar(50), cast(isnull(g.Gastos,0) as money ), 1) as Gatos,
CONVERT(VarChar(50), cast((isnull(a.Ganancia,0)-isnull(g.Gastos,0)) as money ), 1) as G_Liquida
from
(select month(n.NotaFecha) as Numero,DATENAME(month,n.NotaFecha) as Mes,
sum(n.NotaGanancia)- SUM(n.NotaDescuento) as Ganancia--ganancia
from 
NotaPedido n
where n.NotaEstado='CANCELADO' and (MONTH(n.NotaFecha)=@Mes and YEAR(n.NotaFecha)=@anno)
group by month(n.NotaFecha),DATENAME(month,n.NotaFecha))a
full join(
select month(g.GastoFecha) as Numero,DATENAME(month,g.GastoFecha) as Mes,SUM(g.GstoMonto) as Gastos 
from GastosFijos g--gastos
where(Month(g.GastoFecha)=@Mes and YEAR(g.GastoFecha)=@anno)
group by month(g.GastoFecha),DATENAME(month,g.GastoFecha)
)g on a.Numero=g.Numero
full join(select month(n.NotaFecha) as Numero,
DATENAME(month,n.NotaFecha) as Mes,SUM(n.NotaPagar) as TotalVenta 
from NotaPedido n--total venta
where (Month(n.NotaFecha)=@Mes and YEAR(n.NotaFecha)=@anno) and n.NotaEstado='CANCELADO'
group by month(n.NotaFecha),DATENAME(month,n.NotaFecha)
)v on a.Numero=v.Numero
group by a.Numero,g.Numero,a.Mes,g.Mes,v.TotalVenta,a.Ganancia,g.Gastos
order by 1 desc
end
GO

IF OBJECT_ID(N'dbo.reportePDT', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[reportePDT] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[reportePDT]
@CompaniaId int,
@Mes int,
@Anno int
as
begin
select isnull(b.CompaniaId,isnull(S.CompaniaId,isnull(d.CompaniaId,isnull(x.CompaniaId,z.CompaniaId)))) as CompaniaId,
convert(varchar(50),cast((ISNULL(b.Monto,0))as money),1) as Ventas,
convert(varchar(50),cast((ISNULL(s.Monto,0)+ISNULL(d.Monto,0))-(ISNULL(x.Monto,0)+ISNULL(z.Monto,0))as money),1) as Compras
from
(
select d.CompaniaId,sum(d.DocuTotal) as Monto--VENTASSS
from DocumentoVenta d
where d.CompaniaId=@companiaId and(month(d.DocuEmision)=@Mes and year(d.DocuEmision)=@Anno)and (d.DocuDocumento<>'PROFORMA V' AND d.DocuDocumento<>'NOTA PEDIDO') and d.DocuEstado<>'ANULADO'
group by d.CompaniaId
)b
full join(
select c.CompaniaId,sum(c.CompraTotal) as Monto
from Compras c--FACTURAS EN SOLES
where c.CompaniaId=@companiaId and(month(c.CompraComputo)=@Mes and year(c.CompraComputo)=@Anno)AND(c.TipoCodigo='01' and c.CompraMoneda='SOLES')
group by c.CompaniaId
)s on b.CompaniaId=s.CompaniaId
full join
(select c.CompaniaId,cast(sum(c.CompraTotal*c.CompraTipoSunat)as decimal(18,2)) as Monto
from Compras c--FACTURAS EN DOLARES
where c.CompaniaId=@companiaId and (month(c.CompraComputo)=@Mes and year(c.CompraComputo)=@Anno)AND(c.TipoCodigo='01' and c.CompraMoneda='DOLARES')
group by c.CompaniaId
)d on b.CompaniaId=d.CompaniaId
full join(
select c.CompaniaId,cast(sum(c.CompraTotal*c.CompraTipoSunat)as decimal(18,2)) as Monto
from Compras c--nota de credito en dolares
where c.CompaniaId=@companiaId and(month(c.CompraComputo)=@Mes and year(c.CompraComputo)=@Anno)AND(c.TipoCodigo='07' and c.CompraMoneda='DOLARES')
group by c.CompaniaId
)x on b.CompaniaId=x.CompaniaId
full join (
select c.CompaniaId,sum(c.CompraTotal) as Monto
from Compras c--nota de credito en soles
where c.CompaniaId=@companiaId and(month(c.CompraComputo)=@Mes and year(c.CompraComputo)=@Anno)AND(c.TipoCodigo='07' and c.CompraMoneda='SOLES')
group by c.CompaniaId
)z on b.CompaniaId=z.CompaniaId
end
GO

IF OBJECT_ID(N'dbo.reporteVentaCompania', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[reporteVentaCompania] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[reporteVentaCompania]
@Mes int,
@Anno int
as
begin
select top 2 isnull(b.CompaniaId,isnull(S.CompaniaId,isnull(d.CompaniaId,isnull(x.CompaniaId,z.CompaniaId)))) as CompaniaId,
ISNULL(b.RazonSocial,isnull(S.RazonSocial,isnull(d.RazonSocial,isnull(x.RazonSocial,z.RazonSocial))))as RazonSocial,
convert(varchar(50),cast((ISNULL(b.Monto,0))as money),1) as Ventas,
convert(varchar(50),cast(((ISNULL(s.Monto,0)+ISNULL(d.Monto,0))-(ISNULL(x.Monto,0)+ISNULL(z.Monto,0)))as money),1) as Compras
from
(
select top 2 c.CompaniaId,c.CompaniaRazonSocial as RazonSocial,
sum(d.DocuTotal) as Monto--VENTASSS
from DocumentoVenta d
inner join Compania c
on c.CompaniaId=d.CompaniaId
where (month(d.DocuEmision)=@Mes and year(d.DocuEmision)=@Anno)and (d.DocuDocumento<>'PROFORMA V' AND d.DocuDocumento<>'NOTA PEDIDO' AND d.DocuDocumento<>'NOTA DE CREDITO') and d.DocuAsociado=''
group by c.CompaniaId,c.CompaniaRazonSocial
)b
full join(
select TOP 2 co.CompaniaId,co.CompaniaRazonSocial as RazonSocial,sum(c.CompraTotal) as Monto
from Compras c--FACTURAS EN SOLES
inner join Compania co
on co.CompaniaId=c.CompaniaId
where (month(c.CompraComputo)=@Mes and year(c.CompraComputo)=@Anno)AND(c.TipoCodigo='01' and c.CompraMoneda='SOLES')
group by co.CompaniaId,co.CompaniaRazonSocial
)s on b.CompaniaId=s.CompaniaId
full join
(select TOP 2 co.CompaniaId,co.CompaniaRazonSocial as RazonSocial,cast(sum(c.CompraTotal*c.CompraTipoSunat)as decimal(18,2)) as Monto
from Compras c--FACTURAS EN DOLARES
inner join Compania co
on co.CompaniaId=c.CompaniaId
where(month(c.CompraComputo)=@Mes and year(c.CompraComputo)=@Anno)AND(c.TipoCodigo='01' and c.CompraMoneda='DOLARES')
group by co.CompaniaId,co.CompaniaRazonSocial
)d on b.CompaniaId=d.CompaniaId
full join(
select TOP 2 co.CompaniaId,co.CompaniaRazonSocial as RazonSocial,cast(sum(c.CompraTotal*c.CompraTipoSunat)as decimal(18,2)) as Monto
from Compras c--nota de credito en dolares
inner join Compania co
on co.CompaniaId=c.CompaniaId
where(month(c.CompraComputo)=@Mes and year(c.CompraComputo)=@Anno)AND(c.TipoCodigo='07' and c.CompraMoneda='DOLARES')
group by co.CompaniaId,co.CompaniaRazonSocial
)x on b.CompaniaId=x.CompaniaId
full join (
select TOP 2 co.CompaniaId,co.CompaniaRazonSocial as RazonSocial,sum(c.CompraTotal) as Monto
from Compras c--nota de credito en soles
inner join Compania co
on co.CompaniaId=c.CompaniaId
where(month(c.CompraComputo)=@Mes and year(c.CompraComputo)=@Anno)AND(c.TipoCodigo='07' and c.CompraMoneda='SOLES')
group by co.CompaniaId,co.CompaniaRazonSocial
)z on b.CompaniaId=z.CompaniaId
end
GO

IF OBJECT_ID(N'dbo.respaldoBD', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[respaldoBD] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[respaldoBD]
as
begin
declare @fecha varchar(max)
declare @hora varchar(max)
declare @archivo varchar(max)

set @fecha=CONVERT(Varchar(10),GETDATE(),105)
set @hora=REPLACE(CONVERT(varchar(10), GETDATE(), 108),':','-')
set @archivo='C:\Users\HP\OneDrive\Bakup\ROSITA-'+@fecha+'-'+@hora+'.bak'--'D:\Archivo_Sistema\Backup\ROSITA-'+@fecha+'-'+@hora+'.bak'

BACKUP DATABASE ROSITA TO DISK=@archivo
WITH FORMAT,
NAME='ROSITA';
end
GO

IF OBJECT_ID(N'dbo.rptCompraA', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[rptCompraA] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[rptCompraA]
as
begin
select c.CompraId,Convert(char(10),c.CompraEmision,103) as FechaEmision,c.CompraSerie+'-'+c.CompraNumero as Documento,
p.ProveedorRuc as RUC,p.ProveedorRazon as RazonSocial,c.TipoCodigo as TipoCodigo,
case when c.CompraMoneda='DOLARES' THEN
CONVERT(VarChar(50), cast((c.CompraTotal/1.18)*c.CompraTipoSunat as money ), 1)
else  CONVERT(VarChar(50), cast((c.CompraTotal/1.18) as money ), 1)
end as SubTotal,
case when c.CompraMoneda='DOLARES' then
CONVERT(VarChar(50), cast((c.CompraTotal-(c.CompraTotal/1.18))*c.CompraTipoSunat as money ), 1)
else CONVERT(VarChar(50), cast((c.CompraTotal-(c.CompraTotal/1.18))as money ), 1)
end as IGV,
case when c.CompraMoneda='DOLARES' then
CONVERT(VarChar(50), cast((c.CompraTotal *c.CompraTipoSunat) as money ), 1)
else CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1)
end as Total,c.CompraMoneda as Moneda,c.CompraTipoSunat as TipoSunat,CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1) as Monto
from Compras c
inner join Proveedor p
on p.ProveedorId=c.ProveedorId
end
GO

IF OBJECT_ID(N'dbo.rptCompraComputo', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[rptCompraComputo] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[rptCompraComputo] @fechainicio date,@fechafin date,@CompaniaId int
as
begin
select c.CompraId,Convert(char(10),c.CompraEmision,103) as FechaEmision,c.CompraSerie+'-'+c.CompraNumero as Documento,
p.ProveedorRuc as RUC,p.ProveedorRazon as RazonSocial,c.TipoCodigo as TipoCodigo,
case when c.CompraMoneda='DOLARES' THEN
CONVERT(VarChar(50), cast((c.CompraTotal/1.18)*c.CompraTipoSunat as money ), 1)
else  CONVERT(VarChar(50), cast((c.CompraTotal/1.18) as money ), 1)
end as SubTotal,
case when c.CompraMoneda='DOLARES' then
CONVERT(VarChar(50), cast((c.CompraTotal-(c.CompraTotal/1.18))*c.CompraTipoSunat as money ), 1)
else CONVERT(VarChar(50), cast((c.CompraTotal-(c.CompraTotal/1.18))as money ), 1)
end as IGV,
case when c.CompraMoneda='DOLARES' then
CONVERT(VarChar(50), cast((c.CompraTotal *c.CompraTipoSunat) as money ), 1)
else CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1)
end as Total,c.CompraMoneda as Moneda,c.CompraTipoSunat as TipoSunat,CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1) as Monto
from Compras c
inner join Proveedor p
on p.ProveedorId=c.ProveedorId
where (Convert(char(10),c.CompraComputo,103) BETWEEN @fechainicio AND @fechafin) and (c.TipoCodigo='01' or c.TipoCodigo='07') and c.CompaniaId=@CompaniaId
order by c.CompraEmision asc
end
GO

IF OBJECT_ID(N'dbo.rptCompraEmision', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[rptCompraEmision] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[rptCompraEmision] @fechainicio date,@fechafin date,@CompaniaId int
as
begin
select c.CompraId,Convert(char(10),c.CompraEmision,103) as FechaEmision,c.CompraSerie+'-'+c.CompraNumero as Documento,
p.ProveedorRuc as RUC,p.ProveedorRazon as RazonSocial,c.TipoCodigo as TipoCodigo,
case when c.CompraMoneda='DOLARES' THEN
CONVERT(VarChar(50), cast((c.CompraTotal/1.18)*c.CompraTipoSunat as money ), 1)
else  CONVERT(VarChar(50), cast((c.CompraTotal/1.18) as money ), 1)
end as SubTotal,
case when c.CompraMoneda='DOLARES' then
CONVERT(VarChar(50), cast((c.CompraTotal-(c.CompraTotal/1.18))*c.CompraTipoSunat as money ), 1)
else CONVERT(VarChar(50), cast((c.CompraTotal-(c.CompraTotal/1.18))as money ), 1)
end as IGV,
case when c.CompraMoneda='DOLARES' then
CONVERT(VarChar(50), cast((c.CompraTotal *c.CompraTipoSunat) as money ), 1)
else CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1)
end as Total,c.CompraMoneda as Moneda,c.CompraTipoSunat as TipoSunat,CONVERT(VarChar(50), cast(c.CompraTotal as money ), 1) as Monto
from Compras c
inner join Proveedor p
on p.ProveedorId=c.ProveedorId
where (Convert(char(10),c.CompraEmision,103) BETWEEN @fechainicio AND @fechafin) and (c.TipoCodigo='01' or c.TipoCodigo='07') and c.CompaniaId=@CompaniaId
order by c.CompraEmision asc
end
GO

IF OBJECT_ID(N'dbo.rptMes', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[rptMes] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[rptMes]
@Mes int,
@Anno int
as 
begin
select
'Dia|Fecha|Venta|Ganancia|Gastos|GananciaLQ¬80|105|103|103|103|103¬String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+
convert(varchar,isnull(a.Dia,b.Dia))+'|'+convert(varchar,isnull(a.Fecha,b.Fecha))+'|'+
convert(varchar(50),cast(isnull(a.VentaTotal,0)as money),1)+'|'+
convert(varchar(50),cast(isnull(a.GananciaTotal,0)as money),1)+'|'+
convert(varchar(50),cast(isnull(b.Gastos,0)as money),1)+'|'+
convert(varchar(50),cast(isnull(a.GananciaTotal,0)-isnull(b.Gastos,0)as money),1)
from
(select DAY(n.NotaFecha) as Dia,
dbo.diaNombre(n.NotaFecha)+' '+convert(nvarchar,DAY(n.NotaFecha)) as Fecha,
SUM(n.NotaPagar)as VentaTotal,
SUM(NotaGanancia)- SUM(n.NotaDescuento) as GananciaTotal
from NotaPedido n
where (month(n.NotaFecha)=@Mes and year(n.NotaFecha)=@Anno) and n.NotaEstado='CANCELADO'
group by DAY(n.NotaFecha),dbo.diaNombre(n.NotaFecha))a
full join(
	select DAY(g.GastoFecha) as Dia,
	dbo.diaNombre(g.GastoFecha)+' '+convert(nvarchar,DAY(g.GastoFecha)) as Fecha,
	SUM(g.GstoMonto) as Gastos 
	from GastosFijos g (noLOCK) 
	where (month(g.GastoFecha)=@Mes and year(g.GastoFecha)=@Anno)
	group by DAY(g.GastoFecha),dbo.diaNombre(g.GastoFecha)
)b on a.Dia=b.Dia
order by a.Dia DESC
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.rptSemanal', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[rptSemanal] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[rptSemanal]
@Fecha date,
@Anno int
as
begin
declare @NumSemana int
set @NumSemana=(select DATEPART(WK,@Fecha))
select
'Dia|Fecha|Venta|Ganancia|Gastos|GananciaLQ¬80|113|105|105|105|105¬String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+
convert(varchar,isnull(a.Dia,b.Dia))+'|'+convert(varchar,isnull(a.Fecha,b.Fecha))+'|'+
convert(varchar(50),cast(isnull(a.VentaTotal,0)as money),1)+'|'+
convert(varchar(50),cast(isnull(a.GananciaTotal,0)as money),1)+'|'+
convert(varchar(50),cast(isnull(b.Gastos,0)as money),1)+'|'+
convert(varchar(50),cast(isnull(a.GananciaTotal,0)-isnull(b.Gastos,0)as money),1)
from
(select DAY(n.NotaFecha) as Dia,
dbo.diaNombre(n.NotaFecha)+' '+convert(nvarchar,DAY(n.NotaFecha)) as Fecha,
SUM(n.NotaPagar)as VentaTotal,
SUM(NotaGanancia)- SUM(n.NotaDescuento) as GananciaTotal
from NotaPedido n
where ((DATEPART(WK,n.NotaFecha)=@NumSemana)and year(n.NotaFecha)=@Anno) and n.NotaEstado='CANCELADO'
group by DAY(n.NotaFecha),dbo.diaNombre(n.NotaFecha))a
full join(
	select DAY(g.GastoFecha) as Dia,
	dbo.diaNombre(g.GastoFecha)+' '+convert(nvarchar,DAY(g.GastoFecha)) as Fecha,
	SUM(g.GstoMonto) as Gastos 
	from GastosFijos g (noLOCK) 
	where((DATEPART(WK,g.GastoFecha)=@NumSemana) and YEAR(g.GastoFecha)=@Anno)
    group by DAY(g.GastoFecha),dbo.diaNombre(g.GastoFecha)
)b on a.Dia=b.Dia
order by a.Dia ASC
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.rptVendedor', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[rptVendedor] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[rptVendedor]   
@Mes INT,  
@ANNO INT  
as  
begin 
select
'Personal|Clientes|Ventas|SubTotal|IGV|Ganancia|ImpRenta|Descuento|DesTotal|GLiquida¬185|105|125|125|125|125|125|125|125|125¬String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+isnull(a.Usuario,b.Usuario)+'|'+  
convert(varchar,ISNULL(a.Cliente,0))+'|'+  
convert(varchar(50),cast((isnull(a.Venta,0)) as money),1)+'|'+--converiertes a moneda y despues conviertes a texto
convert(varchar(50),cast(((isnull(b.Ganancia,0)/1.18))as money),1)+'|'+
convert(varchar(50),cast((isnull(b.Ganancia,0)-(cast((isnull(b.Ganancia,0)/1.18)as decimal(18,2))))as money),1)+'|'+   
convert(varchar(50),cast((isnull(b.Ganancia,0))as money),1)+'|'+ 
convert(varchar(50),cast((cast((isnull(a.Venta,0)* 0.01) as decimal(18,2)))as money),1)+'|'+   
convert(varchar(50),cast((isnull(a.Descuento,0))as money),1)+'|'+   
convert(varchar(50),cast(((cast((isnull(b.Ganancia,0)-(cast((isnull(b.Ganancia,0)/1.18)as decimal(18,2))))as decimal(18,2))+  
cast((isnull(a.Venta,0)* 0.01) as decimal(18,2)))+isnull(a.Descuento,0))as money),1)+'|'+   
convert(varchar(50),cast((isnull(b.Ganancia,0)-((cast((isnull(b.Ganancia,0)-(cast((isnull(b.Ganancia,0)/1.18)as decimal(18,2))))as decimal(18,2))+cast((isnull(a.Venta,0)* 0.01) as decimal(18,2)))+isnull(a.Descuento,0)))as money),1)
from   
(  
	select n.NotaUsuario as Usuario,COUNT(ClienteId) as Cliente,SUM(n.NotaPagar) as Venta,SUM(n.NotaDescuento) as Descuento  
	from NotaPedido n (NOLOCK) 
	where (
		month(n.NotaFecha)=@Mes and
		YEAR(n.NotaFecha)=@ANNO) and
		n.NotaEstado='CANCELADO'
	group by n.NotaUsuario)a  
	FULL join(
	select n.NotaUsuario as Usuario,cast(Sum((d.DetallePrecio - d.DetalleCosto) * d.DetalleCantidad)as decimal(18,2)) as Ganancia  --ok
	from DetallePedido d (NOLOCK) 
	inner join NotaPedido n  (NOLOCK) 
	on n.NotaId=d.NotaId
	where (month(n.NotaFecha)=@Mes and 
	YEAR(n.NotaFecha)=@ANNO) and 
	n.NotaEstado='CANCELADO'  
	group by n.NotaUsuario  
)b on a.Usuario=b.Usuario  
group by a.Usuario,b.Usuario,a.Cliente,a.Venta,a.Descuento,b.Ganancia  
order by a.Cliente desc 
for xml path('')),1,1,'')),'~') 
end
GO

IF OBJECT_ID(N'dbo.spPrueba', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[spPrueba] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[spPrueba]
as
begin
select 
'Codigo|Descipcion|Stock|UM|Costo|Dolar¬130|470|105|105|105|105¬String|String|Decimal|String|Decimal|Decimal¬'+
(select STUFF((select'¬'+p.ProductoCodigo+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
CONVERT(VarChar(50), cast(p.ProductoCantidad as money ), 1)+'|'+
p.ProductoUM+'|'+CONVERT(VarChar(50), cast(p.ProductoCosto as money ), 1)+'|'+CONVERT(VarChar(50), cast(p.ProductoCostoDolar as money ), 1)
from Producto p
where p.ProductoCantidad < = p.ValorCritico
order by p.ProductoNombre+' '+p.ProductoMarca asc
for xml path('')),1,1,''))
end
GO

IF OBJECT_ID(N'dbo.TipoCambioFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[TipoCambioFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[TipoCambioFecha] 
@fechainicio date,
@fechafin date
as
begin
select
'ID|Fecha|COMPRA|VENTA|EMPRESA¬90|110|108|108|117¬String|String|String|String|String¬'+
(select STUFF((select '¬'+ convert(varchar,t.IdTipo),+'|'+
(Convert(char(10),t.TipoFecha,103))+'|'+convert(varchar,t.TipoCompra)+'|'+
convert(varchar,t.TipoVenta)+'|'+
convert(varchar,t.TipoEmpresa) 
from TipoCambio t 
where t.TipoFecha BETWEEN @fechainicio AND @fechafin 
order by t.TipoFecha asc
for xml path('')),1,1,''))
end
GO

IF OBJECT_ID(N'dbo.totalLetras', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[totalLetras] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[totalLetras] @numero decimal(18,2),@Moneda varchar(60)
as
begin
select dbo.letras(@numero,@Moneda) as letras
end
GO

IF OBJECT_ID(N'dbo.traerProducto', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[traerProducto] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[traerProducto] 
@codigo varchar(80)
as
begin
SELECT top 1 p.IdProducto,l.NombreLinea,s.NombreSublinea,p.ProductoCodigo,p.ProductoNombre,
p.ProductoMarca,p.ProductoNombre+' '+p.ProductoMarca as Descripcion,p.ProductoCantidad, 
p.ProductoUM,p.ProductoVenta,p.ProductoINV,p.ProductoCosto,
a.AlmacenNombre,p.ProductoUbicacion,p.ProductoObs,p.ProductoEstado,
p.ProductoUsuario,p.ProductoFecha,p.ProductoImagen,
p.ProductoPV,p.ProductoSV,p.ValorCritico,p.ProductoxCaja,p.AplicaFB
FROM Producto p
INNER JOIN Sublinea s
ON p.IdSubLinea =s.IdSubLinea 
INNER JOIN Linea l
ON s.IdLinea =l.IdLinea 
INNER JOIN Almacen a
ON p.AlmacenId =a.AlmacenId
where p.ProductoCodigo=@codigo
order by p.IdProducto desc
end
GO

IF OBJECT_ID(N'dbo.upsEliminaGuiaInterna', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[upsEliminaGuiaInterna] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[upsEliminaGuiaInterna]              
@ListaOrden varchar(Max)              
as              
begin              
Declare @pos int              
Declare @orden varchar(max)              
Declare @detalle varchar(max)              
Set @pos = CharIndex('[',@ListaOrden,0)              
Set @orden = SUBSTRING(@ListaOrden,1,@pos-1)              
Set @detalle = SUBSTRING(@ListaOrden,@pos+1,len(@ListaOrden)-@pos)              
declare @p1 int,@p2 int,@p3 int,      
        @p4 int,@p5 int,@p6 int,@p7 int,      
        @p8 int,@p9 int           
             
declare @GuiaId numeric(38),@Usuario varchar(80),            
        @Concepto nvarchar(1),@Numero nvarchar(20),      
        @Destino varchar(300),@CodigoDXN varchar(80),      
        @NroTransaccion varchar(250),@Serie nvarchar(4),  
        @GuiaIdB varchar(38)        
              
Set @orden= LTRIM(RTrim(@orden))              
Set @p1 = CharIndex('|',@orden,0)            
Set @p2 = CharIndex('|',@orden,@p1+1)      
Set @p3 = CharIndex('|',@orden,@p2+1)      
Set @p4 = CharIndex('|',@orden,@p3+1)      
Set @p5 = CharIndex('|',@orden,@p4+1)      
Set @p6 = CharIndex('|',@orden,@p5+1)      
Set @p7 = CharIndex('|',@orden,@p6+1)  
Set @p8 = CharIndex('|',@orden,@p7+1)                
Set @p9 = Len(@orden)+1      
             
Set @GuiaId=convert(numeric(38),SUBSTRING(@orden,1,@p1-1))              
Set @Usuario=SUBSTRING(@orden,@p1+1,@p2-@p1-1)            
Set @Concepto=SUBSTRING(@orden,@p2+1,@p3-@p2-1)      
Set @Numero=SUBSTRING(@orden,@p3+1,@p4-@p3-1)       
Set @Destino=SUBSTRING(@orden,@p4+1,@p5-@p4-1)       
Set @CodigoDXN=SUBSTRING(@orden,@p5+1,@p6-@p5-1)      
Set @NroTransaccion=SUBSTRING(@orden,@p6+1,@p7-@p6-1)      
Set @Serie=SUBSTRING(@orden,@p7+1,@p8-@p7-1)  
Set @GuiaIdB=SUBSTRING(@orden,@p8+1,@p9-@p8-1)             
             
Begin Transaction              
            
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')               
Open Tabla              
Declare @Columna varchar(max),              
  @IdProducto numeric(20),              
  @Cantidad decimal(18,2),              
  @Costo decimal(18,4),                     
             
  @IniciaStock decimal(18,2),              
  @StockFinal decimal(18,2)              
            
Declare @pos1 int,    
        @pos2 int,@pos3 int--,@pos4 int          
             
Fetch Next From Tabla INTO @Columna              
 While @@FETCH_STATUS = 0              
 Begin          
               
Set @pos1 = CharIndex('|',@Columna,0)              
Set @pos2 = CharIndex('|',@Columna,@pos1+1)                  
Set @pos3 = Len(@Columna)+1            
            
Set @IdProducto=Convert(numeric(38),SUBSTRING(@Columna,1,@pos1-1))              
Set @Cantidad=Convert(decimal(18,2),SUBSTRING(@Columna,@pos1+1,@pos2-(@pos1+1)))              
Set @Costo=Convert(decimal(18,2),SUBSTRING(@Columna,@pos2+1,@pos3-(@pos2+1)))       
           
 if(@Concepto='S')            
 begin            
             
 set @IniciaStock=(select top 1 ProductoCantidad from Producto where IdProducto=@IdProducto)              
 set @StockFinal=@IniciaStock-@Cantidad            
               
 insert into Kardex values(@IdProducto,GETDATE(),'Salida Por Anulacion Guia Interna',@Numero,@IniciaStock,              
 0,@Cantidad,@Costo,@StockFinal,'SALIDA',@Usuario,          
@Destino,@CodigoDXN,@NroTransaccion,'102',@Serie,'01','S','','','E')             
               
 update producto               
 set  ProductoCantidad =ProductoCantidad - @Cantidad              
 where IDProducto=@IdProducto            
               
 end            
 else            
 begin            
             
 set @IniciaStock=(select top 1 ProductoCantidad from Producto where IdProducto=@IdProducto)              
 set @StockFinal=@IniciaStock+@Cantidad            
               
 insert into Kardex values(@IdProducto,GETDATE(),'Ingreso Por Anulacion Guia Interna',@Numero,@IniciaStock,              
 @Cantidad,0,@Costo,@StockFinal,'INGRESO',@Usuario,          
@Destino,@CodigoDXN,@NroTransaccion,'103',@Serie,'02','S','','','E')            
               
 update producto               
 set  ProductoCantidad =ProductoCantidad + @Cantidad              
 where IDProducto=@IdProducto    
              
END         
          
Fetch Next From Tabla INTO @Columna              
end              
 Close Tabla;              
 Deallocate Tabla;  
   
 delete from DetalleGuiaInterna            
 where GuiaId=@GuiaId            
   
 delete from GuiaInternaSI            
 where GuiaId=@GuiaId  
   
 if(@Concepto='S')  
 begin  
 if(len(@GuiaIdB)>0)  
 begin  
 update GuiaInternaSI  
 set Estado='P'  
 where GuiaId=@GuiaIdB  
 end  
 end                     
 Commit Transaction;              
 select 'true'              
end
GO

IF OBJECT_ID(N'dbo.upsInsertaTemGuiaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[upsInsertaTemGuiaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[upsInsertaTemGuiaB]      
@Data varchar(max)        
as        
begin        
Declare @pos1 int,@pos2 int,        
  @pos3 int,@pos4 int,        
     @pos5 int,@pos6 int,  
     @pos7 int        
        
Declare @UsuarioID int,@IdProducto numeric(20),      
@UnidadM varchar(80),@Cantidad decimal(18,2),      
@PrecioVenta decimal(18,2),@Importe decimal(18,2),  
@Concepto nvarchar(1)  
      
Set @Data = LTRIM(RTrim(@Data))        
Set @pos1 = CharIndex('|',@Data,0)      
Set @pos2 = CharIndex('|',@Data,@pos1+1)      
Set @pos3 = CharIndex('|',@Data,@pos2+1)          
Set @pos4 = CharIndex('|',@Data,@pos3+1)  
Set @pos5 = CharIndex('|',@Data,@pos4+1)          
Set @pos6 = CharIndex('|',@Data,@pos5+1)      
Set @pos7 = Len(@Data)+1       
      
Set @UsuarioID=convert(int,SUBSTRING(@Data,1,@pos1-1))        
Set @IdProducto=convert(numeric(20),SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1))        
Set @Cantidad=convert(decimal(18,2),SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1))       
Set @UnidadM=SUBSTRING(@Data,@pos3+1,@pos4-@pos3-1)  
Set @PrecioVenta=convert(decimal(18,2),SUBSTRING(@Data,@pos4+1,@pos5-@pos4-1))  
Set @Importe=convert(decimal(18,2),SUBSTRING(@Data,@pos5+1,@pos6-@pos5-1))  
Set @Concepto=SUBSTRING(@Data,@pos6+1,@pos7-@pos6-1)      
      
insert into TemporalGuiaB values(@UsuarioID,@IdProducto,      
@Cantidad,@UnidadM,@PrecioVenta,@Importe,@Concepto)      
       
select 'true'        
        
end
GO

IF OBJECT_ID(N'dbo.usp_DeleteOldBackupFiles', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usp_DeleteOldBackupFiles] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usp_DeleteOldBackupFiles] 
    @path NVARCHAR(256),--RUTA DEL ARCHIVO
	@extension NVARCHAR(10),--EXTENSION DEL ARCHIVO
	@age_hrs INT--el número de horas que tiene que envejecer 
	--un archivo de respaldo para ser eliminado.
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @DeleteDate NVARCHAR(50)
	DECLARE @DeleteDateTime DATETIME

	SET @DeleteDateTime = DateAdd(hh, - @age_hrs, GetDate())
    SET @DeleteDate = (Select Replace(Convert(nvarchar, @DeleteDateTime, 111), '/', '-') 
    + 'T' + Convert(nvarchar, @DeleteDateTime, 108))

	EXECUTE master.dbo.xp_delete_file 0,
		@path,
		@extension,
		@DeleteDate,--
		1
END
GO

IF OBJECT_ID(N'dbo.uspAcuentaPuntos', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspAcuentaPuntos] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspAcuentaPuntos]
@NotaId varchar(38)
as
begin
Declare @Acuenta decimal(18,2)
set @Acuenta=isnull((select sum(d.Acuenta)
from DetallesPVS d
where NotaId=@NotaId),0)
select
isnull((select STUFF((select '¬'+ d.NroTransaccion+'  S/ '+
CONVERT(VarChar(50), cast(d.Acuenta as money ), 1)
from DetallesPVS d
where NotaId=@NotaId
order by d.DetalleId desc 
FOR XML PATH('')),1,1,'')),'~')+'['+
CONVERT(VarChar(50), cast(@Acuenta as money ), 1)
end
GO

IF OBJECT_ID(N'dbo.uspAsistenciaDia', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspAsistenciaDia] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspAsistenciaDia]
@fechainicio date,
@fechafin date
as
Begin
select 
'Id|Fecha|Dia|PersonalId|Nombres|HoraIngreso|IngresoRefrigerio|RetornoRefrigerio|HoraSalida|NroMar|HoraING|HoraREF|NroTardanza¬90|100|100|100|220|125|125|125|125|70|90|90|100¬String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+Convert(varchar,a.Id)+'|'+
convert(varchar,a.Fecha,103)+'|'+dbo.diaNombre(a.Fecha)+'|'+
Convert(varchar,a.PersonalId)+'|'+
(((SUBSTRING(p.PersonalNombres+' ',1,CHARINDEX(' ',p.PersonalNombres+' ')-1)))+' '+ ((SUBSTRING(p.PersonalApellidos+' ',1,CHARINDEX(' ',p.PersonalApellidos+' ')-1))))+'|'+
isnull(SUBSTRING(convert(varchar,a.HoraIngreso,114),1,8),'')+'|'+
isnull(SUBSTRING(convert(varchar,a.SalidaRefrigerio,114),1,8),'')+'|'+
isnull(SUBSTRING(convert(varchar,a.IngresoRefrigerio,114),1,8),''),''+'|'+
isnull(SUBSTRING(convert(varchar,a.HoraSalida,114),1,8),'')+'|'+
Convert(varchar,a.NroMarcacion)+'|'+
a.Estado+'|'+
case when (convert(time,a.IngresoRefrigerio) > DATEADD(minute,60,(convert(time,a.SalidaRefrigerio)))) then
'T' else 'A' end+'|'+convert(varchar,a.NroTardanza)
from Asistencia a
inner join Personal p
on p.PersonalId=a.PersonalId
where Convert(char(10),a.Fecha,101) BETWEEN @fechainicio AND @fechafin
order by a.Fecha asc
for XMl path('')),1,1,'')),'~')
End
GO

IF OBJECT_ID(N'dbo.uspAsistenciaInsertaCsv', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspAsistenciaInsertaCsv] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspAsistenciaInsertaCsv]
@PersonalId int
as
Begin
Declare @Data varchar(max)
Declare @NroMarca int,
        @Id numeric(38)
Declare @p1 int,@p2 int
IF NOT EXISTS(select a.PersonalId  from Asistencia a
where a.PersonalId=@PersonalId and a.Fecha=convert(date,GETDATE()))
begin

Declare @DiaActual nvarchar(20)
Declare @HoraIngreso time(7)
set @DiaActual=(select dbo.diaNombre(getdate()))
set @HoraIngreso=isnull((select t.Turno from DetalleTurnos d
inner join Turnos t
on t.TurnoId=d.TurnoId
where d.PersonalId=@PersonalId and d.Dia=@DiaActual),'08:00:00')

Declare @DetalleId numeric(38)
Declare @Aviso nvarchar(1)
Declare @NroTardanza int
declare @UltimoNro int
set @UltimoNro=isnull((select top 1 a.NroTardanza from Asistencia a
where a.PersonalId=@PersonalId and Month(a.Fecha)=MONTH(GETDATE()) and YEAR(a.Fecha)=year(getdate())
order by a.Id desc),0)
insert into Asistencia values(GETDATE(),@PersonalId,GETDATE(),null,null,null,1,'',@UltimoNro,'A')
set @DetalleId=(select @@IDENTITY)
set @Aviso=isnull((
select top 1 case when(convert(time,a.HoraIngreso) > @HoraIngreso) then
'T' else 'A' end 
from Asistencia a
inner join Personal p
on p.PersonalId=a.PersonalId
where a.PersonalId=@PersonalId and 
Month(a.Fecha)=MONTH(GETDATE()) and YEAR(a.Fecha)=year(getdate()) and a.Id=@DetalleId
order by a.Id desc),'A')
if(@Aviso='T')
begin
update Asistencia
set NroTardanza=@UltimoNro+1,Estado='T'
where Id=@DetalleId
end
Select 'true'
end
else
begin
set @Data=(select convert(varchar,a.Id)+'|'+convert(varchar,a.NroMarcacion) 
from Asistencia a
where a.PersonalId=@PersonalId and a.Fecha=convert(date,GETDATE()))
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = Len(@Data)+1
Set @Id=convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
Set @NroMarca=convert(numeric(20),SUBSTRING(@Data,@p1+1,@p2-@p1-1))
if(@NroMarca=1)
begin
update Asistencia
set SalidaRefrigerio=GETDATE(),NroMarcacion=2
where Id=@Id
select 'R1'
end
else if(@NroMarca=2)
begin
update Asistencia
set IngresoRefrigerio=GETDATE(),NroMarcacion=3
where Id=@Id
select 'R2'
end
else if(@NroMarca=3)
begin
update Asistencia
set HoraSalida=GETDATE(),NroMarcacion=4
where Id=@Id
select 'S'
end
else
begin
select 'completo'
end
end
end
GO

IF OBJECT_ID(N'dbo.uspAsistenciaListaCsv', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspAsistenciaListaCsv] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspAsistenciaListaCsv]
as
Begin
select 
'Id|Fecha|PersonalId|Nombres|HoraIngreso|IngresoRefrigerio|RetornoRefrigerio|HoraSalida|NroMar|HoraING|HoraREF¬90|100|100|220|125|125|125|125|70|90|90¬String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+Convert(varchar,a.Id)+'|'+
convert(varchar,a.Fecha,103)+'|'+
Convert(varchar,a.PersonalId)+'|'+
(((SUBSTRING(p.PersonalNombres+' ',1,CHARINDEX(' ',p.PersonalNombres+' ')-1)))+' '+ ((SUBSTRING(p.PersonalApellidos+' ',1,CHARINDEX(' ',p.PersonalApellidos+' ')-1))))+'|'+
isnull(SUBSTRING(convert(varchar,a.HoraIngreso,114),1,8),'')+'|'+
isnull(SUBSTRING(convert(varchar,a.SalidaRefrigerio,114),1,8),'')+'|'+
isnull(SUBSTRING(convert(varchar,a.IngresoRefrigerio,114),1,8),''),''+'|'+
isnull(SUBSTRING(convert(varchar,a.HoraSalida,114),1,8),'')+'|'+
Convert(varchar,a.NroMarcacion)+'|'+a.Estado+'|'+
case when (convert(time,a.IngresoRefrigerio) > DATEADD(minute,60,(convert(time,a.SalidaRefrigerio)))) then
'T' else 'A' end
from Asistencia a
inner join Personal p
on p.PersonalId=a.PersonalId
where DAY(a.Fecha)=DAY(GETDATE())and Month(a.Fecha)=Month(GETDATE())and year(a.Fecha)=YEAR(Getdate())
order by a.Id desc
for XMl path('')),1,1,'')),'~')
End
GO

IF OBJECT_ID(N'dbo.uspAsistenciaListaCsvB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspAsistenciaListaCsvB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspAsistenciaListaCsvB]
@Data date
as
Begin
select 
'Id|Fecha|PersonalId|Nombres|HoraIngreso|IngresoRefrigerio|RetornoRefrigerio|HoraSalida|NroMar|HoraING|HoraREF|CantidadTar¬90|100|100|220|125|125|125|125|70|90|90|90¬String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+Convert(varchar,a.Id)+'|'+
convert(varchar,a.Fecha,103)+'|'+
Convert(varchar,a.PersonalId)+'|'+
(((SUBSTRING(p.PersonalNombres+' ',1,CHARINDEX(' ',p.PersonalNombres+' ')-1)))+' '+ ((SUBSTRING(p.PersonalApellidos+' ',1,CHARINDEX(' ',p.PersonalApellidos+' ')-1))))+'|'+
isnull(SUBSTRING(convert(varchar,a.HoraIngreso,114),1,8),'')+'|'+
isnull(SUBSTRING(convert(varchar,a.SalidaRefrigerio,114),1,8),'')+'|'+
isnull(SUBSTRING(convert(varchar,a.IngresoRefrigerio,114),1,8),''),''+'|'+
isnull(SUBSTRING(convert(varchar,a.HoraSalida,114),1,8),'')+'|'+
Convert(varchar,a.NroMarcacion)+'|'+case when(a.Estado='T') then
'TARDANZA' else 'ASISTIO' end+'|'+
case when (convert(time,a.IngresoRefrigerio) > DATEADD(minute,60,(convert(time,a.SalidaRefrigerio)))) then
'T' else 'A' end+'|'+CONVERT(varchar,a.NroTardanza)
from Asistencia a
inner join Personal p
on p.PersonalId=a.PersonalId
inner join Usuarios u
on u.PersonalId=p.PersonalId
where a.Fecha=@Data and u.Administrador=0
order by a.Id desc
for XMl path('')),1,1,'')),'~')
End
GO

IF OBJECT_ID(N'dbo.uspAsistenciaPersonal', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspAsistenciaPersonal] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspAsistenciaPersonal]
@Id numeric(20),
@fechainicio date,
@fechafin date
as
Begin
select 
'Id|Fecha|Dia|PersonalId|Nombres|HoraIngreso|IngresoRefrigerio|RetornoRefrigerio|HoraSalida|NroMar|HoraING|HoraREF|NroTardanza¬90|100|100|100|220|125|125|125|125|70|90|90|100¬String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+Convert(varchar,a.Id)+'|'+
convert(varchar,a.Fecha,103)+'|'+dbo.diaNombre(a.Fecha)+'|'+
Convert(varchar,a.PersonalId)+'|'+
(((SUBSTRING(p.PersonalNombres+' ',1,CHARINDEX(' ',p.PersonalNombres+' ')-1)))+' '+ ((SUBSTRING(p.PersonalApellidos+' ',1,CHARINDEX(' ',p.PersonalApellidos+' ')-1))))+'|'+
isnull(SUBSTRING(convert(varchar,a.HoraIngreso,114),1,8),'')+'|'+
isnull(SUBSTRING(convert(varchar,a.SalidaRefrigerio,114),1,8),'')+'|'+
isnull(SUBSTRING(convert(varchar,a.IngresoRefrigerio,114),1,8),''),''+'|'+
isnull(SUBSTRING(convert(varchar,a.HoraSalida,114),1,8),'')+'|'+
Convert(varchar,a.NroMarcacion)+'|'+
a.Estado+'|'+
case when (convert(time,a.IngresoRefrigerio) > DATEADD(minute,60,(convert(time,a.SalidaRefrigerio)))) then
'T' else 'A' end+'|'+convert(varchar,a.NroTardanza)
from Asistencia a
inner join Personal p
on p.PersonalId=a.PersonalId
where a.PersonalId=@Id and (Convert(char(10),a.Fecha,101) BETWEEN @fechainicio AND @fechafin)
order by a.Fecha asc
for XMl path('')),1,1,'')),'~')
End
GO

IF OBJECT_ID(N'dbo.uspBuscarApertura', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspBuscarApertura] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspBuscarApertura]
@IdApertura numeric(38)
as
begin
select
'Id|Codigo|Descripcion¬100|120|380¬String|String|String¬'+
isnull((select STUFF ((select '¬'+
convert(varchar,p.IdProducto)+'|'+p.ProductoCodigo+'|'+
p.ProductoMarca+' '+p.ProductoNombre
from Producto p
where (p.ProductoEstado='BUENO' and p.IdSubLinea=1) and p.IdProducto NOT IN (SELECT IdProducto FROM 
DetalleApertura where IdApertura=@IdApertura)
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspCajaInsertaCsv', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspCajaInsertaCsv] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspCajaInsertaCsv]      
@Data varchar(max)      
as      
Begin      
Declare @p1 int,@p2 int,@p3 int,      
        @p4 int,@p5 int,@p6 int,      
        @p7 int,@p8 int,@p9 int,      
        @p10 int,@p11 int,@p12 int      
Declare @CajaId  numeric(38),@CajaCierre  varchar(40),      
        @MontoIniSOl  decimal(18,2),@CajaEncargado  varchar(60),      
        @CajaUsuario  varchar(60),@CajaEstado  varchar(40),@CajaIngresos  decimal(18,2),      
        @CajaDeposito  decimal(18,2),@CajaSalidas  decimal(18,2),@CajaTotal  decimal(18,2),      
        @UsuarioId  int,@CantCajas int,@SerieFactura varchar(10),@Asistencia int,      
        @Observacion varchar(max)      
Set @Data = LTRIM(RTrim(@Data))      
Set @p1 = CharIndex('|',@Data,0)      
Set @p2=CharIndex('|',@Data,@p1+1)      
Set @p3=CharIndex('|',@Data,@p2+1)      
Set @p4=CharIndex('|',@Data,@p3+1)      
Set @p5=CharIndex('|',@Data,@p4+1)      
Set @p6=CharIndex('|',@Data,@p5+1)      
Set @p7=CharIndex('|',@Data,@p6+1)      
Set @p8=CharIndex('|',@Data,@p7+1)      
Set @p9=CharIndex('|',@Data,@p8+1)      
Set @p10=CharIndex('|',@Data,@p9+1)      
Set @p11=CharIndex('|',@Data,@p10+1)      
Set @p12= Len(@Data)+1      
Set @CajaId=convert(numeric(38),SUBSTRING(@Data,1,@p1-1))      
Set @CajaCierre=SUBSTRING(@Data,@p1+1,@p2-@p1-1)      
Set @MontoIniSOl=convert(decimal(18,2),SUBSTRING(@Data,@p2+1,@p3-@p2-1))      
Set @CajaEncargado=SUBSTRING(@Data,@p3+1,@p4-@p3-1)      
Set @CajaUsuario=SUBSTRING(@Data,@p4+1,@p5-@p4-1)      
Set @CajaEstado=SUBSTRING(@Data,@p5+1,@p6-@p5-1)      
Set @CajaIngresos=convert(decimal(18,2),SUBSTRING(@Data,@p6+1,@p7-@p6-1))      
Set @CajaDeposito=convert(decimal(18,2),SUBSTRING(@Data,@p7+1,@p8-@p7-1))      
Set @CajaSalidas=convert(decimal(18,2),SUBSTRING(@Data,@p8+1,@p9-@p8-1))      
Set @CajaTotal=convert(decimal(18,2),SUBSTRING(@Data,@p9+1,@p10-@p9-1))      
Set @UsuarioId=convert(int,SUBSTRING(@Data,@p10+1,@p11-@p10-1))      
Set @Observacion=SUBSTRING(@Data,@p11+1,@p12-@p11-1)      
--Declare @FechaAyer date      
--Declare @Dia varchar(20)      
--Declare @Arqueo int      
--set @FechaAyer=(SELECT DATEADD(DAY,-1,convert(date,GETDATE())))      
--set @Dia=(select dbo.diaNombre(@FechaAyer))      
--if(@Dia='DOMINGO')      
--begin      
--set @FechaAyer=(SELECT DATEADD(DAY,-2,convert(date,GETDATE())))      
--end      
--set @Arqueo=(select top 1 Count(FechaConteo) from ConteoMonedas      
--where FechaConteo=@FechaAyer)      
--if(@Arqueo=0)      
--begin      
--set @Arqueo=(select top 1 Count(Fecha) from Feriados      
--where Fecha=@FechaAyer)      
--end      
--if(@Arqueo=0)      
--begin      
--Select 'NO ARQUEO'      
--end      
--else      
--begin      
if(@CajaId=0)      
begin      
--Declare @DataAsis varchar(80)      
--Declare @Tardanza nvarchar(1),      
--        @OBS varchar(max),      
--        @NroTardanza int      
--Declare @pos1 int,@pos2 int,      
--        @pos3 int,@pos4 int             
--set @DataAsis=isnull((select top 1 convert(varchar,COUNT(a.PersonalId))+'|'+      
--a.Estado+'|'+a.Observaciones+'|'+convert(varchar,a.NroTardanza)      
--from Asistencia a      
--inner join Usuarios u      
--on u.PersonalId=a.PersonalId      
--inner join Personal p      
--on p.PersonalId=u.PersonalId      
--where u.UsuarioID=@UsuarioId and a.Fecha=convert(date,GETDATE())      
--group by a.HoraIngreso,a.Estado,a.Observaciones,a.NroTardanza),'0|||0')      
--Set @DataAsis= LTRIM(RTrim(@DataAsis))      
--Set @pos1 = CharIndex('|',@DataAsis,0)      
--Set @pos2 = CharIndex('|',@DataAsis,@pos1+1)      
--Set @pos3 = CharIndex('|',@DataAsis,@pos2+1)      
--Set @pos4= Len(@DataAsis)+1      
--Set @Asistencia=convert(int,SUBSTRING(@DataAsis,1,@pos1-1))      
--Set @Tardanza=SUBSTRING(@DataAsis,@pos1+1,@pos2-@pos1-1)      
--Set @OBS=SUBSTRING(@DataAsis,@pos2+1,@pos3-@pos2-1)      
--Set @NroTardanza=convert(int,SUBSTRING(@DataAsis,@pos3+1,@pos4-@pos3-1))      
--if(@Asistencia=0)      
--begin      
--Select 'NO ASISTIO'      
--end      
--else      
--begin      
--if(@Tardanza='T' and @OBS='')      
--begin      
--select '['+convert(varchar,@NroTardanza)+']'      
--end      
--else      
--begin      
IF EXISTS(select top 1 CajaId from Caja where CajaEstado='ACTIVO' and UsuarioId=@UsuarioId order by 1 desc)      
begin      
select 'existe'      
end      
else      
begin      
set @CantCajas=(select convert(varchar,count(u.UsuarioID))from Caja c      
inner join Usuarios u      
on u.UsuarioID=c.UsuarioId      
where CajaEstado='ACTIVO')      
if(@CantCajas>=5)      
begin      
select 'NO CERRO'      
end      
else      
begin      
insert into Caja values(GETDATE(),@CajaCierre,@MontoIniSOl,      
@CajaEncargado,@CajaUsuario,@CajaEstado,@CajaIngresos,@CajaDeposito,      
@CajaSalidas,@CajaTotal,@UsuarioId,@Observacion)      
set @CajaId=@@identity      
insert into CajaDetalle values(@CajaId,GETDATE(),0,'INGRESO','TOTAL EFECTIVO',0,0,0,'','T','V',0,'','','','')      
insert into CajaDetalle values(@CajaId,GETDATE(),0,'INGRESO','VITRINA',0,0,0,'','D','V',0,'','','','')      
insert into CajaDetalle values(@CajaId,GETDATE(),0,'INGRESO','SENCILLO',0,0,0,'','T','V',0,'','','','')      
insert into CajaDetalle values(@CajaId,GETDATE(),0,'INGRESO','IOC',0,0,0,'','T','V',0,'','','','')      
insert into CajaDetalle values(@CajaId,GETDATE(),0,'INGRESO','REVISTAS',0,0,0,'','D','V',0,'','','','')      
insert into CajaDetalle values(@CajaId,GETDATE(),0,'INGRESO','COPIAS Y OTROS',0,0,0,'','D','V',0,'','','','')      
insert into Monedas values(0,0,'200.00',0,'B',@CajaId)      
insert into Monedas values(0,0,'100.00',0,'B',@CajaId)      
insert into Monedas values(0,0,'50.00',0,'B',@CajaId)      
insert into Monedas values(0,0,'20.00',0,'B',@CajaId)      
insert into Monedas values(0,0,'10.00',0,'B',@CajaId)      
insert into Monedas values(0,0,'5.00',0,'M',@CajaId)      
insert into Monedas values(0,0,'2.00',0,'M',@CajaId)      
insert into Monedas values(0,0,'1.00',0,'M',@CajaId)      
insert into Monedas values(0,0,'0.50',0,'M',@CajaId)      
insert into Monedas values(0,0,'0.20',0,'M',@CajaId)      
insert into Monedas values(0,0,'0.10',0,'M',@CajaId)      
Select 'true'      
end      
end      
end      
--end      
--end      
else      
begin      
if(@CajaEstado='CERRADA')      
begin      
Declare @Descripcion varchar(max)      
set @Descripcion=isnull((select top 1 d.DetalleConcepto + ' TOTAL S/ '+CONVERT(varChar(max),cast(d.DetalleMonto as money ), 1)      
from CajaDetalle d      
where d.RutaImagen like '%file.png%' and(d.CajaId=@CajaId and d.NotaId=0 and d.DetalleMonto>=500000)      
order by d.DetalleId asc),'0')      
if(@Descripcion='0')      
begin      
update Caja      
set CajaCierre=@CajaCierre,MontoIniSOl=@MontoIniSOl,      
CajaEncargado=@CajaEncargado,CajaUsuario=@CajaUsuario,      
CajaEstado=@CajaEstado,CajaIngresos=@CajaIngresos,CajaDeposito=@CajaDeposito,      
CajaSalidas=@CajaSalidas,CajaTotal=@CajaTotal,UsuarioId=@UsuarioId,      
observacion=@Observacion      
where CajaId=@CajaId      
Select 'true'      
end      
else      
begin      
select 'Falta Adjuntar el Archivo de: '+@Descripcion      
end      
end      
else      
begin      
update Caja      
set CajaCierre=@CajaCierre,MontoIniSOl=@MontoIniSOl,      
CajaEncargado=@CajaEncargado,CajaUsuario=@CajaUsuario,      
CajaEstado=@CajaEstado,CajaIngresos=@CajaIngresos,CajaDeposito=@CajaDeposito,      
CajaSalidas=@CajaSalidas,CajaTotal=@CajaTotal,UsuarioId=@UsuarioId,      
observacion=@Observacion      
where CajaId=@CajaId      
Select 'true'      
end      
end      
end      
--end
GO

IF OBJECT_ID(N'dbo.uspCantidadLiquidacion', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspCantidadLiquidacion] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspCantidadLiquidacion]
@NotaId nvarchar(40)
as
begin
declare @count int 
declare @guiaEntrega int
declare @total int
set @count =
isnull((select COUNT(*)from DetaLiquidaVenta 
where NotaId =@NotaId), 0)
set @guiaEntrega=isnull((
select COUNT(*) from GuiaLiquidacion
where NotaId =@NotaId), 0)
set @total=@count+@guiaEntrega
select convert(varchar,@total)
end
GO

IF OBJECT_ID(N'dbo.uspComboDocumentos', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspComboDocumentos] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspComboDocumentos]
@CodigoRes varchar(80)
as
begin
select n.NotaId,n.NotaSerie+'-'+n.NotaNumero as Documento
from NotaPedido n
inner join DetallePedido d
on d.NotaId=n.NotaId
where d.cantidadSaldo>0 and 
n.CodigoRes=@CodigoRes and (n.NotaEstado<>'ANULADO' and n.NotaEntrega='POR ENTREGAR')
group by n.NotaId,n.NotaSerie+'-'+n.NotaNumero
order by n.NotaId desc
end
GO

IF OBJECT_ID(N'dbo.uspComboGuiasCredito', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspComboGuiasCredito] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspComboGuiasCredito]    
@CodigoRes varchar(80)    
as    
begin    
select g.GuiaId as GuiaId,g.Serie+'-'+g.Numero as Documento    
from GuiaInternaSI g  
inner join DetalleGuiaInterna d    
on d.GuiaId=g.GuiaId    
--where d.cantidadSaldo>0 and     
where g.CodigoDXN=@CodigoRes and g.Estado='P'  
group by g.GuiaId,g.Serie+'-'+g.Numero   
order by g.GuiaId desc    
end
GO

IF OBJECT_ID(N'dbo.uspConceptoOBSDetalle', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspConceptoOBSDetalle] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspConceptoOBSDetalle]
@Id varchar(40),
@fechainicio date,
@fechafin date
as
SELECT
'Codigo|Descripcion|Cantidad|Importe¬120|400|130|130¬String|String|String|String¬'+
isnull((select STUFF ((select '¬'+
p.ProductoCodigo+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
(convert(varchar(50), CAST(Sum(d.DetalleCantidad) as money),1))+'|'+
(convert(varchar(50), CAST(Sum(d.DetalleImporte) as money),1))
FROM NotaPedido n
inner join DetallePedido d
on d.NotaId=n.NotaId
inner join Producto p
on p.IdProducto=d.IdProducto
WHERE n.ConceptoOBS=@Id and(Convert(char(10),n.NotaFechaPago,101) 
BETWEEN @fechainicio AND @fechafin) and n.NotaEstado<>'ANULADO'
group by p.ProductoCodigo,p.ProductoNombre,p.ProductoMarca
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')+'['+
'Codigo|Descripcion|Cantidad|Importe¬120|400|130|130¬String|String|String|String¬'+
isnull((select STUFF ((select '¬'+
p.ProductoCodigo+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
(convert(varchar(50), CAST(Sum(d.DetalleCantidad) as money),1))+'|'+
(convert(varchar(50), CAST(Sum(d.DetalleImporte) as money),1))
FROM GuiaRemision g
inner join DetalleGuia d
on d.GuiaId=g.GuiaId
inner join Producto p
on p.IdProducto=d.IdProducto
WHERE g.GuiaMotivo=ltrim(Replace(@Id,'PUNTOS A ','')) and(Convert(char(10),g.Guiafecha,101) 
BETWEEN @fechainicio AND @fechafin)
group by p.ProductoCodigo,p.ProductoNombre,p.ProductoMarca
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')
GO

IF OBJECT_ID(N'dbo.uspConceptosOBS', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspConceptosOBS] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspConceptosOBS]
@Id varchar(40),
@fechainicio date,
@fechafin date
as
begin
SELECT
'Emision|Documento|NotaId|ConceptoOBS|Codigo|Cliente|Total|Usuario¬115|120|100|160|110|350|120|150¬String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+(Convert(char(10),n.NotaFechaPago,103))+'|'+
n.NotaSerie+'-'+n.NotaNumero+'|'+convert(varchar,n.NotaId)+'|'+
n.ConceptoOBS+'|'+c.ClienteCodigo+'|'+c.ClienteRazon+'|'+
(convert(varchar(50), CAST(n.NotaTotal as money),1))+'|'+n.NotaUsuario
FROM NotaPedido n
inner join Cliente c
on c.ClienteId=n.ClienteId
WHERE n.ConceptoOBS=@Id and(Convert(char(10),n.NotaFechaPago,101) BETWEEN @fechainicio AND @fechafin)
order by n.NotaId desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspConsultaDNI', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspConsultaDNI] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspConsultaDNI]
@DNI varchar(40)
as
begin
select  
isnull((select STUFF ((select top 1'¬'+
case when (len(c.ClienteCodigo)>0)then
c.ClienteCodigo
else '-'
end+'_'+
c.ClienteRazon+'_'+
case when (len(c.ClienteDni)>0)then
c.ClienteDni
else '-'end
from Cliente c
where c.ClienteDni=@DNI
order by c.ClienteId desc
for xml path('')),1,1,'')),'~') as Data--cerrar la cadena
end
GO

IF OBJECT_ID(N'dbo.uspCorregirKardex', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspCorregirKardex] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspCorregirKardex]    
@detalle varchar(Max)    
as    
begin    
Begin Transaction    
 Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')     
Open Tabla    
  Declare @Columna varchar(max),    
  @KardexId numeric(38),    
  @StockFinal decimal(18,2)    
  Declare @pos1 int    
  Declare @pos2 int    
 Fetch Next From Tabla INTO @Columna    
 While @@FETCH_STATUS = 0    
 Begin    
  Set @pos1 = CharIndex('|',@Columna,0)    
  Set @pos2 =Len(@Columna)+1   
  Set @KardexId=Convert(numeric(20),SUBSTRING(@Columna,1,@pos1-1))  
  Set @StockFinal= Convert(decimal(18,2),SUBSTRING(@Columna,@pos1+1,@pos2-(@pos1+1)))      
    
  update Producto    
  set UltimoINV=@StockFinal    
  where IdProducto=@KardexId    
   
 Fetch Next From Tabla INTO @Columna    
 End    
 Close Tabla;    
 Deallocate Tabla;    
 Commit Transaction;    
 Select 'true';    
end
GO

IF OBJECT_ID(N'dbo.uspCruzeOBS', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspCruzeOBS] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspCruzeOBS]
@Fecha date
as
begin
Declare @Cantidad int
set @Cantidad=(select COUNT(t.ID)
from TABLAOBS t
where t.FechaTransaccion=@Fecha)
if(@Cantidad=0)
begin
select '0[~'
--'Descripcion|CierreAyer|AperturaHoy|Validacion|Observacion¬100|100|100|100|100¬String|String|String|String|String¬'+
--isnull((select STUFF ((select '¬'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
--CONVERT(VarChar(50),cast(d.total-(d.Validacion)as money),1)+'|'+
--CONVERT(VarChar(50),cast(d.total as money ), 1)+'|'+
--CONVERT(VarChar(50),cast(d.Validacion as money ), 1)+'|'+
--case when (d.validacion >0)then
--'Sobra Producto'else 'Falta Producto'end
--from DetalleApertura d
--inner join Producto p
--on p.IdProducto=d.IdProducto
--inner join APERTURA_ALMACEN a
--on a.IdApertura=d.IdApertura
--where convert(date,FechaApertura)=@Fecha and Validacion<>0
--for xml path('')),1,1,'')),'~')+'['+
-- isnull((select STUFF((select top 1 '¬'+ 
-- CONVERT(VarChar(50), cast(a.ValorInventario-((a.BalanceApertura+a.Recepcion)-(a.CashBill+a.IOC))as money ), 1)--cuadre
-- from AperturaOBS a
-- where Month(a.Fecha)=Month(@Fecha) and YEAR(a.Fecha)=YEAR(@fecha)
-- order by a.Fecha desc
-- FOR XML PATH('')), 1, 1, '')),'0')
end
else
begin
select
'Transaccion|Codigo|Cliente|Importe¬80|110|200|110¬String|String|String|String¬'+
isnull((select STUFF ((select '¬'+
t.NotaTransaccion+'|'+
t.CodigoMiembro+'|'+t.NombreMiembro+'|'+
convert(VarChar,cast(t.Importe as money ), 1)
from TABLAOBS t
left join NotaPedido n
on n.NotaTransaccion=t.NotaTransaccion
where t.FechaTransaccion=@Fecha AND n.CajaId IS NULL
for xml path('')),1,1,'')),'~')+'[~'
--'Descripcion|CierreAyer|AperturaHoy|Validacion|Observacion¬100|100|100|100|100¬String|String|String|String|String¬'+
--isnull((select STUFF ((select '¬'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
--CONVERT(VarChar(50),cast(d.total-(d.Validacion)as money),1)+'|'+
--CONVERT(VarChar(50),cast(d.total as money ), 1)+'|'+
--CONVERT(VarChar(50),cast(d.Validacion as money ), 1)+'|'+
--case when (d.validacion >0)then
--'Sobra Producto'else 'Falta Producto'end
--from DetalleApertura d
--inner join Producto p
--on p.IdProducto=d.IdProducto
--inner join APERTURA_ALMACEN a
--on a.IdApertura=d.IdApertura
--where convert(date,FechaApertura)=@Fecha and Validacion<>0
--for xml path('')),1,1,'')),'~')+'['+
-- isnull((select STUFF((select top 1'¬'+
-- CONVERT(VarChar(50), cast(a.ValorInventario-((a.BalanceApertura+a.Recepcion)-(a.CashBill+a.IOC))as money ), 1)--cuadre
-- from AperturaOBS a
-- where Month(a.Fecha)=Month(@Fecha) and YEAR(a.Fecha)=YEAR(@fecha)
-- order by a.Fecha desc
-- FOR XML PATH('')), 1, 1, '')),'0')
end
end
GO

IF OBJECT_ID(N'dbo.uspCuentaProve', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspCuentaProve] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspCuentaProve]
@ProveedorId numeric(38)
as
select 
'Id|EntidadBancaria|TipoCuenta|Moneda|NroCuenta¬100|250|140|95|250¬String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+ CONVERT(varchar,c.CuentaId)+'|'+c.Entidad+'|'+
c.TipoCuenta+'|'+c.Moneda+'|'+c.NroCuenta
from CuentaProveedor c
where c.ProveedorId=@ProveedorId
order by c.CuentaId desc
for xml path('')),1,1,'')),'~')
GO

IF OBJECT_ID(N'dbo.uspDescontinuados', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspDescontinuados] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspDescontinuados]
as
begin
select 
'IdProducto|Codigo|Descripcion|Cantidad|UM|PrecioVenta|PrecioVentaB|Costo|CostoDola|TipoCambio|Estado|Usuario|Imagen¬100|135|380|100|85|100|100|100|100|100|120|150|100¬String|String|String|String|String|String|String|Decimal|Decimal|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,p.IdProducto)+'|'+p.ProductoCodigo+'|'+
p.ProductoNombre+' '+p.ProductoMarca+'|'+convert(varchar(50),cast(p.ProductoCantidad as money),1)+'|'+ 
p.ProductoUM+'|'+convert(varchar(50),cast(p.ProductoVenta as money),1)+'|'+
convert(varchar(50),cast(p.ProductoVenta as money),1)+'|'+convert(varchar,p.ProductoCosto)+'|'+
convert(varchar,ProductoCostoDolar)+'|'+convert(varchar,ProductoTipoCambio)+'|'+
p.ProductoEstado+'|'+p.ProductoUsuario+'|'+p.ProductoImagen
FROM Producto p with(nolock)
where p.ProductoEstado='DESCONTINUADO'
order by p.ProductoNombre+' '+p.ProductoMarca asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspDescuento', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspDescuento] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspDescuento]
@detalle varchar(Max)
as
begin
Begin Transaction
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max),
        @TemporalId numeric(38),
		@Descuento decimal(18,4)
Declare @p1 int,@p2 int
Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	Begin
Set @p1 = CharIndex('|',@Columna,0)
Set @p2 = Len(@Columna)+1
Set @TemporalId=Convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))
Set @Descuento=Convert(decimal(18,4),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
update TemporalCompra 
set DetalleDescuento=@Descuento 
where TemporalId=@TemporalId		
Fetch Next From Tabla INTO @Columna
end
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
select 'true'
end
GO

IF OBJECT_ID(N'dbo.uspDescuentoB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspDescuentoB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspDescuentoB]
@detalle varchar(Max)
as
begin
Begin Transaction
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max),
        @DetalleId numeric(38),
		@Descuento decimal(18,4)
Declare @p1 int,@p2 int
Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	Begin
Set @p1 = CharIndex('|',@Columna,0)
Set @p2 = Len(@Columna)+1
Set @DetalleId=Convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))
Set @Descuento=Convert(decimal(18,4),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
update DetalleCompra 
set DetalleDescuento=@Descuento
where DetalleId=@DetalleId	
Fetch Next From Tabla INTO @Columna
end
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
select 'true'
end
GO

IF OBJECT_ID(N'dbo.uspDetaAperturaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspDetaAperturaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspDetaAperturaB]
@UsuarioID int
as
begin
Declare @IdApertura numeric(38)
declare @IdAperturaC numeric(38)
set @IdApertura=isnull((select top 1 a.IdApertura from APERTURA_ALMACEN a 
where a.UsuarioID=@UsuarioID and a.AperturaEstado='0' order by a.IdApertura desc),'0')
set @IdAperturaC=isnull((select top 1 a.IdApertura from APERTURA_ALMACEN a 
order by a.IdApertura desc),0)
if(@IdApertura=0)
begin
select
'0['+ 
'ID|Codigo|Descripcion|xMayor|UNIxCaja|TotalxMayor|UM|Despacho|Vitrina|AlmacenTotal|Validacion¬90|100|350|100|110|110|80|100|100|110|90¬String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,p.IdProducto)+'|'+p.ProductoCodigo+'|'+
p.ProductoNombre+' '+p.ProductoMarca+'|'+''+'|'+convert(varchar,p.productoxCaja)+'|'+''+'|'+
p.ProductoUM+'|'+''+'|'+''+'|'+''+'|'+''
from Producto p
inner join Sublinea s
on s.IdSubLinea=p.IdSubLinea
where p.ProductoEstado='BUENO' and s.Vista='V'
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')+'['+
'IdProducto|total¬90|100¬String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,d.IdProducto)+'|'+
CONVERT(VarChar(50),cast(d.total as money ), 1)
from DetalleCierre d
where d.IdApertura=@IdAperturaC
order by d.DetalleId asc
for xml path('')),1,1,'')),'~')
end
else
begin
select
isnull((select STUFF ((select '¬'+CONVERT(varchar,a.IdApertura)+'|'+
(IsNull(convert(varchar,a.FechaApertura,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,a.FechaApertura,114),1,8),''))+'|'+
a.FechaCierre+'|'+CONVERT(varchar,a.UsuarioId)+'|'+a.Usuario+'|'+a.Observacion+'|'+a.AperturaEstado
from APERTURA_ALMACEN a
where a.IdApertura=@IdApertura
for xml path('')),1,1,'')),'~')+'['+
'ID|Codigo|Descripcion|xMayor|UNIxCaja|TotalxMayor|UM|Despacho|Vitrina|AlmacenTotal|Validacion¬90|100|350|100|110|110|80|100|100|110|90¬String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,p.IdProducto)+'|'+p.ProductoCodigo+'|'+
p.ProductoNombre+' '+p.ProductoMarca+'|'+convert(varchar,d.CantMayor)+'|'+convert(varchar,d.xCaja)+'|'+
convert(varchar(50), CAST(d.CantMayor*d.xCaja as money),1)+'|'+
p.ProductoUM+'|'+CONVERT(varchar,d.CantDespacho)+'|'+CONVERT(varchar,d.CantVitrina)+'|'+
convert(varchar(50), CAST(d.total as money),1)+'|'+convert(varchar,d.Validacion)
from DetalleApertura d
inner join Producto p
on p.IdProducto=d.IdProducto
where d.IdApertura=@IdApertura
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')+'['+
'ID|Codigo|Descripcion|xMayor|UNIxCaja|TotalxMayor|UM|Despacho|Vitrina|AlmacenTotal¬90|100|350|100|110|110|80|100|100|110¬String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,p.IdProducto)+'|'+p.ProductoCodigo+'|'+
p.ProductoNombre+' '+p.ProductoMarca+'|'+''+'|'+convert(varchar,p.productoxCaja)+'|'+''+'|'+
p.ProductoUM+'|'+''+'|'+''+'|'+''
from Producto p
inner join Sublinea s
on s.IdSubLinea=p.IdSubLinea
where p.ProductoEstado='BUENO' and s.Vista='V'
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')
end
end
GO

IF OBJECT_ID(N'dbo.uspDetalleApertura', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspDetalleApertura] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspDetalleApertura]
@IdApertura numeric(38)
as
begin
select
'ID|Codigo|Descripcion|xMayor|UNIxCaja|TotalxMayor|UM|Despacho|Vitrina|AlmacenTotal|Validacion¬90|100|350|100|110|110|80|100|100|110|90¬String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,p.IdProducto)+'|'+p.ProductoCodigo+'|'+
p.ProductoNombre+' '+p.ProductoMarca+'|'+convert(varchar,d.CantMayor)+'|'+convert(varchar,d.xCaja)+'|'+
convert(varchar(50), CAST(d.CantMayor*d.xCaja as money),1)+'|'+
p.ProductoUM+'|'+CONVERT(varchar,d.CantDespacho)+'|'+CONVERT(varchar,d.CantVitrina)+'|'+
convert(varchar(50), CAST(d.total as money),1)+'|'+
convert(varchar(50), CAST(d.Validacion as money),1)
from DetalleApertura d
inner join Producto p
on p.IdProducto=d.IdProducto
where d.IdApertura=@IdApertura
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')+'['+
'ID|Codigo|Descripcion|xMayor|UNIxCaja|TotalxMayor|UM|Despacho|Vitrina|AlmacenTotal¬90|100|350|100|110|110|80|100|100|110¬String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,p.IdProducto)+'|'+p.ProductoCodigo+'|'+
p.ProductoNombre+' '+p.ProductoMarca+'|'+convert(varchar,d.CantMayor)+'|'+convert(varchar,d.xCaja)+'|'+
convert(varchar(50), CAST(d.CantMayor*d.xCaja as money),1)+'|'+
p.ProductoUM+'|'+CONVERT(varchar,d.CantDespacho)+'|'+CONVERT(varchar,d.CantVitrina)+'|'+
convert(varchar(50), CAST(d.total as money),1)
from DetalleCierre d
inner join Producto p
on p.IdProducto=d.IdProducto
where d.IdApertura=@IdApertura
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspDetalleNC', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspDetalleNC] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspDetalleNC]
@DocuId numeric(38)
as
begin
select
'Cantidad|UM|Descripcion|Precio|Importe|DetalleId|IdProducto|valorUM|PrecioSunat|IGVPrecio|ImporteSunat|Codigo¬103|100|350|110|115|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+CONVERT(VarChar(50), cast(d.DetalleCantidad as money ), 1)+'|'+
d.DetalleUM+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
CONVERT(VarChar(50), cast(d.DetallPrecio as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleImporte as money ), 1)+'|'+
convert(varchar,d.DetalleNotaId)+'|'+convert(varchar,d.IdProducto)+'|'+
convert(varchar,d.ValorUM)+'|'+
convert(varchar,convert(decimal(18,2),d.DetallPrecio/1.18))+'|'+
convert(varchar,(d.DetalleImporte - convert(decimal(18,2),d.DetalleImporte/1.18)))+'|'+
convert(varchar,convert(decimal(18,2),d.DetalleImporte/1.18))+'|'+
P.ProductoCodigo
from DetalleDocumento d
inner join Producto p
on p.IdProducto=d.IdProducto
where DocuId=@DocuId
order by d.DetalleId asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspDetallesPVSListaCsv', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspDetallesPVSListaCsv] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspDetallesPVSListaCsv]
@NotaId varchar(38)
as
Begin
select 
'FechaRegistro|CodigoDXN|Cliente|NroTransaccion|Acuenta|Usuario¬100|100|100|100|100|100¬String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,d.FechaRegistro,103)+' '+ SUBSTRING(convert(varchar,d.FechaRegistro,114),1,8)+'|'+
d.CodigoDXN+'|'+d.Cliente+'|'+d.NroTransaccion+'|'+
CONVERT(VarChar(50), cast(d.Acuenta as money ), 1)+'|'+d.Usuario
from DetallesPVS d
where d.NotaId=@NotaId
order by d.DetalleId desc
for XMl path('')),1,1,'')),'~')
End
GO

IF OBJECT_ID(N'dbo.uspDetaPagoV', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspDetaPagoV] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspDetaPagoV]
@PagoId varchar(38)
as
begin
select
'DocuId|NotaId|Documento|Codigo|RazonSocial|Monto|Selec|ConceptoOBS¬100|100|100|100|100|100|100|100¬String|String|String|String|String|String|Boolean|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,d.DocuId)+'|'+convert(varchar,d.NotaId)+'|'+
n.NotaSerie+'-'+n.NotaNumero+'|'+c.ClienteCodigo+'|'+
c.ClienteRazon+'|'+CONVERT(VarChar(50),cast(n.NotaPagar as money ), 1)+'|1|'+n.ConceptoOBS
from DetallePVarios d
inner join NotaPedido n
on n.NotaId=d.NotaId
inner join Cliente c
on c.ClienteId=n.ClienteId
where d.PagoId=@PagoId
order by d.DetalleId asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspDeudasDelDia', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspDeudasDelDia] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspDeudasDelDia]
@Fecha date
as
begin
select 
'Codigo|Responsable|SaldoSol¬130|430|120¬String|String|String¬'+
isnull((select stuff((select '¬'+ convert(varchar,n.CodigoRes)+'|'+
n.Responsable+'|'+
CONVERT(VarChar(50), cast(sum(n.NotaSaldo)as money ), 1)
from NotaPedido n
inner join Cliente c
on c.ClienteId=n.ClienteId
where (n.NotaSaldo>0 and n.NotaEstado<>'CANCELADO' and n.NotaEstado<>'ANULADO') and n.NotaCondicion='CREDITO'
and convert(date,n.NotaFecha)=@fecha
group by n.CodigoRes,n.Responsable
order by n.Responsable asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspEditaBonificacion', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEditaBonificacion] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEditaBonificacion]
@Data varchar(max)
as
begin
Declare @p1 int
Declare @p2 int
Declare @p3 int
declare @TemporalId numeric(38),
@Estado varchar(20),
@UsuarioID int
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 =Len(@Data)+1
Set @TemporalId =convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
Set @Estado=SUBSTRING(@Data,@p1+1,@p2-@p1-1)
Set @UsuarioID=convert(int,SUBSTRING(@Data,@p2+1,@p3-@p2-1))
update TemporalCompra 
set PrecioCosto=0,DetalleImporte=0,DetalleDescuento=0,
DetalleEstado=@Estado 
where TemporalId=@TemporalId
select
isnull((select STUFF ((select '¬'+convert(varchar,t.TemporalId)+'|'+convert(varchar,t.IdProducto)+'|'+
t.DetalleCodigo+'|'+t.Descripcion+'|'+t.DetalleUM+'|'+
CONVERT(VarChar(50),cast(t.DetalleCantidad as money ), 1)+'|'+
convert(varchar,t.PrecioCosto)+'|'+convert(varchar,t.DetalleDescuento)
+'|'+convert(varchar,t.DetalleImporte)+'|'+CONVERT(varchar,t.ValorUM)+'|'+
t.DetalleEstado
from TemporalCompra t 
inner join Producto p 
on p.IdProducto=t.IdProducto 
where t.UsuarioID=@UsuarioID
order by t.TemporalId asc
for xml path('')),1,1,'')),'~')+'['+
isnull((select STUFF ((select '¬'+convert(varchar,u.IdUm)+'|'+convert(varchar,u.IdProducto)+'|'+
u.UMDescripcion+'|'+CONVERT(VarChar(50), cast(u.ValorUM as money ), 1)+'|'+
convert(varchar,t.PrecioCosto)
from UnidadMedida u
inner join TemporalCompra t
on t.IdProducto=u.IdProducto
where t.UsuarioID=@UsuarioID
order by u.ValorUM asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspEditaDocNro', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEditaDocNro] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEditaDocNro]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,@p3 int,@p4 int
Declare @DocuId numeric(38),@DocuNumero varchar(80),
@DocuEmision date,@DocuUsuario varchar(80)
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 = CharIndex('|',@Data,@p2+1)  
Set @p4 = Len(@Data)+1 
Set @DocuId=convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
Set @DocuNumero=SUBSTRING(@Data,@p1+1,@p2-@p1-1) 
Set @DocuEmision=convert(date,SUBSTRING(@Data,@p2+1,@p3-@p2-1))
Set @DocuUsuario=SUBSTRING(@Data,@p3+1,@p4-@p3-1)
update DocumentoVenta
set DocuNumero=@DocuNumero,DocuEmision=@DocuEmision,
DocuUsuario=@DocuUsuario
where DocuId=@DocuId
select 'true'
end
GO

IF OBJECT_ID(N'dbo.uspEditaDocu', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEditaDocu] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEditaDocu]
@Data varchar(max)
as
begin
Declare @pos1 int
Declare @pos2 int
declare @pos3 int
declare @pos4 int
Declare @DocuId numeric(38),
@Numero varchar(40),
@DocuEmision date,
@Usuario varchar(40)
Set @Data = LTRIM(RTrim(@Data))
Set @pos1 = CharIndex('|',@Data,0)
Set @DocuId=convert(numeric(38),SUBSTRING(@Data,1,@pos1-1))
Set @pos2 = CharIndex('|',@Data,@pos1+1)
Set @Numero=SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1)
Set @pos3= CharIndex('|',@Data,@pos2+1)
Set @DocuEmision=convert(date,SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1))
Set @pos4= Len(@Data)+1
Set @Usuario=SUBSTRING(@Data,@pos3+1,@pos4-@pos3-1)
update DocumentoVenta
set DocuNumero=@Numero,DocuEmision=@DocuEmision,DocuUsuario=@Usuario
where DocuId=@DocuId
select 'true'
end
GO

IF OBJECT_ID(N'dbo.uspEditarConteoCaja', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEditarConteoCaja] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEditarConteoCaja]
@ListaOrden varchar(Max)
as
Declare @pos1 int,@pos2 int,@pos3 int
Declare @orden varchar(max),
        @detalle varchar(max),
        @Monedas varchar(max)
Set @pos1 = CharIndex('[',@ListaOrden,0)
Set @pos2 = CharIndex('[',@ListaOrden,@pos1+1)
Set @pos3=Len(@ListaOrden)+1
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)
Set @detalle =SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)
Set @Monedas=SUBSTRING(@ListaOrden,@pos2+1,@pos3-@pos2-1)
Declare @c1 int,@c2 int,@c3 int,@c4 int,
        @c5 int,@c6 int,@c7 int,@c8 int,
        @c9 int,@c10 int,@c11 int,@C12 int
Declare @ConteoId numeric(38),@FechaConteo date,
        @UsuarioId int,@Usuario varchar(80),
        @Cajeros varchar(300),@TotalOBS decimal(18,2),
        @Gastos decimal(18,2),@Diferencial decimal(18,2),
        @Total decimal(18,2),@Aviso varchar(140),
        @Observaciones varchar(max),@CajaId numeric(38)
Set @c1 = CharIndex('|',@orden,0)
Set @c2 = CharIndex('|',@orden,@c1+1)
Set @c3 = CharIndex('|',@orden,@c2+1)
Set @c4 = CharIndex('|',@orden,@c3+1)
Set @c5 = CharIndex('|',@orden,@c4+1)
Set @c6= CharIndex('|',@orden,@c5+1)
Set @c7 = CharIndex('|',@orden,@c6+1)
Set @c8 = CharIndex('|',@orden,@c7+1)
Set @c9 = CharIndex('|',@orden,@c8+1)
Set @c10= CharIndex('|',@orden,@c9+1)
Set @c11= CharIndex('|',@orden,@c10+1)
Set @C12= Len(@orden)+1
Set @ConteoId=convert(numeric(38),SUBSTRING(@orden,1,@c1-1))
Set @FechaConteo=convert(date,SUBSTRING(@orden,@c1+1,@c2-@c1-1))
Set @UsuarioId=convert(int,SUBSTRING(@orden,@c2+1,@c3-@c2-1))
Set @Usuario=SUBSTRING(@orden,@c3+1,@c4-@c3-1)
Set @Cajeros=SUBSTRING(@orden,@c4+1,@c5-@c4-1)
Set @TotalOBS=convert(decimal(18,2),SUBSTRING(@orden,@c5+1,@c6-@c5-1))
Set @Gastos=convert(decimal(18,2),SUBSTRING(@orden,@c6+1,@c7-@c6-1))
Set @Diferencial=convert(decimal(18,2),SUBSTRING(@orden,@c7+1,@c8-@c7-1))
Set @Total=convert(decimal(18,2),SUBSTRING(@orden,@c8+1,@c9-@c8-1))
Set @Aviso=SUBSTRING(@orden,@c9+1,@c10-@c9-1)
Set @Observaciones=SUBSTRING(@orden,@c10+1,@c11-@c10-1)
Set @CajaId=convert(numeric(38),SUBSTRING(@orden,@c11+1,@C12-@c11-1))
Begin Transaction
update ConteoMonedas
set FechaConteo=@FechaConteo,FechaRegistro=getdate(),
UsuarioId=@UsuarioId,Usuario=@Usuario,
Cajeros=@Cajeros,TotalOBS=@TotalOBS,
Gastos=@Gastos,Diferencial=@Diferencial,
Total=@Total,Aviso=@Aviso,Observaciones=@Observaciones
where ConteoId=@ConteoId
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
        Declare @Columna varchar(max)
        Declare @Descripcion varchar(max),@Importe decimal(18,2),
        @Estado char(1),@DetalleId numeric(38),@Concepto char(1)
		Declare @d1 int,@d2 int,@d3 int,@d4 int,@d5 int
Fetch Next From Tabla INTO @Columna
While @@FETCH_STATUS = 0
Begin
	    Set @d1 = CharIndex('|',@Columna,0)
	    Set @d2 = CharIndex('|',@Columna,@d1+1)
        Set @d3 = CharIndex('|',@Columna,@d2+1)
        Set @d4= CharIndex('|',@Columna,@d3+1)
		Set @d5=Len(@Columna)+1
        Set @Descripcion=SUBSTRING(@Columna,1,@d1-1)
		Set @Importe=convert(decimal(18,2),SUBSTRING(@Columna,@d1+1,@d2-(@d1+1)))
		set @Estado=SUBSTRING(@Columna,@d2+1,@d3-(@d2+1))
		set @DetalleId=SUBSTRING(@Columna,@d3+1,@d4-(@d3+1))
		set @Concepto=SUBSTRING(@Columna,@d4+1,@d5-(@d4+1))
		if(@DetalleId=0)
		begin
		insert into DetalleConteo values(@ConteoId,upper(@Descripcion),@Importe,@Estado,@Concepto,@CajaId)
		end
		else
		begin
		update DetalleConteo
		set Descripcion=upper(@Descripcion),Importe=@Importe,Estado=@Estado
		where DetalleId=@DetalleId
		end
Fetch Next From Tabla INTO @Columna
End
    Close Tabla;
	Deallocate Tabla;
	begin
	Declare TablaB Cursor For Select * From fnSplitString(@Monedas,';')	
Open TablaB
        Declare @ARQUEO varchar(max)
Declare  @Id numeric(38),@Efectivo int,
         @Monto decimal(18,2)
		Declare @m1 int,@m2 int,@m3 int
Fetch Next From TablaB INTO @ARQUEO
While @@FETCH_STATUS = 0
Begin
	    Set @m1 = CharIndex('|',@ARQUEO,0)
	    Set @m2 = CharIndex('|',@ARQUEO,@m1+1)
		Set @m3=Len(@ARQUEO)
		Set @Id=convert(numeric(38),SUBSTRING(@ARQUEO,1,@m1-1))
        Set @Efectivo=CONVERT(int,SUBSTRING(@ARQUEO,@m1+1,@m2-(@m1+1)))
		set @Monto=convert(decimal(18,2),SUBSTRING(@ARQUEO,@m2+1,@m3-(@m2+1)))
		update Monedas
		set Efectivo=@Efectivo,Monto=@Monto
		where MonedaId=@Id
Fetch Next From TablaB INTO @ARQUEO
END
	Close TablaB;
	Deallocate TablaB;
END
	Commit Transaction;
	Select 'true';
GO

IF OBJECT_ID(N'dbo.uspEditarLiquidaVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEditarLiquidaVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEditarLiquidaVenta]
@ListaOrden varchar(Max)
as
begin
Declare @pos1 int,@pos2 int
Declare @orden varchar(max),
        @detalle varchar(max)
Set @pos1 = CharIndex('[',@ListaOrden,0)
Set @pos2=Len(@ListaOrden)+1
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)
Declare @c1 int,@c2 int,@c3 int,@c4 int,
        @c5 int,@c6 int,@c7 int,
        @c8 int,@c9 int,@c10 int
Declare @LiquidacionId numeric(38),
		@Fecha date,
		@Descripcion varchar(250),
		@EfectivoSol decimal(18,2),
		@DepositoSol decimal(18,2),
		@TotalSol decimal(18,2),
		@EfectivoDol decimal(18,2),
		@DepositoDol decimal(18,2),
		@TotalDol decimal(18,2),
		@Usuario varchar(60)
Set @c1 = CharIndex('|',@orden,0)
Set @c2 = CharIndex('|',@orden,@c1+1)
Set @c3 = CharIndex('|',@orden,@c2+1)
Set @c4 = CharIndex('|',@orden,@c3+1)
Set @c5 = CharIndex('|',@orden,@c4+1)
Set @c6 = CharIndex('|',@orden,@c5+1)
Set @c7 = CharIndex('|',@orden,@c6+1)
Set @c8 = CharIndex('|',@orden,@c7+1)
Set @c9 = CharIndex('|',@orden,@c8+1)
Set @c10= Len(@orden)+1
Set @LiquidacionId=convert(numeric(38),SUBSTRING(@orden,1,@c1-1))
Set @Fecha=SUBSTRING(@orden,@c1+1,@c2-@c1-1)
Set @Descripcion=SUBSTRING(@orden,@c2+1,@c3-@c2-1)
Set @EfectivoSol=SUBSTRING(@orden,@c3+1,@c4-@c3-1)
Set @DepositoSol=SUBSTRING(@orden,@c4+1,@c5-@c4-1)
Set @TotalSol=SUBSTRING(@orden,@c5+1,@c6-@c5-1)
Set @EfectivoDol=SUBSTRING(@orden,@c6+1,@c7-@c6-1)
Set @DepositoDol=SUBSTRING(@orden,@c7+1,@c8-@c7-1)
Set @TotalDol=SUBSTRING(@orden,@c8+1,@c9-@c8-1)
Set @Usuario=SUBSTRING(@orden,@c9+1,@c10-@c9-1)
Begin Transaction
update LiquidacionVenta
set LiquidacionFecha=@Fecha,LiquidacionRegistro=GETDATE(),
LiquidacionDescripcion=@Descripcion,
LiquidaEfectivoSol=@EfectivoSol,LiquidaDepositoSol=@DepositoSol,
LiquidaTotalSol=@TotalSol,LiquidaEfectivoDol=@EfectivoDol,
LiquidaDepositoDol=@DepositoDol,LiquidaTotalDol=@TotalDol,
LiquidaUsuario=@Usuario
where LiquidacionId=@LiquidacionId
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max)
Declare @p1 int,@p2 int,@p3 int,@p4 int
Declare @DetalleId numeric(38),@EntidadBanco varchar(80),
        @NroOperacion varchar(80),@FechaPago varchar(60)
While @@FETCH_STATUS = 0
Begin
        Set @p1 = CharIndex('|',@Columna,0)
        Set @p2 = CharIndex('|',@Columna,@p1+1)
        Set @p3 = CharIndex('|',@Columna,@p2+1)
	    Set @p4=Len(@Columna)+1
	    Set @DetalleId=convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))	
		Set @EntidadBanco=SUBSTRING(@Columna,@p1+1,@p2-(@p1+1))
		Set @NroOperacion=SUBSTRING(@Columna,@p2+1,@p3-(@p2+1))
		Set @FechaPago=SUBSTRING(@Columna,@p3+1,@p4-(@p3+1))
		update DetalleLiquida
		set EntidadBanco=@EntidadBanco,NroOperacion=@NroOperacion,FechaPago=@FechaPago
		where DetalleId=@DetalleId
Fetch Next From Tabla INTO @Columna
End
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
	select 'true'
end
GO

IF OBJECT_ID(N'dbo.uspEditarNotaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEditarNotaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEditarNotaB]    
@ListaOrden varchar(Max)    
as    
begin    
Declare @pos1 int,@pos2 int    
Declare @orden varchar(max),    
        @detalle varchar(max)    
Set @pos1 = CharIndex('[',@ListaOrden,0)    
Set @pos2=Len(@ListaOrden)+1    
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)    
Set @detalle = SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)    
Declare @c1 int,@c2 int,@c3 int,@c4 int,    
        @c5 int,@c6 int,@c7 int,@c8 int,    
        @c9 int,@c10 int,@c11 int,@c12 int,    
        @c13 int,@c14 int,@c15 int,@c16 int,    
        @c17 int,@c18 int,@c19 int,@c20 int,    
        @c21 int,@c22 int,@c23 int,@c24 int,    
        @c25 int,@c26 int,@c27 int,@c28 int,    
        @c29 int,@c30 int,@c31 int,@c32 int,    
        @c33 int,@c34 int,@c35 int,@c36 int,    
        @c37 int,@c38 int,@c39 int,@c40 int,    
        @c41 int,@c42 int,@c43 int,@c44 int,    
        @c45 int    
Declare     
  @NotaDocu varchar(60),@ClienteId numeric(20),    
  @NotaUsuario varchar(60),@NotaFormaPago varchar(60),    
  @NotaCondicion varchar(60),@NotaDireccion varchar(max),    
  @NotaSubtotal decimal (18,2),@NotaMovilidad decimal(18,2),    
  @NotaDescuento decimal (18, 2),@NotaTotal decimal (18,2),    
  @NotaAcuenta decimal(18,2),@NotaSaldo decimal(18,2),    
  @NotaAdicional decimal(18,2),    
  @NotaTarjeta decimal(18,2),@NotaPagar decimal(18,2),    
  @NotaEstado varchar(60),@CompaniaId int,    
  @NotaEntrega varchar(40),@NotaConcepto varchar(60),    
  @Serie char(4),@Numero varchar(60),    
  @NotaGanancia decimal(18,2),@Letra varchar(max),    
  @DocuAdicional decimal(18,2),@DocuHash varchar(250),    
  @EstadoSunat varchar(80),@DocuSubtotal decimal(18,2),    
  @DocuIGV decimal(18,2),@UsuarioId int,@NotaId numeric(38),    
  @CajaId numeric(38),@Movimiento varchar(40),    
  @NotaTransaccion varchar(250),@KARDEX VARCHAR(1),    
  @Miembro varchar(300),@CodigoCliente varchar(80),@ICBPER DECIMAL(18,2),    
  @Asistencia int,@DocuGRAVADA decimal(18,2),    
  @ConceptoOBS varchar(80),@EstadoOBS varchar(20),    
  @PV varchar(40),@Image varchar(max),@TEXTO varchar(300),    
  @CodigoRes varchar(80),@Responsable varchar(300),    
  @EntidadBancaria varchar(80),@Efectivo decimal(18,2),    
  @Deposito decimal(18,2),@NroOperacion varchar(80)    
Set @c1 = CharIndex('|',@orden,0)    
Set @c2 = CharIndex('|',@orden,@c1+1)    
Set @c3 = CharIndex('|',@orden,@c2+1)    
Set @c4 = CharIndex('|',@orden,@c3+1)    
Set @c5 = CharIndex('|',@orden,@c4+1)    
Set @c6= CharIndex('|',@orden,@c5+1)    
Set @c7 = CharIndex('|',@orden,@c6+1)    
Set @c8 = CharIndex('|',@orden,@c7+1)    
Set @c9 = CharIndex('|',@orden,@c8+1)    
Set @c10= CharIndex('|',@orden,@c9+1)    
Set @c11= CharIndex('|',@orden,@c10+1)    
Set @c12= CharIndex('|',@orden,@c11+1)    
Set @c13= CharIndex('|',@orden,@c12+1)    
Set @c14= CharIndex('|',@orden,@c13+1)    
Set @c15= CharIndex('|',@orden,@c14+1)    
Set @c16= CharIndex('|',@orden,@c15+1)    
Set @c17= CharIndex('|',@orden,@c16+1)    
Set @c18 = CharIndex('|',@orden,@c17+1)    
Set @c19 = CharIndex('|',@orden,@c18+1)    
Set @c20= CharIndex('|',@orden,@c19+1)    
Set @c21= CharIndex('|',@orden,@c20+1)    
Set @c22= CharIndex('|',@orden,@c21+1)    
Set @c23= CharIndex('|',@orden,@c22+1)    
Set @c24= CharIndex('|',@orden,@c23+1)    
Set @c25= CharIndex('|',@orden,@c24+1)    
Set @c26= CharIndex('|',@orden,@c25+1)    
Set @c27= CharIndex('|',@orden,@c26+1)    
Set @c28= CharIndex('|',@orden,@c27+1)    
Set @c29= CharIndex('|',@orden,@c28+1)    
Set @c30= CharIndex('|',@orden,@c29+1)    
Set @c31= CharIndex('|',@orden,@c30+1)    
Set @c32= CharIndex('|',@orden,@c31+1)    
Set @c33= CharIndex('|',@orden,@c32+1)    
Set @c34= CharIndex('|',@orden,@c33+1)    
Set @c35= CharIndex('|',@orden,@c34+1)    
Set @c36= CharIndex('|',@orden,@c35+1)    
Set @c37= CharIndex('|',@orden,@c36+1)    
Set @c38= CharIndex('|',@orden,@c37+1)    
Set @c39= CharIndex('|',@orden,@c38+1)    
Set @c40= CharIndex('|',@orden,@c39+1)    
Set @c41= CharIndex('|',@orden,@c40+1)    
    
Set @c42= CharIndex('|',@orden,@c41+1)    
Set @c43= CharIndex('|',@orden,@c42+1)    
Set @c44= CharIndex('|',@orden,@c43+1)    
    
Set @c45= Len(@orden)+1    
set @NotaDocu=SUBSTRING(@orden,1,@c1-1)    
set @ClienteId=convert(numeric(20),SUBSTRING(@orden,@c1+1,@c2-@c1-1))    
set @NotaUsuario=SUBSTRING(@orden,@c2+1,@c3-@c2-1)    
set @NotaFormaPago=SUBSTRING(@orden,@c3+1,@c4-@c3-1)    
set @NotaCondicion=SUBSTRING(@orden,@c4+1,@c5-@c4-1)    
set @NotaDireccion=SUBSTRING(@orden,@c5+1,@c6-@c5-1)    
set @NotaSubtotal=convert(decimal(18,2),SUBSTRING(@orden,@c6+1,@c7-@c6-1))    
set @NotaMovilidad=convert(decimal(18,2),SUBSTRING(@orden,@c7+1,@c8-@c7-1))    
set @NotaDescuento=convert(decimal(18,2),SUBSTRING(@orden,@c8+1,@c9-@c8-1))    
set @NotaTotal=convert(decimal(18,2),SUBSTRING(@orden,@c9+1,@c10-@c9-1))    
set @NotaAcuenta=convert(decimal(18,2),SUBSTRING(@orden,@c10+1,@c11-@c10-1))    
set @NotaSaldo=convert(decimal(18,2),SUBSTRING(@orden,@c11+1,@c12-@c11-1))    
set @NotaAdicional=convert(decimal(18,2),SUBSTRING(@orden,@c12+1,@c13-@c12-1))    
set @NotaTarjeta=convert(decimal(18,2),SUBSTRING(@orden,@c13+1,@c14-@c13-1))    
set @NotaPagar=convert(decimal(18,2),SUBSTRING(@orden,@c14+1,@c15-@c14-1))    
set @NotaEstado=SUBSTRING(@orden,@c15+1,@c16-@c15-1)    
set @CompaniaId=convert(int,SUBSTRING(@orden,@c16+1,@c17-@c16-1))    
set @NotaEntrega=SUBSTRING(@orden,@c17+1,@c18-@c17-1)    
set @NotaConcepto=SUBSTRING(@orden,@c18+1,@c19-@c18-1)    
set @Serie=convert(char(4),SUBSTRING(@orden,@c19+1,@c20-@c19-1))    
set @Numero=SUBSTRING(@orden,@c20+1,@c21-@c20-1)    
set @NotaGanancia=convert(decimal(18,2),SUBSTRING(@orden,@c21+1,@c22-@c21-1))    
set @Letra=SUBSTRING(@orden,@c22+1,@c23-@c22-1)    
set @DocuAdicional=convert(decimal(18,2),SUBSTRING(@orden,@c23+1,@c24-@c23-1))    
set @DocuHash=SUBSTRING(@orden,@c24+1,@c25-@c24-1)    
set @EstadoSunat=SUBSTRING(@orden,@c25+1,@c26-@c25-1)    
set @DocuSubtotal=convert(decimal(18,2),SUBSTRING(@orden,@c26+1,@c27-@c26-1))    
set @DocuIGV=convert(decimal(18,2),SUBSTRING(@orden,@c27+1,@c28-@c27-1))    
set @UsuarioId=convert(int,SUBSTRING(@orden,@c28+1,@c29-@c28-1))    
set @NotaId=convert(numeric(38),SUBSTRING(@orden,@c29+1,@c30-@c29-1))    
set @NotaTransaccion=SUBSTRING(@orden,@c30+1,@c31-@c30-1)    
set @Miembro=SUBSTRING(@orden,@c31+1,@c32-@c31-1)    
set @CodigoCliente=SUBSTRING(@orden,@c32+1,@c33-@c32-1)    
set @ICBPER=convert(decimal(18,2),SUBSTRING(@orden,@c33+1,@c34-@c33-1))    
set @DocuGRAVADA=convert(decimal(18,2),SUBSTRING(@orden,@c34+1,@c35-@c34-1))    
set @ConceptoOBS=SUBSTRING(@orden,@c35+1,@c36-@c35-1)    
set @EstadoOBS=SUBSTRING(@orden,@c36+1,@c37-@c36-1)    
set @PV=SUBSTRING(@orden,@c37+1,@c38-@c37-1)    
set @Image=SUBSTRING(@orden,@c38+1,@c39-@c38-1)    
set @CodigoRes=SUBSTRING(@orden,@c39+1,@c40-@c39-1)    
set @Responsable=SUBSTRING(@orden,@c40+1,@c41-@c40-1)    
set @EntidadBancaria=SUBSTRING(@orden,@c41+1,@c42-@c41-1)    
set @Efectivo=convert(decimal(18,2),SUBSTRING(@orden,@c42+1,@c43-@c42-1))    
set @Deposito=convert(decimal(18,2),SUBSTRING(@orden,@c43+1,@c44-@c43-1))    
set @NroOperacion=SUBSTRING(@orden,@c44+1,@c45-@c44-1)    
    
declare @cod varchar(13)    
SET @cod=(select TOP 1 dbo.genenerarNroFactura(@Serie,@CompaniaId,@NotaDocu) AS ID FROM DocumentoVenta)    
    
if(@ConceptoOBS='PUNTOS A ICA' or @ConceptoOBS='PUNTOS A COMAS')    
begin    
set @TEXTO='SE MANDO A PASAR '+@ConceptoOBS+' CODIGO: '+@CodigoCliente+' ('+@Miembro+')'    
end    
else if(@ConceptoOBS='POR PASAR AL OBS')    
begin    
set @TEXTO='CANCELARON PRODUCTOS POR PASAR AL OBS '+@PV +' CODIGO: '+@CodigoCliente+' ('+@Miembro+')'    
end    
else if(@ConceptoOBS='VENTA LIBRE')    
begin    
set @TEXTO='VENTA LIBRE. SE VENDIO SIN CODIGO ('+@Miembro+')'    
end    
else if(@ConceptoOBS='FACTURA MANUAL')    
begin    
set @TEXTO='FACTURA MANUAL. SUMA TOTAL DE PRODUCTOS Y CODIGOS. RESPONSABLE ('+@Miembro+')'    
end    
else if(@ConceptoOBS='LIQUIDACION DE PAGO')    
begin    
set @TEXTO='CANCELARON DEUDA PENDIENTE PORQUE SE LE PASO SOLO PUNTOS AL OBS '+@PV +' CODIGO: '+@CodigoCliente+' ('+@Miembro+')'    
end    
else    
begin    
set @TEXTO='VENTA DEL OBS DOCUMENTO '+@Serie+'-'+@cod+' CODIGO: '+@CodigoCliente+' ('+@Miembro+')'    
end    
if(@Deposito>0)    
begin    
set @TEXTO=@TEXTO+' FORMA DE PAGO: '+@NotaFormaPago+' ENTIDAD BANCARIA: '+@EntidadBancaria+' NRO OPERACION: '+@NroOperacion    
end    
    
--set @Asistencia=(select COUNT(a.PersonalId)from Asistencia a    
--inner join Usuarios u    
--on u.PersonalId=a.PersonalId    
--where u.UsuarioID=@UsuarioId and (Day(a.Fecha)=Day(GETDATE()) and Month(a.Fecha)=MONTH(GETDATE()) and year(a.Fecha)=year(GETDATE())))    
--if(@Asistencia=0)    
--begin    
--Select 'NO ASISTIO'    
--end    
--else    
--begin    
set @CajaId=isnull((select top 1 CajaId from Caja where CajaEstado='ACTIVO'   
and UsuarioId=@UsuarioId order by 1 desc),'0')   
if(@CajaId=0)    
begin    
select 'false'    
end    
else    
begin    
if(@NotaDocu='FACTURA')    
begin    
set @NotaEstado='PENDIENTE'    
 if(@NotaCondicion='CREDITO' or @NotaCondicion='PAGO/VARIOS')    
 begin    
 set @NotaSaldo=@NotaPagar    
 set @NotaAcuenta=0    
 end    
 else    
 begin    
 set @NotaSaldo=0    
 set @NotaAcuenta=@NotaPagar    
 end    
end    
else    
begin    
   if(@NotaCondicion='CREDITO' or @NotaCondicion='PAGO/VARIOS')    
   begin    
   set @NotaEstado='PENDIENTE'    
   set @NotaSaldo=@NotaPagar    
   set @NotaAcuenta=0    
   end    
   else    
   begin    
   set @NotaEstado='CANCELADO'    
   set @NotaSaldo=0    
   set @NotaAcuenta=@NotaPagar    
   end    
end    
if(@NotaFormaPago='EFECTIVO')set @Movimiento='INGRESO'    
else set @Movimiento='TARJETA'     
declare @DocuId numeric(38)=0    
Begin Transaction    
update Cliente    
set ClienteDireccion=@NotaDireccion,    
ClienteDocu=@NotaDocu    
where ClienteId=@ClienteId    
delete from TemporalVenta     
where UsuarioID=@UsuarioId    
    
update NotaPedido    
set NotaDocu=@NotaDocu,    
ClienteId=@ClienteId,    
FechaEdita=(IsNull(convert(varchar,GETDATE(),103),'')+' '+ IsNull(SUBSTRING(convert(varchar,GETDATE(),114),1,8),'')),    
NotaUsuario=@NotaUsuario,    
NotaFormaPago=@NotaFormaPago,    
NotaCondicion=@NotaCondicion,    
NotaDireccion=@NotaDireccion,    
NotaSubtotal=@NotaSubtotal,    
NotaMovilidad=@NotaMovilidad,    
NotaDescuento=@NotaDescuento,    
NotaTotal=@NotaTotal,    
NotaSaldo=@NotaSaldo,    
NotaAdicional=@NotaAdicional,    
NotaTarjeta=@NotaTarjeta,    
NotaPagar=@NotaPagar,    
CompaniaId=@CompaniaId,    
NotaEntrega=@NotaEntrega,    
ModificadoPor=@NotaUsuario,    
NotaSerie=@Serie,    
NotaNumero=@cod,    
NotaGanancia=@NotaGanancia,    
NotaEstado=@NotaEstado,    
NotaTransaccion=@NotaTransaccion,    
NotaConcepto=@NotaConcepto,    
CajaId=@CajaId,    
ICBPER=@ICBPER,    
ConceptoOBS=@ConceptoOBS,    
EstadoOBS=@EstadoOBS,    
CodigoRes=@CodigoRes,    
Responsable=@Responsable,    
EntidadBancaria=@EntidadBancaria,    
Efectivo=@Efectivo,    
Deposito=@Deposito,    
NroOperacion=@NroOperacion    
where NotaId=@NotaId    
Declare @TipoCodigo nvarchar(3)    
    
    
DECLARE @VFechaPago datetime    
set @VFechaPago=GETDATE()    
if(@NotaCondicion='CREDITO')set @VFechaPago=DATEADD(DAY,15,@VFechaPago)    
    
if @NotaDocu='PROFORMA V'    
begin    
set @TipoCodigo='00'    
insert into DocumentoVenta values    
(@CompaniaId,@NotaId,@NotaDocu,@cod,@ClienteId,@VFechaPago,    
GETDATE(),@NotaCondicion,@Letra,@DocuSubtotal,    
@DocuIGV,@NotaPagar,@DocuGRAVADA,@NotaUsuario,'EMITIDO',@Serie,@TipoCodigo,@DocuAdicional,'','VENTA','',@DocuHash,'ENVIADO',    
@NotaConcepto,@NotaTransaccion,@ICBPER,'','',    
@NotaFormaPago,@EntidadBancaria,@NroOperacion,@Efectivo,@Deposito)    
set @DocuId=(select @@IDENTITY)    
    
if(@ConceptoOBS='VENTA' and @NotaCondicion='ALCONTADO')    
begin    
 if(@Deposito>0)    
 begin    
    insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',    
 @TEXTO,@Deposito,@Deposito,0,@Image,'D','',@NotaId,'',@NotaFormaPago,    
 @EntidadBancaria,@NroOperacion)    
 end        
end    
Else    
begin    
if(@ConceptoOBS<>'VENTA' and @NotaCondicion='ALCONTADO')    
begin    
if(@ConceptoOBS<>'FACTURA MANUAL')    
begin    
insert into CajaDetalle values(@CajaId,GETDATE(),0,'INGRESO',    
@TEXTO,@NotaTotal,@NotaTotal,0,@Image,'D','',@NotaId,'',    
@NotaFormaPago,@EntidadBancaria,@NroOperacion)    
if(@Deposito>0)    
begin    
 insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',    
 @TEXTO,@Deposito,@Deposito,0,@Image,'D','',@NotaId,'',@NotaFormaPago,    
 @EntidadBancaria,@NroOperacion)    
end          
end    
    
end    
else    
begin    
insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,'INGRESO',    
'Transacción con '+@NotaFormaPago,@NotaTotal,@NotaTotal,0,'','T','',0,'',@NotaFormaPago,'','')    
end    
end      
SET @KARDEX='S'    
    
end    
else if @NotaDocu='BOLETA'    
begin    
set @TipoCodigo='03'    
insert into DocumentoVenta values    
(@CompaniaId,@NotaId,'BOLETA',@cod,@ClienteId,@VFechaPago,    
GETDATE(),@NotaCondicion,@Letra,@DocuSubtotal,    
@DocuIGV,@NotaPagar,@DocuGRAVADA,@NotaUsuario,'EMITIDO',@Serie,@TipoCodigo,@DocuAdicional,'','VENTA','',@DocuHash,@EstadoSunat,    
@NotaConcepto,@NotaTransaccion,@ICBPER,'','',    
@NotaFormaPago,@EntidadBancaria,@NroOperacion,@Efectivo,@Deposito)    
set @DocuId=(select @@IDENTITY)    
    
    
if(@ConceptoOBS='VENTA' and @NotaCondicion='ALCONTADO')    
begin    
if(@Deposito>0)    
 begin    
    insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',    
 @TEXTO,@Deposito,@Deposito,0,@Image,'D','',@NotaId,'',@NotaFormaPago,    
 @EntidadBancaria,@NroOperacion)    
 end        
end    
Else    
begin    
if(@ConceptoOBS<>'VENTA' and @NotaCondicion='ALCONTADO')    
begin    
if(@ConceptoOBS<>'FACTURA MANUAL')    
begin    
insert into CajaDetalle values(@CajaId,GETDATE(),0,'INGRESO',    
@TEXTO,@NotaTotal,@NotaTotal,0,@Image,'D','',@NotaId,'',    
@NotaFormaPago,@EntidadBancaria,@NroOperacion)    
    
 if(@Deposito>0)    
 begin    
 insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',    
 @TEXTO,@Deposito,@Deposito,0,@Image,'D','',@NotaId,'',@NotaFormaPago,    
 @EntidadBancaria,@NroOperacion)    
 end        
end    
end    
else    
begin    
insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,'INGRESO',    
'Transacción con '+@NotaFormaPago,@NotaTotal,@NotaTotal,0,'','T','',0,'',@NotaFormaPago,'','')    
end    
end    
    
SET @KARDEX='S'    
    
    
end    
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')     
Open Tabla    
Declare @Columna varchar(max),    
        @DetalleId numeric(38),    
  @IdProducto numeric(20),    
  @DetalleCantidad decimal(18,2),    
  @DetalleUm varchar(40),    
  @Descripcion varchar(max),    
  @DetalleCosto decimal(18,2),     
  @DetallePrecio decimal(18,2),    
  @DetallePV decimal(18,2),    
  @DetalleSV decimal(18,2),    
  @DetalleImporte decimal(18,2),    
  @DetalleEstado varchar(60),--@CodigoPro varchar(80),    
  @ValorUM decimal(18,4),@CantidadSaldo decimal(18,2),    
  @IniciaStock decimal(18,2),@StockFinal decimal(18,2)    
Declare @p1 int,@p2 int,@p3 int,@p4 int,    
        @p5 int,@p6 int,@p7 int,@p8 int,    
        @p9 int,@p10 int,@p11 int,@p12 int    
Fetch Next From Tabla INTO @Columna    
 While @@FETCH_STATUS = 0    
 Begin    
Set @p1 = CharIndex('|',@Columna,0)    
Set @p2 = CharIndex('|',@Columna,@p1+1)    
Set @p3 = CharIndex('|',@Columna,@p2+1)    
Set @p4 = CharIndex('|',@Columna,@p3+1)    
Set @p5 = CharIndex('|',@Columna,@p4+1)    
Set @p6= CharIndex('|',@Columna,@p5+1)    
Set @p7= CharIndex('|',@Columna,@p6+1)    
Set @p8 = CharIndex('|',@Columna,@p7+1)    
Set @p9= CharIndex('|',@Columna,@p8+1)    
Set @p10 = CharIndex('|',@Columna,@p9+1)    
Set @p11 = CharIndex('|',@Columna,@p10+1)    
Set @p12=Len(@Columna)+1    
set @DetalleId=Convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))    
set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))    
Set @DetalleCantidad=convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))    
Set @DetalleUm=SUBSTRING(@Columna,@p3+1,@p4-(@p3+1))    
Set @Descripcion=SUBSTRING(@Columna,@p4+1,@p5-(@p4+1))    
Set @DetalleCosto=convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))    
Set @DetallePrecio=convert(decimal(18,2),SUBSTRING(@Columna,@p6+1,@p7-(@p6+1)))    
Set @DetallePV=convert(decimal(18,2),SUBSTRING(@Columna,@p7+1,@p8-(@p7+1)))    
Set @DetalleSV=convert(decimal(18,2),SUBSTRING(@Columna,@p8+1,@p9-(@p8+1)))    
Set @DetalleImporte=convert(decimal(18,2),SUBSTRING(@Columna,@p9+1,@p10-(@p9+1)))    
Set @DetalleEstado=SUBSTRING(@Columna,@p10+1,@p11-(@p10+1))    
set @ValorUM=convert(decimal(18,4),SUBSTRING(@Columna,@p11+1,@p12-(@p11+1)))    
if(@NotaEntrega='INMEDIATA')Set @CantidadSaldo=0    
else Set @CantidadSaldo=@DetalleCantidad    
update DetallePedido    
set DetalleCantidad=@DetalleCantidad,DetalleCosto=@DetalleCosto,    
DetallePrecio=@DetallePrecio,DetalleImporte=@DetalleImporte,DetalleEstado=@DetalleEstado,    
DetallePV=@DetallePV,DetalleSV=@DetalleSV    
where DetalleId=@DetalleId    
if(@DocuId<>0)  begin    
insert into DetalleDocumento values    
(@DocuId,@IdProducto,@DetalleCantidad,@DetallePrecio,@DetalleImporte,    
@NotaId,@DetalleUm,@ValorUM)    
    if(@NotaEntrega='INMEDIATA')    
    begin    
    --set @CodigoPro=isnull((select top 1 ProductoCodigo from Producto    
    --where IdProducto=@IdProducto),'0')    
 --   if(@CodigoPro='PEKIT-3')    
 --   begin    
 --   set @IniciaStock=(select top 1 ProductoCantidad from Producto     
 --   where IdProducto=7)    
 --set @StockFinal=@IniciaStock-@DetalleCantidad    
 --   insert into Kardex values(7,GETDATE(),'Salida por Venta',@Numero,@IniciaStock,    
 --0,@DetalleCantidad,57,@StockFinal,'SALIDA',@NotaUsuario,@Miembro,    
 --@CodigoCliente,@NotaTransaccion,@TipoCodigo,@Serie,'01','S',convert(varchar,@DocuId),'','E')    
 --update producto     
 --set  ProductoCantidad =ProductoCantidad - @DetalleCantidad    
 --where IDProducto=7    
 --  end      
    set @IniciaStock=(select top 1 ProductoCantidad from Producto where IdProducto=@IdProducto)    
 set @StockFinal=@IniciaStock-@DetalleCantidad    
    insert into Kardex values(@IdProducto,GETDATE(),'Salida por Venta',@Numero,@IniciaStock,    
 0,@DetalleCantidad,@DetalleCosto,@StockFinal,'SALIDA',@NotaUsuario,@Miembro,    
 @CodigoCliente,@NotaTransaccion,@TipoCodigo,@Serie,'01','S',convert(varchar,@DocuId),'','E')    
 update producto     
 set  ProductoCantidad =ProductoCantidad - @DetalleCantidad    
 where IDProducto=@IdProducto    
 end    
 else    
 begin    
 set @IniciaStock=(select top 1 ProductoCantidad from Producto where IdProducto=@IdProducto)    
 set @StockFinal=@IniciaStock-@DetalleCantidad    
    insert into Kardex values(@IdProducto,GETDATE(),'Salida por Venta',@Numero,@IniciaStock,    
 0,@DetalleCantidad,@DetalleCosto,@StockFinal,'SALIDA',@NotaUsuario,@Miembro,    
 @CodigoCliente,@NotaTransaccion,@TipoCodigo,@Serie,'01','N',convert(varchar,@DocuId),'','E')    
 end     
end    
Fetch Next From Tabla INTO @Columna    
end    
 Close Tabla;    
 Deallocate Tabla;    
    Commit Transaction;    
    select @cod    
END    
END    
--end
GO

IF OBJECT_ID(N'dbo.uspEditarNotaPedido', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEditarNotaPedido] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE dbo.uspEditarNotaPedido
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE 
        @open int,
        @Cabecera varchar(max),
        @Detalle varchar(max);

    DECLARE 
        @p1 int,
        @p2 int,
        @p3 int,
        @p4 int,
        @p5 int,
        @p6 int,
        @p7 int,
        @p8 int;

    /* =========================================================
       OBTENER CABECERA Y DETALLE
       ========================================================= */

    SET @open = CHARINDEX('[', @Data);

    SET @Cabecera = SUBSTRING(@Data, 1, @open - 1);
    SET @Detalle = SUBSTRING(@Data, @open + 1, LEN(@Data));

    SET @p1 = CHARINDEX('|', @Cabecera);
    SET @p2 = CHARINDEX('|', @Cabecera, @p1 + 1);
    SET @p3 = CHARINDEX('|', @Cabecera, @p2 + 1);
    SET @p4 = CHARINDEX('|', @Cabecera, @p3 + 1);
    SET @p5 = CHARINDEX('|', @Cabecera, @p4 + 1);
    SET @p6 = CHARINDEX('|', @Cabecera, @p5 + 1);
    SET @p7 = CHARINDEX('|', @Cabecera, @p6 + 1);
    SET @p8 = LEN(@Cabecera) + 1;

    /* =========================================================
       VALIDAR FORMATO
       ========================================================= */

    IF @open = 0
       OR @p1 = 0
       OR @p2 = 0
       OR @p3 = 0
       OR @p4 = 0
       OR @p5 = 0
       OR @p6 = 0
       OR @p7 = 0
    BEGIN
        SELECT 'FORMATO_INVALIDO';
        RETURN;
    END;

    /* =========================================================
       DATOS PRINCIPALES
       ========================================================= */

    DECLARE 
        @NotaId numeric(38),
        @UsuarioId int,
        @CajaId numeric(38);

    SET @NotaId = CONVERT(
        numeric(38),
        SUBSTRING(@Cabecera, 1, @p1 - 1)
    );

    SET @UsuarioId = CONVERT(
        int,
        SUBSTRING(
            @Cabecera,
            @p7 + 1,
            @p8 - @p7 - 1
        )
    );

    IF @NotaId IS NULL
       OR ISNULL(@UsuarioId, 0) <= 0
    BEGIN
        SELECT 'FORMATO_INVALIDO';
        RETURN;
    END;

    /* =========================================================
       OBTENER CAJA ACTIVA DEL USUARIO
       ========================================================= */

    SELECT TOP (1)
        @CajaId = CajaId
    FROM Caja
    WHERE CajaEstado = 'ACTIVO'
      AND UsuarioId = @UsuarioId
    ORDER BY CajaId DESC;

    IF ISNULL(@CajaId, 0) = 0
    BEGIN
        SELECT 'false';
        RETURN;
    END;

    /* =========================================================
       INICIAR TRANSACCIÓN
       ========================================================= */

    BEGIN TRANSACTION;

    /* =========================================================
       DEVOLVER STOCK DEL DETALLE ANTERIOR
       ========================================================= */

    UPDATE p
       SET p.ProductoCantidad =
               p.ProductoCantidad
               + (
                    d.DetalleCantidad
                    * ISNULL(NULLIF(d.ValorUM, 0), 1)
                 )
    FROM Producto p
    INNER JOIN DetallePedido d
        ON d.IdProducto = p.IdProducto
    WHERE d.NotaId = @NotaId;

    /* =========================================================
       ACTUALIZAR CABECERA DE LA NOTA
       ========================================================= */

    UPDATE NotaPedido
       SET NotaDocu = SUBSTRING(
                @Cabecera,
                @p1 + 1,
                @p2 - @p1 - 1
           ),
           ClienteId = CONVERT(
                int,
                SUBSTRING(
                    @Cabecera,
                    @p2 + 1,
                    @p3 - @p2 - 1
                )
           ),
           NotaFecha = CONVERT(
                datetime,
                SUBSTRING(
                    @Cabecera,
                    @p3 + 1,
                    @p4 - @p3 - 1
                )
           ),
           NotaUsuario = SUBSTRING(
                @Cabecera,
                @p4 + 1,
                @p5 - @p4 - 1
           ),
           NotaFormaPago = SUBSTRING(
                @Cabecera,
                @p5 + 1,
                @p6 - @p5 - 1
           ),
           NotaCondicion = SUBSTRING(
                @Cabecera,
                @p6 + 1,
                @p7 - @p6 - 1
           ),
           CajaId = @CajaId
    WHERE NotaId = @NotaId;

    /* =========================================================
       ELIMINAR DETALLE ANTERIOR
       ========================================================= */

    DELETE FROM DetallePedido
    WHERE NotaId = @NotaId;

    /* =========================================================
       VARIABLES PARA PROCESAR EL NUEVO DETALLE
       ========================================================= */

    DECLARE
        @fila varchar(max),
        @c1 int,
        @c2 int,
        @c3 int,
        @c4 int,
        @c5 int,
        @c6 int,
        @c7 int,
        @c8 int,
        @c9 int;

    DECLARE
        @IdProducto numeric(20),
        @Cantidad decimal(18,2),
        @ValorUM decimal(18,6);

    /* =========================================================
       RECORRER DETALLE
       ========================================================= */

    WHILE LEN(@Detalle) > 0
    BEGIN

        /* -----------------------------------------------------
           EXTRAER FILA
           ----------------------------------------------------- */

        SET @c1 = CHARINDEX(';', @Detalle);

        IF @c1 = 0
        BEGIN
            SET @fila = @Detalle;
            SET @Detalle = '';
        END;
        ELSE
        BEGIN
            SET @fila = SUBSTRING(
                @Detalle,
                1,
                @c1 - 1
            );

            SET @Detalle = SUBSTRING(
                @Detalle,
                @c1 + 1,
                LEN(@Detalle)
            );
        END;

        /* -----------------------------------------------------
           IDENTIFICAR COLUMNAS
           ----------------------------------------------------- */

        SET @c1 = CHARINDEX('|', @fila);
        SET @c2 = CHARINDEX('|', @fila, @c1 + 1);
        SET @c3 = CHARINDEX('|', @fila, @c2 + 1);
        SET @c4 = CHARINDEX('|', @fila, @c3 + 1);
        SET @c5 = CHARINDEX('|', @fila, @c4 + 1);
        SET @c6 = CHARINDEX('|', @fila, @c5 + 1);
        SET @c7 = CHARINDEX('|', @fila, @c6 + 1);
        SET @c8 = CHARINDEX('|', @fila, @c7 + 1);

        IF @c8 = 0
            SET @c8 = LEN(@fila) + 1;

        SET @c9 = CHARINDEX('|', @fila, @c8 + 1);

        IF @c9 = 0
            SET @c9 = LEN(@fila) + 1;

        /* -----------------------------------------------------
           OBTENER DATOS DEL PRODUCTO
           ----------------------------------------------------- */

        SET @IdProducto = CONVERT(
            numeric(20),
            SUBSTRING(
                @fila,
                1,
                @c1 - 1
            )
        );

        SET @Cantidad = CONVERT(
            decimal(18,2),
            SUBSTRING(
                @fila,
                @c1 + 1,
                @c2 - @c1 - 1
            )
        );

        SET @ValorUM = CONVERT(
            decimal(18,6),
            REPLACE(
                SUBSTRING(
                    @fila,
                    @c8 + 1,
                    @c9 - @c8 - 1
                ),
                ',',
                '.'
            )
        );

        IF @ValorUM <= 0
            SET @ValorUM = 1;

        /* -----------------------------------------------------
           INSERTAR NUEVO DETALLE
           ----------------------------------------------------- */

        INSERT INTO DetallePedido
        (
            NotaId,
            IdProducto,
            DetalleCantidad,
            DetalleUm,
            DetalleDescripcion,
            DetalleCosto,
            DetallePrecio,
            DetalleImporte,
            DetalleEstado,
            ValorUM
        )
        VALUES
        (
            @NotaId,
            @IdProducto,
            @Cantidad,

            SUBSTRING(
                @fila,
                @c2 + 1,
                @c3 - @c2 - 1
            ),

            SUBSTRING(
                @fila,
                @c3 + 1,
                @c4 - @c3 - 1
            ),

            CONVERT(
                decimal(18,2),
                SUBSTRING(
                    @fila,
                    @c4 + 1,
                    @c5 - @c4 - 1
                )
            ),

            CONVERT(
                decimal(18,2),
                SUBSTRING(
                    @fila,
                    @c5 + 1,
                    @c6 - @c5 - 1
                )
            ),

            CONVERT(
                decimal(18,2),
                SUBSTRING(
                    @fila,
                    @c6 + 1,
                    @c7 - @c6 - 1
                )
            ),

            SUBSTRING(
                @fila,
                @c7 + 1,
                @c8 - @c7 - 1
            ),

            @ValorUM
        );

        /* -----------------------------------------------------
           DESCONTAR NUEVO STOCK
           ----------------------------------------------------- */

        UPDATE Producto
           SET ProductoCantidad =
                   ProductoCantidad
                   - (@Cantidad * @ValorUM)
        WHERE IdProducto = @IdProducto;

    END;

    /* =========================================================
       FINALIZAR
       ========================================================= */

    COMMIT TRANSACTION;

    SELECT 'UPDATED';
END;
GO

IF OBJECT_ID(N'dbo.uspEditarNroTransaccion', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEditarNroTransaccion] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEditarNroTransaccion]
@orden varchar(max)
as
begin
Declare @c1 int,@c2 int,@c3 int,
		@c4 int,@c5 int,@c6 int,
		@c7 int,@c8 int,@c9 int,
		@c10 int,@c11 int,@c12 int,
		@c13 int
Declare @RutaOBS varchar(max),@flac int,@UsuarioID int,
        @NotaId numeric(38),@NotaTransaccion varchar(80),
        @Descripcion varchar(max),@NotaImagen varchar(max),
        @NotaTotal decimal(18,2),@CajaId numeric(38),
        @Asistencia int,@Aviso int,@Codigo varchar(80),
        @Cliente varchar(300),@Usuario varchar(80),
        @Saldo decimal(18,2),@ConceptoOBS varchar(80),
        @DetaIdC numeric(38)
Set @c1=CharIndex('|',@orden,0)
Set @c2=CharIndex('|',@orden,@c1+1)
Set @c3=CharIndex('|',@orden,@c2+1)
Set @c4=CharIndex('|',@orden,@c3+1)
Set @c5=CharIndex('|',@orden,@c4+1)
Set @c6=CharIndex('|',@orden,@c5+1)
Set @c7=CharIndex('|',@orden,@c6+1)
Set @c8=CharIndex('|',@orden,@c7+1)
Set @c9=CharIndex('|',@orden,@c8+1)
Set @c10=CharIndex('|',@orden,@c9+1)
Set @c11=CharIndex('|',@orden,@c10+1)
Set @c12=CharIndex('|',@orden,@c11+1)
Set @c13=Len(@orden)+1
set @flac=convert(int,SUBSTRING(@orden,1,@c1-1))
set @RutaOBS=SUBSTRING(@orden,@c1+1,@c2-@c1-1)
set @UsuarioID=convert(int,SUBSTRING(@orden,@c2+1,@c3-@c2-1))
set @NotaId=convert(numeric(38),SUBSTRING(@orden,@c3+1,@c4-@c3-1))
set @NotaTransaccion=SUBSTRING(@orden,@c4+1,@c5-@c4-1)	
set @Descripcion=SUBSTRING(@orden,@c5+1,@c6-@c5-1)	
set @NotaImagen=SUBSTRING(@orden,@c6+1,@c7-@c6-1)
set @NotaTotal=convert(decimal(18,2),SUBSTRING(@orden,@c7+1,@c8-@c7-1))
set @Aviso=convert(int,SUBSTRING(@orden,@c8+1,@c9-@c8-1))
set @Codigo=SUBSTRING(@orden,@c9+1,@c10-@c9-1)
set @Cliente=SUBSTRING(@orden,@c10+1,@c11-@c10-1)
set @Usuario=SUBSTRING(@orden,@c11+1,@c12-@c11-1)
set @Saldo=SUBSTRING(@orden,@c12+1,@c13-@c12-1)

set @Asistencia=(select COUNT(a.PersonalId)from Asistencia a
inner join Usuarios u
on u.PersonalId=a.PersonalId
where u.UsuarioID=@UsuarioId and (Day(a.Fecha)=Day(GETDATE()) and Month(a.Fecha)=MONTH(GETDATE()) and year(a.Fecha)=year(GETDATE())))

if(@Asistencia=0)
begin
Select 'NO ASISTIO'
end

else
begin
IF EXISTS(select top 1 NotaTransaccion from NotaPedido 
where NotaTransaccion=@NotaTransaccion and NotaTransaccion<>'' and NotaEstado<>'ANULADO')
begin
select 'existe'
end
else
begin
set @CajaId=isnull((select top 1 CajaId 
from Caja where CajaEstado='ACTIVO' 
and UsuarioId=@UsuarioId order by 1 desc),'0')
if(@CajaId=0)
begin
select 'false'
end
else
begin
Begin Transaction		
if(@flac=1)
begin
update Usuarios
set UserRuta=@RutaOBS
where UsuarioID=@UsuarioID
end

insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',
@Descripcion,@NotaTotal,@NotaTotal,0,@NotaImagen,'P','',@NotaId,'','EFECTIVO','-','')
set @DetaIdC=(select @@IDENTITY)

 
if(@Saldo<=0)set @ConceptoOBS='VENTA'
else set @ConceptoOBS='POR PASAR AL OBS'

if(@Aviso=1)
begin
insert into DetallesPVS values(@NotaId,GETDATE(),
@Codigo,@Cliente,@NotaTransaccion,@NotaTotal,@Usuario,@DetaIdC)
update NotaPedido
set    CajaId=@CajaId,ConceptoOBS=@ConceptoOBS
where  NotaId=@NotaId
end
else
begin
update NotaPedido
set NotaTransaccion=@NotaTransaccion,
ConceptoOBS=@ConceptoOBS,CajaId=@CajaId
where NotaId=@NotaId
end	
Commit Transaction;
select @RutaOBS 
end
end
end
end
GO

IF OBJECT_ID(N'dbo.uspEditarRB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEditarRB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEditarRB]
@Data varchar(max)
as
begin
Declare  @p1 int,@p2 int,
         @p3 int,@p4 int
Declare  @ResumenId numeric(38),@CodigoSunat varchar(80),
         @MensajeSunat varchar(max),@HASHCDR varchar(max)
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 = CharIndex('|',@Data,@p2+1)
Set @p4= Len(@Data)+1
Set @ResumenId=convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
Set @CodigoSunat=SUBSTRING(@Data,@p1+1,@p2-@p1-1)
Set @MensajeSunat=SUBSTRING(@Data,@p2+1,@p3-@p2-1)
Set @HASHCDR=SUBSTRING(@Data,@p3+1,@p4-@p3-1)
update ResumenBoletas
set CodigoSunat=@CodigoSunat,MensajeSunat=@MensajeSunat,HASHCDR=@HASHCDR
where ResumenId=@ResumenId
SELECT 'true'
end
GO

IF OBJECT_ID(N'dbo.uspEditarRBweb', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEditarRBweb] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE dbo.uspEditarRBweb
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @p1 int, @p2 int, @p3 int, @p4 int, @p5 int
    DECLARE @ResumenId numeric(38),
            @CodigoSunat varchar(80),
            @MensajeSunat varchar(max),
            @HASHCDR varchar(max),
            @CDRBase64 varchar(max)

    SET @Data = LTRIM(RTRIM(@Data))
    SET @p1 = CHARINDEX('|', @Data, 0)
    SET @p2 = CHARINDEX('|', @Data, @p1 + 1)
    SET @p3 = CHARINDEX('|', @Data, @p2 + 1)
    SET @p4 = CHARINDEX('|', @Data, @p3 + 1)
    SET @p5 = LEN(@Data) + 1

    IF (@p4 = 0) SET @p4 = @p5

    SET @ResumenId = CONVERT(numeric(38), SUBSTRING(@Data, 1, @p1 - 1))
    SET @CodigoSunat = SUBSTRING(@Data, @p1 + 1, @p2 - @p1 - 1)
    SET @MensajeSunat = SUBSTRING(@Data, @p2 + 1, @p3 - @p2 - 1)
    SET @HASHCDR = SUBSTRING(@Data, @p3 + 1, @p4 - @p3 - 1)
    SET @CDRBase64 = CASE WHEN @p4 < @p5 THEN SUBSTRING(@Data, @p4 + 1, @p5 - @p4 - 1) ELSE '' END

    UPDATE dbo.ResumenBoletas
       SET CodigoSunat = @CodigoSunat,
           MensajeSunat = @MensajeSunat,
           HASHCDR = @HASHCDR,
           CDRBase64 = CASE WHEN ISNULL(@CDRBase64, '') = '' THEN CDRBase64 ELSE @CDRBase64 END
     WHERE ResumenId = @ResumenId

    SELECT 'true'
END
GO

IF OBJECT_ID(N'dbo.uspEditarTemporal', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEditarTemporal] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEditarTemporal]  
@Data varchar(max)  
as  
begin  
Declare @pos1 int  
Declare @pos2 int  
Declare @pos3 int  
Declare @pos4 int  
Declare @pos5 int  
Declare @pos6 int  
declare @Id numeric(38),  
@cantidad decimal(18,2),  
@precioCosto decimal(18,4),  
@Descuento decimal(18,4),  
@importe decimal(18,2),  
@UsuarioID int  
Set @Data = LTRIM(RTrim(@Data))  
Set @pos1 = CharIndex('|',@Data,0)  
Set @pos2 = CharIndex('|',@Data,@pos1+1)  
Set @pos3 = CharIndex('|',@Data,@pos2+1)  
Set @pos4 = CharIndex('|',@Data,@pos3+1)  
Set @pos5= CharIndex('|',@Data,@pos4+1)  
Set @pos6 =Len(@Data)+1  
Set @Id =convert(numeric(38),SUBSTRING(@Data,1,@pos1-1))  
Set @cantidad=convert(decimal(18,2),SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1))  
Set @precioCosto=convert(decimal(18,4),SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1))  
Set @Descuento=convert(decimal(18,4),SUBSTRING(@Data,@pos3+1,@pos4-@pos3-1))  
Set @importe=convert(decimal(18,4),SUBSTRING(@Data,@pos4+1,@pos5-@pos4-1))  
Set @UsuarioID=convert(int,SUBSTRING(@Data,@pos5+1,@pos6-@pos5-1))  
update TemporalCompra  
set DetalleCantidad=@cantidad,PrecioCosto=@precioCosto,  
DetalleDescuento=@Descuento,DetalleImporte=@importe  
where TemporalId=@Id  
select isnull((select STUFF ((select '¬'+convert(varchar,u.IdUm)+'|'+convert(varchar,u.IdProducto)+'|'+  
u.UMDescripcion+'|'+CONVERT(VarChar(50), cast(u.ValorUM as money ), 1)+'|'+  
convert(varchar,t.PrecioCosto)  
from UnidadMedida u  
inner join TemporalCompra t  
on t.IdProducto=u.IdProducto  
where t.UsuarioID=@UsuarioID  
order by u.ValorUM asc  
for xml path('')),1,1,'')),'true')  
end
GO

IF OBJECT_ID(N'dbo.uspEliminaGasto', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEliminaGasto] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEliminaGasto]
@Data varchar(max)
as
begin
declare @GastoId int
Set @GastoId=convert(int,@Data)
begin
	delete from GastosFijos 
	where GastoId=@GastoId
	select isnull((select STUFF((select '¬'+ CONVERT(varchar,g.GastoId)+'|'+convert(varchar,g.GastoFecha,103)+'|'+
	g.GsstoDesc+'|'+CONVERT(VarChar(50), cast(g.GstoMonto as money ), 1)+'|'+
	(IsNull(convert(varchar,g.GastoReg,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,g.GastoReg,114),1,8),''))+'|'+
	g.GastoUsuario
	from GastosFijos g 
	where month(g.GastoFecha)=month(GETDATE())and year(g.GastoFecha)=year(GETDATE())
	order by g.GastoFecha asc,g.GastoId asc
	FOR XML PATH('')), 1, 1, '')),'~')
end
end
GO

IF OBJECT_ID(N'dbo.uspEliminaLiquiVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEliminaLiquiVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEliminaLiquiVenta]
@ListaOrden varchar(Max)
as
begin
Declare @pos1 int,@pos2 int
Declare @orden varchar(max),
        @detalle varchar(max)
Set @pos1 = CharIndex('[',@ListaOrden,0)
Set @pos2=Len(@ListaOrden)+1
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)
Declare @c1 int
Declare @LiquidacionId numeric(38)
Set @c1 = Len(@orden)+1
set @LiquidacionId=Convert(numeric(38),SUBSTRING(@orden,1,@c1-1))
Begin Transaction
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max)
		Declare @p1 int,@p2 int,@p3 int
		Declare @DetalleId nvarchar(38),
		        @Acuenta decimal(18,2),
		        @NotaId numeric(38)		        		        
Fetch Next From Tabla INTO @Columna
While @@FETCH_STATUS = 0
Begin
		Set @p1 = CharIndex('|',@Columna,0)
		Set @p2 = CharIndex('|',@Columna,@p1+1)
		Set @p3 =Len(@Columna)+1
		set @DetalleId=SUBSTRING(@Columna,1,@p1-1)
		Set @Acuenta=Convert(decimal(18,2),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
		Set @NotaId=SUBSTRING(@Columna,@p2+1,@p3-(@p2+1))
		delete from CajaDetalle
		where LiquidaId=convert(varchar,@LiquidacionId)
		update NotaPedido
		set  NotaAcuenta=NotaAcuenta-@Acuenta,
		NotaSaldo=NotaSaldo + @Acuenta,NotaEstado='EMITIDO'
		where NotaId=@NotaId
Fetch Next From Tabla INTO @Columna
End
	Close Tabla;
	Deallocate Tabla;
	delete from DetaLiquidaVenta
	where LiquidacionId=@LiquidacionId
	delete from LiquidacionVenta
	where LiquidacionId=@LiquidacionId
	Commit Transaction;
	select 'true'
end
GO

IF OBJECT_ID(N'dbo.uspEliminarApertura', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEliminarApertura] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEliminarApertura]
@IdApertura numeric(38)
as
begin
delete from DetalleCierre
where IdApertura=@IdApertura
delete from DetalleApertura
where IdApertura=@IdApertura
delete from APERTURA_ALMACEN
where IdApertura=@IdApertura
select 'true'
end
GO

IF OBJECT_ID(N'dbo.uspEliminarCajaDetalle', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEliminarCajaDetalle] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEliminarCajaDetalle]
@Datas varchar(max)
as
begin
Declare @pos1 int,@pos2 int
Declare @pos3 int,@pos4 int
Declare @DetalleId numeric(38),
        @FormaPago varchar(80),
        @EntidadBancaria varchar(80),
        @NroOperacion varchar(80)
Set @Datas = LTRIM(RTrim(@Datas))
Set @pos1 = CharIndex('|',@Datas,0)
Set @pos2 = CharIndex('|',@Datas,@pos1+1)
Set @pos3 = CharIndex('|',@Datas,@pos2+1)
Set @pos4= Len(@Datas)+1

Set @DetalleId=convert(numeric(38),SUBSTRING(@Datas,1,@pos1-1))
Set @FormaPago=SUBSTRING(@Datas,@pos1+1,@pos2-@pos1-1)
Set @EntidadBancaria=SUBSTRING(@Datas,@pos2+1,@pos3-@pos2-1)
Set @NroOperacion=SUBSTRING(@Datas,@pos3+1,@pos4-@pos3-1)

declare @Data varchar(max)
declare @c1 int,@c2 int
declare @Estado nvarchar(1)
declare @NotaIdB nvarchar(38)
set @Data=(select top 1 d.Estado+'|'+CONVERT(varchar,d.NotaIdB)
from CajaDetalle d
where d.DetalleId=@DetalleId)
Set @c1 = CharIndex('|',@Data,0)
Set @c2 =Len(@Data)+1
set @Estado=SUBSTRING(@Data,1,@c1-1)
set @NotaIdB=SUBSTRING(@Data,@c1+1,@c2-@c1-1)
if(@Estado='P')
begin
Begin Transaction
update NotaPedido
set NotaTransaccion='',ConceptoOBS='POR PASAR AL OBS'
where NotaId=@NotaIdB
delete from CajaDetalle
where DetalleId=@DetalleId
delete from DetallesPVS
where DetaIdC=@DetalleId
select 'true'
Commit Transaction;
end
else
begin
delete from CajaDetalle
where DetalleId=@DetalleId
select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.uspEliminarGuiaLiquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEliminarGuiaLiquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEliminarGuiaLiquida]
@ListaOrden varchar(Max)
as
begin
Declare @pos1 int,@pos2 int
Declare @orden varchar(max),
        @detalle varchar(max)
Set @pos1 = CharIndex('[',@ListaOrden,0)
Set @pos2=Len(@ListaOrden)+1
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)
Declare @c1 int,@c2 int,@c3 int,@c4 int,
        @c5 int,@c6 int,@c7 int,@c8 int
Declare @GuiaId numeric(38),@NotaId numeric(38),
        @Total decimal(18,2),@Condicion varchar(40),
        @GuiaNumero varchar(40),@CodigoRes varchar(80),
        @Responsable varchar(80),@Usuario varchar(80)
Set @c1= CharIndex('|',@orden,0)
Set @c2= CharIndex('|',@orden,@c1+1)
Set @c3= CharIndex('|',@orden,@c2+1)
Set @c4= CharIndex('|',@orden,@c3+1)
Set @c5= CharIndex('|',@orden,@c4+1)
Set @c6= CharIndex('|',@orden,@c5+1)
Set @c7= CharIndex('|',@orden,@c6+1)
Set @c8= Len(@orden)+1
set @GuiaId=convert(numeric(38),SUBSTRING(@orden,1,@c1-1))
set @NotaId=convert(numeric(38),SUBSTRING(@orden,@c1+1,@c2-@c1-1))
set @Total=convert(decimal(18,2),SUBSTRING(@orden,@c2+1,@c3-@c2-1))
set @Condicion=SUBSTRING(@orden,@c3+1,@c4-@c3-1)
set @GuiaNumero=SUBSTRING(@orden,@c4+1,@c5-@c4-1)
set @CodigoRes=SUBSTRING(@orden,@c5+1,@c6-@c5-1)
set @Responsable=SUBSTRING(@orden,@c6+1,@c7-@c6-1)
set @Usuario=SUBSTRING(@orden,@c7+1,@c8-@c7-1)
Begin Transaction
if(@Condicion='CREDITO')
BEGIN
Update NotaPedido
set NotaSaldo=NotaSaldo+@Total,NotaAcuenta=NotaAcuenta-@Total,NotaEstado='EMITIDO'
where NotaId=@NotaId
END
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max),
		@DetalleId numeric(38),
		@Idproducto numeric(38),
		@Cantidad decimal(18,2),
		@Precio decimal(18,2)			
		Declare @IniciaStock decimal(18,2),
		@StockFinal decimal(18,2),@CodigoPro varchar(80)
Declare @p1 int,@p2 int,@p3 int,@p4 int
Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	Begin
Set @p1 = CharIndex('|',@Columna,0)
Set @p2 = CharIndex('|',@Columna,@p1+1)
Set @p3 = CharIndex('|',@Columna,@p2+1)
Set @p4= Len(@Columna)+1
Set @DetalleId=Convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))
Set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
Set @Cantidad=Convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))
Set @Precio=Convert(decimal(18,2),SUBSTRING(@Columna,@p3+1,@p4-(@p3+1)))
   
    set @CodigoPro=isnull((select top 1 ProductoCodigo from Producto
    where IdProducto=@IdProducto),'0')
    if(@CodigoPro='PEKIT-3')
    begin      
	
	update producto 
	set  ProductoCantidad=ProductoCantidad + @Cantidad
	where IDProducto=7
	
    end
       
    set @IniciaStock=(select top 1 ProductoCantidad from Producto 
    where IdProducto=@IdProducto)
	set @StockFinal=@IniciaStock+@Cantidad
	
    insert into Kardex values(@IdProducto,GETDATE(),'Ingreso por Venta',
    SUBSTRING(@GuiaNumero,6,13),@IniciaStock,@Cantidad,0,
    @Precio,@StockFinal,'INGRESO',@Usuario,@Responsable,
	@CodigoRes,'','101',SUBSTRING(@GuiaNumero,1,4),'02','S','','','B')
	
	update producto 
	set  ProductoCantidad=ProductoCantidad + @Cantidad
	where IDProducto=@IdProducto
	
	update DetallePedido
	set CantidadSaldo=CantidadSaldo+@Cantidad
	where DetalleId=@DetalleId
	
Fetch Next From Tabla INTO @Columna
end
	Close Tabla;
	Deallocate Tabla;
	delete from DetalleGuiaLiquida 
	where GuiaId=@GuiaId
	
	delete from GuiaLiquidacion
	where GuiaId=@GuiaId
	
	delete from CajaDetalle 
	where NotaIdB=@GuiaId AND LiquidaId='G'
	
    update NotaPedido
	set NotaEntrega='POR ENTREGAR'
	where NotaId=@NotaId	
	
	delete from Kardex
	where KardexDocumento=SUBSTRING(@GuiaNumero,6,13) and 
	Serie=SUBSTRING(@GuiaNumero,1,4)
	
	Commit Transaction;
	select 'true'	
end
GO

IF OBJECT_ID(N'dbo.uspEliminarPagoV', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEliminarPagoV] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEliminarPagoV]  
@ListaOrden varchar(Max)  
as  
begin  
Declare @pos int  
Declare @orden varchar(max)  
Declare @detalle varchar(max)  
Set @pos = CharIndex('[',@ListaOrden,0)  
Set @orden = SUBSTRING(@ListaOrden,1,@pos-1)  
Set @detalle = SUBSTRING(@ListaOrden,@pos+1,len(@ListaOrden)-@pos)  
Declare @pos1 int  
Declare @PagoId numeric(38)  
Set @pos1 =Len(@orden)+1  
Set @PagoId=convert(numeric(38),SUBSTRING(@orden,1,@pos1-1))  
  
Begin Transaction  
  
delete from DetallePVarios  
where PagoId=@PagoId

delete from PagoVarios  
where PagoId=@PagoId  

delete from CajaDetalle  
where NotaIdB=@PagoId  
  
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')   
Open Tabla  
Declare @Columna varchar(max),  
  @DocuId numeric(38),  
  @NotaId numeric(38)  
  
Declare @p1 int,@p2 int  
Fetch Next From Tabla INTO @Columna  
 While @@FETCH_STATUS = 0  
 Begin  
Set @p1 = CharIndex('|',@Columna,0)  
Set @p2 = Len(@Columna)+1  
  
set @DocuId=Convert(numeric(20),SUBSTRING(@Columna,1,@p1-1))  
Set @NotaId=convert(numeric(20),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))  
  
update NotaPedido  
set Efectivo=0,Deposito=0,NotaEstado='PENDIENTE',NotaFormaPago='-',  
EntidadBancaria='-',NroOperacion=''  
Where NotaId=@NotaId  
  
update DocumentoVenta  
set Efectivo=0,Deposito=0,FormaPago='-',EntidadBancaria='-',  
NroOperacion=''  
Where DocuId=@DocuId

delete from CajaDetalle
where NotaId=@NotaId
  
Fetch Next From Tabla INTO @Columna  
end  
 Close Tabla;  
 Deallocate Tabla;  
    Commit Transaction;  
    select 'true'  
end
GO

IF OBJECT_ID(N'dbo.uspeliminaTD', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspeliminaTD] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspeliminaTD]
@UsuarioID  int
as
begin
delete from TemporalVenta 
where UsuarioID=@UsuarioID
select
    isnull((select STUFF ((select '¬'+convert(varchar,t.temporalId)+'|'+CONVERT(varchar,t.UsuarioId)+'|'+convert(varchar,t.IdProducto)+'|'+
    p.ProductoCodigo+'|'+convert(varchar,t.cantidad)+'|'+t.UniMedida+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
	convert(varchar,cast((p.ProductoCosto* t.ValorUM) as decimal(18,2)))+'|'+
	convert(varchar,t.precioventa)+'|'+
    CONVERT(VarChar(50), cast((t.cantidad*p.ProductoPV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast((t.cantidad*p.ProductoSV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(t.importe as money ), 1)+'|'+
	p.ProductoImagen+'|'+
	convert(varchar,t.ValorUM)+'|'+
	convert(varchar,convert(decimal(18,2),t.precioventa/1.18))+'|'+
	convert(varchar,(t.importe - convert(decimal(18,2),t.importe/1.18)))+'|'+
	convert(varchar,convert(decimal(18,2),t.importe/1.18))+'|'+
	convert(varchar,p.ProductoPV)+'|'+convert(varchar,p.ProductoSV)
	from TemporalVenta t
	inner join Producto p
	on p.IdProducto=t.IdProducto
	where t.UsuarioID=@UsuarioID 
	order by t.temporalId asc
	for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspeliminaTem', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspeliminaTem] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspeliminaTem]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int
Declare @TemporalId numeric(38),
        @UsuarioID  int
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2= Len(@Data)+1
Set @TemporalId=convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
Set @UsuarioID=convert(int,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
delete from TemporalVenta 
where TemporalId=@TemporalId
select
    isnull((select STUFF ((select '¬'+convert(varchar,t.temporalId)+'|'+CONVERT(varchar,t.UsuarioId)+'|'+convert(varchar,t.IdProducto)+'|'+
    p.ProductoCodigo+'|'+convert(varchar,t.cantidad)+'|'+t.UniMedida+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
	convert(varchar,cast((p.ProductoCosto* t.ValorUM) as decimal(18,2)))+'|'+
	convert(varchar,t.precioventa)+'|'+
    CONVERT(VarChar(50), cast((t.cantidad*p.ProductoPV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast((t.cantidad*p.ProductoSV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(t.importe as money ), 1)+'|'+
	p.ProductoImagen+'|'+
	convert(varchar,t.ValorUM)+'|'+
	convert(varchar,convert(decimal(18,2),t.precioventa/1.18))+'|'+
	convert(varchar,(t.importe - convert(decimal(18,2),t.importe/1.18)))+'|'+
	convert(varchar,convert(decimal(18,2),t.importe/1.18))+'|'+
	convert(varchar,p.ProductoPV)+'|'+convert(varchar,p.ProductoSV)+'|'+
	s.NombreSublinea+'|'+p.AplicaFB
	from TemporalVenta t
	inner join Producto p
	on p.IdProducto=t.IdProducto
	inner join Sublinea s
	on s.IdSubLinea=p.IdSubLinea
	where t.UsuarioID=@UsuarioID 
	order by t.temporalId asc
	for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspeliminaTemB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspeliminaTemB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspeliminaTemB]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int
Declare @IdProducto numeric(20),
        @UsuarioID  int
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2= Len(@Data)+1
Set @IdProducto=convert(numeric(20),SUBSTRING(@Data,1,@p1-1))
Set @UsuarioID=convert(int,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
delete from TemporalVenta 
where IdProducto=@IdProducto and UsuarioID=@UsuarioID
select
    isnull((select STUFF ((select '¬'+convert(varchar,t.temporalId)+'|'+CONVERT(varchar,t.UsuarioId)+'|'+convert(varchar,t.IdProducto)+'|'+
    p.ProductoCodigo+'|'+convert(varchar,t.cantidad)+'|'+t.UniMedida+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
	convert(varchar,cast((p.ProductoCosto* t.ValorUM) as decimal(18,2)))+'|'+
	convert(varchar,t.precioventa)+'|'+
    CONVERT(VarChar(50), cast((t.cantidad*p.ProductoPV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast((t.cantidad*p.ProductoSV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(t.importe as money ), 1)+'|'+
	p.ProductoImagen+'|'+
	convert(varchar,t.ValorUM)+'|'+
	convert(varchar,convert(decimal(18,2),t.precioventa/1.18))+'|'+
	convert(varchar,(t.importe - convert(decimal(18,2),t.importe/1.18)))+'|'+
	convert(varchar,convert(decimal(18,2),t.importe/1.18))+'|'+
	convert(varchar,p.ProductoPV)+'|'+convert(varchar,p.ProductoSV)+'|'+
    s.NombreSublinea
	from TemporalVenta t
	inner join Producto p
	on p.IdProducto=t.IdProducto
	inner join Sublinea s
    on s.IdSubLinea=p.IdSubLinea
	where t.UsuarioID=@UsuarioID 
	order by t.temporalId asc
	for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspeliminaTemTD', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspeliminaTemTD] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspeliminaTemTD]
@UsuarioID  int
as
begin
delete from TemporalVenta 
where UsuarioID=@UsuarioID
select
    isnull((select STUFF ((select '¬'+convert(varchar,t.temporalId)+'|'+CONVERT(varchar,t.UsuarioId)+'|'+convert(varchar,t.IdProducto)+'|'+
    p.ProductoCodigo+'|'+convert(varchar,t.cantidad)+'|'+t.UniMedida+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
	convert(varchar,cast((p.ProductoCosto* t.ValorUM) as decimal(18,2)))+'|'+
	convert(varchar,t.precioventa)+'|'+
    CONVERT(VarChar(50), cast((t.cantidad*p.ProductoPV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast((t.cantidad*p.ProductoSV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(t.importe as money ), 1)+'|'+
	p.ProductoImagen+'|'+
	convert(varchar,t.ValorUM)+'|'+
	convert(varchar,convert(decimal(18,2),t.precioventa/1.18))+'|'+
	convert(varchar,(t.importe - convert(decimal(18,2),t.importe/1.18)))+'|'+
	convert(varchar,convert(decimal(18,2),t.importe/1.18))+'|'+
	convert(varchar,p.ProductoPV)+'|'+convert(varchar,p.ProductoSV)+'|'+
    s.NombreSublinea
	from TemporalVenta t
	inner join Producto p
	on p.IdProducto=t.IdProducto
	inner join Sublinea s
    on s.IdSubLinea=p.IdSubLinea
	where t.UsuarioID=@UsuarioID 
	order by t.temporalId asc
	for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspEnviarDocu', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspEnviarDocu] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspEnviarDocu]
@Id int,
@fechainicio date,
@fechafin date
as
select 
isnull((select STUFF ((select '¬'+convert(varchar,d.DocuId)+'|'+convert(varchar,d.CompaniaId)+'|'+
convert(varchar,d.NotaId)+'|'+d.DocuDocumento+'|'+
d.DocuSerie+'-'+d.DocuNumero+'|'+c.ClienteRazon+'|'+c.ClienteRuc+'|'+c.ClienteDni+'|'+c.ClienteDireccion+'|'+c.ClienteDespacho+'|'+Convert(char(10),d.DocuEmision,110)+'|'+
CONVERT(VarChar(50),d.DocuTotal)+'|'+d.DocuUsuario+'|'+d.DocuEstado
from DocumentoVenta d
inner join Cliente c
on c.ClienteId=d.ClienteId
where d.CompaniaId=@Id and d.ClienteId <>47 and ((Convert(char(10),d.DocuEmision,103) BETWEEN @fechainicio AND @fechafin)and d.DocuDocumento<>'PROFORMA V')
order by d.DocuEmision asc
for xml path('')),1,1,'')),'~')+'['+
isnull((select STUFF ((select '¬'+convert(varchar,d.DocuId)+'|'+convert(varchar,d.IdProducto)+'|'+
p.ProductoCodigo+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
CONVERT(VarChar(50),d.DetalleCantidad)+'|'+d.DetalleUM+'|'+
CONVERT(VarChar(50),d.DetallPrecio)+'|'+
CONVERT(VarChar(50),d.DetalleImporte)
FROM DetalleDocumento d
inner join DocumentoVenta v
on v.DocuId=d.DocuId
inner join Producto p
on p.IdProducto=d.IdProducto
where v.CompaniaId=@Id and v.ClienteId <>47 and ((Convert(char(10),v.DocuEmision,103) BETWEEN @fechainicio AND @fechafin)and v.DocuDocumento<>'PROFORMA V')
order by v.DocuId asc
for xml path('')),1,1,'')),'~')
GO

IF OBJECT_ID(N'dbo.uspGasto', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspGasto] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspGasto]
as
begin
select
'Id|Fecha|Descripcion|Monto|FechaRe|Usuario¬100|120|415|125|100|100¬String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+ CONVERT(varchar,g.GastoId)+'|'+convert(varchar,g.GastoFecha,103)+'|'+
g.GsstoDesc+'|'+CONVERT(VarChar(50), cast(g.GstoMonto as money ), 1)+'|'+
(IsNull(convert(varchar,g.GastoReg,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,g.GastoReg,114),1,8),''))+'|'+
g.GastoUsuario
from GastosFijos g 
where month(g.GastoFecha)=month(GETDATE())and year(g.GastoFecha)=year(GETDATE())
order by g.GastoFecha asc,g.GastoId asc
FOR XML PATH('')), 1, 1, '')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspGastoFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspGastoFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspGastoFecha]
@fechainicio date,
@fechafin date
as
begin
select
'Id|Fecha|Descripcion|Monto|FechaRe|Usuario¬100|120|415|125|100|100¬String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+ CONVERT(varchar,g.GastoId)+'|'+convert(varchar,g.GastoFecha,103)+'|'+
g.GsstoDesc+'|'+CONVERT(VarChar(50), cast(g.GstoMonto as money ), 1)+'|'+
(IsNull(convert(varchar,g.GastoReg,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,g.GastoReg,114),1,8),''))+'|'+
g.GastoUsuario
from GastosFijos g 
where (Convert(char(10),g.GastoFecha,103) BETWEEN @fechainicio AND @fechafin)
order by g.GastoFecha asc,g.GastoId asc
FOR XML PATH('')), 1, 1, '')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspGuardarCredencialesSunatweb', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspGuardarCredencialesSunatweb] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE dbo.uspGuardarCredencialesSunatweb
    @CompaniaId int,
    @UsuarioSOL varchar(100),
    @ClaveSOL varchar(100),
    @CertificadoBase64 varchar(max),
    @ClaveCertificado varchar(100),
    @Entorno int
AS
BEGIN
    SET NOCOUNT ON

    IF NOT EXISTS (SELECT 1 FROM dbo.Compania WHERE CompaniaId = @CompaniaId)
    BEGIN
        RAISERROR('CompaniaId no existe.', 16, 1)
        RETURN
    END

    UPDATE dbo.Compania
       SET CompaniaUserSecun = @UsuarioSOL,
           ComapaniaPWD = @ClaveSOL,
           CompaniaPFX = @CertificadoBase64,
           CompaniaClave = @ClaveCertificado,
           TIPO_PROCESO = ISNULL(@Entorno, 3)
     WHERE CompaniaId = @CompaniaId
END
GO

IF OBJECT_ID(N'dbo.uspHistoria', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspHistoria] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspHistoria]
@ClienteId numeric(20),
@IdProducto numeric(20)
as
begin
select
'FechaVenta|PrecioUni|Cantidad|UM|Vendedor¬140|100|100|80|150¬String|String|String|String|String¬'+
isnull((select stuff((select '¬'+(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
CONVERT(VarChar(50),cast(d.DetallePrecio as money ), 1)+'|'+
CONVERT(VarChar(50),cast(d.DetalleCantidad as money ), 1)+'|'+d.DetalleUm+'|'+
n.NotaUsuario
from DetallePedido d 
inner join NotaPedido n 
on n.NotaId=d.NotaId
where n.ClienteId=@ClienteId and (d.IdProducto=@IdProducto and n.NotaEstado<>'PENDIENTE') 
order by n.NotaFecha desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspInsertaAutorizacion', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertaAutorizacion] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertaAutorizacion]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,@p3 int,
        @p4 int,@p5 int,@p6 int,
        @p7 int,@p8 int
Declare @IdAuto numeric(38),
        @UsuarioId int,@Encargado varchar(80),
        @HoraInicio datetime,@Tiempo int,
        @HoraFin datetime,@Observaciones varchar(max),
        @Autorizado varchar(80)
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 = CharIndex('|',@Data,@p2+1)
Set @p4 = CharIndex('|',@Data,@p3+1)
Set @p5 = CharIndex('|',@Data,@p4+1)
Set @p6 = CharIndex('|',@Data,@p5+1)
Set @p7 = CharIndex('|',@Data,@p6+1)
Set @p8= Len(@Data)+1
Set @IdAuto=convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
Set @UsuarioId=convert(int,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
Set @Encargado=SUBSTRING(@Data,@p2+1,@p3-@p2-1)
Set @HoraInicio=convert(datetime,SUBSTRING(@Data,@p3+1,@p4-@p3-1))
Set @Tiempo=convert(int,SUBSTRING(@Data,@p4+1,@p5-@p4-1))
Set @HoraFin=convert(datetime,SUBSTRING(@Data,@p5+1,@p6-@p5-1))
Set @Observaciones=SUBSTRING(@Data,@p6+1,@p7-@p6-1)
Set @Autorizado=SUBSTRING(@Data,@p7+1,@p8-@p7-1)
if(@IdAuto=0)
begin
IF EXISTS(select a.IdAuto from AutorizaEdicion a 
where convert(date,a.HoraInicio)=convert(date,@HoraInicio) and a.UsuarioId=@UsuarioId)
begin
select 'existe'
end
else
begin
insert into AutorizaEdicion values(@UsuarioId,@Encargado,
@HoraInicio,@Tiempo,@HoraFin,@Observaciones,@Autorizado,GETDATE())
select 'true'
end
end
else
begin
update AutorizaEdicion
set UsuarioId=@UsuarioId,Encargado=@Encargado,
HoraInicio=@HoraInicio,Tiempo=@Tiempo,HoraFin=@HoraFin,
Observaciones=@Observaciones,Autorizado=@Autorizado
where IdAuto=@IdAuto
select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.uspinsertaDetalleTurno', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspinsertaDetalleTurno] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspinsertaDetalleTurno]
@ListaOrden varchar(Max)
as
begin
Declare @pos1 int,@pos2 int
Declare @orden varchar(max),
        @detalle varchar(max)
Set @pos1 = CharIndex('[',@ListaOrden,0)
Set @pos2=Len(@ListaOrden)+1
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)
Declare @c1 int,@c2 int
Set @c1 = CharIndex('|',@orden,0)
Set @c2 =  Len(@orden)+1    
Declare @PersonalId numeric(20),
        @TurnoId int
set @PersonalId=convert(numeric(20),SUBSTRING(@orden,1,@c1-1))
set @TurnoId=convert(int,SUBSTRING(@orden,@c1+1,@c2-@c1-1))
Declare @Aviso int
set @Aviso=(select COUNT(d.PersonalId) from DetalleTurnos d
where PersonalId=@PersonalId)
Begin Transaction
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
        Declare @Columna varchar(max)
        Declare @DetalleId numeric(38),
        @Estado bit,
        @Dia nvarchar(40)
        Declare @p1 int,@p2 int,@p3 int
Fetch Next From Tabla INTO @Columna
While @@FETCH_STATUS = 0
Begin
        Set @Columna= LTRIM(RTrim(@Columna))
		Set @p1 = CharIndex('|',@Columna,0)
		Set @p2 = CharIndex('|',@Columna,@p1+1)
		Set @p3=Len(@Columna)+1
        Set @DetalleId=Convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))
		Set @Estado=SUBSTRING(@Columna,@p1+1,@p2-(@p1+1))
		Set @Dia=SUBSTRING(@Columna,@p2+1,@p3-(@p2+1))
		if(@Aviso=0)
        begin
        insert into DetalleTurnos values(@PersonalId,1,@Dia,'0')
        set @DetalleId=(select @@IDENTITY)
        update DetalleTurnos
		set TurnoId=@TurnoId,Estado=@Estado
		where DetalleId=@DetalleId
        end
        else
        begin
		update DetalleTurnos
		set TurnoId=@TurnoId,Estado=@Estado
		where PersonalId=@PersonalId and Dia=@Dia
		end
Fetch Next From Tabla INTO @Columna
End
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
	Select 'true';
end
GO

IF OBJECT_ID(N'dbo.uspinsertaFactura', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspinsertaFactura] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspinsertaFactura]    
@ListaOrden varchar(Max)    
as    
begin    
Declare @pos int    
Declare @orden varchar(max)    
Declare @detalle varchar(max)    
Set @pos = CharIndex('[',@ListaOrden,0)    
Set @orden = SUBSTRING(@ListaOrden,1,@pos-1)    
Set @detalle = SUBSTRING(@ListaOrden,@pos+1,len(@ListaOrden)-@pos)    
Declare @pos1 int,@pos2 int,@pos3 int,@pos4 int,    
        @pos5 int,@pos6 int,@pos7 int,@pos8 int,    
        @pos9 int,@pos10 int,@pos11 int,@pos12 int,    
        @pos13 int,@pos14 int,@pos15 int,@pos16 int,    
        @pos17 int,@pos18 int,@pos19 int,@pos20 int,    
        @pos21 int,@pos22 int,@pos23 int,@pos24 int,    
        @pos25 int,@pos26 int,@pos27 int,@pos28 int,    
        @pos29 int,@pos30 int,@pos31 int,@pos32 int,    
        @pos33 int,@pos34 int,@pos35 int,@pos36 int,    
        @pos37 int    
 Declare @CompaniaId int,@NotaId numeric(38),@DocuDocumento varchar(60),    
         @DocuNumero varchar(60),@ClienteId numeric(20),@DocuEmision date,    
         @DocuSubTotal decimal(18,2),@DocuIgv decimal(18,2),@DocuTotal decimal(18,2),    
         @DocuUsuario varchar(60),@DocuSerie char(4),@TipoCodigo nvarchar(10),    
         @DocuAdicional decimal(18,2),@DocuAsociado varchar(80),    
         @DocuConcepto varchar(80),@DocuHASH varchar(250),@EstadoSunat varchar(80),    
         @Letras varchar(60),@DocuId numeric(38),@TraeEstado varchar(80),    
         @CajaId numeric(38),@UsuarioId int,@NotaFormaPago varchar(60),    
         @Movimiento varchar(40),@Concepto varchar(40),@Transaccion varchar(250),    
         @Miembro varchar(300),@CodigoCliente varchar(80),    
         @ICBPER DECIMAL(18,2),@CodigoSunat varchar(80),@MensajeSunat varchar(max),    
         @DocuGRAVADA decimal(18,2),@ConceptoOBS varchar(80),@Image varchar(max),    
   @PV decimal(18,2),@TEXTO varchar(300),@Condicion varchar(80),    
   @Entrega varchar(80),@EntidadBancaria varchar(80),    
   @Efectivo decimal(18,2),@Deposito decimal(18,2),    
   @NroOperacion varchar(80),@DocuPago datetime    
Set @pos1 = CharIndex('|',@orden,0)    
Set @pos2 = CharIndex('|',@orden,@pos1+1)    
Set @pos3 = CharIndex('|',@orden,@pos2+1)    
Set @pos4 = CharIndex('|',@orden,@pos3+1)    
Set @pos5 = CharIndex('|',@orden,@pos4+1)    
Set @pos6= CharIndex('|',@orden,@pos5+1)    
Set @pos7 = CharIndex('|',@orden,@pos6+1)    
Set @pos8 = CharIndex('|',@orden,@pos7+1)    
Set @pos9 = CharIndex('|',@orden,@pos8+1)    
Set @pos10= CharIndex('|',@orden,@pos9+1)    
Set @pos11= CharIndex('|',@orden,@pos10+1)    
Set @pos12= CharIndex('|',@orden,@pos11+1)    
Set @pos13= CharIndex('|',@orden,@pos12+1)    
Set @pos14= CharIndex('|',@orden,@pos13+1)    
Set @pos15= CharIndex('|',@orden,@pos14+1)    
Set @pos16= CharIndex('|',@orden,@pos15+1)    
Set @pos17= CharIndex('|',@orden,@pos16+1)    
Set @pos18= CharIndex('|',@orden,@pos17+1)    
Set @pos19= CharIndex('|',@orden,@pos18+1)    
Set @pos20= CharIndex('|',@orden,@pos19+1)    
Set @pos21= CharIndex('|',@orden,@pos20+1)    
Set @pos22=CharIndex('|',@orden,@pos21+1)    
Set @pos23= CharIndex('|',@orden,@pos22+1)    
Set @pos24= CharIndex('|',@orden,@pos23+1)    
Set @pos25=CharIndex('|',@orden,@pos24+1)    
Set @pos26= CharIndex('|',@orden,@pos25+1)    
Set @pos27= CharIndex('|',@orden,@pos26+1)    
Set @pos28= CharIndex('|',@orden,@pos27+1)    
Set @pos29= CharIndex('|',@orden,@pos28+1)    
Set @pos30= CharIndex('|',@orden,@pos29+1)    
Set @pos31= CharIndex('|',@orden,@pos30+1)    
Set @pos32= CharIndex('|',@orden,@pos31+1)    
    
Set @pos33= CharIndex('|',@orden,@pos32+1)    
Set @pos34= CharIndex('|',@orden,@pos33+1)    
Set @pos35= CharIndex('|',@orden,@pos34+1)    
Set @pos36= CharIndex('|',@orden,@pos35+1)    
    
Set @pos37= Len(@orden)+1    
Set @CompaniaId=convert(int,SUBSTRING(@orden,1,@pos1-1))    
Set @NotaId=convert(numeric(38),SUBSTRING(@orden,@pos1+1,@pos2-@pos1-1))    
Set @DocuDocumento=SUBSTRING(@orden,@pos2+1,@pos3-@pos2-1)    
Set @DocuNumero=SUBSTRING(@orden,@pos3+1,@pos4-@pos3-1)    
Set @ClienteId=convert(numeric(20),SUBSTRING(@orden,@pos4+1,@pos5-@pos4-1))    
Set @DocuEmision=convert(date,SUBSTRING(@orden,@pos5+1,@pos6-@pos5-1))    
Set @DocuSubTotal=convert(decimal(18,2),SUBSTRING(@orden,@pos6+1,@pos7-@pos6-1))    
Set @DocuIgv=convert(decimal(18,2),SUBSTRING(@orden,@pos7+1,@pos8-@pos7-1))    
Set @DocuTotal=convert(decimal(18,2),SUBSTRING(@orden,@pos8+1,@pos9-@pos8-1))    
Set @DocuUsuario=SUBSTRING(@orden,@pos9+1,@pos10-@pos9-1)    
Set @DocuSerie=SUBSTRING(@orden,@pos10+1,@pos11-@pos10-1)    
Set @TipoCodigo=SUBSTRING(@orden,@pos11+1,@pos12-@pos11-1)    
set @DocuAdicional=convert(decimal(18,2),SUBSTRING(@orden,@pos12+1,@pos13-@pos12-1))    
set @DocuAsociado=SUBSTRING(@orden,@pos13+1,@pos14-@pos13-1)    
set @DocuConcepto=SUBSTRING(@orden,@pos14+1,@pos15-@pos14-1)    
set @DocuHASH=SUBSTRING(@orden,@pos15+1,@pos16-@pos15-1)    
set @EstadoSunat=SUBSTRING(@orden,@pos16+1,@pos17-@pos16-1)    
set @Letras=SUBSTRING(@orden,@pos17+1,@pos18-@pos17-1)    
set @UsuarioId=convert(int,SUBSTRING(@orden,@pos18+1,@pos19-@pos18-1))    
set @NotaFormaPago=SUBSTRING(@orden,@pos19+1,@pos20-@pos19-1)    
set @Concepto=SUBSTRING(@orden,@pos20+1,@pos21-@pos20-1)    
set @Transaccion=SUBSTRING(@orden,@pos21+1,@pos22-@pos21-1)    
set @Miembro=SUBSTRING(@orden,@pos22+1,@pos23-@pos22-1)    
set @CodigoCliente=SUBSTRING(@orden,@pos23+1,@pos24-@pos23-1)    
set @ICBPER=convert(decimal(18,2),SUBSTRING(@orden,@pos24+1,@pos25-@pos24-1))    
set @CodigoSunat=SUBSTRING(@orden,@pos25+1,@pos26-@pos25-1)    
set @MensajeSunat=SUBSTRING(@orden,@pos26+1,@pos27-@pos26-1)    
set @DocuGRAVADA=SUBSTRING(@orden,@pos27+1,@pos28-@pos27-1)    
set @ConceptoOBS=SUBSTRING(@orden,@pos28+1,@pos29-@pos28-1)    
set @Image=SUBSTRING(@orden,@pos29+1,@pos30-@pos29-1)    
set @Condicion=SUBSTRING(@orden,@pos30+1,@pos31-@pos30-1)    
set @Entrega=SUBSTRING(@orden,@pos31+1,@pos32-@pos31-1)    
set @EntidadBancaria=SUBSTRING(@orden,@pos32+1,@pos33-@pos32-1)    
    
set @Efectivo=convert(decimal(18,2),SUBSTRING(@orden,@pos33+1,@pos34-@pos33-1))    
set @Deposito=convert(decimal(18,2),SUBSTRING(@orden,@pos34+1,@pos35-@pos34-1))    
set @NroOperacion=SUBSTRING(@orden,@pos35+1,@pos36-@pos35-1)    
set @DocuPago=convert(datetime,SUBSTRING(@orden,@pos36+1,@pos37-@pos36-1))    
    
set @PV=(select SUM(d.DetallePV) from DetallePedido d    
where d.NotaId=@NotaId)    
    
if(@ConceptoOBS='PUNTOS A ICA' or @ConceptoOBS='PUNTOS A COMAS')    
begin    
set @TEXTO='SE MANDO A PASAR '+@ConceptoOBS+' CODIGO: '+@CodigoCliente+' ('+@Miembro+')'    
end    
else if(@ConceptoOBS='POR PASAR AL OBS')    
begin    
set @TEXTO='CANCELARON PRODUCTOS POR PASAR AL OBS '+convert(varchar,@PV) +' CODIGO: '+@CodigoCliente+' ('+@Miembro+')'    
end    
else if(@ConceptoOBS='VENTA LIBRE')    
begin    
set @TEXTO='VENTA LIBRE. SE VENDIO SIN CODIGO ('+@Miembro+')'    
end    
else if(@ConceptoOBS='FACTURA MANUAL')    
begin    
set @TEXTO='FACTURA MANUAL. SUMA TOTAL DE PRODUCTOS Y CODIGOS. RESPONSABLE ('+@Miembro+')'    
end    
else if(@ConceptoOBS='LIQUIDACION DE PAGO')    
begin    
set @TEXTO='CANCELARON DEUDA PENDIENTE PORQUE SE LE PASO SOLO PUNTOS AL OBS '+@PV +' CODIGO: '+@CodigoCliente+' ('+@Miembro+')'    
end    
else    
begin    
set @TEXTO='VENTA DEL OBS DOCUMENTO '+@DocuSerie+'-'+@DocuNumero+' CODIGO: '+@CodigoCliente+' ('+@Miembro+')'    
end    
if(@Deposito>0)    
begin    
set @TEXTO=@TEXTO+' FORMA DE PAGO: '+@NotaFormaPago+' ENTIDAD BANCARIA: '+@EntidadBancaria+' NRO OPERACION: '+@NroOperacion    
end    
    
set @CajaId=isnull((select top 1 CajaId from Caja where CajaEstado='ACTIVO'   
and UsuarioId=@UsuarioId order by 1 desc),'0')     
if(@CajaId=0)    
begin    
select 'false'    
end    
else    
begin    
Begin Transaction    
insert into DocumentoVenta values(@CompaniaId,@NotaId,@DocuDocumento,@DocuNumero,    
@ClienteId,@DocuPago,@DocuEmision,@Condicion,@Letras,@DocuSubTotal,    
@DocuIgv,@DocuTotal,@DocuGRAVADA,@DocuUsuario,'EMITIDO',@DocuSerie,@TipoCodigo,@DocuAdicional,    
@DocuAsociado,'VENTA','',@DocuHASH,@EstadoSunat,@Concepto,@Transaccion,    
@ICBPER,@CodigoSunat,@MensajeSunat,@NotaFormaPago,@EntidadBancaria,@NroOperacion,@Efectivo,@Deposito)    
Set @DocuId= @@identity    
    
if(@Concepto='MERCADERIA')    
begin    
    
if(@ConceptoOBS='VENTA' and @Condicion='ALCONTADO')    
begin    
 if(@Deposito>0)    
 begin    
    insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',    
 @TEXTO,@Deposito,@Deposito,0,@Image,'D','',@NotaId,'',@NotaFormaPago,    
 @EntidadBancaria,@NroOperacion)    
 end        
end    
Else    
begin    
if(@ConceptoOBS<>'VENTA' and @Condicion='ALCONTADO')    
begin    
if(@ConceptoOBS<>'FACTURA MANUAL')    
begin    
insert into CajaDetalle values(@CajaId,GETDATE(),0,'INGRESO',    
@TEXTO,@DocuTotal,@DocuTotal,0,@Image,'D','',@NotaId,'',    
@NotaFormaPago,@EntidadBancaria,@NroOperacion)    
if(@Deposito>0)    
begin    
 insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',    
 @TEXTO,@Deposito,@Deposito,0,@Image,'D','',@NotaId,'',@NotaFormaPago,    
 @EntidadBancaria,@NroOperacion)    
end          
end    
end    
else    
begin    
    
insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,'INGRESO',    
'Transacción con '+@NotaFormaPago,@DocuTotal,@DocuTotal,0,'','T','',0,'',@NotaFormaPago,'','')    
    
end    
end    
end    
Declare @Estado varchar(60)    
Declare @SaldoPen decimal(18,2)    
if(@Condicion='CREDITO' or @Condicion='PAGO/VARIOS')    
begin    
set @Estado='EMITIDO'    
set @SaldoPen=@DocuTotal    
end    
else    
begin    
set @Estado='CANCELADO'    
set @SaldoPen=0    
end    
update NotaPedido     
set CompaniaId=@CompaniaId,NotaSerie=@DocuSerie,NotaSaldo=@SaldoPen,NotaUsuario=@DocuUsuario,    
NotaAcuenta=@DocuTotal,NotaNumero=@DocuNumero,NotaEstado=@Estado,CajaId=@CajaId    
where NotaId=@NotaId    
   Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')     
Open Tabla    
Declare @Columna varchar(max),    
  @IdProducto numeric(20),    
  @Cantidad decimal(18,2),    
  @Precio decimal(18,2),    
  @Importe decimal(18,2),    
  @DetalleNotaId numeric(38),    
  @UM varchar(80),    
  @ValorUM decimal(18,4),--@CodigoPro varchar(80),    
  @IniciaStock decimal(18,2),@StockFinal decimal(18,2)    
Declare @p1 int,@p2 int,@p3 int,@p4 int,    
        @p5 int,@p6 int,@p7 int    
Fetch Next From Tabla INTO @Columna    
 While @@FETCH_STATUS = 0    
 Begin    
Set @p1 = CharIndex('|',@Columna,0)    
Set @p2 = CharIndex('|',@Columna,@p1+1)    
Set @p3 = CharIndex('|',@Columna,@p2+1)    
Set @p4 = CharIndex('|',@Columna,@p3+1)    
Set @p5 = CharIndex('|',@Columna,@p4+1)    
Set @p6= CharIndex('|',@Columna,@p5+1)    
Set @p7 = Len(@Columna)+1    
Set @DetalleNotaId=Convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))    
Set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))    
Set @Cantidad=Convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))    
Set @UM=SUBSTRING(@Columna,@p3+1,@p4-(@p3+1))    
Set @Precio=Convert(decimal(18,2),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))    
Set @Importe=Convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))    
Set @ValorUM=Convert(decimal(18,4),SUBSTRING(@Columna,@p6+1,@p7-(@p6+1)))    
insert into DetalleDocumento     
values(@DocuId,@IdProducto,@Cantidad,@Precio,@Importe,@DetalleNotaId,@UM,@ValorUM)    
    if(@Entrega='INMEDIATA')    
    begin       
    --set @CodigoPro=isnull((select top 1 ProductoCodigo from Producto    
    --where IdProducto=@IdProducto),'0')    
 --   if(@CodigoPro='PEKIT-3')    
 --   begin    
 --   set @IniciaStock=(select top 1 ProductoCantidad from Producto     
 --   where IdProducto=7)    
 --set @StockFinal=@IniciaStock-@Cantidad    
 --   insert into Kardex values(7,GETDATE(),'Salida por Venta',    
 --   @DocuNumero,@IniciaStock,0,@Cantidad,    
 --   57,@StockFinal,'SALIDA',@DocuUsuario,@Miembro,    
 --@CodigoCliente,@Transaccion,@TipoCodigo,@DocuSerie,'01','S',convert(varchar,@DocuId),'','E')    
 --update producto     
 --set  ProductoCantidad =ProductoCantidad - @Cantidad    
 --where IDProducto=7    
 --   end        
    set @IniciaStock=(select top 1 ProductoCantidad from Producto where IdProducto=@IdProducto)    
 set @StockFinal=@IniciaStock-@Cantidad    
    insert into Kardex values(@IdProducto,GETDATE(),'Salida por Venta',    
    @DocuNumero,@IniciaStock,0,@Cantidad,    
    @Precio,@StockFinal,'SALIDA',@DocuUsuario,@Miembro,    
 @CodigoCliente,@Transaccion,@TipoCodigo,@DocuSerie,'01','S',convert(varchar,@DocuId),'','E')    
 update producto     
 set  ProductoCantidad =ProductoCantidad - @Cantidad    
 where IDProducto=@IdProducto    
 end    
 else    
 begin    
 set @IniciaStock=(select top 1 ProductoCantidad from Producto where IdProducto=@IdProducto)    
 set @StockFinal=@IniciaStock-@Cantidad    
    insert into Kardex values(@IdProducto,GETDATE(),'Salida por Venta',    
    @DocuNumero,@IniciaStock,0,@Cantidad,    
    @Precio,@StockFinal,'SALIDA',@DocuUsuario,@Miembro,    
 @CodigoCliente,@Transaccion,@TipoCodigo,@DocuSerie,'01','N',convert(varchar,@DocuId),'','E')    
 end    
Fetch Next From Tabla INTO @Columna    
end    
 Close Tabla;    
 Deallocate Tabla;    
 Declare @EstadoDetalle varchar(80)    
    if(@EstadoSunat='PENDIENTE')set @EstadoDetalle='PENDIENTEB'    
 else set @EstadoDetalle='EMITIDO'    
 update DetallePedido    
 set DetalleEstado=@EstadoDetalle    
 where NotaId=@NotaId    
 Commit Transaction;    
select 'true'    
end    
end
GO

IF OBJECT_ID(N'dbo.uspinsertaGasto', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspinsertaGasto] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspinsertaGasto]
@Data varchar(max)
as
begin
Declare @pos1 int
Declare @pos2 int
Declare @pos3 int
Declare @pos4 int
Declare @pos5 int
declare
@GastoId int,
@GastoFecha date,
@GsstoDesc varchar(max),
@GstoMonto decimal(18,2),
@GastoUsuario varchar(80)
Set @Data = LTRIM(RTrim(@Data))
Set @pos1 = CharIndex('|',@Data,0)
Set @GastoId=convert(int,SUBSTRING(@Data,1,@pos1-1))
Set @pos2 = CharIndex('|',@Data,@pos1+1)
Set @GastoFecha=convert(date,SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1))
Set @pos3 = CharIndex('|',@Data,@pos2+1)
Set @GsstoDesc=SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1)
Set @pos4 = CharIndex('|',@Data,@pos3+1)
Set @GstoMonto=convert(decimal(18,2),SUBSTRING(@Data,@pos3+1,@pos4-@pos3-1))
Set @pos5= Len(@Data)+1
Set @GastoUsuario=SUBSTRING(@Data,@pos4+1,@pos5-@pos4-1)
if @GastoId=0
begin
IF EXISTS(select * from GastosFijos g where g.GsstoDesc=@GsstoDesc and
(Month(g.GastoFecha)=MONTH(@GastoFecha) and year(g.GastoFecha)=YEAR(@GastoFecha)))
select 'existe'
else
begin
insert into GastosFijos values(@GastoFecha,@GsstoDesc,@GstoMonto,GETDATE(),@GastoUsuario)
	select isnull((select STUFF((select '¬'+ CONVERT(varchar,g.GastoId)+'|'+convert(varchar,g.GastoFecha,103)+'|'+
	g.GsstoDesc+'|'+CONVERT(VarChar(50), cast(g.GstoMonto as money ), 1)+'|'+
	(IsNull(convert(varchar,g.GastoReg,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,g.GastoReg,114),1,8),''))+'|'+
	g.GastoUsuario
	from GastosFijos g 
	where month(g.GastoFecha)=month(GETDATE())and year(g.GastoFecha)=year(GETDATE())
	order by g.GastoFecha asc,g.GastoId asc
	FOR XML PATH('')), 1, 1, '')),'~')	
end
end
end
GO

IF OBJECT_ID(N'dbo.uspinsertaGuiaInterna', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspinsertaGuiaInterna] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspinsertaGuiaInterna]                  
@ListaOrden varchar(Max)                  
as                  
begin                  
Declare @pos int                  
Declare @orden varchar(max)                  
Declare @detalle varchar(max)                  
Set @pos = CharIndex('[',@ListaOrden,0)                  
Set @orden = SUBSTRING(@ListaOrden,1,@pos-1)                  
Set @detalle = SUBSTRING(@ListaOrden,@pos+1,len(@ListaOrden)-@pos)                  
Declare @pos1 int,@pos2 int,@pos3 int,@pos4 int,                  
        @pos5 int,@pos6 int,@pos7 int ,@pos8 int,      
        @pos9 int,@pos10 int,@pos11 int,@pos12 int,      
        @pos13 int,@pos14 int,@pos15 int,@pos16 int                                  
Declare @GuiaId numeric(38),@FechaRegistro datetime,                
  @Concepto nvarchar(1),@Motivo varchar(300),@Origen varchar(300),                
  @Destino varchar(300),@Observacion varchar(max),@Usuario varchar(80),                
  @KardexDocu varchar(300),@UsuarioId int,@Estado nvarchar(1),      
  @Serie nvarchar(4),@ClienteId varchar(20),@NroTransaccion varchar(250),      
  @CodigoDXN varchar(80),@Total decimal(18,2),@GuiaIdB varchar(38),  
  @GuiaRealacion varchar(40)     
            
Set @pos1 = CharIndex('|',@orden,0)                  
Set @pos2 = CharIndex('|',@orden,@pos1+1)                  
Set @pos3 = CharIndex('|',@orden,@pos2+1)                  
Set @pos4 = CharIndex('|',@orden,@pos3+1)                  
Set @pos5 = CharIndex('|',@orden,@pos4+1)                  
Set @pos6= CharIndex('|',@orden,@pos5+1)                
Set @pos7= CharIndex('|',@orden,@pos6+1)        
Set @pos8= CharIndex('|',@orden,@pos7+1)      
Set @pos9= CharIndex('|',@orden,@pos8+1)                  
Set @pos10 = CharIndex('|',@orden,@pos9+1)                  
Set @pos11= CharIndex('|',@orden,@pos10+1)                
Set @pos12= CharIndex('|',@orden,@pos11+1)        
Set @pos13= CharIndex('|',@orden,@pos12+1)  
Set @pos14= CharIndex('|',@orden,@pos13+1)        
Set @pos15= CharIndex('|',@orden,@pos14+1)                 
Set @pos16= Len(@orden)+1                  
                
Set @FechaRegistro=convert(datetime,SUBSTRING(@orden,1,@pos1-1))                  
Set @Concepto=SUBSTRING(@orden,@pos1+1,@pos2-@pos1-1)      
Set @Serie=SUBSTRING(@orden,@pos2+1,@pos3-@pos2-1)                  
Set @Motivo=SUBSTRING(@orden,@pos3+1,@pos4-@pos3-1)                  
Set @Origen=SUBSTRING(@orden,@pos4+1,@pos5-@pos4-1)                  
Set @Destino=SUBSTRING(@orden,@pos5+1,@pos6-@pos5-1)                  
Set @ClienteId=SUBSTRING(@orden,@pos6+1,@pos7-@pos6-1)      
Set @CodigoDXN=SUBSTRING(@orden,@pos7+1,@pos8-@pos7-1)      
Set @NroTransaccion=SUBSTRING(@orden,@pos8+1,@pos9-@pos8-1)      
Set @Observacion=SUBSTRING(@orden,@pos9+1,@pos10-@pos9-1)                  
Set @Total=convert(decimal(18,2),SUBSTRING(@orden,@pos10+1,@pos11-@pos10-1))    
Set @Usuario=SUBSTRING(@orden,@pos11+1,@pos12-@pos11-1)                  
Set @UsuarioId=SUBSTRING(@orden,@pos12+1,@pos13-@pos12-1)        
Set @Estado=SUBSTRING(@orden,@pos13+1,@pos14-@pos13-1)  
Set @GuiaIdB=SUBSTRING(@orden,@pos14+1,@pos15-@pos14-1)        
Set @GuiaRealacion=SUBSTRING(@orden,@pos15+1,@pos16-@pos15-1)                    
                
Begin Transaction      
      
declare @cod varchar(13)      
SET @cod=isnull((select TOP 1 dbo.genenerarNroGuiaSI(@Serie,@Concepto) AS ID       
FROM GuiaInternaSI),'00000001')      
                  
insert into GuiaInternaSI values(@FechaRegistro,@Concepto,      
@Serie,@cod,@Motivo,@Origen,@Destino,@ClienteId,@CodigoDXN,      
@NroTransaccion,@Observacion,@Total,@Usuario,@Estado,@GuiaIdB,@GuiaRealacion)        
                  
Set @GuiaId= @@identity                
                
if(@Concepto='I')set @KardexDocu='Guia De ING Interno'                
else set @KardexDocu='Guia De SAL Interno'                
                
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')                   
Open Tabla                  
                
Declare @Columna varchar(max),                  
  @IdProducto numeric(20),                  
  @Cantidad decimal(18,2),                 
  @UM varchar(80),                 
  @Descripcion varchar(max),          
  @Costo decimal(18,4),        
  @PrecioVenta decimal(18,2),        
  @Importe decimal(18,2),                  
                  
  @StockInicial decimal(18,2),                  
  @StockFinal decimal(18,2),@CantidadIng decimal(18,2)                
                    
Declare @p1 int,@p2 int,@p3 int,@p4 int,                  
        @p5 int,@p6 int,@p7 int                
                        
Fetch Next From Tabla INTO @Columna                  
 While @@FETCH_STATUS = 0                  
 Begin                  
Set @p1 = CharIndex('|',@Columna,0)                  
Set @p2 = CharIndex('|',@Columna,@p1+1)                  
Set @p3 = CharIndex('|',@Columna,@p2+1)                  
Set @p4 = CharIndex('|',@Columna,@p3+1)        
Set @p5 = CharIndex('|',@Columna,@p4+1)                  
Set @p6 = CharIndex('|',@Columna,@p5+1)                     
Set @p7= Len(@Columna)+1                
                 
Set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,1,@p1-1))        
Set @Cantidad=convert(decimal(18,2),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))                  
Set @UM=SUBSTRING(@Columna,@p2+1,@p3-(@p2+1))         
Set @Descripcion=SUBSTRING(@Columna,@p3+1,@p4-(@p3+1))        
Set @Costo=Convert(decimal(18,4),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))        
Set @PrecioVenta=Convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))           
Set @Importe=Convert(decimal(18,2),SUBSTRING(@Columna,@p6+1,@p7-(@p6+1)))                  
                
insert into DetalleGuiaInterna values(@GuiaId,@IdProducto,@Cantidad,@UM,@Descripcion,        
@Costo,@PrecioVenta,@Importe,'E')                  
              
if(@Concepto='I')              
begin                
set @StockInicial=(select top 1 ProductoCantidad from Producto(nolock)                   
where IdProducto=@IdProducto)                  
                
set @CantidadIng=(@Cantidad*1)                  
set @StockFinal=@StockInicial+@CantidadIng                  
                
update Producto                  
set ProductoCantidad=ProductoCantidad+@CantidadIng                  
where IdProducto=@IdProducto                
                 
insert into Kardex values(@IdProducto,@FechaRegistro,@KardexDocu,@cod,@StockInicial,                  
@CantidadIng,0,@Costo,@StockFinal,'INGRESO',@Usuario,      
@Destino,@CodigoDXN,@NroTransaccion,'103',@Serie,'02','S','','','E')          
          
end              
else              
begin              
              
set @StockInicial=(select top 1 ProductoCantidad from Producto(nolock)                   
where IdProducto=@IdProducto)                  
                
set @CantidadIng=(@Cantidad*1)                  
set @StockFinal=@StockInicial-@CantidadIng                  
                
update Producto                  
set ProductoCantidad=ProductoCantidad-@CantidadIng                  
where IdProducto=@IdProducto                
                 
insert into Kardex values(@IdProducto,@FechaRegistro,@KardexDocu,@cod,@StockInicial,                  
0,@CantidadIng,@Costo,@StockFinal,'SALIDA',@Usuario,          
@Destino,@CodigoDXN,@NroTransaccion,'102',@Serie,'01','S','','','E')                
              
end                  
              
Fetch Next From Tabla INTO @Columna                  
end                  
 Close Tabla;                  
 Deallocate Tabla;                
   
 if(@Concepto='I')  
 begin  
 if(len(@GuiaIdB)>0)  
 begin  
 update GuiaInternaSI  
 set Estado='E'  
 where GuiaId=@GuiaIdB  
 end  
 end  
                 
 delete from TemporalGuiaB                 
 where UsuarioID=@UsuarioId and Concepto=@Concepto              
                 
 Commit Transaction;                  
 select convert(varchar,@GuiaId)+'¬'+@cod         
end
GO

IF OBJECT_ID(N'dbo.uspInsertaGuiaLiquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertaGuiaLiquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertaGuiaLiquida]
@ListaOrden varchar(Max)
as
begin
Declare @pos int
Declare @orden varchar(max)
Declare @detalle varchar(max)
Set @pos = CharIndex('[',@ListaOrden,0)
Set @orden = SUBSTRING(@ListaOrden,1,@pos-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos+1,len(@ListaOrden)-@pos)
Declare @pos1 int,@pos2 int,@pos3 int,@pos4 int,
        @pos5 int,@pos6 int,@pos7 int,@pos8 int,
        @pos9 int,@pos10 int,@pos11 int,@pos12 int,
        @pos13 int,@pos14 int,@pos15 int
Declare @GuiaId numeric(38),@NotaId numeric(38),
		@Documento varchar(80),@CodigoRes varchar(80),
		@Responsable varchar(300),@Condicion varchar(40),
		@EfectivoSoles decimal(18,2),@DepositoSoles decimal(18,2),
		@EntidadBancaria varchar(300),@NroOperacion varchar(80),
		@TotalPago decimal(18,2),@Usuario varchar(80),
		@GuiaNumero varchar(60),@CajaId varchar(40),
		@ConceptoEntrega varchar(40),@Aviso int
Set @pos1 = CharIndex('|',@orden,0)
Set @pos2 = CharIndex('|',@orden,@pos1+1)
Set @pos3 = CharIndex('|',@orden,@pos2+1)
Set @pos4 = CharIndex('|',@orden,@pos3+1)
Set @pos5 = CharIndex('|',@orden,@pos4+1)
Set @pos6= CharIndex('|',@orden,@pos5+1)
Set @pos7 = CharIndex('|',@orden,@pos6+1)
Set @pos8 = CharIndex('|',@orden,@pos7+1)
Set @pos9 = CharIndex('|',@orden,@pos8+1)
Set @pos10= CharIndex('|',@orden,@pos9+1)
Set @pos11= CharIndex('|',@orden,@pos10+1)
Set @pos12= CharIndex('|',@orden,@pos11+1)
Set @pos13= CharIndex('|',@orden,@pos12+1)
Set @pos14= CharIndex('|',@orden,@pos13+1)
Set @pos15= Len(@orden)+1
Set @GuiaId=convert(numeric(38),SUBSTRING(@orden,1,@pos1-1))
Set @NotaId=convert(numeric(38),SUBSTRING(@orden,@pos1+1,@pos2-@pos1-1))
Set @Documento=SUBSTRING(@orden,@pos2+1,@pos3-@pos2-1)
Set @CodigoRes=SUBSTRING(@orden,@pos3+1,@pos4-@pos3-1)
Set @Responsable=SUBSTRING(@orden,@pos4+1,@pos5-@pos4-1)
Set @Condicion=SUBSTRING(@orden,@pos5+1,@pos6-@pos5-1)
Set @EfectivoSoles=convert(decimal(18,2),SUBSTRING(@orden,@pos6+1,@pos7-@pos6-1))
Set @DepositoSoles=convert(decimal(18,2),SUBSTRING(@orden,@pos7+1,@pos8-@pos7-1))
Set @EntidadBancaria=SUBSTRING(@orden,@pos8+1,@pos9-@pos8-1)
Set @NroOperacion=SUBSTRING(@orden,@pos9+1,@pos10-@pos9-1)
Set @TotalPago=convert(decimal(18,2),SUBSTRING(@orden,@pos10+1,@pos11-@pos10-1))
set @Usuario=SUBSTRING(@orden,@pos11+1,@pos12-@pos11-1)
set @CajaId=SUBSTRING(@orden,@pos12+1,@pos13-@pos12-1)
set @ConceptoEntrega=SUBSTRING(@orden,@pos13+1,@pos14-@pos13-1)
set @Aviso=Convert(int,SUBSTRING(@orden,@pos14+1,@pos15-@pos14-1))

SET @GuiaNumero=isnull((select TOP 1 dbo.generaNroGuiaLiquida('G001-') AS ID 
FROM GuiaLiquidacion),'00000001')

IF EXISTS(select l.NroOperacion
from LiquidacionVenta l
where l.EntidadBancaria=@EntidadBancaria and EntidadBancaria<>'-' and l.NroOperacion=@NroOperacion and l.NroOperacion<>'')
begin
select 'EXISTE'
end

ELSE IF EXISTS(select c.NroOperacion
from CajaDetalle c
where c.EntidadBancaria=@EntidadBancaria and c.EntidadBancaria<>'-' and c.NroOperacion=@NroOperacion and c.NroOperacion<>'')
begin
select 'EXISTE'
end

else
begin
Begin Transaction
if(@GuiaId=0)
begin
insert into GuiaLiquidacion values(@NotaId,@Documento,GETDATE(),
@CodigoRes,@Responsable,@Condicion,@EfectivoSoles,@DepositoSoles,@EntidadBancaria,
@NroOperacion,@TotalPago,@Usuario,+'G001-'+@GuiaNumero,@ConceptoEntrega)
Set @GuiaId= @@identity
if(@Condicion='CREDITO' and @Aviso=0)
begin
update NotaPedido
set NotaSaldo=NotaSaldo-@TotalPago,NotaAcuenta=NotaAcuenta+@TotalPago
where NotaId=@NotaId
        if(@EfectivoSoles>0)
		insert into CajaDetalle values(@CajaId,GETDATE(),'0','INGRESO',
		'CANCELO DEUDA Y SE LE ENTREGO PRODUCTOS. CODIGO: '+@CodigoRes+' ( ' +@Responsable+' )',@EfectivoSoles,
		@EfectivoSoles,0,'','D','',@GuiaId,'G','EFECTIVO','-','')				
	    if(@DepositoSoles>0)
		begin
	    insert into CajaDetalle values(@CajaId,GETDATE(),'0','INGRESO',
		'CANCELO DEUDA Y SE LE ENTREGO PRODUCTOS. CODIGO: '+@CodigoRes+' ( ' +@Responsable+' )',@DepositoSoles,
		@DepositoSoles,0,'','D','',@GuiaId,'G','DEPOSITO',@EntidadBancaria,@NroOperacion)	
		insert into CajaDetalle values(@CajaId,GETDATE(),'0','SALIDA',
		'CANCELO DEUDA POR DEPOSITO Y SE LE ENTREGO PRODUCTOS. CODIGO: '+@CodigoRes+' ( ' +@Responsable+' ) ENTIDAD BANCARIA: '+@EntidadBancaria + ' NRO OPERACION: '+@NroOperacion,@DepositoSoles,
		@DepositoSoles,0,'','D','',@GuiaId,'G','DEPOSITO',@EntidadBancaria,@NroOperacion)			
		end
end
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max),
		@DetalleId numeric(38),
		@Idproducto numeric(38),
		@Cantidad decimal(18,2),
		@Descripcion varchar(300),
		@Precio decimal(18,2),
		@PV decimal(18,2),
		@SV decimal(18,2),
		@Importe decimal(18,2),@CodigoPro varchar(80)				
		Declare @IniciaStock decimal(18,2),@StockFinal decimal(18,2)
Declare @p1 int,@p2 int,@p3 int,@p4 int,
        @p5 int,@p6 int,@p7 int,@p8 int
Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	Begin
Set @p1 = CharIndex('|',@Columna,0)
Set @p2 = CharIndex('|',@Columna,@p1+1)
Set @p3 = CharIndex('|',@Columna,@p2+1)
Set @p4 = CharIndex('|',@Columna,@p3+1)
Set @p5 = CharIndex('|',@Columna,@p4+1)
Set @p6= CharIndex('|',@Columna,@p5+1)
Set @p7= CharIndex('|',@Columna,@p6+1)
Set @p8 = Len(@Columna)+1
Set @DetalleId=Convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))
Set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
Set @Cantidad=Convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))
Set @Descripcion=SUBSTRING(@Columna,@p3+1,@p4-(@p3+1))
Set @Precio=Convert(decimal(18,2),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))
Set @PV=Convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))
Set @SV=Convert(decimal(18,2),SUBSTRING(@Columna,@p6+1,@p7-(@p6+1)))
Set @Importe=Convert(decimal(18,2),SUBSTRING(@Columna,@p7+1,@p8-(@p7+1)))
insert into DetalleGuiaLiquida values(@GuiaId,@DetalleId,@Idproducto,@Cantidad,
@Descripcion,@Precio,@PV,@SV,@Importe) 
    
	set @CodigoPro=isnull((select top 1 ProductoCodigo from Producto
    where IdProducto=@IdProducto),'0')
    if(@CodigoPro='PEKIT-3')
    begin
    set @IniciaStock=(select top 1 ProductoCantidad from Producto 
    where IdProducto=7)
	set @StockFinal=@IniciaStock-@Cantidad
	
    insert into Kardex values(7,GETDATE(),'Salida por Venta',
    @GuiaNumero,@IniciaStock,0,@Cantidad,
    57,@StockFinal,'SALIDA',@Usuario,@Responsable,
	@CodigoRes,'','101','G001','01','S','','','E')
	
	update producto 
	set  ProductoCantidad =ProductoCantidad - @Cantidad
	where IDProducto=7
    
    end
       
    set @IniciaStock=(select top 1 ProductoCantidad from Producto where IdProducto=@IdProducto)
	set @StockFinal=@IniciaStock-@Cantidad
	
    insert into Kardex values(@IdProducto,GETDATE(),'Salida por Venta',
    @GuiaNumero,@IniciaStock,0,@Cantidad,
    @Precio,@StockFinal,'SALIDA',@Usuario,@Responsable,
	@CodigoRes,'','101','G001','01','S','','','E')
	
	update producto 
	set  ProductoCantidad =ProductoCantidad - @Cantidad
	where IDProducto=@IdProducto
	
	update DetallePedido
	set CantidadSaldo=CantidadSaldo-@Cantidad
	where DetalleId=@DetalleId
	
Fetch Next From Tabla INTO @Columna
end
	Close Tabla;
	Deallocate Tabla;
	
	Declare @Saldo int
	set @Saldo=isnull((select 
	count(d.DetalleId)
	from NotaPedido n
	inner join DetallePedido d
	on d.NotaId=n.NotaId
	where d.cantidadSaldo>0 and 
	n.CodigoRes=@CodigoRes and (n.NotaEstado<>'ANULADO')),0)
	
	declare @SaldoDocu decimal(18,2)
	set @SaldoDocu=isnull((select top 1 NotaSaldo 
	from NotaPedido where NotaId=@NotaId),0)

	declare @Entreaga varchar(40)
	if(@Saldo=0)set @Entreaga='INMEDIATA'
	else set @Entreaga='POR ENTREGAR'
	if(@SaldoDocu=0)
	begin
	update NotaPedido
	set NotaEntrega=@Entreaga,NotaEstado='CANCELADO'
	where NotaId=@NotaId	
	end
	else
	begin
	update NotaPedido
	set NotaEntrega=@Entreaga
	where NotaId=@NotaId	
	end
	Commit Transaction;
	select @GuiaNumero
end
end
end
GO

IF OBJECT_ID(N'dbo.uspInsertaHtmlGuia', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertaHtmlGuia] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertaHtmlGuia]
@ListaOrden varchar(Max)
as
begin
Declare @pos1 int,@pos2 int
Declare @orden varchar(max),
        @detalle varchar(max)
Set @pos1 = CharIndex('[',@ListaOrden,0)
Set @pos2=Len(@ListaOrden)+1
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)
Declare @c1 int,@c2 int,@c3 int
Declare @flac int,@UserRuta varchar(max),
        @UsuarioID INT
Set @c1 = CharIndex('|',@orden,0)
Set @c2 = CharIndex('|',@orden,@c1+1)
Set @c3= Len(@orden)+1
set @flac=convert(int,SUBSTRING(@orden,1,@c1-1))
set @UserRuta=SUBSTRING(@orden,@c1+1,@c2-@c1-1)
set @UsuarioID=convert(int,SUBSTRING(@orden,@c2+1,@c3-@c2-1))
Begin Transaction
if(@flac=1)
begin
update Usuarios
set UserRuta=@UserRuta
where UsuarioID=@UsuarioID
end
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
        Declare @Columna varchar(max)
		declare @Codigo varchar(80),
		@IdProducto numeric(20),@Cantidad decimal(18,2),
		@precio decimal(18,2),@importe decimal(18,2)
		Declare @p1 int,@p2 int
Fetch Next From Tabla INTO @Columna
While @@FETCH_STATUS = 0
Begin
	    Set @p1 = CharIndex('|',@Columna,0)
		Set @p2=Len(@Columna)+1
        Set @Codigo=SUBSTRING(@Columna,1,@p1-1)
		Set @Cantidad=convert(decimal(18,2),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
		set @IdProducto=isnull((select top 1 IdProducto from Producto where ProductoCodigo=@Codigo),'0')
		set @precio=isnull((select top 1 ProductoVenta from Producto where ProductoCodigo=@Codigo),'0')
		if(@IdProducto<>'0')
		begin
		set @importe=@Cantidad * @precio
		insert into TemporalGuia values(@UsuarioID,@IdProducto,@Cantidad,@precio,@importe,'SALIDA',0,0,0,'UNIDAD',1)
		end
Fetch Next From Tabla INTO @Columna
End
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
	select
    isnull((select STUFF ((select top 1 '¬'+u.UserRuta
	from Usuarios u
	where u.UsuarioID=@UsuarioID 
	order by u.UsuarioID asc
	for xml path('')),1,1,'')),'')
End
GO

IF OBJECT_ID(N'dbo.uspinsertaLiquidaVenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspinsertaLiquidaVenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspinsertaLiquidaVenta]
@ListaOrden varchar(Max)
as
begin
Declare @pos1 int,@pos2 int
Declare @orden varchar(max),
        @detalle varchar(max)
Set @pos1 = CharIndex('[',@ListaOrden,0)
Set @pos2=Len(@ListaOrden)+1
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)
Declare @c1 int,@c2 int,@c3 int,@c4 int,
        @c5 int,@c6 int,@c7 int,@c8 int,@c9 int,
        @c10 int,@c11 int,@c12 int,@C13 int
Declare @Fecha date,
		@Descripcion varchar(250),
		@EfectivoSol decimal(18,2),
		@DepositoSol decimal(18,2),
		@TotalSol decimal(18,2),
		@EfectivoDol decimal(18,2),
		@DepositoDol decimal(18,2),
		@TotalDol decimal(18,2),
		@Usuario varchar(60),
		@CajaId varchar(40),
		@EntidadBancaria varchar(80),
		@NroOperacionA varchar(80),
		@FormaPago varchar(80)
Set @c1 = CharIndex('|',@orden,0)
Set @c2 = CharIndex('|',@orden,@c1+1)
Set @c3 = CharIndex('|',@orden,@c2+1)
Set @c4 = CharIndex('|',@orden,@c3+1)
Set @c5 = CharIndex('|',@orden,@c4+1)
Set @c6 = CharIndex('|',@orden,@c5+1)
Set @c7 = CharIndex('|',@orden,@c6+1)
Set @c8 = CharIndex('|',@orden,@c7+1)
Set @c9 = CharIndex('|',@orden,@c8+1)
Set @c10 = CharIndex('|',@orden,@c9+1)
Set @c11= CharIndex('|',@orden,@c10+1)
Set @c12= CharIndex('|',@orden,@c11+1)
Set @C13= Len(@orden)+1
Set @Fecha=convert(date,SUBSTRING(@orden,1,@c1-1))
Set @Descripcion=SUBSTRING(@orden,@c1+1,@c2-@c1-1)
Set @EfectivoSol=SUBSTRING(@orden,@c2+1,@c3-@c2-1)
Set @DepositoSol=SUBSTRING(@orden,@c3+1,@c4-@c3-1)
Set @TotalSol=SUBSTRING(@orden,@c4+1,@c5-@c4-1)
Set @EfectivoDol=SUBSTRING(@orden,@c5+1,@c6-@c5-1)
Set @DepositoDol=SUBSTRING(@orden,@c6+1,@c7-@c6-1)
Set @TotalDol=SUBSTRING(@orden,@c7+1,@c8-@c7-1)
Set @Usuario=SUBSTRING(@orden,@c8+1,@c9-@c8-1)
Set @CajaId=SUBSTRING(@orden,@c9+1,@c10-@c9-1)
Set @EntidadBancaria=SUBSTRING(@orden,@c10+1,@c11-@c10-1)
Set @NroOperacionA=SUBSTRING(@orden,@c11+1,@c12-@c11-1)
Set @FormaPago=SUBSTRING(@orden,@c12+1,@C13-@c12-1)
IF EXISTS(select l.NroOperacion
from LiquidacionVenta l
where l.EntidadBancaria=@EntidadBancaria and EntidadBancaria<>'-' and l.NroOperacion=@NroOperacionA and l.NroOperacion<>'')
begin
select 'EXISTE'
end

ELSE IF EXISTS(select c.NroOperacion
from CajaDetalle c
where c.EntidadBancaria=@EntidadBancaria and c.EntidadBancaria<>'-' and c.NroOperacion=@NroOperacionA and c.NroOperacion<>'')
begin
select 'EXISTE'
end

else
begin
declare @cod varchar(12)
set @cod=ISNULL(dbo.geneneraIdLiVenta('001-'),'001-00000001')
Declare @LiquidaId numeric(38)
Begin Transaction
insert into LiquidacionVenta values(@cod,
GETDATE(),@Fecha,@Descripcion,0,@EfectivoSol,@DepositoSol,
@TotalSol,@EfectivoDol,@DepositoDol,
@TotalDol,@Usuario,@EntidadBancaria,@NroOperacionA,@FormaPago)
set @LiquidaId=(select @@identity)
if(@FormaPago='EFECTIVO')
begin
insert into CajaDetalle values(@CajaId,GETDATE(),'0','INGRESO',
@Descripcion,@TotalSol,
@TotalSol,0,'','D','',0,CONVERT(varchar,@LiquidaId),@FormaPago,@EntidadBancaria,@NroOperacionA)
end
else
begin
insert into CajaDetalle values(@CajaId,GETDATE(),'0','INGRESO',
@Descripcion+' ENTIDAD BANCARIA: '+@EntidadBancaria+' NRO OPERACION: '+@NroOperacionA,@TotalSol,
@TotalSol,0,'','D','',0,CONVERT(varchar,@LiquidaId),@FormaPago,@EntidadBancaria,@NroOperacionA)	
insert into CajaDetalle values(@CajaId,GETDATE(),'0','SALIDA',
@Descripcion+' ENTIDAD BANCARIA: '+@EntidadBancaria+' NRO OPERACION: '+@NroOperacionA,@TotalSol,
@TotalSol,0,'','D','',0,CONVERT(varchar,@LiquidaId),@FormaPago,@EntidadBancaria,@NroOperacionA)
end
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max)
Declare @p1 int,@p2 int,@p3 int,@p4 int,
        @p5 int,@p6 int,@p7 int,@p8 int,
        @p9 int,@p10 int,@p11 int,@p12 int,     
        @p13 int
Declare @DocuId numeric(38),@SaldoDocu decimal(18,2),@EfectivoSoles decimal(18, 2),
		@EfectivoDolar decimal(18, 2),@DepositoSoles decimal(18, 2),
		@DepositoDolar decimal(18, 2),@EntidadBanco varchar(80),
		@NroOperacion varchar(80),@AcuentaGeneral decimal(18, 2),
		@SaldoActual decimal(18, 2),@FechaPago varchar(60),
		@DocuEstado varchar(60),@NotaId numeric(38),@DetalleId numeric(38)
Fetch Next From Tabla INTO @Columna
While @@FETCH_STATUS = 0
Begin
        Set @p1 = CharIndex('|',@Columna,0)
        Set @p2 = CharIndex('|',@Columna,@p1+1)
        Set @p3 = CharIndex('|',@Columna,@p2+1)
        Set @p4 = CharIndex('|',@Columna,@p3+1)
        Set @p5 = CharIndex('|',@Columna,@p4+1)
        Set @p6 = CharIndex('|',@Columna,@p5+1)
        Set @p7 = CharIndex('|',@Columna,@p6+1)
        Set @p8 = CharIndex('|',@Columna,@p7+1)
        Set @p9 = CharIndex('|',@Columna,@p8+1)
        Set @p10 = CharIndex('|',@Columna,@p9+1)
        Set @p11 = CharIndex('|',@Columna,@p10+1)
        Set @p12 = CharIndex('|',@Columna,@p11+1)
        Set @p13= Len(@Columna)+1
	    Set @DocuId=convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))	
		Set @SaldoDocu=convert(decimal(18,2),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
		Set @EfectivoSoles=convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))
		Set @EfectivoDolar=convert(decimal(18,2),SUBSTRING(@Columna,@p3+1,@p4-(@p3+1)))
		Set @DepositoSoles=convert(decimal(18,2),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))		
		Set @DepositoDolar=convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))
		Set @EntidadBanco=SUBSTRING(@Columna,@p6+1,@p7-(@p6+1))
		Set @NroOperacion=SUBSTRING(@Columna,@p7+1,@p8-(@p7+1))
		Set @AcuentaGeneral=convert(decimal(18,2),SUBSTRING(@Columna,@p8+1,@p9-(@p8+1)))		
		Set @SaldoActual=convert(decimal(18,2),SUBSTRING(@Columna,@p9+1,@p10-(@p9+1)))
		Set @FechaPago=SUBSTRING(@Columna,@p10+1,@p11-(@p10+1))
		Set @DocuEstado=SUBSTRING(@Columna,@p11+1,@p12-(@p11+1))
	    Set @NotaId=convert(numeric(38),SUBSTRING(@Columna,@p12+1,@p13-(@p12+1)))	
		insert into DetaLiquidaVenta values(
		@LiquidaId,@DocuId,@NotaId,@SaldoDocu,@EfectivoSoles,
		@EfectivoDolar,@DepositoSoles,@DepositoDolar,
		0,@EntidadBanco,@NroOperacion,
		@AcuentaGeneral,@SaldoActual,@FechaPago)	
		update NotaPedido
		set NotaAcuenta=NotaAcuenta+@AcuentaGeneral,
		NotaSaldo=NotaSaldo-@AcuentaGeneral,NotaEstado=@DocuEstado
		where NotaId=@NotaId
Fetch Next From Tabla INTO @Columna
End
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
	select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.uspInsertarApertura', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarApertura] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarApertura]
@ListaOrden varchar(Max)
as
begin
Declare @pos int
Declare @orden varchar(max)
Declare @detalle varchar(max)
Set @pos = CharIndex('[',@ListaOrden,0)
Set @orden = SUBSTRING(@ListaOrden,1,@pos-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos+1,len(@ListaOrden)-@pos)
Declare @c1 int,@c2 int,@c3 int
Declare @UsuarioID int,@Usuario varchar(80),
        @Observacion varchar(max),@IdApertura numeric(38),
        @Asistencia int
Set @c1 = CharIndex('|',@orden,0)
Set @c2 = CharIndex('|',@orden,@c1+1)
Set @c3 = Len(@orden)+1
Set @UsuarioID=convert(int,SUBSTRING(@orden,1,@c1-1))
Set @Usuario=SUBSTRING(@orden,@c1+1,@c2-@c1-1)
Set @Observacion=SUBSTRING(@orden,@c2+1,@c3-@c2-1)
Declare @DataAsis varchar(80)
Declare @Tardanza nvarchar(1),
        @OBS varchar(max),
        @NroTardanza int
Declare @pos1 int,@pos2 int,
        @pos3 int,@pos4 int    
set @DataAsis=isnull((select top 1 convert(varchar,COUNT(a.PersonalId))+'|'+
a.Estado+'|'+a.Observaciones+'|'+convert(varchar,a.NroTardanza)
from Asistencia a
inner join Usuarios u
on u.PersonalId=a.PersonalId
where u.UsuarioID=@UsuarioId and a.Fecha=convert(date,GETDATE())
group by a.HoraIngreso,a.Estado,a.Observaciones,a.NroTardanza),'0|||0')
Set @DataAsis= LTRIM(RTrim(@DataAsis))
Set @pos1 = CharIndex('|',@DataAsis,0)
Set @pos2 = CharIndex('|',@DataAsis,@pos1+1)
Set @pos3 = CharIndex('|',@DataAsis,@pos2+1)
Set @pos4= Len(@DataAsis)+1
Set @Asistencia=convert(int,SUBSTRING(@DataAsis,1,@pos1-1))
Set @Tardanza=SUBSTRING(@DataAsis,@pos1+1,@pos2-@pos1-1)
Set @OBS=SUBSTRING(@DataAsis,@pos2+1,@pos3-@pos2-1)
Set @NroTardanza=convert(int,SUBSTRING(@DataAsis,@pos3+1,@pos4-@pos3-1))
if(@Asistencia=0)
begin
Select 'NO ASISTIO'
end
else
begin
if(@Tardanza='T' and @OBS='')
begin
select '['+convert(varchar,@NroTardanza)+']'
end
else
begin
Begin Transaction
insert into APERTURA_ALMACEN values(GETDATE(),'',@UsuarioID,@Usuario,@Observacion,'0','')
set @IdApertura=(select @@IDENTITY)
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max),
        @p1 int,@p2 int,@p3 int,
        @p4 int,@p5 int,@p6 int,
        @p7 int
Declare @IdProducto numeric(20),
        @CantMayor decimal(18,2),
        @CantDespacho decimal(18,2),
        @CantVitrina decimal(18,2),
        @total decimal(18,2),
        @xCaja decimal(18,2),
        @Validacion decimal(18,2)
Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	Begin
Set @p1 = CharIndex('|',@Columna,0)
Set @p2 = CharIndex('|',@Columna,@p1+1)
Set @p3 = CharIndex('|',@Columna,@p2+1)
Set @p4 = CharIndex('|',@Columna,@p3+1)
Set @p5 = CharIndex('|',@Columna,@p4+1)
Set @p6 = CharIndex('|',@Columna,@p5+1)
Set @p7= Len(@Columna)+1
set @IdProducto=Convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))
Set @CantMayor=convert(decimal(18,2),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
Set @xCaja=convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))
Set @CantDespacho=convert(decimal(18,2),SUBSTRING(@Columna,@p3+1,@p4-(@p3+1)))
Set @CantVitrina=convert(decimal(18,2),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))
Set @total=convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))
Set @Validacion=convert(decimal(18,2),SUBSTRING(@Columna,@p6+1,@p7-(@p6+1)))
insert into DetalleApertura values(@IdApertura,@IdProducto,@CantMayor,
@CantDespacho,@CantVitrina,@total,@xCaja,@Validacion)
Fetch Next From Tabla INTO @Columna
end
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
	select 'true'
end
end
end
GO

IF OBJECT_ID(N'dbo.uspInsertarApertutaOBS', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarApertutaOBS] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarApertutaOBS]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,@p3 int,
        @p4 int,@p5 int,@p6 int,
        @p7 int,@p8 int,@p9 int,
        @p10 int,@p11 int,@p12 int,
        @p13 int,@p14 int,@p15 int
Declare @IdApertura numeric(38),@Fecha date,
@BalanceApertura decimal(18,2),@Recepcion decimal(18,2),
@Factura decimal(18,2),@CashBill decimal(18,2),
@ReciboCliente decimal(18,2),@Ajuste decimal(18,2),
@IOC decimal(18,2),@DSP decimal(18,2),
@BalanceCierre decimal(18,2),@ValorInventario decimal(18,2),
@Usuario varchar(80),@FechaTexto varchar(50),@UsuarioID int,
@Apertura decimal(18,2),@RutaApertura varchar(max)
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 = CharIndex('|',@Data,@p2+1)
Set @p4 = CharIndex('|',@Data,@p3+1)
Set @p5= CharIndex('|',@Data,@p4+1)
Set @p6= CharIndex('|',@Data,@p5+1)
Set @p7 = CharIndex('|',@Data,@p6+1)
Set @p8 = CharIndex('|',@Data,@p7+1)
Set @p9= CharIndex('|',@Data,@p8+1)
Set @p10=CharIndex('|',@Data,@p9+1)
Set @p11=CharIndex('|',@Data,@p10+1)
Set @p12=CharIndex('|',@Data,@p11+1)
Set @p13=CharIndex('|',@Data,@p12+1)
Set @p14=CharIndex('|',@Data,@p13+1)
Set @p15=Len(@Data)+1
Set @Fecha=convert(date,SUBSTRING(@Data,1,@p1-1))
Set @BalanceApertura=convert(decimal(18,2),SUBSTRING(@Data,@p1+1,@p2-@p1-1))
Set @Recepcion=convert(decimal(18,2),SUBSTRING(@Data,@p2+1,@p3-@p2-1))
Set @Factura=convert(decimal(18,2),SUBSTRING(@Data,@p3+1,@p4-@p3-1))
Set @CashBill=convert(decimal(18,2),SUBSTRING(@Data,@p4+1,@p5-@p4-1))
Set @ReciboCliente=convert(decimal(18,2),SUBSTRING(@Data,@p5+1,@p6-@p5-1))
Set @Ajuste=convert(decimal(18,2),SUBSTRING(@Data,@p6+1,@p7-@p6-1))
Set @IOC=convert(decimal(18,2),SUBSTRING(@Data,@p7+1,@p8-@p7-1))
Set @DSP=convert(decimal(18,2),SUBSTRING(@Data,@p8+1,@p9-@p8-1))
Set @BalanceCierre=convert(decimal(18,2),SUBSTRING(@Data,@p9+1,@p10-@p9-1))
Set @ValorInventario=convert(decimal(18,2),SUBSTRING(@Data,@p10+1,@p11-@p10-1))
Set @Usuario=SUBSTRING(@Data,@p11+1,@p12-@p11-1)
Set @FechaTexto=SUBSTRING(@Data,@p12+1,@p13-@p12-1)
Set @UsuarioID=convert(int,SUBSTRING(@Data,@p13+1,@p14-@p13-1))
Set @RutaApertura=SUBSTRING(@Data,@p14+1,@p15-@p14-1)
update Usuarios 
set RutaApertura=@RutaApertura 
where UsuarioID=@UsuarioID 
IF EXISTS(select top 1 a.Fecha from AperturaOBS a where a.Fecha=@Fecha)
begin
update AperturaOBS
set BalanceApertura=@BalanceApertura,Recepcion=@Recepcion,
Factura=@Factura,CashBill=@CashBill,ReciboCliente=@ReciboCliente,
Ajuste=@Ajuste,IOC=@IOC,DSP=@DSP,
BalanceCierre=@BalanceCierre,ValorInventario=@ValorInventario,FechaRegistro=GETDATE(),
Usuario=@Usuario,FechaTexto=@FechaTexto
where Fecha=@Fecha
select 'true'
end
else
begin
Declare @count int
set @count=(select COUNT(*) from AperturaOBS)
if(@count=0)
begin
set @Apertura=0
insert into AperturaOBS values(@Fecha,@BalanceApertura,@Recepcion,
@Factura,@CashBill,@ReciboCliente,@Ajuste,@IOC,@DSP,
@BalanceCierre,@ValorInventario,GETDATE(),@Usuario,@FechaTexto,@Apertura)
select 'true'
end
else
begin
Declare @Periodo varchar(max)
set @Periodo=(select top 1 convert(varchar,Fecha,101)+'|'+
CONVERT(VarChar(50),ValorInventario)
from AperturaOBS order by Fecha desc)
Declare @c1 int,@c2 int
declare @FechaUltimo date
declare @BalanApeAyer decimal(18,2)
Declare @FechaSiguiente date
Set @Periodo= LTRIM(RTrim(@Periodo))
Set @c1 = CharIndex('|',@Periodo,0)
Set @c2 = Len(@Periodo)+1
Set @FechaUltimo=convert(date,SUBSTRING(@Periodo,1,@c1-1))
Set @BalanApeAyer=convert(decimal(18,2),SUBSTRING(@Periodo,@c1+1,@c2-@c1-1))
set @FechaSiguiente=(SELECT DATEADD(DAY,1,@FechaUltimo))
set @Apertura=@BalanApeAyer-@BalanceApertura
if(@FechaSiguiente=@Fecha)
begin
insert into AperturaOBS values(@Fecha,@BalanceApertura,@Recepcion,
@Factura,@CashBill,@ReciboCliente,@Ajuste,@IOC,@DSP,
@BalanceCierre,@ValorInventario,GETDATE(),@Usuario,@FechaTexto,@Apertura)
select 'true'
end
else
begin
select 'NEXT'
end
end
end
end




ALTER TABLE ConteoMonedas ADD ESTADO VARCHAR(1)





select isnull((select STUFF((select ';'+ p.PersonalEmail 
from Personal p
inner join Usuarios u
on p.PersonalId=u.PersonalId
where u.Administrador=1 and p.PersonalEmail<>''
order by p.PersonalId asc
FOR XML PATH('')),1,1,'')),'')
--============================================
select p.PersonalId,p.PersonalNombres 
from Personal p
inner join Usuarios u
on p.PersonalId=u.PersonalId
where u.Administrador=1 and p.PersonalEmail<>''
GO

IF OBJECT_ID(N'dbo.uspInsertarCalendario', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarCalendario] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarCalendario]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,
        @p3 int,@p4 int,
        @p5 int,@p6 int,
        @p7 int,@p8 int,
        @p9 int,@p10 int,
        @p11 int       
Declare 
	@id int ,
	@fecha_capacitacion date ,
	@auditor nvarchar(80) ,
	@tema nvarchar(40) ,
	@hora_inicio time ,
	@hora_fin time ,	
	@auditorio nvarchar(60) ,
	@cantidad_asistencia nvarchar(20) ,
	@comentario nvarchar(150) ,
	@usuario_registro nvarchar(80) ,
	@estado char(1) 	
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 = CharIndex('|',@Data,@p2+1)
set @p4 = CharIndex('|',@Data,@p3+1)
set @p5 = CharIndex('|',@Data,@p4+1)
set @p6 = CharIndex('|',@Data,@p5+1)
set @p7 = CharIndex('|',@Data,@p6+1)
set @p8 = CharIndex('|',@Data,@p7+1)
set @p9 = CharIndex('|',@Data,@p8+1)
set @p10 = CharIndex('|',@Data,@p9+1)
Set @p11= Len(@Data)+1
Set @id					=convert(int,SUBSTRING(@Data,1,@p1-1))
Set @fecha_capacitacion =convert(date,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
Set	@auditor			=SUBSTRING(@Data,@p2+1,@p3-@p2-1)
Set	@tema				=SUBSTRING(@Data,@p3+1,@p4-@p3-1)
Set	@hora_inicio		=convert(time,SUBSTRING(@Data,@p4+1,@p5-@p4-1))
Set	@hora_fin			=convert(time,SUBSTRING(@Data,@p5+1,@p6-@p5-1))
Set	@auditorio			=SUBSTRING(@Data,@p6+1,@p7-@p6-1)
Set	@cantidad_asistencia=SUBSTRING(@Data,@p7+1,@p8-@p7-1)
Set	@comentario			=SUBSTRING(@Data,@p8+1,@p9-@p8-1)
Set	@usuario_registro	=SUBSTRING(@Data,@p9+1,@p10-@p9-1)
Set	@estado				=SUBSTRING(@Data,@p10+1,@p11-@p10-1)
if(@Id=0)
begin
insert into appointment values(@fecha_capacitacion,@auditor,@tema,
@hora_inicio,@hora_fin,@auditorio,@cantidad_asistencia,
@comentario,@usuario_registro,getdate(),@estado)
select 'true'
end
else
begin
update appointment
set fecha_capacitacion=@fecha_capacitacion, auditor=@auditor, tema=@tema,
hora_inicio=@hora_inicio, hora_fin=@hora_fin,auditorio=@auditorio,
cantidad_asistencia=@cantidad_asistencia,comentario=@comentario, 
usuario_registro=@usuario_registro,fecha_registro=getdate(),estado=@estado
where id=@id
select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.uspInsertarCierre', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarCierre] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarCierre]
@ListaOrden varchar(Max)
as
begin
Declare @pos int
Declare @orden varchar(max)
Declare @detalle varchar(max)
Set @pos = CharIndex('[',@ListaOrden,0)
Set @orden = SUBSTRING(@ListaOrden,1,@pos-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos+1,len(@ListaOrden)-@pos)
Declare @c1 int,@c2 int,@c3 int,@c4 int,@c5 int
Declare @UsuarioID int,@Usuario varchar(80),
        @Observacion varchar(max),@ObservacionC varchar(max),
        @IdApertura numeric(38),@Asistencia int
Set @c1 = CharIndex('|',@orden,0)
Set @c2 = CharIndex('|',@orden,@c1+1)
Set @c3 = CharIndex('|',@orden,@c2+1)
Set @c4= CharIndex('|',@orden,@c3+1)
Set @c5= Len(@orden)+1
Set @UsuarioID=convert(int,SUBSTRING(@orden,1,@c1-1))
Set @Usuario=SUBSTRING(@orden,@c1+1,@c2-@c1-1)
Set @Observacion=SUBSTRING(@orden,@c2+1,@c3-@c2-1)
Set @ObservacionC=SUBSTRING(@orden,@c3+1,@c4-@c3-1)
set @IdApertura=SUBSTRING(@orden,@c4+1,@c5-@c4-1)
set @Asistencia=(select COUNT(a.PersonalId)from Asistencia a
inner join Usuarios u
on u.PersonalId=a.PersonalId
where u.UsuarioID=@UsuarioId and (Day(a.Fecha)=Day(GETDATE()) and Month(a.Fecha)=MONTH(GETDATE()) and year(a.Fecha)=year(GETDATE())))
if(@Asistencia=0)
begin
Select 'NO ASISTIO'
end
else
begin
Begin Transaction
update APERTURA_ALMACEN
set FechaCierre=convert(varchar,GETDATE(),103)+' '+ SUBSTRING(convert(varchar,GETDATE(),114),1,8),
AperturaEstado='1',Observacion=@Observacion,
UsuarioID=@UsuarioID,Usuario=@Usuario,
ObservacionCierre=@ObservacionC
where IdApertura=@IdApertura
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max),
        @p1 int,@p2 int,@p3 int,
        @p4 int,@p5 int,@p6 int
Declare @IdProducto numeric(20),
        @CantMayor decimal(18,2),
        @xCaja decimal(18,2),
        @CantDespacho decimal(18,2),
        @CantVitrina decimal(18,2),
        @total decimal(18,2)
Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	Begin
Set @p1 = CharIndex('|',@Columna,0)
Set @p2 = CharIndex('|',@Columna,@p1+1)
Set @p3 = CharIndex('|',@Columna,@p2+1)
Set @p4 = CharIndex('|',@Columna,@p3+1)
Set @p5 = CharIndex('|',@Columna,@p4+1)
Set @p6= Len(@Columna)+1
set @IdProducto=Convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))
Set @CantMayor=convert(decimal(18,2),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
Set @xCaja=convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))
Set @CantDespacho=convert(decimal(18,2),SUBSTRING(@Columna,@p3+1,@p4-(@p3+1)))
Set @CantVitrina=convert(decimal(18,2),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))
Set @total=convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))
insert into DetalleCierre values(@IdApertura,@IdProducto,@CantMayor,@CantDespacho,
@CantVitrina,@total,@xCaja)
Fetch Next From Tabla INTO @Columna
end
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
	select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.uspInsertarConteoCaja', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarConteoCaja] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarConteoCaja]  
@ListaOrden varchar(Max)  
as  
Declare @pos1 int,@pos2 int,@pos3 int  
Declare @orden varchar(max),  
        @detalle varchar(max),  
        @Monedas varchar(max)  
Set @pos1 = CharIndex('[',@ListaOrden,0)  
Set @pos2 = CharIndex('[',@ListaOrden,@pos1+1)  
Set @pos3=Len(@ListaOrden)+1  
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)  
Set @detalle =SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)  
Set @Monedas=SUBSTRING(@ListaOrden,@pos2+1,@pos3-@pos2-1)  
Declare @c1 int,@c2 int,@c3 int,@c4 int,  
        @c5 int,@c6 int,@c7 int,@c8 int,  
        @c9 int,@c10 int,@c11 int,@C12 int  
Declare @ConteoId numeric(38),@FechaConteo date,  
        @UsuarioId int,@Usuario varchar(80),  
        @Cajeros varchar(300),@TotalOBS decimal(18,2),  
        @Gastos decimal(18,2),@Diferencial decimal(18,2),  
        @Total decimal(18,2),@Aviso varchar(140),  
        @Observaciones varchar(max),@CajaId numeric(38)  
Set @c1 = CharIndex('|',@orden,0)  
Set @c2 = CharIndex('|',@orden,@c1+1)  
Set @c3 = CharIndex('|',@orden,@c2+1)  
Set @c4 = CharIndex('|',@orden,@c3+1)  
Set @c5 = CharIndex('|',@orden,@c4+1)  
Set @c6= CharIndex('|',@orden,@c5+1)  
Set @c7 = CharIndex('|',@orden,@c6+1)  
Set @c8 = CharIndex('|',@orden,@c7+1)  
Set @c9 = CharIndex('|',@orden,@c8+1)  
Set @c10= CharIndex('|',@orden,@c9+1)  
Set @c11= CharIndex('|',@orden,@c10+1)  
Set @C12= Len(@orden)+1  
Set @ConteoId=convert(numeric(38),SUBSTRING(@orden,1,@c1-1))  
Set @FechaConteo=convert(date,SUBSTRING(@orden,@c1+1,@c2-@c1-1))  
Set @UsuarioId=convert(int,SUBSTRING(@orden,@c2+1,@c3-@c2-1))  
Set @Usuario=SUBSTRING(@orden,@c3+1,@c4-@c3-1)  
Set @Cajeros=SUBSTRING(@orden,@c4+1,@c5-@c4-1)  
Set @TotalOBS=convert(decimal(18,2),SUBSTRING(@orden,@c5+1,@c6-@c5-1))  
Set @Gastos=convert(decimal(18,2),SUBSTRING(@orden,@c6+1,@c7-@c6-1))  
Set @Diferencial=convert(decimal(18,2),SUBSTRING(@orden,@c7+1,@c8-@c7-1))  
Set @Total=convert(decimal(18,2),SUBSTRING(@orden,@c8+1,@c9-@c8-1))  
Set @Aviso=SUBSTRING(@orden,@c9+1,@c10-@c9-1)  
Set @Observaciones=SUBSTRING(@orden,@c10+1,@c11-@c10-1)  
Set @CajaId=convert(numeric(38),SUBSTRING(@orden,@c11+1,@C12-@c11-1))  
Begin Transaction  
insert into ConteoMonedas values(  
@FechaConteo,Getdate(),@UsuarioId,@Usuario,@Cajeros,@TotalOBS,  
@Gastos,@Diferencial,@Total,@Aviso,@Observaciones,@CajaId,'N')--N 
Set @ConteoId= @@identity  
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')   
Open Tabla  
        Declare @Columna varchar(max)  
        Declare @Descripcion varchar(max),@Importe decimal(18,2),  
        @Estado char(1),@Concepto char(1)  
  Declare @d1 int,@d2 int,@d3 int,@d4 int  
Fetch Next From Tabla INTO @Columna  
While @@FETCH_STATUS = 0  
Begin  
     Set @d1 = CharIndex('|',@Columna,0)  
     Set @d2 = CharIndex('|',@Columna,@d1+1)  
        Set @d3 = CharIndex('|',@Columna,@d2+1)  
  Set @d4=Len(@Columna)+1  
        Set @Descripcion=SUBSTRING(@Columna,1,@d1-1)  
  Set @Importe=convert(decimal(18,2),SUBSTRING(@Columna,@d1+1,@d2-(@d1+1)))  
  set @Estado=SUBSTRING(@Columna,@d2+1,@d3-(@d2+1))  
  set @Concepto=SUBSTRING(@Columna,@d3+1,@d4-(@d3+1))  
insert into DetalleConteo values(@ConteoId,upper(@Descripcion),@Importe,@Estado,@Concepto,@CajaId)  
Fetch Next From Tabla INTO @Columna  
End  
    Close Tabla;  
 Deallocate Tabla;  
 begin  
 Declare TablaB Cursor For Select * From fnSplitString(@Monedas,';')   
Open TablaB  
        Declare @ARQUEO varchar(max)  
Declare  @Efectivo int,@Billete varchar(80),  
         @Monto decimal(18,2),@ConceptoB char(1)  
  Declare @m1 int,@m2 int,@m3 int,@m4 int  
Fetch Next From TablaB INTO @ARQUEO  
While @@FETCH_STATUS = 0  
Begin  
     Set @m1 = CharIndex('|',@ARQUEO,0)  
     Set @m2 = CharIndex('|',@ARQUEO,@m1+1)  
        Set @m3 = CharIndex('|',@ARQUEO,@m2+1)  
  Set @m4=Len(@ARQUEO)+1  
        Set @Efectivo=convert(int,SUBSTRING(@ARQUEO,1,@m1-1))  
  Set @Billete=SUBSTRING(@ARQUEO,@m1+1,@m2-(@m1+1))  
  set @Monto=convert(decimal(18,2),SUBSTRING(@ARQUEO,@m2+1,@m3-(@m2+1)))  
  set @ConceptoB=SUBSTRING(@ARQUEO,@m3+1,@m4-(@m3+1))  
insert into Monedas values(@ConteoId,@Efectivo,@Billete,@Monto,@ConceptoB,@CajaId)  
Fetch Next From TablaB INTO @ARQUEO  
END  
 Close TablaB;  
 Deallocate TablaB;  
END  
 Commit Transaction;  
 update TemporalMoneda   
 set Efectivo=null,Monto=null   
 where UsuarioID=@UsuarioId and CajaId=0  
 Select convert(varchar,@ConteoId);
GO

IF OBJECT_ID(N'dbo.uspInsertarCuenta', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarCuenta] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarCuenta]
@Data varchar(max)
as
begin
Declare @pos1 int
Declare @pos2 int
Declare @pos3 int
Declare @pos4 int
Declare @pos5 int
Declare @pos6 int
declare @CuentaId numeric(38),
@ProveedorId numeric(38),
@Entidad varchar(80),
@TipoCuenta varchar(80),
@Moneda varchar(80),
@NroCuenta varchar(80)
Set @Data = LTRIM(RTrim(@Data))
Set @pos1 = CharIndex('|',@Data,0)
Set @CuentaId=convert(numeric(38),SUBSTRING(@Data,1,@pos1-1))
Set @pos2 = CharIndex('|',@Data,@pos1+1)
Set @ProveedorId=convert(numeric(38),SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1))
Set @pos3 = CharIndex('|',@Data,@pos2+1)
Set @Entidad=SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1)
Set @pos4 = CharIndex('|',@Data,@pos3+1)
Set @TipoCuenta=SUBSTRING(@Data,@pos3+1,@pos4-@pos3-1)
Set @pos5 = CharIndex('|',@Data,@pos4+1)
Set @Moneda=SUBSTRING(@Data,@pos4+1,@pos5-@pos4-1)
Set @pos6 = Len(@Data)+1
Set @NroCuenta=SUBSTRING(@Data,@pos5+1,@pos6-@pos5-1)
if(@CuentaId=0)
begin
insert into CuentaProveedor values(@ProveedorId,@Entidad,@TipoCuenta,@Moneda,@NroCuenta)
select isnull((select STUFF ((select '¬'+ CONVERT(varchar,c.CuentaId)+'|'+c.Entidad+'|'+
c.TipoCuenta+'|'+c.Moneda+'|'+c.NroCuenta
from CuentaProveedor c
where c.ProveedorId=@ProveedorId
order by c.CuentaId desc
for xml path('')),1,1,'')),'~')
end
else
begin
update CuentaProveedor
set TipoCuenta=@TipoCuenta,NroCuenta=@NroCuenta
where CuentaId=@CuentaId
select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.uspinsertaRechazo', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspinsertaRechazo] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspinsertaRechazo]
@ListaOrden varchar(Max)
as
begin
Declare @pos int
Declare @orden varchar(max)
Declare @detalle varchar(max)
Set @pos = CharIndex('[',@ListaOrden,0)
Set @orden = SUBSTRING(@ListaOrden,1,@pos-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos+1,len(@ListaOrden)-@pos)
Declare @pos1 int,@pos2 int,@pos3 int,@pos4 int,
        @pos5 int,@pos6 int,@pos7 int,@pos8 int,
        @pos9 int,@pos10 int,@pos11 int,@pos12 int,
        @pos13 int,@pos14 int,@pos15 int,@pos16 int,
        @pos17 int,@pos18 int,@pos19 int,@pos20 int
 Declare @CompaniaId int,@NotaId numeric(38),@DocuDocumento varchar(60),
         @DocuNumero varchar(60),@ClienteId numeric(20),@DocuEmision date,
         @DocuSubTotal decimal(18,2),@DocuIgv decimal(18,2),@DocuTotal decimal(18,2),
         @DocuUsuario varchar(60),@DocuSerie char(4),@TipoCodigo char(20),
         @DocuAdicional decimal(18,2),@DocuAsociado varchar(80),@DocuConcepto varchar(80),
         @DocuHASH varchar(250),@EstadoSunat varchar(80),@Letras varchar(60),
         @CodigoSunat varchar(80),@MensajeSunat varchar(max),
         @DocuId numeric(38),@TraeEstado varchar(80),@NotaEstado varchar(80)
Set @pos1 = CharIndex('|',@orden,0)
Set @pos2 = CharIndex('|',@orden,@pos1+1)
Set @pos3 = CharIndex('|',@orden,@pos2+1)
Set @pos4 = CharIndex('|',@orden,@pos3+1)
Set @pos5 = CharIndex('|',@orden,@pos4+1)
Set @pos6= CharIndex('|',@orden,@pos5+1)
Set @pos7 = CharIndex('|',@orden,@pos6+1)
Set @pos8 = CharIndex('|',@orden,@pos7+1)
Set @pos9 = CharIndex('|',@orden,@pos8+1)
Set @pos10= CharIndex('|',@orden,@pos9+1)
Set @pos11= CharIndex('|',@orden,@pos10+1)
Set @pos12= CharIndex('|',@orden,@pos11+1)
Set @pos13= CharIndex('|',@orden,@pos12+1)
Set @pos14= CharIndex('|',@orden,@pos13+1)
Set @pos15= CharIndex('|',@orden,@pos14+1)
Set @pos16= CharIndex('|',@orden,@pos15+1)
Set @pos17= CharIndex('|',@orden,@pos16+1)
Set @pos18= CharIndex('|',@orden,@pos17+1)
Set @pos19= CharIndex('|',@orden,@pos18+1)
Set @pos20= Len(@orden)+1
Set @CompaniaId=convert(int,SUBSTRING(@orden,1,@pos1-1))
Set @NotaId=convert(numeric(38),SUBSTRING(@orden,@pos1+1,@pos2-@pos1-1))
Set @DocuDocumento=SUBSTRING(@orden,@pos2+1,@pos3-@pos2-1)
Set @DocuNumero=SUBSTRING(@orden,@pos3+1,@pos4-@pos3-1)
Set @ClienteId=convert(numeric(20),SUBSTRING(@orden,@pos4+1,@pos5-@pos4-1))
Set @DocuEmision=convert(date,SUBSTRING(@orden,@pos5+1,@pos6-@pos5-1))
Set @DocuSubTotal=convert(decimal(18,2),SUBSTRING(@orden,@pos6+1,@pos7-@pos6-1))
Set @DocuIgv=convert(decimal(18,2),SUBSTRING(@orden,@pos7+1,@pos8-@pos7-1))
Set @DocuTotal=convert(decimal(18,2),SUBSTRING(@orden,@pos8+1,@pos9-@pos8-1))
Set @DocuUsuario=SUBSTRING(@orden,@pos9+1,@pos10-@pos9-1)
Set @DocuSerie=SUBSTRING(@orden,@pos10+1,@pos11-@pos10-1)
Set @TipoCodigo=SUBSTRING(@orden,@pos11+1,@pos12-@pos11-1)
set @DocuAdicional=convert(decimal(18,2),SUBSTRING(@orden,@pos12+1,@pos13-@pos12-1))
set @DocuAsociado=SUBSTRING(@orden,@pos13+1,@pos14-@pos13-1)
set @DocuConcepto=SUBSTRING(@orden,@pos14+1,@pos15-@pos14-1)
set @DocuHASH=SUBSTRING(@orden,@pos15+1,@pos16-@pos15-1)
set @EstadoSunat=SUBSTRING(@orden,@pos16+1,@pos17-@pos16-1)
set @Letras=SUBSTRING(@orden,@pos17+1,@pos18-@pos17-1)
set @CodigoSunat=SUBSTRING(@orden,@pos18+1,@pos19-@pos18-1)
set @MensajeSunat=SUBSTRING(@orden,@pos19+1,@pos20-@pos19-1)
set @TraeEstado=(select top 1 n.NotaEstado from NotaPedido n where n.NotaId=@NotaId)
if(@TraeEstado='PENDIENTE')set @NotaEstado='EMITIDO'
else set @NotaEstado=@TraeEstado
Begin Transaction
insert into DocumentoVenta values(@CompaniaId,@NotaId,@DocuDocumento,@DocuNumero,
@ClienteId,GETDATE(),@DocuEmision,'ALCONTADO','CERO CON 00/100 SOLES',0,0,0,0,
@DocuUsuario,'RECHAZADO',@DocuSerie,@TipoCodigo,0,@DocuAsociado,
@DocuConcepto,'',@DocuHASH,'RECHAZADO','SERVICIO','',0,
@CodigoSunat,@MensajeSunat,'EFECTIVO','-','',0,0)
Set @DocuId= @@identity
update NotaPedido 
set CompaniaId=@CompaniaId,NotaSerie=@DocuSerie,
NotaNumero=@DocuNumero,NotaEstado=@NotaEstado
where NotaId=@NotaId
   Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max),
		@IdProducto numeric(20),
		@Cantidad decimal(18,2),
		@Precio decimal(18,2),
		@Importe decimal(18,2),
		@DetalleNotaId numeric(38),
		@UM varchar(80),
		@ValorUM decimal(18,4)
Declare @p1 int,@p2 int,@p3 int,@p4 int,
        @p5 int,@p6 int,@p7 int
Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	Begin
Set @p1 = CharIndex('|',@Columna,0)
Set @p2 = CharIndex('|',@Columna,@p1+1)
Set @p3 = CharIndex('|',@Columna,@p2+1)
Set @p4 = CharIndex('|',@Columna,@p3+1)
Set @p5 = CharIndex('|',@Columna,@p4+1)
Set @p6= CharIndex('|',@Columna,@p5+1)
Set @p7 = Len(@Columna)+1
Set @DetalleNotaId=Convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))
Set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
Set @Cantidad=Convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))
Set @UM=SUBSTRING(@Columna,@p3+1,@p4-(@p3+1))
Set @Precio=Convert(decimal(18,2),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))
Set @Importe=Convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))
Set @ValorUM=Convert(decimal(18,4),SUBSTRING(@Columna,@p6+1,@p7-(@p6+1)))
insert into DetalleDocumento 
values(@DocuId,@IdProducto,@Cantidad,@Precio,@Importe,@DetalleNotaId,@UM,@ValorUM)
Fetch Next From Tabla INTO @Columna
end
	Close Tabla;
	Deallocate Tabla;
	update DetallePedido
	set DetalleEstado='PENDIENTE'
	where NotaId=@NotaId
	Commit Transaction;
select 'true'
end
GO

IF OBJECT_ID(N'dbo.uspinsertarGuiaSP', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspinsertarGuiaSP] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspinsertarGuiaSP]
@ListaOrden varchar(Max)
as
begin
Declare @pos int
Declare @orden varchar(max)
Declare @detalle varchar(max)
Set @pos = CharIndex('[',@ListaOrden,0)
Set @orden = SUBSTRING(@ListaOrden,1,@pos-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos+1,len(@ListaOrden)-@pos)
Declare  @pos1 int,@pos2 int,@pos3 int,@pos4 int,
         @pos5 int,@pos6 int,@pos7 int,@pos8 int,
         @pos9 int,@pos10 int,@pos11 int,@pos12 int,
         @pos13 int,@pos14 int,@pos15 int,@pos16 int,
         @pos17 int,@pos18 int,@pos19 int,@pos20 int,
         @pos21 int,@pos22 int,@pos23 int
 Declare @GuiaId numeric(38),@GuiaNumero varchar(60),
	     @GuiaMotivo varchar(60),@GuiaFecha datetime,
	     @ClienteId numeric(20),@OPGRAVADA decimal(18, 2),
	     @Descuento decimal(18, 2),@Subtotal decimal(18, 2),
	     @IGV decimal(18, 2),@ICBPER decimal(18, 2),
	     @Total decimal(18, 2),@GuiaEstado varchar(60),
	     @NumeroOrden varchar(80),@GuiaUsuario varchar(80),
         @GuiaObservacion varchar(max),@Asistencia int,
         @CajaId numeric(38),@NotaTransaccion varchar(250),
         @UsuarioId int,@Cliente varchar(max),@PV varchar(40),
         @Image varchar(max),@CajaDetaId numeric(38),
         @ClienteIdRes numeric(20),@Responsable varchar(140),
         @CodigoRes varchar(80)
Set @pos1 = CharIndex('|',@orden,0)
Set @pos2 = CharIndex('|',@orden,@pos1+1)
Set @pos3 = CharIndex('|',@orden,@pos2+1)
Set @pos4 = CharIndex('|',@orden,@pos3+1)
Set @pos5 = CharIndex('|',@orden,@pos4+1)
Set @pos6= CharIndex('|',@orden,@pos5+1)
Set @pos7 = CharIndex('|',@orden,@pos6+1)
Set @pos8 = CharIndex('|',@orden,@pos7+1)
Set @pos9 = CharIndex('|',@orden,@pos8+1)
Set @pos10= CharIndex('|',@orden,@pos9+1)
Set @pos11= CharIndex('|',@orden,@pos10+1)
Set @pos12= CharIndex('|',@orden,@pos11+1)
Set @pos13= CharIndex('|',@orden,@pos12+1)
Set @pos14= CharIndex('|',@orden,@pos13+1)
Set @pos15= CharIndex('|',@orden,@pos14+1)
Set @pos16= CharIndex('|',@orden,@pos15+1)
Set @pos17= CharIndex('|',@orden,@pos16+1)
Set @pos18= CharIndex('|',@orden,@pos17+1)
Set @pos19= CharIndex('|',@orden,@pos18+1)
Set @pos20= CharIndex('|',@orden,@pos19+1)
Set @pos21= CharIndex('|',@orden,@pos20+1)
Set @pos22= CharIndex('|',@orden,@pos21+1)
Set @pos23= Len(@orden)+1
Set @GuiaId=convert(numeric(38),SUBSTRING(@orden,1,@pos1-1))
Set @GuiaNumero=SUBSTRING(@orden,@pos1+1,@pos2-@pos1-1)
Set @GuiaMotivo=SUBSTRING(@orden,@pos2+1,@pos3-@pos2-1)
Set @GuiaFecha=convert(datetime,SUBSTRING(@orden,@pos3+1,@pos4-@pos3-1))
Set @ClienteId=convert(numeric(20),SUBSTRING(@orden,@pos4+1,@pos5-@pos4-1))
Set @OPGRAVADA=convert(decimal(18,2),SUBSTRING(@orden,@pos5+1,@pos6-@pos5-1))
Set @Descuento=convert(decimal(18,2),SUBSTRING(@orden,@pos6+1,@pos7-@pos6-1))
Set @Subtotal=convert(decimal(18,2),SUBSTRING(@orden,@pos7+1,@pos8-@pos7-1))
Set @IGV=convert(decimal(18,2),SUBSTRING(@orden,@pos8+1,@pos9-@pos8-1))
Set @ICBPER=convert(decimal(18,2),SUBSTRING(@orden,@pos9+1,@pos10-@pos9-1))
Set @Total=convert(decimal(18,2),SUBSTRING(@orden,@pos10+1,@pos11-@pos10-1))
Set @GuiaEstado=SUBSTRING(@orden,@pos11+1,@pos12-@pos11-1)
set @NumeroOrden=SUBSTRING(@orden,@pos12+1,@pos13-@pos12-1)
set @GuiaUsuario=SUBSTRING(@orden,@pos13+1,@pos14-@pos13-1)
set @GuiaObservacion=SUBSTRING(@orden,@pos14+1,@pos15-@pos14-1)
set @NotaTransaccion=SUBSTRING(@orden,@pos15+1,@pos16-@pos15-1)
set @UsuarioId=convert(int,SUBSTRING(@orden,@pos16+1,@pos17-@pos16-1))
set @Cliente=SUBSTRING(@orden,@pos17+1,@pos18-@pos17-1)
set @PV=SUBSTRING(@orden,@pos18+1,@pos19-@pos18-1)
set @Image=SUBSTRING(@orden,@pos19+1,@pos20-@pos19-1)
set @ClienteIdRes=convert(numeric(20),SUBSTRING(@orden,@pos20+1,@pos21-@pos20-1))
set @Responsable=SUBSTRING(@orden,@pos21+1,@pos22-@pos21-1)
set @CodigoRes=SUBSTRING(@orden,@pos22+1,@pos23-@pos22-1)
SET @GuiaNumero=isnull((select TOP 1 dbo.genenerarNroGuia('0001-') AS ID 
FROM DocumentoVenta),'0001-000001')
set @Asistencia=(select COUNT(a.PersonalId)from Asistencia a
inner join Usuarios u
on u.PersonalId=a.PersonalId
where u.UsuarioID=@UsuarioId and (Day(a.Fecha)=Day(GETDATE()) and Month(a.Fecha)=MONTH(GETDATE()) and year(a.Fecha)=year(GETDATE())))
if(@Asistencia=0)
begin
Select 'NO ASISTIO'
end
else
begin
IF EXISTS(select top 1 NotaTransaccion from GuiaRemision where NotaTransaccion=@NotaTransaccion and NotaTransaccion<>'')
begin
select 'existe'
end
else
begin
set @CajaId=isnull((select top 1 CajaId from Caja where CajaEstado='ACTIVO' 
and UsuarioId=@UsuarioId order by 1 desc),'0')
if(@CajaId=0)
begin
select 'false'
end
else
begin
Begin Transaction
delete from TemporalVenta 
where UsuarioID=@UsuarioId
IF(@GuiaMotivo<>'CREDITO ALA RED')
begin
insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',
'SE PASO A '+@GuiaMotivo+' '+@PV+' ( '+@Cliente+' )',
@Total,@Total,0,@Image,'D','',0,'','EFECTIVO','-','')
set @CajaDetaId=@@IDENTITY
end
else
begin
insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',
'SE PASO POR MOTIVO DE '+@GuiaMotivo+' DE '+@PV+' A LA ('+@Cliente+')',
@Total,@Total,0,@Image,'D','',0,'','EFECTIVO','-','')
set @CajaDetaId=@@IDENTITY
end
insert into GuiaRemision values(@GuiaNumero,@GuiaMotivo,@GuiaFecha,
@ClienteId,@OPGRAVADA,@Descuento,@Subtotal,@IGV,@ICBPER,
@Total,@GuiaEstado,@NumeroOrden,@GuiaUsuario,@GuiaObservacion,
GETDATE(),@NotaTransaccion,@CajaDetaId,@ClienteIdRes,@Responsable,@CodigoRes)
Set @GuiaId= @@identity
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max),
		@IdProducto numeric(20),
	    @DetalleCantidad decimal(18, 2),
	    @DetalleCosto decimal(18, 4),
	    @DetallePrecio decimal(18, 2),
	    @DetalleImporte decimal(18, 2),
	    @DetallePV  decimal(18,2),
	    @DetalleSV decimal(18,2)
Declare @p1 int,@p2 int,@p3 int,@p4 int,
        @p5 int,@p6 int,@p7 int
Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	Begin
Set @p1 = CharIndex('|',@Columna,0)
Set @p2 = CharIndex('|',@Columna,@p1+1)
Set @p3 = CharIndex('|',@Columna,@p2+1)
Set @p4 = CharIndex('|',@Columna,@p3+1)
Set @p5 = CharIndex('|',@Columna,@p4+1)
Set @p6 = CharIndex('|',@Columna,@p5+1)
Set @p7= Len(@Columna)+1
Set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,1,@p1-1))
Set @DetalleCantidad=convert(decimal(18,2),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
Set @DetalleCosto=Convert(decimal(18,4),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))
Set @DetallePrecio=Convert(decimal(18,2),SUBSTRING(@Columna,@p3+1,@p4-(@p3+1)))
Set @DetallePV=Convert(decimal(18,2),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))
Set @DetalleSV=Convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))
Set @DetalleImporte=Convert(decimal(18,2),SUBSTRING(@Columna,@p6+1,@p7-(@p6+1)))
insert into DetalleGuia
values(@GuiaId,@IdProducto,@DetalleCantidad,@DetalleCosto,@DetallePrecio,
@DetalleImporte,@DetallePV,@DetalleSV)
Fetch Next From Tabla INTO @Columna
end
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
    select CONVERT(varchar,@GuiaId)+'¬'+@GuiaNumero
end
end
end
end
GO

IF OBJECT_ID(N'dbo.uspInsertarHorario', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarHorario] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarHorario]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,
        @p3 int,@p4 int,
        @p5 int,@p6 int,
        @p7 int,@p8 int,
        @p9 int,@p10 int,
        @p11 int,@p12 int
        
Declare 

	@id int ,
	@fecha_registro date ,
	@tipo nvarchar(40) ,
	@auditor nvarchar(80) ,
	@curso nvarchar(40) ,
	@dia_texto nvarchar(40) ,
	@hora_inicio time ,
	@hora_fin time ,	
	@color nvarchar(60) ,	
	@comentario nvarchar(150) ,
	@usuario_registro nvarchar(80) ,
	@estado char(1) 
	
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 = CharIndex('|',@Data,@p2+1)
set @p4 = CharIndex('|',@Data,@p3+1)
set @p5 = CharIndex('|',@Data,@p4+1)
set @p6 = CharIndex('|',@Data,@p5+1)
set @p7 = CharIndex('|',@Data,@p6+1)
set @p8 = CharIndex('|',@Data,@p7+1)
set @p9 = CharIndex('|',@Data,@p8+1)
set @p10 = CharIndex('|',@Data,@p9+1)
set @p11 = CharIndex('|',@Data,@p10+1)
Set @p12= Len(@Data)+1

Set @id					=convert(int,SUBSTRING(@Data,1,@p1-1))
Set @fecha_registro     =convert(date,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
Set	@tipo			    			=SUBSTRING(@Data,@p2+1,@p3-@p2-1)
Set	@auditor						=SUBSTRING(@Data,@p3+1,@p4-@p3-1)
Set	@curso			    			=SUBSTRING(@Data,@p4+1,@p5-@p4-1)
Set	@dia_texto						=SUBSTRING(@Data,@p5+1,@p6-@p5-1)
Set	@hora_inicio		=convert(time,SUBSTRING(@Data,@p6+1,@p7-@p6-1))
Set	@hora_fin			=convert(time,SUBSTRING(@Data,@p7+1,@p8-@p7-1))
Set	@color							=SUBSTRING(@Data,@p8+1,@p9-@p8-1)
Set	@comentario						=SUBSTRING(@Data,@p9+1,@p10-@p9-1)
Set	@usuario_registro				=SUBSTRING(@Data,@p10+1,@p11-@p10-1)
Set	@estado							=SUBSTRING(@Data,@p11+1,@p12-@p11-1)

if(@Id=0)
begin
insert into tbl_horario values(@fecha_registro ,@tipo  ,@auditor ,@curso ,@dia_texto ,@hora_inicio ,@hora_fin ,@color ,@comentario ,@usuario_registro ,@estado)
select 'true'
end
else
begin
update tbl_horario
set fecha_registro=@fecha_registro ,tipo=@tipo  ,auditor=@auditor ,curso=@curso ,dia_texto=@dia_texto ,
hora_inicio=@hora_inicio ,hora_fin=@hora_fin ,color=@color ,comentario=@comentario ,usuario_registro=@usuario_registro ,estado= @estado
where id=@id
select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.uspInsertarHtml', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarHtml] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarHtml]
@ListaOrden varchar(Max)
as
begin
Declare @pos1 int,@pos2 int
Declare @orden varchar(max),
        @detalle varchar(max)
Set @pos1 = CharIndex('[',@ListaOrden,0)
Set @pos2=Len(@ListaOrden)+1
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)
Declare @c1 int,@c2 int,@c3 int
Declare @flac int,@UserRuta varchar(max),
        @UsuarioID INT
Set @c1 = CharIndex('|',@orden,0)
Set @c2 = CharIndex('|',@orden,@c1+1)
Set @c3= Len(@orden)+1
set @flac=convert(int,SUBSTRING(@orden,1,@c1-1))
set @UserRuta=SUBSTRING(@orden,@c1+1,@c2-@c1-1)
set @UsuarioID=convert(int,SUBSTRING(@orden,@c2+1,@c3-@c2-1))
Begin Transaction
if(@flac=1)
begin
update Usuarios
set UserRuta=@UserRuta
where UsuarioID=@UsuarioID
end
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
        Declare @Columna varchar(max)
		declare @Codigo varchar(80),
		@IdProducto numeric(20),@Cantidad decimal(18,2),
		@precio decimal(18,2),@importe decimal(18,2)
		Declare @p1 int,@p2 int
Fetch Next From Tabla INTO @Columna
While @@FETCH_STATUS = 0
Begin
	    Set @p1 = CharIndex('|',@Columna,0)
		Set @p2=Len(@Columna)+1
        Set @Codigo=SUBSTRING(@Columna,1,@p1-1)
		Set @Cantidad=convert(decimal(18,2),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
		set @IdProducto=isnull((select top 1 IdProducto from Producto where ProductoCodigo=@Codigo),'0')
		set @precio=isnull((select top 1 ProductoVenta from Producto where ProductoCodigo=@Codigo),'0')
		if(@IdProducto<>'0')
		begin
		set @importe=@Cantidad * @precio
		insert into TemporalVenta values(@UsuarioID,@IdProducto,@Cantidad,@precio,@importe,1,'UNIDAD')
		end
Fetch Next From Tabla INTO @Columna
End
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
	select
    isnull((select STUFF ((select '¬'+convert(varchar,t.temporalId)+'|'+CONVERT(varchar,t.UsuarioId)+'|'+convert(varchar,t.IdProducto)+'|'+
    p.ProductoCodigo+'|'+convert(varchar,t.cantidad)+'|'+t.UniMedida+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
	convert(varchar,cast((p.ProductoCosto* t.ValorUM) as decimal(18,2)))+'|'+
	convert(varchar,t.precioventa)+'|'+
    CONVERT(VarChar(50), cast((t.cantidad*p.ProductoPV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast((t.cantidad*p.ProductoSV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(t.importe as money ), 1)+'|'+
	p.ProductoImagen+'|'+
	convert(varchar,t.ValorUM)+'|'+
	convert(varchar,convert(decimal(18,2),t.precioventa/1.18))+'|'+
	convert(varchar,(t.importe - convert(decimal(18,2),t.importe/1.18)))+'|'+
	convert(varchar,convert(decimal(18,2),t.importe/1.18))+'|'+
	convert(varchar,p.ProductoPV)+'|'+convert(varchar,p.ProductoSV)+'|'+
	s.NombreSublinea+'|'+p.AplicaFB
	from TemporalVenta t
	inner join Producto p
	on p.IdProducto=t.IdProducto
	inner join Sublinea s
	on s.IdSubLinea=p.IdSubLinea
	where t.UsuarioID=@UsuarioID 
	order by t.temporalId asc
	for xml path('')),1,1,'')),'~')+'['+
    isnull((select STUFF ((select top 1 '¬'+u.UserRuta
	from Usuarios u
	where u.UsuarioID=@UsuarioID 
	order by u.UsuarioID asc
	for xml path('')),1,1,'')),'')
End
GO

IF OBJECT_ID(N'dbo.uspInsertarHtmlGSI', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarHtmlGSI] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarHtmlGSI]    
@ListaOrden varchar(Max)    
as    
begin    
Declare @pos1 int,@pos2 int    
Declare @orden varchar(max),    
        @detalle varchar(max)    
Set @pos1 = CharIndex('[',@ListaOrden,0)    
Set @pos2=Len(@ListaOrden)+1    
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)    
Set @detalle = SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)    
Declare @c1 int,@c2 int,@c3 int    
Declare @flac int,@UserRuta varchar(max),    
        @UsuarioID INT    
Set @c1 = CharIndex('|',@orden,0)    
Set @c2 = CharIndex('|',@orden,@c1+1)    
Set @c3= Len(@orden)+1    
set @flac=convert(int,SUBSTRING(@orden,1,@c1-1))    
set @UserRuta=SUBSTRING(@orden,@c1+1,@c2-@c1-1)    
set @UsuarioID=convert(int,SUBSTRING(@orden,@c2+1,@c3-@c2-1))    
Begin Transaction    
if(@flac=1)    
begin    
update Usuarios    
set UserRuta=@UserRuta    
where UsuarioID=@UsuarioID    
end    
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')     
Open Tabla    
        Declare @Columna varchar(max)    
  declare @Codigo varchar(80),    
  @IdProducto numeric(20),@Cantidad decimal(18,2),    
  @precio decimal(18,2),@importe decimal(18,2)    
  Declare @p1 int,@p2 int    
Fetch Next From Tabla INTO @Columna    
While @@FETCH_STATUS = 0    
Begin    
     Set @p1 = CharIndex('|',@Columna,0)    
  Set @p2=Len(@Columna)+1    
  Set @Codigo=SUBSTRING(@Columna,1,@p1-1)    
  Set @Cantidad=convert(decimal(18,2),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))    
  set @IdProducto=isnull((select top 1 IdProducto from Producto where ProductoCodigo=@Codigo),'0')    
  set @precio=isnull((select top 1 ProductoVenta from Producto where ProductoCodigo=@Codigo),'0')    
  if(@IdProducto<>'0')    
  begin    
  set @importe=@Cantidad * @precio    
  insert into TemporalGuiaB values(@UsuarioID,@IdProducto,@Cantidad,'UNIDAD',@precio,@importe,'S')    
  end    
Fetch Next From Tabla INTO @Columna    
End    
 Close Tabla;    
 Deallocate Tabla;    
 Commit Transaction;    
 select 'true['+    
 Isnull((select STUFF ((select top 1 '¬'+u.UserRuta    
 from Usuarios u    
 where u.UsuarioID=@UsuarioID     
 order by u.UsuarioID asc    
 for xml path('')),1,1,'')),'')      
End
GO

IF OBJECT_ID(N'dbo.uspInsertarHuella', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarHuella] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarHuella]
@PersonalId numeric(20),
@PARAM_HUELLA image
as
begin
UPDATE PERSONAL 
SET HUELLA=@PARAM_HUELLA 
WHERE PersonalId=@PersonalId
end
GO

IF OBJECT_ID(N'dbo.uspinsertarNC', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspinsertarNC] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspinsertarNC]
@ListaOrden varchar(Max)
as
begin
Declare @pos int
Declare @orden varchar(max)
Declare @detalle varchar(max)
Set @pos = CharIndex('[',@ListaOrden,0)
Set @orden = SUBSTRING(@ListaOrden,1,@pos-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos+1,len(@ListaOrden)-@pos)
Declare @pos1 int,@pos2 int,@pos3 int,@pos4 int,
        @pos5 int,@pos6 int,@pos7 int,@pos8 int,
        @pos9 int,@pos10 int,@pos11 int,@pos12 int,
        @pos13 int,@pos14 int,@pos15 int,@pos16 int,
        @pos17 int,@pos18 int,@pos19 int,@pos20 int,
        @pos21 int,@pos22 int,@pos23 int,@pos24 int,
        @pos25 int,@pos26 int,@pos27 int,@pos28 int,
        @pos29 int,@pos30 int,@pos31 int,
        @pos32 int,@pos33 int
 Declare @CompaniaId int,@NotaId numeric(38),@DocuDocumento varchar(60),
         @DocuNumero varchar(60),@ClienteId numeric(20),@DocuEmision date,
         @DocuSubTotal decimal(18,2),@DocuIgv decimal(18,2),@DocuTotal decimal(18,2),
         @DocuUsuario varchar(60),@DocuSerie char(4),@TipoCodigo nvarchar(10),
         @DocuAdicional decimal(18,2),@DocuAsociado varchar(80),@DocuConcepto varchar(80),
         @DocuHASH varchar(250),@EstadoSunat varchar(80),@Letras varchar(60),@NroReferencia varchar(80),
         @DocuId numeric(38),@KardexDocu varchar(80),@DetalleId numeric(38),@Concepto varchar(40),
         @Transaccion varchar(250),@Miembro varchar(300),@CodigoCliente varchar(80),
         @ICBPER DECIMAL(18,2),@CodigoSunat varchar(80),@MensajeSunat varchar(max),
         @FechaFactura date,@DocuGravada decimal(18,2),@ConceptoOBS varchar(80),
         @Entrega varchar(80),@FormaPago varchar(80),@EntidadBancaria varchar(80),
         @Efectivo decimal(18,2),@Deposito decimal(18,2)
Set @pos1 = CharIndex('|',@orden,0)
Set @pos2 = CharIndex('|',@orden,@pos1+1)
Set @pos3 = CharIndex('|',@orden,@pos2+1)
Set @pos4 = CharIndex('|',@orden,@pos3+1)
Set @pos5 = CharIndex('|',@orden,@pos4+1)
Set @pos6= CharIndex('|',@orden,@pos5+1)
Set @pos7 = CharIndex('|',@orden,@pos6+1)
Set @pos8 = CharIndex('|',@orden,@pos7+1)
Set @pos9 = CharIndex('|',@orden,@pos8+1)
Set @pos10= CharIndex('|',@orden,@pos9+1)
Set @pos11= CharIndex('|',@orden,@pos10+1)
Set @pos12= CharIndex('|',@orden,@pos11+1)
Set @pos13= CharIndex('|',@orden,@pos12+1)
Set @pos14= CharIndex('|',@orden,@pos13+1)
Set @pos15= CharIndex('|',@orden,@pos14+1)
Set @pos16= CharIndex('|',@orden,@pos15+1)
Set @pos17= CharIndex('|',@orden,@pos16+1)
Set @pos18= CharIndex('|',@orden,@pos17+1)
Set @pos19= CharIndex('|',@orden,@pos18+1)
Set @pos20= CharIndex('|',@orden,@pos19+1)
Set @pos21= CharIndex('|',@orden,@pos20+1)
Set @pos22= CharIndex('|',@orden,@pos21+1)
Set @pos23= CharIndex('|',@orden,@pos22+1)
Set @pos24= CharIndex('|',@orden,@pos23+1)
Set @pos25= CharIndex('|',@orden,@pos24+1)
Set @pos26= CharIndex('|',@orden,@pos25+1)
Set @pos27= CharIndex('|',@orden,@pos26+1)
Set @pos28= CharIndex('|',@orden,@pos27+1)
Set @pos29= CharIndex('|',@orden,@pos28+1)
Set @pos30= CharIndex('|',@orden,@pos29+1)

Set @pos31= CharIndex('|',@orden,@pos30+1)
Set @pos32= CharIndex('|',@orden,@pos31+1)

Set @pos33= Len(@orden)+1
Set @CompaniaId=convert(int,SUBSTRING(@orden,1,@pos1-1))
Set @NotaId=convert(numeric(38),SUBSTRING(@orden,@pos1+1,@pos2-@pos1-1))
Set @DocuDocumento=SUBSTRING(@orden,@pos2+1,@pos3-@pos2-1)
Set @DocuNumero=SUBSTRING(@orden,@pos3+1,@pos4-@pos3-1)
Set @ClienteId=convert(numeric(20),SUBSTRING(@orden,@pos4+1,@pos5-@pos4-1))
Set @DocuEmision=convert(date,SUBSTRING(@orden,@pos5+1,@pos6-@pos5-1))
Set @DocuSubTotal=convert(decimal(18,2),SUBSTRING(@orden,@pos6+1,@pos7-@pos6-1))
Set @DocuIgv=convert(decimal(18,2),SUBSTRING(@orden,@pos7+1,@pos8-@pos7-1))
Set @DocuTotal=convert(decimal(18,2),SUBSTRING(@orden,@pos8+1,@pos9-@pos8-1))
Set @DocuUsuario=SUBSTRING(@orden,@pos9+1,@pos10-@pos9-1)
Set @DocuSerie=SUBSTRING(@orden,@pos10+1,@pos11-@pos10-1)
Set @TipoCodigo=SUBSTRING(@orden,@pos11+1,@pos12-@pos11-1)
set @DocuAdicional=convert(decimal(18,2),SUBSTRING(@orden,@pos12+1,@pos13-@pos12-1))
set @DocuAsociado=SUBSTRING(@orden,@pos13+1,@pos14-@pos13-1)
set @DocuConcepto=SUBSTRING(@orden,@pos14+1,@pos15-@pos14-1)
set @DocuHASH=SUBSTRING(@orden,@pos15+1,@pos16-@pos15-1)
set @EstadoSunat=SUBSTRING(@orden,@pos16+1,@pos17-@pos16-1)
set @Letras=SUBSTRING(@orden,@pos17+1,@pos18-@pos17-1)
set @NroReferencia=SUBSTRING(@orden,@pos18+1,@pos19-@pos18-1)
set @Concepto=SUBSTRING(@orden,@pos19+1,@pos20-@pos19-1)
set @Transaccion=SUBSTRING(@orden,@pos20+1,@pos21-@pos20-1)
set @Miembro=SUBSTRING(@orden,@pos21+1,@pos22-@pos21-1)
set @CodigoCliente=SUBSTRING(@orden,@pos22+1,@pos23-@pos22-1)
set @ICBPER=convert(decimal(18,2),SUBSTRING(@orden,@pos23+1,@pos24-@pos23-1))
set @CodigoSunat=SUBSTRING(@orden,@pos24+1,@pos25-@pos24-1)
set @MensajeSunat=SUBSTRING(@orden,@pos25+1,@pos26-@pos25-1)
set @DocuGravada=SUBSTRING(@orden,@pos26+1,@pos27-@pos26-1)
set @ConceptoOBS=SUBSTRING(@orden,@pos27+1,@pos28-@pos27-1)
set @Entrega=SUBSTRING(@orden,@pos28+1,@pos29-@pos28-1)

set @FormaPago=SUBSTRING(@orden,@pos29+1,@pos30-@pos29-1)
set @EntidadBancaria=SUBSTRING(@orden,@pos30+1,@pos31-@pos30-1)

set @Efectivo=convert(decimal(18,2),SUBSTRING(@orden,@pos31+1,@pos32-@pos31-1))
set @Deposito=convert(decimal(18,2),SUBSTRING(@orden,@pos32+1,@pos33-@pos32-1))

if(@ConceptoOBS<>'VENTA')
begin
set @DetalleId=isnull((select top 1 d.DetalleId from CajaDetalle d
where d.NotaIdB=@NotaId 
order by d.DetalleId desc),0)
end
else
begin
set @DetalleId=isnull((select top 1 d.DetalleId from CajaDetalle d
where d.NotaId=@NotaId 
order by d.DetalleId desc),0)
end
set @FechaFactura=(select top 1 d.DocuEmision from DocumentoVenta d
where NotaId=@NotaId and TipoCodigo='01')
Begin Transaction
insert into DocumentoVenta values(@CompaniaId,@NotaId,@DocuDocumento,@DocuNumero,
@ClienteId,GETDATE(),@DocuEmision,'ALCONTADO',@Letras,@DocuSubTotal,
@DocuIgv,@DocuTotal,@DocuGravada,@DocuUsuario,'EMITIDO',@DocuSerie,@TipoCodigo,@DocuAdicional,
@DocuAsociado,@DocuConcepto,@NroReferencia,@DocuHASH,@EstadoSunat,@Concepto,'',@ICBPER,@CodigoSunat,
@MensajeSunat,@FormaPago,@EntidadBancaria,'',@Efectivo,@Deposito)
Set @DocuId= @@identity
set @KardexDocu='NC '+@DocuSerie+'-'+@DocuNumero
Update DocumentoVenta
set DocuAsociado=@DocuId
where DocuId=@DocuAsociado

if(@DocuConcepto='ANULACION DE LA OPERACION')
begin
update NotaPedido
set NotaEstado='ANULADO',NotaAcuenta=0,NotaSaldo=NotaPagar
where NotaId=@NotaId
end

if(@FechaFactura=CONVERT(date,GETDATE()))
begin
if(@Concepto='MERCADERIA')
begin
	delete from CajaDetalle
	where DetalleId=@DetalleId
	delete from CajaDetalle
	where NotaIdB=@NotaId
end
end
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max),
		@IdProducto numeric(20),
	    @IdProductoB numeric(20),
		@Cantidad decimal(18,2),
		@Precio decimal(18,2),
		@Importe decimal(18,2),
		@DetalleNotaId numeric(38),
		@UM varchar(80),
		@ValorUM decimal(18,4),
		@StockInicial decimal(18,2),
		@StockFinal decimal(18,2),@CantidadIng decimal(18,2),
		@CodigoPro varchar(80)
		
Declare @p1 int,@p2 int,@p3 int,@p4 int,
        @p5 int,@p6 int,@p7 int,@p8 int

Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	Begin
Set @p1 = CharIndex('|',@Columna,0)
Set @p2 = CharIndex('|',@Columna,@p1+1)
Set @p3 = CharIndex('|',@Columna,@p2+1)
Set @p4 = CharIndex('|',@Columna,@p3+1)
Set @p5 = CharIndex('|',@Columna,@p4+1)
Set @p6= CharIndex('|',@Columna,@p5+1)
Set @p7= CharIndex('|',@Columna,@p6+1)
Set @p8 = Len(@Columna)+1
Set @Cantidad=Convert(decimal(18,2),SUBSTRING(@Columna,1,@p1-1))
Set @UM=SUBSTRING(@Columna,@p1+1,@p2-(@p1+1))
Set @Precio=Convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))
Set @Importe=Convert(decimal(18,2),SUBSTRING(@Columna,@p3+1,@p4-(@p3+1)))
Set @DetalleNotaId=Convert(numeric(38),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))
Set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))
Set @ValorUM=Convert(decimal(18,4),SUBSTRING(@Columna,@p6+1,@p7-(@p6+1)))
Set @CodigoPro=SUBSTRING(@Columna,@p7+1,@p8-(@p7+1))

if(@CodigoPro='MD100')
begin

set @IdProductoB=isnull((select top 1 P.IdProducto from Producto P
where P.ProductoCodigo=@CodigoPro),0)

set @IdProducto=@IdProductoB

end

insert into DetalleDocumento 
values(@DocuId,@IdProducto,@Cantidad,@Precio,@Importe,@DetalleNotaId,@UM,@ValorUM)

if(@Entrega='INMEDIATA')
begin
	--set @CodigoPro=isnull((select top 1 ProductoCodigo from Producto
 --   where IdProducto=@IdProducto),'0')
 --   if(@CodigoPro='PEKIT-3')
 --   begin
 --   set @StockInicial=(select top 1 ProductoCantidad from Producto(nolock) 
 --   where IdProducto=7)
	--set @CantidadIng=(@Cantidad*@ValorUM)
	--set @StockFinal=@StockInicial+@CantidadIng
 --   insert into Kardex
	--values(7,GETDATE(),'Ingreso por N-Credito',@DocuNumero,
	--@StockInicial,@CantidadIng,0,57,@StockFinal,'INGRESO',@DocuUsuario,@Miembro,
	--@CodigoCliente,@Transaccion,@TipoCodigo,@DocuSerie,'02','S',convert(varchar,@DocuId),'','B')
	--update Producto
	--set ProductoCantidad=ProductoCantidad+@CantidadIng
	--where IdProducto=7
 --   end
    set @StockInicial=(select top 1 ProductoCantidad from Producto(nolock) where IdProducto=@IdProducto)
	set @CantidadIng=(@Cantidad*@ValorUM)
	set @StockFinal=@StockInicial+@CantidadIng     
	update Producto
	set ProductoCantidad=ProductoCantidad+@CantidadIng
	where IdProducto=@IdProducto
	insert into Kardex
	values(@IdProducto,GETDATE(),'Ingreso por N-Credito',@DocuNumero,
	@StockInicial,@CantidadIng,0,@Precio,@StockFinal,'INGRESO',@DocuUsuario,@Miembro,
	@CodigoCliente,@Transaccion,@TipoCodigo,@DocuSerie,'02','S',convert(varchar,@DocuId),'','B')
end
else
begin
	set @StockInicial=(select top 1 ProductoCantidad from Producto(nolock) where IdProducto=@IdProducto)
	set @CantidadIng=(@Cantidad*@ValorUM)
	set @StockFinal=@StockInicial+@CantidadIng
	insert into Kardex
	values(@IdProducto,GETDATE(),'Ingreso por N-Credito',@DocuNumero,
	@StockInicial,@CantidadIng,0,@Precio,@StockFinal,'INGRESO',@DocuUsuario,@Miembro,
	@CodigoCliente,@Transaccion,@TipoCodigo,@DocuSerie,'02','N',convert(varchar,@DocuId),'','B')
end
Fetch Next From Tabla INTO @Columna
end
    update Kardex
    set Estado='B'
    where DocuId=@DocuAsociado
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
select 'true'
End
GO

IF OBJECT_ID(N'dbo.uspinsertarNotaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspinsertarNotaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspinsertarNotaB]            
@ListaOrden varchar(Max)            
as            
begin            
Declare @pos1 int,@pos2 int            
Declare @orden varchar(max),            
        @detalle varchar(max)            
Set @pos1 = CharIndex('[',@ListaOrden,0)            
Set @pos2 =Len(@ListaOrden)+1            
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)            
Set @detalle = SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)            
Declare @c1 int,@c2 int,@c3 int,@c4 int,            
        @c5 int,@c6 int,@c7 int,@c8 int,            
        @c9 int,@c10 int,@c11 int,@c12 int,            
        @c13 int,@c14 int,@c15 int,@c16 int,            
        @c17 int,@c18 int,@c19 int,@c20 int,            
        @c21 int,@c22 int,@c23 int,@c24 int,            
        @c25 int,@c26 int,@c27 int,@c28 int,            
        @c29 int,@c30 int,@c31 int,@c32 int,            
        @c33 int,@c34 int,@c35 int,@c36 int,            
        @c37 int,@c38 int,@c39 int,@c40 int,            
        @c41 int,@c42 int,@c43 int,@c44 int            
Declare             
  @NotaDocu varchar(60),@ClienteId numeric(20),            
  @NotaUsuario varchar(60),@NotaFormaPago varchar(60),            
  @NotaCondicion varchar(60),@NotaDireccion varchar(max),            
  @NotaSubtotal decimal (18,2),@NotaMovilidad decimal(18,2),            
  @NotaDescuento decimal (18, 2),@NotaTotal decimal (18,2),            
  @NotaAcuenta decimal(18,2),@NotaSaldo decimal(18,2),            
  @NotaAdicional decimal(18,2),@NotaTarjeta decimal(18,2),            
  @NotaPagar decimal(18,2),            
  @NotaEstado varchar(60),@CompaniaId int,            
  @NotaEntrega varchar(40),@NotaConcepto varchar(60),            
  @Serie char(4),@Numero varchar(60),            
  @NotaGanancia decimal(18,2),@Letra varchar(max),            
  @DocuAdicional decimal(18,2),@DocuHash varchar(250),            
  @EstadoSunat varchar(80),@DocuSubtotal decimal(18,2),            
  @DocuIGV decimal(18,2),@UsuarioId int,@CajaId numeric(38),          
  @NotaTransaccion varchar(250),@KARDEX VARCHAR(1),            
  @Miembro varchar(300),@CodigoCliente varchar(80),            
  @ICBPER DECIMAL(18,2),@Asistencia int,@DocuGRAVADA decimal(18,2),            
  @ConceptoOBS varchar(80),@EstadoOBS varchar(20),            
  @PV varchar(40),@Image varchar(max),@TEXTO varchar(300),            
  @CodigoRes varchar(80),@Responsable varchar(300),            
  @EntidadBancaria varchar(80),            
  @Efectivo decimal(18,2),@Deposito decimal(18,2),            
  @NroOperacion varchar(80)            
Set @c1 = CharIndex('|',@orden,0)            
Set @c2 = CharIndex('|',@orden,@c1+1)            
Set @c3 = CharIndex('|',@orden,@c2+1)            
Set @c4 = CharIndex('|',@orden,@c3+1)            
Set @c5 = CharIndex('|',@orden,@c4+1)            
Set @c6= CharIndex('|',@orden,@c5+1)            
Set @c7 = CharIndex('|',@orden,@c6+1)            
Set @c8 = CharIndex('|',@orden,@c7+1)            
Set @c9 = CharIndex('|',@orden,@c8+1)            
Set @c10= CharIndex('|',@orden,@c9+1)            
Set @c11= CharIndex('|',@orden,@c10+1)            
Set @c12= CharIndex('|',@orden,@c11+1)            
Set @c13= CharIndex('|',@orden,@c12+1)            
Set @c14= CharIndex('|',@orden,@c13+1)            
Set @c15= CharIndex('|',@orden,@c14+1)            
Set @c16= CharIndex('|',@orden,@c15+1)            
Set @c17= CharIndex('|',@orden,@c16+1)            
Set @c18 = CharIndex('|',@orden,@c17+1)            
Set @c19 = CharIndex('|',@orden,@c18+1)            
Set @c20= CharIndex('|',@orden,@c19+1)            
Set @c21= CharIndex('|',@orden,@c20+1)            
Set @c22= CharIndex('|',@orden,@c21+1)            
Set @c23= CharIndex('|',@orden,@c22+1)            
Set @c24= CharIndex('|',@orden,@c23+1)            
Set @c25= CharIndex('|',@orden,@c24+1)            
Set @c26= CharIndex('|',@orden,@c25+1)            
Set @c27= CharIndex('|',@orden,@c26+1)            
Set @c28= CharIndex('|',@orden,@c27+1)            
Set @c29= CharIndex('|',@orden,@c28+1)            
Set @c30= CharIndex('|',@orden,@c29+1)            
Set @c31= CharIndex('|',@orden,@c30+1)            
Set @c32= CharIndex('|',@orden,@c31+1)        
Set @c33= CharIndex('|',@orden,@c32+1)            
Set @c34= CharIndex('|',@orden,@c33+1)            
Set @c35= CharIndex('|',@orden,@c34+1)            
Set @c36= CharIndex('|',@orden,@c35+1)            
Set @c37= CharIndex('|',@orden,@c36+1)            
Set @c38= CharIndex('|',@orden,@c37+1)            
Set @c39= CharIndex('|',@orden,@c38+1)            
Set @c40= CharIndex('|',@orden,@c39+1)            
Set @c41= CharIndex('|',@orden,@c40+1)            
Set @c42= CharIndex('|',@orden,@c41+1)            
Set @c43= CharIndex('|',@orden,@c42+1)            
Set @c44= Len(@orden)+1            
set @NotaDocu=SUBSTRING(@orden,1,@c1-1)            
set @ClienteId=convert(numeric(20),SUBSTRING(@orden,@c1+1,@c2-@c1-1))            
set @NotaUsuario=SUBSTRING(@orden,@c2+1,@c3-@c2-1)            
set @NotaFormaPago=SUBSTRING(@orden,@c3+1,@c4-@c3-1)            
set @NotaCondicion=SUBSTRING(@orden,@c4+1,@c5-@c4-1)            
set @NotaDireccion=SUBSTRING(@orden,@c5+1,@c6-@c5-1)            
set @NotaSubtotal=convert(decimal(18,2),SUBSTRING(@orden,@c6+1,@c7-@c6-1))            
set @NotaMovilidad=convert(decimal(18,2),SUBSTRING(@orden,@c7+1,@c8-@c7-1))            
set @NotaDescuento=convert(decimal(18,2),SUBSTRING(@orden,@c8+1,@c9-@c8-1))            
set @NotaTotal=convert(decimal(18,2),SUBSTRING(@orden,@c9+1,@c10-@c9-1))            
set @NotaAcuenta=convert(decimal(18,2),SUBSTRING(@orden,@c10+1,@c11-@c10-1))            
set @NotaSaldo=convert(decimal(18,2),SUBSTRING(@orden,@c11+1,@c12-@c11-1))            
set @NotaAdicional=convert(decimal(18,2),SUBSTRING(@orden,@c12+1,@c13-@c12-1))            
set @NotaTarjeta=convert(decimal(18,2),SUBSTRING(@orden,@c13+1,@c14-@c13-1))            
set @NotaPagar=convert(decimal(18,2),SUBSTRING(@orden,@c14+1,@c15-@c14-1))            
set @NotaEstado=SUBSTRING(@orden,@c15+1,@c16-@c15-1)            
set @CompaniaId=convert(int,SUBSTRING(@orden,@c16+1,@c17-@c16-1))            
set @NotaEntrega=SUBSTRING(@orden,@c17+1,@c18-@c17-1)            
set @NotaConcepto=SUBSTRING(@orden,@c18+1,@c19-@c18-1)            
set @Serie=convert(char(4),SUBSTRING(@orden,@c19+1,@c20-@c19-1))            
set @Numero=SUBSTRING(@orden,@c20+1,@c21-@c20-1)            
set @NotaGanancia=convert(decimal(18,2),SUBSTRING(@orden,@c21+1,@c22-@c21-1))            
set @Letra=SUBSTRING(@orden,@c22+1,@c23-@c22-1)            
set @DocuAdicional=convert(decimal(18,2),SUBSTRING(@orden,@c23+1,@c24-@c23-1))            
set @DocuHash=SUBSTRING(@orden,@c24+1,@c25-@c24-1)            
set @EstadoSunat=SUBSTRING(@orden,@c25+1,@c26-@c25-1)            
set @DocuSubtotal=convert(decimal(18,2),SUBSTRING(@orden,@c26+1,@c27-@c26-1))            
set @DocuIGV=convert(decimal(18,2),SUBSTRING(@orden,@c27+1,@c28-@c27-1))            
set @UsuarioId=convert(int,SUBSTRING(@orden,@c28+1,@c29-@c28-1))            
            
set @NotaTransaccion=SUBSTRING(@orden,@c29+1,@c30-@c29-1)            
set @Miembro=SUBSTRING(@orden,@c30+1,@c31-@c30-1)            
set @CodigoCliente=SUBSTRING(@orden,@c31+1,@c32-@c31-1)            
set @ICBPER=convert(decimal(18,2),SUBSTRING(@orden,@c32+1,@c33-@c32-1))            
set @DocuGRAVADA=convert(decimal(18,2),SUBSTRING(@orden,@c33+1,@c34-@c33-1))            
set @ConceptoOBS=SUBSTRING(@orden,@c34+1,@c35-@c34-1)            
set @EstadoOBS=SUBSTRING(@orden,@c35+1,@c36-@c35-1)            
set @PV=SUBSTRING(@orden,@c36+1,@c37-@c36-1)            
set @Image=SUBSTRING(@orden,@c37+1,@c38-@c37-1)            
set @CodigoRes=SUBSTRING(@orden,@c38+1,@c39-@c38-1)            
set @Responsable=SUBSTRING(@orden,@c39+1,@c40-@c39-1)            
set @EntidadBancaria=SUBSTRING(@orden,@c40+1,@C41-@c40-1)            
            
set @Efectivo=convert(decimal(18,2),SUBSTRING(@orden,@c41+1,@c42-@c41-1))            
set @Deposito=convert(decimal(18,2),SUBSTRING(@orden,@c42+1,@c43-@c42-1))            
set @NroOperacion=SUBSTRING(@orden,@c43+1,@c44-@c43-1)   
            
declare @cod varchar(13)            
SET @cod=isnull((select TOP 1 dbo.genenerarNroFactura(@Serie,@CompaniaId,@NotaDocu) AS ID             
FROM DocumentoVenta),'00000001')            
            
if(@ConceptoOBS='PUNTOS A ICA' or @ConceptoOBS='PUNTOS A COMAS')     
begin            
set @TEXTO='SE MANDO A PASAR '+@ConceptoOBS+' CODIGO: '+@CodigoCliente+' ('+@Miembro+')'            
end            
else if(@ConceptoOBS='POR PASAR AL OBS')            
begin            
set @TEXTO='CANCELARON PRODUCTOS POR PASAR AL OBS '+@PV +' CODIGO: '+@CodigoCliente+' ('+@Miembro+')'           
end            
else if(@ConceptoOBS='VENTA LIBRE')            
begin            
set @TEXTO='VENTA LIBRE. SE VENDIO SIN CODIGO ('+@Miembro+')'            
end            
else if(@ConceptoOBS='FACTURA MANUAL')            
begin            
set @TEXTO='FACTURA MANUAL. SUMA TOTAL DE PRODUCTOS Y CODIGOS. RESPONSABLE ('+@Miembro+')'            
end            
else if(@ConceptoOBS='LIQUIDACION DE PAGO')            
begin            
set @TEXTO='CANCELARON DEUDA PENDIENTE PORQUE SE LE PASO SOLO PUNTOS AL OBS '+@PV +' CODIGO: '+@CodigoCliente+' ('+@Miembro+')'            
end            
else            
begin            
set @TEXTO='VENTA DEL OBS DOCUMENTO '+@Serie+'-'+@cod+' CODIGO: '+@CodigoCliente+' ('+@Miembro+')'           
end            
if(@Deposito>0)            
begin            
set @TEXTO=@TEXTO+' FORMA DE PAGO: '+@NotaFormaPago+' ENTIDAD BANCARIA: '+@EntidadBancaria+' NRO OPERACION: '+@NroOperacion            
end            
            
--set @Asistencia=(select COUNT(a.PersonalId)from Asistencia a            
--inner join Usuarios u            
--on u.PersonalId=a.PersonalId            
--where u.UsuarioID=@UsuarioId and (Day(a.Fecha)=Day(GETDATE()) and Month(a.Fecha)=MONTH(GETDATE()) and year(a.Fecha)=year(GETDATE())))            
--if(@Asistencia=0)            
--begin            
--Select 'NO ASISTIO'            
--end            
--else            
--begin            
IF EXISTS(select top 1 NotaTransaccion             
from NotaPedido             
where NotaTransaccion=@NotaTransaccion and NotaTransaccion<>'' and NotaEstado<>'ANULADO')            
begin            
select 'existe'            
END            
ELSE IF EXISTS(select top 1 NroOperacion            
from NotaPedido             
where EntidadBancaria=@EntidadBancaria and EntidadBancaria<>'-' and NroOperacion=@NroOperacion and NroOperacion<>'' and NotaEstado<>'ANULADO')            
begin            
select 'OPERACION'            
END            
else            
begin            
set @CajaId=isnull((select top 1 CajaId from Caja where CajaEstado='ACTIVO'         
and UsuarioId=@UsuarioId order by 1 desc),'0')            
if(@CajaId=0)            
begin            
select 'false'            
end            
else            
begin            
if(@NotaDocu='FACTURA')            
begin            
set @NotaEstado='PENDIENTE'            
 if(@NotaCondicion='CREDITO' or @NotaCondicion='PAGO/VARIOS')            
 begin            
 set @NotaSaldo=@NotaPagar            
 set @NotaAcuenta=0            
 end            
 else            
 begin            
 set @NotaSaldo=0            
 set @NotaAcuenta=@NotaPagar            
 end            
end            
else            
begin            
   if(@NotaCondicion='CREDITO' or @NotaCondicion='PAGO/VARIOS')            
   begin            
   set @NotaEstado='PENDIENTE'            
   set @NotaSaldo=@NotaPagar            
   set @NotaAcuenta=0            
   end            
   else            
   begin            
   set @NotaEstado='CANCELADO'            
   set @NotaSaldo=0            
   set @NotaAcuenta=@NotaPagar            
   end            
end            
            
declare @NotaId numeric(38),            
        @DocuId numeric(38)=0            
Begin Transaction            
            
update Cliente            
set ClienteDireccion=@NotaDireccion,ClienteDocu=@NotaDocu            
where ClienteId=@ClienteId            
delete from TemporalVenta             
where UsuarioID=@UsuarioId            
    
insert into NotaPedido values(@NotaDocu,@ClienteId,GETDATE(),@NotaUsuario,            
@NotaFormaPago,@NotaCondicion,GETDATE(),@NotaDireccion,            
@NotaSubtotal,@NotaMovilidad,@NotaDescuento,@NotaTotal,@NotaAcuenta,@NotaSaldo,            
@NotaAdicional,@NotaTarjeta,@NotaPagar,@NotaEstado,@CompaniaId,            
@NotaEntrega,'','',@NotaConcepto,@Serie,@cod,@NotaGanancia,@CajaId,            
@NotaTransaccion,@ICBPER,@ConceptoOBS,@EstadoOBS,@CodigoRes,@Responsable,            
@EntidadBancaria,@NroOperacion,@Efectivo,@Deposito,'ENTREGADO',GETDATE(),@NotaUsuario)--  'PENDIENTE',NULL,'')--       
set @NotaId=(select @@IDENTITY)            
Declare @TipoCodigo nvarchar(3)            
            
DECLARE @VFechaPago datetime            
set @VFechaPago=GETDATE()            
if(@NotaCondicion='CREDITO')set @VFechaPago=DATEADD(DAY,15,@VFechaPago)            
            
if @NotaDocu='PROFORMA V'            
begin            
set @TipoCodigo='00'            
insert into DocumentoVenta values            
(@CompaniaId,@NotaId,@NotaDocu,@cod,@ClienteId,@VFechaPago,            
GETDATE(),@NotaCondicion,@Letra,@DocuSubtotal,            
@DocuIGV,@NotaPagar,@DocuGRAVADA,@NotaUsuario,'EMITIDO',@Serie,@TipoCodigo,@DocuAdicional,            
'','VENTA','',@DocuHash,'ENVIADO',@NotaConcepto,@NotaTransaccion,@ICBPER,'','',            
@NotaFormaPago,@EntidadBancaria,@NroOperacion,@Efectivo,@Deposito)            
set @DocuId=(select @@IDENTITY)            
            
if(@ConceptoOBS='VENTA' and @NotaCondicion='ALCONTADO')            
begin            
 if(@Deposito>0)            
 begin            
    insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',            
 @TEXTO,@Deposito,@Deposito,0,@Image,'D','',@NotaId,'',@NotaFormaPago,            
 @EntidadBancaria,@NroOperacion)            
 end                
end            
Else            
begin            
if(@ConceptoOBS<>'VENTA' and @NotaCondicion='ALCONTADO')            
begin            
if(@ConceptoOBS<>'FACTURA MANUAL')            
begin            
insert into CajaDetalle values(@CajaId,GETDATE(),0,'INGRESO',            
@TEXTO,@NotaTotal,@NotaTotal,0,@Image,'D','',@NotaId,'',            
@NotaFormaPago,@EntidadBancaria,@NroOperacion)            
if(@Deposito>0)            
begin            
 insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',            
 @TEXTO,@Deposito,@Deposito,0,@Image,'D','',@NotaId,'',@NotaFormaPago,            
 @EntidadBancaria,@NroOperacion)            
end                  
end            
            
end            
else            
begin            
insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,'INGRESO',            
'Transacción con '+@NotaFormaPago,@NotaTotal,@NotaTotal,0,'','T','',0,'',@NotaFormaPago,'','')            
end            
end            
            
SET @KARDEX='S'            
end            
            
else if @NotaDocu='BOLETA'            
begin            
set @TipoCodigo='03'            
insert into DocumentoVenta values            
(@CompaniaId,@NotaId,'BOLETA',@cod,@ClienteId,@VFechaPago,            
GETDATE(),@NotaCondicion,@Letra,@DocuSubtotal,            
@DocuIGV,@NotaPagar,@DocuGRAVADA,@NotaUsuario,'EMITIDO',@Serie,@TipoCodigo,@DocuAdicional,            
'','VENTA','',@DocuHash,@EstadoSunat,@NotaConcepto,@NotaTransaccion,@ICBPER,'','',            
@NotaFormaPago,@EntidadBancaria,@NroOperacion,@Efectivo,@Deposito)            
set @DocuId=(select @@IDENTITY)            
            
if(@ConceptoOBS='VENTA' and @NotaCondicion='ALCONTADO')            
begin            
if(@Deposito>0)            
 begin            
    insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',            
 @TEXTO,@Deposito,@Deposito,0,@Image,'D','',@NotaId,'',@NotaFormaPago,            
 @EntidadBancaria,@NroOperacion)            
 end                
end            
Else            
begin            
if(@ConceptoOBS<>'VENTA' and @NotaCondicion='ALCONTADO')            
begin            
if(@ConceptoOBS<>'FACTURA MANUAL')            
begin            
insert into CajaDetalle values(@CajaId,GETDATE(),0,'INGRESO',            
@TEXTO,@NotaTotal,@NotaTotal,0,@Image,'D','',@NotaId,'',            
@NotaFormaPago,@EntidadBancaria,@NroOperacion)            
            
 if(@Deposito>0)            
 begin            
 insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',            
 @TEXTO,@Deposito,@Deposito,0,@Image,'D','',@NotaId,'',@NotaFormaPago,            
 @EntidadBancaria,@NroOperacion)            
 end                
end            
end            
else            
begin            
insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,'INGRESO',            
'Transacción con '+@NotaFormaPago,@NotaTotal,@NotaTotal,0,'','T','',0,'',@NotaFormaPago,'','')     
end            
end            
            
SET @KARDEX='S'            
end            
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')             
Open Tabla            
Declare @Columna varchar(max),            
  @IdProducto numeric(20),            
  @DetalleCantidad decimal(18,2),            
  @DetalleUm varchar(40),            
  @Descripcion varchar(max),            
  @DetalleCosto decimal(18,2),             
  @DetallePrecio decimal(18,2),            
  @DetallePV decimal(18,2),            
  @DetalleSV decimal(18,2),            
  @DetalleImporte decimal(18,2),            
  @DetalleEstado varchar(60),            
  @ValorUM decimal(18,4),@CantidadSaldo decimal(18,2),            
  @IniciaStock decimal(18,2),@StockFinal decimal(18,2)           
Declare @p1 int,@p2 int,@p3 int,@p4 int,            
        @p5 int,@p6 int,@p7 int,@p8 int,            
        @p9 int,@p10 int,@p11 int            
Fetch Next From Tabla INTO @Columna            
 While @@FETCH_STATUS = 0            
 Begin            
Set @p1 = CharIndex('|',@Columna,0)            
Set @p2 = CharIndex('|',@Columna,@p1+1)            
Set @p3 = CharIndex('|',@Columna,@p2+1)            
Set @p4 = CharIndex('|',@Columna,@p3+1)            
Set @p5 = CharIndex('|',@Columna,@p4+1)            
Set @p6= CharIndex('|',@Columna,@p5+1)            
Set @p7= CharIndex('|',@Columna,@p6+1)            
Set @p8 = CharIndex('|',@Columna,@p7+1)            
Set @p9= CharIndex('|',@Columna,@p8+1)            
Set @p10 = CharIndex('|',@Columna,@p9+1)            
Set @p11=Len(@Columna)+1            
set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,1,@p1-1))            
Set @DetalleCantidad=convert(decimal(18,2),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))            
Set @DetalleUm=SUBSTRING(@Columna,@p2+1,@p3-(@p2+1))            
Set @Descripcion=SUBSTRING(@Columna,@p3+1,@p4-(@p3+1))            
Set @DetalleCosto=convert(decimal(18,2),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))            
Set @DetallePrecio=convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))            
Set @DetallePV=convert(decimal(18,2),SUBSTRING(@Columna,@p6+1,@p7-(@p6+1)))            
Set @DetalleSV=convert(decimal(18,2),SUBSTRING(@Columna,@p7+1,@p8-(@p7+1)))            
Set @DetalleImporte=convert(decimal(18,2),SUBSTRING(@Columna,@p8+1,@p9-(@p8+1)))            
Set @DetalleEstado=SUBSTRING(@Columna,@p9+1,@p10-(@p9+1))            
set @ValorUM=convert(decimal(18,4),SUBSTRING(@Columna,@p10+1,@p11-(@p10+1)))            
if(@NotaEntrega='INMEDIATA')Set @CantidadSaldo=0            
else Set @CantidadSaldo=@DetalleCantidad            
insert into DetallePedido values(@NotaId,@IdProducto,@DetalleCantidad,            
@DetalleUm,@Descripcion,@DetalleCosto, @DetallePrecio,            
@DetalleImporte,@DetalleEstado,@CantidadSaldo,@ValorUM,@DetallePV,@DetalleSV)            
if(@DocuId<>0)            
begin            
insert into DetalleDocumento values            
(@DocuId,@IdProducto,@DetalleCantidad,@DetallePrecio,@DetalleImporte,            
@NotaId,@DetalleUm,@ValorUM)            
end            
if(@NotaDocu <>'FACTURA')            
BEGIN            
if(@NotaEntrega='INMEDIATA')            
begin             
 set @IniciaStock=(select top 1 ProductoCantidad from Producto             
 where IdProducto=@IdProducto)            
 set @StockFinal=@IniciaStock-@DetalleCantidad      
 insert into Kardex values(@IdProducto,GETDATE(),'Salida por Venta',@Numero,@IniciaStock,            
 0,@DetalleCantidad,@DetalleCosto,@StockFinal,'SALIDA',@NotaUsuario,@Miembro,            
 @CodigoCliente,@NotaTransaccion,@TipoCodigo,@Serie,'01','S',convert(varchar,@DocuId),'','E')            
 update producto             
 set  ProductoCantidad =ProductoCantidad - @DetalleCantidad            
 where IDProducto=@IdProducto             
end            
else            
begin            
 set @IniciaStock=(select top 1 ProductoCantidad from Producto where IdProducto=@IdProducto)            
 set @StockFinal=@IniciaStock-@DetalleCantidad            
 insert into Kardex values(@IdProducto,GETDATE(),'Salida por Venta',@Numero,@IniciaStock,            
 0,@DetalleCantidad,@DetalleCosto,@StockFinal,'SALIDA',@NotaUsuario,@Miembro,       
 @CodigoCliente,@NotaTransaccion,@TipoCodigo,@Serie,'01','N',convert(varchar,@DocuId),'','E')            
end            
END            
Fetch Next From Tabla INTO @Columna            
end            
 Close Tabla;            
 Deallocate Tabla;            
 Commit Transaction;            
 select convert(varchar,@NotaId)+'¬'+@cod            
end            
END            
END            
--end
GO

IF OBJECT_ID(N'dbo.uspinsertarNotaBweb', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspinsertarNotaBweb] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE dbo.uspinsertarNotaBweb
    @ListaOrden varchar(max)
AS
BEGIN
    SET NOCOUNT ON;

    /* =========================================================
       SEPARAR CABECERA Y DETALLE
       ========================================================= */

    DECLARE
        @pos1 int,
        @orden varchar(max),
        @detalle varchar(max);

    SET @pos1 = CHARINDEX('[', @ListaOrden, 1);

    IF @pos1 <= 0
    BEGIN
        RAISERROR('Formato de orden invalido.', 16, 1);
        RETURN;
    END;

    SET @orden = SUBSTRING(
        @ListaOrden,
        1,
        @pos1 - 1
    );

    SET @detalle = SUBSTRING(
        @ListaOrden,
        @pos1 + 1,
        LEN(@ListaOrden) - @pos1
    );

    /* =========================================================
       DESCOMPONER CAMPOS DE CABECERA
       ========================================================= */

    DECLARE @campos TABLE
    (
        Pos int IDENTITY(1,1) NOT NULL,
        Valor varchar(max) NULL
    );

    DECLARE
        @start int,
        @end int;

    SET @start = 1;

    WHILE @start <= LEN(@orden) + 1
    BEGIN
        SET @end = CHARINDEX('|', @orden, @start);

        IF @end = 0
            SET @end = LEN(@orden) + 1;

        INSERT INTO @campos
        (
            Valor
        )
        VALUES
        (
            SUBSTRING(
                @orden,
                @start,
                @end - @start
            )
        );

        SET @start = @end + 1;
    END;

    /* =========================================================
       VARIABLES DE CABECERA
       ========================================================= */

    DECLARE
        @NotaDocu varchar(60),
        @ClienteId numeric(20),
        @NotaUsuario varchar(60),
        @NotaFormaPago varchar(60),
        @NotaCondicion varchar(60),
        @NotaDireccion varchar(max),

        @NotaSubtotal decimal(18,2),
        @NotaMovilidad decimal(18,2),
        @NotaDescuento decimal(18,2),
        @NotaTotal decimal(18,2),
        @NotaAcuenta decimal(18,2),
        @NotaSaldo decimal(18,2),
        @NotaAdicional decimal(18,2),
        @NotaTarjeta decimal(18,2),
        @NotaPagar decimal(18,2),

        @NotaEstado varchar(60),
        @CompaniaId int,
        @NotaEntrega varchar(40),
        @NotaConcepto varchar(60),

        @Serie varchar(60),
        @Numero varchar(60),
        @NotaGanancia decimal(18,2),

        @Letra varchar(max),
        @DocuAdicional decimal(18,2),
        @DocuHash varchar(250),
        @EstadoSunat varchar(80),
        @DocuSubtotal decimal(18,2),
        @DocuIGV decimal(18,2),

        @UsuarioId int,
        @NotaTransaccion varchar(250),
        @Miembro varchar(300),
        @CodigoCliente varchar(80),

        @ICBPER decimal(18,2),
        @DocuGravada decimal(18,2),

        @ConceptoOBS varchar(80),
        @EstadoOBS varchar(20),
        @PV varchar(40),
        @Image varchar(max),

        @CodigoRes varchar(80),
        @Responsable varchar(300),

        @EntidadBancaria varchar(80),
        @Efectivo decimal(18,2),
        @Deposito decimal(18,2),
        @NroOperacion varchar(80),

        @ClienteRazon varchar(140),
        @ClienteRuc varchar(40),
        @ClienteDni varchar(40),
        @DireccionFiscal varchar(max),

        @TipoCodigo char(20),
        @cod varchar(60),

        @NotaId numeric(38),
        @DocuId numeric(38);

    /* =========================================================
       ASIGNAR CAMPOS DE CABECERA
       ========================================================= */

    SELECT @NotaDocu = Valor
    FROM @campos
    WHERE Pos = 1;

    SELECT @ClienteId =
        CONVERT(
            numeric(20),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 2;

    SELECT @NotaUsuario = Valor
    FROM @campos
    WHERE Pos = 3;

    SELECT @NotaFormaPago = Valor
    FROM @campos
    WHERE Pos = 4;

    SELECT @NotaCondicion = Valor
    FROM @campos
    WHERE Pos = 5;

    SELECT @NotaDireccion = Valor
    FROM @campos
    WHERE Pos = 6;

    SELECT @NotaSubtotal =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 7;

    SELECT @NotaMovilidad =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 8;

    SELECT @NotaDescuento =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 9;

    SELECT @NotaTotal =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 10;

    SELECT @NotaAcuenta =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 11;

    SELECT @NotaSaldo =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 12;

    SELECT @NotaAdicional =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 13;

    SELECT @NotaTarjeta =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 14;

    SELECT @NotaPagar =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 15;

    SELECT @NotaEstado = Valor
    FROM @campos
    WHERE Pos = 16;

    SELECT @CompaniaId =
        CONVERT(
            int,
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 17;

    SELECT @NotaEntrega = Valor
    FROM @campos
    WHERE Pos = 18;

    SELECT @NotaConcepto = Valor
    FROM @campos
    WHERE Pos = 19;

    SELECT @Serie = Valor
    FROM @campos
    WHERE Pos = 20;

    SELECT @Numero = Valor
    FROM @campos
    WHERE Pos = 21;

    SELECT @NotaGanancia =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 22;

    SELECT @Letra = Valor
    FROM @campos
    WHERE Pos = 23;

    SELECT @DocuAdicional =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 24;

    SELECT @DocuHash = Valor
    FROM @campos
    WHERE Pos = 25;

    SELECT @EstadoSunat = Valor
    FROM @campos
    WHERE Pos = 26;

    SELECT @DocuSubtotal =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 27;

    SELECT @DocuIGV =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 28;

    SELECT @UsuarioId =
        CONVERT(
            int,
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 29;

    SELECT @NotaTransaccion = Valor
    FROM @campos
    WHERE Pos = 30;

    SELECT @Miembro = Valor
    FROM @campos
    WHERE Pos = 31;

    SELECT @CodigoCliente = Valor
    FROM @campos
    WHERE Pos = 32;

    SELECT @ICBPER =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 33;

    SELECT @DocuGravada =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 34;

    SELECT @ConceptoOBS = Valor
    FROM @campos
    WHERE Pos = 35;

    SELECT @EstadoOBS = Valor
    FROM @campos
    WHERE Pos = 36;

    SELECT @PV = Valor
    FROM @campos
    WHERE Pos = 37;

    SELECT @Image = Valor
    FROM @campos
    WHERE Pos = 38;

    SELECT @CodigoRes = Valor
    FROM @campos
    WHERE Pos = 39;

    SELECT @Responsable = Valor
    FROM @campos
    WHERE Pos = 40;

    SELECT @EntidadBancaria = Valor
    FROM @campos
    WHERE Pos = 41;

    SELECT @Efectivo =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 42;

    SELECT @Deposito =
        CONVERT(
            decimal(18,2),
            ISNULL(NULLIF(Valor, ''), '0')
        )
    FROM @campos
    WHERE Pos = 43;

    SELECT @NroOperacion = Valor
    FROM @campos
    WHERE Pos = 44;

    /* =========================================================
       VALORES POR DEFECTO
       ========================================================= */

    SET @NotaDocu =
        ISNULL(
            NULLIF(LTRIM(RTRIM(@NotaDocu)), ''),
            'BOLETA'
        );

    SET @NotaUsuario =
        ISNULL(@NotaUsuario, '');

    SET @NotaFormaPago =
        ISNULL(
            NULLIF(@NotaFormaPago, ''),
            'EFECTIVO'
        );

    SET @NotaCondicion =
        ISNULL(
            NULLIF(@NotaCondicion, ''),
            'ALCONTADO'
        );

    SET @NotaDireccion =
        ISNULL(
            NULLIF(@NotaDireccion, ''),
            '-'
        );

    SET @NotaEstado =
        ISNULL(
            NULLIF(@NotaEstado, ''),
            'PENDIENTE'
        );

    SET @CompaniaId =
        ISNULL(
            NULLIF(@CompaniaId, 0),
            1
        );

    SET @NotaEntrega =
        ISNULL(
            NULLIF(@NotaEntrega, ''),
            'INMEDIATA'
        );

    SET @NotaConcepto =
        ISNULL(
            NULLIF(@NotaConcepto, ''),
            'MERCADERIA'
        );

    SET @Serie =
        ISNULL(
            NULLIF(@Serie, ''),
            CASE
                WHEN @NotaDocu = 'FACTURA'
                    THEN 'FA01'
                ELSE 'BA01'
            END
        );

    SET @Letra = ISNULL(@Letra, '');
    SET @DocuHash = ISNULL(@DocuHash, '');

    SET @EstadoSunat =
        ISNULL(
            NULLIF(@EstadoSunat, ''),
            'PENDIENTE'
        );

    SET @NotaTransaccion = ISNULL(@NotaTransaccion, '');
    SET @Miembro = ISNULL(@Miembro, '');
    SET @CodigoCliente = ISNULL(@CodigoCliente, '');

    SET @ConceptoOBS =
        ISNULL(
            NULLIF(@ConceptoOBS, ''),
            'VENTA'
        );

    SET @EstadoOBS =
        ISNULL(
            NULLIF(@EstadoOBS, ''),
            'EMITIDO'
        );

    SET @CodigoRes = ISNULL(@CodigoRes, '');
    SET @Responsable = ISNULL(@Responsable, '');

    SET @EntidadBancaria =
        ISNULL(
            NULLIF(@EntidadBancaria, ''),
            '-'
        );

    SET @NroOperacion =
        ISNULL(@NroOperacion, '');

    /* =========================================================
       TIPO DE COMPROBANTE
       ========================================================= */

    IF @NotaDocu = 'FACTURA'
        SET @TipoCodigo = '01';
    ELSE IF @NotaDocu = 'PROFORMA V'
        SET @TipoCodigo = '00';
    ELSE
        SET @TipoCodigo = '03';

    /* =========================================================
       DATOS DEL CLIENTE
       ========================================================= */

    SELECT TOP 1
        @ClienteRazon =
            NULLIF(
                LTRIM(RTRIM(ClienteRazon)),
                ''
            ),

        @ClienteRuc =
            NULLIF(
                LTRIM(RTRIM(ClienteRuc)),
                ''
            ),

        @ClienteDni =
            NULLIF(
                LTRIM(RTRIM(ClienteDni)),
                ''
            ),

        @DireccionFiscal =
            NULLIF(
                LTRIM(RTRIM(ClienteDireccion)),
                ''
            )
    FROM Cliente
    WHERE ClienteId = @ClienteId;

    SET @ClienteRazon =
        ISNULL(
            @ClienteRazon,
            CASE
                WHEN @Miembro <> ''
                    THEN @Miembro
                ELSE 'VARIOS'
            END
        );

    SET @ClienteRuc = ISNULL(@ClienteRuc, '');
    SET @ClienteDni = ISNULL(@ClienteDni, '');

    IF @NotaDocu = 'BOLETA'
       AND @ClienteRuc = ''
       AND @ClienteDni = ''
    BEGIN
        SET @ClienteDni = '00000000';
    END;

    SET @DireccionFiscal =
        ISNULL(
            @DireccionFiscal,
            @NotaDireccion
        );

    IF NULLIF(@DireccionFiscal, '') IS NULL
        SET @DireccionFiscal = '-';

    /* =========================================================
       FORMA DE PAGO
       ========================================================= */

    IF @NotaFormaPago <> 'EFECTIVO'
    BEGIN
        IF @Efectivo IS NULL
            SET @Efectivo = 0;

        IF @Deposito IS NULL
           OR @Deposito = 0
            SET @Deposito = @NotaPagar;
    END;
    ELSE
    BEGIN
        IF @Efectivo IS NULL
           OR @Efectivo = 0
            SET @Efectivo = @NotaPagar;

        IF @Deposito IS NULL
            SET @Deposito = 0;
    END;

    /* =========================================================
       ESTADO SEGÚN CONDICIÓN / DOCUMENTO
       ========================================================= */

    IF @NotaCondicion = 'CREDITO'
    BEGIN
        SET @NotaEstado = 'EMITIDO';
        SET @NotaSaldo = @NotaPagar;
        SET @NotaAcuenta = 0;
    END;
    ELSE IF @NotaDocu <> 'FACTURA'
        AND @NotaDocu <> 'PROFORMA V'
    BEGIN
        SET @NotaEstado = 'CANCELADO';
        SET @NotaSaldo = 0;
        SET @NotaAcuenta = @NotaPagar;
    END;

    /* =========================================================
       VALIDAR TRANSACCIÓN DUPLICADA
       ========================================================= */

    IF @NotaTransaccion <> ''
       AND EXISTS
       (
            SELECT 1
            FROM NotaPedido
            WHERE NotaTransaccion = @NotaTransaccion
              AND ISNULL(NotaEstado, '') <> 'ANULADO'
       )
    BEGIN
        SELECT 'EXISTE';
        RETURN;
    END;

    /* =========================================================
       VALIDAR OPERACIÓN BANCARIA
       ========================================================= */

    IF @Deposito > 0
       AND NULLIF(LTRIM(RTRIM(@NroOperacion)), '') IS NULL
    BEGIN
        SELECT 'OPERACION_REQUERIDA';
        RETURN;
    END;

    IF @NroOperacion <> ''
       AND ISNULL(@EntidadBancaria, '-') <> '-'
       AND EXISTS
       (
            SELECT 1
            FROM NotaPedido
            WHERE EntidadBancaria = @EntidadBancaria
              AND NroOperacion = @NroOperacion
              AND ISNULL(NotaEstado, '') <> 'ANULADO'
       )
    BEGIN
        SELECT 'OPERACION';
        RETURN;
    END;

    /* =========================================================
       OBTENER CAJA ACTIVA
       ========================================================= */

    DECLARE @CajaId numeric(38);

    SELECT TOP (1)
        @CajaId = CajaId
    FROM Caja
    WHERE CajaEstado = 'ACTIVO'
      AND UsuarioId = @UsuarioId
    ORDER BY CajaId DESC;

    IF ISNULL(@CajaId, 0) = 0
    BEGIN
        SELECT 'false';
        RETURN;
    END;

    /* =========================================================
       TRANSACCIÓN PRINCIPAL
       ========================================================= */

    BEGIN TRY

        BEGIN TRANSACTION;

        /* -----------------------------------------------------
           ACTUALIZAR DIRECCIÓN DEL CLIENTE
           ----------------------------------------------------- */

        UPDATE Cliente
        SET ClienteDespacho = @NotaDireccion
        WHERE ClienteId = @ClienteId;

        /* -----------------------------------------------------
           LIMPIAR VENTA TEMPORAL
           ----------------------------------------------------- */

        DELETE FROM TemporalVenta
        WHERE UsuarioID = @UsuarioId;

        /* -----------------------------------------------------
           GENERAR NÚMERO DE COMPROBANTE
           ----------------------------------------------------- */

        SELECT @cod =
            ISNULL(
                (
                    SELECT TOP 1
                        dbo.genenerarNroFactura(
                            @Serie,
                            @CompaniaId,
                            @NotaDocu
                        )
                    FROM DocumentoVenta
                ),
                '00000001'
            );

        /* =====================================================
           INSERTAR NOTA DE PEDIDO
           ===================================================== */

        INSERT INTO NotaPedido
        (
            NotaDocu,
            ClienteId,
            NotaFecha,
            NotaUsuario,
            NotaFormaPago,
            NotaCondicion,
            NotaFechaPago,
            NotaDireccion,
            NotaSubtotal,
            NotaMovilidad,
            NotaDescuento,
            NotaTotal,
            NotaAcuenta,
            NotaSaldo,
            NotaAdicional,
            NotaTarjeta,
            NotaPagar,
            NotaEstado,
            CompaniaId,
            NotaEntrega,
            ModificadoPor,
            FechaEdita,
            NotaConcepto,
            NotaSerie,
            NotaNumero,
            NotaGanancia,
            CajaId,
            NotaTransaccion,
            ICBPER,
            ConceptoOBS,
            EstadoOBS,
            CodigoRes,
            Responsable,
            EntidadBancaria,
            NroOperacion,
            Efectivo,
            Deposito
        )
        VALUES
        (
            @NotaDocu,
            @ClienteId,
            GETDATE(),
            @NotaUsuario,
            @NotaFormaPago,
            @NotaCondicion,
            GETDATE(),
            @NotaDireccion,
            @NotaSubtotal,
            @NotaMovilidad,
            @NotaDescuento,
            @NotaTotal,
            @NotaAcuenta,
            @NotaSaldo,
            @NotaAdicional,
            @NotaTarjeta,
            @NotaPagar,
            @NotaEstado,
            @CompaniaId,
            @NotaEntrega,
            '',
            NULL,
            @NotaConcepto,
            @Serie,
            @cod,
            @NotaGanancia,
            @CajaId,
            @NotaTransaccion,
            @ICBPER,
            @ConceptoOBS,
            @EstadoOBS,
            @CodigoRes,
            @Responsable,
            @EntidadBancaria,
            @NroOperacion,
            @Efectivo,
            @Deposito
        );

        SET @NotaId = SCOPE_IDENTITY();

        /* =====================================================
           INSERTAR DOCUMENTO DE VENTA
           ===================================================== */

        INSERT INTO DocumentoVenta
        (
            CompaniaId,
            NotaId,
            DocuDocumento,
            DocuNumero,
            ClienteId,
            DocuRegistro,
            DocuEmision,
            DocuCondicion,
            DocuLetras,
            DocuSubTotal,
            DocuIgv,
            DocuTotal,
            DocuSaldo,
            DocuUsuario,
            DocuEstado,
            DocuSerie,
            TipoCodigo,
            DocuAdicional,
            DocuAsociado,
            DocuConcepto,
            DocuNroGuia,
            DocuHash,
            EstadoSunat,
            DocuOperacion,
            DocuTransaccion,
            ICBPER,
            CodigoSunat,
            MensajeSunat,
            FormaPago,
            EntidadBancaria,
            NroOperacion,
            Efectivo,
            Deposito
        )
        VALUES
        (
            @CompaniaId,
            @NotaId,
            @NotaDocu,
            @cod,
            @ClienteId,
            GETDATE(),
            GETDATE(),
            @NotaCondicion,
            @Letra,
            @DocuSubtotal,
            @DocuIGV,
            @NotaPagar,
            0,
            @NotaUsuario,
            'EMITIDO',
            @Serie,
            @TipoCodigo,
            @DocuAdicional,
            '',
            'VENTA',
            '',
            @DocuHash,

            CASE
                WHEN @NotaDocu = 'PROFORMA V'
                    THEN 'ENVIADO'
                ELSE @EstadoSunat
            END,

            @NotaConcepto,
            @NotaTransaccion,
            @ICBPER,
            '',
            '',
            @NotaFormaPago,
            @EntidadBancaria,
            @NroOperacion,
            @Efectivo,
            @Deposito
        );

        SET @DocuId = SCOPE_IDENTITY();

        /* =====================================================
           DATOS CPE WEB
           ===================================================== */

        INSERT INTO dbo.DocumentoVentaCpeWeb
        (
            DocuId,
            ClienteRazon,
            ClienteRuc,
            ClienteDni,
            DireccionFiscal,
            DocuPdfUrl,
            DocuXmlUrl,
            DocuCdrUrl,
            DocuFechaPago
        )
        VALUES
        (
            @DocuId,
            @ClienteRazon,
            @ClienteRuc,
            @ClienteDni,
            @DireccionFiscal,
            '',
            '',
            '',
            GETDATE()
        );

        /* =====================================================
           PROCESAR DETALLE
           ===================================================== */

        DECLARE detalle_cursor CURSOR LOCAL FAST_FORWARD
        FOR
            SELECT splitdata
            FROM dbo.fnSplitString(@detalle, ';')
            WHERE LEN(LTRIM(RTRIM(splitdata))) > 0;

        DECLARE @Columna varchar(max);

        DECLARE @detalleCampos TABLE
        (
            Pos int NOT NULL PRIMARY KEY,
            Valor varchar(max) NULL
        );

        DECLARE @campoPos int;

        OPEN detalle_cursor;

        FETCH NEXT FROM detalle_cursor
        INTO @Columna;

        WHILE @@FETCH_STATUS = 0
        BEGIN

            DELETE FROM @detalleCampos;

            SET @campoPos = 1;
            SET @start = 1;

            /* -------------------------------------------------
               SEPARAR COLUMNAS DEL DETALLE
               ------------------------------------------------- */

            WHILE @start <= LEN(@Columna) + 1
            BEGIN

                SET @end =
                    CHARINDEX(
                        '|',
                        @Columna,
                        @start
                    );

                IF @end = 0
                    SET @end = LEN(@Columna) + 1;

                INSERT INTO @detalleCampos
                (
                    Pos,
                    Valor
                )
                VALUES
                (
                    @campoPos,
                    SUBSTRING(
                        @Columna,
                        @start,
                        @end - @start
                    )
                );

                SET @campoPos = @campoPos + 1;
                SET @start = @end + 1;
            END;

            /* -------------------------------------------------
               VARIABLES DEL DETALLE
               ------------------------------------------------- */

            DECLARE
                @IdProducto numeric(20),
                @DetalleCantidad decimal(18,2),
                @DetalleUm varchar(40),
                @Descripcion varchar(max),
                @DetalleCosto decimal(18,4),
                @DetallePrecio decimal(18,2),
                @DetallePV decimal(18,2),
                @DetalleSV decimal(18,2),
                @DetalleImporte decimal(18,2),
                @DetalleEstado varchar(60),
                @ValorUM decimal(18,4),
                @CantidadSaldo decimal(18,2),
                @IniciaStock decimal(18,2),
                @StockFinal decimal(18,2);

            /* -------------------------------------------------
               LEER DETALLE
               ------------------------------------------------- */

            SELECT @IdProducto =
                CONVERT(
                    numeric(20),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 1;

            SELECT @DetalleCantidad =
                CONVERT(
                    decimal(18,2),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 2;

            SELECT @DetalleUm = Valor
            FROM @detalleCampos
            WHERE Pos = 3;

            SELECT @Descripcion = Valor
            FROM @detalleCampos
            WHERE Pos = 4;

            SELECT @DetalleCosto =
                CONVERT(
                    decimal(18,4),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 5;

            SELECT @DetallePrecio =
                CONVERT(
                    decimal(18,2),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 6;

            SELECT @DetallePV =
                CONVERT(
                    decimal(18,2),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 7;

            SELECT @DetalleSV =
                CONVERT(
                    decimal(18,2),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 8;

            SELECT @DetalleImporte =
                CONVERT(
                    decimal(18,2),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 9;

            SELECT @DetalleEstado = Valor
            FROM @detalleCampos
            WHERE Pos = 10;

            SELECT @ValorUM =
                CONVERT(
                    decimal(18,4),
                    ISNULL(NULLIF(Valor, ''), '0')
                )
            FROM @detalleCampos
            WHERE Pos = 11;

            /* -------------------------------------------------
               VALORES POR DEFECTO DEL DETALLE
               ------------------------------------------------- */

            SET @DetalleUm =
                ISNULL(
                    NULLIF(@DetalleUm, ''),
                    'UNIDAD'
                );

            SET @Descripcion =
                ISNULL(@Descripcion, '');

            SET @DetalleEstado =
                ISNULL(
                    NULLIF(@DetalleEstado, ''),
                    'PENDIENTE'
                );

            IF @ValorUM IS NULL
               OR @ValorUM = 0
            BEGIN
                SET @ValorUM = 1;
            END;

            IF @NotaEntrega = 'INMEDIATA'
                SET @CantidadSaldo = 0;
            ELSE
                SET @CantidadSaldo = @DetalleCantidad;

            /* =================================================
               INSERTAR DETALLE DE PEDIDO
               ================================================= */

            INSERT INTO DetallePedido
            (
                NotaId,
                IdProducto,
                DetalleCantidad,
                DetalleUm,
                DetalleDescripcion,
                DetalleCosto,
                DetallePrecio,
                DetalleImporte,
                DetalleEstado,
                CantidadSaldo,
                ValorUM,
                DetallePV,
                DetalleSV
            )
            VALUES
            (
                @NotaId,
                @IdProducto,
                @DetalleCantidad,
                @DetalleUm,
                @Descripcion,
                @DetalleCosto,
                @DetallePrecio,
                @DetalleImporte,
                @DetalleEstado,
                @CantidadSaldo,
                @ValorUM,
                @DetallePV,
                @DetalleSV
            );

            /* =================================================
               INSERTAR DETALLE DEL DOCUMENTO
               ================================================= */

            IF @DocuId <> 0
            BEGIN

                INSERT INTO DetalleDocumento
                (
                    DocuId,
                    IdProducto,
                    DetalleCantidad,
                    DetallPrecio,
                    DetalleImporte,
                    DetalleNotaId,
                    DetalleUM,
                    ValorUM
                )
                VALUES
                (
                    @DocuId,
                    @IdProducto,
                    @DetalleCantidad,
                    @DetallePrecio,
                    @DetalleImporte,
                    @NotaId,
                    @DetalleUm,
                    @ValorUM
                );

            END;

            /* =================================================
               KARDEX Y STOCK
               ================================================= */

            IF @NotaDocu <> 'FACTURA'
            BEGIN

                SELECT TOP 1
                    @IniciaStock = ProductoCantidad
                FROM Producto
                WHERE IdProducto = @IdProducto;

                SET @IniciaStock =
                    ISNULL(@IniciaStock, 0);

                SET @StockFinal =
                    @IniciaStock - @DetalleCantidad;

                INSERT INTO Kardex
                (
                    IdProducto,
                    KardexFecha,
                    KardexMotivo,
                    KardexDocumento,
                    StockInicial,
                    CantidadIngreso,
                    CantidadSalida,
                    PrecioCosto,
                    StockFinal,
                    KadexConcepto,
                    Usuario,
                    CLIENTE,
                    CODIGOCLIENTE,
                    NROTRANSAC,
                    TipoCodigo,
                    Serie,
                    TipoOperacion,
                    Consideracion,
                    DocuId,
                    CompraId,
                    Estado
                )
                VALUES
                (
                    @IdProducto,
                    GETDATE(),
                    'Salida por Venta',
                    @cod,
                    @IniciaStock,
                    0,
                    @DetalleCantidad,
                    @DetalleCosto,
                    @StockFinal,
                    'SALIDA',
                    @NotaUsuario,
                    @Miembro,
                    @CodigoCliente,
                    @NotaTransaccion,
                    @TipoCodigo,
                    @Serie,
                    '01',

                    CASE
                        WHEN @NotaEntrega = 'INMEDIATA'
                            THEN 'S'
                        ELSE 'N'
                    END,

                    CONVERT(varchar(40), @DocuId),
                    '',
                    'E'
                );

                /* ---------------------------------------------
                   DESCONTAR STOCK
                   --------------------------------------------- */

                IF @NotaEntrega = 'INMEDIATA'
                BEGIN

                    UPDATE Producto
                    SET ProductoCantidad =
                        ProductoCantidad - @DetalleCantidad
                    WHERE IdProducto = @IdProducto;

                END;

            END;

            FETCH NEXT FROM detalle_cursor
            INTO @Columna;

        END;

        CLOSE detalle_cursor;
        DEALLOCATE detalle_cursor;

        /* =====================================================
           CONFIRMAR TRANSACCIÓN
           ===================================================== */

        COMMIT TRANSACTION;

        SELECT
            CONVERT(varchar(38), @NotaId)
            + N'¬'
            + @cod;

    END TRY

    /* =========================================================
       CONTROL DE ERRORES
       ========================================================= */

    BEGIN CATCH

        IF CURSOR_STATUS('local', 'detalle_cursor') > -1
        BEGIN
            CLOSE detalle_cursor;
            DEALLOCATE detalle_cursor;
        END;

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE
            @ErrMsg nvarchar(4000),
            @ErrSeverity int,
            @ErrState int;

        SELECT
            @ErrMsg = ERROR_MESSAGE(),
            @ErrSeverity = ERROR_SEVERITY(),
            @ErrState = ERROR_STATE();

        RAISERROR(
            @ErrMsg,
            @ErrSeverity,
            @ErrState
        );

    END CATCH;

END;
GO

IF OBJECT_ID(N'dbo.uspInsertarOBS', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarOBS] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarOBS]  
@ListaOrden varchar(Max)  
as  
begin  
Declare @pos1 int,@pos2 int  
Declare @orden varchar(max),  
        @detalle varchar(max)  
Set @pos1 = CharIndex('[',@ListaOrden,0)  
Set @pos2=Len(@ListaOrden)+1  
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)  
Set @detalle = SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)  
Declare @c1 int,@c2 int,@c3 int  
Declare @RutaOBS varchar(max),@RutaIOC varchar(max),  
        @UsuarioID INT  
Set @c1 = CharIndex('|',@orden,0)  
Set @c2 = CharIndex('|',@orden,@c1+1)  
Set @c3 = Len(@orden)+1  
set @RutaOBS=SUBSTRING(@orden,1,@c1-1)  
Set @RutaIOC=SUBSTRING(@orden,@c1+1,@c2-@c1-1)  
set @UsuarioID=convert(int,SUBSTRING(@orden,@c2+1,@c3-@c2-1))  
Begin Transaction  
update Usuarios  
set   RutaVentaOBS=@RutaOBS,RutaIOC=@RutaIOC  
where UsuarioID=@UsuarioID  
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')   
Open Tabla  
        Declare @Columna varchar(max)  
  declare @FechaTransaccion date,  
        @NotaTransaccion varchar(250),@CodigoMiembro varchar(80),  
        @NombreMiembro varchar(140),@Importe decimal(18,2),@TipoVenta nvarchar(3)  
  Declare @p1 int,@p2 int,@p3 int,@p4 int,@p5 int,@p6 int  
Fetch Next From Tabla INTO @Columna  
While @@FETCH_STATUS = 0  
Begin  
     Set @p1 = CharIndex('|',@Columna,0)  
     Set @p2 = CharIndex('|',@Columna,@p1+1)  
     Set @p3 = CharIndex('|',@Columna,@p2+1)  
     Set @p4 = CharIndex('|',@Columna,@p3+1)  
     Set @p5= CharIndex('|',@Columna,@p4+1)  
  Set @p6=Len(@Columna)+1  
        Set @FechaTransaccion=SUBSTRING(@Columna,1,@p1-1)  
  Set @NombreMiembro=SUBSTRING(@Columna,@p1+1,@p2-(@p1+1))  
  Set @CodigoMiembro=SUBSTRING(@Columna,@p2+1,@p3-(@p2+1))  
  Set @NotaTransaccion=SUBSTRING(@Columna,@p3+1,@p4-(@p3+1))  
  Set @Importe=convert(decimal(18,2),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))  
  Set @TipoVenta=SUBSTRING(@Columna,@p5+1,@p6-(@p5+1))  
  IF EXISTS(select top 1 NotaTransaccion from TABLAOBS t where t.NotaTransaccion=@NotaTransaccion)  
  begin  
  update TABLAOBS  
  set FechaTransaccion=@FechaTransaccion,CodigoMiembro=@CodigoMiembro,NombreMiembro=@NombreMiembro,  
  Importe=@Importe,TipoVenta=@TipoVenta  
  where NotaTransaccion=@NotaTransaccion  
  end  
  else  
  begin  
  if(@Importe>0)  
  begin  
  insert into TABLAOBS values(@FechaTransaccion,@NotaTransaccion,@CodigoMiembro,@NombreMiembro,@Importe,@TipoVenta)  
  end  
  end  
Fetch Next From Tabla INTO @Columna  
End  
 Close Tabla;  
 Deallocate Tabla;  
 Commit Transaction;  
 select  
 isnull((select STUFF ((select '¬'+convert(varchar,T.ID)+'|'+IsNull(convert(varchar,T.FechaTransaccion,103),'')+'|'+  
 T.NotaTransaccion+'|'+T.CodigoMiembro+'|'+T.NombreMiembro+'|'+  
 CONVERT(VarChar(50),cast(T.Importe as money ), 1)+'|'+isnull(n.NotaUsuario,'NO EXISTE')+'|'+isnull(n.NotaEstado,'NO EXISTE')  
 +'|'+isnull(convert(varchar,n.CajaId),'NO EXISTE')  
 from TABLAOBS T  
    left join NotaPedido n  
 on n.NotaTransaccion=t.NotaTransaccion  
 where T.TipoVenta='OBS' and t.FechaTransaccion=@FechaTransaccion  
 order by T.ID asc  
 for xml path('')),1,1,'')),'~')+'['+  
 isnull((select STUFF ((select '¬'+convert(varchar,T.ID)+'|'+IsNull(convert(varchar,T.FechaTransaccion,103),'')+'|'+  
 T.NotaTransaccion+'|'+T.CodigoMiembro+'|'+T.NombreMiembro+'|'+  
 CONVERT(VarChar(50),cast(T.Importe as money ), 1)+'|'+isnull(n.NotaUsuario,'NO EXISTE')+'|'+isnull(n.NotaEstado,'NO EXISTE')  
 +'|'+isnull(convert(varchar,n.CajaId),'NO EXISTE')  
 from TABLAOBS T  
 left join NotaPedido n  
 on n.NotaTransaccion=t.NotaTransaccion  
 where T.TipoVenta='IOC' and t.FechaTransaccion=@FechaTransaccion  
 order by T.ID asc  
 for xml path('')),1,1,'')),'~')+'['+@RutaOBS+'['+@RutaIOC  
End
GO

IF OBJECT_ID(N'dbo.uspInsertarPaginas', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarPaginas] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarPaginas]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,@p3 int,
        @p4 int,@p5 int,@p6 int,
        @p7 int,@p8 int,@p9 int,
        @p10 int
Declare @IdPagina numeric(38),@Concepto nvarchar(40),
        @UsuarioId int,@Encargado varchar(80),
        @HoraInicio datetime,@Tiempo int,
        @HoraFin datetime,@PaginasWeb varchar(max),
        @Observaciones varchar(max),@Autorizado varchar(80)
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 = CharIndex('|',@Data,@p2+1)
Set @p4 = CharIndex('|',@Data,@p3+1)
Set @p5 = CharIndex('|',@Data,@p4+1)
Set @p6 = CharIndex('|',@Data,@p5+1)
Set @p7 = CharIndex('|',@Data,@p6+1)
Set @p8 = CharIndex('|',@Data,@p7+1)
Set @p9 = CharIndex('|',@Data,@p8+1)
Set @p10 = Len(@Data)+1
Set @IdPagina =convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
Set @Concepto=SUBSTRING(@Data,@p1+1,@p2-@p1-1)
Set @UsuarioId=convert(int,SUBSTRING(@Data,@p2+1,@p3-@p2-1))
Set @Encargado=SUBSTRING(@Data,@p3+1,@p4-@p3-1)
Set @HoraInicio=convert(datetime,SUBSTRING(@Data,@p4+1,@p5-@p4-1))
Set @Tiempo=convert(int,SUBSTRING(@Data,@p5+1,@p6-@p5-1))
Set @HoraFin=convert(datetime,SUBSTRING(@Data,@p6+1,@p7-@p6-1))
Set @PaginasWeb=SUBSTRING(@Data,@p7+1,@p8-@p7-1)
Set @Observaciones=SUBSTRING(@Data,@p8+1,@p9-@p8-1)
Set @Autorizado=SUBSTRING(@Data,@p9+1,@p10-@p9-1)
if(@IdPagina=0)
begin
insert into Paginas values(@Concepto,@UsuarioId,@Encargado,
@HoraInicio,@Tiempo,@HoraFin,@PaginasWeb,@Observaciones,@Autorizado,GETDATE())
select 'true'
end
else
begin
update Paginas
set Concepto=@Concepto,UsuarioId=@UsuarioId,Encargado=@Encargado,
HoraInicio=@HoraInicio,Tiempo=@Tiempo,HoraFin=@HoraFin,
PaginasWeb=@PaginasWeb,Observaciones=@Observaciones,Autorizado=@Autorizado
where IdPagina=@IdPagina
select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.uspInsertarPagoVarios', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarPagoVarios] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarPagoVarios]          
@ListaOrden varchar(Max)          
as          
begin          
Declare @pos int          
Declare @orden varchar(max)          
Declare @detalle varchar(max)          
Set @pos = CharIndex('[',@ListaOrden,0)          
Set @orden = SUBSTRING(@ListaOrden,1,@pos-1)          
Set @detalle = SUBSTRING(@ListaOrden,@pos+1,len(@ListaOrden)-@pos)          
Declare @pos1 int,@pos2 int,@pos3 int,@pos4 int,          
        @pos5 int,@pos6 int,@pos7 int,@pos8 int,          
        @pos9 int,@pos10 int,@pos11 int,          
        @pos12 int,@pos13 int          
Declare @PagoId numeric(38),          
  @FechaEmision date,          
  @FormaPago varchar(80),@Entidad varchar(100),          
  @Efectivo decimal(18,2),@Deposito decimal(18,2),          
  @NroOperacion varchar(300),@Usuario varchar(80),          
  @Descripcion varchar(max),@UsuarioId int,          
  @CajaId numeric(38),         
  @ConceptoOBS varchar(80),@PagoTotal decimal(18,2),          
  @TEXTO varchar(max),@Image varchar(max)                 
Set @pos1 = CharIndex('|',@orden,0)          
Set @pos2 = CharIndex('|',@orden,@pos1+1)          
Set @pos3 = CharIndex('|',@orden,@pos2+1)          
Set @pos4 = CharIndex('|',@orden,@pos3+1)          
Set @pos5 = CharIndex('|',@orden,@pos4+1)          
Set @pos6= CharIndex('|',@orden,@pos5+1)          
Set @pos7 = CharIndex('|',@orden,@pos6+1)          
Set @pos8 = CharIndex('|',@orden,@pos7+1)          
Set @pos9= CharIndex('|',@orden,@pos8+1)          
Set @pos10= CharIndex('|',@orden,@pos9+1)          
Set @pos11= CharIndex('|',@orden,@pos10+1)          
Set @pos12= CharIndex('|',@orden,@pos11+1)          
Set @pos13 =Len(@orden)+1          
Set @PagoId=convert(numeric(38),SUBSTRING(@orden,1,@pos1-1))          
Set @FechaEmision=convert(date,SUBSTRING(@orden,@pos1+1,@pos2-@pos1-1))          
Set @FormaPago=SUBSTRING(@orden,@pos2+1,@pos3-@pos2-1)          
Set @Entidad=SUBSTRING(@orden,@pos3+1,@pos4-@pos3-1)          
Set @Efectivo=convert(decimal(18,2),SUBSTRING(@orden,@pos4+1,@pos5-@pos4-1))          
Set @Deposito=convert(decimal(18,2),SUBSTRING(@orden,@pos5+1,@pos6-@pos5-1))          
Set @NroOperacion=SUBSTRING(@orden,@pos6+1,@pos7-@pos6-1)          
Set @Descripcion=SUBSTRING(@orden,@pos7+1,@pos8-@pos7-1)          
Set @Usuario=SUBSTRING(@orden,@pos8+1,@pos9-@pos8-1)          
Set @UsuarioId=convert(int,SUBSTRING(@orden,@pos9+1,@pos10-@pos9-1))          
Set @ConceptoOBS=SUBSTRING(@orden,@pos10+1,@pos11-@pos10-1)          
Set @PagoTotal=convert(decimal(18,2),SUBSTRING(@orden,@pos11+1,@pos12-@pos11-1))          
Set @Image=SUBSTRING(@orden,@pos12+1,@pos13-@pos12-1)          
          
IF EXISTS(select top 1 NroOperacion          
from NotaPedido           
where EntidadBancaria=@Entidad and EntidadBancaria<>'-' and NroOperacion=@NroOperacion and NroOperacion<>'' and NotaEstado<>'ANULADO')          
begin          
select 'OPERACION'          
end          
Else IF EXISTS(select top 1 NroOperacion          
from PagoVarios          
where Entidad=@Entidad and Entidad<>'-' and NroOperacion=@NroOperacion and NroOperacion<>'')          
begin          
select 'OPERACION'          
end          
Else          
begin          
set @CajaId=isnull((select top 1 CajaId from Caja where CajaEstado='ACTIVO'           
and UsuarioId=@UsuarioId         
order by 1 desc),'0')          
if(@CajaId=0)          
begin          
select 'false'          
end          
else          
begin          
          
if(@ConceptoOBS='PUNTOS A ICA' or @ConceptoOBS='PUNTOS A COMAS')          
begin          
set @TEXTO='SE MANDO A PASAR '+@ConceptoOBS+' '+@Descripcion          
end          
else if(@ConceptoOBS='POR PASAR AL OBS')          
begin          
set @TEXTO='CANCELARON PRODUCTOS POR PASAR AL OBS '+@Descripcion          
end          
else if(@ConceptoOBS='VENTA LIBRE')          
begin          
set @TEXTO='VENTA LIBRE. SE VENDIO SIN CODIGO ' +@Descripcion          
end          
else if(@ConceptoOBS='FACTURA MANUAL')          
begin          
set @TEXTO='FACTURA MANUAL. SUMA TOTAL DE PRODUCTOS Y CODIGOS. '+@Descripcion          
end          
else if(@ConceptoOBS='LIQUIDACION DE PAGO')          
begin          
set @TEXTO='CANCELARON DEUDA PENDIENTE PORQUE SE LE PASO SOLO PUNTOS AL OBS '+@Descripcion          
end          
else          
begin          
set @TEXTO='VENTA DEL OBS '+@Descripcion          
end          
if(@Deposito>0)          
begin          
set @TEXTO=@TEXTO+' FORMA DE PAGO: '+@FormaPago+' ENTIDAD BANCARIA: '+@Entidad+' NRO OPERACION: '+@NroOperacion          
end          
          
Begin Transaction          
          
insert into PagoVarios values (@CajaId,@FechaEmision,@FormaPago,@Entidad,          
@Efectivo,@Deposito,@NroOperacion,@Descripcion,@Usuario,GETDATE(),@PagoTotal)          
set @PagoId=(select @@IDENTITY)          
          
if(@ConceptoOBS='VENTA')          
begin          
 if(@Deposito>0)          
 begin    
    insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',          
 @TEXTO,@Deposito,@Deposito,0,@Image,'D','',@PagoId,'',@FormaPago,          
 @Entidad,@NroOperacion)          
 end              
end          
Else          
begin          
if(@ConceptoOBS<>'VENTA')          
begin          
if(@ConceptoOBS<>'FACTURA MANUAL')          
begin          
insert into CajaDetalle values(@CajaId,GETDATE(),0,'INGRESO',          
@TEXTO,@PagoTotal,@PagoTotal,0,@Image,'D','',@PagoId,'',          
@FormaPago,@Entidad,@NroOperacion)          
if(@Deposito>0)          
begin          
 insert into CajaDetalle values(@CajaId,GETDATE(),0,'SALIDA',          
 @TEXTO,@Deposito,@Deposito,0,@Image,'D','',@PagoId,'',@FormaPago,          
 @Entidad,@NroOperacion)          
end                
end          
end          
end          
          
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')           
Open Tabla          
Declare @Columna varchar(max),          
  @DocuId numeric(38),          
  @NotaId numeric(38),          
  @Monto decimal(18,2),          
  @Concepto varchar(80),    
  @EfectivoD decimal(18,2),    
  @DepositoD decimal(18,2)    
    
Declare @p1 int,@p2 int,@p3 int,          
        @p4 int,@p5 int,@p6 int          
Fetch Next From Tabla INTO @Columna          
 While @@FETCH_STATUS = 0          
 Begin          
Set @p1 = CharIndex('|',@Columna,0)          
Set @p2 = CharIndex('|',@Columna,@p1+1)          
Set @p3 = CharIndex('|',@Columna,@p2+1)    
Set @p4 = CharIndex('|',@Columna,@p3+1)          
Set @p5 = CharIndex('|',@Columna,@p4+1)    
Set @p6 =Len(@Columna)+1          
          
set @DocuId=Convert(numeric(20),SUBSTRING(@Columna,1,@p1-1))          
Set @NotaId=convert(numeric(20),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))          
Set @Monto=convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))          
Set @Concepto=SUBSTRING(@Columna,@p3+1,@p4-(@p3+1))    
Set @EfectivoD=convert(decimal(18,2),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))          
Set @DepositoD=convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))     
          
insert into DetallePVarios values(@PagoId,@DocuId,@NotaId,@Monto,@ConceptoOBS,@EfectivoD,@DepositoD)      
      
if(@FormaPago='EFECTIVO')          
 begin            
   update NotaPedido          
   set Efectivo=@Monto,Deposito=0,NotaEstado='CANCELADO',NotaFormaPago=@FormaPago,          
   EntidadBancaria=@Entidad,NroOperacion=@NroOperacion,NotaAcuenta=@Monto,NotaSaldo=0         
   Where NotaId=@NotaId          
          
   update DocumentoVenta          
   set Efectivo=@Monto,Deposito=0,FormaPago=@FormaPago,EntidadBancaria=@Entidad,          
   NroOperacion=@NroOperacion,DocuSaldo=0        
   Where DocuId=@DocuId                
 end          
Else          
 begin             
   if(@FormaPago='DEPOSITO' or @FormaPago='TARJETA' or @FormaPago='YAPE'or @FormaPago='YAPE/DEPOSITO'or @FormaPago='TARJETA/DEPOSITO')       
       Begin    
    
   update NotaPedido          
   set Efectivo=0,Deposito=@Monto,NotaEstado='CANCELADO',NotaFormaPago=@FormaPago,          
   EntidadBancaria=@Entidad,NroOperacion=@NroOperacion,NotaAcuenta=@Monto,NotaSaldo=0   
   Where NotaId=@NotaId          
          
   update DocumentoVenta          
   set Efectivo=0,Deposito=@Monto,FormaPago=@FormaPago,EntidadBancaria=@Entidad,          
   NroOperacion=@NroOperacion,DocuSaldo=0        
   Where DocuId=@DocuId     
    
    End    
    Else    
      begin  
     
  update NotaPedido          
    set Efectivo=@EfectivoD,  
        Deposito=@DepositoD,  
        NotaEstado='CANCELADO',  
        NotaFormaPago=@FormaPago,          
        EntidadBancaria=@Entidad,  
        NroOperacion=@NroOperacion,  
        NotaAcuenta=@EfectivoD + @DepositoD,  
        NotaSaldo=0          
    Where NotaId=@NotaId   
          
  update DocumentoVenta          
  set Efectivo=@EfectivoD,Deposito=@DepositoD,FormaPago=@FormaPago,EntidadBancaria=@Entidad,          
  NroOperacion=@NroOperacion,DocuSaldo=0          
  Where DocuId=@DocuId          
        
   End     
 end          
Fetch Next From Tabla INTO @Columna          
end          
  Close Tabla;          
  Deallocate Tabla;          
  Commit Transaction;          
  select 'true'          
end          
end          
end
GO

IF OBJECT_ID(N'dbo.uspinsertarRB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspinsertarRB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspinsertarRB]
@ListaOrden varchar(Max)
as
begin
Declare @pos int
Declare @orden varchar(max)
Declare @detalle varchar(max)
Set @pos = CharIndex('[',@ListaOrden,0)
Set @orden = SUBSTRING(@ListaOrden,1,@pos-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos+1,len(@ListaOrden)-@pos)
Declare @c1 int,@c2 int,@c3 int,@c4 int,
        @c5 int,@c6 int,@c7 int,@c8 int,
        @c9 int,@c10 int,@c11 int,@c12 int,
        @c13 int,@c14 INT
Declare @CompaniaId int,@ResumenSerie varchar(250),
@Secuencia numeric(38),@FechaReferencia date,
@SubTotal decimal(18,2),@IGV decimal(18,2),
@Total decimal(18,2),@ResumenTiket varchar(250),
@CodigoSunat  varchar(80),@HASHCDR   varchar(max),
@Usuario varchar(80),@Status int,@Estado char(1),
@RangoNumero varchar(80),@ICBPER decimal(18,2)
Set @c1 = CharIndex('|',@orden,0)
Set @c2 = CharIndex('|',@orden,@c1+1)
Set @c3 = CharIndex('|',@orden,@c2+1)
Set @c4 = CharIndex('|',@orden,@c3+1)
Set @c5 = CharIndex('|',@orden,@c4+1)
Set @c6= CharIndex('|',@orden,@c5+1)
Set @c7 = CharIndex('|',@orden,@c6+1)
Set @c8 = CharIndex('|',@orden,@c7+1)
Set @c9 = CharIndex('|',@orden,@c8+1)
Set @c10= CharIndex('|',@orden,@c9+1)
Set @c11= CharIndex('|',@orden,@c10+1)
Set @c12= CharIndex('|',@orden,@c11+1)
Set @c13= CharIndex('|',@orden,@c12+1)
Set @c14= Len(@orden)+1
Set @CompaniaId=convert(int,SUBSTRING(@orden,1,@c1-1))
Set @ResumenSerie=SUBSTRING(@orden,@c1+1,@c2-@c1-1)
Set @Secuencia=convert(int,SUBSTRING(@orden,@c2+1,@c3-@c2-1))
set @FechaReferencia=convert(date,SUBSTRING(@orden,@c3+1,@c4-@c3-1))
set @SubTotal=convert(decimal(18,2),SUBSTRING(@orden,@c4+1,@c5-@c4-1))
set @IGV=convert(decimal(18,2),SUBSTRING(@orden,@c5+1,@c6-@c5-1))
set @Total=convert(decimal(18,2),SUBSTRING(@orden,@c6+1,@c7-@c6-1))
set @ResumenTiket=SUBSTRING(@orden,@c7+1,@c8-@c7-1)
set @CodigoSunat=SUBSTRING(@orden,@c8+1,@c9-@c8-1)
set @HASHCDR=SUBSTRING(@orden,@c9+1,@c10-@c9-1)
set @Usuario=SUBSTRING(@orden,@c10+1,@c11-@c10-1)
set @Status=SUBSTRING(@orden,@c11+1,@c12-@c11-1)
set @RangoNumero=SUBSTRING(@orden,@c12+1,@c13-@c12-1)
set @ICBPER=SUBSTRING(@orden,@c13+1,@c14-@c13-1)
if(@Status=3)
begin
set @SubTotal=0-@SubTotal
set @IGV=0-@IGV
set @ICBPER=0-@ICBPER
set @Total=0-@Total
set @Estado='B'--BAJA
end
else
begin
set @Estado='E'--ENVIADO
end
Begin Transaction
insert into ResumenBoletas values
(@CompaniaId,@ResumenSerie,@Secuencia,@FechaReferencia,Getdate(),
@SubTotal,@IGV,@Total,@ResumenTiket,@CodigoSunat,@HASHCDR,'',@Usuario,
@Estado,@RangoNumero,@ICBPER)
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max),
        @DocuId numeric(38)
Declare @p1 int
Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	Begin
Set @p1 = Len(@Columna)+1
Set @DocuId=Convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))
if(@Status=1)--Declarar 3 Anular
begin
update DocumentoVenta
set DocuHash=@HASHCDR,EstadoSunat='ENVIADO'
where DocuId=@DocuId
end
else
begin
update DocumentoVenta
set DocuHash=@HASHCDR,DocuEstado='BAJA',EstadoSunat='ENVIADO',
DocuSubTotal=0,DocuIgv=0,DocuTotal=0,ICBPER=0
where DocuId=@DocuId
end
Fetch Next From Tabla INTO @Columna
end
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
SELECT
isnull((select STUFF ((select '¬'+convert(varchar,r.ResumenId)+'|'+convert(varchar,r.CompaniaId)+'|'+
(IsNull(convert(varchar,r.FechaReferencia,103),''))+'|'+
(IsNull(convert(varchar,r.FechaEnvio,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,r.FechaEnvio,114),1,8),''))+'|'+
r.ResumenSerie+'-'+convert(varchar,r.Secuencia)+'|'+r.RangoNumero+'|'+
CONVERT(VarChar(50),cast(r.SubTotal as money ), 1)+'|'+
CONVERT(VarChar(50),cast( r.IGV as money ), 1)+'|'+
CONVERT(VarChar(50),cast( r.ICBPER as money ), 1)+'|'+
CONVERT(VarChar(50),cast(r.Total as money ), 1)+'|'+
r.ResumenTiket+'|'+r.CodigoSunat+'|'+r.HASHCDR+'|'+r.MensajeSunat+'|'+
r.Usuario+'|'+c.CompaniaRUC+'|'+
c.CompaniaUserSecun+'|'+c.ComapaniaPWD+'|'+r.Estado+'||'+c.TokenApi+'|'+ClienIdToken
FROM ResumenBoletas r
inner join Compania c
on c.CompaniaId=r.CompaniaId
where Month(r.FechaReferencia)=MONTH(Getdate()) and YEAR(r.FechaReferencia)=year(Getdate())
order by r.CompaniaId,r.FechaEnvio asc
for xml path('')),1,1,'')),'~')
end
-----------------------------------------
GO

IF OBJECT_ID(N'dbo.uspinsertarRBweb', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspinsertarRBweb] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE dbo.uspinsertarRBweb
    @ListaOrden varchar(max)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @pos int
    DECLARE @orden varchar(max)
    DECLARE @detalle varchar(max)

    SET @pos = CHARINDEX('[', @ListaOrden, 0)
    SET @orden = SUBSTRING(@ListaOrden, 1, @pos - 1)
    SET @detalle = SUBSTRING(@ListaOrden, @pos + 1, LEN(@ListaOrden) - @pos)

    DECLARE @c1 int, @c2 int, @c3 int, @c4 int,
            @c5 int, @c6 int, @c7 int, @c8 int,
            @c9 int, @c10 int, @c11 int, @c12 int,
            @c13 int, @c14 int

    DECLARE @CompaniaId int, @ResumenSerie varchar(250),
            @Secuencia numeric(38), @FechaReferencia date,
            @SubTotal decimal(18,2), @IGV decimal(18,2),
            @Total decimal(18,2), @ResumenTiket varchar(250),
            @CodigoSunat varchar(80), @HASHCDR varchar(max),
            @Usuario varchar(80), @Status int, @Estado char(1),
            @RangoNumero varchar(80), @ICBPER decimal(18,2)

    SET @c1 = CHARINDEX('|', @orden, 0)
    SET @c2 = CHARINDEX('|', @orden, @c1 + 1)
    SET @c3 = CHARINDEX('|', @orden, @c2 + 1)
    SET @c4 = CHARINDEX('|', @orden, @c3 + 1)
    SET @c5 = CHARINDEX('|', @orden, @c4 + 1)
    SET @c6 = CHARINDEX('|', @orden, @c5 + 1)
    SET @c7 = CHARINDEX('|', @orden, @c6 + 1)
    SET @c8 = CHARINDEX('|', @orden, @c7 + 1)
    SET @c9 = CHARINDEX('|', @orden, @c8 + 1)
    SET @c10 = CHARINDEX('|', @orden, @c9 + 1)
    SET @c11 = CHARINDEX('|', @orden, @c10 + 1)
    SET @c12 = CHARINDEX('|', @orden, @c11 + 1)
    SET @c13 = CHARINDEX('|', @orden, @c12 + 1)
    SET @c14 = LEN(@orden) + 1

    SET @CompaniaId = CONVERT(int, SUBSTRING(@orden, 1, @c1 - 1))
    SET @ResumenSerie = SUBSTRING(@orden, @c1 + 1, @c2 - @c1 - 1)
    SET @Secuencia = CONVERT(numeric(38), SUBSTRING(@orden, @c2 + 1, @c3 - @c2 - 1))
    SET @FechaReferencia = CONVERT(date, SUBSTRING(@orden, @c3 + 1, @c4 - @c3 - 1))
    SET @SubTotal = CONVERT(decimal(18,2), SUBSTRING(@orden, @c4 + 1, @c5 - @c4 - 1))
    SET @IGV = CONVERT(decimal(18,2), SUBSTRING(@orden, @c5 + 1, @c6 - @c5 - 1))
    SET @Total = CONVERT(decimal(18,2), SUBSTRING(@orden, @c6 + 1, @c7 - @c6 - 1))
    SET @ResumenTiket = SUBSTRING(@orden, @c7 + 1, @c8 - @c7 - 1)
    SET @CodigoSunat = SUBSTRING(@orden, @c8 + 1, @c9 - @c8 - 1)
    SET @HASHCDR = SUBSTRING(@orden, @c9 + 1, @c10 - @c9 - 1)
    SET @Usuario = SUBSTRING(@orden, @c10 + 1, @c11 - @c10 - 1)
    SET @Status = CONVERT(int, SUBSTRING(@orden, @c11 + 1, @c12 - @c11 - 1))
    SET @RangoNumero = SUBSTRING(@orden, @c12 + 1, @c13 - @c12 - 1)
    SET @ICBPER = CONVERT(decimal(18,2), SUBSTRING(@orden, @c13 + 1, @c14 - @c13 - 1))

    IF (@Status = 3)
    BEGIN
        SET @SubTotal = 0 - @SubTotal
        SET @IGV = 0 - @IGV
        SET @ICBPER = 0 - @ICBPER
        SET @Total = 0 - @Total
        SET @Estado = 'B'
    END
    ELSE
    BEGIN
        SET @Estado = 'E'
    END

    BEGIN TRANSACTION

    INSERT INTO dbo.ResumenBoletas
    (
        CompaniaId, ResumenSerie, Secuencia, FechaReferencia, FechaEnvio,
        SubTotal, IGV, Total, ResumenTiket, CodigoSunat, HASHCDR, MensajeSunat,
        Usuario, ESTADO, RangoNumero, ICBPER, CDRBase64
    )
    VALUES
    (
        @CompaniaId, @ResumenSerie, @Secuencia, @FechaReferencia, GETDATE(),
        @SubTotal, @IGV, @Total, @ResumenTiket, @CodigoSunat, @HASHCDR, '',
        @Usuario, @Estado, @RangoNumero, @ICBPER, ''
    )

    DECLARE Tabla CURSOR FOR SELECT * FROM dbo.fnSplitString(@detalle, ';')
    OPEN Tabla

    DECLARE @Columna varchar(max), @DocuId numeric(38)
    DECLARE @p1 int

    FETCH NEXT FROM Tabla INTO @Columna
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @p1 = LEN(@Columna) + 1
        SET @DocuId = CONVERT(numeric(38), SUBSTRING(@Columna, 1, @p1 - 1))

        IF (@Status = 1)
        BEGIN
            UPDATE dbo.DocumentoVenta
               SET DocuHash = @HASHCDR,
                   EstadoSunat = 'ENVIADO',
                   CodigoSunat = NULL,
                   MensajeSunat = NULL
             WHERE DocuId = @DocuId
        END
        ELSE
        BEGIN
            UPDATE dbo.DocumentoVenta
               SET DocuHash = @HASHCDR,
                   DocuEstado = 'BAJA',
                   EstadoSunat = 'ENVIADO',
                   DocuSubTotal = 0,
                   DocuIgv = 0,
                   DocuTotal = 0,
                   ICBPER = 0,
                   CodigoSunat = NULL,
                   MensajeSunat = NULL
             WHERE DocuId = @DocuId
        END

        FETCH NEXT FROM Tabla INTO @Columna
    END

    CLOSE Tabla
    DEALLOCATE Tabla

    COMMIT TRANSACTION

    SELECT ISNULL((
        SELECT STUFF((
            SELECT '¬' + CONVERT(varchar, r.ResumenId) + '|' + CONVERT(varchar, r.CompaniaId) + '|' +
                   ISNULL(CONVERT(varchar, r.FechaReferencia, 103), '') + '|' +
                   ISNULL(CONVERT(varchar, r.FechaEnvio, 103), '') + ' ' + ISNULL(SUBSTRING(CONVERT(varchar, r.FechaEnvio, 114), 1, 8), '') + '|' +
                   r.ResumenSerie + '-' + CONVERT(varchar, r.Secuencia) + '|' + ISNULL(r.RangoNumero, '') + '|' +
                   CONVERT(varchar(50), CAST(r.SubTotal AS money), 1) + '|' +
                   CONVERT(varchar(50), CAST(r.IGV AS money), 1) + '|' +
                   CONVERT(varchar(50), CAST(r.ICBPER AS money), 1) + '|' +
                   CONVERT(varchar(50), CAST(r.Total AS money), 1) + '|' +
                   ISNULL(r.ResumenTiket, '') + '|' + ISNULL(r.CodigoSunat, '') + '|' +
                   ISNULL(r.HASHCDR, '') + '|' + ISNULL(r.MensajeSunat, '') + '|' +
                   ISNULL(r.Usuario, '') + '|' + ISNULL(c.CompaniaRUC, '') + '|' +
                   ISNULL(c.CompaniaUserSecun, '') + '|' + ISNULL(c.ComapaniaPWD, '') + '|' +
                   ISNULL(r.Estado, '') + '||' + ISNULL(c.TokenApi, '') + '|' + ISNULL(c.ClienIdToken, '')
            FROM dbo.ResumenBoletas r
            INNER JOIN dbo.Compania c ON c.CompaniaId = r.CompaniaId
            WHERE MONTH(r.FechaReferencia) = MONTH(GETDATE())
              AND YEAR(r.FechaReferencia) = YEAR(GETDATE())
            ORDER BY r.CompaniaId, r.FechaEnvio ASC
            FOR XML PATH('')
        ), 1, 1, '')
    ), '~')
END
GO

IF OBJECT_ID(N'dbo.uspInsertarXML', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInsertarXML] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInsertarXML]
@ListaOrden varchar(Max)
as
begin
Declare @pos1 int,@pos2 int
Declare @orden varchar(max),
        @detalle varchar(max)
Set @pos1 = CharIndex('[',@ListaOrden,0)
Set @pos2=Len(@ListaOrden)+1
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)
Declare @UsuarioID nvarchar(8)
set @UsuarioID=@orden
Begin Transaction
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
        Declare @Columna varchar(max)
		declare @Codigo varchar(80),
		@IdProducto nvarchar(20),@Cantidad decimal(18,2),
		@precio decimal(18,2),@importe decimal(18,2),
		@Descripcion varchar(200)
		Declare @p1 int,@p2 int
Fetch Next From Tabla INTO @Columna
While @@FETCH_STATUS = 0
Begin
	    Set @p1 = CharIndex('|',@Columna,0)
		Set @p2=Len(@Columna)+1
        Set @Codigo=SUBSTRING(@Columna,1,@p1-1)
		Set @Cantidad=convert(decimal(18,2),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))
		set @IdProducto=isnull((select top 1 IdProducto from Producto 
		where ProductoCodigo=@Codigo),'0')
		set @precio=isnull((select top 1 ProductoCosto from Producto 
		where IdProducto=@IdProducto),'0')
		set @Descripcion=isnull((select top 1 ProductoNombre+' '+ProductoMarca 
		from Producto where IdProducto=@IdProducto),'')
		if(@IdProducto<>'0')
		begin
		set @importe=@Cantidad * @precio
		insert into TemporalCompra values(@UsuarioID,@IdProducto,@Codigo,
        @Descripcion,'UNIDAD',@Cantidad,@Precio,@Importe,
        0,'EMITIDO',1)
		end
Fetch Next From Tabla INTO @Columna
End
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
	select 'true'
End
GO

IF OBJECT_ID(N'dbo.uspinsertaSeries', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspinsertaSeries] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspinsertaSeries]
@detalle varchar(max)
as
Begin Transaction
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
		Declare @Columna varchar(max)
Declare @p1 int,@p2 int,
        @p3 int,@p4 int,@p5 int
Declare @UsuarioID int,@UsuarioSerie varchar(4),
        @EnviaBoleta Bit,@EnviarFactura Bit,
        @Admin bit,@B int,@F int,@A int
	Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	Begin
Set @p1 = CharIndex('|',@Columna,0)
Set @p2 = CharIndex('|',@Columna,@p1+1)
Set @p3 = CharIndex('|',@Columna,@p2+1) 
Set @p4= CharIndex('|',@Columna,@p3+1)
Set @p5= Len(@Columna)+1 
Set @UsuarioID=convert(int,SUBSTRING(@Columna,1,@p1-1))
Set @UsuarioSerie=SUBSTRING(@Columna,@p1+1,@p2-@p1-1)
Set @EnviaBoleta=SUBSTRING(@Columna,@p2+1,@p3-@p2-1)
Set @EnviarFactura=SUBSTRING(@Columna,@p3+1,@p4-@p3-1)
Set @Admin=SUBSTRING(@Columna,@p4+1,@p5-@p4-1)
if(@EnviaBoleta='False')set @B=0
else set @B=1
if(@EnviarFactura='False')set @f=0
else set @f=1
if(@Admin='False')set @A=0
else set @A=1
update Usuarios
set UsuarioSerie=UPPER(@UsuarioSerie),EnviaBoleta=@B,EnviarFactura=@F,
Administrador=@A
where UsuarioID=@UsuarioID
Fetch Next From Tabla INTO @Columna
	end
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
	Select 'true';
GO

IF OBJECT_ID(N'dbo.uspInventarioProducto', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInventarioProducto] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInventarioProducto]  
@Data varchar(max)  
as  
begin  
Declare @fechainicio date,  
        @fechafin date,  
        @IdProducto nvarchar(40)  
Declare @p1 int,@p2 int,@p3 int  
Set @Data = LTRIM(RTrim(@Data))  
Set @p1 = CharIndex('|',@Data,0)  
Set @p2 = CharIndex('|',@Data,@p1+1)  
Set @p3 = Len(@Data)+1  
Set @fechainicio=convert(date,SUBSTRING(@Data,1,@p1-1))  
Set @fechafin=convert(date,SUBSTRING(@Data,@p1+1,@p2-@p1-1))  
Set @IdProducto=SUBSTRING(@Data,@p2+1,@p3-@p2-1)  
Declare @Codigo varchar(80)  
set @Codigo=(select top 1 p.ProductoCodigo from Producto p  
where p.IdProducto=@IdProducto and p.ProductoEstado='BUENO'  
order by p.IdProducto asc)  
set @Codigo=LTRIM(RTrim(Replace(@Codigo,'191','')))  
set @Codigo=LTRIM(RTrim(Replace(@Codigo,'201','')))  
select  
'CodigoAnexo|CodCatUtilizado|TipoExistencia|CodigoExistencia|CodigoOSCE|FechaEmision|TipoCodigo|Serie|Numero|Operacion|Descripcion|UM|MetodoEvaluacion|CantidadING|CostoUnitario|CostoTotal|CantidadSAL|CostoUnita|CostoTotalS|StockFinal|CostoUni|CostoTotalF|Concepto|KardexId¬90|100|90|100|100|110|80|80|100|90|250|100|100|100|100|100|100|100|100|100|100|115|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+  
isnull((select STUFF((select '¬'+'0001'+'|'+'1'+'|'+  
'01'+'|502017|'+--'+substring(s.CodigoSUNAT,1,6)+'  
''+'|'+  
(Convert(char(10),k.KardexFecha,103))+'|'+  
K.TipoCodigo+'|'+k.Serie+'|'+k.KardexDocumento+'|'+K.TipoOperacion+'|'+  
p.ProductoNombre+'|'+'UNIDADES'+'|'+  
'2'+'|'+  
CONVERT(VarChar(50), cast(k.CantidadIngreso as money ), 1)+'|'+  
case when (K.TipoOperacion='02')then   
CONVERT(VarChar(50), cast(k.PrecioCosto as money ), 1)  
else '0.00' end+'|'+  
CONVERT(VarChar(50), cast(k.CantidadIngreso * k.PrecioCosto as money ), 1)+'|'+  
----  
CONVERT(VarChar(50), cast(k.CantidadSalida as money ), 1)+'|'+  
case when (K.TipoOperacion='01')then   
CONVERT(VarChar(50), cast(k.PrecioCosto as money ), 1)  
else '0.00' end+'|'+  
CONVERT(VarChar(50), cast(k.CantidadSalida * k.PrecioCosto as money ), 1)+'|'+  
---------  
isnull(convert(varchar,p.UltimoINV),'')+'|'+  
CONVERT(VarChar(50), cast(k.PrecioCosto as money ), 1)+'|'+  
CONVERT(VarChar(50), cast(k.StockFinal * k.PrecioCosto as money ), 1)+'|'+  
k.KadexConcepto+'|'+convert(varchar,k.KardexId)  
FROM Kardex K  
inner join Producto p  
on p.IdProducto=k.IdProducto  
--inner join Sublinea s  
--on s.IdSubLinea=p.IdSubLinea  
--WHERE k.IdProducto=@IdProducto and  
WHERE (p.ProductoCodigo=@Codigo or  p.ProductoCodigo='191'+@Codigo or p.ProductoCodigo='201'+@Codigo)and    
(Convert(char(10),k.KardexFecha,101) BETWEEN @fechainicio AND @fechafin)   
and (k.KardexMotivo='Salida por Venta' or k.KardexMotivo='Ingreso por Compra')  
--and s.Vista='V'    
and k.Estado='E'  
order by k.KardexFecha ASC  
FOR XML path ('')),1,1,'')),'~')  
end
GO

IF OBJECT_ID(N'dbo.uspInventarioProductoZ', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInventarioProductoZ] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInventarioProductoZ]
@Data varchar(max)
as
begin
Declare @fechainicio date,
        @fechafin date,
        @IdProducto nvarchar(40)
Declare @p1 int,@p2 int,@p3 int
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 = Len(@Data)+1
Set @fechainicio=convert(date,SUBSTRING(@Data,1,@p1-1))
Set @fechafin=convert(date,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
Set @IdProducto=SUBSTRING(@Data,@p2+1,@p3-@p2-1)
Declare @Codigo varchar(80)
set @Codigo=(select top 1 p.ProductoCodigo from Producto p
where p.IdProducto=@IdProducto and p.ProductoEstado='BUENO'
order by p.IdProducto asc)
set @Codigo=LTRIM(RTrim(Replace(@Codigo,'191','')))
set @Codigo=LTRIM(RTrim(Replace(@Codigo,'201','')))
select
'CodigoAnexo|CodCatUtilizado|TipoExistencia|CodigoExistencia|CodigoOSCE|FechaEmision|TipoCodigo|Serie|Numero|Operacion|Descripcion|UM|MetodoEvaluacion|CantidadING|CostoUnitario|CostoTotal|CantidadSAL|CostoUnita|CostoTotalS|StockFinal|CostoUni|CostoTotalF|Concepto|KardexId¬90|100|90|100|100|110|80|80|100|90|250|100|100|100|100|100|100|100|100|100|100|115|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+k.CodigoAnexo+'|'+'1'+'|'+
'01'+'|502017|'+--'+substring(s.CodigoSUNAT,1,6)+'
''+'|'+
(Convert(char(10),k.FechaEmision,103))+'|'+
K.TipoCodigo+'|'+k.Serie+'|'+k.Numero+'|'+K.Operacion+'|'+
k.Descripcion+'|'+'UNIDADES'+'|'+
'2'+'|'+
CONVERT(VarChar(50), cast(k.CantidadING as money ), 1)+'|'+
CONVERT(VarChar(50), cast(k.CostoUnitario as money ), 1)+'|'+
CONVERT(VarChar(50), cast(k.CostoTotal as money ), 1)+'|'+
----
CONVERT(VarChar(50), cast(k.CantidadSAL as money ), 1)+'|'+
CONVERT(VarChar(50), cast(k.CostoUnita as money ), 1)+'|'+
CONVERT(VarChar(50), cast(k.CostoTotalS as money ), 1)+'|'+
---------
CONVERT(VarChar(50), cast(k.StockFinal as money ), 1)+'|'+
CONVERT(VarChar(50), cast(k.CostoUni as money ), 1)+'|'+
CONVERT(VarChar(50), cast(k.CostoTotalF as money ), 1)+'|'+
k.Concepto+'|'+k.ProductoCodigo
FROM InformeKardex k
WHERE (k.ProductoCodigo=@Codigo or  k.ProductoCodigo='191'+@Codigo or k.ProductoCodigo='201'+@Codigo)and  
(Convert(char(10),k.FechaEmision,101) BETWEEN @fechainicio AND @fechafin) 
and (k.KardexMotivo='Salida por Venta' or k.KardexMotivo='Ingreso por Compra')
--and s.Vista='V'  
and k.Estado='E'
order by k.FechaEmision ASC,k.Id asc
FOR XML path ('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspInventarioValorizado', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspInventarioValorizado] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspInventarioValorizado]
@Data varchar(max)
as
begin
Declare @fechainicio date,
        @fechafin date
Declare @p1 int,@p2 int
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = Len(@Data)+1
Set @fechainicio=convert(date,SUBSTRING(@Data,1,@p1-1))
Set @fechafin=convert(date,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
select
'CodigoAnexo|CodCatUtilizado|TipoExistencia|CodigoExistencia|CodigoOSCE|FechaEmision|TipoCodigo|Serie|Numero|Operacion|Descripcion|UM|MetodoEvaluacion|CantidadING|CostoUnitario|CostoTotal|CantidadSAL|CostoUnita|CostoTotalS|StockFinal|CostoUni|CostoTotalF|Concepto¬90|100|90|100|100|110|80|80|100|90|250|100|100|100|100|100|100|100|100|100|100|115|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+'0000'+'|'+'1'+'|'+
'01'+'|'+substring(s.CodigoSUNAT,1,6)+'|'+
''+'|'+
(Convert(char(10),k.KardexFecha,103))+'|'+
K.TipoCodigo+'|'+k.Serie+'|'+k.KardexDocumento+'|'+K.TipoOperacion+'|'+
p.ProductoNombre+'|'+'UNIDADES'+'|'+
'2'+'|'+
CONVERT(VarChar(50), cast(k.CantidadIngreso as money ), 1)+'|'+
case when (K.TipoOperacion='02')then 
CONVERT(VarChar(50), cast(k.PrecioCosto as money ), 1)
else '0.00' end+'|'+
CONVERT(VarChar(50), cast(k.CantidadIngreso * k.PrecioCosto as money ), 1)+'|'+
----
CONVERT(VarChar(50), cast(k.CantidadSalida as money ), 1)+'|'+
case when (K.TipoOperacion='01')then 
CONVERT(VarChar(50), cast(k.PrecioCosto as money ), 1)
else '0.00' end+'|'+
CONVERT(VarChar(50), cast(k.CantidadSalida * k.PrecioCosto as money ), 1)+'|'+
---------
CONVERT(VarChar(50), cast(k.StockFinal as money ), 1)+'|'+
CONVERT(VarChar(50), cast(k.PrecioCosto as money ), 1)+'|'+
CONVERT(VarChar(50), cast(k.StockFinal * k.PrecioCosto as money ), 1)+'|'+
k.KadexConcepto
FROM Kardex K
inner join Producto p
on p.IdProducto=k.IdProducto
inner join Sublinea s
on s.IdSubLinea=p.IdSubLinea
WHERE (Convert(char(10),k.KardexFecha,101) BETWEEN @fechainicio AND @fechafin) 
and (k.KardexMotivo='Salida por Venta'or k.KardexMotivo='Ingreso por Compra')and 
s.Vista='V' and k.TipoCodigo<>'09'
order by k.KardexFecha ASC
FOR XML path ('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspLDPagos', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspLDPagos] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspLDPagos]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int
Declare @fechainicio date,
        @fechafin date
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2= Len(@Data)+1
Set @fechainicio=convert(date,SUBSTRING(@Data,1,@p1-1))
Set @fechafin=convert(date,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
select
'FechaPago|Documento|RazonSocial|Saldo|FormaPago|EntidadBancaria|NroOperacion|Efectivo|Deposito|Acuenta|SaldoActual¬110|120|350|115|100|135|220|115|115|115|115¬'+ 
isnull((select STUFF((select '¬'+
Convert(char(10),l.LiquidacionFecha,103)+'|'+n.NotaSerie+'-'+n.NotaNumero+'|'+
c.ClienteRazon+'|'+CONVERT(VarChar(50), cast(d.SaldoDocu as money ), 1)+'|'+
l.FormaPago+'|'+l.EntidadBancaria+'|'+l.NroOperacion+'|'+
CONVERT(VarChar(50), cast(d.EfectivoSoles as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DepositoSoles as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.AcuentaGeneral as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.SaldoActual as money ), 1)
from DetaLiquidaVenta d
inner join LiquidacionVenta l
on l.LiquidacionId=d.LiquidacionId
inner join NotaPedido n
on n.NotaId=d.NotaId
inner join Cliente c
on c.ClienteId=n.ClienteId
where (Convert(char(10),l.LiquidacionFecha,101) BETWEEN @fechainicio AND @fechafin)
order by l.LiquidacionFecha,l.LiquidacionId asc
FOR XML path ('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspListaAperturaOBS', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaAperturaOBS] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaAperturaOBS]
@fechainicio date,
@fechafin date
as
begin
select 
'ID|Fecha|FechaTexto|BalanceApertura|Recepcion|Factura|CashBill|ReciboCliente|Ajuste|IOC|DSP|BalanceCierre|ValorInventario|Apertura|Stock|Ventas|Cierre|Cuadre|Usuario¬90|120|100|125|120|120|125|125|120|120|120|120|120|115|115|115|115|115|150¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
 isnull((select STUFF((select '¬'+ CONVERT(varchar,a.IdApertura)+'|'+
 convert(varchar,a.Fecha,103)+'|'+a.FechaTexto+'|'+
 CONVERT(VarChar(50), cast(a.BalanceApertura as money ), 1)+'|'+
 CONVERT(VarChar(50), cast(a.Recepcion as money ), 1)+'|'+
 CONVERT(VarChar(50), cast(a.Factura as money ), 1)+'|'+
 CONVERT(VarChar(50), cast(a.CashBill as money ), 1)+'|'+
 CONVERT(VarChar(50), cast(a.ReciboCliente as money ), 1)+'|'+
 CONVERT(VarChar(50), cast(a.Ajuste as money ), 1)+'|'+
 CONVERT(VarChar(50), cast(a.IOC as money ), 1)+'|'+
 CONVERT(VarChar(50), cast(a.DSP as money ), 1)+'|'+
 CONVERT(VarChar(50), cast(a.BalanceCierre as money ), 1)+'|'+
 CONVERT(VarChar(50), cast(a.ValorInventario as money ), 1)+'|'+
 CONVERT(VarChar(50), cast(a.Apertura as money ), 1)+'|'+
 CONVERT(VarChar(50), cast((a.BalanceApertura+a.Recepcion) as money ), 1)+'|'+--stock
 CONVERT(VarChar(50), cast((a.CashBill+a.IOC) as money ), 1)+'|'+--ventas
 CONVERT(VarChar(50), cast((a.BalanceApertura+a.Recepcion)-(a.CashBill+a.IOC)as money ), 1)+'|'+--cierre
 CONVERT(VarChar(50), cast(a.ValorInventario-((a.BalanceApertura+a.Recepcion)-(a.CashBill+a.IOC))as money ), 1)+'|'+--cuadre
 a.Usuario
 from AperturaOBS a
 where (Convert(char(10),a.Fecha,101) BETWEEN @fechainicio AND @fechafin)
 order by a.Fecha asc
 FOR XML PATH('')), 1, 1, '')),'~')
 end
GO

IF OBJECT_ID(N'dbo.uspListaAutorizacion', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaAutorizacion] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaAutorizacion]
as
begin
select
'Id|Usuario|Fecha|HoraInicio|Tiempo|HoraFin|Observaciones|Autorizado¬80|160|115|100|70|140|100|100¬String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+
convert(varchar,a.IdAuto)+'|'+a.Encargado+'|'+
IsNull(convert(varchar,a.HoraInicio,103),'')+'|'+
IsNull(SUBSTRING(convert(varchar,a.HoraInicio,114),1,8),'')+'|'+
convert(varchar,a.Tiempo)+'|'+
(IsNull(convert(varchar,a.HoraFin,103),'')+';  '+IsNull(SUBSTRING(convert(varchar,a.HoraFin,114),1,8),''))+'|'+
a.Observaciones+'|'+a.Autorizado
from AutorizaEdicion a
order by a.IdAuto desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspListaBajas', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaBajas] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaBajas]
@Data varchar(max)
as
begin
Declare @p1 int
Declare @CompaniaId int
Set @Data = LTRIM(RTrim(@Data))
set @CompaniaId=@Data
select
'DocuId|Compania|NotaId|FechaEmision|Documento|Numero|RazonSocial|DNI|SubTotal|IGV|ICBPER|Total|Usuario|Estado¬100|80|100|115|95|130|350|90|115|115|100|115|160|125¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,d.DocuId)+'|'+convert(varchar,d.CompaniaId)+'|'+convert(varchar,d.NotaId)+'|'+
(Convert(char(10),d.DocuEmision,103))+'|'+d.DocuDocumento+'|'+d.docuSerie+'-'+d.DocuNumero+'|'+
c.ClienteRazon+'|'+c.ClienteDni+'|'+
(convert(varchar(50), CAST(d.DocuSubTotal as money), -1))+'|'+
(convert(varchar(50), CAST(d.DocuIgv as money), -1))+'|'+
(convert(varchar(50), CAST(d.ICBPER as money), -1))+'|'+
(convert(varchar(50), CAST(d.DocuTotal as money), -1))+'|'+
d.DocuUsuario+'|'+d.EstadoSunat
from DocumentoVenta d
inner join Cliente c
on c.ClienteId=d.ClienteId
where d.TipoCodigo='03'and((d.CompaniaId=@CompaniaId and DocuEstado='ANULADO' and EstadoSunat='ENVIADO'))
order by d.DocuSerie,d.DocuNumero asc
FOR XML path ('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistaComboCalendario', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaComboCalendario] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaComboCalendario]
as
begin
select
isnull((select STUFF((select '¬'+ a.auditor
from appointment a
group by  a.auditor
order by a.auditor asc 
FOR XML PATH('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ a.tema
from appointment a
group by a.tema
order by a.tema asc
FOR XML PATH('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistaComboHorario', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaComboHorario] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaComboHorario]
as
begin
select
isnull((select STUFF((select '¬'+ h.auditor
from tbl_horario h
group by  h.auditor
order by h.auditor asc 
FOR XML PATH('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+h.curso
from tbl_horario h
group by h.curso
order by h.curso asc
FOR XML PATH('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistaConteo', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaConteo] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaConteo]
@fechainicio date,
@fechafin date
as
begin
select 
'ID|Fecha|Cajeros|TotalOBS|Salidas|Diferencial|Total|Usuario|Registro|Aviso|OBS|UsuarioId|Estado¬80|100|350|110|110|110|110|150|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,c.ConteoId)+'|'+(Convert(char(10),c.FechaConteo,103))+'|'+c.Cajeros+'|'+
CONVERT(VarChar(50), cast(c.TotalOBS as money ), 1)+'|'+
CONVERT(VarChar(50), cast(c.Gastos as money ), 1)+'|'+
CONVERT(VarChar(50), cast(c.Diferencial as money ), 1)+'|'+
CONVERT(VarChar(50), cast(c.Total as money ), 1)+'|'+c.Usuario+'|'+
(IsNull(convert(varchar,c.FechaRegistro,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,c.FechaRegistro,114),1,8),''))+'|'+
c.Aviso+'|'+c.Observaciones+'|'+convert(varchar,c.UsuarioId)+'|'+c.ESTADO
from ConteoMonedas c
where Convert(char(10),c.FechaConteo,101) BETWEEN @fechainicio AND @fechafin
order by c.FechaConteo desc
FOR XML path ('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspListaCreditoGuia', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaCreditoGuia] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaCreditoGuia]    
as    
begin    
select     
'Codigo|Responsable|Saldo¬100|100|100¬String|String|String¬'+    
isnull((select STUFF ((select '¬'+g.CodigoDXN+'|'+g.Destino+'|'+    
CONVERT(VarChar(max), cast(SUM(g.Total) as money ), 1)    
from GuiaInternaSI g   
where (g.Estado='P')    
and g.Destino<>''    
group by g.CodigoDXN,g.Destino    
order by g.Destino asc    
for xml path('')),1,1,'')),'~')    
end
GO

IF OBJECT_ID(N'dbo.uspListaDespachoFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaDespachoFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaDespachoFecha]
@fechainicio date,
@fechafin date
as
begin
select 
'NotaId|Documento|Numero|FechaVenta|Entrega|HoraEntrega|Codigo|RazonSocial|RUC|DNI|Total|Almacenero|Estado|Vendedor¬90|90|90|90|90|90|90|90|90|90|90|90|90|90¬String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+
convert(varchar,n.NotaId)+'|'+n.NotaDocu+'|'+n.NotaSerie+'-'+n.NotaNumero+'|'+
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
n.Entrega+'|'+
(IsNull(convert(varchar,n.Hora,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.Hora,114),1,8),''))+'|'+
c.ClienteCodigo+'|'+
c.ClienteRazon+'|'+c.ClienteRuc+'|'+c.ClienteDni+'|'+
(convert(varchar,CAST(n.NotaPagar as money), -1))+'|'+
n.Almacen+'|'+n.NotaEstado,+'|'+n.NotaUsuario
from NotaPedido n
inner join Cliente c
on c.ClienteId=n.ClienteId
where (Convert(char(10),n.NotaFecha,101) BETWEEN @fechainicio AND @fechafin) and n.NotaConcepto='MERCADERIA'
order by n.NotaId desc
FOR XML path ('')),1,1,'')),'~') 
end
GO

IF OBJECT_ID(N'dbo.usplistaDetaGuiaLiquida', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaDetaGuiaLiquida] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaDetaGuiaLiquida]
@Data varchar(max)
as
begin

Declare @p1 int,@p2 int
Declare @GuiaId varchar(40),
        @NotaId varchar(40)
Set @p1 = CharIndex('|',@Data,0)
Set @p2=Len(@Data)+1
Set @GuiaId= SUBSTRING(@Data,1,@p1-1)
Set @NotaId= SUBSTRING(@Data,@p1+1,@p2-@p1-1)
select 
isnull((select STUFF ((select top 1 '¬'+convert(varchar,n.NotaId)+'|'+n.NotaCondicion+'|'+ 
c.ClienteCodigo+'|'+
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
c.ClienteRazon+'|'+n.Responsable+'|'+
CONVERT(VarChar(max), cast(n.NotaSaldo as money ), 1)
from NotaPedido n
inner join Cliente c
on c.ClienteId=n.ClienteId
where n.NotaId=@NotaId
for xml path('')),1,1,'')),'~')+'['+
'DetalleId|ID|Cantidad|Descripcion|Precio|PV|SV|Importe|SaldoCan|InicialCan¬100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,d.DetalleId)+'|'+
convert(varchar,d.IdProducto)+'|'+
CONVERT(VarChar(max), cast(d.Cantidad as money ), 1)+'|'+
d.Descripcion+'|'+
CONVERT(VarChar(max), cast(d.Precio as money ), 1)+'|'+
CONVERT(VarChar(max), cast(d.PV as money ), 1)+'|'+
CONVERT(VarChar(max), cast(d.SV as money ), 1)+'|'+
CONVERT(VarChar(max), cast(d.Importe as money ), 1)+'|'+
CONVERT(VarChar(max), cast(dbo.CantidadSaldo as money ), 1)+'|'+
CONVERT(VarChar(max), cast(dbo.DetalleCantidad as money ), 1)
from DetalleGuiaLiquida d
inner join DetallePedido dbo
on dbo.DetalleId=d.DetalleId
where d.GuiaId=@GuiaId
order by d.DetaId asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistaDetalleConteo', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaDetalleConteo] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaDetalleConteo]
@ConteoId numeric(38)
as
begin
select 
isnull((select STUFF((select '¬'+CONVERT(varchar,m.MonedaId)+'|'+
case when m.Efectivo=0 then
''
else CONVERT(VarChar,m.Efectivo)end+'|'+
m.Billete +'|'+
CONVERT(VarChar(50), cast(m.Monto as money ), 1)+'|'+
m.Concepto
from Monedas m
where m.ConteoId=@ConteoId
order by m.MonedaId asc
FOR XML path ('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+d.Descripcion+'|'+
case when d.Importe=0 then
''
else CONVERT(VarChar(50),cast(d.Importe as money ), 1)end+'|'+
d.Estado+'|'+CONVERT(varchar,d.DetalleId)+'|'+d.Concepto
from DetalleConteo d
where d.ConteoId=@ConteoId and d.Concepto='I'
order by d.DetalleId asc
FOR XML path ('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+
d.Descripcion+'|'+CONVERT(VarChar(50),cast(d.Importe as money ), 1)+'|'+
d.Estado+'|'+CONVERT(varchar,d.DetalleId)+'|'+d.Concepto
from DetalleConteo d
where d.ConteoId=@ConteoId and d.Concepto='S'
order by d.DetalleId asc
FOR XML path ('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspListaDetalleGuiaINT', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaDetalleGuiaINT] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaDetalleGuiaINT]      
@GuiaId varchar(38)      
as      
begin      
select      
'ID|IdPro|Cantidad|Unidad|Descripcion|PrecioCosto|PrecioVenta|Importe¬100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String¬'+    
isnull((select STUFF ((select '¬'+convert(varchar,d.DetalleId)+'|'+      
convert(varchar,d.IdProducto)+'|'+convert(varchar,d.Cantidad)+'|'+      
d.UnidadM+'|'+d.Descripcion+'|'+convert(varchar,d.Costo)+'|'+      
convert(varchar,d.PrecioVenta)+'|'+   
CONVERT(VarChar(50), cast(d.Importe as money ), 1)   
from DetalleGuiaInterna d      
where d.GuiaId=@GuiaId      
order by d.DetalleId asc      
for xml path('')),1,1,'')),'~')      
end
GO

IF OBJECT_ID(N'dbo.usplistaDetalleturno', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaDetalleturno] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaDetalleturno]
@PersonalId nvarchar(20)
as 
Select
isnull((select STUFF ((select '¬'+ 
convert(char(1),d.Estado)+'|'+
d.Dia+'|'+
convert(varchar,d.TurnoId)
from DetalleTurnos d
where d.PersonalId=@PersonalId
order by d.DetalleId asc
for xml path('')),1,1,'')),'~')
GO

IF OBJECT_ID(N'dbo.uspListaDocumentos', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaDocumentos] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaDocumentos]
@Data varchar(max)
as
begin
Declare @p1 int
Declare @CompaniaId int
declare @fechaReferencia date
Set @Data = LTRIM(RTrim(@Data))
set @CompaniaId=@Data
set @fechaReferencia=(select top 1 DocuEmision from DocumentoVenta
where TipoCodigo='03'and((CompaniaId=@CompaniaId and EstadoSunat='PENDIENTE') and DocuEmision < convert(date,GETDATE()))
group by DocuEmision
order by DocuEmision asc)
select
'DocuId|Compania|NotaId|FechaEmision|Documento|Numero|RazonSocial|DNI|SubTotal|IGV|ICBPER|Total|Usuario|Estado¬100|80|100|115|95|130|350|90|115|115|100|115|160|125¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select top 450'¬'+convert(varchar,d.DocuId)+'|'+convert(varchar,d.CompaniaId)+'|'+convert(varchar,d.NotaId)+'|'+
(Convert(char(10),d.DocuEmision,103))+'|'+d.DocuDocumento+'|'+d.docuSerie+'-'+d.DocuNumero+'|'+
c.ClienteRazon+'|'+c.ClienteDni+'|'+
(convert(varchar(50), CAST(d.DocuSubTotal as money), -1))+'|'+
(convert(varchar(50), CAST(d.DocuIgv as money), -1))+'|'+
(convert(varchar(50), CAST(d.ICBPER as money), -1))+'|'+
(convert(varchar(50), CAST(d.DocuTotal as money), -1))+'|'+
d.DocuUsuario+'|'+d.EstadoSunat
from DocumentoVenta d
inner join Cliente c
on c.ClienteId=d.ClienteId
where d.TipoCodigo='03'and((d.CompaniaId=@CompaniaId and EstadoSunat='PENDIENTE') and d.DocuEmision=@fechaReferencia)
order by d.DocuSerie,d.DocuNumero asc
FOR XML path ('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspListaFacturaPendiente', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaFacturaPendiente] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaFacturaPendiente]
as
begin
select 
'DocuID|NotaId|FechaEmision|Documento|Numero|Cliente|RUC|Descuento|SubTotal|IGV|ICBPER|Total|Usuario|Compania|Movilidad|Adicional|TipoCodigo|Serie|Nro¬90|100|100|100|130|350|100|100|110|110|90|110|150|90|90|90|90|90|90¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,d.DocuId)+'|'+convert(varchar,d.NotaId)+'|'+
Convert(char(10),d.DocuEmision,103)+'|'+d.DocuDocumento+'|'+
d.DocuSerie+'-'+d.DocuNumero+'|'+cl.ClienteRazon+'|'+cl.ClienteRuc+'|'+
CONVERT(VarChar(50), cast(n.NotaDescuento as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DocuSubTotal as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DocuIgv as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.ICBPER as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DocuTotal as money ), 1)+'|'+DocuUsuario+'|'+c.CompaniaRazonSocial+'|'+
CONVERT(VarChar(50), cast(n.NotaMovilidad as money ), 1)+'|'+
CONVERT(VarChar(50), cast(n.NotaAdicional as money ), 1)+'|'+
LTRIM(RTrim(d.TipoCodigo))+'|'+d.DocuSerie+'|'+d.DocuNumero
from DocumentoVenta d
inner join NotaPedido n
on n.NotaId=d.NotaId
inner join Cliente cl
on cl.ClienteId=d.ClienteId
inner join Compania c
on c.CompaniaId=d.CompaniaId
where d.EstadoSunat='PENDIENTE' and (d.TipoCodigo='01' or d.TipoCodigo='07')
order by d.CompaniaId,d.DocuEmision asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspListaGuiaInterna', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaGuiaInterna] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaGuiaInterna]            
@Id nvarchar(1),            
@fechainicio date,              
@fechafin date             
as            
begin            
select            
'Id|NroGuia|FechaRegistro|Motivo|Origen|CodigoDXN|RazonSocial|NroTransaccion|Observacion|Total|Usuario|Estado|ClienteId|Numero|GuiaIdB|GuiaRelacion¬90|90|90|90|90|90|90|90|90|90|90|90|90|90|90|90¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+              
isnull((select STUFF ((select '¬'+convert(varchar,g.GuiaId)+'|'+      
g.Serie+'-'+g.Numero+'|'+            
(IsNull(convert(varchar,g.FechaRegistro,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,g.FechaRegistro,114),1,8),''))+'|'+              
g.Motivo+'|'+g.Origen+'|'+g.CodigoDXN+'|'+g.Destino+'|'+g.NroTransaccion+'|'+g.Observacion+'|'+      
CONVERT(VarChar(50), cast(g.Total as money ), 1)+'|'+      
g.Usuario+'|'+g.Estado+'|'+g.ClienteId+'|'+g.Numero+'|'+g.GuiaIdB+'|'+g.GuiaRealacion            
from GuiaInternaSI g            
where g.Concepto=@Id and (Convert(char(10),g.FechaRegistro,101) BETWEEN @fechainicio AND @fechafin)              
order by g.GuiaId desc            
for xml path('')),1,1,'')),'~')      
end
GO

IF OBJECT_ID(N'dbo.uspListaGuiaLiquidacion', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaGuiaLiquidacion] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaGuiaLiquidacion]
@fechainicio date,
@fechafin date
as
begin
select
'GuiaId|NotaId|GuiaNumero|Documento|FechaEntrega|Codigo|Responsable|Condicion|Efectivo|Deposito|Entidad|NroOperacion|TotalPago|Usuario|Entrega¬100|100|100|100|100|100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+ convert(varchar,g.GuiaId)+'|'+convert(varchar,g.NotaId)+'|'+
g.GuiaNumero+'|'+g.Documento+'|'+
(IsNull(convert(varchar,g.FechaEntrega,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,g.FechaEntrega,114),1,8),''))+'|'+
g.CodigoRes+'|'+g.Responsable+'|'+g.Condicion+'|'+
CONVERT(VarChar(50),cast(g.EfectivoSoles as money ), 1)+'|'+
CONVERT(VarChar(50),cast(g.DepositoSoles as money ), 1)+'|'+
g.EntidadBancaria+'|'+g.NroOperacion+'|'+
CONVERT(VarChar(50), cast(g.TotalPago as money ), 1)+'|'+g.Usuario+'|'+
g.ConceptoEntrega
from GuiaLiquidacion g
where (Convert(char(10),g.FechaEntrega,101) BETWEEN @fechainicio AND @fechafin)
order by g.GuiaId desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistaGuiaSP', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaGuiaSP] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaGuiaSP]
as
begin
select 
'ID|Numero|FechaEmision|Motivo|Transaccion|ClienteId|Codigo|Cliente|Responsable|Descuento|Total|DocuRelacionado|Estado|Usuario|RUC|DNI|fiscal|CajaId|CodigoRes¬100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,g.GuiaId)+'|'+g.GuiaNumero+'|'+
IsNull(convert(varchar,g.Guiafecha,103),'')+'|'+g.GuiaMotivo+'|'+g.NotaTransaccion+'|'+
convert(varchar,g.ClienteId)+'|'+c.ClienteCodigo+'|'+c.ClienteRazon+'|'+g.Responsable+'|'+
(convert(varchar(50), CAST(g.Descuento as money), -1))+'|'+
(convert(varchar(50), CAST(g.Total as money), -1))+'|'+
g.NumeroOrden+'|'+g.GuiaEstado+'|'+g.GuiaUsuario+'|'+c.ClienteRuc+'|'+
c.ClienteDni+'|'+c.ClienteDireccion+'|'+convert(varchar,g.CajaDetaId)+'|'+
CodigoRes
from GuiaRemision g
inner join Cliente c
on c.ClienteId=g.ClienteId
where MONTH(g.GuiaRegistro)=MONTH(GETDATE()) AND YEAR(g.GuiaRegistro)=YEAR(GETDATE())
order by g.GuiaId desc
FOR XML path ('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistaGuiaSPFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaGuiaSPFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaGuiaSPFecha]
@fechainicio date,
@fechafin date
as
begin
select 
'ID|Numero|FechaEmision|Motivo|Transaccion|ClienteId|Codigo|Cliente|Responsable|Descuento|Total|DocuRelacionado|Estado|Usuario|RUC|DNI|fiscal|CajaId|CodigoRes¬100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,g.GuiaId)+'|'+g.GuiaNumero+'|'+
IsNull(convert(varchar,g.Guiafecha,103),'')+'|'+g.GuiaMotivo+'|'+g.NotaTransaccion+'|'+
convert(varchar,g.ClienteId)+'|'+c.ClienteCodigo+'|'+c.ClienteRazon+'|'+g.Responsable+'|'+
(convert(varchar(50), CAST(g.Descuento as money), -1))+'|'+
(convert(varchar(50), CAST(g.Total as money), -1))+'|'+
g.NumeroOrden+'|'+g.GuiaEstado+'|'+g.GuiaUsuario+'|'+c.ClienteRuc+'|'+
c.ClienteDni+'|'+c.ClienteDireccion+'|'+convert(varchar,g.CajaDetaId)+'|'+
CodigoRes
from GuiaRemision g
inner join Cliente c
on c.ClienteId=g.ClienteId
where Convert(char(10),g.Guiafecha,101) BETWEEN @fechainicio AND @fechafin
order by g.Guiafecha asc
FOR XML path ('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistaINV', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaINV] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaINV]  
as  
begin  
select   
'ID|CODIGO|DESCRIPCION|COSTO|STOCK|ULTINV|EXPORTAR¬90|120|300|120|120|100|100¬String|String|String|String|String|String|Boolean¬'+  
isnull((select STUFF((select '¬'+convert(varchar,p.IdProducto)+'|'+p.ProductoCodigo+'|'+  
p.ProductoNombre+'|'+  
(convert(varchar(50), CAST(p.ProductoCosto as money), -1))+'|'+  
(convert(varchar(50), CAST(p.ProductoCantidad as money), -1))+'||'+  
CONVERT(nchar(1),'1')  
from Producto p  
where p.ProductoEstado='BUENO' AND p.ProductoINV='S'  
order by p.ProductoCodigo asc  
FOR XML path ('')),1,1,'')),'~')  
end
GO

IF OBJECT_ID(N'dbo.uspListaPaginas', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaPaginas] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaPaginas]
as
begin
select
'Id|Concepto|Usuario|Fecha|HoraInicio|Tiempo|HoraFin|Paginas|Observaciones|Autorizado¬80|115|160|115|100|70|140|100|100|100¬String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+
convert(varchar,p.IdPagina)+'|'+p.Concepto+'|'+p.Encargado+'|'+
(IsNull(convert(varchar,p.HoraInicio,103),'')+'|'+ IsNull(SUBSTRING(convert(varchar,p.HoraInicio,114),1,8),''))+'|'+
convert(varchar,p.Tiempo)+'|'+
(IsNull(convert(varchar,p.HoraFin,103),'')+';  '+IsNull(SUBSTRING(convert(varchar,p.HoraFin,114),1,8),''))+'|'+
p.PaginasWeb+'|'+p.Observaciones+'|'+p.Autorizado
from Paginas p
order by p.IdPagina desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistaPagosVariosP', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaPagosVariosP] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaPagosVariosP]
@fechainicio date,
@fechafin date
as
begin
select
'PagoId|CajaId|FechaEmision|Descripcion|FormaPago|Entidad|Efectivo|Deposito|NroOperacion|Usuario|Total¬100|100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,p.PagoId)+'|'+
convert(varchar,p.CajaId)+'|'+
convert(varchar,p.FechaEmision,103)+'|'+p.Descripcion+'|'+p.FormaPago+'|'+p.Entidad+'|'+
CONVERT(VarChar(50), cast(p.Efectivo as money ), 1)+'|'+
CONVERT(VarChar(50), cast(p.Deposito as money ), 1)+'|'+
p.NroOperacion+'|'+p.Usuario+'|'+
CONVERT(VarChar(50),cast(p.PagoTotal as money ), 1)
from PagoVarios p
where (Convert(char(10),p.FechaEmision,101) BETWEEN @fechainicio AND @fechafin)
order by p.PagoId desc
FOR XML path ('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistaPersonal', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaPersonal] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaPersonal]
as
begin
select top 1 p.PersonalId as ID,(((SUBSTRING(p.PersonalNombres+' ',1,CHARINDEX(' ',p.PersonalNombres+' ')-1)))+' '+ ((SUBSTRING(p.PersonalApellidos+' ',1,CHARINDEX(' ',p.PersonalApellidos+' ')-1)))) as Nombres,
a.AreaNombre as Area,p.PersonalDNI as DNI,p.PersonalEstado as Estado,
p.PersonalImagen as Imagen,p.HUELLA
from Personal p
inner join Area a
on a.AreaId=p.AreaId
where p.PersonalEstado='ACTIVO'
end
GO

IF OBJECT_ID(N'dbo.uspListaPersonalED', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaPersonalED] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaPersonalED]  
as  
begin  
select  
isnull((select STUFF ((select '¬'+
c.ClienteRazon+'_'+
case when (len(c.ClienteCodigo)>0)then
c.ClienteCodigo
else '-'
end+'_'+
case when (len(c.ClienteDni)>0)then
c.ClienteDni
else '-'
end
from Cliente c
order by c.ClienteId desc
for xml path('')),1,1,'')),'~') --cerrar la cadena
end
GO

IF OBJECT_ID(N'dbo.usplistaPrueba', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaPrueba] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaPrueba]
as
select
'DocuAosciado¬100¬String¬'+
isnull((select STUFF ((select '¬'+
DocuAsociado from DocumentoVenta
where TipoCodigo='07'
order by DocuId asc
for xml path('')),1,1,'')),'~')
GO

IF OBJECT_ID(N'dbo.uspListarApertura', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListarApertura] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListarApertura]
as
select 
'ID|Codigo|Descripcion|xMayor|UNIxCaja|TotalxMayor|UM|Despacho|Vitrina|AlmacenTotal¬90|100|350|100|110|110|100|100|100|110¬String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,p.IdProducto)+'|'+p.ProductoCodigo+'|'+
p.ProductoNombre+' '+p.ProductoMarca+'|'+''+'|'+convert(varchar,p.productoxCaja)+'|'+''+'|'+
p.ProductoUM+'|'+''+'|'+''+'|'+''
from Producto p
where p.ProductoEstado='BUENO'
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')
GO

IF OBJECT_ID(N'dbo.uspListarArchivos', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListarArchivos] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListarArchivos]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int
Declare @fechainicio date,
        @fechafin date
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2= Len(@Data)+1
Set @fechainicio=convert(date,SUBSTRING(@Data,1,@p1-1))
Set @fechafin=convert(date,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
SELECT
'ID|Descripcion|Importe|Encargado|Ruta¬90|525|110|160|90¬String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,d.DetalleId)+'|'+
d.DetalleConcepto+'|'+CONVERT(varChar(max),cast(d.DetalleMonto as money ), 1)+'|'+
c.CajaEncargado+'|'+d.RutaImagen
from CajaDetalle d
inner join Caja c
on c.CajaId=d.CajaId
where (Convert(char(10),d.DetalleFecha,101) BETWEEN @fechainicio AND @fechafin)and(d.NotaId=0 and d.DetalleMovimiento='SALIDA')
order by d.DetalleId desc
FOR XML PATH('')), 1, 1, '')),'~')+'['+
'ID|Descripcion|Importe|Encargado|Ruta¬90|525|110|160|90¬String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,d.DetalleId)+'|'+
d.DetalleConcepto+'|'+CONVERT(varChar(max),cast(d.DetalleMonto as money ), 1)+'|'+
c.CajaEncargado+'|'+d.RutaImagen
from CajaDetalle d
inner join Caja c
on c.CajaId=d.CajaId
where (Convert(char(10),d.DetalleFecha,101) BETWEEN @fechainicio AND @fechafin) and(d.NotaId=0 and d.DetalleMovimiento='INGRESO' and d.Vista='')
order by d.DetalleId desc
FOR XML PATH('')), 1, 1, '')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspListarCajaWEB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListarCajaWEB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE dbo.uspListarCajaWEB AS 
BEGIN  SET NOCOUNT ON; SELECT CONVERT(BIGINT, CajaId) AS CajaId, 
CONVERT(VARCHAR(19), CajaFecha, 126) AS FechaApertura, ISNULL(CajaCierre, '') AS FechaCierre,  ISNULL(MontoIniSOl, 0) AS MontoInicial, ISNULL(CajaEncargado, '') AS Encargado, ISNULL(CajaUsuario, '') AS Usuario, ISNULL(CajaEstado, '') AS Estado,         ISNULL(Observacion, '') AS Observacion 
FROM dbo.Caja
ORDER BY CajaId DESC; END;
GO

IF OBJECT_ID(N'dbo.uspListarDespacho', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListarDespacho] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListarDespacho]
as
begin
select 
'NotaId|Documento|Numero|FechaVenta|Entrega|HoraEntrega|Codigo|RazonSocial|RUC|DNI|Total|Almacenero|Estado|Vendedor¬90|90|90|90|90|90|90|90|90|90|90|90|90|90¬String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+
convert(varchar,n.NotaId)+'|'+n.NotaDocu+'|'+n.NotaSerie+'-'+n.NotaNumero+'|'+
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
n.Entrega+'|'+
(IsNull(convert(varchar,n.Hora,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.Hora,114),1,8),''))+'|'+
c.ClienteCodigo+'|'+
c.ClienteRazon+'|'+c.ClienteRuc+'|'+c.ClienteDni+'|'+
(convert(varchar,CAST(n.NotaPagar as money), -1))+'|'+
n.Almacen+'|'+n.NotaEstado,+'|'+n.NotaUsuario
from NotaPedido n
inner join Cliente c
on c.ClienteId=n.ClienteId
where n.NotaConcepto='MERCADERIA' and 
(Day(n.NotaFecha)=Day(GETDATE()) and month(n.NotaFecha)=month(GETDATE())and year(n.NotaFecha)=year(GETDATE())) 
order by n.NotaId desc
FOR XML path ('')),1,1,'')),'~')+'¬'+
isnull((select STUFF((select '¬'+
convert(varchar,n.NotaId)+'|'+n.NotaDocu+'|'+n.NotaSerie+'-'+n.NotaNumero+'|'+
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
n.Entrega+'|'+
(IsNull(convert(varchar,n.Hora,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.Hora,114),1,8),''))+'|'+
c.ClienteCodigo+'|'+
c.ClienteRazon+'|'+c.ClienteRuc+'|'+c.ClienteDni+'|'+
(convert(varchar,CAST(n.NotaPagar as money), -1))+'|'+
n.Almacen+'|'+n.NotaEstado,+'|'+n.NotaUsuario
from NotaPedido n
inner join Cliente c
on c.ClienteId=n.ClienteId
where n.NotaEstado<>'ANULADO'and(n.NotaConcepto='MERCADERIA' and n.Entrega<>'ENTREGADO'      
and (convert(date,n.NotaFecha) < convert(date,getdate())))        
order by n.NotaId desc  
FOR XML path ('')),1,1,'')),'~')   
end
GO

IF OBJECT_ID(N'dbo.usplistarDetaCaja', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistarDetaCaja] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistarDetaCaja]
@CajaId numeric(38)
as
begin
select
'Id|Fecha|Descripcion|Importe|Ruta|Estado|FormaPago|Entidad|NroOPR¬80|150|420|115|100|80|80|80|80¬String|String|String|String|String|String|String|String|String¬'+
isnull((select stuff((select '¬'+convert(varchar,d.DetalleId)+'|'+
(IsNull(convert(varchar,d.DetalleFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,d.DetalleFecha,114),1,8),''))+'|'+
d.DetalleConcepto+'|'+
CONVERT(VarChar(50), cast(d.DetalleMonto as money ), 1)+'|'+d.RutaImagen+'|'+d.Estado+'|'+
d.FormaPago+'|'+d.EntidadBancaria+'|'+d.NroOperacion
from CajaDetalle d
where d.CajaId=@CajaId and (d.NotaId=0 and d.DetalleMovimiento='INGRESO' and d.Vista='')
order by d.DetalleId desc
for xml path('')),1,1,'')),'~')+'['+
'Id|Fecha|Descripcion|Importe|Ruta|Esatdo|FormaPago|Entidad|NroOPR¬80|150|420|115|100|80|80|80|80¬String|String|String|String|String|String|String|String|String¬'+
isnull((select stuff((select '¬'+convert(varchar,d.DetalleId)+'|'+
(IsNull(convert(varchar,d.DetalleFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,d.DetalleFecha,114),1,8),''))+'|'+
d.DetalleConcepto+'|'+
CONVERT(VarChar(50), cast(d.DetalleMonto as money ), 1)+'|'+d.RutaImagen+'|'+d.Estado+'|'+
d.FormaPago+'|'+d.EntidadBancaria+'|'+d.NroOperacion
from CajaDetalle d
where d.CajaId=@CajaId and (d.NotaId=0 and d.DetalleMovimiento='SALIDA' and d.Vista='')
order by d.DetalleId desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspListaResPorEntregar', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaResPorEntregar] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaResPorEntregar]
as
begin
select 
'Codigo|Responsable|Saldo¬100|100|100¬String|String|String¬'+
isnull((select STUFF ((select '¬'+n.CodigoRes+'|'+n.Responsable+'|'+
CONVERT(VarChar(max), cast(SUM(n.NotaSaldo) as money ), 1)
from NotaPedido n
where (n.NotaEstado<>'ANULADO' and n.NotaEntrega='POR ENTREGAR')
and n.Responsable<>''
group by n.CodigoRes,n.Responsable
order by n.Responsable asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistaResumen', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaResumen] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaResumen]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int
Declare @MES INT,@ANNO INT
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2= Len(@Data)+1
Set @MES=convert(int,SUBSTRING(@Data,1,@p1-1))
Set @ANNO=convert(int,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
SELECT
'Id|Compania|Referencia|FechaEnvio|Serie|SubTotal|IGV|Total|Ticket|CDSunat|HASHCDR|Mensaje|Usuario|RUC|UserSol|ClaveSol¬100|100|100|100|100|100|110|110|110|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+ 
isnull((select STUFF ((select '¬'+convert(varchar,r.ResumenId)+'|'+convert(varchar,r.CompaniaId)+'|'+
(IsNull(convert(varchar,r.FechaReferencia,103),''))+'|'+
(IsNull(convert(varchar,r.FechaEnvio,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,r.FechaEnvio,114),1,8),''))+'|'+
r.ResumenSerie+'-'+convert(varchar,r.Secuencia)+'|'+CONVERT(VarChar(50),cast(r.SubTotal as money ), 1)+'|'+
CONVERT(VarChar(50),cast( r.IGV as money ), 1)+'|'+CONVERT(VarChar(50),cast(r.Total as money ), 1)+'|'+
r.ResumenTiket+'|'+r.CodigoSunat+'|'+r.HASHCDR+'|'+r.MensajeSunat+'|'+r.Usuario+'|'+c.CompaniaRUC+'|'+
c.CompaniaUserSecun+'|'+c.ComapaniaPWD
FROM ResumenBoletas r
inner join Compania c
on c.CompaniaId=r.CompaniaId
where Month(r.FechaReferencia)=@MES and YEAR(r.FechaReferencia)=@ANNO
order by r.CompaniaId,r.FechaEnvio asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistarNC', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistarNC] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistarNC]
as
begin
select
'DocuId|Compania|NroNota|FechaEmision|Documento|Numero|RazonSocial|RUC|Referencia|Nro|Serie|SubTotal|IGV|ICBPER|Total|Usuario|Estado|Direccion|Asociado|CompaniaRazon|CompaniaRUC|Concepto|Gravada|Descuento¬100|80|100|110|115|120|340|105|120|100|100|115|115|90|115|150|130|100|100|100|100|220|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,d.DocuId)+'|'+convert(varchar,d.CompaniaId)+'|'+
convert(varchar,d.NotaId)+'|'+(Convert(char(10),d.DocuEmision,103))+'|'+
d.DocuDocumento+'|'+d.docuSerie+'-'+d.DocuNumero+'|'+c.ClienteRazon+'|'+c.ClienteRuc+'|'+
d.DocuNroGuia+'|'+d.DocuNumero+'|'+d.DocuSerie+'|'+
(convert(varchar(50), CAST(d.DocuSubTotal as money),1))+'|'+
(convert(varchar(50), CAST(d.DocuIgv as money),1))+'|'+
(convert(varchar(50), CAST(d.ICBPER as money),1))+'|'+
(convert(varchar(50), CAST(d.DocuTotal as money),1))+'|'+
d.DocuUsuario+'|'+d.DocuEstado+'|'+c.ClienteDireccion+'|'+d.DocuAsociado+'|'+
co.CompaniaRazonSocial+'|'+co.CompaniaRUC+'|'+d.DocuConcepto+'|'+
(convert(varchar(50), CAST(d.DocuSaldo as money),1))+'|'+
(convert(varchar(50), CAST(d.DocuAdicional as money),1))
from DocumentoVenta d
inner join Cliente c
on c.ClienteId=d.ClienteId
inner join Compania co
on co.CompaniaId=d.CompaniaId
where d.TipoCodigo='07'and (Month(d.DocuEmision)=Month(GETDATE())and year(d.DocuEmision)=YEAR(Getdate()))
order by d.DocuId desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistarNCFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistarNCFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistarNCFecha]
@fechainicio date,
@fechafin date
as
begin
select
'DocuId|Compania|NroNota|FechaEmision|Documento|Numero|RazonSocial|RUC|Referencia|Nro|Serie|SubTotal|IGV|ICBPER|Total|Usuario|Estado|Direccion|Asociado|CompaniaRazon|CompaniaRUC|Concepto|Gravada|Descuento¬100|80|100|110|115|120|340|105|120|100|100|115|115|90|115|150|130|100|100|100|100|220|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,d.DocuId)+'|'+convert(varchar,d.CompaniaId)+'|'+
convert(varchar,d.NotaId)+'|'+(Convert(char(10),d.DocuEmision,103))+'|'+
d.DocuDocumento+'|'+d.docuSerie+'-'+d.DocuNumero+'|'+c.ClienteRazon+'|'+c.ClienteRuc+'|'+
d.DocuNroGuia+'|'+d.DocuNumero+'|'+d.DocuSerie+'|'+
(convert(varchar(50), CAST(d.DocuSubTotal as money),1))+'|'+
(convert(varchar(50), CAST(d.DocuIgv as money),1))+'|'+
(convert(varchar(50), CAST(d.ICBPER as money),1))+'|'+
(convert(varchar(50), CAST(d.DocuTotal as money),1))+'|'+
d.DocuUsuario+'|'+d.DocuEstado+'|'+c.ClienteDireccion+'|'+d.DocuAsociado+'|'+
co.CompaniaRazonSocial+'|'+co.CompaniaRUC+'|'+d.DocuConcepto+'|'+
(convert(varchar(50), CAST(d.DocuSaldo as money),1))+'|'+
(convert(varchar(50), CAST(d.DocuAdicional as money),1))
from DocumentoVenta d
inner join Cliente c
on c.ClienteId=d.ClienteId
inner join Compania co
on co.CompaniaId=d.CompaniaId
where d.TipoCodigo='07' and(Convert(char(10),d.DocuEmision,101) BETWEEN @fechainicio AND @fechafin)
order by d.DocuId desc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistarOBS', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistarOBS] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistarOBS]
@Value varchar(max)
as
begin
Declare @p1 int,@p2 int,
        @p3 int
Declare @UsuarioID int,
        @fechainicio date,
        @fechafin date
Set @p1 = CharIndex('|',@Value,0)
Set @p2 = CharIndex('|',@Value,@p1+1)
Set @p3 =Len(@Value)+1
set @UsuarioID=SUBSTRING(@Value,1,@p1-1)
Set @fechainicio=SUBSTRING(@Value,@p1+1,@p2-@p1-1)
Set @fechafin=SUBSTRING(@Value,@p2+1,@p3-@p2-1)          
Declare @Data varchar(max)
Declare @c1 int,@c2 int       
Declare @RutaOBS varchar(max),
        @RutaIOC varchar(max)
set @Data=(select u.RutaVentaOBS+'|'+u.RutaIOC 
from Usuarios u where u.UsuarioID=@UsuarioID)
Set @c1 = CharIndex('|',@Data,0)
Set @c2 =Len(@Data)+1
set @RutaOBS=SUBSTRING(@Data,1,@c1-1)
Set @RutaIOC=SUBSTRING(@Data,@c1+1,@c2-@c1-1)
select
'ID|Fecha|NroTransaccion|Codigo|Cliente|Importe|Usuario|Estado|CajaId¬80|110|200|110|370|120|170|100|100¬String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,T.ID)+'|'+IsNull(convert(varchar,T.FechaTransaccion,103),'')+'|'+
T.NotaTransaccion+'|'+T.CodigoMiembro+'|'+t.NombreMiembro+'|'+
CONVERT(VarChar(50),cast(T.Importe as money ), 1)+'|'+isnull(n.NotaUsuario,'NO EXISTE')+'|'+isnull(n.NotaEstado,'NO EXISTE')
+'|'+isnull(convert(varchar,n.CajaId),'NO EXISTE')
from TABLAOBS T
left join NotaPedido n
on n.NotaTransaccion=t.NotaTransaccion
--Left join Cliente c
--on c.ClienteCodigo=T.CodigoMiembro
where T.TipoVenta='OBS' and(Convert(char(10),t.FechaTransaccion,101) BETWEEN @fechainicio AND @fechafin)
order by T.ID asc
for xml path('')),1,1,'')),'~')+'['+
'ID|Fecha|NroTransaccion|Codigo|Cliente|Importe|Usuario|Estado|CajaId¬80|110|200|110|370|120|170|100|100¬String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,T.ID)+'|'+IsNull(convert(varchar,T.FechaTransaccion,103),'')+'|'+
T.NotaTransaccion+'|'+T.CodigoMiembro+'|'+t.NombreMiembro+'|'+
CONVERT(VarChar(50),cast(T.Importe as money ), 1)+'|'+isnull(n.NotaUsuario,'NO EXISTE')+'|'+isnull(n.NotaEstado,'NO EXISTE')
+'|'+isnull(convert(varchar,n.CajaId),'NO EXISTE')
from TABLAOBS T
left join NotaPedido n
on n.NotaTransaccion=t.NotaTransaccion
--Left join Cliente c
--on c.ClienteCodigo=T.CodigoMiembro
where T.TipoVenta='IOC' and(Convert(char(10),t.FechaTransaccion,101) BETWEEN @fechainicio AND @fechafin)
order by T.ID asc
for xml path('')),1,1,'')),'~')+'['+@RutaOBS+'['+@RutaIOC
end
GO

IF OBJECT_ID(N'dbo.usplistarPagoVarios', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistarPagoVarios] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE usplistarPagoVarios    
@UsuarioId varchar(20)    
as    
begin    
Declare @CajaId numeric(38)     
set @CajaId=isnull((select top 1 CajaId from Caja where CajaEstado='ACTIVO'     
and UsuarioId=@UsuarioId order by 1 desc),'0')    
select    
'DocuId|NotaId|Documento|Codigo|RazonSocial|Monto|Selec|ConceptoOBS|FP|MontoD|Efectivo|Depsoito¬100|100|100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|Boolean|String|String|Decimal|String|String¬'+    
isnull((select STUFF ((select '¬'+convert(varchar,d.DocuId)+'|'+convert(varchar,d.NotaId)+'|'+    
n.NotaSerie+'-'+n.NotaNumero+'|'+c.ClienteCodigo+'|'+    
c.ClienteRazon+'|'+CONVERT(VarChar(50),cast(n.NotaPagar as money ), 1)+'|0|'+n.ConceptoOBS+'||'+convert(varchar,n.NotaPagar) +'|0.00|0.00'
from DocumentoVenta d    
inner join NotaPedido n    
on n.NotaId=d.NotaId
inner join Cliente c    
on c.ClienteId=n.ClienteId    
where n.NotaCondicion='PAGO/VARIOS' AND n.CajaId=@CajaId and (n.NotaEstado<>'CANCELADO' and n.NotaEstado<>'ANULADO')    
order by n.NotaId desc    
for xml path('')),1,1,'')),'~')    
end
GO

IF OBJECT_ID(N'dbo.uspListarStock', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListarStock] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListarStock]
@AlmacenId numeric(20)
as
begin
select
'IdStock|Id|Codigo|Descripcion|Cantidad|Precio|PV|SV|ValorUM|ValorCritico|Imagen¬100|100|120|380|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,s.IdStock)+'|'+
convert(varchar,s.IdProducto)+'|'+p.ProductoCodigo+'|'+p.ProductoMarca+' '+p.ProductoNombre+'|'+
CONVERT(VarChar(50), cast(s.Cantidad as money ), 1)+'|'+
CONVERT(VarChar(50), cast(p.ProductoCosto as money ), 1)+'|'+
CONVERT(VarChar(50), cast(p.ProductoPV as money ), 1)+'|'+
CONVERT(VarChar(50), cast(p.ProductoSV as money ), 1)+'|'+
'1'+'|'+convert(varchar,p.ValorCritico)+'|'+p.ProductoImagen
from Stock s
inner join Producto p
on p.IdProducto=s.IdProducto
where s.AlmacenId=@AlmacenId and s.Estado='BUENO'
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspListarTemGuiaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListarTemGuiaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListarTemGuiaB]        
@Data varchar(max)      
as        
begin      
Declare @pos1 int        
Declare @pos2 int       
Declare @UsuarioID int,      
        @Concepto nvarchar(1)      
Set @Data = LTRIM(RTrim(@Data))        
Set @pos1 = CharIndex('|',@Data,0)      
Set @pos2 = Len(@Data)+1      
      
Set @UsuarioID=convert(int,SUBSTRING(@Data,1,@pos1-1))        
Set @Concepto=SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1)      
                 
select        
'ID|IdPro|Cantidad|Unidad|Descripcion|PrecioCosto|PrecioVenta|Importe¬100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String¬'+        
isnull((select STUFF ((select '¬'+convert(varchar,t.TemporalId)+'|'+        
convert(varchar,t.IdProducto)+'|'+        
convert(varchar,t.Cantidad)+'|'+t.UnidadM+'|'+p.ProductoNombre+'|'+        
CONVERT(varchar,p.ProductoCosto)+'|'+        
convert(varchar,p.ProductoVenta)+'|'+   
CONVERT(VarChar(50), cast(t.Importe as money ), 1)       
from TemporalGuiaB t        
inner join Producto p         
on p.IdProducto=t.IdProducto        
where t.UsuarioID=@UsuarioID and t.Concepto=@Concepto       
order by t.TemporalId asc        
for xml path('')),1,1,'')),'~')        
end
GO

IF OBJECT_ID(N'dbo.uspListaSeries', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspListaSeries] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspListaSeries]
as
begin
select
'UsuarioId|CompaniaId|Compania|Usuario|SerieB|EnviaBoleta|EnviarFactura|Admin¬100|85|100|180|100|100|100|100¬String|String|String|String|String|Boolean|Boolean|Boolean¬'+
isnull((select STUFF ((select '¬'+ convert(varchar,u.UsuarioID)+'|'+convert(varchar,p.CompaniaId)+'|'+c.CompaniaRazonSocial+'|'+
(((SUBSTRING(p.PersonalNombres+' ',1,CHARINDEX(' ',p.PersonalNombres+' ')-1)))+' '+ ((SUBSTRING(p.PersonalApellidos+' ',1,CHARINDEX(' ',p.PersonalApellidos+' ')-1))))+'|'+
u.UsuarioSerie+'|'+convert(char(1),u.EnviaBoleta)+'|'+convert(char(1),u.EnviarFactura)+'|'+convert(char(1),u.Administrador)
from Usuarios u
inner join Personal p
on p.PersonalId=u.PersonalId
inner join Compania c
on c.CompaniaId=p.CompaniaId
where p.PersonalEstado='ACTIVO'
order by p.PersonalNombres asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usplistaTempoGuiaINT', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usplistaTempoGuiaINT] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usplistaTempoGuiaINT]
@Data varchar(max)
as
begin
Declare @UsuarioID int,
        @Concepto nvarchar(1)
Declare @c1 int,@c2 int
Set @Data = LTRIM(RTrim(@Data))        
Set @c1 = CharIndex('|',@Data,0)
Set @c2= Len(@Data)+1
set @UsuarioID=convert(int,SUBSTRING(@Data,1,@c1-1))
set @Concepto=SUBSTRING(@Data,@c1+1,@c2-@c1-1)        
select
'Id|IdProducto|Codigo|Cantidad|UM|Descripcion¬100|100|100|100|100|100¬String|String|String|String|String|String¬'+
    isnull((select STUFF ((select '¬'+convert(varchar,t.temporalId)+'|'+
    convert(varchar,t.IdProducto)+'|'+p.ProductoCodigo+'|'+convert(varchar,t.cantidad)+'|UNIDAD|'+
    p.ProductoNombre+' '+p.ProductoMarca
	from TemporalGuiaINT t
	inner join Producto p
	on p.IdProducto=t.IdProducto
	where t.UsuarioID=@UsuarioID and t.Concepto=@Concepto
	order by t.temporalId asc
	for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspObtenerCajaActivaWEB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspObtenerCajaActivaWEB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE dbo.uspObtenerCajaActivaWEB 
@UsuarioId int AS 
BEGIN     
SET NOCOUNT ON;  
DECLARE @CajaId numeric(38); 
SELECT TOP (1) @CajaId = CajaId 
FROM dbo.Caja 
WHERE UsuarioId = @UsuarioId AND CajaEstado = 'ACTIVO'      ORDER
BY CajaId DESC;      
IF ISNULL(@CajaId, 0) = 0         
RETURN;      
DECLARE @MontoInicial decimal(18,2), 
        @Ingresos decimal(18,2), 
		@Tarjeta decimal(18,2),
		@Depositos decimal(18,2),
		@Salidas decimal(18,2);      

SELECT @MontoInicial = ISNULL(MontoIniSOl, 0)
       FROM dbo.Caja WHERE CajaId = @CajaId; 
SELECT @Ingresos = ISNULL(SUM(ISNULL(Efectivo, 0)), 0), 
       @Tarjeta = ISNULL(SUM(CASE WHEN UPPER(ISNULL(NotaFormaPago, '')) LIKE '%TARJETA%' THEN ISNULL(Deposito, 0) ELSE 0 END), 0),     
       @Depositos = ISNULL(SUM(CASE WHEN UPPER(ISNULL(NotaFormaPago, '')) NOT LIKE '%TARJETA%' THEN ISNULL(Deposito, 0) ELSE 0 END), 0)
	   FROM dbo.NotaPedido
	   WHERE CajaId = @CajaId AND ISNULL(NotaEstado, '') <> 'ANULADO'; 
SELECT @Salidas = ISNULL(SUM(ISNULL(DetalleEfectivo, DetalleMonto)), 0) 
	   FROM dbo.CajaDetalle      WHERE CajaId = @CajaId AND DetalleMovimiento = 'SALIDA' AND ISNULL(NotaId, 0) = 0; 
SELECT CONVERT(bigint, c.CajaId) AS CajaId,CONVERT(varchar(19), c.CajaFecha, 126) AS FechaApertura, ISNULL(c.MontoIniSOl, 0) AS MontoInicial,         ISNULL(c.CajaEncargado, '') AS Encargado,         ISNULL(c.CajaUsuario, '') AS Usuario,         ISNULL(c.Observacion, '') AS Observacion,         @Ingresos AS VentasEfectivo,         @Tarjeta AS VentasTarjeta,         @Depositos AS VentasDeposito,         @Salidas AS Salidas,         @MontoInicial + @Ingresos - @Salidas AS EfectivoEsperado     FROM dbo.Caja c     WHERE c.CajaId = @CajaId;      SELECT Billete, ISNULL(Efectivo, 0) AS Cantidad       FROM dbo.Monedas      WHERE CajaId = @CajaId      ORDER BY CONVERT(decimal(18,2), Billete) DESC; END;
GO

IF OBJECT_ID(N'dbo.uspObtenerCredencialesSunatweb', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspObtenerCredencialesSunatweb] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE dbo.uspObtenerCredencialesSunatweb
    @CompaniaId int
AS
BEGIN
    SET NOCOUNT ON

    SELECT CompaniaUserSecun AS UsuarioSOL,
           ComapaniaPWD AS ClaveSOL,
           CompaniaPFX AS CertificadoPFX,
           CompaniaClave AS ClaveCertificado,
           ISNULL(TIPO_PROCESO, 3) AS Entorno
      FROM dbo.Compania
     WHERE CompaniaId = @CompaniaId
END
GO

IF OBJECT_ID(N'dbo.uspObtenerPVMensual', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspObtenerPVMensual] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspObtenerPVMensual]    
@Id int,    
@fechainicio date,    
@fechafin date    
as    
Begin    
Declare @mes int, @anno int    
    
set @mes=month(@fechainicio)    
set @anno=YEAR(@fechainicio)    
    
SELECT     
CONVERT(VarChar, cast(isnull(sum(t3.DetallePV),0) as money ), 1)    
FROM NotaPedido t1 (nolock)    
INNER JOIN DocumentoVenta t2
on t2.NotaId=t1.NotaId
inner join DetallePedido t3 (nolock)    
on t3.NotaId=t1.NotaId
WHERE month(t1.NotaFechaPago)= @mes and year(t1.NotaFechaPago)=@anno and (t1.ClienteId=@Id and t1.NotaEstado<>'ANULADO')        
End  

select top 10 * from NotaPedido
order by 1 desc

select top 10 * from DetalleDocumento
order by 1 desc
GO

IF OBJECT_ID(N'dbo.uspPersonalBaja', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspPersonalBaja] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspPersonalBaja]
as
begin
select
'Id|Personal|AREA|FechaBaja|Estado¬90|360|160|100|100¬String|String|String|String|String¬'+
isnull((select stuff((SELECT '¬'+ convert(varchar,P.PersonalId)+'|'+
P.PersonalNombres+' '+P.PersonalApellidos+'|'+a.AreaNombre+'|'+
p.PersonalBajaFecha+'|'+p.PersonalEstado
from Personal P
inner join Area a
on a.AreaId=p.AreaId
where p.PersonalEstado='DESACTIVO'
order by P.PersonalNombres+' '+P.PersonalApellidos asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspReEnviarFactura', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspReEnviarFactura] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspReEnviarFactura]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,
        @p3 int
DECLARE @NotaId numeric(38),@CodigoSunat VARCHAR(80),
        @MensajeSunat varchar(max)
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 =Len(@Data)+1
Set @NotaId=convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
Set @CodigoSunat=convert(numeric(38),SUBSTRING(@Data,@p1+1,@p2-@p1-1))
Set @MensajeSunat=SUBSTRING(@Data,@p2+1,@p3-@p2-1)
update DocumentoVenta
set EstadoSunat='ENVIADO',CodigoSunat=@CodigoSunat,
MensajeSunat=@MensajeSunat
where NotaId=@NotaId and (TipoCodigo='01' and EstadoSunat='PENDIENTE')
update DetallePedido
set DetalleEstado='EMITIDO'
where NotaId=@NotaId
select 'true' 
end
GO

IF OBJECT_ID(N'dbo.uspReEnviarNotaCredito', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspReEnviarNotaCredito] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspReEnviarNotaCredito]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int,
        @p3 int
DECLARE @DocuId numeric(38),@CodigoSunat VARCHAR(80),
        @MensajeSunat varchar(max)
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3 =Len(@Data)+1
Set @DocuId=convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
Set @CodigoSunat=convert(numeric(38),SUBSTRING(@Data,@p1+1,@p2-@p1-1))
Set @MensajeSunat=SUBSTRING(@Data,@p2+1,@p3-@p2-1)
update DocumentoVenta
set EstadoSunat='ENVIADO',CodigoSunat=@CodigoSunat,MensajeSunat=@MensajeSunat
where DocuId=@DocuId and (TipoCodigo='07' and EstadoSunat='PENDIENTE')
select 'true' 
end
GO

IF OBJECT_ID(N'dbo.uspReporteAnual', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspReporteAnual] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspReporteAnual]
@CompaniaId int,
@ANNO int
AS
begin
SELECT
--isnull(b.NroMes,s.NroMes) as NroMes,
--isnull(b.Mes,S.Mes) as Mes, 
isnull(b.NroMes,isnull(S.NroMes,isnull(d.NroMes,isnull(x.NroMes,z.NroMes)))) as NroMes,
isnull(b.Mes,isnull(S.Mes,isnull(d.Mes,isnull(x.Mes,z.Mes)))) as Mes,
convert(varchar(50),cast((ISNULL(b.Monto,0))as money),1) as Ventas,
convert(varchar(50),cast((ISNULL(s.Monto,0)+ISNULL(d.Monto,0))-(ISNULL(x.Monto,0)+ISNULL(z.Monto,0))as money),1) as Compras,
convert(varchar(50),cast((ISNULL(b.Monto,0)-(ISNULL(s.Monto,0)+ISNULL(d.Monto,0))-(ISNULL(x.Monto,0)+ISNULL(z.Monto,0)))as money),1) as Ganancia
FROM(
select month(d.DocuEmision) as NroMes,Datename(MONTH,d.DocuEmision)as Mes,sum(d.DocuTotal)as Monto
from DocumentoVenta d with(nolock)
where (CompaniaId=@CompaniaId and year(d.DocuEmision)=@ANNO)and(D.DocuDocumento<>'PROFORMA V')
group by month(d.DocuEmision),Datename(MONTH,d.DocuEmision)) b
full join
(
    select month(c.CompraComputo) as NroMes,Datename(MONTH,c.CompraComputo)as Mes,SUM(c.CompraTotaL)as Monto
	from Compras c with(nolock)--FACTURAS EN SOLES
	where (c.CompaniaId=@CompaniaId AND year(c.CompraComputo)=@ANNO)and(c.TipoCodigo='01' and c.CompraMoneda='SOLES')
	group by month(c.CompraComputo),Datename(MONTH,c.CompraComputo)
)s on s.NroMes=b.NroMes
full join(
	select month(c.CompraComputo) as NroMes,Datename(MONTH,c.CompraComputo)as Mes,cast(sum(c.CompraTotal*c.CompraTipoSunat)as decimal(18,2)) as Monto
	from Compras c with(nolock)--FACTURAS EN DOLARES
	where (c.CompaniaId=@CompaniaId AND year(c.CompraComputo)=@ANNO) and (c.TipoCodigo='01' and c.CompraMoneda='DOLARES')
	group by month(c.CompraComputo),Datename(MONTH,c.CompraComputo)
)d on d.NroMes=b.NroMes
full join (
	select month(c.CompraComputo) as NroMes,Datename(MONTH,c.CompraComputo)as Mes,sum(c.CompraTotal) as Monto
	from Compras c with(nolock)--nota de credito en soles
	where (c.CompaniaId=@CompaniaId AND year(c.CompraComputo)=@ANNO) AND(c.TipoCodigo='07' and c.CompraMoneda='SOLES')
	group by month(c.CompraComputo),Datename(MONTH,c.CompraComputo)
)x on x.NroMes=b.NroMes
full join(
	select month(c.CompraComputo) as NroMes,Datename(MONTH,c.CompraComputo)as Mes,cast(sum(c.CompraTotal*c.CompraTipoSunat)as decimal(18,2)) as Monto
	from Compras c with(nolock)--credito EN DOLARES
	where c.CompaniaId=@CompaniaId AND year(c.CompraComputo)=@ANNO and (c.TipoCodigo='07' and c.CompraMoneda='DOLARES')
	group by month(c.CompraComputo),Datename(MONTH,c.CompraComputo)
)z on z.NroMes=b.NroMes
order by 1 asc
end
GO

IF OBJECT_ID(N'dbo.uspResumenDetalle', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspResumenDetalle] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspResumenDetalle] 
@fechainicio date,@fechafin date
as
begin
select 
'Codigo|Descripcion|Cantidad|UM|PVTotal|SVTotal|Importe¬100|400|110|100|115|115|115¬String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+p.ProductoCodigo+'|'+
d.DetalleDescripcion+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetalleCantidad) as money ), 1)+'|'+d.DetalleUm+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetallePV) as money ), 1)+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetalleSV) as money ), 1)+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetalleImporte) as money ), 1)
from NotaPedido n
inner join DetallePedido d
on d.NotaId=n.NotaId
inner join Producto p
on p.IdProducto=d.IdProducto
where n.NotaEstado='CANCELADO' and (Convert(char(10),n.NotaFecha,101) BETWEEN @fechainicio AND @fechafin)
group by p.ProductoCodigo,d.DetalleDescripcion,d.DetalleUm
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspResumenDetalleB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspResumenDetalleB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspResumenDetalleB] 
@fechainicio date,@fechafin date
as
begin
select 
'Codigo|Descripcion|Cantidad|UM|PVTotal|SVTotal|Importe¬100|400|110|100|115|115|115¬String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+p.ProductoCodigo+'|'+
d.DetalleDescripcion+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetalleCantidad) as money ), 1)+'|'+d.DetalleUm+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetallePV) as money ), 1)+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetalleSV) as money ), 1)+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetalleImporte) as money ), 1)
from NotaPedido n
inner join DetallePedido d
on d.NotaId=n.NotaId
inner join Producto p
on p.IdProducto=d.IdProducto
where n.NotaDocu='PROFORMA V' and n.NotaEstado='CANCELADO' and (Convert(char(10),n.NotaFecha,101) BETWEEN @fechainicio AND @fechafin)
group by p.ProductoCodigo,d.DetalleDescripcion,d.DetalleUm
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspResumenFecha', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspResumenFecha] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspResumenFecha]
@Data varchar(max)
as
begin
Declare @p1 int,@p2 int
Declare @fechainicio date,
        @fechafin date
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2= Len(@Data)+1
Set @fechainicio=convert(date,SUBSTRING(@Data,1,@p1-1))
Set @fechafin=convert(date,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
SELECT
'Id|Compania|FechaEmision|FechaEnvio|Serie|RangoNumeros|SubTotal|IGV|ICBPER|Total|Ticket|CDSunat|HASHCDR|Mensaje|Usuario|RUC|UserSol|ClaveSol|ESTADO|Intentos|TokenApi|IdToken¬100|100|100|100|100|100|110|110|110|100|100|100|100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+ 
isnull((select STUFF ((select '¬'+convert(varchar,r.ResumenId)+'|'+convert(varchar,r.CompaniaId)+'|'+
(IsNull(convert(varchar,r.FechaReferencia,103),''))+'|'+
(IsNull(convert(varchar,r.FechaEnvio,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,r.FechaEnvio,114),1,8),''))+'|'+
r.ResumenSerie+'-'+convert(varchar,r.Secuencia)+'|'+r.RangoNumero+'|'+
CONVERT(VarChar(50),cast(r.SubTotal as money ), 1)+'|'+
CONVERT(VarChar(50),cast( r.IGV as money ), 1)+'|'+
CONVERT(VarChar(50),cast( r.ICBPER as money ), 1)+'|'+
CONVERT(VarChar(50),cast(r.Total as money ), 1)+'|'+
r.ResumenTiket+'|'+r.CodigoSunat+'|'+r.HASHCDR+'|'+r.MensajeSunat+'|'+
r.Usuario+'|'+c.CompaniaRUC+'|'+
c.CompaniaUserSecun+'|'+c.ComapaniaPWD+'|'+r.Estado+'||'+c.TokenApi+'|'+ClienIdToken
FROM ResumenBoletas r
inner join Compania c
on c.CompaniaId=r.CompaniaId
where (Convert(char(10),r.FechaReferencia,101) BETWEEN @fechainicio AND @fechafin)
order by r.CompaniaId,r.FechaEnvio asc
for xml path('')),1,1,'')),'~')
end
----------------------------
GO

IF OBJECT_ID(N'dbo.uspResumenFechaweb', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspResumenFechaweb] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE dbo.uspResumenFechaweb
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @p1 int, @p2 int
    DECLARE @fechainicio date, @fechafin date
    DECLARE @sep char(1)
    SET @sep = CHAR(172)

    SET @Data = LTRIM(RTRIM(@Data))
    SET @p1 = CHARINDEX('|', @Data, 0)
    SET @p2 = LEN(@Data) + 1

    SET @fechainicio = CONVERT(date, SUBSTRING(@Data, 1, @p1 - 1), 120)
    SET @fechafin = CONVERT(date, SUBSTRING(@Data, @p1 + 1, @p2 - @p1 - 1), 120)

    SELECT
        'Id|Compania|FechaEmision|FechaEnvio|Serie|RangoNumeros|SubTotal|IGV|ICBPER|Total|Ticket|CDSunat|HASHCDR|Mensaje|Usuario|RUC|UserSol|ClaveSol|ESTADO|Intentos|TokenApi|IdToken|TieneCDR|CDRBase64'
        + @sep +
        '100|100|100|100|100|100|110|110|110|100|100|100|100|100|100|100|100|100|100|100|100|100|80|300'
        + @sep +
        'String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String'
        + @sep +
        ISNULL((
            SELECT STUFF((
                SELECT @sep + CONVERT(varchar, r.ResumenId) + '|' + CONVERT(varchar, r.CompaniaId) + '|' +
                       ISNULL(CONVERT(varchar, r.FechaReferencia, 103), '') + '|' +
                       ISNULL(CONVERT(varchar, r.FechaEnvio, 103), '') + ' ' + ISNULL(SUBSTRING(CONVERT(varchar, r.FechaEnvio, 114), 1, 8), '') + '|' +
                       ISNULL(r.ResumenSerie, '') + '-' + CONVERT(varchar, r.Secuencia) + '|' +
                       ISNULL(r.RangoNumero, '') + '|' +
                       CONVERT(varchar(50), CAST(r.SubTotal AS money), 1) + '|' +
                       CONVERT(varchar(50), CAST(r.IGV AS money), 1) + '|' +
                       CONVERT(varchar(50), CAST(r.ICBPER AS money), 1) + '|' +
                       CONVERT(varchar(50), CAST(r.Total AS money), 1) + '|' +
                       ISNULL(r.ResumenTiket, '') + '|' +
                       REPLACE(ISNULL(r.CodigoSunat, ''), '|', ' ') + '|' +
                       REPLACE(ISNULL(r.HASHCDR, ''), '|', ' ') + '|' +
                       REPLACE(ISNULL(r.MensajeSunat, ''), '|', ' ') + '|' +
                       REPLACE(ISNULL(r.Usuario, ''), '|', ' ') + '|' +
                       ISNULL(c.CompaniaRUC, '') + '|' +
                       ISNULL(c.CompaniaUserSecun, '') + '|' +
                       ISNULL(c.ComapaniaPWD, '') + '|' +
                       ISNULL(r.Estado, '') + '||' +
                       ISNULL(c.TokenApi, '') + '|' +
                       ISNULL(c.ClienIdToken, '') + '|' +
                       CASE WHEN ISNULL(r.CDRBase64, '') = '' THEN 'NO' ELSE 'SI' END + '|' +
                       REPLACE(ISNULL(r.CDRBase64, ''), '|', ' ')
                FROM dbo.ResumenBoletas r
                INNER JOIN dbo.Compania c ON c.CompaniaId = r.CompaniaId
                WHERE r.FechaReferencia BETWEEN @fechainicio AND @fechafin
                ORDER BY r.CompaniaId, r.FechaEnvio ASC
                FOR XML PATH('')
            ), 1, 1, '')
        ), '~')
END
GO

IF OBJECT_ID(N'dbo.uspResumenPVS', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspResumenPVS] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspResumenPVS]  
@Id numeric(20),  
@fechainicio date,  
@fechafin date  
as  
Begin  
select  
'NotaId|Fecha|NroTransaccion|Codigo|Nombre|PV|SV|Importe¬90|100|200|100|350|100|100|100¬String|String|String|String|String|String|String|String|¬'+  
isnull((select STUFF ((select '¬'+ convert(varchar,n.NotaId)+'|'+  
convert(varchar,n.NotaFechaPago,103)+'|'+  
n.NotaTransaccion+'|'+  
c.ClienteCodigo+'|'+  
c.ClienteRazon+'|'+  
CONVERT(VarChar, cast(isnull(sum(d.DetallePV),0) as money ), 1)+'|'+  
CONVERT(VarChar, cast(isnull(sum(d.DetalleSV),0) as money ), 1)+'|'+  
CONVERT(VarChar, cast(n.notapagar as money ), 1)  
from NotaPedido n (nolock)    
inner join Cliente c (nolock)    
on c.ClienteId=n.ClienteId  
inner join DetallePedido d (nolock)    
on n.NotaId=d.NotaId  
where n.NotaFechaPago between @fechainicio and @fechafin and (n.ClienteId=@Id and n.NotaEstado='CANCELADO')    
group by n.NotaId,  
n.NotaFechaPago,  
n.NotaTransaccion,  
c.ClienteCodigo,  
c.ClienteRazon,  
n.NotaPagar  
order by n.NotaId desc  
for xml path('')),1,1,'')),'~')  
End
GO

IF OBJECT_ID(N'dbo.uspRetornaBoletaPorTicket', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspRetornaBoletaPorTicket] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspRetornaBoletaPorTicket]
@ResumenId varchar(80)
as
begin
declare @FechaEmision date
declare @Dia int,@Mes int,@ANNO int
set @FechaEmision=(select top 1 r.FechaReferencia from ResumenBoletas r where r.ResumenId=@ResumenId)
set @Dia=DAY(@FechaEmision)
set @Mes=MONTH(@FechaEmision)
set @ANNO=YEAR(@FechaEmision)
update ResumenBoletas
set MensajeSunat='NO SE GENERO EL TICKET DE RESPUESTA DE SUNAT'
where ResumenId=@ResumenId
update DocumentoVenta
set EstadoSunat='PENDIENTE'
WHERE (DAY(DocuEmision)=@Dia AND MONTH(DocuEmision)=@Mes and YEAR(DocuEmision)=@ANNO) and TipoCodigo='03'
select 'true'
end
GO

IF OBJECT_ID(N'dbo.uspRetornarBoletas', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspRetornarBoletas] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspRetornarBoletas]
@ResumenId varchar(80)
as
begin
declare @FechaEmision date
declare @Dia int,@Mes int,@ANNO int
set @FechaEmision=(select top 1 r.FechaReferencia from ResumenBoletas r where r.ResumenId=@ResumenId)
set @Dia=DAY(@FechaEmision)
set @Mes=MONTH(@FechaEmision)
set @ANNO=YEAR(@FechaEmision)
update DocumentoVenta
set EstadoSunat='PENDIENTE'
WHERE (DAY(DocuEmision)=@Dia AND MONTH(DocuEmision)=@Mes and YEAR(DocuEmision)=@ANNO) and TipoCodigo='03'
select 'true'
end
GO

IF OBJECT_ID(N'dbo.uspStockB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspStockB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspStockB]
as
begin
select
'Id|Codigo|Descripcion|Cantidad|Precio|Inventario|PV|SV|ValorUM|ValorCritico¬100|120|380|100|100|120|100|100|100|100¬String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,p.IdProducto)+'|'+
p.ProductoCodigo+'|'+p.ProductoMarca+' '+p.ProductoNombre+'|'+''+'|'+
CONVERT(VarChar(50), cast(p.ProductoCosto as money ), 1)+'|'+
CONVERT(VarChar(50), cast(p.ProductoCantidad as money ), 1)+'|'+
CONVERT(VarChar(50), cast(p.ProductoPV as money ), 1)+'|'+
CONVERT(VarChar(50), cast(p.ProductoSV as money ), 1)+'|'+
'1'+'|'+convert(varchar,p.ValorCritico)+'|'+p.ProductoImagen
from Producto p
where p.AlmacenId='1'
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspStockInsertaCsv', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspStockInsertaCsv] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspStockInsertaCsv]
@detalle varchar(max)
as
begin
Begin Transaction
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')	
Open Tabla
Declare @Columna varchar(max)
Declare @p1 int,
        @p2 int,
        @p3 int,
        @p4 int
Declare @AlmacenId  numeric(20),
        @IdProducto  numeric(20),
        @Cantidad  decimal(18,2),
        @ValorUM  decimal(18,4)
Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	begin
Set @Columna= LTRIM(RTrim(@Columna))
Set @p1 = CharIndex('|',@Columna,0)
Set @p2=CharIndex('|',@Columna,@p1+1)
Set @p3=CharIndex('|',@Columna,@p2+1)
Set @p4 = Len(@Columna)+1
Set @AlmacenId=convert(numeric(20),SUBSTRING(@Columna,1,@p1-1))
Set @IdProducto=convert(numeric(20),SUBSTRING(@Columna,@p1+1,@p2-@p1-1))
Set @Cantidad=convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-@p2-1))
Set @ValorUM=convert(decimal(18,4),SUBSTRING(@Columna,@p3+1,@p4-@p3-1))
insert into Stock values(@AlmacenId,@IdProducto,@Cantidad,@ValorUM,'BUENO')
Fetch Next From Tabla INTO @Columna
end
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
select 'true'
end
GO

IF OBJECT_ID(N'dbo.uspTemMonedas', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTemMonedas] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTemMonedas]
@Data varchar(max)
as
begin
Declare @UsuarioID int,@CajaId numeric(38)
Declare @Count int
Declare @p1 int,@p2 int
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = Len(@Data)+1
set @UsuarioID=convert(int,SUBSTRING(@Data,1,@p1-1))
Set @CajaId=convert(numeric(38),SUBSTRING(@Data,@p1+1,@p2-@p1-1))
set @Count=(select count(*) from TemporalMoneda t
where t.UsuarioID=@UsuarioID and CajaId=@CajaId)
if(@Count=0)
begin
insert into TemporalMoneda values(1,@UsuarioID,null,0,@CajaId)
insert into TemporalMoneda values(2,@UsuarioID,null,0,@CajaId)
insert into TemporalMoneda values(3,@UsuarioID,null,0,@CajaId)
insert into TemporalMoneda values(4,@UsuarioID,null,0,@CajaId)
insert into TemporalMoneda values(5,@UsuarioID,null,0,@CajaId)
insert into TemporalMoneda values(6,@UsuarioID,null,0,@CajaId)
insert into TemporalMoneda values(7,@UsuarioID,null,0,@CajaId)
insert into TemporalMoneda values(8,@UsuarioID,null,0,@CajaId)
insert into TemporalMoneda values(9,@UsuarioID,null,0,@CajaId)
insert into TemporalMoneda values(10,@UsuarioID,null,0,@CajaId)
insert into TemporalMoneda values(11,@UsuarioID,null,0,@CajaId)
end 
select 
isnull((select STUFF((select '¬'+convert(varchar,t.TemporalId)+'|'+
case when t.Efectivo<=0 then
''else isnull(convert(varchar,t.Efectivo),'')end+'|'+
isnull(convert(varchar,MonedaValor),'')+'|'+
isnull(CONVERT(VarChar(50), cast(t.Monto as money ), 1),'0.00')+'|'+m.MonedaTipo
from Moneda m
LEFT OUTER JOIN TemporalMoneda t
on t.MonedaId=m.MonedaId
where t.UsuarioID=@UsuarioID and CajaId=@CajaId
FOR XML PATH('')), 1, 1, '')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspTemporalVentaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTemporalVentaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTemporalVentaB]
@Data varchar(max)
as
begin
Begin Transaction
Declare Tabla Cursor For Select * From fnSplitString(@Data,';')	
Open Tabla
Declare @Columna varchar(max)
Declare @p1 int,@p2 int,@p3 int,
        @p4 int,@p5 int,@p6 int,
        @p7 int,@p8 int
Declare @temporalId  numeric(38)
Declare @UsuarioID  int
Declare @IdProducto  numeric(20)
Declare @cantidad  decimal(18,2)
Declare @precioventa  decimal(18,2)
Declare @importe  decimal(18,2)
Declare @ValorUM  decimal(18,4)
Declare @UniMedida  varchar(40)
Fetch Next From Tabla INTO @Columna
	While @@FETCH_STATUS = 0
	Begin
Set @p1 = CharIndex('|',@Columna,0)
Set @p2=CharIndex('|',@Columna,@p1+1)
Set @p3=CharIndex('|',@Columna,@p2+1)
Set @p4=CharIndex('|',@Columna,@p3+1)
Set @p5=CharIndex('|',@Columna,@p4+1)
Set @p6=CharIndex('|',@Columna,@p5+1)
Set @p7=CharIndex('|',@Columna,@p6+1)
Set @p8= Len(@Columna)+1
Set @temporalId=convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))
Set @UsuarioID=convert(int,SUBSTRING(@Columna,@p1+1,@p2-@p1-1))
Set @IdProducto=convert(numeric(20),SUBSTRING(@Columna,@p2+1,@p3-@p2-1))
Set @cantidad=convert(decimal(18,2),SUBSTRING(@Columna,@p3+1,@p4-@p3-1))
Set @precioventa=convert(decimal(18,2),SUBSTRING(@Columna,@p4+1,@p5-@p4-1))
Set @importe=convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-@p5-1))
Set @ValorUM=convert(decimal(18,4),SUBSTRING(@Columna,@p6+1,@p7-@p6-1))
Set @UniMedida=SUBSTRING(@Columna,@p7+1,@p8-@p7-1)
IF NOT EXISTS(select t.IdProducto from TemporalVenta t where t.IdProducto=@IdProducto and t.UsuarioID=@UsuarioID)
begin
insert into TemporalVenta values(@UsuarioID,@IdProducto,@cantidad,@precioventa,
@importe,@ValorUM,@UniMedida)
end
else
begin
update TemporalVenta
set cantidad=cantidad+@cantidad,importe=importe+@importe
where IdProducto=@IdProducto and UsuarioID=@UsuarioID
end
Fetch Next From Tabla INTO @Columna
end
	Close Tabla;
	Deallocate Tabla;
	Commit Transaction;
select
    isnull((select STUFF ((select '¬'+convert(varchar,t.temporalId)+'|'+CONVERT(varchar,t.UsuarioId)+'|'+convert(varchar,t.IdProducto)+'|'+
    p.ProductoCodigo+'|'+convert(varchar,t.cantidad)+'|'+t.UniMedida+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
	convert(varchar,cast((p.ProductoCosto* t.ValorUM) as decimal(18,2)))+'|'+
	convert(varchar,t.precioventa)+'|'+
    CONVERT(VarChar(50), cast((t.cantidad*p.ProductoPV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast((t.cantidad*p.ProductoSV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(t.importe as money ), 1)+'|'+
	p.ProductoImagen+'|'+
	convert(varchar,t.ValorUM)+'|'+
	convert(varchar,convert(decimal(18,2),t.precioventa/1.18))+'|'+
	convert(varchar,(t.importe - convert(decimal(18,2),t.importe/1.18)))+'|'+
	convert(varchar,convert(decimal(18,2),t.importe/1.18))+'|'+
	convert(varchar,p.ProductoPV)+'|'+convert(varchar,p.ProductoSV)
	from TemporalVenta t
	inner join Producto p
	on p.IdProducto=t.IdProducto
	where t.UsuarioID=@UsuarioID 
	order by t.temporalId asc
	for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspTemporalVentaInsertaCsv', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTemporalVentaInsertaCsv] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTemporalVentaInsertaCsv]
@Data varchar(max)
as
Begin
Declare @p1 int,@p2 int,@p3 int,
        @p4 int,@p5 int,@p6 int,
        @p7 int,@p8 int
Declare @temporalId  numeric(38)
Declare @UsuarioID  int
Declare @IdProducto  numeric(20)
Declare @cantidad  decimal(18,2)
Declare @precioventa  decimal(18,2)
Declare @importe  decimal(18,2)
Declare @ValorUM  decimal(18,4)
Declare @UniMedida  varchar(40)
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2=CharIndex('|',@Data,@p1+1)
Set @p3=CharIndex('|',@Data,@p2+1)
Set @p4=CharIndex('|',@Data,@p3+1)
Set @p5=CharIndex('|',@Data,@p4+1)
Set @p6=CharIndex('|',@Data,@p5+1)
Set @p7=CharIndex('|',@Data,@p6+1)
Set @p8= Len(@Data)+1
Set @temporalId=convert(numeric(38),SUBSTRING(@Data,1,@p1-1))
Set @UsuarioID=convert(int,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
Set @IdProducto=convert(numeric(20),SUBSTRING(@Data,@p2+1,@p3-@p2-1))
Set @cantidad=convert(decimal(18,2),SUBSTRING(@Data,@p3+1,@p4-@p3-1))
Set @precioventa=convert(decimal(18,2),SUBSTRING(@Data,@p4+1,@p5-@p4-1))
Set @importe=convert(decimal(18,2),SUBSTRING(@Data,@p5+1,@p6-@p5-1))
Set @ValorUM=convert(decimal(18,4),SUBSTRING(@Data,@p6+1,@p7-@p6-1))
Set @UniMedida=SUBSTRING(@Data,@p7+1,@p8-@p7-1)
insert into TemporalVenta values(@UsuarioID,@IdProducto,@cantidad,@precioventa,
@importe,@ValorUM,@UniMedida)
select
    isnull((select STUFF ((select '¬'+convert(varchar,t.temporalId)+'|'+CONVERT(varchar,t.UsuarioId)+'|'+convert(varchar,t.IdProducto)+'|'+
    p.ProductoCodigo+'|'+convert(varchar,t.cantidad)+'|'+t.UniMedida+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
	convert(varchar,cast((p.ProductoCosto* t.ValorUM) as decimal(18,2)))+'|'+
	convert(varchar,t.precioventa)+'|'+
    CONVERT(VarChar(50), cast((t.cantidad*p.ProductoPV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast((t.cantidad*p.ProductoSV) as money ), 1)+'|'+
	CONVERT(VarChar(50), cast(t.importe as money ), 1)+'|'+
	p.ProductoImagen+'|'+
	convert(varchar,t.ValorUM)+'|'+
	convert(varchar,convert(decimal(18,2),t.precioventa/1.18))+'|'+
	convert(varchar,(t.importe - convert(decimal(18,2),t.importe/1.18)))+'|'+
	convert(varchar,convert(decimal(18,2),t.importe/1.18))+'|'+
	convert(varchar,p.ProductoPV)+'|'+convert(varchar,p.ProductoSV)+'|'+
	s.NombreSublinea+'|'+p.AplicaFB
	from TemporalVenta t
	inner join Producto p
	on p.IdProducto=t.IdProducto
	inner join Sublinea s
	on s.IdSubLinea=p.IdSubLinea
	where t.UsuarioID=@UsuarioID 
	order by t.temporalId asc
	for xml path('')),1,1,'')),'~')
End
GO

IF OBJECT_ID(N'dbo.uspTraeGuiaCredito', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTraeGuiaCredito] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTraeGuiaCredito]    
@GuiaId varchar(40)    
as    
begin    
select     
isnull((select STUFF ((select top 1 '¬'+convert(varchar,g.GuiaId)+'|'+g.CodigoDXN+'|'+    
(IsNull(convert(varchar,g.FechaRegistro,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,g.FechaRegistro,114),1,8),''))+'|'+    
g.Destino+'|'+g.Usuario+'|'+    
CONVERT(VarChar(max), cast(g.Total as money ), 1)    
from GuiaInternaSI g  
where g.GuiaId=@GuiaId    
for xml path('')),1,1,'')),'~')+'['+    
'ID|IdPro|Cantidad|Unidad|Descripcion|PrecioCosto|PrecioVenta|Importe¬100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String¬'+  
isnull((select STUFF ((select '¬'+convert(varchar,d.DetalleId)+'|'+    
convert(varchar,d.IdProducto)+'|'+    
CONVERT(VarChar(max), cast(d.Cantidad as money ), 1)+'|'+d.UnidadM+'|'+    
d.Descripcion+'|'+    
CONVERT(VarChar(max), cast(d.Costo as money ), 1)+'|'+    
CONVERT(VarChar(max), cast(d.PrecioVenta as money ), 1)+'|'+    
CONVERT(VarChar(max), cast(d.Importe as money ), 1)  
from DetalleGuiaInterna d    
where d.GuiaId=@GuiaId   
order by d.DetalleId asc    
for xml path('')),1,1,'')),'~')    
end
GO

IF OBJECT_ID(N'dbo.usptraerCaja', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usptraerCaja] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usptraerCaja]
@UsuarioId int
as
begin
select
isnull((select stuff((select '¬'+
convert(varchar,c.CajaId)
from Caja c 
where c.CajaEstado='ACTIVO' and UsuarioId=@UsuarioId
order by c.CajaId desc
for xml path('')),1,1,'')),'0')
end
GO

IF OBJECT_ID(N'dbo.usptraerCajeros', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usptraerCajeros] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usptraerCajeros]
@Fecha Date
as
begin
select isnull((select stuff((SELECT ', '+ c.CajaEncargado
from Caja c 
where convert(date,c.CajaFecha)=@Fecha
for xml path('')),1,1,'')),'~')+'['+
isnull((select stuff((SELECT ', '+ a.Usuario
from APERTURA_ALMACEN a 
where convert(date,a.FechaApertura)=@fecha
for xml path('')),1,1,'')),'~')+'['+
'Codigo|Descripcion|Cantidad|Importe¬100|400|110|115¬String|String|String|String¬'+
isnull((select STUFF((select '¬'+p.ProductoCodigo+'|'+
d.DetalleDescripcion+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetalleCantidad) as money ), 1)+'|'+
CONVERT(VarChar(50), cast(SUM(d.DetalleImporte) as money ), 1)
from NotaPedido n
inner join DetallePedido d
on d.NotaId=n.NotaId
inner join Producto p
on p.IdProducto=d.IdProducto
where (n.NotaEntrega='INMEDIATA' AND n.NotaEstado<>'ANULADO') and convert(date,n.NotaFechaPago)=@Fecha
group by p.ProductoCodigo,d.DetalleDescripcion
order by p.ProductoCodigo asc
for xml path('')),1,1,'')),'~')+'['+
'Codigo|Responsable|SaldoSol¬130|430|120¬String|String|String¬'+
isnull((select stuff((select '¬'+ convert(varchar,n.CodigoRes)+'|'+
n.Responsable+'|'+
CONVERT(VarChar(50), cast(sum(n.NotaSaldo)as money ), 1)
from NotaPedido n
inner join Cliente c
on c.ClienteId=n.ClienteId
where (n.NotaSaldo>0 and n.NotaEstado<>'CANCELADO' and n.NotaEstado<>'ANULADO') and n.NotaCondicion='CREDITO'
and convert(date,n.NotaFecha)=@fecha
group by n.CodigoRes,n.Responsable
order by n.Responsable asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspTraerDV', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTraerDV] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTraerDV]
@Valores varchar(max)
as
begin
Declare @NotaId numeric(38),@DocuIdA numeric(38)
Declare @a1 int,@a2 int
Set @Valores= LTRIM(RTrim(@Valores))
Set @a1 = CharIndex('|',@Valores,0)
Set @a2= Len(@Valores)+1

set @NotaId=SUBSTRING(@Valores,1,@a1-1)
set @DocuIdA=SUBSTRING(@Valores,@a1+1,@a2-@a1-1)

Declare @EstadoSunat varchar(40)

set @EstadoSunat=isnull((select top 1 EstadoSunat
from DocumentoVenta
where DocuId=@DocuIdA),'')

IF EXISTS(select top 1 NotaId 
from DocumentoVenta 
where NotaId=@NotaId and TipoCodigo='01') --(TipoCodigo<>'07' and TipoCodigo <>'00'))
begin
Declare @lista varchar(max)
Declare @Estado varchar(20),@Asociado varchar(40),
@TipoCodigo char(2),@Serie char(4)
Declare @DocuId numeric(38)
declare @1 int,@2 int,@3 int,@4 int
set @lista=(select top 1 d.DocuEstado+'|'+d.DocuAsociado+'|'+convert(char(2),d.TipoCodigo)+'|'+convert(varchar,d.DocuId) 
from DocumentoVenta d 
where NotaId=@NotaId and TipoCodigo='01')
Set @lista = LTRIM(RTrim(@lista))
Set @1 = CharIndex('|',@lista,0)
Set @2 = CharIndex('|',@lista,@1+1)
Set @3 = CharIndex('|',@lista,@2+1)
Set @4 = Len(@lista)+1
set @Estado=SUBSTRING(@lista,1,@1-1)
set @Asociado=SUBSTRING(@lista,@1+1,@2-@1-1)
set @TipoCodigo=SUBSTRING(@lista,@2+1,@3-@2-1)
set @DocuId=convert(numeric(38),SUBSTRING(@lista,@3+1,@4-@3-1))

set @Serie=isnull((select top 1 m.SerieNC  
from MAQUINAS m 
where m.SerieNC<>''),'')

if(len(@Asociado)>0 and @EstadoSunat='ENVIADO')
select 'CANJEADO'
else
begin
Declare @Data varchar(max)
Declare @NotaConcepto varchar(20)
Declare @Entrega varchar(40)
Declare @FormaPago varchar(40)
Declare @NotaEstado varchar(40)
Declare @ConceptoOBS varchar(80)
declare @p1 int,@p2 int,@p3 int,@p4 int,@p5 int
set @Data=(select top 1 NotaConcepto+'|'+n.NotaEntrega+'|'+
n.NotaFormaPago+'|'+n.NotaEstado+'|'+n.ConceptoOBS 
from NotaPedido n where n.NotaId=@NotaId)
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = CharIndex('|',@Data,@p1+1)
Set @p3= CharIndex('|',@Data,@p2+1)
Set @p4= CharIndex('|',@Data,@p3+1)
Set @p5 = Len(@Data)+1
set @NotaConcepto=SUBSTRING(@Data,1,@p1-1)
set @Entrega=SUBSTRING(@Data,@p1+1,@p2-@p1-1)
set @FormaPago=SUBSTRING(@Data,@p2+1,@p3-@p2-1)
set @NotaEstado=SUBSTRING(@Data,@p3+1,@p4-@p3-1)
set @ConceptoOBS=SUBSTRING(@Data,@p4+1,@p5-@p4-1)
select
isnull((select STUFF((select top 1'¬'+d.DocuCondicion+'|'+d.EstadoSunat+'|'+d.DocuDocumento+'|'+
d.DocuSerie+'-'+d.DocuNumero+'|'+convert(varchar,d.ClienteId)+'|'+
c.ClienteRazon+'|'+c.ClienteRuc+'|'+c.ClienteDni+'|'+c.ClienteDireccion+'|'+
(Convert(char(10),d.DocuEmision,103))+'|'+d.DocuUsuario+'|'+
CONVERT(VarChar(50), cast(d.DocuTotal as money ), 1)+'|'+convert(varchar,d.CompaniaId)+'|'+
(select dbo.genenerarNroFactura(@Serie,d.CompaniaId,'NOTA DE CREDITO'))+'|'+
@Entrega+'|'+@FormaPago+'|'+@NotaEstado+'|'+convert(varchar,d.NotaId)+'|'+
convert(varchar,d.DocuId)+'|'+@Serie+'|'+co.CompaniaRazonSocial+'|'+co.CompaniaComercial+'|'+
co.CompaniaRUC+'|'+co.CompaniaUserSecun+'|'+co.ComapaniaPWD+'|'+co.CompaniaPFX+'|'+
co.CompaniaClave+'|'+co.CompaniaEmail+'|'+co.CompaniaDireccion+'|'+co.CompaniaTelefono+'|'+
co.CompaniaNomUBG+'|'+co.CompaniaCodigoUBG+'|'+co.CompaniaDistrito+'|'+co.CompaniaDirecSunat+'|'+
d.DocuOperacion+'|'+c.ClienteCodigo+'|'+d.DocuTransaccion+'|'+
CONVERT(VarChar(50), cast(d.DocuSaldo as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DocuAdicional as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DocuSubTotal as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DocuIgv as money ), 1)+'|'+@ConceptoOBS+'|'+d.EntidadBancaria+'|'+
CONVERT(VarChar(50), cast(d.Efectivo as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.Deposito as money ), 1)
from DocumentoVenta d
inner join Cliente c
on c.ClienteId=d.ClienteId
inner join Compania co
on co.CompaniaId=d.CompaniaId
where d.NotaId=@NotaId and TipoCodigo='01'
for xml path('')),1,1,'')),'~')+'['+
'Cantidad|UM|Descripcion|Precio|Importe|DetalleId|IdProducto|valorUM|PrecioSunat|IGVPrecio|ImporteSunat|Codigo|Linea|CodSunat¬103|100|350|110|115|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+CONVERT(VarChar(50), cast(d.DetalleCantidad as money ), 1)+'|'+
d.DetalleUM+'|'+p.ProductoNombre+' '+p.ProductoMarca+'|'+
CONVERT(VarChar(50), cast(d.DetallPrecio as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleImporte as money ), 1)+'|'+
convert(varchar,d.DetalleNotaId)+'|'+convert(varchar,d.IdProducto)+'|'+
convert(varchar,d.ValorUM)+'|'+

convert(varchar,convert(decimal(18,6),d.DetallPrecio/1.18))+'|'+
convert(varchar,(convert(decimal(18,6),d.DetallPrecio/1.18)* d.DetalleCantidad)*0.18)+'|'+
convert(varchar,convert(decimal(18,6),d.DetallPrecio/1.18)* d.DetalleCantidad) +'|'+

p.ProductoCodigo+'|'+s.NombreSublinea+'|'+s.CodigoSUNAT
from DetalleDocumento d
inner join Producto p
on p.IdProducto=d.IdProducto
inner join Sublinea s
on s.IdSubLinea=p.IdSubLinea
where DocuId=@DocuId
order by d.DetalleId asc
for xml path('')),1,1,'')),'~')
end
end
else
begin
select 'NO EXISTE'
end
end
GO

IF OBJECT_ID(N'dbo.uspTraerEscaneo', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTraerEscaneo] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTraerEscaneo]
@NotaId varchar(38)
as
begin

Declare @Data varchar(max)
set @Data=isnull((select top 1 n.NotaEstado+'|'+n.NotaConcepto+'|'+n.Entrega 
from NotaPedido n
where n.NotaId=@NotaId),'N')

if(@Data='N')
begin
select 'N'
end
Else
begin
Declare @pos1 int,@pos2 int,@pos3 int
Declare @Estado varchar(40),@Concepto varchar(40),
        @Entrega varchar(40)
Set @pos1=CharIndex('|',@Data,0)
Set @pos2=CharIndex('|',@Data,@pos1+1)
Set @pos3=Len(@Data)+1
Set @Estado=SUBSTRING(@Data,1,@pos1-1)
Set @Concepto=SUBSTRING(@Data,@pos1+1,@pos2-@pos1-1)
Set @Entrega=SUBSTRING(@Data,@pos2+1,@pos3-@pos2-1)
if(@Estado='ANULADO')
BEGIN
select 'ANULADO'
END
ELSE IF(@Concepto='SERVICIO')
BEGIN
select 'SERVICIO'
END
ELSE IF(@Entrega='ENTREGADO')
BEGIN
select 'ENTREGADO'
END
ELSE
BEGIN
select 
isnull((select STUFF((select '¬'+convert(varchar,n.NotaId)+'|'+
n.NotaDocu+'|'+n.NotaSerie+'-'+n.NotaNumero+'|'+
c.ClienteCodigo+'|'+convert(varchar,n.NotaFecha,103)+'|'+
c.ClienteRazon+'|'+c.ClienteRuc+'|'+c.ClienteDni+'|'+
n.NotaTransaccion+'|'+n.NotaUsuario+'|'+
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
(convert(varchar,CAST(n.NotaPagar as money), -1))
from NotaPedido n
inner join Cliente c
on c.ClienteId=n.ClienteId
where n.NotaId=@NotaId
FOR XML path ('')),1,1,'')),'~')+'['+
'Cantidad|Descripcion|PrecioUni|Importe¬90|90|90|90¬String|String|String|String¬'+
isnull((select STUFF((select '¬'+
convert(varchar,d.DetalleCantidad)+'|'+
d.DetalleDescripcion+'|'+
(convert(varchar,CAST(d.DetallePrecio as money), -1))+'|'+
(convert(varchar,CAST(d.DetalleImporte as money), -1))
from DetallePedido d
where d.NotaId=@NotaId
order by d.DetalleId asc
FOR XML path ('')),1,1,'')),'~')
END
End
End
GO

IF OBJECT_ID(N'dbo.uspTraerEscaneoB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTraerEscaneoB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTraerEscaneoB]
@NotaId varchar(38)
as
begin
select 
isnull((select STUFF((select '¬'+convert(varchar,n.NotaId)+'|'+
n.NotaDocu+'|'+n.NotaSerie+'-'+n.NotaNumero+'|'+
c.ClienteCodigo+'|'+convert(varchar,n.NotaFecha,103)+'|'+
c.ClienteRazon+'|'+c.ClienteRuc+'|'+c.ClienteDni+'|'+
n.NotaTransaccion+'|'+n.NotaUsuario+'|'+
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
(convert(varchar,CAST(n.NotaPagar as money), -1))
from NotaPedido n
inner join Cliente c
on c.ClienteId=n.ClienteId
where n.NotaId=@NotaId
FOR XML path ('')),1,1,'')),'~')+'['+
'Cantidad|Descripcion|PrecioUni|Importe¬90|90|90|90¬String|String|String|String¬'+
isnull((select STUFF((select '¬'+
convert(varchar,d.DetalleCantidad)+'|'+
d.DetalleDescripcion+'|'+
(convert(varchar,CAST(d.DetallePrecio as money), -1))+'|'+
(convert(varchar,CAST(d.DetalleImporte as money), -1))
from DetallePedido d
where d.NotaId=@NotaId
order by d.DetalleId asc
FOR XML path ('')),1,1,'')),'~')
End
GO

IF OBJECT_ID(N'dbo.uspTraerGastos', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTraerGastos] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTraerGastos]    
@Fecha date    
as    
begin    
Declare @Aviso int    
set @Aviso=(select COUNT(c.ConteoId)from ConteoMonedas c    
where FechaConteo=@Fecha)    
if(@Aviso=0)    
begin   
  
--dECLARE @Fecha date   
--SET @Fecha='05-07-2025'  
  
--IF OBJECT_ID('#tmpOBS') IS NOT NULL DROP TABLE #tmpOBS  
CREATE TABLE #tmpOBS (FechaTransaccion date,NotaTransaccion varchar(80),TipoVenta nvarchar(3))  
  
--IF OBJECT_ID('#tmpNota') IS NOT NULL DROP TABLE #tmpNota  
CREATE TABLE #tmpNota (NotaTransaccion varchar(80),CajaId numeric(38))  
  
insert into #tmpOBS (FechaTransaccion,NotaTransaccion,TipoVenta)  
select t.FechaTransaccion,T.NotaTransaccion,t.TipoVenta  
from TABLAOBS T    
where T.FechaTransaccion between @Fecha and @Fecha  
  
  
insert into #tmpNota (NotaTransaccion,CajaId)  
select n.NotaTransaccion,n.CajaId  
from NotaPedido n    
where n.NotaFechaPago between @Fecha and @Fecha  
  
--SELECT * FROM #tmpNota  
--SELECT * FROM #tmpOBS   
  
Select    
isnull((select STUFF((select '¬'+ c.DetalleConcepto+'|'+    
CONVERT(VarChar(50),cast(c.DetalleMonto as money ), 1)+'|T|0|S'    
from CajaDetalle c    
where (convert(date,c.DetalleFecha) between @Fecha and @Fecha) and c.NotaId=0 and c.DetalleMovimiento='SALIDA' and c.Vista=''  
order by c.DetalleId asc    
FOR XML path ('')),1,1,'')),'~')+'['+    
isnull((select STUFF((select '¬'+ c.DetalleConcepto+'|'+    
CONVERT(VarChar(50),cast(c.DetalleMonto as money ), 1)+'|T|0|I'    
from CajaDetalle c    
where (convert(date,c.DetalleFecha) between @Fecha and @Fecha) and c.NotaId=0 and c.DetalleMovimiento='INGRESO' and c.Vista=''   
order by c.DetalleId asc    
FOR XML path ('')),1,1,'')),'~')+'['+    
isnull((select STUFF((select '¬'+     
isnull(CONVERT(VarChar(50), cast(sum(c.MontoIniSOl) as money ), 1),'0.00') from Caja c    
where c.CajaEstado='ACTIVO'    
FOR XML path ('')),1,1,'')),'~')+'['+    
isnull((select STUFF((select '¬'+    
isnull(CONVERT(VarChar(50), cast(sum(T.Importe) as money ), 1),'0.00')     
from TABLAOBS T    
where T.FechaTransaccion between @Fecha and @Fecha and T.TipoVenta='OBS'    
FOR XML path ('')),1,1,'')),'~')+'['+    
isnull((select STUFF((select '¬'+    
convert(varchar,COUNT(t.ID))+'|'+    
isnull(CONVERT(VarChar(50), cast(sum(T.Importe) as money ), 1),'0.00')    
from TABLAOBS T    
where T.FechaTransaccion between @Fecha and @Fecha and T.tipoVenta='IOC'    
FOR XML path ('')),1,1,'')),'~')+'['+    
isnull((select STUFF((select '¬'+    
isnull(CONVERT(VarChar(50), cast(sum(d.DetalleMonto) as money ), 1),'0.00')    
from CajaDetalle d    
where (convert(date,d.DetalleFecha) between @Fecha and @Fecha) and d.DetalleConcepto='REVISTAS'    
FOR XML path ('')),1,1,'')),'~')+'['+    
isnull((select STUFF((select '¬'+    
isnull(CONVERT(VarChar(50), cast(sum(d.DetalleMonto) as money ), 1),'0.00')    
from CajaDetalle d    
where (convert(date,d.DetalleFecha) between @Fecha and @Fecha) and d.DetalleConcepto='COPIAS Y OTROS'    
FOR XML path ('')),1,1,'')),'~')+'['+    
isnull((select STUFF((select '¬'+    
isnull(CONVERT(VarChar(50), cast(sum(d.DetalleMonto) as money ), 1),'0.00')    
from CajaDetalle d    
where (convert(date,d.DetalleFecha) between @Fecha and @Fecha) and d.DetalleConcepto='VITRINA'    
FOR XML path ('')),1,1,'')),'')+'['+    
isnull((select STUFF((select  top 1'¬'+ convert(varchar,count(isnull(n.CajaId,0)))--isnull(convert(varchar,n.CajaId),0)  
from #tmpOBS T    
left join #tmpNota n    
on n.NotaTransaccion=t.NotaTransaccion  
where  (T.FechaTransaccion between @Fecha and @Fecha) and T.TipoVenta='OBS' and  n.CajaId is null    
FOR XML path ('')),1,1,'')),'~')+'['+    
isnull((select STUFF((select  top 1'¬'+ convert(varchar,count(isnull(n.CajaId,0)))    
from #tmpOBS T    
left join #tmpNota n    
on n.NotaTransaccion=t.NotaTransaccion    
where (T.FechaTransaccion between @Fecha and @Fecha) and T.TipoVenta='IOC' and  n.CajaId is null    
FOR XML path ('')),1,1,'')),'~')    
end    
else    
begin    
select '~[~[[[0|[[[0[0[0'    
end    
end
GO

IF OBJECT_ID(N'dbo.uspTraerGastosA', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTraerGastosA] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTraerGastosA]
@CajaId numeric(38)
as
begin
Select
isnull((select STUFF((select '¬'+ c.DetalleConcepto+'|'+
case when c.DetalleMonto<=0 then
''
else CONVERT(VarChar(max),cast(c.DetalleMonto as money ), 1) end +'|'+
c.Estado+'|'+CONVERT(varchar,c.DetalleId)+'|S'
from CajaDetalle c
where (CajaId=@CajaId and NotaId='0') and c.DetalleMovimiento='SALIDA'
order by c.DetalleId asc
FOR XML path ('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ c.DetalleConcepto+'|'+
case when c.DetalleMonto<=0 then
''
else CONVERT(VarChar(max),cast(c.DetalleMonto as money ), 1) end +'|'+
c.Estado+'|'+CONVERT(varchar,c.DetalleId)+'|I'
from CajaDetalle c
where (CajaId=@CajaId and NotaId='0')and c.DetalleMovimiento='INGRESO'
order by c.DetalleId asc
FOR XML path ('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ 
isnull(CONVERT(VarChar(max),cast(sum(T.Importe) as money ), 1),'0.00')
from TABLAOBS T
left join NotaPedido n
on n.NotaTransaccion=t.NotaTransaccion
where T.TipoVenta='OBS' and n.CajaId=@CajaId
FOR XML path ('')),1,1,'')),'~')+'['+
isnull((select STUFF((select '¬'+ 
isnull(CONVERT(VarChar(max),cast(sum(T.Importe) as money ), 1),'0.00')+'|'+
isnull(CONVERT(varchar,count(T.ID)),'')
from TABLAOBS T
left join NotaPedido n
on n.NotaTransaccion=t.NotaTransaccion
where T.TipoVenta='IOC' and n.CajaId=@CajaId
FOR XML path ('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspTraerPaginaActiva', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTraerPaginaActiva] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTraerPaginaActiva]
@UsuarioId int
as
begin
select
isnull((select STUFF((select top 1'¬'+ (IsNull(convert(varchar,p.HoraFin,103),'')+'  '+IsNull(SUBSTRING(convert(varchar,p.HoraFin,114),1,8),''))+'|'+
p.PaginasWeb
from Paginas p
where (p.UsuarioId=@UsuarioId and p.HoraFin>GETDATE()) and p.Concepto='ACTIVAR'
order by p.IdPagina ASC
FOR XML PATH('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspTraerPFX', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTraerPFX] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTraerPFX]
@Data varchar(max)
as
begin
declare @CompaniaId int,
        @Serie varchar(4)
declare @p1 int,@p2 int
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 = Len(@Data)+1
set @CompaniaId=convert(int,SUBSTRING(@Data,1,@p1-1))
set @Serie=SUBSTRING(@Data,@p1+1,@p2-@p1-1)
SELECT 
isnull((select STUFF ((select top 1'¬'+convert(varchar,c.CompaniaId)+'|'+c.CompaniaRazonSocial+'|'+
c.CompaniaComercial+'|'+c.CompaniaRUC+'|'+c.CompaniaUserSecun+'|'+c.ComapaniaPWD+'|'+c.CompaniaPFX+'|'+c.CompaniaClave+'|'+
@Serie+'-'+convert(varchar,dbo.genenerarNroFactura(@Serie,@CompaniaId,'FACTURA'))+'|'+c.CompaniaEmail+'|'+c.CompaniaDireccion+'|'+
c.CompaniaTelefono+'|'+CompaniaNomUBG+'|'+CompaniaCodigoUBG+'|'+CompaniaDistrito+'|'+CompaniaDirecSunat
FROM Compania c
where c.CompaniaId=@CompaniaId
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspTraerPFXB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTraerPFXB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTraerPFXB]
@CompaniaId int
as
begin
SELECT 
isnull((select STUFF ((select top 1'¬'+convert(varchar,c.CompaniaId)+'|'+c.CompaniaRazonSocial+'|'+
c.CompaniaComercial+'|'+c.CompaniaRUC+'|'+c.CompaniaUserSecun+'|'+c.ComapaniaPWD+'|'+c.CompaniaPFX+'|'+c.CompaniaClave+'|'+
convert(varchar,dbo.genenerarNroFactura('F001',@CompaniaId,'FACTURA'))+'|'+c.CompaniaEmail+'|'+c.CompaniaDireccion+'|'+
c.CompaniaTelefono+'|'+CompaniaNomUBG+'|'+CompaniaCodigoUBG+'|'+CompaniaDistrito+'|'+CompaniaDirecSunat
FROM Compania c
where c.CompaniaId=@CompaniaId
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspTraerPorEntregar', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTraerPorEntregar] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTraerPorEntregar]
@NotaId varchar(40)
as
begin
select 
isnull((select STUFF ((select top 1 '¬'+convert(varchar,n.NotaId)+'|'+n.NotaCondicion+'|'+ 
c.ClienteCodigo+'|'+
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
c.ClienteRazon+'|'+n.Responsable+'|'+
CONVERT(VarChar(max), cast(n.NotaSaldo as money ), 1)
from NotaPedido n
inner join Cliente c
on c.ClienteId=n.ClienteId
where n.NotaId=@NotaId
for xml path('')),1,1,'')),'~')+'['+
'DetalleId|ID|Cantidad|Descripcion|Precio|PV|SV|Importe|SaldoCan|InicialCan¬100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF ((select '¬'+convert(varchar,d.DetalleId)+'|'+
convert(varchar,d.IdProducto)+'|'+
CONVERT(VarChar(max), cast(d.CantidadSaldo as money ), 1)+'|'+
d.DetalleDescripcion+'|'+
CONVERT(VarChar(max), cast(d.DetallePrecio as money ), 1)+'|'+
CONVERT(VarChar(max), cast(d.DetallePV as money ), 1)+'|'+
CONVERT(VarChar(max), cast(d.DetalleSV as money ), 1)+'|'+
CONVERT(VarChar(max), cast(d.DetalleImporte as money ), 1)+'|'+
CONVERT(VarChar(max), cast(d.CantidadSaldo as money ), 1)+'|'+
CONVERT(VarChar(max), cast(d.DetalleCantidad as money ), 1)
from DetallePedido d
where d.NotaId=@NotaId
order by d.DetalleId asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.usptraerResponsableDeuda', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usptraerResponsableDeuda] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usptraerResponsableDeuda]  
@Codigo varchar(80)  
as  
begin  
declare @Data varchar(max)  
declare @Deuda decimal(18,2)  
declare @SumSoloPuntos decimal(18,2)  
declare @DeudaTotal decimal(18,2)  
set @Deuda=isnull((select   
SUM(NotaSaldo)  
from NotaPedido n  
where CodigoRes=@Codigo and (n.NotaCondicion='CREDITO' and (n.NotaEstado<>'CANCELADO' and n.NotaEstado<>'ANULADO'))  
and n.NotaSaldo > 0),0)  
set @SumSoloPuntos=isnull((select SUM(Total)   
from GuiaRemision  
where CodigoRes=@Codigo and GuiaEstado='PENDIENTE' AND GuiaMotivo='CREDITO ALA RED'),0)  
set @DeudaTotal=@Deuda+@SumSoloPuntos  
set @Data = isnull((select top 1 convert(varchar, c.clienteId) + '|' +  
c.ClienteCodigo + '|' + c.ClienteRazon+'|'+CONVERT(varchar,@DeudaTotal) from Cliente c   
where ClienteCodigo =@Codigo  
order by c.ClienteId desc), '~')  
select @Data  
end
GO

IF OBJECT_ID(N'dbo.usptraerSecuenciaResumen', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[usptraerSecuenciaResumen] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[usptraerSecuenciaResumen]  
@CompaniaId varchar(20)  
as  
begin  
Declare @COUNT INT  
set @COUNT=(select COUNT(*) from ResumenBoletas)  
if(@COUNT=0)  
begin  
select '1'  
end  
else  
begin  
select top 1 convert(varchar,Secuencia+1)  
from ResumenBoletas where CompaniaId =@CompaniaId  
order by Secuencia desc  
end  
end
GO

IF OBJECT_ID(N'dbo.uspTraeTodasMonedas', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTraeTodasMonedas] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTraeTodasMonedas]
@Fecha date
as
begin
--set @Fecha='06-30-2021'
Declare @Count int,@Aviso int
set @Count=(select COUNT(c.CajaId) from Caja c
where convert(date,c.CajaFecha)=@Fecha)
if(@Count<=3)
begin
select 
isnull((select STUFF ((select '¬'+convert(varchar,d.MonedaId)+'|'+
case when sum(m.Efectivo)=0then
'' else convert(varchar,sum(m.Efectivo))end +'|'+
m.Billete+'|'+CONVERT(VarChar(50),cast(sum(m.Monto)as money ), 1)+'|'+m.Concepto
from Monedas m
inner join Caja c
on c.CajaId=m.CajaId
inner join Moneda d
on d.MonedaValor=m.Billete
where convert(date,c.CajaFecha)=@Fecha AND C.CajaEstado='ACTIVO'
group by d.MonedaId,m.Billete,m.Concepto
order by d.MonedaId asc
for xml path('')),1,1,'')),'~')
end
else
begin
select
isnull((select STUFF ((select '¬'+convert(varchar,d.MonedaId)+'|'+
case when sum(m.Efectivo)=0then
'' else convert(varchar,sum(m.Efectivo))end +'|'+
m.Billete+'|'+CONVERT(VarChar(50),cast(sum(m.Monto)as money ), 1)+'|'+m.Concepto
from Monedas m
inner join Caja c
on c.CajaId=m.CajaId
inner join Moneda d
on d.MonedaValor=m.Billete
where convert(date,c.CajaFecha)=@Fecha and m.Concepto='B'
group by d.MonedaId,m.Billete,m.Concepto
order by d.MonedaId asc
for xml path('')),1,1,'')),'~')+'¬'+
isnull((select STUFF ((select '¬'+convert(varchar,d.MonedaId)+'|'+
case when sum(m.Efectivo)=0then
'' else convert(varchar,sum(m.Efectivo))end +'|'+
m.Billete+'|'+CONVERT(VarChar(50),cast(sum(m.Monto)as money ), 1)+'|'+m.Concepto
from Monedas m
inner join Caja c
on c.CajaId=m.CajaId
inner join Moneda d
on d.MonedaValor=m.Billete
where convert(date,c.CajaFecha)=@Fecha and m.Concepto='M' and c.CajaEstado='ACTIVO'
group by d.MonedaId,m.Billete,m.Concepto
order by d.MonedaId asc
for xml path('')),1,1,'')),'~')
end
end
GO

IF OBJECT_ID(N'dbo.uspTrunks', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspTrunks] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspTrunks]
@Data varchar(max)
as
Declare @p1 int,@p2 int
Declare @fechainicio date,
        @fechafin date
Set @Data = LTRIM(RTrim(@Data))
Set @p1 = CharIndex('|',@Data,0)
Set @p2 =Len(@Data)+1
Set @fechainicio=convert(date,SUBSTRING(@Data,1,@p1-1))
Set @fechafin=convert(date,SUBSTRING(@Data,@p1+1,@p2-@p1-1))
begin
Select
'DocuId|Compania|NotaId|FechaEmision|Documento|Numero|RazonSocial|RUC|DNI|Direccion|Usuario|SubTotal|IGV|Total¬100|90|100|120|120|140|350|100|90|400|160|120|120|120¬String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+Convert(varchar,d.DocuId)+'|'+
convert(varchar,d.CompaniaId)+'|'+convert(varchar,d.NotaId)+'|'+
(Convert(char(10),d.DocuEmision,103))+'|'+
d.DocuDocumento+'|'+d.DocuSerie+'-'+d.DocuNumero+'|'+c.ClienteRazon+'|'+
c.ClienteRuc+'|'+c.ClienteDni+'|'+c.ClienteDireccion+'|'+d.DocuUsuario+'|'+
CONVERT(VarChar(50), cast(d.DocuSubTotal as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DocuIgv as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DocuTotal as money ), 1)
from DocumentoVenta d
inner join Cliente c
on c.ClienteId=d.ClienteId
where (d.TipoCodigo='03' or d.TipoCodigo='01')and (Convert(char(10),d.DocuEmision,103) BETWEEN @fechainicio AND @fechafin)
order by d.DocuEmision,d.DocuSerie,d.DocuNumero asc
for xml path('')),1,1,'')),'~')+'['+
'DocuId|Cantidad|UM|Descripcion|PrecioUni|Importe¬100|100|100|350|115|120¬String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,d.DocuId)+'|'+
CONVERT(VarChar(50), cast(d.DetalleCantidad as money ), 1)+'|'+DetalleUM+'|'+
p.ProductoNombre+' '+p.ProductoMarca+'|'+
CONVERT(VarChar(50), cast(d.DetallPrecio as money ), 1)+'|'+
CONVERT(VarChar(50), cast(d.DetalleImporte as money ), 1)
from DetalleDocumento d
inner join Producto p
on p.IdProducto=d.IdProducto
inner join DocumentoVenta do
on do.DocuId=d.DocuId
where (do.TipoCodigo='03' or do.TipoCodigo='01')and(Convert(char(10),do.DocuEmision,103) BETWEEN @fechainicio AND @fechafin)
order by do.DocuEmision,do.DocuSerie,do.DocuNumero asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspUsuarioBaja', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspUsuarioBaja] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspUsuarioBaja]
as
begin
select
'Id|Usuario|AREA|FechaBaja|Estado¬90|260|250|100|100¬String|String|String|String|String¬'+
isnull((select stuff((SELECT '¬'+ convert(varchar,u.UsuarioID)+'|'+
u.UsuarioAlias+'|'+a.AreaNombre+'|'+
p.PersonalBajaFecha+'|'+p.PersonalEstado
from Usuarios u
inner join Personal P
on p.PersonalId=u.PersonalId
inner join Area a
on a.AreaId=p.AreaId
where u.UsuarioEstado='DESACTIVO'
order by P.PersonalNombres+' '+P.PersonalApellidos asc
for xml path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspUtilitario', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspUtilitario] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspUtilitario]
as
begin
select 
'TABLAS|TABLE['+
isnull((select STUFF((select '¬'+s.name+'|'+s.name
from sys.tables s
order by s.name asc
for XMl path('')),1,1,'')),'~')+'['+
'TYPO|COLUMN_NAME|DATA_TYPE|TAMANO¬0|220|150|115¬'+
isnull((select STUFF((select '¬'+ I.DATA_TYPE+'|'+I.COLUMN_NAME+'|'+I.DATA_TYPE+'|'+
       isnull(convert(varchar,case when CHARACTER_MAXIMUM_LENGTH is null then
       NUMERIC_PRECISION
       else CHARACTER_MAXIMUM_LENGTH end),'0')+','+isnull(convert(varchar,NUMERIC_SCALE),'0')+'|'+
       I.TABLE_NAME
FROM   INFORMATION_SCHEMA.COLUMNS I
order by TABLE_NAME asc
for XMl path('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.uspValidarApertura', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspValidarApertura] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspValidarApertura]
@Fecha date
as
begin
--Declare @IdApertura numeric(38)
--set @IdApertura=isnull((
--select top 1 IdApertura from APERTURA_ALMACEN a
--where convert(date,FechaApertura)=@Fecha),'0')
--if(@IdApertura=0)
--begin
--select 'NO EXISTE'
--end
--else
--begin
--Declare @data varchar(40)
--set @data=(select top 1 FechaCierre from APERTURA_ALMACEN
--where IdApertura=@IdApertura)
--if(len(@data)=0)
--begin
--select 'NO CERRO'
--end
--else
--begin
--IF NOT EXISTS(select top 1 a.Fecha from AperturaOBS a where a.Fecha=@Fecha)
--begin
--select 'NO APERTURO OBS'
--end
--else
--begin
--Declare @BoletaPen int
--Declare @ConsultaPen int 
--Declare @AnuladosPen int
--Declare @ConsultaError int
--set @BoletaPen=(select top 1 count(DocuId) from DocumentoVenta
--where TipoCodigo='03'and((CompaniaId=1 and EstadoSunat='PENDIENTE')
--and DocuEmision<convert(date,GETDATE())))
--set @ConsultaPen=(select COUNT(ResumenId) from ResumenBoletas
--where CodigoSunat='')
--set @AnuladosPen=(select COUNT(d.DocuId) from DocumentoVenta d
--where d.TipoCodigo='03'and((d.CompaniaId=1 and DocuEstado='ANULADO' and d.EstadoSunat='ENVIADO')))
--set @ConsultaError=(select COUNT(ResumenId) from ResumenBoletas
--where CodigoSunat='env:Server' or CodigoSunat='env:Client')
--if(@BoletaPen>0)
--begin
--select 'BOLETA'
--END
--else if(@AnuladosPen>0)
--begin
--select 'ANULADOS'
--END
--else if(@ConsultaPen>0)
--begin
--select 'CONSULTA'
--END
--else if(@ConsultaError>0)
--begin
--select 'ERROR'
--end
--else
--begin

Declare @PagoVarios int
set @PagoVarios=(select convert(varchar, COUNT(*)) from DocumentoVenta d 
inner join NotaPedido n 
on n.NotaId = d.NotaId 
where n.NotaCondicion = 'PAGO/VARIOS' and (n.NotaEstado <> 'CANCELADO' and n.NotaEstado <> 'ANULADO'))

if(@PagoVarios>0)
begin
select 'PAGO/VARIOS'
end
else
begin
select 'true'
end

end
--end
--end
--end
--end
GO

IF OBJECT_ID(N'dbo.uspValidarAperturaB', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspValidarAperturaB] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspValidarAperturaB]
as
begin
Declare @BoletaPen int
Declare @ConsultaPen int 
Declare @AnuladosPen int
Declare @ConsultaError int
set @BoletaPen=(select top 1 count(DocuId) from DocumentoVenta
where TipoCodigo='03'and((CompaniaId=1 and EstadoSunat='PENDIENTE')
and DocuEmision<convert(date,GETDATE())))
set @ConsultaPen=(select COUNT(ResumenId) from ResumenBoletas
where CodigoSunat='')
set @AnuladosPen=(select COUNT(d.DocuId) from DocumentoVenta d
where d.TipoCodigo='03'and((d.CompaniaId=1 and DocuEstado='ANULADO' and 
d.EstadoSunat='ENVIADO')))
set @ConsultaError=(select COUNT(ResumenId) from ResumenBoletas
where CodigoSunat='env:Server' or CodigoSunat='env:Client')
if(@BoletaPen>0)
begin
select 'BOLETA'
END
else if(@AnuladosPen>0)
begin
select 'ANULADOS'
END
else if(@ConsultaPen>0)
begin
select 'CONSULTA'
END
else if(@ConsultaError>0)
begin
select 'ERROR'
end
else
begin
select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.uspValidarAperturaC', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspValidarAperturaC] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspValidarAperturaC]
as
begin
Declare @BoletaPen int
Declare @ConsultaPen int 
Declare @ConsultaError int
set @BoletaPen=(select top 1 count(DocuId) from DocumentoVenta
where TipoCodigo='03'and((CompaniaId=1 and EstadoSunat='PENDIENTE')
and DocuEmision<convert(date,GETDATE())))
set @ConsultaPen=(select COUNT(ResumenId) from ResumenBoletas
where CodigoSunat='')
set @ConsultaError=(select COUNT(ResumenId) from ResumenBoletas
where CodigoSunat='env:Server' or CodigoSunat='env:Client')
if(@BoletaPen>0)
begin
select 'BOLETA'
END
else if(@ConsultaPen>0)
begin
select 'CONSULTA'
END
else if(@ConsultaError>0)
begin
select 'ERROR'
end
else
begin
select 'true'
end
end
GO

IF OBJECT_ID(N'dbo.uspValidarNotaCre', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspValidarNotaCre] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspValidarNotaCre]      
@NotaId numeric(38)      
as      
begin      
      
Declare @count int      
      
set @count=(select COUNT(NotaId) from DocumentoVenta      
where NotaId=@NotaId and TipoCodigo='07')-- and EstadoSunat='ENVIADO')      
      
if(@count=0)select 'true'      
else select 'existe'      
      
end
GO

IF OBJECT_ID(N'dbo.uspValidaUsuario', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspValidaUsuario] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[uspValidaUsuario]  
@Data varchar(max)  
as  
begin  
Declare @p1 int,@p2 int,  
        @p3 int   
Declare @Usuario varchar(150),  
        @Clave varchar(150),  
        @CPUNAME VARCHAR(140)    
Set @Data = LTRIM(RTrim(@Data))  
Set @p1 = CharIndex('|',@Data,0)  
Set @p2 = CharIndex('|',@Data,@p1+1)  
Set @p3 = Len(@Data)+1  
Set @Usuario=SUBSTRING(@Data,1,@p1-1)  
Set @Clave=SUBSTRING(@Data,@p1+1,@p2-@p1-1)  
Set @CPUNAME=SUBSTRING(@Data,@p2+1,@p3-@p2-1)  
SELECT   
isnull((select STUFF ((select top 1 '¬'+convert(varchar,U.UsuarioID)+'|'+convert(varchar,p.PersonalId)+'|'+a.AreaNombre+'|'+  
(((SUBSTRING(p.PersonalNombres+' ',1,CHARINDEX(' ',p.PersonalNombres+' ')-1)))+' '+ ((SUBSTRING(p.PersonalApellidos+' ',1,CHARINDEX(' ',p.PersonalApellidos+' ')-1))))+'|'+  
convert(varchar,p.CompaniaId)+'|'+c.CompaniaRazonSocial+'|'+c.CompaniaRUC+'|'+  
u.UsuarioSerie+'|'+convert(varchar(1),u.EnviaBoleta)+'|'+  
convert(varchar(1),u.EnviarFactura)+'|'+c.CompaniaComercial+'|'+u.UserRuta+'|'+  
CONVERT(varchar,c.ICBPER)+'|'+u.UserRutaOBS+'|'+convert(varchar(1),u.Administrador)+'|'+  
c.HoraInicio+'|'+c.HoraFin+'|'+c.HoraIniAlm+'|'+c.HoraFinOBS+'|'+  
case when (CONVERT(date,GETDATE())>=(c.FechaRenovacion)) then  
'VENCIDO'  
else  
case when ((dateadd(DAY,-6,c.FechaRenovacion))<= CONVERT(date,GETDATE())) then  
'POR VENCER'  
else  
'PREMIUM' end end+'|'+  
(Convert(char(10),c.FechaRenovacion,103))  
FROM Usuarios U  
inner join Personal p  
on p.PersonalId=U.PersonalId  
inner join Area a  
on a.AreaId=p.AreaId  
inner join Compania c  
on c.CompaniaId=p.CompaniaId  
where U.UsuarioAlias=@Usuario AND dbo.desincrectar(U.UsuarioClave)=@Clave and u.Usuarioestado ='ACTIVO'and p.PersonalEstado='ACTIVO'  
for xml path('')),1,1,'')),'~')+'['+  
isnull((select STUFF ((select top 1 '¬'+ m.SerieFactura+'|'+  
m.SerieNC+'|'+m.SerieBoleta+'|'+m.Tiketera
FROM MAQUINAS m  
WHERE m.Maquina=@CPUNAME  
for xml path('')),1,1,'')),'~')  
end
GO

IF OBJECT_ID(N'dbo.uspValidaUsuarioweb', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[uspValidaUsuarioweb] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE dbo.uspValidaUsuarioweb
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @p1 int, @p2 int
    DECLARE @Usuario varchar(150), @Clave varchar(150)

    SET @Data = LTRIM(RTRIM(@Data))
    SET @p1 = CHARINDEX('|', @Data, 0)
    SET @p2 = CHARINDEX('|', @Data, @p1 + 1)
    IF (@p2 = 0) SET @p2 = LEN(@Data) + 1

    SET @Usuario = SUBSTRING(@Data, 1, @p1 - 1)
    SET @Clave = SUBSTRING(@Data, @p1 + 1, @p2 - @p1 - 1)

    SELECT ISNULL((
        SELECT STUFF((
            SELECT TOP 1
                '¬' + CONVERT(varchar, U.UsuarioID) + '|' +
                CONVERT(varchar, p.PersonalId) + '|' +
                ISNULL(a.AreaNombre, '') + '|' +
                (
                    SUBSTRING(ISNULL(p.PersonalNombres, '') + ' ', 1, CHARINDEX(' ', ISNULL(p.PersonalNombres, '') + ' ') - 1) + ' ' +
                    SUBSTRING(ISNULL(p.PersonalApellidos, '') + ' ', 1, CHARINDEX(' ', ISNULL(p.PersonalApellidos, '') + ' ') - 1)
                ) + '|' +
                CONVERT(varchar, p.CompaniaId) + '|' +
                ISNULL(c.CompaniaRazonSocial, '') + '|' +
                ISNULL(CONVERT(varchar(10), U.FechaVencimientoClave, 23), '') + '|' +
                ISNULL(CONVERT(varchar(20), c.DescuentoMax), '0') + '|' +
                ISNULL(c.CompaniaRUC, '') + '|' +
                ISNULL(c.CompaniaNomUBG, '') + '|' +
                ISNULL(c.CompaniaComercial, '') + '|' +
                ISNULL(c.CompaniaDirecSunat, '') + '|' +
                ISNULL(c.CompaniaUserSecun, '') + '|' +
                ISNULL(c.ComapaniaPWD, '') + '|' +
                ISNULL(c.CompaniaPFX, '') + '|' +
                ISNULL(c.CompaniaClave, '') + '|' +
                ISNULL(CONVERT(varchar, c.TIPO_PROCESO), '3') + '|' +
                ISNULL(c.CompaniaTelefono, '') + '|' +
                ISNULL(CONVERT(varchar, c.BoletaPorLote), '1') + '|' +
                ISNULL(CONVERT(varchar, c.FlagCaptura), '0')
            FROM dbo.Usuarios U
            INNER JOIN dbo.Personal p ON p.PersonalId = U.PersonalId
            INNER JOIN dbo.Area a ON a.AreaId = p.AreaId
            INNER JOIN dbo.Compania c ON c.CompaniaId = p.CompaniaId
            WHERE U.UsuarioAlias = @Usuario
              AND dbo.desincrectar(U.UsuarioClave) = @Clave
              AND U.UsuarioEstado = 'ACTIVO'
              AND p.PersonalEstado = 'ACTIVO'
            FOR XML PATH('')
        ), 1, 1, '')
    ), '~')
END
GO

IF OBJECT_ID(N'dbo.validarDatos', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[validarDatos] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[validarDatos]
@NotaId numeric(38)
as
begin
select a.NotaId,a.NotaEstado,a.Cantidad,isnull(b.Documento,0) as Emitidos,isnull(b.Acuenta,0)as Acuenta 
from 
(select n.NotaId,n.NotaEstado,
'0' as Cantidad 
from  DetallePedido d 
right join NotaPedido n
on n.NotaId=d.NotaId
where n.NotaId=@NotaId
group by n.NotaId,n.NotaEstado) a 
full join 
(select d.NotaId as NotaId,COUNT(d.NotaId) as Documento ,COUNT(l.DocuId) as Acuenta 
from DocumentoVenta d
left join DetaLiquidaVenta l
on l.DocuId=d.DocuId 
where d.NotaId=@NotaId
group by d.NotaId) b 
on a.NotaId=b.NotaId
end
GO

IF OBJECT_ID(N'dbo.ventanaDeudas', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ventanaDeudas] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ventanaDeudas]
as
begin
select 
'ID|Codigo|Responsable|Cliente|FechaEmision|Documento|Saldo|Total|NotaId¬100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|String|String|String¬'+
isnull((select STUFF((select '¬'+convert(varchar,n.NotaId)+'|'+
n.CodigoRes+'|'+n.Responsable+'|'+c.ClienteRazon+'|'+
(IsNull(convert(varchar,n.NotaFecha,103),'')+' '+ IsNull(SUBSTRING(convert(varchar,n.NotaFecha,114),1,8),''))+'|'+
n.NotaSerie+'-'+n.NotaNumero+'|'+
CONVERT(VarChar(50),cast(n.NotaSaldo as money ), 1)+'|'+
CONVERT(VarChar(50),cast(n.NotaPagar as money ), 1)+'|'+
convert(varchar,n.NotaId)
from NotaPedido n
inner join Cliente c
on  c.ClienteId=n.ClienteId
where n.NotaConcepto='MERCADERIA' and (n.NotaCondicion='CREDITO' and (n.NotaEstado<>'CANCELADO' and n.NotaEstado<>'ANULADO'))and n.NotaSaldo > 0
order by n.NotaId desc
FOR XML path ('')),1,1,'')),'~')
end
GO

IF OBJECT_ID(N'dbo.ventanaFacturas', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ventanaFacturas] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ventanaFacturas]@TipoCodigo varchar(40)
as
begin
select c.CompraId,p.ProveedorRazon,(Convert(char(10),c.CompraEmision,103)) as CompraEmision,substring(t.TipoDescripcion,1,1)+'C '+c.CompraSerie+'-'+c.CompraNumero as Numero,c.CompraMoneda,c.CompraTipoCambio,CONVERT(VarChar(50),cast(c.CompraSaldo as money ), 1) as SaldoDoc,CONVERT(VarChar(50),cast(c.CompraTotal as money ), 1) as Total,
t.TipoDescripcion
from Compras c
inner join Proveedor p
on  c.ProveedorId=p.ProveedorId
inner join TipoComprobante t
on t.TipoCodigo=c.TipoCodigo
where t.TipoCodigo=@TipoCodigo and c.CompraEstado='PENDIENTE DE PAGO'
order by c.CompraId desc
end
GO

IF OBJECT_ID(N'dbo.ventanaLetras', N'P') IS NULL EXEC(N'CREATE PROCEDURE [dbo].[ventanaLetras] AS BEGIN SET NOCOUNT ON; END;');
GO

ALTER PROCEDURE [dbo].[ventanaLetras]
as
begin
select d.DetalleId,l.LetraId,p.ProveedorRazon,(Convert(char(10),d.LetraVencimiento,103)) as Vencimiento,'LT '+d.LetraCanje as LetraCanje,
(Convert(char(10),l.LetraFechaGiro,103)) as FechaGiro,l.LetraMoneda,CONVERT(VarChar(50),cast(d.DetalleSaldo as money ), 1) as SaldoDoc,
CONVERT(VarChar(50),cast(d.DetalleMonto as money ), 1) as MontoDoc
from DetalleLetra d
inner join Letra l
on l.LetraId=d.LetraId
inner join Proveedor p
on p.ProveedorId=l.ProveedorId
where d.DetalleEstado<>'TOTALMENTE PAGADO'
order by d.LetraVencimiento asc
end
GO

