
CREATE  procedure [dbo].[anularDocumentoWEB]
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

