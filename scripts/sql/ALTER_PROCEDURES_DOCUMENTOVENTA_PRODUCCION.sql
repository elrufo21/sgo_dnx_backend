/*
Listo para copiar/pegar en produccion.
No guarda XML/CDR/PDF en estos flujos: DocuPdfUrl/DocuXmlUrl/DocuCdrUrl = ''.
Factura por servicio NO va aqui: ese flujo guarda XML/CDR desde backend.
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[uspinsertaFactura]              
@ListaOrden varchar(Max)              
as              
begin              
Declare @posA1 int,@posA2 int,@posA3 int    
Declare @orden varchar(max),    
        @detalle varchar(max),    
        @Guia varchar(max)    
Set @posA1 = CharIndex('[',@ListaOrden,0)    
Set @posA2 = CharIndex('[',@ListaOrden,@posA1+1)    
Set @posA3 =Len(@ListaOrden)+1    
Set @orden = SUBSTRING(@ListaOrden,1,@posA1-1)    
Set @detalle = SUBSTRING(@ListaOrden,@posA1+1,@posA2-@posA1-1)    
Set @Guia=SUBSTRING(@ListaOrden,@posA2+1,@posA3-@posA2-1)  
              
Declare @pos1 int,@pos2 int,@pos3 int,@pos4 int,              
        @pos5 int,@pos6 int,@pos7 int,@pos8 int,              
        @pos9 int,@pos10 int,@pos11 int,@pos12 int,              
        @pos13 int,@pos14 int,@pos15 int,@pos16 int,              
        @pos17 int,@pos18 int,@pos19 int,@pos20 int,              
        @pos21 int,@pos22 int,@pos23 int,@pos24 int,              
        @pos25 int,@pos26 int,@pos27 int,@pos28 int,              
        @pos29 int,@pos30 int,@pos31 int,@pos32 int,              
        @pos33 int,@pos34 int            
Declare @CompaniaId int,@NotaId numeric(38),@DocuDocumento varchar(60),              
        @DocuNumero varchar(60),@ClienteId numeric(20),@DocuEmision date,              
        @DocuSubTotal decimal(18,2),@DocuIgv decimal(18,2),@DocuTotal decimal(18,2),              
        @DocuUsuario varchar(60),@DocuSerie varchar(4),@TipoCodigo char(20),              
        @DocuAdicional decimal(18,2),@DocuAsociado varchar(80),@DocuConcepto varchar(80),              
        @DocuHASH varchar(250),@EstadoSunat varchar(80),@Letras varchar(60),              
        @DocuId numeric(38),@ICBPER decimal(18,2),@CodigoSunat VARCHAR(80),@MensajeSunat varchar(max),              
        @DocuGravada decimal(18,2),@DocuDescuento decimal(18,2),@CajaId nvarchar(40),              
        @UsuarioId int,@NotaFormaPago varchar(60),@Movimiento varchar(40),        
        @NotaCondicion varchar(60),@EntidadBancaria varchar(80),@NroOperacion varchar(80),      
        @Efectivo decimal(18,2),@Deposito decimal(18,2),@ClienteRazon varchar(140),  
        @ClienteRuc varchar(40),@ClienteDni varchar(40),@DireccionFiscal varchar(max)          
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
Set @pos33= CharIndex('|',@orden,@pos32+1)    
             
Set @pos34= Len(@orden)+1      
              
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
set @ICBPER=convert(decimal(18,2),SUBSTRING(@orden,@pos18+1,@pos19-@pos18-1))              
set @CodigoSunat=SUBSTRING(@orden,@pos19+1,@pos20-@pos19-1)              
set @MensajeSunat=SUBSTRING(@orden,@pos20+1,@pos21-@pos20-1)              
set @DocuGravada=convert(decimal(18,2),SUBSTRING(@orden,@pos21+1,@pos22-@pos21-1))              
set @DocuDescuento=convert(decimal(18,2),SUBSTRING(@orden,@pos22+1,@pos23-@pos22-1))              
set @NotaFormaPago=SUBSTRING(@orden,@pos23+1,@pos24-@pos23-1)              
set @UsuarioId=convert(int,SUBSTRING(@orden,@pos24+1,@pos25-@pos24-1))        
set @NotaCondicion=SUBSTRING(@orden,@pos25+1,@pos26-@pos25-1)      
      
set @EntidadBancaria=SUBSTRING(@orden,@pos26+1,@pos27-@pos26-1)              
set @NroOperacion=SUBSTRING(@orden,@pos27+1,@pos28-@pos27-1)              
set @Efectivo=convert(decimal(18,2),SUBSTRING(@orden,@pos28+1,@pos29-@pos28-1))              
set @Deposito=convert(decimal(18,2),SUBSTRING(@orden,@pos29+1,@pos30-@pos29-1))      
    
set @ClienteRazon=SUBSTRING(@orden,@pos30+1,@pos31-@pos30-1)              
set @ClienteRuc=SUBSTRING(@orden,@pos31+1,@pos32-@pos31-1)     
set @ClienteDni=SUBSTRING(@orden,@pos32+1,@pos33-@pos32-1)              
set @DireccionFiscal=SUBSTRING(@orden,@pos33+1,@pos34-@pos33-1)       
             
set @CajaId=isnull((select top 1 convert(nvarchar,CajaId)from Caja               
where CajaEstado='ACTIVO' order by 1 desc),'0')        
              
if(@CajaId=0)              
begin              
select 'false'              
end              
else              
begin              
Begin Transaction      
              
INSERT INTO DocumentoVenta
(
    CompaniaId, NotaId, DocuDocumento, DocuNumero, ClienteId, DocuRegistro,
    DocuEmision, DocuCondicion, DocuLetras, DocuSubTotal, DocuIgv, DocuTotal,
    DocuSaldo, DocuUsuario, DocuEstado, DocuSerie, TipoCodigo, DocuAdicional,
    DocuAsociado, DocuConcepto, DocuNroGuia, DocuHash, EstadoSunat, ICBPER,
    CodigoSunat, MensajeSunat, DocuGravada, DocuDescuento, EnvioCorreo,
    FormaPago, EntidadBancaria, NroOperacion, Efectivo, Deposito,
    ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal,
    DocuPdfUrl, DocuXmlUrl, DocuCdrUrl
)
VALUES
(
    @CompaniaId, @NotaId, @DocuDocumento, @DocuNumero,
    @ClienteId, GETDATE(), @DocuEmision, 'ALCONTADO', @Letras,
    @DocuSubTotal, @DocuIgv, @DocuTotal, 0,
    @DocuUsuario, 'EMITIDO', @DocuSerie, @TipoCodigo, @DocuAdicional,
    @DocuAsociado, @DocuConcepto, '', @DocuHASH, @EstadoSunat, @ICBPER,
    @CodigoSunat, @MensajeSunat, @DocuGravada, @DocuDescuento, '', @NotaFormaPago,
    @EntidadBancaria, @NroOperacion, @Efectivo, @Deposito,
    @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal,
    '', '', ''
)            
            
Set @DocuId= @@identity        
              
/*        
EFECTIVO        
DEPOSITO        
TARJETA        
YAPE        
EFECTIVO/DEPOSITO        
TARJETA/EFECTIVO        
YAPE/EFECTIVO        
YAPE/DEPOSITO        
TARJETA/DEPOSITO        
*/        
        
Declare @pZ1 int=0        
        
if(@NotaFormaPago='YAPE/DEPOSITO' or @NotaFormaPago='TARJETA/DEPOSITO')        
begin        
set @Movimiento='DEPOSITO'         
end        
else        
begin        
Declare @pZ2 int        
Declare @FormaA varchar(max),                      
        @FormaB varchar(max),        
        @MovimientoB varchar(40)        
                         
Set @pZ1 = CharIndex('/',@NotaFormaPago,0)        
        
if(@pZ1>0)        
begin        
        
Set @pZ2 =Len(@NotaFormaPago)+1        
Set @FormaA = SUBSTRING(@NotaFormaPago,1,@pZ1-1)        
Set @FormaB = SUBSTRING(@NotaFormaPago,@pZ1+1,@pZ2-@pZ1-1)        
        
if(@FormaA='EFECTIVO')set @Movimiento='INGRESO'                      
else if(@FormaA='DEPOSITO')set @Movimiento='DEPOSITO'                      
else if(@FormaA='YAPE' or @FormaA='PLIN' or @FormaA='PEDIDOSYA')set @Movimiento='DEPOSITO'                      
else set @Movimiento='TARJETA'         
        
if(@FormaB='EFECTIVO')set @MovimientoB='INGRESO'                      
else if(@FormaB='DEPOSITO')set @MovimientoB='DEPOSITO'                      
else if(@FormaB='YAPE' or @FormaB='PLIN' or @FormaB='PEDIDOSYA')set @MovimientoB='DEPOSITO'                      
else set @MovimientoB='TARJETA'         
        
END        
Else        
begin        
        
if(@NotaFormaPago='EFECTIVO')set @Movimiento='INGRESO'                      
else if(@NotaFormaPago='DEPOSITO')set @Movimiento='DEPOSITO'                      
else if(@NotaFormaPago='YAPE' OR @NotaFormaPago='PLIN' or @NotaFormaPago='PEDIDOSYA')set @Movimiento='DEPOSITO'                      
else set @Movimiento='TARJETA'         
        
End        
END      
              
   if(@NotaCondicion='CREDITO')        
   BEGIN          
   update NotaPedido               
   set CompaniaId=@CompaniaId,NotaSerie=@DocuSerie,              
   NotaNumero=@DocuNumero,NotaEstado='EMITIDO',NotaSaldo=@DocuTotal,NotaAcuenta=0,CajaId=@CajaId              
   where NotaId=@NotaId         
   end        
   Else        
   begin        
   if(@pZ1>0)        
begin        
    if(@Movimiento='INGRESO')        
    BEGIN        
    insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,@Movimiento,'',                      
    'TransacciÃ³n con '+@NotaFormaPago,@Efectivo,@Efectivo,0,'','T','',@DocuUsuario,'','')                      
    END        
    else        
    begin        
    insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,@Movimiento,'',                      
    'TransacciÃ³n con '+@NotaFormaPago,@Deposito,@Deposito,0,'','T','',@DocuUsuario,'','')         
    end        
    if(@MovimientoB='INGRESO')        
    BEGIN        
    insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,@MovimientoB,'',                      
    'TransacciÃ³n con '+@NotaFormaPago,@Efectivo,@Efectivo,0,'','T','',@DocuUsuario,'','')         
    END        
    ELSE        
    BEGIN        
    insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,@MovimientoB,'',                      
    'TransacciÃ³n con '+@NotaFormaPago,@Deposito,@Deposito,0,'','T','',@DocuUsuario,'','')         
    END                
END      
ELSE         
BEGIN       
    insert into CajaDetalle values(@CajaId,GETDATE(),@NotaId,@Movimiento,'',                      
    'TransacciÃ³n con '+@NotaFormaPago,@DocuTotal,@DocuTotal,0,'','T','',@DocuUsuario,'','')              
END      
           
   update NotaPedido               
   set CompaniaId=@CompaniaId,NotaSerie=@DocuSerie,              
   NotaNumero=@DocuNumero,NotaEstado='CANCELADO',NotaSaldo=0,NotaAcuenta=@DocuTotal,CajaId=@CajaId              
   where NotaId=@NotaId           
         
END      
        
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')               
Open Tabla              
Declare @Columna varchar(max),              
  @IdProducto numeric(20),              
  @Cantidad decimal(18,2),              
  @Costo decimal(18,4),              
  @Precio decimal(18,2),              
  @Importe decimal(18,2),              
  @DetalleNotaId numeric(38),              
  @UM varchar(80),              
  @ValorUM decimal(18,4),            
  @Descripcion varchar(300),
  @AplicaINV nvarchar(1),            
  @IniciaStock decimal(18,2),@StockFinal decimal(18,2)              
Declare @p1 int,@p2 int,@p3 int,@p4 int,              
        @p5 int,@p6 int,@p7 int,@p8 int,
        @p9 int,@p10 int             
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
Set @p8= CharIndex('|',@Columna,@p7+1)
Set @p9= CharIndex('|',@Columna,@p8+1)                
Set @p10= Len(@Columna)+1          
              
Set @DetalleNotaId=Convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))              
Set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))              
Set @Cantidad=Convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))              
Set @UM=SUBSTRING(@Columna,@p3+1,@p4-(@p3+1))              
Set @Costo=Convert(decimal(18,4),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))              
Set @Precio=Convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))              
Set @Importe=Convert(decimal(18,2),SUBSTRING(@Columna,@p6+1,@p7-(@p6+1)))              
Set @ValorUM=Convert(decimal(18,4),SUBSTRING(@Columna,@p7+1,@p8-(@p7+1)))            
Set @Descripcion=SUBSTRING(@Columna,@p8+1,@p9-(@p8+1))
Set @AplicaINV=SUBSTRING(@Columna,@p9+1,@p10-(@p9+1))            
               
Declare @CantidadSal decimal(18,2)          
                    
insert into DetalleDocumento               
values(@DocuId,@IdProducto,@Cantidad,@Precio,@Importe,            
@DetalleNotaId,@UM,@ValorUM,@Descripcion)              

if(@AplicaINV='S')          
  BEGIN            
   set @CantidadSal=@Cantidad * @ValorUM           
          
   set @IniciaStock=(select top 1 ProductoCantidad from Producto where IdProducto=@IdProducto)              
   set @StockFinal=@IniciaStock-@CantidadSal              
            
   insert into Kardex values(@IdProducto,GETDATE(),'Salida por Venta',@DocuSerie+'-'+@DocuNumero,@IniciaStock,              
   0,@CantidadSal,@Costo,@StockFinal,'SALIDA',@DocuUsuario)              
             
   update producto               
   set  ProductoCantidad =ProductoCantidad - @CantidadSal             
   where IDProducto=@IdProducto              
  End           
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
 --Commit Transaction;              
 --select 'true'  
if(len(@Guia)>0)    
begin    
Declare TablaB Cursor For Select * From fnSplitString(@Guia,';')     
Open TablaB    
Declare @ColumnaB varchar(max)  
Declare @g1 int,@g2 int,  
        @g3 int,@g4 int,@g5 int  
  
Declare @CantidadA decimal(18,2),   
        @IdProductoU numeric(20),                   
        @CantidadU decimal(18,2),                      
        @UmU varchar(40),                                                     
        @ValorUMU decimal(18,4)  
  
Declare @IniciaStockB decimal(18,2),  
        @StockFinalB decimal(18,2)  
            
Fetch Next From TablaB INTO @ColumnaB    
 While @@FETCH_STATUS = 0    
 Begin    
Set @g1 = CharIndex('|',@ColumnaB,0)                     
Set @g2 = CharIndex('|',@ColumnaB,@g1+1)                      
Set @g3 = CharIndex('|',@ColumnaB,@g2+1)                      
Set @g4 = CharIndex('|',@ColumnaB,@g3+1)                      
Set @g5=Len(@ColumnaB)+1     
   
set @CantidadA=Convert(decimal(18,2),SUBSTRING(@ColumnaB,1,@g1-1))  
Set @IdProductoU=Convert(numeric(20),SUBSTRING(@ColumnaB,@g1+1,@g2-(@g1+1)))  
Set @CantidadU=Convert(decimal(18,2),SUBSTRING(@ColumnaB,@g2+1,@g3-(@g2+1)))    
Set @UmU=SUBSTRING(@ColumnaB,@g3+1,@g4-(@g3+1))    
Set @ValorUMU=Convert(decimal(18,4),SUBSTRING(@ColumnaB,@g4+1,@g5-(@g4+1)))        
  
 Declare @CantidadSalB decimal(18,2)   
  
 set @CantidadSalB=(@CantidadA * @CantidadU)* @ValorUMU              
                  
 set @IniciaStockB=(select top 1 p.ProductoCantidad   
 from Producto p where p.IdProducto=@IdProductoU)                      
   
 set @StockFinalB=@IniciaStockB-@CantidadSalB                     
               
 insert into Kardex values(@IdProductoU,GETDATE(),'Salida por Venta',@DocuSerie+'-'+@DocuNumero,@IniciaStockB,                      
 0,@CantidadSalB,0,@StockFinalB,'SALIDA',@DocuUsuario)                      
                 
 update producto                       
 set  ProductoCantidad =ProductoCantidad - @CantidadSalB                     
 where IDProducto=@IdProductoU      
  
Fetch Next From TablaB INTO @ColumnaB    
end    
    Close TablaB;    
    Deallocate TablaB;    
    Commit Transaction;    
    select 'true'  
end    
else    
begin    
    Commit Transaction;    
    select 'true'  
end  
                
end              
end
GO

/*
Listo para copiar/pegar en produccion.
No guarda XML/CDR/PDF en estos flujos: DocuPdfUrl/DocuXmlUrl/DocuCdrUrl = ''.
Factura por servicio NO va aqui: ese flujo guarda XML/CDR desde backend.
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
Declare  @pos1 int,@pos2 int,@pos3 int,@pos4 int,      
         @pos5 int,@pos6 int,@pos7 int,@pos8 int,      
         @pos9 int,@pos10 int,@pos11 int,@pos12 int,      
         @pos13 int,@pos14 int,@pos15 int,@pos16 int,      
         @pos17 int,@pos18 int,@pos19 int,@pos20 int,      
         @pos21 int,@pos22 int,@pos23 int,@pos24 int,      
         @pos25 int      
 Declare @CompaniaId int,@NotaId numeric(38),@DocuDocumento varchar(60),      
         @DocuNumero varchar(60),@ClienteId numeric(20),@DocuEmision date,      
         @DocuSubTotal decimal(18,2),@DocuIgv decimal(18,2),@DocuTotal decimal(18,2),      
         @DocuUsuario varchar(60),@DocuSerie char(4),@TipoCodigo char(20),      
         @DocuAdicional decimal(18,2),@DocuAsociado varchar(80),@DocuConcepto varchar(80),      
         @DocuHASH varchar(250),@EstadoSunat varchar(80),@Letras varchar(60),      
         @DocuId numeric(38),@TraeEstado varchar(80),@NotaEstado varchar(80),      
         @ICBPER decimal(18,2),@CodigoSunat VARCHAR(80),@MensajeSunat varchar(max),
         @ClienteRazon varchar(140),@ClienteRuc varchar(40),
         @ClienteDni varchar(40),@DireccionFiscal varchar(max)      
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
Set @pos25= Len(@orden)+1
      
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
set @ICBPER=convert(decimal(18,2),SUBSTRING(@orden,@pos18+1,@pos19-@pos18-1))      
set @CodigoSunat=SUBSTRING(@orden,@pos19+1,@pos20-@pos19-1)      
set @MensajeSunat=SUBSTRING(@orden,@pos20+1,@pos21-@pos20-1)      

set @ClienteRazon=SUBSTRING(@orden,@pos21+1,@pos22-@pos21-1)          
set @ClienteRuc=SUBSTRING(@orden,@pos22+1,@pos23-@pos22-1) 
set @ClienteDni=SUBSTRING(@orden,@pos23+1,@pos24-@pos23-1)          
set @DireccionFiscal=SUBSTRING(@orden,@pos24+1,@pos25-@pos24-1)   

set @TraeEstado=(select top 1 n.NotaEstado from NotaPedido n where n.NotaId=@NotaId)      
if(@TraeEstado='PENDIENTE')set @NotaEstado='EMITIDO'      
else set @NotaEstado=@TraeEstado      

Begin Transaction      
INSERT INTO DocumentoVenta
(
    CompaniaId, NotaId, DocuDocumento, DocuNumero, ClienteId, DocuRegistro,
    DocuEmision, DocuCondicion, DocuLetras, DocuSubTotal, DocuIgv, DocuTotal,
    DocuSaldo, DocuUsuario, DocuEstado, DocuSerie, TipoCodigo, DocuAdicional,
    DocuAsociado, DocuConcepto, DocuNroGuia, DocuHash, EstadoSunat, ICBPER,
    CodigoSunat, MensajeSunat, DocuGravada, DocuDescuento, EnvioCorreo,
    FormaPago, EntidadBancaria, NroOperacion, Efectivo, Deposito,
    ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal,
    DocuPdfUrl, DocuXmlUrl, DocuCdrUrl
)
VALUES
(
    @CompaniaId, @NotaId, @DocuDocumento, @DocuNumero,
    @ClienteId, GETDATE(), @DocuEmision, 'ALCONTADO', 'CERO CON 00/100 SOLES',
    0, 0, 0, 0,
    @DocuUsuario, 'RECHAZADO', @DocuSerie, @TipoCodigo, 0,
    @DocuAsociado, @DocuConcepto, '', @DocuHASH, 'RECHAZADO', 0,
    @CodigoSunat, @MensajeSunat, 0, 0, '', 'EFECTIVO', '', '', 0, 0,
    @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal,
    '', '', ''
)

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
  @ValorUM decimal(18,4),    
  @Descripcion varchar(300)     
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
Set @DetalleNotaId=Convert(numeric(38),SUBSTRING(@Columna,1,@p1-1))      
Set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,@p1+1,@p2-(@p1+1)))      
Set @Cantidad=Convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))      
Set @UM=SUBSTRING(@Columna,@p3+1,@p4-(@p3+1))      
Set @Precio=Convert(decimal(18,2),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))      
Set @Importe=Convert(decimal(18,2),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))      
Set @ValorUM=Convert(decimal(18,4),SUBSTRING(@Columna,@p6+1,@p7-(@p6+1)))    
Set @Descripcion=SUBSTRING(@Columna,@p7+1,@p8-(@p7+1))    
      
insert into DetalleDocumento       
values(@DocuId,@IdProducto,@Cantidad,@Precio,@Importe,@DetalleNotaId,@UM,@ValorUM,@Descripcion)      
    
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

/*
Listo para copiar/pegar en produccion.
No guarda XML/CDR/PDF en estos flujos: DocuPdfUrl/DocuXmlUrl/DocuCdrUrl = ''.
Factura por servicio NO va aqui: ese flujo guarda XML/CDR desde backend.
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[uspinsertarNC]                
@ListaOrden varchar(Max)                
as                
begin                
  
Declare @posA1 int,@posA2 int,@posA3 int      
Declare @orden varchar(max),      
        @detalle varchar(max),      
        @Guia varchar(max)      
Set @posA1 = CharIndex('[',@ListaOrden,0)      
Set @posA2 = CharIndex('[',@ListaOrden,@posA1+1)      
Set @posA3 =Len(@ListaOrden)+1      
Set @orden = SUBSTRING(@ListaOrden,1,@posA1-1)      
Set @detalle = SUBSTRING(@ListaOrden,@posA1+1,@posA2-@posA1-1)      
Set @Guia=SUBSTRING(@ListaOrden,@posA2+1,@posA3-@posA2-1)   
               
Declare @pos1 int,@pos2 int,@pos3 int,@pos4 int,                
        @pos5 int,@pos6 int,@pos7 int,@pos8 int,                
        @pos9 int,@pos10 int,@pos11 int,@pos12 int,                
        @pos13 int,@pos14 int,@pos15 int,@pos16 int,                
        @pos17 int,@pos18 int,@pos19 int,@pos20 int,                
        @pos21 int,@pos22 int,@pos23 int,@pos24 int,        
        @pos25 int,@pos26 int,@pos27 int,@pos28 int,    
        @pos29 int,@pos30 int,@pos31 int,@pos32 int,@pos33 int              
Declare @CompaniaId int,@NotaId numeric(38),@DocuDocumento varchar(60),                
        @DocuNumero varchar(60),@ClienteId numeric(20),@DocuEmision date,                
        @DocuSubTotal decimal(18,2),@DocuIgv decimal(18,2),@DocuTotal decimal(18,2),                
        @DocuUsuario varchar(60),@DocuSerie char(4),@TipoCodigo varchar(10),                
        @DocuAdicional decimal(18,2),@DocuAsociado varchar(80),@DocuConcepto varchar(80),                
        @DocuHASH varchar(250),@EstadoSunat varchar(80),@Letras varchar(60),@NroReferencia varchar(80),                
        @DocuId numeric(38),@KardexDocu varchar(80),@ICBPER decimal(18,2),                
        @CodigoSunat VARCHAR(80),@MensajeSunat varchar(max),                
        @DocuGravada decimal(18,2),@DocuDescuento decimal(18,2),        
        @Efectivo decimal(18,2),@Deposito decimal(18,2),@ClienteRazon varchar(140),    
        @ClienteRuc varchar(40),@ClienteDni varchar(40),@DireccionFiscal varchar(max),      
        @FormaPago varchar(60),@EntidadBancaria varchar(80),@NroOperacion varchar(80)             
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
set @ICBPER=convert(decimal(18,2),SUBSTRING(@orden,@pos19+1,@pos20-@pos19-1))                
set @CodigoSunat=SUBSTRING(@orden,@pos20+1,@pos21-@pos20-1)                
set @MensajeSunat=SUBSTRING(@orden,@pos21+1,@pos22-@pos21-1)                
set @DocuGravada=convert(decimal(18,2),SUBSTRING(@orden,@pos22+1,@pos23-@pos22-1))                
set @DocuDescuento=convert(decimal(18,2),SUBSTRING(@orden,@pos23+1,@pos24-@pos23-1))        
set @Efectivo=convert(decimal(18,2),SUBSTRING(@orden,@pos24+1,@pos25-@pos24-1))                
set @Deposito=convert(decimal(18,2),SUBSTRING(@orden,@pos25+1,@pos26-@pos25-1))      
set @ClienteRazon=SUBSTRING(@orden,@pos26+1,@pos27-@pos26-1)                
set @ClienteRuc=SUBSTRING(@orden,@pos27+1,@pos28-@pos27-1)       
set @ClienteDni=SUBSTRING(@orden,@pos28+1,@pos29-@pos28-1)                
set @DireccionFiscal=SUBSTRING(@orden,@pos29+1,@pos30-@pos29-1)      
set @FormaPago=SUBSTRING(@orden,@pos30+1,@pos31-@pos30-1)    
set @EntidadBancaria=SUBSTRING(@orden,@pos31+1,@pos32-@pos31-1)      
set @NroOperacion=SUBSTRING(@orden,@pos32+1,@pos33-@pos32-1)            
               
Begin Transaction                
 INSERT INTO DocumentoVenta
(
    CompaniaId, NotaId, DocuDocumento, DocuNumero, ClienteId, DocuRegistro,
    DocuEmision, DocuCondicion, DocuLetras, DocuSubTotal, DocuIgv, DocuTotal,
    DocuSaldo, DocuUsuario, DocuEstado, DocuSerie, TipoCodigo, DocuAdicional,
    DocuAsociado, DocuConcepto, DocuNroGuia, DocuHash, EstadoSunat, ICBPER,
    CodigoSunat, MensajeSunat, DocuGravada, DocuDescuento, EnvioCorreo,
    FormaPago, EntidadBancaria, NroOperacion, Efectivo, Deposito,
    ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal,
    DocuPdfUrl, DocuXmlUrl, DocuCdrUrl
)
VALUES
(
    @CompaniaId, @NotaId, @DocuDocumento, @DocuNumero,
    @ClienteId, GETDATE(), @DocuEmision, 'ALCONTADO', @Letras,
    @DocuSubTotal, @DocuIgv, @DocuTotal, 0,
    @DocuUsuario, 'EMITIDO', @DocuSerie, @TipoCodigo, @DocuAdicional,
    @DocuAsociado, @DocuConcepto, @NroReferencia, @DocuHASH, @EstadoSunat, @ICBPER,
    @CodigoSunat, @MensajeSunat, @DocuGravada, @DocuDescuento, '', @FormaPago,
    @EntidadBancaria, @NroOperacion, @Efectivo, @Deposito,
    @ClienteRazon, @ClienteRuc, @ClienteDni, @DireccionFiscal,
    '', '', ''
)             
                
 Set @DocuId= @@identity                
 set @KardexDocu=@DocuSerie+'-'+@DocuNumero                
               
 Update DocumentoVenta                
 set DocuAsociado=@DocuId                
 where DocuId=@DocuAsociado                
               
 update NotaPedido                
 set NotaEstado='ANULADO',NotaSaldo=@DocuTotal,NotaAcuenta=0                
 where NotaId=@NotaId      
                
Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')                 
Open Tabla                
Declare @Columna varchar(max),                
  @IdProducto numeric(20),                
  @Cantidad decimal(18,2),    
  @Costo decimal(18,4),                
  @Precio decimal(18,2),                
  @Importe decimal(18,2),                
  @DetalleNotaId numeric(38),                
  @UM varchar(80),                
  @ValorUM decimal(18,4),              
  @Descripcion varchar(300),  
  @AplicaINV nvarchar(1),             
  @StockInicial decimal(18,2),                
  @StockFinal decimal(18,2),@CantidadIng decimal(18,2)                
Declare @p1 int,@p2 int,@p3 int,@p4 int,                
        @p5 int,@p6 int,@p7 int,@p8 int,
        @p9 int,@p10 int              
                        
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
Set @p8= CharIndex('|',@Columna,@p7+1)
Set @p9= CharIndex('|',@Columna,@p8+1)                 
Set @p10= Len(@Columna)+1                
              
Set @Cantidad=Convert(decimal(18,2),SUBSTRING(@Columna,1,@p1-1))                
Set @UM=SUBSTRING(@Columna,@p1+1,@p2-(@p1+1))            
Set @Descripcion=SUBSTRING(@Columna,@p2+1,@p3-(@p2+1))                 
Set @Precio=Convert(decimal(18,2),SUBSTRING(@Columna,@p3+1,@p4-(@p3+1)))                
Set @Importe=Convert(decimal(18,2),SUBSTRING(@Columna,@p4+1,@p5-(@p4+1)))                
Set @DetalleNotaId=Convert(numeric(38),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))                
Set @IdProducto=Convert(numeric(20),SUBSTRING(@Columna,@p6+1,@p7-(@p6+1)))                
Set @ValorUM=Convert(decimal(18,4),SUBSTRING(@Columna,@p7+1,@p8-(@p7+1)))                
Set @Costo=Convert(decimal(18,4),SUBSTRING(@Columna,@p8+1,@p9-(@p8+1)))
Set @AplicaINV=SUBSTRING(@Columna,@p9+1,@p10-(@p9+1))               
                         
insert into DetalleDocumento                 
values(@DocuId,@IdProducto,@Cantidad,@Precio,@Importe,              
@DetalleNotaId,@UM,@ValorUM,@Descripcion)              

if(@AplicaINV='S')
BEGIN               
set @StockInicial=(select top 1 ProductoCantidad from Producto(nolock)                 
where IdProducto=@IdProducto)              
               
set @CantidadIng=(@Cantidad*@ValorUM)         
set @StockFinal=@StockInicial+@CantidadIng                
              
update Producto                
set ProductoCantidad=ProductoCantidad+@CantidadIng                
where IdProducto=@IdProducto              
                 
insert into Kardex                
values(@IdProducto,GETDATE(),'Ingreso por N-Credito',@KardexDocu,@StockInicial,                
@CantidadIng,0,@Costo,@StockFinal,'INGRESO',@DocuUsuario)
End             
                
Fetch Next From Tabla INTO @Columna                
end                
 Close Tabla;                
 Deallocate Tabla;                
 delete from CajaDetalle                
 where NotaId=@NotaId                
 --Commit Transaction;                
 --SELECT 'true'    
if(len(@Guia)>0)      
begin      
Declare TablaB Cursor For Select * From fnSplitString(@Guia,';')       
Open TablaB      
Declare @ColumnaB varchar(max)    
Declare @g1 int,@g2 int,    
        @g3 int,@g4 int,@g5 int    
    
Declare @CantidadA decimal(18,2),     
        @IdProductoU numeric(20),                     
        @CantidadU decimal(18,2),                        
        @UmU varchar(40),                                                       
        @ValorUMU decimal(18,4)    
    
Declare @IniciaStockB decimal(18,2),    
        @StockFinalB decimal(18,2)    
              
Fetch Next From TablaB INTO @ColumnaB      
 While @@FETCH_STATUS = 0      
 Begin      
Set @g1 = CharIndex('|',@ColumnaB,0)                       
Set @g2 = CharIndex('|',@ColumnaB,@g1+1)                        
Set @g3 = CharIndex('|',@ColumnaB,@g2+1)                        
Set @g4 = CharIndex('|',@ColumnaB,@g3+1)                        
Set @g5=Len(@ColumnaB)+1       
     
set @CantidadA=Convert(decimal(18,2),SUBSTRING(@ColumnaB,1,@g1-1))    
Set @IdProductoU=Convert(numeric(20),SUBSTRING(@ColumnaB,@g1+1,@g2-(@g1+1)))    
Set @CantidadU=Convert(decimal(18,2),SUBSTRING(@ColumnaB,@g2+1,@g3-(@g2+1)))      
Set @UmU=SUBSTRING(@ColumnaB,@g3+1,@g4-(@g3+1))      
Set @ValorUMU=Convert(decimal(18,4),SUBSTRING(@ColumnaB,@g4+1,@g5-(@g4+1)))          
    
 Declare @CantidadSalB decimal(18,2)     
    
 set @CantidadSalB=(@CantidadA * @CantidadU)* @ValorUMU                
                    
 set @IniciaStockB=(select top 1 p.ProductoCantidad     
 from Producto p where p.IdProducto=@IdProductoU)                        
     
 set @StockFinalB=@IniciaStockB + @CantidadSalB                       
                 
 insert into Kardex values(@IdProductoU,GETDATE(),'Ingreso por N-Credito',@KardexDocu,@IniciaStockB,              
 @CantidadSalB,0,0,@StockFinalB,'INGRESO',@DocuUsuario)                          
                   
 update producto                         
 set  ProductoCantidad =ProductoCantidad + @CantidadSalB                       
 where IDProducto=@IdProductoU        
    
Fetch Next From TablaB INTO @ColumnaB      
end      
    Close TablaB;      
    Deallocate TablaB;      
    Commit Transaction;      
    select 'true'    
end      
else      
begin      
    Commit Transaction;      
    select 'true'    
end   
                
end
GO

/*
Listo para copiar/pegar en produccion.
No guarda XML/CDR/PDF en estos flujos: DocuPdfUrl/DocuXmlUrl/DocuCdrUrl = ''.
Factura por servicio NO va aqui: ese flujo guarda XML/CDR desde backend.
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[uspinsertarNotaB]
@ListaOrden varchar(Max)
AS
BEGIN
Declare @pos1 int,@pos2 int,@pos3 int
Declare @orden varchar(max),
        @detalle varchar(max),
        @Guia varchar(max)
Set @pos1 = CharIndex('[',@ListaOrden,0)
Set @pos2 = CharIndex('[',@ListaOrden,@pos1+1)
Set @pos3 = Len(@ListaOrden)+1
Set @orden = SUBSTRING(@ListaOrden,1,@pos1-1)
Set @detalle = SUBSTRING(@ListaOrden,@pos1+1,@pos2-@pos1-1)
Set @Guia = SUBSTRING(@ListaOrden,@pos2+1,@pos3-@pos2-1)

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
        @c41 int,@c42 int

Declare
  @NotaDocu varchar(60),@ClienteId numeric(20),
  @NotaUsuario varchar(60),@NotaFormaPago varchar(60),
  @NotaCondicion varchar(60),@NotaDireccion varchar(max),
  @NotaTelefono varchar(60),@NotaSubtotal decimal(18,2),
  @NotaMovilidad decimal(18,2),@NotaDescuento decimal(18,2),
  @NotaTotal decimal(18,2),@NotaAcuenta decimal(18,2),
  @NotaSaldo decimal(18,2),@NotaAdicional decimal(18,2),
  @NotaTarjeta decimal(18,2),@NotaPagar decimal(18,2),
  @NotaEstado varchar(60),@CompaniaId int,
  @NotaEntrega varchar(40),@NotaConcepto varchar(60),
  @Serie varchar(20),@Numero varchar(60),
  @NotaGanancia decimal(18,2),@Letra varchar(max),
  @DocuAdicional decimal(18,2),@DocuHash varchar(250),
  @EstadoSunat varchar(80),@DocuSubtotal decimal(18,2),
  @DocuIGV decimal(18,2),@UsuarioId int,@ICBPER decimal(18,2),
  @DocuGravada decimal(18,2),@DocuDescuento decimal(18,2),
  @CajaId varchar(38),@Movimiento varchar(40),@KARDEX varchar(1),
  @NotaIdBR varchar(38),@EntidadBancaria varchar(80),
  @NroOperacion varchar(80),@Efectivo decimal(18,2),
  @Deposito decimal(18,2),@ClienteRazon varchar(140),
  @ClienteRuc varchar(40),@ClienteDni varchar(40),
  @DireccionFiscal varchar(max)

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
Set @c11 = CharIndex('|',@orden,@c10+1)
Set @c12 = CharIndex('|',@orden,@c11+1)
Set @c13 = CharIndex('|',@orden,@c12+1)
Set @c14 = CharIndex('|',@orden,@c13+1)
Set @c15 = CharIndex('|',@orden,@c14+1)
Set @c16 = CharIndex('|',@orden,@c15+1)
Set @c17 = CharIndex('|',@orden,@c16+1)
Set @c18 = CharIndex('|',@orden,@c17+1)
Set @c19 = CharIndex('|',@orden,@c18+1)
Set @c20 = CharIndex('|',@orden,@c19+1)
Set @c21 = CharIndex('|',@orden,@c20+1)
Set @c22 = CharIndex('|',@orden,@c21+1)
Set @c23 = CharIndex('|',@orden,@c22+1)
Set @c24 = CharIndex('|',@orden,@c23+1)
Set @c25 = CharIndex('|',@orden,@c24+1)
Set @c26 = CharIndex('|',@orden,@c25+1)
Set @c27 = CharIndex('|',@orden,@c26+1)
Set @c28 = CharIndex('|',@orden,@c27+1)
Set @c29 = CharIndex('|',@orden,@c28+1)
Set @c30 = CharIndex('|',@orden,@c29+1)
Set @c31 = CharIndex('|',@orden,@c30+1)
Set @c32 = CharIndex('|',@orden,@c31+1)
Set @c33 = CharIndex('|',@orden,@c32+1)
Set @c34 = CharIndex('|',@orden,@c33+1)
Set @c35 = CharIndex('|',@orden,@c34+1)
Set @c36 = CharIndex('|',@orden,@c35+1)
Set @c37 = CharIndex('|',@orden,@c36+1)
Set @c38 = CharIndex('|',@orden,@c37+1)
Set @c39 = CharIndex('|',@orden,@c38+1)
Set @c40 = CharIndex('|',@orden,@c39+1)
Set @c41 = CharIndex('|',@orden,@c40+1)
Set @c42 = Len(@orden)+1

set @NotaDocu = SUBSTRING(@orden,1,@c1-1)
set @ClienteId = convert(numeric(20),SUBSTRING(@orden,@c1+1,@c2-@c1-1))
set @NotaUsuario = SUBSTRING(@orden,@c2+1,@c3-@c2-1)
set @NotaFormaPago = SUBSTRING(@orden,@c3+1,@c4-@c3-1)
set @NotaCondicion = SUBSTRING(@orden,@c4+1,@c5-@c4-1)
set @NotaDireccion = SUBSTRING(@orden,@c5+1,@c6-@c5-1)
set @NotaTelefono = SUBSTRING(@orden,@c6+1,@c7-@c6-1)
set @NotaSubtotal = convert(decimal(18,2),SUBSTRING(@orden,@c7+1,@c8-@c7-1))
set @NotaMovilidad = convert(decimal(18,2),SUBSTRING(@orden,@c8+1,@c9-@c8-1))
set @NotaDescuento = convert(decimal(18,2),SUBSTRING(@orden,@c9+1,@c10-@c9-1))
set @NotaTotal = convert(decimal(18,2),SUBSTRING(@orden,@c10+1,@c11-@c10-1))
set @NotaAcuenta = convert(decimal(18,2),SUBSTRING(@orden,@c11+1,@c12-@c11-1))
set @NotaSaldo = convert(decimal(18,2),SUBSTRING(@orden,@c12+1,@c13-@c12-1))
set @NotaAdicional = convert(decimal(18,2),SUBSTRING(@orden,@c13+1,@c14-@c13-1))
set @NotaTarjeta = convert(decimal(18,2),SUBSTRING(@orden,@c14+1,@c15-@c14-1))
set @NotaPagar = convert(decimal(18,2),SUBSTRING(@orden,@c15+1,@c16-@c15-1))
set @NotaEstado = SUBSTRING(@orden,@c16+1,@c17-@c16-1)
set @CompaniaId = convert(int,SUBSTRING(@orden,@c17+1,@c18-@c17-1))
set @NotaEntrega = SUBSTRING(@orden,@c18+1,@c19-@c18-1)
set @NotaConcepto = SUBSTRING(@orden,@c19+1,@c20-@c19-1)
set @Serie = SUBSTRING(@orden,@c20+1,@c21-@c20-1)
set @Numero = SUBSTRING(@orden,@c21+1,@c22-@c21-1)
set @NotaGanancia = convert(decimal(18,2),SUBSTRING(@orden,@c22+1,@c23-@c22-1))
set @Letra = SUBSTRING(@orden,@c23+1,@c24-@c23-1)
set @DocuAdicional = convert(decimal(18,2),SUBSTRING(@orden,@c24+1,@c25-@c24-1))
set @DocuHash = SUBSTRING(@orden,@c25+1,@c26-@c25-1)
set @EstadoSunat = SUBSTRING(@orden,@c26+1,@c27-@c26-1)
set @DocuSubtotal = convert(decimal(18,2),SUBSTRING(@orden,@c27+1,@c28-@c27-1))
set @DocuIGV = convert(decimal(18,2),SUBSTRING(@orden,@c28+1,@c29-@c28-1))
set @UsuarioId = convert(int,SUBSTRING(@orden,@c29+1,@c30-@c29-1))
set @ICBPER = convert(decimal(18,2),SUBSTRING(@orden,@c30+1,@c31-@c30-1))
set @DocuGravada = convert(decimal(18,2),SUBSTRING(@orden,@c31+1,@c32-@c31-1))
set @DocuDescuento = convert(decimal(18,2),SUBSTRING(@orden,@c32+1,@c33-@c32-1))
set @NotaIdBR = SUBSTRING(@orden,@c33+1,@c34-@c33-1)
set @EntidadBancaria = SUBSTRING(@orden,@c34+1,@c35-@c34-1)
set @NroOperacion = SUBSTRING(@orden,@c35+1,@c36-@c35-1)
set @Efectivo = convert(decimal(18,2),SUBSTRING(@orden,@c36+1,@c37-@c36-1))
set @Deposito = convert(decimal(18,2),SUBSTRING(@orden,@c37+1,@c38-@c37-1))
set @ClienteRazon = SUBSTRING(@orden,@c38+1,@c39-@c38-1)
set @ClienteRuc = SUBSTRING(@orden,@c39+1,@c40-@c39-1)
set @ClienteDni = SUBSTRING(@orden,@c40+1,@c41-@c40-1)
set @DireccionFiscal = SUBSTRING(@orden,@c41+1,@c42-@c41-1)

if(@NotaIdBR='') set @NotaIdBR = 0

IF EXISTS(
    select top 1 n.NotaId
    from NotaPedido n
    where n.NotaId = @NotaIdBR
)
begin
    select 'EXISTE'
end
else
begin
    if(@NotaDocu='FACTURA')
    begin
        -- FACTURA debe comportarse igual que BOLETA:
        -- - Si es CREDITO => EMITIDO con saldo
        -- - Si es ALCONTADO => CANCELADO con saldo 0
        if(@NotaCondicion='CREDITO')
        begin
            set @NotaEstado='EMITIDO'
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
    else if(@NotaDocu='PROFORMA')
        set @NotaEstado='PENDIENTE'
    else
    begin
        if(@NotaCondicion='CREDITO')
        begin
            set @NotaEstado='EMITIDO'
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

    Declare @pZ1 int = 0

    if(@NotaFormaPago='YAPE/DEPOSITO' or @NotaFormaPago='TARJETA/DEPOSITO')
    begin
        set @Movimiento='DEPOSITO'
    end
    else
    begin
        Declare @pZ2 int
        Declare @FormaA varchar(max),
                @FormaB varchar(max),
                @MovimientoB varchar(40)

        Set @pZ1 = CharIndex('/',@NotaFormaPago,0)

        if(@pZ1>0)
        begin
            Set @pZ2 = Len(@NotaFormaPago)+1
            Set @FormaA = SUBSTRING(@NotaFormaPago,1,@pZ1-1)
            Set @FormaB = SUBSTRING(@NotaFormaPago,@pZ1+1,@pZ2-@pZ1-1)

            if(@FormaA='EFECTIVO') set @Movimiento='INGRESO'
            else if(@FormaA='DEPOSITO') set @Movimiento='DEPOSITO'
            else if(@FormaA='YAPE' OR @FormaA='PLIN') set @Movimiento='DEPOSITO'
            else set @Movimiento='TARJETA'

            if(@FormaB='EFECTIVO') set @MovimientoB='INGRESO'
            else if(@FormaB='DEPOSITO') set @MovimientoB='DEPOSITO'
            else if(@FormaB='YAPE' OR @FormaB='PLIN') set @MovimientoB='DEPOSITO'
            else set @MovimientoB='TARJETA'
        end
        else
        begin
            if(@NotaFormaPago='EFECTIVO') set @Movimiento='INGRESO'
            else if(@NotaFormaPago='DEPOSITO') set @Movimiento='DEPOSITO'
            else if(@NotaFormaPago='TRANSFERENCIA') set @Movimiento='DEPOSITO'
            else if(@NotaFormaPago='YAPE' OR @NotaFormaPago='PLIN') set @Movimiento='DEPOSITO'
            else set @Movimiento='TARJETA'
        end
    end

    declare @NotaId numeric(38),
            @DocuId numeric(38) = 0

    Begin Transaction

    update Cliente
    set ClienteDespacho=@NotaDireccion,ClienteTelefono=@NotaTelefono
    where ClienteId=@ClienteId

    delete from TemporalVenta
    where UsuarioID=@UsuarioId

    declare @cod varchar(13)

    SET @cod = ISNULL((
        select top 1 dbo.genenerarNroFactura(@Serie,@CompaniaId,@NotaDocu) AS ID
        FROM DocumentoVenta
    ),'00000001')

    insert into NotaPedido (
        NotaDocu,
        ClienteId,
        NotaFecha,
        NotaUsuario,
        NotaFormaPago,
        NotaCondicion,
        NotaFechaPago,
        NotaDireccion,
        NotaTelefono,
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
        ICBPER,
        CajaId,
        EntidadBancaria,
        NroOperacion,
        Efectivo,
        Deposito
    )
    VALUES (
        @NotaDocu,
        @ClienteId,
        GETDATE(),
        @NotaUsuario,
        @NotaFormaPago,
        @NotaCondicion,
        GETDATE(),
        @NotaDireccion,
        @NotaTelefono,
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
        @ICBPER,
        @CajaId,
        @EntidadBancaria,
        @NroOperacion,
        @Efectivo,
        @Deposito
    )

    set @NotaId = (select @@IDENTITY)

    if (@NotaDocu='PROFORMA V')
    begin
        insert into DocumentoVenta (
            CompaniaId, NotaId, DocuDocumento, DocuNumero, ClienteId, DocuRegistro,
            DocuEmision, DocuCondicion, DocuLetras, DocuSubTotal, DocuIgv, DocuTotal,
            DocuSaldo, DocuUsuario, DocuEstado, DocuSerie, TipoCodigo, DocuAdicional,
            DocuAsociado, DocuConcepto, DocuNroGuia, DocuHash, EstadoSunat, ICBPER,
            CodigoSunat, MensajeSunat, DocuGravada, DocuDescuento, EnvioCorreo,
            FormaPago, EntidadBancaria, NroOperacion, Efectivo, Deposito,
            ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal,
            DocuPdfUrl, DocuXmlUrl, DocuCdrUrl
        ) values
        (@CompaniaId,@NotaId,'PROFORMA V',@cod,@ClienteId,GETDATE(),
         GETDATE(),@NotaCondicion,@Letra,@DocuSubtotal,
         @DocuIGV,@NotaPagar,0,@NotaUsuario,'EMITIDO',@Serie,'00',@NotaMovilidad,'','VENTA','',
         @DocuHash,'ENVIADO',
         @ICBPER,'','',@DocuGravada,@DocuDescuento,'',@NotaFormaPago,@EntidadBancaria,
         @NroOperacion,@Efectivo,@Deposito,@ClienteRazon,@ClienteRuc,@ClienteDni,@DireccionFiscal,
         '', '', '')

        set @DocuId = (select @@IDENTITY)

        if(@NotaCondicion<>'CREDITO')
        begin
            if(@pZ1>0)
            begin
                set @KARDEX='S'
            end
            else
            begin
                set @KARDEX='S'
            end
        end
    end
    else if(@NotaDocu='FACTURA')
    begin
        insert into DocumentoVenta (
            CompaniaId, NotaId, DocuDocumento, DocuNumero, ClienteId, DocuRegistro,
            DocuEmision, DocuCondicion, DocuLetras, DocuSubTotal, DocuIgv, DocuTotal,
            DocuSaldo, DocuUsuario, DocuEstado, DocuSerie, TipoCodigo, DocuAdicional,
            DocuAsociado, DocuConcepto, DocuNroGuia, DocuHash, EstadoSunat, ICBPER,
            CodigoSunat, MensajeSunat, DocuGravada, DocuDescuento, EnvioCorreo,
            FormaPago, EntidadBancaria, NroOperacion, Efectivo, Deposito,
            ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal,
            DocuPdfUrl, DocuXmlUrl, DocuCdrUrl
        ) values
        (@CompaniaId,@NotaId,'FACTURA',@cod,@ClienteId,GETDATE(),
         GETDATE(),@NotaCondicion,@Letra,@DocuSubtotal,
         @DocuIGV,@NotaPagar,0,@NotaUsuario,'EMITIDO',@Serie,'01',@DocuAdicional,'','VENTA','',
         @DocuHash,@EstadoSunat,
         @ICBPER,'','',@DocuGravada,@DocuDescuento,'',
         @NotaFormaPago,@EntidadBancaria,@NroOperacion,@Efectivo,@Deposito,
         @ClienteRazon,@ClienteRuc,@ClienteDni,@DireccionFiscal,
         '', '', '')

        set @DocuId = (select @@IDENTITY)

        if(@NotaConcepto='MERCADERIA')
        begin
            if(@NotaCondicion<>'CREDITO')
            begin
                if(@pZ1>0)
                begin
                    set @KARDEX='S'
                end
                else
                begin
                    set @KARDEX='S'
                end
            end
        end
    end
    else if(@NotaDocu='BOLETA')
    begin
        insert into DocumentoVenta (
            CompaniaId, NotaId, DocuDocumento, DocuNumero, ClienteId, DocuRegistro,
            DocuEmision, DocuCondicion, DocuLetras, DocuSubTotal, DocuIgv, DocuTotal,
            DocuSaldo, DocuUsuario, DocuEstado, DocuSerie, TipoCodigo, DocuAdicional,
            DocuAsociado, DocuConcepto, DocuNroGuia, DocuHash, EstadoSunat, ICBPER,
            CodigoSunat, MensajeSunat, DocuGravada, DocuDescuento, EnvioCorreo,
            FormaPago, EntidadBancaria, NroOperacion, Efectivo, Deposito,
            ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal,
            DocuPdfUrl, DocuXmlUrl, DocuCdrUrl
        ) values
        (@CompaniaId,@NotaId,'BOLETA',@cod,@ClienteId,GETDATE(),
         GETDATE(),@NotaCondicion,@Letra,@DocuSubtotal,
         @DocuIGV,@NotaPagar,0,@NotaUsuario,'EMITIDO',@Serie,'03',@NotaMovilidad,'','VENTA','',
         @DocuHash,@EstadoSunat,
         @ICBPER,'','',@DocuGravada,@DocuDescuento,'',
         @NotaFormaPago,@EntidadBancaria,@NroOperacion,@Efectivo,@Deposito,
         @ClienteRazon,@ClienteRuc,@ClienteDni,@DireccionFiscal,
         '', '', '')

        set @DocuId = (select @@IDENTITY)

        if(@NotaConcepto='MERCADERIA')
        begin
            if(@NotaCondicion<>'CREDITO')
            begin
                if(@pZ1>0)
                begin
                    set @KARDEX='S'
                end
                else
                begin
                    set @KARDEX='S'
                end
            end
        end
    end

    Declare Tabla Cursor For Select * From fnSplitString(@detalle,';')
    Open Tabla

    Declare @Columna varchar(max),
      @IdProducto numeric(20),
      @CodigoPro varchar(200),
      @DetalleCantidad decimal(18,2),
      @DetalleUm varchar(40),
      @Descripcion varchar(140),
      @DetalleCosto decimal(18,4),
      @DetallePrecio decimal(18,2),
      @DetalleImporte decimal(18,2),
      @DetalleEstado varchar(60),
      @AplicaINV nvarchar(1),
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
        Set @p6 = CharIndex('|',@Columna,@p5+1)
        Set @p7 = CharIndex('|',@Columna,@p6+1)
        Set @p8 = CharIndex('|',@Columna,@p7+1)
        Set @p9 = CharIndex('|',@Columna,@p8+1)
        Set @p10 = CharIndex('|',@Columna,@p9+1)
        Set @p11 = Len(@Columna)+1

        set @IdProducto = Convert(numeric(20),SUBSTRING(@Columna,1,@p1-1))
        Set @CodigoPro = SUBSTRING(@Columna,@p1+1,@p2-(@p1+1))
        Set @DetalleCantidad = convert(decimal(18,2),SUBSTRING(@Columna,@p2+1,@p3-(@p2+1)))
        Set @DetalleUm = SUBSTRING(@Columna,@p3+1,@p4-(@p3+1))
        Set @Descripcion = SUBSTRING(@Columna,@p4+1,@p5-(@p4+1))
        Set @DetalleCosto = convert(decimal(18,4),SUBSTRING(@Columna,@p5+1,@p6-(@p5+1)))
        Set @DetallePrecio = convert(decimal(18,2),SUBSTRING(@Columna,@p6+1,@p7-(@p6+1)))
        Set @DetalleImporte = convert(decimal(18,2),SUBSTRING(@Columna,@p7+1,@p8-(@p7+1)))
        Set @DetalleEstado = SUBSTRING(@Columna,@p8+1,@p9-(@p8+1))
        set @ValorUM = convert(decimal(18,4),SUBSTRING(@Columna,@p9+1,@p10-(@p9+1)))
        set @AplicaINV = SUBSTRING(@Columna,@p10+1,@p11-(@p10+1))

        Declare @CantidadSal decimal(18,2)

        if(@NotaEntrega='INMEDIATA')
            Set @CantidadSaldo=0
        else
            Set @CantidadSaldo=@DetalleCantidad

        insert into DetallePedido values(@NotaId,@IdProducto,@DetalleCantidad,
        @DetalleUm,@Descripcion,@DetalleCosto,@DetallePrecio,
        @DetalleImporte,@DetalleEstado,@CantidadSaldo,@ValorUM)

        if(@DocuId<>0)
        begin
            insert into DetalleDocumento values
            (@DocuId,@IdProducto,@DetalleCantidad,@DetallePrecio,@DetalleImporte,
             @NotaId,@DetalleUm,@ValorUM,@Descripcion)
        end

        if(@KARDEX='S')
        BEGIN
            if(@AplicaINV='S')
            BEGIN
                set @CantidadSal = @DetalleCantidad * @ValorUM
                set @IniciaStock = (select top 1 ProductoCantidad from Producto where IdProducto=@IdProducto)
                set @StockFinal = @IniciaStock-@CantidadSal

                insert into Kardex values(@IdProducto,GETDATE(),'Salida por Venta',@Serie+'-'+@cod,@IniciaStock,
                 0,@CantidadSal,@DetalleCosto,@StockFinal,'SALIDA',@NotaUsuario)

                update producto
                set ProductoCantidad = ProductoCantidad - @CantidadSal
                where IDProducto=@IdProducto
            End
        END

        Fetch Next From Tabla INTO @Columna
    end

    Close Tabla;
    Deallocate Tabla;

    if(len(@Guia)>0 AND @NotaEstado<>'PENDIENTE')
    begin
        Declare TablaB Cursor For Select * From fnSplitString(@Guia,';')
        Open TablaB

        Declare @ColumnaB varchar(max)
        Declare @g1 int,@g2 int,@g3 int,@g4 int,@g5 int

        Declare @CantidadA decimal(18,2),
                @IdProductoU numeric(20),
                @CantidadU decimal(18,2),
                @Um varchar(40),
                @ValorUMU decimal(18,4)

        Declare @IniciaStockB decimal(18,2),
                @StockFinalB decimal(18,2)

        Fetch Next From TablaB INTO @ColumnaB
        While @@FETCH_STATUS = 0
        Begin
            Set @g1 = CharIndex('|',@ColumnaB,0)
            Set @g2 = CharIndex('|',@ColumnaB,@g1+1)
            Set @g3 = CharIndex('|',@ColumnaB,@g2+1)
            Set @g4 = CharIndex('|',@ColumnaB,@g3+1)
            Set @g5 = Len(@ColumnaB)+1

            set @CantidadA = Convert(decimal(18,2),SUBSTRING(@ColumnaB,1,@g1-1))
            Set @IdProductoU = Convert(numeric(20),SUBSTRING(@ColumnaB,@g1+1,@g2-(@g1+1)))
            Set @CantidadU = Convert(decimal(18,2),SUBSTRING(@ColumnaB,@g2+1,@g3-(@g2+1)))
            Set @Um = SUBSTRING(@ColumnaB,@g3+1,@g4-(@g3+1))
            Set @ValorUMU = Convert(decimal(18,4),SUBSTRING(@ColumnaB,@g4+1,@g5-(@g4+1)))

            Declare @CantidadSalB decimal(18,2)

            set @CantidadSalB = (@CantidadA * @CantidadU) * @ValorUMU
            set @IniciaStockB = (select top 1 p.ProductoCantidad from Producto p where p.IdProducto=@IdProductoU)
            set @StockFinalB = @IniciaStockB-@CantidadSalB

            insert into Kardex values(@IdProductoU,GETDATE(),'Salida por Venta',@Serie+'-'+@cod,@IniciaStockB,
             0,@CantidadSalB,0,@StockFinalB,'SALIDA',@NotaUsuario)

            update producto
            set ProductoCantidad = ProductoCantidad - @CantidadSalB
            where IDProducto=@IdProductoU

            Fetch Next From TablaB INTO @ColumnaB
        end

        Close TablaB;
        Deallocate TablaB;
        Commit Transaction;
        select convert(varchar,@NotaId) + CHAR(172) + @cod
    end
    else
    begin
        Commit Transaction;
        select convert(varchar,@NotaId) + CHAR(172) + @cod
    end
END
END
GO

