create procedure [dbo].[uspinsertarNC]
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
