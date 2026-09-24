
CREATE OR ALTER procedure [dbo].[anularDocumentoWEB]
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

CREATE OR ALTER procedure [dbo].[editarCompaniaWEB]
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

CREATE OR ALTER procedure [dbo].[editarProductoWEB]
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

CREATE OR ALTER PROCEDURE dbo.ingresarProductoWEB
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

    INSERT INTO dbo.Kardex
    VALUES
    (
        @ProductoId, GETDATE(), 'Nuevo Registro', 'Nuevo Registro',
        0, @ProductoCantidad, 0, @ProductoCosto, @ProductoCantidad, 'INGRESO',
        @ProductoUsuario, '', '', '', '', '', '', 'S', '', '', 'E'
    );

    SELECT @ProductoId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.LDdocumentosweb
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Cabecera VARCHAR(MAX) =
        'Fecha|Documento|NroDoc|Cliente|RUC|DNI|SubTotal|IGV|ICBPER|Total|Usuario|Estado|Referencia|Codigo|Mensaje|Condicion|FormaPago|Entidad|NroOperacion|Efectivo|Deposito';

    DECLARE @Anchos VARCHAR(MAX) =
        '85|90|110|250|80|80|115|115|90|115|150|150|110|0|0|0|0|0|0|0|0';

    DECLARE @Detalle VARCHAR(MAX);

    IF @FechaInicio IS NULL
       OR @FechaFin IS NULL
    BEGIN
        SELECT @Cabecera + '¬' + @Anchos;
        RETURN;
    END;

    IF @FechaInicio > @FechaFin
    BEGIN
        DECLARE @FechaTemporal DATE = @FechaInicio;

        SET @FechaInicio = @FechaFin;
        SET @FechaFin = @FechaTemporal;
    END;

    SET @Detalle =
    (
        SELECT STUFF(
        (
            SELECT
                '¬'
                + CONVERT(CHAR(10), d.DocuEmision, 103) + '|'
                + d.DocuDocumento + '|'
                + CONVERT(VARCHAR, d.DocuSerie + '-' + d.DocuNumero) + '|'
                + c.ClienteRazon + '|'
                + ISNULL(c.ClienteRuc, '') + '|'
                + ISNULL(c.ClienteDni, '') + '|'
                + CASE
                    WHEN d.TipoCodigo = '07' THEN '-'
                    ELSE ''
                  END
                + CONVERT(VARCHAR(50), CAST(d.DocuSubTotal AS MONEY), 1) + '|'
                + CASE
                    WHEN d.TipoCodigo = '07' THEN '-'
                    ELSE ''
                  END
                + CONVERT(VARCHAR(50), CAST(d.DocuIgv AS MONEY), 1) + '|'
                + CASE
                    WHEN d.TipoCodigo = '07' THEN '-'
                    ELSE ''
                  END
                + CONVERT(VARCHAR(50), CAST(d.ICBPER AS MONEY), 1) + '|'
                + CASE
                    WHEN d.TipoCodigo = '07' THEN '-'
                    ELSE ''
                  END
                + CONVERT(VARCHAR(50), CAST(d.DocuTotal AS MONEY), 1) + '|'
                + d.DocuUsuario + '|'
                + d.DocuEstado + '|'
                + d.DocuNroGuia + '|'
                + d.CodigoSunat + '|'
                + REPLACE(d.MensajeSunat, '|', ' ') + '|'
                + d.DocuCondicion + '|'
                + d.FormaPago + '|'
                + d.EntidadBancaria + '|'
                + d.NroOperacion + '|'
                + CONVERT(VARCHAR(50), CAST(d.Efectivo AS MONEY), 1) + '|'
                + CONVERT(VARCHAR(50), CAST(d.Deposito AS MONEY), 1)
            FROM DocumentoVenta AS d
            INNER JOIN Cliente AS c
                ON c.ClienteId = d.ClienteId
            WHERE d.DocuEmision >= @FechaInicio
              AND d.DocuEmision < DATEADD(DAY, 1, @FechaFin)
              AND d.DocuDocumento <> 'PROFORMA V'
            ORDER BY
                d.DocuEmision,
                d.DocuSerie + '-' + d.DocuNumero
            FOR XML PATH('')
        ),
        1,
        1,
        '')
    );

    SELECT
        @Cabecera
        + '¬'
        + @Anchos
        + CASE
            WHEN NULLIF(LTRIM(RTRIM(@Detalle)), '') IS NULL
                THEN ''
            ELSE '¬' + @Detalle
          END;
END;

GO

CREATE OR ALTER PROCEDURE dbo.listaNotaPedido
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ISNULL((
        SELECT STUFF((
            SELECT NCHAR(172) +
                CONVERT(VARCHAR, n.NotaId) + '|' +
                ISNULL(n.NotaDocu, '') + '|' +
                CONVERT(VARCHAR, c.ClienteId) + '|' +
                ISNULL(c.ClienteRazon, '') + '|' +
                ISNULL(c.ClienteRuc, '') + '|' +
                ISNULL(c.ClienteDni, '') + '|' +
                ISNULL(c.ClienteDireccion, '') + '|' +
                ISNULL(c.ClienteTelefono, '') + '|' +
                ISNULL(c.ClienteCorreo, '') + '|' +
                ISNULL(c.ClienteEstado, '') + '|' +
                ISNULL(c.ClienteDespacho, '') + '|' +
                ISNULL(c.ClienteUsuario, '') + '|' +
                CONVERT(VARCHAR, c.ClienteFecha, 103) + '|' +
                CONVERT(VARCHAR(10), n.NotaFecha, 103) + ' ' + CONVERT(VARCHAR(8), n.NotaFecha, 108) + '|' +
                ISNULL(n.NotaUsuario, '') + '|' +
                ISNULL(n.NotaFormaPago, '') + '|' +
                ISNULL(n.NotaCondicion, '') + '|' +
                CONVERT(VARCHAR, n.NotaFechaPago, 103) + '|' +
                ISNULL(n.NotaDireccion, '') + '|' +
                '' + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaSubtotal AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaMovilidad AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaDescuento AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaTotal AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaAcuenta AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaSaldo AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaAdicional AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaTarjeta AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaPagar AS MONEY), 1) + '|' +
                ISNULL(n.NotaEstado, '') + '|' +
                CONVERT(VARCHAR, n.CompaniaId) + '|' +
                ISNULL(n.NotaEntrega, '') + '|' +
                ISNULL(n.ModificadoPor, '') + '|' +
                ISNULL(n.FechaEdita, '') + '|' +
                ISNULL(n.NotaConcepto, '') + '|' +
                ISNULL(n.NotaSerie, '') + '|' +
                ISNULL(n.NotaNumero, '') + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaGanancia AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.ICBPER AS MONEY), 1) + '|' +
                ISNULL(CONVERT(VARCHAR, n.CajaId), '') + '|' +
                ISNULL(n.EntidadBancaria, '') + '|' +
                ISNULL(n.NroOperacion, '') + '|' +
                CONVERT(VARCHAR(50), CAST(n.Efectivo AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.Deposito AS MONEY), 1) + '|' +
                ISNULL((
                    SELECT TOP (1) d.EstadoSunat
                    FROM DocumentoVenta d WITH (NOLOCK)
                    WHERE d.NotaId = n.NotaId
                      AND d.TipoCodigo IN ('01', '03')
                    ORDER BY d.DocuId DESC
                ), 'PENDIENTE') + '|' +
                ISNULL(c.ClienteCodigo, '')
            FROM NotaPedido n WITH (NOLOCK)
            LEFT JOIN Cliente c WITH (NOLOCK) ON c.ClienteId = n.ClienteId
            WHERE n.NotaFecha >= @FechaInicio
              AND n.NotaFecha < DATEADD(DAY, 1, @FechaFin)
            ORDER BY n.NotaId DESC
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')
    ), '~') AS Resultado;
END;

GO

CREATE OR ALTER procedure [dbo].[listarCajaWEB]
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

CREATE OR ALTER procedure [dbo].[listarCajaFechaWEB]
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

CREATE OR ALTER procedure [dbo].[listarDetaCajaWEB]
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

CREATE OR ALTER PROCEDURE dbo.usp_Area
    @Data VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @accion      VARCHAR(20),
        @AreaId      INT,
        @AreaNombre  VARCHAR(150),
        @idTexto     VARCHAR(20),
        @p1          INT,
        @p2          INT;

    SET @Data = LTRIM(RTRIM(ISNULL(@Data, '')));

    IF @Data = ''
    BEGIN
        SELECT 'ERROR|No se enviaron datos.' AS Data;
        RETURN;
    END;

    SET @p1 = CHARINDEX('|', @Data);

    IF @p1 = 0
        SET @accion = UPPER(LTRIM(RTRIM(@Data)));
    ELSE
        SET @accion = UPPER(
            LTRIM(RTRIM(
                SUBSTRING(@Data, 1, @p1 - 1)
            ))
        );

    IF @accion = 'LISTAR'
    BEGIN

        SELECT
            CAST(AreaId AS VARCHAR(20)) + '|' +
            ISNULL(AreaNombre, '') AS Data
        FROM Area
        ORDER BY AreaNombre;

        RETURN;
    END;

    IF @accion = 'CREAR'
    BEGIN

        IF @p1 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar el nombre del area.' AS Data;
            RETURN;
        END;
        SET @AreaNombre = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                LEN(@Data)
            )
        ));
        IF ISNULL(@AreaNombre, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el nombre del area.' AS Data;
            RETURN;
        END;
        IF EXISTS
        (
            SELECT 1
            FROM Area
            WHERE UPPER(LTRIM(RTRIM(AreaNombre)))
                = UPPER(LTRIM(RTRIM(@AreaNombre)))
        )
        BEGIN
            SELECT 'ERROR|Ya existe un area con ese nombre.' AS Data;
            RETURN;
        END;
        BEGIN TRY

            INSERT INTO Area
            (
                AreaNombre
            )
            VALUES
            (
                @AreaNombre
            );


            SET @AreaId = SCOPE_IDENTITY();


            SELECT
                'OK|' +
                CAST(@AreaId AS VARCHAR(20)) +
                '|Area registrada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE()
                AS Data;

        END CATCH;


        RETURN;
    END;

    IF @accion = 'ACTUALIZAR'
    BEGIN

        IF @p1 = 0
        BEGIN
            SELECT 'ERROR|Formato incorrecto para actualizar.' AS Data;
            RETURN;
        END;


        SET @p2 = CHARINDEX('|', @Data, @p1 + 1);


        IF @p2 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar el ID y el nombre del area.' AS Data;
            RETURN;
        END;
        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                @p2 - @p1 - 1
            )
        ));
        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN
            SELECT 'ERROR|El ID del area no es valido.' AS Data;
            RETURN;
        END;


        SET @AreaId = CONVERT(INT, @idTexto);
        IF NOT EXISTS
        (
            SELECT 1
            FROM Area
            WHERE AreaId = @AreaId
        )
        BEGIN
            SELECT 'ERROR|El area que intenta actualizar no existe.' AS Data;
            RETURN;
        END;
        SET @AreaNombre = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p2 + 1,
                LEN(@Data)
            )
        ));
        IF ISNULL(@AreaNombre, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el nombre del area.' AS Data;
            RETURN;
        END;
        IF EXISTS
        (
            SELECT 1
            FROM Area
            WHERE UPPER(LTRIM(RTRIM(AreaNombre)))
                = UPPER(LTRIM(RTRIM(@AreaNombre)))
              AND AreaId <> @AreaId
        )
        BEGIN
            SELECT 'ERROR|Ya existe otra area con ese nombre.' AS Data;
            RETURN;
        END;
        BEGIN TRY

            UPDATE Area
            SET AreaNombre = @AreaNombre
            WHERE AreaId = @AreaId;


            SELECT
                'OK|Area actualizada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE()
                AS Data;

        END CATCH;


        RETURN;
    END;

    IF @accion = 'ELIMINAR'
    BEGIN

        IF @p1 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar el ID del area.' AS Data;
            RETURN;
        END;
        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                LEN(@Data)
            )
        ));
        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN
            SELECT 'ERROR|El ID del area no es valido.' AS Data;
            RETURN;
        END;


        SET @AreaId = CONVERT(INT, @idTexto);
        IF NOT EXISTS
        (
            SELECT 1
            FROM Area
            WHERE AreaId = @AreaId
        )
        BEGIN
            SELECT 'ERROR|El area que intenta eliminar no existe.' AS Data;
            RETURN;
        END;
        BEGIN TRY

            DELETE FROM Area
            WHERE AreaId = @AreaId;


            SELECT
                'OK|Area eliminada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH
            IF ERROR_NUMBER() = 547
            BEGIN

                SELECT
                    'ERROR|No se puede eliminar el area porque tiene registros relacionados.'
                    AS Data;

            END
            ELSE
            BEGIN

                SELECT
                    'ERROR|' + ERROR_MESSAGE()
                    AS Data;

            END

        END CATCH;


        RETURN;
    END;

    SELECT
        'ERROR|La accion ingresada no es valida.'
        AS Data;

END;

GO

CREATE OR ALTER PROCEDURE dbo.usp_Feriado
    @Data VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @accion            VARCHAR(20),
        @idFeriado         INT,
        @fecha             DATETIME,
        @motivo            VARCHAR(250),
        @fechaTexto        VARCHAR(20),
        @fechaNormalizada  VARCHAR(20),
        @idTexto           VARCHAR(20),
        @p1                INT,
        @p2                INT,
        @p3                INT;
    SET @Data = LTRIM(RTRIM(ISNULL(@Data, '')));

    IF @Data = ''
    BEGIN
        SELECT 'ERROR|No se enviaron datos.' AS Data;
        RETURN;
    END;
    SET @p1 = CHARINDEX('|', @Data);

    IF @p1 = 0
        SET @accion = UPPER(LTRIM(RTRIM(@Data)));
    ELSE
        SET @accion = UPPER(
            LTRIM(RTRIM(
                SUBSTRING(@Data, 1, @p1 - 1)
            ))
        );

    IF @accion = 'LISTAR'
    BEGIN

        SELECT
            CAST(idFeriado AS VARCHAR(20)) + '|' +
            CONVERT(VARCHAR(10), fecha, 23) + '|' +
            ISNULL(motivo, '') AS Data
        FROM Feriados
        ORDER BY fecha ASC;

        RETURN;
    END;

    IF @accion = 'CREAR'
    BEGIN
        IF @p1 = 0
        BEGIN
            SELECT 'ERROR|Formato incorrecto para crear.' AS Data;
            RETURN;
        END;

        SET @p2 = CHARINDEX('|', @Data, @p1 + 1);

        IF @p2 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar fecha y motivo.' AS Data;
            RETURN;
        END;
        SET @fechaTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                @p2 - @p1 - 1
            )
        ));
        SET @fechaNormalizada = REPLACE(@fechaTexto, '-', '');
        IF LEN(@fechaNormalizada) <> 8
           OR @fechaNormalizada LIKE '%[^0-9]%'
           OR ISDATE(@fechaNormalizada) = 0
        BEGIN
            SELECT 'ERROR|La fecha ingresada no es válida.' AS Data;
            RETURN;
        END;

        SET @fecha = CONVERT(DATETIME, @fechaNormalizada, 112);
        SET @motivo = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p2 + 1,
                LEN(@Data)
            )
        ));
        IF ISNULL(@motivo, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el motivo del feriado.' AS Data;
            RETURN;
        END;
        IF LEN(@motivo) > 250
        BEGIN
            SELECT 'ERROR|El motivo no puede superar los 250 caracteres.' AS Data;
            RETURN;
        END;
        IF EXISTS
        (
            SELECT 1
            FROM Feriados
            WHERE DATEDIFF(DAY, fecha, @fecha) = 0
        )
        BEGIN
            SELECT 'ERROR|Ya existe un feriado registrado en esa fecha.' AS Data;
            RETURN;
        END;
        IF EXISTS
        (
            SELECT 1
            FROM Feriados
            WHERE UPPER(LTRIM(RTRIM(motivo)))
                = UPPER(LTRIM(RTRIM(@motivo)))
        )
        BEGIN
            SELECT 'ERROR|Ya existe un feriado con el mismo motivo.' AS Data;
            RETURN;
        END;
        BEGIN TRY

            INSERT INTO Feriados
            (
                fecha,
                motivo
            )
            VALUES
            (
                @fecha,
                @motivo
            );

            SET @idFeriado = SCOPE_IDENTITY();

            SELECT
                'OK|' +
                CAST(@idFeriado AS VARCHAR(20)) +
                '|Feriado registrado correctamente.' AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE() AS Data;

        END CATCH;

        RETURN;
    END;

    IF @accion = 'ACTUALIZAR'
    BEGIN
        IF @p1 = 0
        BEGIN
            SELECT 'ERROR|Formato incorrecto para actualizar.' AS Data;
            RETURN;
        END;

        SET @p2 = CHARINDEX('|', @Data, @p1 + 1);

        IF @p2 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar el ID del feriado.' AS Data;
            RETURN;
        END;

        SET @p3 = CHARINDEX('|', @Data, @p2 + 1);

        IF @p3 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar fecha y motivo.' AS Data;
            RETURN;
        END;
        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                @p2 - @p1 - 1
            )
        ));
        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN
            SELECT 'ERROR|El ID del feriado no es válido.' AS Data;
            RETURN;
        END;

        SET @idFeriado = CONVERT(INT, @idTexto);
        IF NOT EXISTS
        (
            SELECT 1
            FROM Feriados
            WHERE idFeriado = @idFeriado
        )
        BEGIN
            SELECT 'ERROR|El feriado que intenta actualizar no existe.' AS Data;
            RETURN;
        END;
        SET @fechaTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p2 + 1,
                @p3 - @p2 - 1
            )
        ));

        SET @fechaNormalizada = REPLACE(@fechaTexto, '-', '');
        IF LEN(@fechaNormalizada) <> 8
           OR @fechaNormalizada LIKE '%[^0-9]%'
           OR ISDATE(@fechaNormalizada) = 0
        BEGIN
            SELECT 'ERROR|La fecha ingresada no es válida.' AS Data;
            RETURN;
        END;

        SET @fecha = CONVERT(DATETIME, @fechaNormalizada, 112);
        SET @motivo = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p3 + 1,
                LEN(@Data)
            )
        ));
        IF ISNULL(@motivo, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el motivo del feriado.' AS Data;
            RETURN;
        END;
        IF LEN(@motivo) > 250
        BEGIN
            SELECT 'ERROR|El motivo no puede superar los 250 caracteres.' AS Data;
            RETURN;
        END;
        IF EXISTS
        (
            SELECT 1
            FROM Feriados
            WHERE DATEDIFF(DAY, fecha, @fecha) = 0
              AND idFeriado <> @idFeriado
        )
        BEGIN
            SELECT 'ERROR|Ya existe otro feriado registrado en esa fecha.' AS Data;
            RETURN;
        END;
        IF EXISTS
        (
            SELECT 1
            FROM Feriados
            WHERE UPPER(LTRIM(RTRIM(motivo)))
                = UPPER(LTRIM(RTRIM(@motivo)))
              AND idFeriado <> @idFeriado
        )
        BEGIN
            SELECT 'ERROR|Ya existe otro feriado con el mismo motivo.' AS Data;
            RETURN;
        END;
        BEGIN TRY

            UPDATE Feriados
            SET
                fecha  = @fecha,
                motivo = @motivo
            WHERE idFeriado = @idFeriado;


            SELECT
                'OK|Feriado actualizado correctamente.' AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE() AS Data;

        END CATCH;

        RETURN;
    END;

    IF @accion = 'ELIMINAR'
    BEGIN
        IF @p1 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar el ID del feriado.' AS Data;
            RETURN;
        END;
        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                LEN(@Data)
            )
        ));
        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN
            SELECT 'ERROR|El ID del feriado no es válido.' AS Data;
            RETURN;
        END;

        SET @idFeriado = CONVERT(INT, @idTexto);
        IF NOT EXISTS
        (
            SELECT 1
            FROM Feriados
            WHERE idFeriado = @idFeriado
        )
        BEGIN
            SELECT 'ERROR|El feriado que intenta eliminar no existe.' AS Data;
            RETURN;
        END;
        BEGIN TRY

            DELETE FROM Feriados
            WHERE idFeriado = @idFeriado;

            SELECT
                'OK|Feriado eliminado correctamente.' AS Data;

        END TRY

        BEGIN CATCH
            IF ERROR_NUMBER() = 547
            BEGIN

                SELECT
                    'ERROR|No se puede eliminar el feriado porque tiene registros relacionados.'
                    AS Data;

            END
            ELSE
            BEGIN

                SELECT
                    'ERROR|' + ERROR_MESSAGE() AS Data;

            END

        END CATCH;

        RETURN;
    END;
    SELECT
        'ERROR|La acción ingresada no es válida.' AS Data;

END;

GO

CREATE OR ALTER PROCEDURE dbo.usp_Maquina
    @Data VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @accion        VARCHAR(20),
        @idMaquina     INT,
        @idTexto       VARCHAR(20),
        @Maquina       VARCHAR(150),
        @SerieFactura  VARCHAR(50),
        @SerieNC       VARCHAR(50),
        @SerieBoleta   VARCHAR(50),
        @Tiketera      VARCHAR(250),
        @p1            INT,
        @p2            INT,
        @p3            INT,
        @p4            INT,
        @p5            INT,
        @p6            INT;


    SET @Data = LTRIM(RTRIM(ISNULL(@Data, '')));

    IF @Data = ''
    BEGIN
        SELECT 'ERROR|No se enviaron datos.' AS Data;
        RETURN;
    END;

    SET @p1 = CHARINDEX('|', @Data);

    IF @p1 = 0
        SET @accion = UPPER(LTRIM(RTRIM(@Data)));
    ELSE
        SET @accion = UPPER(
            LTRIM(RTRIM(
                SUBSTRING(@Data, 1, @p1 - 1)
            ))
        );

    IF @accion = 'LISTAR'
    BEGIN

        SELECT
            CAST(IdMaquina AS VARCHAR(20)) + '|' +
            ISNULL(Maquina, '') + '|' +
            ISNULL(CONVERT(VARCHAR(23), Registro, 121), '') + '|' +
            ISNULL(SerieFactura, '') + '|' +
            ISNULL(SerieNC, '') + '|' +
            ISNULL(SerieBoleta, '') + '|' +
            ISNULL(Tiketera, '') AS Data
        FROM MAQUINAS
        ORDER BY Maquina;

        RETURN;
    END;

    IF @accion = 'CREAR'
    BEGIN
        SET @p2 = CHARINDEX('|', @Data, @p1 + 1);
        SET @p3 = CHARINDEX('|', @Data, @p2 + 1);
        SET @p4 = CHARINDEX('|', @Data, @p3 + 1);
        SET @p5 = CHARINDEX('|', @Data, @p4 + 1);
        IF @p1 = 0
           OR @p2 = 0
           OR @p3 = 0
           OR @p4 = 0
           OR @p5 = 0
        BEGIN
            SELECT
                'ERROR|Formato incorrecto. Use CREAR|Maquina|SerieFactura|SerieNC|SerieBoleta|Tiketera'
                AS Data;
            RETURN;
        END;
        SET @Maquina = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                @p2 - @p1 - 1
            )
        ));

        SET @SerieFactura = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p2 + 1,
                @p3 - @p2 - 1
            )
        ));

        SET @SerieNC = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p3 + 1,
                @p4 - @p3 - 1
            )
        ));

        SET @SerieBoleta = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p4 + 1,
                @p5 - @p4 - 1
            )
        ));

        SET @Tiketera = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p5 + 1,
                LEN(@Data)
            )
        ));

        IF ISNULL(@Maquina, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el nombre de la máquina.' AS Data;
            RETURN;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM MAQUINAS
            WHERE UPPER(LTRIM(RTRIM(Maquina)))
                = UPPER(LTRIM(RTRIM(@Maquina)))
        )
        BEGIN
            SELECT
                'ERROR|Ya existe una máquina registrada con ese nombre.'
                AS Data;
            RETURN;
        END;

        IF ISNULL(@SerieFactura, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM MAQUINAS
                WHERE UPPER(LTRIM(RTRIM(SerieFactura)))
                    = UPPER(LTRIM(RTRIM(@SerieFactura)))
            )
            BEGIN
                SELECT
                    'ERROR|La serie de factura ya está registrada en otra máquina.'
                    AS Data;
                RETURN;
            END;

        END;

        IF ISNULL(@SerieNC, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM MAQUINAS
                WHERE UPPER(LTRIM(RTRIM(SerieNC)))
                    = UPPER(LTRIM(RTRIM(@SerieNC)))
            )
            BEGIN
                SELECT
                    'ERROR|La serie de nota de crédito ya está registrada en otra máquina.'
                    AS Data;
                RETURN;
            END;

        END;

        IF ISNULL(@SerieBoleta, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM MAQUINAS
                WHERE UPPER(LTRIM(RTRIM(SerieBoleta)))
                    = UPPER(LTRIM(RTRIM(@SerieBoleta)))
            )
            BEGIN
                SELECT
                    'ERROR|La serie de boleta ya está registrada en otra máquina.'
                    AS Data;
                RETURN;
            END;

        END;

        BEGIN TRY

            INSERT INTO MAQUINAS
            (
                Maquina,
                Registro,
                SerieFactura,
                SerieNC,
                SerieBoleta,
                Tiketera
            )
            VALUES
            (
                @Maquina,
                GETDATE(),
                @SerieFactura,
                @SerieNC,
                @SerieBoleta,
                @Tiketera
            );


            SET @idMaquina = SCOPE_IDENTITY();


            SELECT
                'OK|' +
                CAST(@idMaquina AS VARCHAR(20)) +
                '|Máquina registrada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE()
                AS Data;

        END CATCH;


        RETURN;
    END;

    IF @accion = 'ACTUALIZAR'
    BEGIN

        SET @p2 = CHARINDEX('|', @Data, @p1 + 1);
        SET @p3 = CHARINDEX('|', @Data, @p2 + 1);
        SET @p4 = CHARINDEX('|', @Data, @p3 + 1);
        SET @p5 = CHARINDEX('|', @Data, @p4 + 1);
        SET @p6 = CHARINDEX('|', @Data, @p5 + 1);
        IF @p1 = 0
           OR @p2 = 0
           OR @p3 = 0
           OR @p4 = 0
           OR @p5 = 0
           OR @p6 = 0
        BEGIN

            SELECT
                'ERROR|Formato incorrecto. Use ACTUALIZAR|Id|Maquina|SerieFactura|SerieNC|SerieBoleta|Tiketera'
                AS Data;

            RETURN;
        END;

        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                @p2 - @p1 - 1
            )
        ));


        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN

            SELECT
                'ERROR|El ID de la máquina no es válido.'
                AS Data;

            RETURN;
        END;


        SET @idMaquina = CONVERT(INT, @idTexto);

        IF NOT EXISTS
        (
            SELECT 1
            FROM MAQUINAS
            WHERE IdMaquina = @idMaquina
        )
        BEGIN

            SELECT
                'ERROR|La máquina que intenta actualizar no existe.'
                AS Data;

            RETURN;
        END;

        SET @Maquina = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p2 + 1,
                @p3 - @p2 - 1
            )
        ));


        SET @SerieFactura = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p3 + 1,
                @p4 - @p3 - 1
            )
        ));


        SET @SerieNC = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p4 + 1,
                @p5 - @p4 - 1
            )
        ));


        SET @SerieBoleta = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p5 + 1,
                @p6 - @p5 - 1
            )
        ));


        SET @Tiketera = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p6 + 1,
                LEN(@Data)
            )
        ));

        IF ISNULL(@Maquina, '') = ''
        BEGIN

            SELECT
                'ERROR|Debe ingresar el nombre de la máquina.'
                AS Data;

            RETURN;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM MAQUINAS
            WHERE UPPER(LTRIM(RTRIM(Maquina)))
                = UPPER(LTRIM(RTRIM(@Maquina)))
              AND IdMaquina <> @idMaquina
        )
        BEGIN

            SELECT
                'ERROR|Ya existe otra máquina registrada con ese nombre.'
                AS Data;

            RETURN;
        END;

        IF ISNULL(@SerieFactura, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM MAQUINAS
                WHERE UPPER(LTRIM(RTRIM(SerieFactura)))
                    = UPPER(LTRIM(RTRIM(@SerieFactura)))
                  AND IdMaquina <> @idMaquina
            )
            BEGIN

                SELECT
                    'ERROR|La serie de factura pertenece a otra máquina.'
                    AS Data;

                RETURN;
            END;

        END;

        IF ISNULL(@SerieNC, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM MAQUINAS
                WHERE UPPER(LTRIM(RTRIM(SerieNC)))
                    = UPPER(LTRIM(RTRIM(@SerieNC)))
                  AND IdMaquina <> @idMaquina
            )
            BEGIN

                SELECT
                    'ERROR|La serie de nota de crédito pertenece a otra máquina.'
                    AS Data;

                RETURN;
            END;

        END;

        IF ISNULL(@SerieBoleta, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM MAQUINAS
                WHERE UPPER(LTRIM(RTRIM(SerieBoleta)))
                    = UPPER(LTRIM(RTRIM(@SerieBoleta)))
                  AND IdMaquina <> @idMaquina
            )
            BEGIN

                SELECT
                    'ERROR|La serie de boleta pertenece a otra máquina.'
                    AS Data;

                RETURN;
            END;

        END;

        BEGIN TRY

            UPDATE MAQUINAS
            SET
                Maquina      = @Maquina,
                SerieFactura = @SerieFactura,
                SerieNC      = @SerieNC,
                SerieBoleta  = @SerieBoleta,
                Tiketera     = @Tiketera
            WHERE IdMaquina = @idMaquina;


            SELECT
                'OK|Máquina actualizada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE()
                AS Data;

        END CATCH;


        RETURN;
    END;

    IF @accion = 'ELIMINAR'
    BEGIN

        IF @p1 = 0
        BEGIN

            SELECT
                'ERROR|Debe ingresar el ID de la máquina.'
                AS Data;

            RETURN;
        END;


        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                LEN(@Data)
            )
        ));
        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN

            SELECT
                'ERROR|El ID de la máquina no es válido.'
                AS Data;

            RETURN;
        END;


        SET @idMaquina = CONVERT(INT, @idTexto);

        IF NOT EXISTS
        (
            SELECT 1
            FROM MAQUINAS
            WHERE IdMaquina = @idMaquina
        )
        BEGIN

            SELECT
                'ERROR|La máquina que intenta eliminar no existe.'
                AS Data;

            RETURN;
        END;

        BEGIN TRY

            DELETE FROM MAQUINAS
            WHERE IdMaquina = @idMaquina;


            SELECT
                'OK|Máquina eliminada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH
            IF ERROR_NUMBER() = 547
            BEGIN

                SELECT
                    'ERROR|No se puede eliminar la máquina porque tiene registros relacionados.'
                    AS Data;

            END
            ELSE
            BEGIN

                SELECT
                    'ERROR|' + ERROR_MESSAGE()
                    AS Data;

            END

        END CATCH;


        RETURN;
    END;

    SELECT
        'ERROR|La acción ingresada no es válida.'
        AS Data;

END;

GO

CREATE OR ALTER PROCEDURE dbo.usp_Personal
    @Data VARCHAR(MAX),
    @Huella VARBINARY(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @accion                VARCHAR(20),
        @PersonalId            NUMERIC(20,0),
        @PersonalNombres       VARCHAR(140),
        @PersonalApellidos     VARCHAR(140),
        @AreaId                NUMERIC(20,0),
        @PersonalCodigo        VARCHAR(80),
        @PersonalNacimiento    DATE,
        @PersonalIngreso       VARCHAR(20),
        @PersonalDNI           VARCHAR(20),
        @PersonalDireccion     VARCHAR(140),
        @PersonalTelefono      VARCHAR(40),
        @PersonalTelefonoAsi   VARCHAR(40),
        @PersonalEmail         VARCHAR(100),
        @PersonalSueldo        DECIMAL(18,2),
        @PersonalEstado        VARCHAR(60),
        @PersonalBajaFecha     VARCHAR(60),
        @PersonalRuc           VARCHAR(20),
        @PersonalImagen        VARCHAR(MAX),
        @CompaniaId            INT,

        @idTexto               VARCHAR(30),
        @areaTexto             VARCHAR(30),
        @companiaTexto         VARCHAR(30),
        @sueldoTexto           VARCHAR(50),
        @nacimientoTexto       VARCHAR(30),
        @fechaNormalizada      VARCHAR(20),

        @resto                 VARCHAR(MAX),
        @valor                 VARCHAR(MAX),
        @separador             INT,
        @posicion              INT,
        @cantidad              INT,
        @numeroCompania        NUMERIC(20,0);

    DECLARE @Partes TABLE
    (
        Posicion INT,
        Valor VARCHAR(MAX)
    );

    SET @Data = LTRIM(RTRIM(ISNULL(@Data, '')));

    IF @Data = ''
    BEGIN
        SELECT 'ERROR|No se enviaron datos.' AS Data;
        RETURN;
    END;

    SET @resto = @Data;
    SET @posicion = 1;

    WHILE 1 = 1
    BEGIN

        SET @separador = CHARINDEX('|', @resto);

        IF @separador = 0
        BEGIN

            INSERT INTO @Partes
            (
                Posicion,
                Valor
            )
            VALUES
            (
                @posicion,
                @resto
            );

            BREAK;
        END;


        SET @valor = SUBSTRING(
            @resto,
            1,
            @separador - 1
        );


        INSERT INTO @Partes
        (
            Posicion,
            Valor
        )
        VALUES
        (
            @posicion,
            @valor
        );


        SET @resto = SUBSTRING(
            @resto,
            @separador + 1,
            LEN(@resto)
        );

        SET @posicion = @posicion + 1;

    END;


    SELECT @cantidad = COUNT(*)
    FROM @Partes;


    SELECT
        @accion = UPPER(LTRIM(RTRIM(Valor)))
    FROM @Partes
    WHERE Posicion = 1;

    IF @accion = 'LISTAR'
    BEGIN

        SELECT
            CAST(PersonalId AS VARCHAR(30)) + '|' +
            ISNULL(PersonalNombres, '') + '|' +
            ISNULL(PersonalApellidos, '') + '|' +
            ISNULL(CAST(AreaId AS VARCHAR(30)), '') + '|' +
            ISNULL(PersonalCodigo, '') + '|' +
            ISNULL(CONVERT(VARCHAR(10), PersonalNacimiento, 23), '') + '|' +
            ISNULL(PersonalIngreso, '') + '|' +
            ISNULL(PersonalDNI, '') + '|' +
            ISNULL(PersonalDireccion, '') + '|' +
            ISNULL(PersonalTelefono, '') + '|' +
            ISNULL(PersonalTelefonoAsi, '') + '|' +
            ISNULL(PersonalEmail, '') + '|' +
            ISNULL(CAST(PersonalSueldo AS VARCHAR(50)), '') + '|' +
            ISNULL(PersonalEstado, '') + '|' +
            ISNULL(PersonalBajaFecha, '') + '|' +
            ISNULL(PersonalRuc, '') + '|' +
            ISNULL(PersonalImagen, '') + '|' +
            ISNULL(CAST(CompaniaId AS VARCHAR(20)), '') + '|' +
            CASE
                WHEN HUELLA IS NULL THEN '0'
                ELSE '1'
            END
            AS Data
        FROM Personal
        ORDER BY PersonalApellidos, PersonalNombres;

        RETURN;
    END;

    IF @accion = 'CREAR'
    BEGIN

        SELECT @PersonalNombres =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 2;

        SELECT @PersonalApellidos =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 3;

        SELECT @areaTexto =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 4;

        SELECT @PersonalCodigo =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 5;

        SELECT @nacimientoTexto =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 6;

        SELECT @PersonalIngreso =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 7;

        SELECT @PersonalDNI =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 8;

        SELECT @PersonalDireccion =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 9;

        SELECT @PersonalTelefono =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 10;

        SELECT @PersonalTelefonoAsi =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 11;

        SELECT @PersonalEmail =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 12;

        SELECT @sueldoTexto =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 13;

        SELECT @PersonalEstado =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 14;

        SELECT @PersonalBajaFecha =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 15;

        SELECT @PersonalRuc =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 16;

        SELECT @PersonalImagen =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 17;

        SELECT @companiaTexto =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 18;

        IF ISNULL(@PersonalNombres, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar los nombres del personal.' AS Data;
            RETURN;
        END;


        IF ISNULL(@PersonalApellidos, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar los apellidos del personal.' AS Data;
            RETURN;
        END;

        IF ISNULL(@areaTexto, '') <> ''
        BEGIN

            IF @areaTexto LIKE '%[^0-9]%'
               OR LEN(@areaTexto) > 20
            BEGIN
                SELECT 'ERROR|El AreaId no es valido.' AS Data;
                RETURN;
            END;


            SET @AreaId = CONVERT(NUMERIC(20,0), @areaTexto);


            IF NOT EXISTS
            (
                SELECT 1
                FROM Area
                WHERE AreaId = @AreaId
            )
            BEGIN
                SELECT 'ERROR|El area seleccionada no existe.' AS Data;
                RETURN;
            END;

        END
        ELSE
        BEGIN
            SET @AreaId = NULL;
        END;

        IF ISNULL(@nacimientoTexto, '') <> ''
        BEGIN

            SET @fechaNormalizada =
                REPLACE(@nacimientoTexto, '-', '');


            IF LEN(@fechaNormalizada) <> 8
               OR @fechaNormalizada LIKE '%[^0-9]%'
               OR ISDATE(@fechaNormalizada) = 0
            BEGIN
                SELECT 'ERROR|La fecha de nacimiento no es valida.' AS Data;
                RETURN;
            END;


            SET @PersonalNacimiento =
                CONVERT(DATE, @fechaNormalizada, 112);

        END
        ELSE
        BEGIN
            SET @PersonalNacimiento = NULL;
        END;

        IF ISNULL(@sueldoTexto, '') <> ''
        BEGIN

            IF ISNUMERIC(@sueldoTexto) = 0
            BEGIN
                SELECT 'ERROR|El sueldo ingresado no es valido.' AS Data;
                RETURN;
            END;


            BEGIN TRY

                SET @PersonalSueldo =
                    CONVERT(DECIMAL(18,2), @sueldoTexto);

            END TRY
            BEGIN CATCH

                SELECT 'ERROR|El sueldo ingresado no es valido.' AS Data;
                RETURN;

            END CATCH;

        END
        ELSE
        BEGIN
            SET @PersonalSueldo = NULL;
        END;

        IF ISNULL(@companiaTexto, '') <> ''
        BEGIN

            IF @companiaTexto LIKE '%[^0-9]%'
            BEGIN
                SELECT 'ERROR|El CompaniaId no es valido.' AS Data;
                RETURN;
            END;


            SET @numeroCompania =
                CONVERT(NUMERIC(20,0), @companiaTexto);


            IF @numeroCompania > 2147483647
            BEGIN
                SELECT 'ERROR|El CompaniaId no es valido.' AS Data;
                RETURN;
            END;


            SET @CompaniaId =
                CONVERT(INT, @numeroCompania);

        END
        ELSE
        BEGIN
            SET @CompaniaId = NULL;
        END;

        IF ISNULL(@PersonalCodigo, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE UPPER(LTRIM(RTRIM(PersonalCodigo)))
                    = UPPER(LTRIM(RTRIM(@PersonalCodigo)))
            )
            BEGIN
                SELECT 'ERROR|Ya existe un personal con el mismo codigo.' AS Data;
                RETURN;
            END;

        END;

        IF ISNULL(@PersonalDNI, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE LTRIM(RTRIM(PersonalDNI))
                    = LTRIM(RTRIM(@PersonalDNI))
            )
            BEGIN
                SELECT 'ERROR|Ya existe un personal con el mismo DNI.' AS Data;
                RETURN;
            END;

        END;

        IF ISNULL(@PersonalEmail, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE UPPER(LTRIM(RTRIM(PersonalEmail)))
                    = UPPER(LTRIM(RTRIM(@PersonalEmail)))
            )
            BEGIN
                SELECT 'ERROR|Ya existe un personal con el mismo correo.' AS Data;
                RETURN;
            END;

        END;

        IF ISNULL(@PersonalRuc, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE LTRIM(RTRIM(PersonalRuc))
                    = LTRIM(RTRIM(@PersonalRuc))
            )
            BEGIN
                SELECT 'ERROR|Ya existe un personal con el mismo RUC.' AS Data;
                RETURN;
            END;

        END;

        BEGIN TRY

            INSERT INTO Personal
            (
                PersonalNombres,
                PersonalApellidos,
                AreaId,
                PersonalCodigo,
                PersonalNacimiento,
                PersonalIngreso,
                PersonalDNI,
                PersonalDireccion,
                PersonalTelefono,
                PersonalTelefonoAsi,
                PersonalEmail,
                PersonalSueldo,
                PersonalEstado,
                PersonalBajaFecha,
                PersonalRuc,
                PersonalImagen,
                CompaniaId,
                HUELLA
            )
            VALUES
            (
                @PersonalNombres,
                @PersonalApellidos,
                @AreaId,
                NULLIF(@PersonalCodigo, ''),
                @PersonalNacimiento,
                NULLIF(@PersonalIngreso, ''),
                NULLIF(@PersonalDNI, ''),
                NULLIF(@PersonalDireccion, ''),
                NULLIF(@PersonalTelefono, ''),
                NULLIF(@PersonalTelefonoAsi, ''),
                NULLIF(@PersonalEmail, ''),
                @PersonalSueldo,
                NULLIF(@PersonalEstado, ''),
                NULLIF(@PersonalBajaFecha, ''),
                NULLIF(@PersonalRuc, ''),
                NULLIF(@PersonalImagen, ''),
                @CompaniaId,
                @Huella
            );


            SET @PersonalId = SCOPE_IDENTITY();


            SELECT
                'OK|' +
                CAST(@PersonalId AS VARCHAR(30)) +
                '|Personal registrado correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            IF ERROR_NUMBER() = 547
            BEGIN
                SELECT
                    'ERROR|No se pudo registrar. Verifique las relaciones de AreaId o CompaniaId.'
                    AS Data;
            END
            ELSE
            BEGIN
                SELECT
                    'ERROR|' + ERROR_MESSAGE()
                    AS Data;
            END

        END CATCH;


        RETURN;
    END;

    IF @accion = 'ACTUALIZAR'
    BEGIN

        SELECT @idTexto =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 2;


        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
           OR LEN(@idTexto) > 20
        BEGIN
            SELECT 'ERROR|El PersonalId no es valido.' AS Data;
            RETURN;
        END;


        SET @PersonalId =
            CONVERT(NUMERIC(20,0), @idTexto);


        IF NOT EXISTS
        (
            SELECT 1
            FROM Personal
            WHERE PersonalId = @PersonalId
        )
        BEGIN
            SELECT 'ERROR|El personal que intenta actualizar no existe.' AS Data;
            RETURN;
        END;


        SELECT @PersonalNombres = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 3;

        SELECT @PersonalApellidos = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 4;

        SELECT @areaTexto = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 5;

        SELECT @PersonalCodigo = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 6;

        SELECT @nacimientoTexto = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 7;

        SELECT @PersonalIngreso = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 8;

        SELECT @PersonalDNI = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 9;

        SELECT @PersonalDireccion = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 10;

        SELECT @PersonalTelefono = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 11;

        SELECT @PersonalTelefonoAsi = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 12;

        SELECT @PersonalEmail = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 13;

        SELECT @sueldoTexto = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 14;

        SELECT @PersonalEstado = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 15;

        SELECT @PersonalBajaFecha = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 16;

        SELECT @PersonalRuc = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 17;

        SELECT @PersonalImagen = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 18;

        SELECT @companiaTexto = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 19;
        IF ISNULL(@PersonalNombres, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar los nombres del personal.' AS Data;
            RETURN;
        END;
        IF ISNULL(@PersonalApellidos, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar los apellidos del personal.' AS Data;
            RETURN;
        END;
        IF ISNULL(@areaTexto, '') <> ''
        BEGIN

            IF @areaTexto LIKE '%[^0-9]%'
               OR LEN(@areaTexto) > 20
            BEGIN
                SELECT 'ERROR|El AreaId no es valido.' AS Data;
                RETURN;
            END;


            SET @AreaId =
                CONVERT(NUMERIC(20,0), @areaTexto);


            IF NOT EXISTS
            (
                SELECT 1
                FROM Area
                WHERE AreaId = @AreaId
            )
            BEGIN
                SELECT 'ERROR|El area seleccionada no existe.' AS Data;
                RETURN;
            END;

        END
        ELSE
        BEGIN
            SET @AreaId = NULL;
        END;
        IF ISNULL(@nacimientoTexto, '') <> ''
        BEGIN

            SET @fechaNormalizada =
                REPLACE(@nacimientoTexto, '-', '');


            IF LEN(@fechaNormalizada) <> 8
               OR @fechaNormalizada LIKE '%[^0-9]%'
               OR ISDATE(@fechaNormalizada) = 0
            BEGIN
                SELECT 'ERROR|La fecha de nacimiento no es valida.' AS Data;
                RETURN;
            END;


            SET @PersonalNacimiento =
                CONVERT(DATE, @fechaNormalizada, 112);

        END
        ELSE
        BEGIN
            SET @PersonalNacimiento = NULL;
        END;
        IF ISNULL(@sueldoTexto, '') <> ''
        BEGIN

            IF ISNUMERIC(@sueldoTexto) = 0
            BEGIN
                SELECT 'ERROR|El sueldo ingresado no es valido.' AS Data;
                RETURN;
            END;


            BEGIN TRY

                SET @PersonalSueldo =
                    CONVERT(DECIMAL(18,2), @sueldoTexto);

            END TRY
            BEGIN CATCH

                SELECT 'ERROR|El sueldo ingresado no es valido.' AS Data;
                RETURN;

            END CATCH;

        END
        ELSE
        BEGIN
            SET @PersonalSueldo = NULL;
        END;
        IF ISNULL(@companiaTexto, '') <> ''
        BEGIN

            IF @companiaTexto LIKE '%[^0-9]%'
            BEGIN
                SELECT 'ERROR|El CompaniaId no es valido.' AS Data;
                RETURN;
            END;


            SET @numeroCompania =
                CONVERT(NUMERIC(20,0), @companiaTexto);


            IF @numeroCompania > 2147483647
            BEGIN
                SELECT 'ERROR|El CompaniaId no es valido.' AS Data;
                RETURN;
            END;


            SET @CompaniaId =
                CONVERT(INT, @numeroCompania);

        END
        ELSE
        BEGIN
            SET @CompaniaId = NULL;
        END;
        IF ISNULL(@PersonalCodigo, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE UPPER(LTRIM(RTRIM(PersonalCodigo)))
                    = UPPER(LTRIM(RTRIM(@PersonalCodigo)))
                  AND PersonalId <> @PersonalId
            )
            BEGIN
                SELECT 'ERROR|Ya existe otro personal con el mismo codigo.' AS Data;
                RETURN;
            END;

        END;
        IF ISNULL(@PersonalDNI, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE LTRIM(RTRIM(PersonalDNI))
                    = LTRIM(RTRIM(@PersonalDNI))
                  AND PersonalId <> @PersonalId
            )
            BEGIN
                SELECT 'ERROR|Ya existe otro personal con el mismo DNI.' AS Data;
                RETURN;
            END;

        END;
        IF ISNULL(@PersonalEmail, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE UPPER(LTRIM(RTRIM(PersonalEmail)))
                    = UPPER(LTRIM(RTRIM(@PersonalEmail)))
                  AND PersonalId <> @PersonalId
            )
            BEGIN
                SELECT 'ERROR|Ya existe otro personal con el mismo correo.' AS Data;
                RETURN;
            END;

        END;
        IF ISNULL(@PersonalRuc, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE LTRIM(RTRIM(PersonalRuc))
                    = LTRIM(RTRIM(@PersonalRuc))
                  AND PersonalId <> @PersonalId
            )
            BEGIN
                SELECT 'ERROR|Ya existe otro personal con el mismo RUC.' AS Data;
                RETURN;
            END;

        END;
        BEGIN TRY

            UPDATE Personal
            SET
                PersonalNombres     = @PersonalNombres,
                PersonalApellidos   = @PersonalApellidos,
                AreaId              = @AreaId,
                PersonalCodigo      = NULLIF(@PersonalCodigo, ''),
                PersonalNacimiento  = @PersonalNacimiento,
                PersonalIngreso     = NULLIF(@PersonalIngreso, ''),
                PersonalDNI         = NULLIF(@PersonalDNI, ''),
                PersonalDireccion   = NULLIF(@PersonalDireccion, ''),
                PersonalTelefono    = NULLIF(@PersonalTelefono, ''),
                PersonalTelefonoAsi = NULLIF(@PersonalTelefonoAsi, ''),
                PersonalEmail       = NULLIF(@PersonalEmail, ''),
                PersonalSueldo      = @PersonalSueldo,
                PersonalEstado      = NULLIF(@PersonalEstado, ''),
                PersonalBajaFecha   = NULLIF(@PersonalBajaFecha, ''),
                PersonalRuc         = NULLIF(@PersonalRuc, ''),
                PersonalImagen      = NULLIF(@PersonalImagen, ''),
                CompaniaId          = @CompaniaId,
                HUELLA =
                    CASE
                        WHEN @Huella IS NULL THEN HUELLA
                        ELSE @Huella
                    END
            WHERE PersonalId = @PersonalId;


            SELECT
                'OK|Personal actualizado correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            IF ERROR_NUMBER() = 547
            BEGIN
                SELECT
                    'ERROR|No se pudo actualizar. Verifique las relaciones de AreaId o CompaniaId.'
                    AS Data;
            END
            ELSE
            BEGIN
                SELECT
                    'ERROR|' + ERROR_MESSAGE()
                    AS Data;
            END

        END CATCH;


        RETURN;
    END;

    IF @accion = 'ELIMINAR'
    BEGIN

        SELECT @idTexto =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 2;


        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
           OR LEN(@idTexto) > 20
        BEGIN
            SELECT 'ERROR|El PersonalId no es valido.' AS Data;
            RETURN;
        END;


        SET @PersonalId =
            CONVERT(NUMERIC(20,0), @idTexto);


        IF NOT EXISTS
        (
            SELECT 1
            FROM Personal
            WHERE PersonalId = @PersonalId
        )
        BEGIN
            SELECT 'ERROR|El personal que intenta eliminar no existe.' AS Data;
            RETURN;
        END;


        BEGIN TRY

            DELETE FROM Personal
            WHERE PersonalId = @PersonalId;


            SELECT
                'OK|Personal eliminado correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            IF ERROR_NUMBER() = 547
            BEGIN
                SELECT
                    'ERROR|No se puede eliminar el personal porque tiene registros relacionados.'
                    AS Data;
            END
            ELSE
            BEGIN
                SELECT
                    'ERROR|' + ERROR_MESSAGE()
                    AS Data;
            END

        END CATCH;


        RETURN;
    END;

    SELECT
        'ERROR|La accion ingresada no es valida.'
        AS Data;

END;

GO

CREATE OR ALTER PROCEDURE dbo.usp_Usuario  
    @Data VARCHAR(MAX),  
    @UsuarioClave VARBINARY(500) = NULL  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    DECLARE  
        @accion                    VARCHAR(20),  
        @UsuarioID                 INT,  
        @PersonalId                NUMERIC(20,0),  
        @UsuarioAlias              VARCHAR(60),  
        @UsuarioEstado             VARCHAR(40),  
        @UsuarioSerie              VARCHAR(4),  
        @EnviaBoleta               BIT,  
        @EnviarFactura             BIT,  
        @EnviaNC                   BIT,  
        @EnviaND                   BIT,  
        @UserRuta                  VARCHAR(MAX),  
        @UserRutaOBS               VARCHAR(MAX),  
        @Administrador             BIT,  
        @RutaVentaOBS              VARCHAR(MAX),  
        @RutaIOC                   VARCHAR(MAX),  
        @RutaApertura              VARCHAR(MAX),  
        @FechaVencimientoClave     DATE,  
  
        @idTexto                   VARCHAR(30),  
        @personalTexto             VARCHAR(30),  
  
        @enviaBoletaTexto          VARCHAR(10),  
        @enviarFacturaTexto        VARCHAR(10),  
        @enviaNCTexto              VARCHAR(10),  
        @enviaNDTexto              VARCHAR(10),  
        @administradorTexto        VARCHAR(10),  
  
        @fechaTexto                VARCHAR(30),  
        @fechaNormalizada          VARCHAR(20),  
  
        @resto                     VARCHAR(MAX),  
        @valor                     VARCHAR(MAX),  
        @separador                 INT,  
        @posicion                  INT;  
  
  
    DECLARE @Partes TABLE  
    (  
        Posicion INT,  
        Valor VARCHAR(MAX)  
    );  
  
    SET @Data = LTRIM(RTRIM(ISNULL(@Data, '')));  
  
    IF @Data = ''  
    BEGIN  
        SELECT 'ERROR|No se enviaron datos.' AS Data;  
        RETURN;  
    END;  
  
    SET @resto = @Data;  
    SET @posicion = 1;  
  
    WHILE 1 = 1  
    BEGIN  
  
        SET @separador = CHARINDEX('|', @resto);  
  
        IF @separador = 0  
        BEGIN  
  
            INSERT INTO @Partes  
            (  
                Posicion,  
                Valor  
            )  
            VALUES  
            (  
                @posicion,  
                @resto  
            );  
  
            BREAK;  
  
        END;  
  
  
        SET @valor =  
            SUBSTRING(  
                @resto,  
                1,  
                @separador - 1  
            );  
  
  
        INSERT INTO @Partes  
        (  
            Posicion,  
            Valor  
        )  
        VALUES  
        (  
            @posicion,  
            @valor  
        );  
  
  
        SET @resto =  
            SUBSTRING(  
                @resto,  
                @separador + 1,  
                LEN(@resto)  
            );  
  
  
        SET @posicion = @posicion + 1;  
  
    END;  
  
  
    SELECT  
        @accion = UPPER(LTRIM(RTRIM(Valor)))  
    FROM @Partes  
    WHERE Posicion = 1;  
  
    IF @accion = 'LISTAR'  
    BEGIN  
  
        SELECT  
            CAST(U.UsuarioID AS VARCHAR(20)) + '|' +  
            ISNULL(CAST(U.PersonalId AS VARCHAR(30)), '') + '|' +  
            ISNULL(U.UsuarioAlias, '') + '|' +  
            ISNULL(CONVERT(VARCHAR(23), U.UsuarioFechaReg, 121), '') + '|' +  
            ISNULL(U.UsuarioEstado, '') + '|' +  
            ISNULL(U.UsuarioSerie, '') + '|' +  
            CAST(ISNULL(U.EnviaBoleta, 0) AS VARCHAR(1)) + '|' +  
            CAST(ISNULL(U.EnviarFactura, 0) AS VARCHAR(1)) + '|' +  
            CAST(ISNULL(U.EnviaNC, 0) AS VARCHAR(1)) + '|' +  
            CAST(ISNULL(U.EnviaND, 0) AS VARCHAR(1)) + '|' +  
            ISNULL(U.UserRuta, '') + '|' +  
            ISNULL(U.UserRutaOBS, '') + '|' +  
            CAST(ISNULL(U.Administrador, 0) AS VARCHAR(1)) + '|' +  
            ISNULL(U.RutaVentaOBS, '') + '|' +  
            ISNULL(U.RutaIOC, '') + '|' +  
            ISNULL(U.RutaApertura, '') + '|' +  
            ISNULL(CONVERT(VARCHAR(10), U.FechaVencimientoClave, 23), '') + '|' +  
            CASE  
                WHEN U.UsuarioClave IS NULL THEN '0'  
                ELSE '1'  
            END  
            AS Data  
        FROM Usuarios U  
        ORDER BY U.UsuarioAlias;  
  
        RETURN;  
  
    END;  
  
    IF @accion = 'CREAR'  
    BEGIN  
  
        SELECT @personalTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 2;  
  
        SELECT @UsuarioAlias =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 3;  
  
        SELECT @UsuarioEstado =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 4;  
  
        SELECT @UsuarioSerie =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 5;  
  
        SELECT @enviaBoletaTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 6;  
  
        SELECT @enviarFacturaTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 7;  
  
        SELECT @enviaNCTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 8;  
  
        SELECT @enviaNDTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 9;  
  
        SELECT @UserRuta =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 10;  
  
        SELECT @UserRutaOBS =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 11;  
  
        SELECT @administradorTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 12;  
  
        SELECT @RutaVentaOBS =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 13;  
  
        SELECT @RutaIOC =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 14;  
  
        SELECT @RutaApertura =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 15;  
  
        SELECT @fechaTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 16;  
  
        IF ISNULL(@personalTexto, '') = ''  
        BEGIN  
            SELECT 'ERROR|Debe seleccionar un personal.' AS Data;  
            RETURN;  
        END;  
  
  
        IF @personalTexto LIKE '%[^0-9]%'  
           OR LEN(@personalTexto) > 20  
        BEGIN  
            SELECT 'ERROR|El PersonalId no es valido.' AS Data;  
            RETURN;  
        END;  
  
  
        SET @PersonalId =  
            CONVERT(NUMERIC(20,0), @personalTexto);  
  
  
        IF NOT EXISTS  
        (  
            SELECT 1  
            FROM Personal  
            WHERE PersonalId = @PersonalId  
        )  
        BEGIN  
            SELECT 'ERROR|El personal seleccionado no existe.' AS Data;  
            RETURN;  
        END;  
  
        IF EXISTS  
(  
            SELECT 1  
            FROM Usuarios  
            WHERE PersonalId = @PersonalId  
        )  
        BEGIN  
            SELECT  
                'ERROR|El personal seleccionado ya tiene un usuario registrado.'  
                AS Data;  
            RETURN;  
        END;  
  
        IF ISNULL(@UsuarioAlias, '') = ''  
        BEGIN  
            SELECT 'ERROR|Debe ingresar el alias del usuario.' AS Data;  
            RETURN;  
        END;  
  
  
        IF LEN(@UsuarioAlias) > 60  
        BEGIN  
            SELECT 'ERROR|El alias no puede superar los 60 caracteres.' AS Data;  
            RETURN;  
        END;  
  
  
        IF EXISTS  
        (  
            SELECT 1  
            FROM Usuarios  
            WHERE UPPER(LTRIM(RTRIM(UsuarioAlias)))  
                = UPPER(LTRIM(RTRIM(@UsuarioAlias)))  
        )  
        BEGIN  
            SELECT 'ERROR|El alias ingresado ya existe.' AS Data;  
            RETURN;  
        END;  
  
        IF ISNULL(@UsuarioEstado, '') = ''  
            SET @UsuarioEstado = 'ACTIVO';  
  
        IF LEN(ISNULL(@UsuarioSerie, '')) > 4  
        BEGIN  
            SELECT  
                'ERROR|La serie del usuario no puede superar los 4 caracteres.'  
                AS Data;  
            RETURN;  
        END;  
  
        IF ISNULL(@enviaBoletaTexto, '') = ''  
            SET @enviaBoletaTexto = '0';  
  
        IF ISNULL(@enviarFacturaTexto, '') = ''  
            SET @enviarFacturaTexto = '0';  
  
        IF ISNULL(@enviaNCTexto, '') = ''  
            SET @enviaNCTexto = '0';  
  
        IF ISNULL(@enviaNDTexto, '') = ''  
            SET @enviaNDTexto = '0';  
  
        IF ISNULL(@administradorTexto, '') = ''  
            SET @administradorTexto = '0';  
        IF @enviaBoletaTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviaBoleta solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
        IF @enviarFacturaTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviarFactura solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
        IF @enviaNCTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviaNC solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
        IF @enviaNDTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviaND solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
        IF @administradorTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|Administrador solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        SET @EnviaBoleta =  
            CONVERT(BIT, @enviaBoletaTexto);  
  
        SET @EnviarFactura =  
            CONVERT(BIT, @enviarFacturaTexto);  
  
        SET @EnviaNC =  
            CONVERT(BIT, @enviaNCTexto);  
  
        SET @EnviaND =  
            CONVERT(BIT, @enviaNDTexto);  
  
        SET @Administrador =  
            CONVERT(BIT, @administradorTexto);  
  
        IF ISNULL(@fechaTexto, '') <> ''  
        BEGIN  
  
            SET @fechaNormalizada =  
                REPLACE(@fechaTexto, '-', '');  
  
  
            IF LEN(@fechaNormalizada) <> 8  
               OR @fechaNormalizada LIKE '%[^0-9]%'  
               OR ISDATE(@fechaNormalizada) = 0  
            BEGIN  
                SELECT  
                    'ERROR|La fecha de vencimiento de clave no es valida.'  
                    AS Data;  
                RETURN;  
            END;  
  
  
            SET @FechaVencimientoClave =  
                CONVERT(DATE, @fechaNormalizada, 112);  
  
        END  
        ELSE  
        BEGIN  
  
            SET @FechaVencimientoClave = NULL;  
  
        END;  
  
        BEGIN TRY  
  
            INSERT INTO Usuarios  
            (  
                PersonalId,  
                UsuarioAlias,  
                UsuarioClave,  
                UsuarioFechaReg,  
                UsuarioEstado,  
                UsuarioSerie,  
                EnviaBoleta,  
                EnviarFactura,  
                EnviaNC,  
                EnviaND,  
                UserRuta,  
                UserRutaOBS,  
                Administrador,  
                RutaVentaOBS,  
                RutaIOC,  
                RutaApertura,  
                FechaVencimientoClave  
            )  
            VALUES  
            (  
                @PersonalId,  
                @UsuarioAlias,  
                @UsuarioClave,  
                GETDATE(),  
                @UsuarioEstado,  
                NULLIF(@UsuarioSerie, ''),  
                @EnviaBoleta,  
                @EnviarFactura,  
                @EnviaNC,  
                @EnviaND,  
                NULLIF(@UserRuta, ''),  
                NULLIF(@UserRutaOBS, ''),  
                @Administrador,  
                NULLIF(@RutaVentaOBS, ''),  
                NULLIF(@RutaIOC, ''),  
                NULLIF(@RutaApertura, ''),  
                @FechaVencimientoClave  
            );  
  
  
            SET @UsuarioID = SCOPE_IDENTITY();  
  
  
            SELECT  
                'OK|' +  
                CAST(@UsuarioID AS VARCHAR(20)) +  
                '|Usuario registrado correctamente.'  
                AS Data;  
  
        END TRY  
  
        BEGIN CATCH  
  
            IF ERROR_NUMBER() = 547  
            BEGIN  
                SELECT  
                    'ERROR|No se pudo registrar el usuario porque existe una relacion invalida.'  
                    AS Data;  
            END  
            ELSE  
            BEGIN  
                SELECT  
                    'ERROR|' + ERROR_MESSAGE()  
                    AS Data;  
            END  
  
        END CATCH;  
  
  
        RETURN;  
    END;  
  
    IF @accion = 'ACTUALIZAR'  
    BEGIN  
  
        SELECT @idTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 2;  
  
  
        IF ISNULL(@idTexto, '') = ''  
           OR @idTexto LIKE '%[^0-9]%'  
        BEGIN  
            SELECT 'ERROR|El UsuarioID no es valido.' AS Data;  
            RETURN;  
        END;  
  
  
        SET @UsuarioID =  
            CONVERT(INT, @idTexto);  
  
  
        IF NOT EXISTS  
        (  
            SELECT 1  
            FROM Usuarios  
            WHERE UsuarioID = @UsuarioID  
        )  
        BEGIN  
            SELECT  
                'ERROR|El usuario que intenta actualizar no existe.'  
                AS Data;  
            RETURN;  
        END;  
  
  
        SELECT @personalTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 3;  
  
      SELECT @UsuarioAlias =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 4;  
  
        SELECT @UsuarioEstado =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 5;  
  
        SELECT @UsuarioSerie =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 6;  
  
        SELECT @enviaBoletaTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 7;  
  
        SELECT @enviarFacturaTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 8;  
  
        SELECT @enviaNCTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 9;  
  
        SELECT @enviaNDTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 10;  
  
        SELECT @UserRuta =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 11;  
  
        SELECT @UserRutaOBS =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 12;  
  
        SELECT @administradorTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 13;  
  
        SELECT @RutaVentaOBS =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 14;  
  
        SELECT @RutaIOC =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 15;  
  
        SELECT @RutaApertura =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 16;  
  
        SELECT @fechaTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 17;  
  
        IF ISNULL(@personalTexto, '') = ''  
        BEGIN  
            SELECT 'ERROR|Debe seleccionar un personal.' AS Data;  
            RETURN;  
        END;  
  
  
        IF @personalTexto LIKE '%[^0-9]%'  
           OR LEN(@personalTexto) > 20  
        BEGIN  
            SELECT 'ERROR|El PersonalId no es valido.' AS Data;  
            RETURN;  
        END;  
  
  
        SET @PersonalId =  
            CONVERT(NUMERIC(20,0), @personalTexto);  
  
  
        IF NOT EXISTS  
        (  
            SELECT 1  
            FROM Personal  
            WHERE PersonalId = @PersonalId  
        )  
        BEGIN  
            SELECT 'ERROR|El personal seleccionado no existe.' AS Data;  
            RETURN;  
        END;  
        IF EXISTS  
        (  
            SELECT 1  
            FROM Usuarios  
            WHERE PersonalId = @PersonalId  
              AND UsuarioID <> @UsuarioID  
        )  
        BEGIN  
            SELECT  
                'ERROR|El personal seleccionado ya pertenece a otro usuario.'  
                AS Data;  
            RETURN;  
        END;  
  
        IF ISNULL(@UsuarioAlias, '') = ''  
        BEGIN  
            SELECT 'ERROR|Debe ingresar el alias del usuario.' AS Data;  
            RETURN;  
        END;  
  
  
        IF EXISTS  
        (  
            SELECT 1  
            FROM Usuarios  
            WHERE UPPER(LTRIM(RTRIM(UsuarioAlias)))  
                = UPPER(LTRIM(RTRIM(@UsuarioAlias)))  
              AND UsuarioID <> @UsuarioID  
        )  
        BEGIN  
            SELECT  
                'ERROR|Ya existe otro usuario con el mismo alias.'  
                AS Data;  
            RETURN;  
        END;  
  
        IF ISNULL(@UsuarioEstado, '') = ''  
            SET @UsuarioEstado = 'ACTIVO';  
  
        IF LEN(ISNULL(@UsuarioSerie, '')) > 4  
        BEGIN  
            SELECT  
                'ERROR|La serie del usuario no puede superar los 4 caracteres.'  
                AS Data;  
            RETURN;  
        END;  
  
        IF ISNULL(@enviaBoletaTexto, '') = ''  
            SET @enviaBoletaTexto = '0';  
  
        IF ISNULL(@enviarFacturaTexto, '') = ''  
            SET @enviarFacturaTexto = '0';  
  
        IF ISNULL(@enviaNCTexto, '') = ''  
            SET @enviaNCTexto = '0';  
  
        IF ISNULL(@enviaNDTexto, '') = ''  
            SET @enviaNDTexto = '0';  
  
        IF ISNULL(@administradorTexto, '') = ''  
            SET @administradorTexto = '0';  
  
  
        IF @enviaBoletaTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviaBoleta solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        IF @enviarFacturaTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviarFactura solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        IF @enviaNCTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviaNC solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        IF @enviaNDTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviaND solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        IF @administradorTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|Administrador solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        SET @EnviaBoleta =  
            CONVERT(BIT, @enviaBoletaTexto);  
  
        SET @EnviarFactura =  
            CONVERT(BIT, @enviarFacturaTexto);  
  
        SET @EnviaNC =  
            CONVERT(BIT, @enviaNCTexto);  
  
        SET @EnviaND =  
            CONVERT(BIT, @enviaNDTexto);  
  
        SET @Administrador =  
            CONVERT(BIT, @administradorTexto);  
  
        IF ISNULL(@fechaTexto, '') <> ''  
        BEGIN  
  
            SET @fechaNormalizada =  
                REPLACE(@fechaTexto, '-', '');  
  
  
            IF LEN(@fechaNormalizada) <> 8  
               OR @fechaNormalizada LIKE '%[^0-9]%'  
               OR ISDATE(@fechaNormalizada) = 0  
            BEGIN  
                SELECT  
                    'ERROR|La fecha de vencimiento de clave no es valida.'  
                    AS Data;  
                RETURN;  
            END;  
  
  
            SET @FechaVencimientoClave =  
                CONVERT(DATE, @fechaNormalizada, 112);  
  
        END  
        ELSE  
        BEGIN  
  
            SET @FechaVencimientoClave = NULL;  
  
        END;  
  
        BEGIN TRY  
  
            UPDATE Usuarios  
            SET  
                PersonalId            = @PersonalId,  
                UsuarioAlias          = @UsuarioAlias,  
  
                UsuarioClave =  
                    CASE  
                        WHEN @UsuarioClave IS NULL  
                            THEN UsuarioClave  
                        ELSE @UsuarioClave  
                    END,  
  
                UsuarioEstado         = @UsuarioEstado,  
                UsuarioSerie          = NULLIF(@UsuarioSerie, ''),  
                EnviaBoleta           = @EnviaBoleta,  
                EnviarFactura         = @EnviarFactura,  
                EnviaNC               = @EnviaNC,  
                EnviaND               = @EnviaND,  
                UserRuta              = NULLIF(@UserRuta, ''),  
                UserRutaOBS           = NULLIF(@UserRutaOBS, ''),  
                Administrador      = @Administrador,  
                RutaVentaOBS          = NULLIF(@RutaVentaOBS, ''),  
                RutaIOC               = NULLIF(@RutaIOC, ''),  
                RutaApertura          = NULLIF(@RutaApertura, ''),  
                FechaVencimientoClave = @FechaVencimientoClave  
  
            WHERE UsuarioID = @UsuarioID;  
  
  
            SELECT  
                'OK|Usuario actualizado correctamente.'  
                AS Data;  
  
        END TRY  
  
        BEGIN CATCH  
  
            IF ERROR_NUMBER() = 547  
            BEGIN  
                SELECT  
                    'ERROR|No se pudo actualizar el usuario porque existe una relacion invalida.'  
                    AS Data;  
            END  
            ELSE  
            BEGIN  
                SELECT  
                    'ERROR|' + ERROR_MESSAGE()  
                    AS Data;  
            END  
  
        END CATCH;  
  
  
        RETURN;  
    END;  
  
    IF @accion = 'ELIMINAR'  
    BEGIN  
  
        SELECT @idTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 2;  
  
  
        IF ISNULL(@idTexto, '') = ''  
           OR @idTexto LIKE '%[^0-9]%'  
        BEGIN  
            SELECT 'ERROR|El UsuarioID no es valido.' AS Data;  
            RETURN;  
        END;  
  
  
        SET @UsuarioID =  
            CONVERT(INT, @idTexto);  
  
  
        IF NOT EXISTS  
        (  
            SELECT 1  
            FROM Usuarios  
            WHERE UsuarioID = @UsuarioID  
        )  
        BEGIN  
            SELECT  
                'ERROR|El usuario que intenta eliminar no existe.'  
                AS Data;  
            RETURN;  
        END;  
  
  
        BEGIN TRY  
  
            DELETE FROM Usuarios  
            WHERE UsuarioID = @UsuarioID;  
  
  
            SELECT  
                'OK|Usuario eliminado correctamente.'  
                AS Data;  
  
        END TRY  
  
        BEGIN CATCH  
  
            IF ERROR_NUMBER() = 547  
            BEGIN  
                SELECT  
                    'ERROR|No se puede eliminar el usuario porque tiene registros relacionados.'  
                    AS Data;  
            END  
            ELSE  
            BEGIN  
                SELECT  
                    'ERROR|' + ERROR_MESSAGE()  
                    AS Data;  
            END  
  
        END CATCH;  
  
  
        RETURN;  
    END;  
  
    SELECT  
        'ERROR|La accion ingresada no es valida.'  
        AS Data;  
  
END;

GO

CREATE OR ALTER PROCEDURE dbo.uspCajaInsertaCsvWeb
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @p1 int, @p2 int, @p3 int, @p4 int, @p5 int, @p6 int,
            @p7 int, @p8 int, @p9 int, @p10 int, @p11 int, @p12 int;
    DECLARE @CajaId numeric(38), @CajaCierre varchar(40), @MontoIniSOl decimal(18, 2),
            @CajaEncargado varchar(60), @CajaUsuario varchar(60), @CajaEstado varchar(40),
            @CajaIngresos decimal(18, 2), @CajaDeposito decimal(18, 2),
            @CajaSalidas decimal(18, 2), @CajaTotal decimal(18, 2), @UsuarioId int,
            @Observacion varchar(max), @CompaniaId int, @FlagCaja bit = 0;

    SET @Data = LTRIM(RTRIM(@Data));
    SET @p1 = CHARINDEX('|', @Data, 0);
    SET @p2 = CHARINDEX('|', @Data, @p1 + 1);
    SET @p3 = CHARINDEX('|', @Data, @p2 + 1);
    SET @p4 = CHARINDEX('|', @Data, @p3 + 1);
    SET @p5 = CHARINDEX('|', @Data, @p4 + 1);
    SET @p6 = CHARINDEX('|', @Data, @p5 + 1);
    SET @p7 = CHARINDEX('|', @Data, @p6 + 1);
    SET @p8 = CHARINDEX('|', @Data, @p7 + 1);
    SET @p9 = CHARINDEX('|', @Data, @p8 + 1);
    SET @p10 = CHARINDEX('|', @Data, @p9 + 1);
    SET @p11 = CHARINDEX('|', @Data, @p10 + 1);
    SET @p12 = LEN(@Data) + 1;

    SET @CajaId = CONVERT(numeric(38), SUBSTRING(@Data, 1, @p1 - 1));
    SET @CajaCierre = SUBSTRING(@Data, @p1 + 1, @p2 - @p1 - 1);
    SET @MontoIniSOl = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p2 + 1, @p3 - @p2 - 1));
    SET @CajaEncargado = SUBSTRING(@Data, @p3 + 1, @p4 - @p3 - 1);
    SET @CajaUsuario = SUBSTRING(@Data, @p4 + 1, @p5 - @p4 - 1);
    SET @CajaEstado = SUBSTRING(@Data, @p5 + 1, @p6 - @p5 - 1);
    SET @CajaIngresos = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p6 + 1, @p7 - @p6 - 1));
    SET @CajaDeposito = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p7 + 1, @p8 - @p7 - 1));
    SET @CajaSalidas = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p8 + 1, @p9 - @p8 - 1));
    SET @CajaTotal = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p9 + 1, @p10 - @p9 - 1));
    SET @UsuarioId = CONVERT(int, SUBSTRING(@Data, @p10 + 1, @p11 - @p10 - 1));
    SET @Observacion = SUBSTRING(@Data, @p11 + 1, @p12 - @p11 - 1);

    IF @CajaId = 0
    BEGIN
        BEGIN TRANSACTION;

        SELECT @CompaniaId = p.CompaniaId
          FROM dbo.Usuarios u WITH (UPDLOCK, HOLDLOCK)
          INNER JOIN dbo.Personal p ON p.PersonalId = u.PersonalId
         WHERE u.UsuarioID = @UsuarioId;

        SELECT TOP (1) @FlagCaja = CONVERT(bit, ISNULL(i.ValorNum, 0))
          FROM dbo.Indicador i
         WHERE i.CompaniaId = @CompaniaId
           AND i.Descripcion = 'MULTIPLES_CAJAS'
         ORDER BY i.Id DESC;

        IF ISNULL(@FlagCaja, 0) = 0
           AND EXISTS
           (
               SELECT 1
                 FROM dbo.Caja c WITH (UPDLOCK, HOLDLOCK)
                 INNER JOIN dbo.Usuarios u ON u.UsuarioID = c.UsuarioId
                 INNER JOIN dbo.Personal p ON p.PersonalId = u.PersonalId
                WHERE c.CajaEstado = 'ACTIVO'
                  AND p.CompaniaId = @CompaniaId
           )
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'SOLO_UNA_CAJA';
            RETURN;
        END;

        INSERT INTO dbo.Caja
        VALUES (GETDATE(), @CajaCierre, @MontoIniSOl, @CajaEncargado, @CajaUsuario,
                @CajaEstado, @CajaIngresos, @CajaDeposito, @CajaSalidas, @CajaTotal,
                @UsuarioId, @Observacion);
        SET @CajaId = @@IDENTITY;

        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'TOTAL EFECTIVO', 0, 0, 0, '', 'T', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'VITRINA', 0, 0, 0, '', 'D', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'SENCILLO', 0, 0, 0, '', 'T', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'IOC', 0, 0, 0, '', 'T', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'REVISTAS', 0, 0, 0, '', 'D', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'COPIAS Y OTROS', 0, 0, 0, '', 'D', 'V', 0, '', '', '', '');
        INSERT INTO dbo.Monedas VALUES (0, 0, '200.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '100.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '50.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '20.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '10.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '5.00', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '2.00', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '1.00', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '0.50', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '0.20', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '0.10', 0, 'M', @CajaId);

        COMMIT TRANSACTION;
        SELECT 'true';
        RETURN;
    END;

    IF @CajaEstado = 'CERRADA'
    BEGIN
        DECLARE @Descripcion varchar(max);
        SET @Descripcion = ISNULL((SELECT TOP 1 d.DetalleConcepto + ' TOTAL S/ ' + CONVERT(varchar(max), CAST(d.DetalleMonto AS money), 1)
                                    FROM dbo.CajaDetalle d
                                    WHERE d.RutaImagen LIKE '%file.png%'
                                      AND d.CajaId = @CajaId
                                      AND d.NotaId = 0
                                      AND d.DetalleMonto >= 500000
                                    ORDER BY d.DetalleId ASC), '0');
        IF @Descripcion <> '0'
        BEGIN
            SELECT 'Falta Adjuntar el Archivo de: ' + @Descripcion;
            RETURN;
        END;
    END;

    UPDATE dbo.Caja
       SET CajaCierre = @CajaCierre,
           MontoIniSOl = @MontoIniSOl,
           CajaEncargado = @CajaEncargado,
           CajaUsuario = @CajaUsuario,
           CajaEstado = @CajaEstado,
           CajaIngresos = @CajaIngresos,
           CajaDeposito = @CajaDeposito,
           CajaSalidas = @CajaSalidas,
           CajaTotal = @CajaTotal,
           UsuarioId = @UsuarioId,
           Observacion = @Observacion
     WHERE CajaId = @CajaId;
    SELECT 'true';
END;

GO

CREATE OR ALTER PROCEDURE dbo.uspEditarConteoCajaWEB @ListaOrden varchar(max) AS BEGIN SET NOCOUNT ON; EXEC dbo.uspEditarConteoCaja @ListaOrden = @ListaOrden; END

GO

CREATE OR ALTER PROCEDURE dbo.uspEditarNotaPedido
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

    

    BEGIN TRANSACTION;

    

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

    

    DELETE FROM DetallePedido
    WHERE NotaId = @NotaId;

    

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

    

    WHILE LEN(@Detalle) > 0
    BEGIN

        

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

        

        UPDATE Producto
           SET ProductoCantidad =
                   ProductoCantidad
                   - (@Cantidad * @ValorUM)
        WHERE IdProducto = @IdProducto;

    END;

    

    COMMIT TRANSACTION;

    SELECT 'UPDATED';
END;

GO

CREATE OR ALTER PROCEDURE dbo.uspEditarRBweb
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

CREATE OR ALTER PROCEDURE dbo.[uspEliminarCajaDetalleWEB] @Datas varchar(max)
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

CREATE OR ALTER PROCEDURE dbo.[uspEliminarPagoVWEB] @ListaOrden varchar(Max)  
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

CREATE OR ALTER PROCEDURE dbo.uspGuardarCredencialesSunatweb
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
           CompaniaClave = @ClaveCertificado
     WHERE CompaniaId = @CompaniaId

    UPDATE dbo.Indicador
       SET Area = 'CPE',
           TipoIndicador = 2,
           ValorTexto1 = NULL,
           ValorNum = @Entorno,
           FechaActualizacion = SYSDATETIME()
     WHERE CompaniaId = @CompaniaId
       AND Descripcion = 'TIPO_PROCESO_CPE';

    IF @@ROWCOUNT = 0
        INSERT INTO dbo.Indicador (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
        VALUES (@CompaniaId, 'CPE', 2, NULL, 'TIPO_PROCESO_CPE', NULL, @Entorno);
END

GO

CREATE OR ALTER PROCEDURE dbo.uspGuardarListaPreciosPdfWEB
    @Productos xml,
    @ProductoUsuario varchar(60)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Filas TABLE
    (
        Codigo varchar(300) NOT NULL,
        Nombre varchar(1000) NOT NULL,
        Costo decimal(18,4) NOT NULL,
        Observacion varchar(300) NOT NULL,
        PV decimal(18,2) NOT NULL,
        SV decimal(18,2) NOT NULL
    );

    ;WITH ProductosXml AS
    (
        SELECT
            Codigo = UPPER(LTRIM(RTRIM(Fila.value('@codigo', 'varchar(300)')))),
            Nombre = UPPER(LTRIM(RTRIM(Fila.value('@nombre', 'varchar(1000)')))),
            Costo = Fila.value('@costo', 'decimal(18,4)'),
            Observacion = UPPER(LTRIM(RTRIM(Fila.value('@observacion', 'varchar(300)')))),
            PV = Fila.value('@pv', 'decimal(18,2)'),
            SV = Fila.value('@sv', 'decimal(18,2)')
        FROM @Productos.nodes('/productos/producto') AS Datos(Fila)
    )
    INSERT INTO @Filas (Codigo, Nombre, Costo, Observacion, PV, SV)
    SELECT
        Codigo,
        REPLACE(CASE WHEN LEFT(Nombre, 4) = 'DXN ' THEN LTRIM(SUBSTRING(Nombre, 5, 1000)) ELSE Nombre END, '''', ''),
        Costo,
        REPLACE(Observacion, ';', ''),
        PV,
        SV
    FROM ProductosXml;

    IF NOT EXISTS (SELECT 1 FROM @Filas)
    BEGIN
        RAISERROR('No hay productos para guardar.', 16, 1);
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM @Filas WHERE Codigo = '' OR Nombre = '')
    BEGIN
        RAISERROR('Cada producto debe tener cÃ³digo y nombre.', 16, 1);
        RETURN;
    END;

    IF EXISTS (SELECT Codigo FROM @Filas GROUP BY Codigo HAVING COUNT(*) > 1)
    BEGIN
        RAISERROR('La lista contiene cÃ³digos repetidos.', 16, 1);
        RETURN;
    END;

    DECLARE @Actualizados TABLE
    (
        IdProducto numeric(20,0) NOT NULL,
        Stock decimal(18,2) NOT NULL,
        Costo decimal(18,4) NOT NULL
    );
    DECLARE @Nuevos TABLE (Codigo varchar(300) NOT NULL PRIMARY KEY);

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE Producto
        SET
            IdSubLinea = 1,
            ProductoNombre = Filas.Nombre,
            ProductoMarca = 'DXN',
            ProductoUM = 'UNIDAD',
            ProductoCosto = Filas.Costo,
            ProductoVenta = Filas.Costo,
            ProductoINV = N'S',
            AlmacenId = 1,
            ProductoUbicacion = '',
            ProductoObs = Filas.Observacion,
            ProductoUsuario = @ProductoUsuario,
            ProductoFecha = GETDATE(),
            ProductoPV = Filas.PV,
            ProductoSV = Filas.SV,
            ProductoxCaja = 1
        OUTPUT INSERTED.IdProducto, INSERTED.ProductoCantidad, INSERTED.ProductoCosto
            INTO @Actualizados (IdProducto, Stock, Costo)
        FROM Producto
        INNER JOIN @Filas AS Filas ON Filas.Codigo = Producto.ProductoCodigo;

        INSERT INTO Producto
        (
            IdSubLinea, ProductoCodigo, ProductoNombre, ProductoMarca,
            ProductoTipoCambio, ProductoCostoDolar, ProductoUM, ProductoCosto,
            ProductoVenta, AlmacenId, ProductoUbicacion, ProductoCantidad,
            ProductoObs, ProductoEstado, ProductoUsuario, ProductoFecha,
            ProductoImagen, ValorCritico, ProductoPV, ProductoSV, ProductoxCaja,
            ProductoINV, AplicaFB, UltimoINV
        )
        OUTPUT INSERTED.ProductoCodigo INTO @Nuevos (Codigo)
        SELECT
            1, Filas.Codigo, Filas.Nombre, 'DXN',
            0, 0, 'UNIDAD', Filas.Costo,
            Filas.Costo, 1, '', 0,
            Filas.Observacion, 'BUENO', @ProductoUsuario, GETDATE(),
            '', 0, Filas.PV, Filas.SV, 1,
            N'S', N'S', NULL
        FROM @Filas AS Filas
        WHERE NOT EXISTS
        (
            SELECT 1 FROM Producto WHERE Producto.ProductoCodigo = Filas.Codigo
        );

        INSERT INTO Kardex
        (
            IdProducto, KardexFecha, KardexMotivo, KardexDocumento,
            StockInicial, CantidadIngreso, CantidadSalida, PrecioCosto, StockFinal,
            KadexConcepto, Usuario, CLIENTE, CODIGOCLIENTE, NROTRANSAC,
            TipoCodigo, Serie, TipoOperacion, Consideracion, DocuId, CompraId, Estado
        )
        SELECT
            Actualizados.IdProducto, GETDATE(), 'Edita Cantidad', 'Edita Cantidad',
            Actualizados.Stock, 0, 0, Actualizados.Costo, Actualizados.Stock,
            'INGRESO', @ProductoUsuario, '', '', '', '', '', '', 'S', '', '', 'E'
        FROM @Actualizados AS Actualizados;

        INSERT INTO Kardex
        (
            IdProducto, KardexFecha, KardexMotivo, KardexDocumento,
            StockInicial, CantidadIngreso, CantidadSalida, PrecioCosto, StockFinal,
            KadexConcepto, Usuario, CLIENTE, CODIGOCLIENTE, NROTRANSAC,
            TipoCodigo, Serie, TipoOperacion, Consideracion, DocuId, CompraId, Estado
        )
        SELECT
            Producto.IdProducto, GETDATE(), 'Nuevo Registro', 'Nuevo Registro',
            0, 0, 0, Producto.ProductoCosto, 0,
            'INGRESO', @ProductoUsuario, '', '', '', '', '', '', 'S', '', '', 'E'
        FROM Producto
        INNER JOIN @Nuevos AS Nuevos ON Nuevos.Codigo = Producto.ProductoCodigo;

        COMMIT TRANSACTION;

        SELECT
            Registrados = (SELECT COUNT(*) FROM @Nuevos),
            Actualizados = (SELECT COUNT(*) FROM @Actualizados);
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;

GO

CREATE OR ALTER PROCEDURE dbo.uspinsertarNotaBweb     @ListaOrden varchar(max) AS BEGIN     SET NOCOUNT ON;      DECLARE         @pos1 int,         @orden varchar(max),         @detalle varchar(max);      SET @pos1 = CHARINDEX('[', @ListaOrden, 1);      IF @pos1 <= 0     BEGIN         RAISERROR('Formato de orden invalido.', 16, 1);         RETURN;     END;      SET @orden = SUBSTRING(         @ListaOrden,         1,         @pos1 - 1     );      SET @detalle = SUBSTRING(         @ListaOrden,         @pos1 + 1,         LEN(@ListaOrden) - @pos1     );      DECLARE @campos TABLE     (         Pos int IDENTITY(1,1) NOT NULL,         Valor varchar(max) NULL     );      DECLARE         @start int,         @end int;      SET @start = 1;      WHILE @start <= LEN(@orden) + 1     BEGIN         SET @end = CHARINDEX('|', @orden, @start);          IF @end = 0             SET @end = LEN(@orden) + 1;          INSERT INTO @campos         (             Valor         )         VALUES         (             SUBSTRING(                 @orden,                 @start,                 @end - @start             )         );          SET @start = @end + 1;     END;      DECLARE         @NotaDocu varchar(60),         @ClienteId numeric(20),         @NotaUsuario varchar(60),         @NotaFormaPago varchar(60),         @NotaCondicion varchar(60),         @NotaDireccion varchar(max),         @CompaniaUbigeo varchar(250),          @NotaSubtotal decimal(18,2),         @NotaMovilidad decimal(18,2),         @NotaDescuento decimal(18,2),         @NotaTotal decimal(18,2),         @NotaAcuenta decimal(18,2),         @NotaSaldo decimal(18,2),         @NotaAdicional decimal(18,2),         @NotaTarjeta decimal(18,2),         @NotaPagar decimal(18,2),          @NotaEstado varchar(60),         @CompaniaId int,         @NotaEntrega varchar(40),         @NotaConcepto varchar(60),          @Serie varchar(60),         @Numero varchar(60),         @NotaGanancia decimal(18,2),          @Letra varchar(max),         @DocuAdicional decimal(18,2),         @DocuHash varchar(250),         @EstadoSunat varchar(80),         @DocuSubtotal decimal(18,2),         @DocuIGV decimal(18,2),          @UsuarioId int,         @NotaTransaccion varchar(250),         @Miembro varchar(300),         @CodigoCliente varchar(80),          @ICBPER decimal(18,2),         @DocuGravada decimal(18,2),          @ConceptoOBS varchar(80),         @EstadoOBS varchar(20),         @PV varchar(40),         @Image varchar(max),          @CodigoRes varchar(80),         @Responsable varchar(300),          @EntidadBancaria varchar(80),         @Efectivo decimal(18,2),         @Deposito decimal(18,2),         @NroOperacion varchar(80),          @ClienteRazon varchar(140),         @ClienteRuc varchar(40),         @ClienteDni varchar(40),         @DireccionFiscal varchar(max),          @TipoCodigo char(20),         @cod varchar(60),          @NotaId numeric(38),         @DocuId numeric(38);      SELECT @NotaDocu = Valor     FROM @campos     WHERE Pos = 1;      SELECT @ClienteId =         CONVERT(             numeric(20),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 2;      SELECT @NotaUsuario = Valor     FROM @campos     WHERE Pos = 3;      SELECT @NotaFormaPago = Valor     FROM @campos     WHERE Pos = 4;      SELECT @NotaCondicion = Valor     FROM @campos     WHERE Pos = 5;      SELECT @NotaDireccion = Valor     FROM @campos     WHERE Pos = 6;      SELECT @NotaSubtotal =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 7;      SELECT @NotaMovilidad =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 8;      SELECT @NotaDescuento =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 9;      SELECT @NotaTotal =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 10;      SELECT @NotaAcuenta =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 11;      SELECT @NotaSaldo =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 12;      SELECT @NotaAdicional =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 13;      SELECT @NotaTarjeta =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 14;      SELECT @NotaPagar =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 15;      SELECT @NotaEstado = Valor     FROM @campos     WHERE Pos = 16;      SELECT @CompaniaId =         CONVERT(             int,             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 17;      SELECT @NotaEntrega = Valor     FROM @campos     WHERE Pos = 18;      SELECT @NotaConcepto = Valor     FROM @campos     WHERE Pos = 19;      SELECT @Serie = Valor     FROM @campos     WHERE Pos = 20;      SELECT @Numero = Valor     FROM @campos     WHERE Pos = 21;      SELECT @NotaGanancia =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 22;      SELECT @Letra = Valor     FROM @campos     WHERE Pos = 23;      SELECT @DocuAdicional =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 24;      SELECT @DocuHash = Valor     FROM @campos     WHERE Pos = 25;      SELECT @EstadoSunat = Valor     FROM @campos     WHERE Pos = 26;      SELECT @DocuSubtotal =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 27;      SELECT @DocuIGV =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 28;      SELECT @UsuarioId =         CONVERT(             int,             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 29;
    /* DNX_VALIDACION_ASISTENCIA */
    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Asistencia AS a
        INNER JOIN dbo.Usuarios AS u ON u.PersonalId = a.PersonalId
        WHERE u.UsuarioID = @UsuarioId
          AND a.Fecha = CONVERT(date, GETDATE())
    )
    BEGIN
        SELECT 'NO ASISTIO';
        RETURN;
    END;      SELECT @NotaTransaccion = Valor     FROM @campos     WHERE Pos = 30;      SELECT @Miembro = Valor     FROM @campos     WHERE Pos = 31;      SELECT @CodigoCliente = Valor     FROM @campos     WHERE Pos = 32;      SELECT @ICBPER =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 33;      SELECT @DocuGravada =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 34;      SELECT @ConceptoOBS = Valor     FROM @campos     WHERE Pos = 35;      SELECT @EstadoOBS = Valor     FROM @campos     WHERE Pos = 36;      SELECT @PV = Valor     FROM @campos     WHERE Pos = 37;      SELECT @Image = Valor     FROM @campos     WHERE Pos = 38;      SELECT @CodigoRes = Valor     FROM @campos     WHERE Pos = 39;      SELECT @Responsable = Valor     FROM @campos     WHERE Pos = 40;      SELECT @EntidadBancaria = Valor     FROM @campos     WHERE Pos = 41;      SELECT @Efectivo =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 42;      SELECT @Deposito =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 43;      SELECT @NroOperacion = Valor     FROM @campos     WHERE Pos = 44;      SET @NotaDocu =         ISNULL(             NULLIF(LTRIM(RTRIM(@NotaDocu)), ''),             'BOLETA'         );      SET @NotaUsuario =         ISNULL(@NotaUsuario, '');      SET @NotaFormaPago =         ISNULL(             NULLIF(@NotaFormaPago, ''),             'EFECTIVO'         );      SET @NotaCondicion =         ISNULL(             NULLIF(@NotaCondicion, ''),             'ALCONTADO'         );      SET @NotaDireccion =         ISNULL(             NULLIF(@NotaDireccion, ''),             '-'         );      SET @NotaEstado =         ISNULL(             NULLIF(@NotaEstado, ''),             'PENDIENTE'         );      SET @CompaniaId =         ISNULL(             NULLIF(@CompaniaId, 0),             1         );      SET @NotaEntrega =         ISNULL(             NULLIF(@NotaEntrega, ''),             'INMEDIATA'         );      SET @NotaConcepto =         ISNULL(             NULLIF(@NotaConcepto, ''),             'MERCADERIA'         );      SET @Serie =         ISNULL(             NULLIF(@Serie, ''),             CASE                 WHEN @NotaDocu = 'FACTURA'                     THEN 'FA01'                 ELSE 'BA01'             END         );      SET @Letra = ISNULL(@Letra, '');     SET @DocuHash = ISNULL(@DocuHash, '');      SET @EstadoSunat =         ISNULL(             NULLIF(@EstadoSunat, ''),             'PENDIENTE'         );      SET @NotaTransaccion = ISNULL(@NotaTransaccion, '');     SET @Miembro = ISNULL(@Miembro, '');     SET @CodigoCliente = ISNULL(@CodigoCliente, '');      SET @ConceptoOBS =         ISNULL(             NULLIF(@ConceptoOBS, ''),             'VENTA'         );      SET @EstadoOBS =         ISNULL(             NULLIF(@EstadoOBS, ''),             'EMITIDO'         );      SET @CodigoRes = ISNULL(@CodigoRes, '');     SET @Responsable = ISNULL(@Responsable, '');      SET @EntidadBancaria =         ISNULL(             NULLIF(@EntidadBancaria, ''),             '-'         );      SET @NroOperacion =         ISNULL(@NroOperacion, '');      IF @NotaDocu = 'FACTURA'         SET @TipoCodigo = '01';     ELSE IF @NotaDocu = 'PROFORMA V'         SET @TipoCodigo = '00';     ELSE         SET @TipoCodigo = '03';      SELECT TOP 1         @ClienteRazon =             NULLIF(                 LTRIM(RTRIM(ClienteRazon)),                 ''             ),          @ClienteRuc =             NULLIF(                 LTRIM(RTRIM(ClienteRuc)),                 ''             ),          @ClienteDni =             NULLIF(                 LTRIM(RTRIM(ClienteDni)),                 ''             ),          @DireccionFiscal =             NULLIF(                 LTRIM(RTRIM(ClienteDireccion)),                 ''             )     FROM Cliente     WHERE ClienteId = @ClienteId;      SET @ClienteRazon =         ISNULL(             @ClienteRazon,             CASE                 WHEN @Miembro <> ''                     THEN @Miembro                 ELSE 'VARIOS'             END         );      SET @ClienteRuc = ISNULL(@ClienteRuc, '');     SET @ClienteDni = ISNULL(@ClienteDni, '');      IF @NotaDocu = 'BOLETA'        AND @ClienteRuc = ''        AND @ClienteDni = ''     BEGIN         SET @ClienteDni = '00000000';     END;      SET @DireccionFiscal =         ISNULL(             @DireccionFiscal,             @NotaDireccion         );      IF NULLIF(@DireccionFiscal, '') IS NULL         SET @DireccionFiscal = '-';      IF @NotaFormaPago <> 'EFECTIVO'     BEGIN         IF @Efectivo IS NULL             SET @Efectivo = 0;          IF @Deposito IS NULL            OR @Deposito = 0             SET @Deposito = @NotaPagar;     END;     ELSE     BEGIN         IF @Efectivo IS NULL            OR @Efectivo = 0             SET @Efectivo = @NotaPagar;          IF @Deposito IS NULL             SET @Deposito = 0;     END;      IF @NotaCondicion = 'CREDITO'     BEGIN         SET @NotaEstado = 'EMITIDO';         SET @NotaSaldo = @NotaPagar;         SET @NotaAcuenta = 0;     END;     ELSE IF @NotaDocu <> 'FACTURA'         AND @NotaDocu <> 'PROFORMA V'     BEGIN         SET @NotaEstado = 'CANCELADO';         SET @NotaSaldo = 0;         SET @NotaAcuenta = @NotaPagar;     END;      IF @NotaTransaccion <> ''        AND EXISTS        (             SELECT 1             FROM NotaPedido             WHERE NotaTransaccion = @NotaTransaccion               AND ISNULL(NotaEstado, '') <> 'ANULADO'        )     BEGIN         SELECT 'EXISTE';         RETURN;     END;      IF @Deposito > 0        AND @NotaCondicion <> 'PAGO/VARIOS'        AND NULLIF(LTRIM(RTRIM(@NroOperacion)), '') IS NULL     BEGIN         SELECT 'OPERACION_REQUERIDA';         RETURN;     END;      IF @NroOperacion <> ''        AND ISNULL(@EntidadBancaria, '-') <> '-'        AND EXISTS        (             SELECT 1             FROM NotaPedido             WHERE EntidadBancaria = @EntidadBancaria               AND NroOperacion = @NroOperacion               AND ISNULL(NotaEstado, '') <> 'ANULADO'        )     BEGIN         SELECT 'OPERACION';         RETURN;     END;      DECLARE @CajaId numeric(38);      SELECT TOP (1)         @CajaId = CajaId     FROM Caja     WHERE CajaEstado = 'ACTIVO'       AND UsuarioId = @UsuarioId     ORDER BY CajaId DESC;      IF ISNULL(@CajaId, 0) = 0     BEGIN         SELECT 'false';         RETURN;     END;      SELECT @CompaniaUbigeo = NULLIF(LTRIM(RTRIM(CompaniaNomUBG)), '')     FROM Compania     WHERE CompaniaId = @CompaniaId;      SET @CompaniaUbigeo = ISNULL(@CompaniaUbigeo, '');      BEGIN TRY          BEGIN TRANSACTION;          UPDATE Cliente         SET ClienteDespacho = @NotaDireccion         WHERE ClienteId = @ClienteId;          SET @NotaDireccion = @CompaniaUbigeo;          DELETE FROM TemporalVenta         WHERE UsuarioID = @UsuarioId;          SELECT @cod =             ISNULL(                 (                     SELECT TOP 1                         dbo.genenerarNroFactura(                             @Serie,                             @CompaniaId,                             @NotaDocu                         )                     FROM DocumentoVenta                 ),                 '00000001'             );          INSERT INTO NotaPedido         (             NotaDocu,             ClienteId,             NotaFecha,             NotaUsuario,             NotaFormaPago,             NotaCondicion,             NotaFechaPago,             NotaDireccion,             NotaSubtotal,             NotaMovilidad,             NotaDescuento,             NotaTotal,             NotaAcuenta,             NotaSaldo,             NotaAdicional,             NotaTarjeta,             NotaPagar,             NotaEstado,             CompaniaId,             NotaEntrega,             ModificadoPor,             FechaEdita,             NotaConcepto,             NotaSerie,             NotaNumero,             NotaGanancia,             CajaId,             NotaTransaccion,             ICBPER,             ConceptoOBS,             EstadoOBS,             CodigoRes,             Responsable,             EntidadBancaria,             NroOperacion,             Efectivo,             Deposito         )         VALUES         (             @NotaDocu,             @ClienteId,             GETDATE(),             @NotaUsuario,             @NotaFormaPago,             @NotaCondicion,             GETDATE(),             @NotaDireccion,             @NotaSubtotal,             @NotaMovilidad,             @NotaDescuento,             @NotaTotal,             @NotaAcuenta,             @NotaSaldo,             @NotaAdicional,             @NotaTarjeta,             @NotaPagar,             @NotaEstado,             @CompaniaId,             @NotaEntrega,             '',             '',             @NotaConcepto,             @Serie,             @cod,             @NotaGanancia,             @CajaId,             @NotaTransaccion,             @ICBPER,             @ConceptoOBS,             @EstadoOBS,             @CodigoRes,             @Responsable,             @EntidadBancaria,             @NroOperacion,             @Efectivo,             @Deposito         );          SET @NotaId = SCOPE_IDENTITY();          INSERT INTO DocumentoVenta         (             CompaniaId,             NotaId,             DocuDocumento,             DocuNumero,             ClienteId,             DocuRegistro,             DocuEmision,             DocuCondicion,             DocuLetras,             DocuSubTotal,             DocuIgv,             DocuTotal,             DocuSaldo,             DocuUsuario,             DocuEstado,             DocuSerie,             TipoCodigo,             DocuAdicional,             DocuAsociado,             DocuConcepto,             DocuNroGuia,             DocuHash,             EstadoSunat,             DocuOperacion,             DocuTransaccion,             ICBPER,             CodigoSunat,             MensajeSunat,             FormaPago,             EntidadBancaria,             NroOperacion,             Efectivo,             Deposito         )         VALUES         (             @CompaniaId,             @NotaId,             @NotaDocu,             @cod,             @ClienteId,             GETDATE(),             GETDATE(),             @NotaCondicion,             @Letra,             @DocuSubtotal,             @DocuIGV,             @NotaPagar,             0,             @NotaUsuario,             'EMITIDO',             @Serie,             @TipoCodigo,             @DocuAdicional,             '',             'VENTA',             '',             @DocuHash,              CASE                 WHEN @NotaDocu = 'PROFORMA V'                     THEN 'ENVIADO'                 ELSE @EstadoSunat             END,              @NotaConcepto,             @NotaTransaccion,             @ICBPER,             '',             '',             @NotaFormaPago,             @EntidadBancaria,             @NroOperacion,             @Efectivo,             @Deposito         );          SET @DocuId = SCOPE_IDENTITY();          INSERT INTO dbo.DocumentoVentaCpeWeb         (             DocuId,             ClienteRazon,             ClienteRuc,             ClienteDni,             DireccionFiscal,             DocuPdfUrl,             DocuXmlUrl,             DocuCdrUrl,             DocuFechaPago         )         VALUES         (             @DocuId,             @ClienteRazon,             @ClienteRuc,             @ClienteDni,             @DireccionFiscal,             '',             '',             '',             GETDATE()         );          IF @NotaCondicion = 'ALCONTADO'            AND @NotaDocu <> 'PROFORMA V'         BEGIN             IF UPPER(LTRIM(RTRIM(@ConceptoOBS))) = 'VENTA LIBRE'             BEGIN                 INSERT INTO dbo.CajaDetalle                 (                     CajaId, DetalleFecha, NotaId, DetalleMovimiento,                     DetalleConcepto, DetalleMonto, DetalleEfectivo,                     DetalleVuelto, RutaImagen, Estado, Vista,                     NotaIdB, LiquidaId, FormaPago, EntidadBancaria, NroOperacion                 )                 VALUES                 (                     @CajaId, GETDATE(), 0, 'INGRESO',                     'VENTA LIBRE DOCUMENTO ' + @Serie + '-' + @cod +                     ' CODIGO: ' + @CodigoCliente + ' (' + @Miembro + ')' +                     ' FORMA DE PAGO: ' + @NotaFormaPago,                     @NotaTotal, @NotaTotal, 0, @Image, 'D', '',                     @NotaId, '', @NotaFormaPago, @EntidadBancaria, @NroOperacion                 );             END;              IF @Deposito > 0                AND UPPER(LTRIM(RTRIM(@ConceptoOBS))) IN ('VENTA', 'IOC', 'CASHBILL', 'VENTA LIBRE')             BEGIN                 INSERT INTO dbo.CajaDetalle                 (                     CajaId, DetalleFecha, NotaId, DetalleMovimiento,                     DetalleConcepto, DetalleMonto, DetalleEfectivo,                     DetalleVuelto, RutaImagen, Estado, Vista,                     NotaIdB, LiquidaId, FormaPago, EntidadBancaria, NroOperacion                 )                 VALUES                 (                     @CajaId, GETDATE(), 0, 'SALIDA',                     'VENTA DEL OBS DOCUMENTO ' + @Serie + '-' + @cod +                     ' CODIGO: ' + @CodigoCliente + ' (' + @Miembro + ')' +                     ' FORMA DE PAGO: ' + @NotaFormaPago +        ' ENTIDAD BANCARIA: ' + @EntidadBancaria +                     ' NRO OPERACION: ' + @NroOperacion,                     @Deposito, @Deposito, 0, @Image, 'D', '',                     @NotaId, '', @NotaFormaPago, @EntidadBancaria, @NroOperacion                 );             END;         END;          DECLARE detalle_cursor CURSOR LOCAL FAST_FORWARD         FOR             SELECT splitdata             FROM dbo.fnSplitString(@detalle, ';')             WHERE LEN(LTRIM(RTRIM(splitdata))) > 0;          DECLARE @Columna varchar(max);          DECLARE @detalleCampos TABLE         (             Pos int NOT NULL PRIMARY KEY,             Valor varchar(max) NULL         );          DECLARE @campoPos int;          OPEN detalle_cursor;          FETCH NEXT FROM detalle_cursor         INTO @Columna;          WHILE @@FETCH_STATUS = 0         BEGIN              DELETE FROM @detalleCampos;              SET @campoPos = 1;             SET @start = 1;              WHILE @start <= LEN(@Columna) + 1             BEGIN                  SET @end =                     CHARINDEX(                         '|',                         @Columna,                         @start                     );                  IF @end = 0                     SET @end = LEN(@Columna) + 1;                  INSERT INTO @detalleCampos                 (                     Pos,                     Valor                 )                 VALUES                 (                     @campoPos,                     SUBSTRING(                         @Columna,                         @start,                         @end - @start                     )                 );                  SET @campoPos = @campoPos + 1;                 SET @start = @end + 1;             END;              DECLARE                 @IdProducto numeric(20),                 @DetalleCantidad decimal(18,2),                 @DetalleUm varchar(40),                 @Descripcion varchar(max),                 @DetalleCosto decimal(18,4),                 @DetallePrecio decimal(18,2),                 @DetallePV decimal(18,2),                 @DetalleSV decimal(18,2),                 @DetalleImporte decimal(18,2),                 @DetalleEstado varchar(60),                 @ValorUM decimal(18,4),                 @CantidadSaldo decimal(18,2),                 @IniciaStock decimal(18,2),                 @StockFinal decimal(18,2);              SELECT @IdProducto =                 CONVERT(                     numeric(20),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 1;              SELECT @DetalleCantidad =                 CONVERT(                     decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 2;              SELECT @DetalleUm = Valor             FROM @detalleCampos             WHERE Pos = 3;              SELECT @Descripcion = Valor             FROM @detalleCampos             WHERE Pos = 4;              SELECT @DetalleCosto =                 CONVERT(                     decimal(18,4),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 5;              SELECT @DetallePrecio =                 CONVERT(                     decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 6;              SELECT @DetallePV =                 CONVERT(                     decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 7;              SELECT @DetalleSV =                 CONVERT(                     decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 8;              SELECT @DetalleImporte =                 CONVERT(    decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 9;              SELECT @DetalleEstado = Valor             FROM @detalleCampos             WHERE Pos = 10;              SELECT @ValorUM =                 CONVERT(                     decimal(18,4),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 11;              SET @DetalleUm =                 ISNULL(                     NULLIF(@DetalleUm, ''),                     'UNIDAD'                 );              SET @Descripcion =                 ISNULL(@Descripcion, '');              SET @DetalleEstado =                 ISNULL(                     NULLIF(@DetalleEstado, ''),                     'PENDIENTE'                 );              IF @ValorUM IS NULL                OR @ValorUM = 0             BEGIN                 SET @ValorUM = 1;             END;              IF @NotaEntrega = 'INMEDIATA'                 SET @CantidadSaldo = 0;             ELSE                 SET @CantidadSaldo = @DetalleCantidad;              INSERT INTO DetallePedido             (                 NotaId,                 IdProducto,                 DetalleCantidad,                 DetalleUm,                 DetalleDescripcion,                 DetalleCosto,                 DetallePrecio,                 DetalleImporte,                 DetalleEstado,                 CantidadSaldo,                 ValorUM,                 DetallePV,                 DetalleSV             )             VALUES             (                 @NotaId,                 @IdProducto,                 @DetalleCantidad,                 @DetalleUm,                 @Descripcion,                 @DetalleCosto,                 @DetallePrecio,                 @DetalleImporte,                 @DetalleEstado,                 @CantidadSaldo,                 @ValorUM,                 @DetallePV,                 @DetalleSV             );              IF @DocuId <> 0             BEGIN                  INSERT INTO DetalleDocumento                 (                     DocuId,                     IdProducto,                     DetalleCantidad,                     DetallPrecio,                     DetalleImporte,                     DetalleNotaId,                     DetalleUM,                     ValorUM                 )                 VALUES                 (                     @DocuId,                     @IdProducto,                     @DetalleCantidad,                     @DetallePrecio,                     @DetalleImporte,                     @NotaId,                     @DetalleUm,                     @ValorUM                 );              END;              IF @NotaDocu <> 'FACTURA'             BEGIN                  SELECT TOP 1                     @IniciaStock = ProductoCantidad                 FROM Producto                 WHERE IdProducto = @IdProducto;                  SET @IniciaStock =                     ISNULL(@IniciaStock, 0);                  SET @StockFinal =                     @IniciaStock - @DetalleCantidad;                  INSERT INTO Kardex                 (                     IdProducto,                     KardexFecha,                     KardexMotivo,                     KardexDocumento,                     StockInicial,                     CantidadIngreso,                     CantidadSalida,                     PrecioCosto,                     StockFinal,                     KadexConcepto,                     Usuario,                     CLIENTE,                     CODIGOCLIENTE,                     NROTRANSAC,                     TipoCodigo,                     Serie,                     TipoOperacion,                     Consideracion,                     DocuId,                     CompraId,                     Estado                 )                 VALUES                 (                     @IdProducto,                     GETDATE(),               'Salida por Venta',                     @cod,                     @IniciaStock,                     0,                     @DetalleCantidad,                     @DetalleCosto,                     @StockFinal,                     'SALIDA',                     @NotaUsuario,                     @Miembro,                     @CodigoCliente,                     @NotaTransaccion,                     @TipoCodigo,                     @Serie,                     '01',                      CASE                         WHEN @NotaEntrega = 'INMEDIATA'                             THEN 'S'                         ELSE 'N'                     END,                      CONVERT(varchar(40), @DocuId),                     '',                     'E'                 );                  IF @NotaEntrega = 'INMEDIATA'                 BEGIN                      UPDATE Producto                     SET ProductoCantidad =                         ProductoCantidad - @DetalleCantidad                     WHERE IdProducto = @IdProducto;                  END;              END;              FETCH NEXT FROM detalle_cursor             INTO @Columna;          END;          CLOSE detalle_cursor;         DEALLOCATE detalle_cursor;          COMMIT TRANSACTION;          SELECT             CONVERT(varchar(38), @NotaId)             + N'¬'             + @cod;      END TRY      BEGIN CATCH          IF CURSOR_STATUS('local', 'detalle_cursor') > -1         BEGIN             CLOSE detalle_cursor;             DEALLOCATE detalle_cursor;         END;          IF @@TRANCOUNT > 0             ROLLBACK TRANSACTION;          DECLARE             @ErrMsg nvarchar(4000),             @ErrSeverity int,             @ErrState int;          SELECT             @ErrMsg = ERROR_MESSAGE(),             @ErrSeverity = ERROR_SEVERITY(),             @ErrState = ERROR_STATE();          RAISERROR(             @ErrMsg,             @ErrSeverity,             @ErrState         );      END CATCH;  END;

GO

CREATE OR ALTER PROCEDURE dbo.[uspInsertarPagoVariosWEB] @ListaOrden varchar(Max)          
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

CREATE OR ALTER PROCEDURE dbo.uspinsertarRBweb
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

CREATE OR ALTER procedure [dbo].[usplistaConteoWEB]
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

CREATE OR ALTER procedure [dbo].[usplistaDetalleConteoWEB]
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

CREATE OR ALTER PROCEDURE dbo.uspListarComprasweb
    @Estado VARCHAR(60) = NULL,
    @Page INT = 1,
    @PageSize INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    SET @Page =
        CASE
            WHEN @Page < 1 THEN 1
            ELSE @Page
        END;

    SET @PageSize =
        CASE
            WHEN @PageSize < 1 THEN 50
            WHEN @PageSize > 500 THEN 500
            ELSE @PageSize
        END;

    SELECT
        CompraId,
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
        CAST(NULL AS DECIMAL(18, 2)) AS CompraPercepcion
    FROM Compras
    WHERE @Estado IS NULL
       OR CompraEstado = @Estado
    ORDER BY CompraId DESC
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;

GO

CREATE OR ALTER PROCEDURE dbo.[usplistarPagoVariosWEB] @UsuarioId varchar(20)    
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

CREATE OR ALTER PROCEDURE dbo.uspObtenerCajaActivaWEB
    @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CajaId NUMERIC(38);

    SELECT TOP (1)
        @CajaId = CajaId
    FROM dbo.Caja
    WHERE UsuarioId = @UsuarioId
      AND CajaEstado = 'ACTIVO'
    ORDER BY CajaId DESC;

    IF ISNULL(@CajaId, 0) = 0
        RETURN;

    DECLARE
        @MontoInicial DECIMAL(18, 2),
        @Ingresos DECIMAL(18, 2),
        @Tarjeta DECIMAL(18, 2),
        @Depositos DECIMAL(18, 2),
        @Salidas DECIMAL(18, 2);

    SELECT
        @MontoInicial = ISNULL(MontoIniSOl, 0)
    FROM dbo.Caja
    WHERE CajaId = @CajaId;

    SELECT
        @Ingresos = ISNULL(SUM(ISNULL(Efectivo, 0)), 0),
        @Tarjeta = ISNULL(
            SUM(
                CASE
                    WHEN UPPER(ISNULL(NotaFormaPago, '')) LIKE '%TARJETA%'
                        THEN ISNULL(Deposito, 0)
                    ELSE 0
                END
            ),
            0
        ),
        @Depositos = ISNULL(
            SUM(
                CASE
                    WHEN UPPER(ISNULL(NotaFormaPago, '')) NOT LIKE '%TARJETA%'
                        THEN ISNULL(Deposito, 0)
                    ELSE 0
                END
            ),
            0
        )
    FROM dbo.NotaPedido
    WHERE CajaId = @CajaId
      AND ISNULL(NotaEstado, '') <> 'ANULADO';

    SELECT
        @Salidas = ISNULL(
            SUM(ISNULL(DetalleEfectivo, DetalleMonto)),
            0
        )
    FROM dbo.CajaDetalle
    WHERE CajaId = @CajaId
      AND DetalleMovimiento = 'SALIDA'
      AND ISNULL(NotaId, 0) = 0;

    SELECT
        CONVERT(BIGINT, c.CajaId) AS CajaId,
        CONVERT(VARCHAR(19), c.CajaFecha, 126) AS FechaApertura,
        ISNULL(c.MontoIniSOl, 0) AS MontoInicial,
        ISNULL(c.CajaEncargado, '') AS Encargado,
        ISNULL(c.CajaUsuario, '') AS Usuario,
        ISNULL(c.Observacion, '') AS Observacion,
        @Ingresos AS VentasEfectivo,
        @Tarjeta AS VentasTarjeta,
        @Depositos AS VentasDeposito,
        @Salidas AS Salidas,
        @MontoInicial + @Ingresos - @Salidas AS EfectivoEsperado
    FROM dbo.Caja c
    WHERE c.CajaId = @CajaId;

    SELECT
        Billete,
        ISNULL(Efectivo, 0) AS Cantidad
    FROM dbo.Monedas
    WHERE CajaId = @CajaId
    ORDER BY CONVERT(DECIMAL(18, 2), Billete) DESC;
END;

GO

CREATE OR ALTER PROCEDURE dbo.uspObtenerCredencialesSunatweb
    @CompaniaId int
AS
BEGIN
    SET NOCOUNT ON

    SELECT CompaniaUserSecun AS UsuarioSOL,
           ComapaniaPWD AS ClaveSOL,
           CompaniaPFX AS CertificadoPFX,
           CompaniaClave AS ClaveCertificado,
           COALESCE(configuracion.ValorNum, 3) AS Entorno
      FROM dbo.Compania
      OUTER APPLY
      (
          SELECT TOP (1) ValorNum
          FROM dbo.Indicador
          WHERE CompaniaId = dbo.Compania.CompaniaId
            AND Descripcion = 'TIPO_PROCESO_CPE'
          ORDER BY Id DESC
      ) configuracion
     WHERE CompaniaId = @CompaniaId
END

GO

CREATE OR ALTER PROCEDURE dbo.uspResumenFechaweb
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

CREATE OR ALTER procedure [dbo].[uspRetornaBoletaPorTicketWEB]
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

CREATE OR ALTER procedure [dbo].[uspRetornarBoletasWEB]
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

CREATE OR ALTER PROCEDURE dbo.[usptraerCajerosWEB] @Fecha Date
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

CREATE OR ALTER PROCEDURE dbo.[uspTraerGastosWEB] @Fecha date    
as    
begin    
Declare @Aviso int    
set @Aviso=(select COUNT(c.ConteoId)from ConteoMonedas c    
where FechaConteo=@Fecha)    
if(@Aviso=0)    
begin   
CREATE TABLE #tmpOBS (FechaTransaccion date,NotaTransaccion varchar(80),TipoVenta nvarchar(3))  
CREATE TABLE #tmpNota (NotaTransaccion varchar(80),CajaId numeric(38))  
  
insert into #tmpOBS (FechaTransaccion,NotaTransaccion,TipoVenta)  
select t.FechaTransaccion,T.NotaTransaccion,t.TipoVenta  
from TABLAOBS T    
where T.FechaTransaccion between @Fecha and @Fecha  
  
  
insert into #tmpNota (NotaTransaccion,CajaId)  
select n.NotaTransaccion,n.CajaId  
from NotaPedido n    
where n.NotaFechaPago between @Fecha and @Fecha  
  
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

CREATE OR ALTER PROCEDURE dbo.[uspTraerGastosAWEB] @CajaId numeric(38)
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

CREATE OR ALTER PROCEDURE [dbo].[usptraerSecuenciaResumen]  
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

CREATE OR ALTER PROCEDURE dbo.[uspTraeTodasMonedasWEB] @Fecha date
as
begin
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

CREATE OR ALTER PROCEDURE dbo.uspValidaCantCajasWeb
    @CajaId numeric(38, 0),
    @UsuarioId int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompaniaId int, @FlagCaja bit = 0;

    SELECT @CompaniaId = p.CompaniaId
      FROM dbo.Usuarios u
      INNER JOIN dbo.Personal p ON p.PersonalId = u.PersonalId
     WHERE u.UsuarioID = @UsuarioId;

    SELECT TOP (1) @FlagCaja = CONVERT(bit, ISNULL(i.ValorNum, 0))
      FROM dbo.Indicador i
     WHERE i.CompaniaId = @CompaniaId
       AND i.Descripcion = 'MULTIPLES_CAJAS'
     ORDER BY i.Id DESC;

    IF ISNULL(@FlagCaja, 0) = 1
    BEGIN
        SELECT 'true';
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
          FROM dbo.Caja c WITH (UPDLOCK, HOLDLOCK)
          INNER JOIN dbo.Usuarios u ON u.UsuarioID = c.UsuarioId
          INNER JOIN dbo.Personal p ON p.PersonalId = u.PersonalId
         WHERE c.CajaEstado = 'ACTIVO'
           AND p.CompaniaId = @CompaniaId
           AND c.CajaId <> @CajaId
    )
    BEGIN
        SELECT 'SOLO_UNA_CAJA';
        RETURN;
    END;

    SELECT 'true';
END;

GO

CREATE OR ALTER PROCEDURE dbo.[uspValidarAperturaWEB] @Fecha date
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

CREATE OR ALTER PROCEDURE dbo.uspValidaUsuarioweb
    @Data VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @p1 INT,
        @p2 INT;

    DECLARE
        @Usuario VARCHAR(150),
        @Clave VARCHAR(150);

    SET @Data = LTRIM(RTRIM(@Data));

    SET @p1 = CHARINDEX('|', @Data, 0);
    SET @p2 = CHARINDEX('|', @Data, @p1 + 1);

    IF @p2 = 0
        SET @p2 = LEN(@Data) + 1;

    SET @Usuario = SUBSTRING(
        @Data,
        1,
        @p1 - 1
    );

    SET @Clave = SUBSTRING(
        @Data,
        @p1 + 1,
        @p2 - @p1 - 1
    );

    SELECT ISNULL(
        (
            SELECT STUFF(
            (
                SELECT TOP 1
                    '¬'
                    + CONVERT(VARCHAR, U.UsuarioID) + '|'
                    + CONVERT(VARCHAR, p.PersonalId) + '|'
                    + ISNULL(a.AreaNombre, '') + '|'
                    + (
                        SUBSTRING(
                            ISNULL(p.PersonalNombres, '') + ' ',
                            1,
                            CHARINDEX(
                                ' ',
                                ISNULL(p.PersonalNombres, '') + ' '
                            ) - 1
                        )
                        + ' '
                        + SUBSTRING(
                            ISNULL(p.PersonalApellidos, '') + ' ',
                            1,
                            CHARINDEX(
                                ' ',
                                ISNULL(p.PersonalApellidos, '') + ' '
                            ) - 1
                        )
                    ) + '|'
                    + CONVERT(VARCHAR, p.CompaniaId) + '|'
                    + ISNULL(c.CompaniaRazonSocial, '') + '|'
                    + ISNULL(CONVERT(VARCHAR(10), U.FechaVencimientoClave, 23), '') + '|'
                    + ISNULL(CONVERT(VARCHAR(30), configuracion.DescuentoMax), '0') + '|'
                    + ISNULL(c.CompaniaRUC, '') + '|'
                    + ISNULL(c.CompaniaNomUBG, '') + '|'
                    + ISNULL(c.CompaniaComercial, '') + '|'
                    + ISNULL(c.CompaniaDirecSunat, '') + '|'
                    + ISNULL(c.CompaniaUserSecun, '') + '|'
                    + ISNULL(c.ComapaniaPWD, '') + '|'
                    + ISNULL(c.CompaniaPFX, '') + '|'
                    + ISNULL(c.CompaniaClave, '') + '|'
                    + ISNULL(CONVERT(VARCHAR(10), configuracion.TipoProceso), '3') + '|'
                    + ISNULL(c.CompaniaTelefono, '') + '|'
                    + ISNULL(CONVERT(VARCHAR(1), configuracion.BoletaPorLote), '1') + '|'
                    + ISNULL(CONVERT(VARCHAR(1), configuracion.FlagCaptura), '0')
                FROM dbo.Usuarios U
                INNER JOIN dbo.Personal p
                    ON p.PersonalId = U.PersonalId
                INNER JOIN dbo.Area a
                    ON a.AreaId = p.AreaId
                INNER JOIN dbo.Compania c
                    ON c.CompaniaId = p.CompaniaId
                OUTER APPLY
                (
                    SELECT
                        MAX(CASE WHEN i.Descripcion = 'DESCUENTO_MAXIMO' THEN i.ValorDecimal END) AS DescuentoMax,
                        MAX(CASE WHEN i.Descripcion = 'TIPO_PROCESO_CPE' THEN i.ValorNum END) AS TipoProceso,
                        MAX(CASE WHEN i.Descripcion = 'BOLETA_POR_LOTE' THEN i.ValorNum END) AS BoletaPorLote,
                        MAX(CASE WHEN i.Descripcion = 'CAPTURA_HTML' THEN i.ValorNum END) AS FlagCaptura
                    FROM dbo.Indicador i
                    WHERE i.CompaniaId = p.CompaniaId
                ) configuracion
                WHERE U.UsuarioAlias = @Usuario
                  AND dbo.desincrectar(U.UsuarioClave) = @Clave
                  AND U.UsuarioEstado = 'ACTIVO'
                  AND p.PersonalEstado = 'ACTIVO'
                FOR XML PATH('')
            ),
            1,
            1,
            '')
        ),
        '~'
    );
END;

GO

CREATE OR ALTER PROCEDURE dbo.[uspInsertarConteoCajaWEB] @ListaOrden varchar(Max)  
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

CREATE OR ALTER PROCEDURE [dbo].[usp_DeleteOldBackupFiles] 
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

CREATE OR ALTER PROCEDURE dbo.usp_Sublinea
    @Data VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @accion          VARCHAR(20),
        @IdSublinea      INT,
        @IdLinea         INT,
        @NombreSublinea  VARCHAR(150),
        @CodigoSUNAT     VARCHAR(50),
        @Vista           VARCHAR(10),
        @idTexto         VARCHAR(20),
        @lineaTexto      VARCHAR(20),
        @p1              INT,
        @p2              INT,
        @p3              INT,
        @p4              INT,
        @p5              INT;

    SET @Data = LTRIM(RTRIM(ISNULL(@Data, '')));

    IF @Data = ''
    BEGIN
        SELECT 'ERROR|No se enviaron datos.' AS Data;
        RETURN;
    END;

    SET @p1 = CHARINDEX('|', @Data);

    IF @p1 = 0
        SET @accion = UPPER(LTRIM(RTRIM(@Data)));
    ELSE
        SET @accion = UPPER(
            LTRIM(RTRIM(
                SUBSTRING(@Data, 1, @p1 - 1)
            ))
        );

    IF @accion = 'LISTAR'
    BEGIN

        SELECT
            CAST(IdSublinea AS VARCHAR(20)) + '|' +
            CAST(IdLinea AS VARCHAR(20)) + '|' +
            ISNULL(NombreSublinea, '') + '|' +
            ISNULL(CodigoSUNAT, '') + '|' +
            ISNULL(Vista, 'V') AS Data
        FROM Sublinea
        ORDER BY NombreSublinea;

        RETURN;
    END;

    IF @accion = 'CREAR'
    BEGIN

        SET @p2 = CHARINDEX('|', @Data, @p1 + 1);
        SET @p3 = CHARINDEX('|', @Data, @p2 + 1);
        SET @p4 = CHARINDEX('|', @Data, @p3 + 1);
        IF @p1 = 0
           OR @p2 = 0
           OR @p3 = 0
        BEGIN
            SELECT
                'ERROR|Formato incorrecto. Use CREAR|IdLinea|NombreSublinea|CodigoSUNAT|Vista'
                AS Data;
            RETURN;
        END;

        SET @lineaTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                @p2 - @p1 - 1
            )
        ));


        IF ISNULL(@lineaTexto, '') = ''
           OR @lineaTexto LIKE '%[^0-9]%'
        BEGIN
            SELECT 'ERROR|El ID de la linea no es valido.' AS Data;
            RETURN;
        END;


        SET @IdLinea = CONVERT(INT, @lineaTexto);

        IF NOT EXISTS
        (
            SELECT 1
            FROM Linea
            WHERE IdLinea = @IdLinea
        )
        BEGIN
            SELECT 'ERROR|La linea seleccionada no existe.' AS Data;
            RETURN;
        END;

        SET @NombreSublinea = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p2 + 1,
                @p3 - @p2 - 1
            )
        ));


        IF ISNULL(@NombreSublinea, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el nombre de la sublinea.' AS Data;
            RETURN;
        END;

        IF @p4 = 0
        BEGIN
            SET @CodigoSUNAT = LTRIM(RTRIM(
                SUBSTRING(
                    @Data,
                    @p3 + 1,
                    LEN(@Data)
                )
            ));

            SET @Vista = 'V';

        END
        ELSE
        BEGIN

            SET @CodigoSUNAT = LTRIM(RTRIM(
                SUBSTRING(
                    @Data,
                    @p3 + 1,
                    @p4 - @p3 - 1
                )
            ));


            SET @Vista = LTRIM(RTRIM(
                SUBSTRING(
                    @Data,
                    @p4 + 1,
                    LEN(@Data)
                )
            ));
            IF ISNULL(@Vista, '') = ''
                SET @Vista = 'V';

        END;

        IF ISNULL(@CodigoSUNAT, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el codigo SUNAT.' AS Data;
            RETURN;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM Sublinea
            WHERE IdLinea = @IdLinea
              AND UPPER(LTRIM(RTRIM(NombreSublinea)))
                  = UPPER(LTRIM(RTRIM(@NombreSublinea)))
        )
        BEGIN
            SELECT
                'ERROR|Ya existe una sublinea con ese nombre dentro de la linea seleccionada.'
                AS Data;
            RETURN;
        END;

        BEGIN TRY

            INSERT INTO Sublinea
            (
                IdLinea,
                NombreSublinea,
                CodigoSUNAT,
                Vista
            )
            VALUES
            (
                @IdLinea,
                @NombreSublinea,
                @CodigoSUNAT,
                @Vista
            );


            SET @IdSublinea = SCOPE_IDENTITY();


            SELECT
                'OK|' +
                CAST(@IdSublinea AS VARCHAR(20)) +
                '|Sublinea registrada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE()
                AS Data;

        END CATCH;


        RETURN;
    END;

    IF @accion = 'ACTUALIZAR'
    BEGIN

        SET @p2 = CHARINDEX('|', @Data, @p1 + 1);
        SET @p3 = CHARINDEX('|', @Data, @p2 + 1);
        SET @p4 = CHARINDEX('|', @Data, @p3 + 1);
        SET @p5 = CHARINDEX('|', @Data, @p4 + 1);


        IF @p1 = 0
           OR @p2 = 0
           OR @p3 = 0
           OR @p4 = 0
        BEGIN
            SELECT
                'ERROR|Formato incorrecto. Use ACTUALIZAR|IdSublinea|IdLinea|NombreSublinea|CodigoSUNAT|Vista'
                AS Data;
            RETURN;
        END;

        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                @p2 - @p1 - 1
            )
        ));


        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN
            SELECT 'ERROR|El ID de la sublinea no es valido.' AS Data;
            RETURN;
        END;


        SET @IdSublinea = CONVERT(INT, @idTexto);

        IF NOT EXISTS
        (
            SELECT 1
            FROM Sublinea
            WHERE IdSublinea = @IdSublinea
        )
        BEGIN
            SELECT 'ERROR|La sublinea que intenta actualizar no existe.' AS Data;
            RETURN;
        END;

        SET @lineaTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p2 + 1,
                @p3 - @p2 - 1
            )
        ));


        IF ISNULL(@lineaTexto, '') = ''
           OR @lineaTexto LIKE '%[^0-9]%'
        BEGIN
            SELECT 'ERROR|El ID de la linea no es valido.' AS Data;
            RETURN;
        END;


        SET @IdLinea = CONVERT(INT, @lineaTexto);

        IF NOT EXISTS
        (
            SELECT 1
            FROM Linea
            WHERE IdLinea = @IdLinea
        )
        BEGIN
            SELECT 'ERROR|La linea seleccionada no existe.' AS Data;
            RETURN;
        END;

        SET @NombreSublinea = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p3 + 1,
                @p4 - @p3 - 1
            )
        ));


        IF ISNULL(@NombreSublinea, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el nombre de la sublinea.' AS Data;
            RETURN;
        END;

        IF @p5 = 0
        BEGIN

            SET @CodigoSUNAT = LTRIM(RTRIM(
                SUBSTRING(
                    @Data,
                    @p4 + 1,
                    LEN(@Data)
                )
            ));

            SET @Vista = 'V';

        END
        ELSE
        BEGIN

            SET @CodigoSUNAT = LTRIM(RTRIM(
                SUBSTRING(
                    @Data,
                    @p4 + 1,
                    @p5 - @p4 - 1
                )
            ));


            SET @Vista = LTRIM(RTRIM(
                SUBSTRING(
                    @Data,
                    @p5 + 1,
                    LEN(@Data)
                )
            ));


            IF ISNULL(@Vista, '') = ''
                SET @Vista = 'V';

        END;

        IF ISNULL(@CodigoSUNAT, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el codigo SUNAT.' AS Data;
            RETURN;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM Sublinea
            WHERE IdLinea = @IdLinea
              AND UPPER(LTRIM(RTRIM(NombreSublinea)))
                  = UPPER(LTRIM(RTRIM(@NombreSublinea)))
              AND IdSublinea <> @IdSublinea
        )
        BEGIN
            SELECT
                'ERROR|Ya existe otra sublinea con ese nombre dentro de la linea seleccionada.'
                AS Data;
            RETURN;
        END;

        BEGIN TRY

            UPDATE Sublinea
            SET
                IdLinea        = @IdLinea,
                NombreSublinea = @NombreSublinea,
                CodigoSUNAT    = @CodigoSUNAT,
                Vista          = @Vista
            WHERE IdSublinea = @IdSublinea;


            SELECT
                'OK|Sublinea actualizada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE()
                AS Data;

        END CATCH;


        RETURN;
    END;

    IF @accion = 'ELIMINAR'
    BEGIN

        IF @p1 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar el ID de la sublinea.' AS Data;
            RETURN;
        END;


        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                LEN(@Data)
            )
        ));


        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN
            SELECT 'ERROR|El ID de la sublinea no es valido.' AS Data;
            RETURN;
        END;


        SET @IdSublinea = CONVERT(INT, @idTexto);
        IF NOT EXISTS
        (
            SELECT 1
            FROM Sublinea
            WHERE IdSublinea = @IdSublinea
        )
        BEGIN
            SELECT 'ERROR|La sublinea que intenta eliminar no existe.' AS Data;
            RETURN;
        END;

        BEGIN TRY

            DELETE FROM Sublinea
            WHERE IdSublinea = @IdSublinea;


            SELECT
                'OK|Sublinea eliminada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            IF ERROR_NUMBER() = 547
            BEGIN
                SELECT
                    'ERROR|No se puede eliminar la sublinea porque tiene registros relacionados.'
                    AS Data;
            END
            ELSE
            BEGIN
                SELECT
                    'ERROR|' + ERROR_MESSAGE()
                    AS Data;
            END

        END CATCH;


        RETURN;
    END;

    SELECT
        'ERROR|La accion ingresada no es valida.'
        AS Data;

END;

GO

CREATE OR ALTER procedure [dbo].[uspConsultaDNI]
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

CREATE OR ALTER PROCEDURE [dbo].[uspListaDespachoFecha]
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

CREATE OR ALTER procedure [dbo].[uspListaPersonalED]  
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

CREATE OR ALTER PROCEDURE dbo.uspListarCajaWEB
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CONVERT(BIGINT, CajaId) AS CajaId,
        CONVERT(VARCHAR(19), CajaFecha, 126) AS FechaApertura,
        ISNULL(CajaCierre, '') AS FechaCierre,
        ISNULL(MontoIniSOl, 0) AS MontoInicial,
        ISNULL(CajaEncargado, '') AS Encargado,
        ISNULL(CajaUsuario, '') AS Usuario,
        ISNULL(CajaEstado, '') AS Estado,
        ISNULL(Observacion, '') AS Observacion
    FROM dbo.Caja
    ORDER BY CajaId DESC;
END;

GO

CREATE OR ALTER PROCEDURE [dbo].[uspListarDespacho]
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

CREATE OR ALTER procedure [dbo].[uspTraerEscaneo]
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

CREATE OR ALTER procedure [dbo].[uspTraerEscaneoB]
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

CREATE OR ALTER PROCEDURE dbo.uspValidaCantCajas
    @CajaId NUMERIC(38, 0),
    @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM Caja WITH (UPDLOCK, HOLDLOCK)
        WHERE CajaEstado = 'ACTIVO'
          AND UsuarioId = @UsuarioId
          AND CajaId <> @CajaId
    )
    BEGIN
        SELECT 'USUARIO_ACTIVO';
        RETURN;
    END;

    IF (
        SELECT COUNT(*)
        FROM Caja WITH (UPDLOCK, HOLDLOCK)
        WHERE CajaEstado = 'ACTIVO'
          AND CajaId <> @CajaId
    ) >= 3
    BEGIN
        SELECT 'NO CERRO';
        RETURN;
    END;

    SELECT 'true';
END;

GO

CREATE OR ALTER procedure [dbo].[uspValidarNotaCre]      
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

-- FIN DEFINICIONES

DECLARE @Esperados int = 54;
DECLARE @Instalados int;

SELECT @Instalados = COUNT(*)
FROM sys.procedures
WHERE schema_id = SCHEMA_ID(N'dbo')
  AND name IN
  (
      N'anularDocumentoWEB', N'editarCompaniaWEB', N'editarProductoWEB', N'ingresarProductoWEB',
      N'LDdocumentosweb', N'listaNotaPedido', N'listarCajaWEB', N'listarCajaFechaWEB',
      N'listarDetaCajaWEB', N'usp_Area', N'usp_Feriado', N'usp_Maquina', N'usp_Personal',
      N'usp_Usuario', N'uspCajaInsertaCsvWeb', N'uspEditarConteoCajaWEB',
      N'uspEditarNotaPedido', N'uspEditarRBweb', N'uspEliminarCajaDetalleWEB',
      N'uspEliminarPagoVWEB', N'uspGuardarCredencialesSunatweb',
      N'uspGuardarListaPreciosPdfWEB', N'uspInsertarConteoCajaWEB',
      N'uspinsertarNotaBweb', N'uspInsertarPagoVariosWEB', N'uspinsertarRBweb',
      N'usplistaConteoWEB', N'usplistaDetalleConteoWEB', N'uspListarComprasweb',
      N'usplistarPagoVariosWEB', N'uspObtenerCajaActivaWEB',
      N'uspObtenerCredencialesSunatweb', N'uspResumenFechaweb',
      N'uspRetornaBoletaPorTicketWEB', N'uspRetornarBoletasWEB', N'usptraerCajerosWEB',
      N'uspTraerGastosWEB', N'uspTraerGastosAWEB', N'usptraerSecuenciaResumen',
      N'uspTraeTodasMonedasWEB', N'uspValidaCantCajasWeb', N'uspValidarAperturaWEB',
      N'uspValidaUsuarioweb', N'usp_DeleteOldBackupFiles', N'usp_Sublinea',
      N'uspConsultaDNI', N'uspListaDespachoFecha', N'uspListaPersonalED',
      N'uspListarCajaWEB', N'uspListarDespacho', N'uspTraerEscaneo',
      N'uspTraerEscaneoB', N'uspValidaCantCajas', N'uspValidarNotaCre'
  );

IF @Instalados <> @Esperados
    THROW 51000, 'Validación fallida: no se instalaron los 54 procedimientos requeridos.', 1;

-- FIN PROCEDIMIENTOS
