SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON;
CREATE TABLE #Manual(
	[KardexId] [numeric](38, 0) IDENTITY(1,1) NOT NULL,
	[IdProducto] [numeric](20, 0) NULL,
	[KardexFecha] [datetime] NULL,
	[KardexMotivo] [varchar](60) NULL,
	[KardexDocumento] [varchar](60) NULL,
	[StockInicial] [decimal](18, 2) NULL,
	[CantidadIngreso] [decimal](18, 2) NULL,
	[CantidadSalida] [decimal](18, 2) NULL,
	[PrecioCosto] [decimal](18, 4) NULL,
	[StockFinal] [decimal](18, 2) NULL,
	[KadexConcepto] [varchar](40) NULL,
	[Usuario] [varchar](60) NULL,
	[CLIENTE] [varchar](300) NULL,
	[CODIGOCLIENTE] [varchar](80) NULL,
	[NROTRANSAC] [varchar](80) NULL,
	[TipoCodigo] [nvarchar](10) NULL,
	[Serie] [nvarchar](10) NULL,
	[TipoOperacion] [nvarchar](10) NULL,
	[Consideracion] [nvarchar](1) NULL,
	[DocuId] [varchar](40) NULL,
	[CompraId] [varchar](40) NULL,
	[Estado] [nvarchar](1) NULL,
PRIMARY KEY CLUSTERED
(
	[KardexId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

insert into #Manual
select de.IdProducto,do.DocuEmision,
case when(do.TipoCodigo='07')
then 'Ingreso por N-Credito'
else 'Salida por Venta' end as KsrdexMotivo,
do.DocuNumero,0,
case when(do.TipoCodigo='07')
then de.DetalleCantidad
else '0' end as CantidadIngreso,
case when(do.TipoCodigo='07')
then '0'
else de.DetalleCantidad end as CantidadSalida,
convert(decimal(18,2),de.DetallPrecio/1.18),'0',
case when(do.TipoCodigo='07')
then 'INGRESO'
else 'SALIDA' end as KardexConcepto,
do.DocuUsuario,
c.ClienteRazon,c.ClienteCodigo,do.DocuTransaccion,
do.TipoCodigo as TipoCodigo,
do.DocuSerie,
case when(do.TipoCodigo='07')
then '02'
else '01' end as TipoOperacion,'S',
convert(varchar,do.DocuId),'','E' as Estado
from DocumentoVenta do
INNER JOIN Cliente C
ON C.ClienteId=do.ClienteId
inner join DetalleDocumento de
on do.DocuId=de.DocuId
where year(do.DocuEmision) BETWEEN 2020 AND 2026 AND do.DocuEmision >= '20261101' AND do.DocuEmision < '20261107' and do.DocuEstado='EMITIDO' and (do.EstadoSunat='ENVIADO' or do.EstadoSunat='PENDIENTE')
and do.DocuTotal<>0
order by do.DocuEmision,de.DetalleId asc

insert into #Manual
select de.IdProducto,do.CompraEmision,
'Ingreso por Compra',
do.CompraNumero,0,de.DetalleCantidad,0,
convert(decimal(18,2),de.PrecioCosto/1.18),0,'INGRESO',
do.CompraUsuario,
c.ProveedorRazon,c.ProveedorRuc,'',
do.TipoCodigo,do.CompraSerie,'02',
'S','',CONVERT(varchar,do.CompraId),'E'
from Compras do
INNER JOIN Proveedor C
ON C.ProveedorId=do.ProveedorId
inner join DetalleCompra de
on do.CompraId=de.CompraId
where year(do.CompraEmision) BETWEEN 2020 AND 2026 AND do.CompraEmision >= '20261101' AND do.CompraEmision < '20261107' and do.TipoCodigo='01'
order by do.CompraEmision,de.DetalleId asc

Create Table #Informe(
Id numeric(38) primary key identity(1,1),
CodigoAnexo varchar(80),
CodCatUtilizado varchar(80),
TipoExistencia varchar(80),
CodigoExistencia varchar(80),
CodigoOSCE varchar(80),
FechaEmision date,
TipoCodigo varchar(20),
Serie varchar(20),
Numero varchar(20),
Operacion varchar(20),
Descripcion varchar(300),
UM varchar(40),
MetodoEvaluacion varchar(20),
CantidadING decimal(18,2),
CostoUnitario decimal(18,2),
CostoTotal decimal(18,2),
CantidadSAL decimal(18,2),
CostoUnita decimal(18,2),
CostoTotalS decimal(18,2),
StockFinal decimal(18,2),
CostoUni decimal(18,2),
CostoTotalF decimal(18,2),
CONCEPTO varchar(20),
ProductoCodigo varchar(80),
KardexMotivo varchar(300),
Estado varchar(1)
)
insert into #Informe
select '0000','1','01','502023','',k.KardexFecha,
K.TipoCodigo,k.Serie,k.KardexDocumento,K.TipoOperacion,
p.ProductoNombre,'UNIDADES','2',k.CantidadIngreso,
case when (K.TipoOperacion='02')then
k.PrecioCosto
else '0.00' end,
(k.CantidadIngreso * k.PrecioCosto),

k.CantidadSalida,
case when (K.TipoOperacion='01')then
k.PrecioCosto
else '0.00' end,
(k.CantidadSalida * k.PrecioCosto),

k.StockFinal,
k.PrecioCosto,
(k.StockFinal * k.PrecioCosto),
k.KadexConcepto,p.ProductoCodigo,
k.KardexMotivo,k.Estado
FROM #Manual K
inner join dbo.Producto p
on p.IdProducto=k.IdProducto
INNER JOIN dbo.Sublinea s
ON s.IdSubLinea=p.IdSubLinea
order by k.KardexFecha ASC

SELECT RIGHT(ProductoCodigo,5), ProductoCodigo, Descripcion, FechaEmision, TipoCodigo, Serie, Numero, Operacion,
       CONVERT(varchar(50),CAST(CantidadING AS money),1), CONVERT(varchar(50),CAST(CostoUnitario AS money),1),
       CONVERT(varchar(50),CAST(CostoTotal AS money),1), CONVERT(varchar(50),CAST(CantidadSAL AS money),1),
       CONVERT(varchar(50),CAST(CostoUnita AS money),1), CONVERT(varchar(50),CAST(CostoTotalS AS money),1),
       CONVERT(varchar(50),CAST(CostoUni AS money),1)
FROM #Informe
WHERE Estado='E' AND KardexMotivo IN ('Salida por Venta','Ingreso por Compra')
AND ProductoCodigo IN ('FB007','191FB007','201FB007','211FB007','221FB007','231FB007','241FB007','251FB007',
'FB124','191FB124','201FB124','211FB124','221FB124','231FB124','241FB124','251FB124')
ORDER BY FechaEmision,Id;
