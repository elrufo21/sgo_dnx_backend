

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;


GO

GO
GO

GO
USE [DXN_CUSCO_DProduccion];


GO

IF (SELECT OBJECT_ID('tempdb..#tmpErrors')) IS NOT NULL DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error int)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO
BEGIN TRANSACTION
GO
GO
ALTER TABLE [dbo].[Compania] ALTER COLUMN [CompaniaPFX] VARCHAR (MAX) NULL;


GO
ALTER TABLE [dbo].[Compania]
    ADD [FlagCaptura]     BIT             CONSTRAINT [DF_Compania_FlagCaptura] DEFAULT ((0)) NOT NULL,
        [TIPO_PROCESO]    INT             NULL,
        [DescuentoMax]    DECIMAL (18, 2) NULL,
        [RenovacionOSE]   DATE            NULL,
        [RenovacionFirma] DATE            NULL,
        [RenovacionSome]  DATE            NULL,
        [CorreoSGO]       VARCHAR (250)   NULL,
        [PasswordCorreo]  VARCHAR (250)   NULL,
        [CorreosAdmin]    VARCHAR (MAX)   NULL,
        [BoletaPorLote]   BIT             CONSTRAINT [DF_Compania_BoletaPorLote] DEFAULT ((1)) NOT NULL;


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
ALTER TABLE [dbo].[ResumenBoletas]
    ADD [CDRBase64] VARCHAR (MAX) NULL;


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
ALTER TABLE [dbo].[Usuarios]
    ADD [FechaVencimientoClave] DATE NULL;


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
CREATE TABLE [dbo].[DocumentoVentaCpeWeb] (
    [DocuId]          NUMERIC (38)  NOT NULL,
    [ClienteRazon]    VARCHAR (140) NULL,
    [ClienteRuc]      VARCHAR (40)  NULL,
    [ClienteDni]      VARCHAR (40)  NULL,
    [DireccionFiscal] VARCHAR (MAX) NULL,
    [DocuPdfUrl]      VARCHAR (500) NULL,
    [DocuXmlUrl]      VARCHAR (500) NULL,
    [DocuCdrUrl]      VARCHAR (500) NULL,
    [DocuFechaPago]   DATE          NULL,
    [FechaRegistro]   DATETIME      NOT NULL,
    CONSTRAINT [PK_DocumentoVentaCpeWeb] PRIMARY KEY CLUSTERED ([DocuId] ASC)
);


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
ALTER TABLE [dbo].[DocumentoVentaCpeWeb]
    ADD CONSTRAINT [DF_DocumentoVentaCpeWeb_FechaRegistro] DEFAULT (getdate()) FOR [FechaRegistro];


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
if(@CajaId=0)      
begin      
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
GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
where T.TipoVenta='IOC' and(Convert(char(10),t.FechaTransaccion,101) BETWEEN @fechainicio AND @fechafin)
order by T.ID asc
for xml path('')),1,1,'')),'~')+'['+@RutaOBS+'['+@RutaIOC
end
GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
select p.PersonalId,p.PersonalNombres 
from Personal p
inner join Usuarios u
on p.PersonalId=u.PersonalId
where u.Administrador=1 and p.PersonalEmail<>''
GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO

ALTER PROCEDURE [dbo].[totalLetras] @numero decimal(18,2),@Moneda varchar(60)
as
begin
select dbo.letras(@numero,@Moneda) as letras
end
GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO

ALTER PROCEDURE [dbo].[uspComboGuiasCredito]    
@CodigoRes varchar(80)    
as    
begin    
select g.GuiaId as GuiaId,g.Serie+'-'+g.Numero as Documento    
from GuiaInternaSI g  
inner join DetalleGuiaInterna d    
on d.GuiaId=g.GuiaId    
where g.CodigoDXN=@CodigoRes and g.Estado='P'  
group by g.GuiaId,g.Serie+'-'+g.Numero   
order by g.GuiaId desc    
end
GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO

ALTER PROCEDURE [dbo].[uspTraeTodasMonedas]
@Fecha date
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
CREATE   PROCEDURE dbo.LDdocumentosweb
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO

CREATE PROCEDURE dbo.listaNotaPedido
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
CREATE PROCEDURE dbo.usp_Area
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
CREATE PROCEDURE dbo.usp_Feriado
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
CREATE PROCEDURE dbo.usp_Maquina
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
CREATE PROCEDURE dbo.usp_Personal
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
CREATE PROCEDURE dbo.usp_Sublinea
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
CREATE   PROCEDURE dbo.usp_Usuario  
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO

CREATE PROCEDURE dbo.uspEditarNotaPedido
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO

CREATE PROCEDURE dbo.uspEditarRBweb
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO

CREATE PROCEDURE dbo.uspGuardarCredencialesSunatweb
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
CREATE   PROCEDURE dbo.uspinsertarNotaBweb     @ListaOrden varchar(max) AS BEGIN     SET NOCOUNT ON;      DECLARE         @pos1 int,         @orden varchar(max),         @detalle varchar(max);      SET @pos1 = CHARINDEX('[', @ListaOrden, 1);      IF @pos1 <= 0     BEGIN         RAISERROR('Formato de orden invalido.', 16, 1);         RETURN;     END;      SET @orden = SUBSTRING(         @ListaOrden,         1,         @pos1 - 1     );      SET @detalle = SUBSTRING(         @ListaOrden,         @pos1 + 1,         LEN(@ListaOrden) - @pos1     );      DECLARE @campos TABLE     (         Pos int IDENTITY(1,1) NOT NULL,         Valor varchar(max) NULL     );      DECLARE         @start int,         @end int;      SET @start = 1;      WHILE @start <= LEN(@orden) + 1     BEGIN         SET @end = CHARINDEX('|', @orden, @start);          IF @end = 0             SET @end = LEN(@orden) + 1;          INSERT INTO @campos         (             Valor         )         VALUES         (             SUBSTRING(                 @orden,                 @start,                 @end - @start             )         );          SET @start = @end + 1;     END;      DECLARE         @NotaDocu varchar(60),         @ClienteId numeric(20),         @NotaUsuario varchar(60),         @NotaFormaPago varchar(60),         @NotaCondicion varchar(60),         @NotaDireccion varchar(max),         @CompaniaUbigeo varchar(250),          @NotaSubtotal decimal(18,2),         @NotaMovilidad decimal(18,2),         @NotaDescuento decimal(18,2),         @NotaTotal decimal(18,2),         @NotaAcuenta decimal(18,2),         @NotaSaldo decimal(18,2),         @NotaAdicional decimal(18,2),         @NotaTarjeta decimal(18,2),         @NotaPagar decimal(18,2),          @NotaEstado varchar(60),         @CompaniaId int,         @NotaEntrega varchar(40),         @NotaConcepto varchar(60),          @Serie varchar(60),         @Numero varchar(60),         @NotaGanancia decimal(18,2),          @Letra varchar(max),         @DocuAdicional decimal(18,2),         @DocuHash varchar(250),         @EstadoSunat varchar(80),         @DocuSubtotal decimal(18,2),         @DocuIGV decimal(18,2),          @UsuarioId int,         @NotaTransaccion varchar(250),         @Miembro varchar(300),         @CodigoCliente varchar(80),          @ICBPER decimal(18,2),         @DocuGravada decimal(18,2),          @ConceptoOBS varchar(80),         @EstadoOBS varchar(20),         @PV varchar(40),         @Image varchar(max),          @CodigoRes varchar(80),         @Responsable varchar(300),          @EntidadBancaria varchar(80),         @Efectivo decimal(18,2),         @Deposito decimal(18,2),         @NroOperacion varchar(80),          @ClienteRazon varchar(140),         @ClienteRuc varchar(40),         @ClienteDni varchar(40),         @DireccionFiscal varchar(max),          @TipoCodigo char(20),         @cod varchar(60),          @NotaId numeric(38),         @DocuId numeric(38);      SELECT @NotaDocu = Valor     FROM @campos     WHERE Pos = 1;      SELECT @ClienteId =         CONVERT(             numeric(20),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 2;      SELECT @NotaUsuario = Valor     FROM @campos     WHERE Pos = 3;      SELECT @NotaFormaPago = Valor     FROM @campos     WHERE Pos = 4;      SELECT @NotaCondicion = Valor     FROM @campos     WHERE Pos = 5;      SELECT @NotaDireccion = Valor     FROM @campos     WHERE Pos = 6;      SELECT @NotaSubtotal =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 7;      SELECT @NotaMovilidad =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 8;      SELECT @NotaDescuento =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 9;      SELECT @NotaTotal =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 10;      SELECT @NotaAcuenta =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 11;      SELECT @NotaSaldo =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 12;      SELECT @NotaAdicional =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 13;      SELECT @NotaTarjeta =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 14;      SELECT @NotaPagar =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 15;      SELECT @NotaEstado = Valor     FROM @campos     WHERE Pos = 16;      SELECT @CompaniaId =         CONVERT(             int,             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 17;      SELECT @NotaEntrega = Valor     FROM @campos     WHERE Pos = 18;      SELECT @NotaConcepto = Valor     FROM @campos     WHERE Pos = 19;      SELECT @Serie = Valor     FROM @campos     WHERE Pos = 20;      SELECT @Numero = Valor     FROM @campos     WHERE Pos = 21;      SELECT @NotaGanancia =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 22;      SELECT @Letra = Valor     FROM @campos     WHERE Pos = 23;      SELECT @DocuAdicional =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 24;      SELECT @DocuHash = Valor     FROM @campos     WHERE Pos = 25;      SELECT @EstadoSunat = Valor     FROM @campos     WHERE Pos = 26;      SELECT @DocuSubtotal =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 27;      SELECT @DocuIGV =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 28;      SELECT @UsuarioId =         CONVERT(             int,             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 29;      SELECT @NotaTransaccion = Valor     FROM @campos     WHERE Pos = 30;      SELECT @Miembro = Valor     FROM @campos     WHERE Pos = 31;      SELECT @CodigoCliente = Valor     FROM @campos     WHERE Pos = 32;      SELECT @ICBPER =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 33;      SELECT @DocuGravada =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 34;      SELECT @ConceptoOBS = Valor     FROM @campos     WHERE Pos = 35;      SELECT @EstadoOBS = Valor     FROM @campos     WHERE Pos = 36;      SELECT @PV = Valor     FROM @campos     WHERE Pos = 37;      SELECT @Image = Valor     FROM @campos     WHERE Pos = 38;      SELECT @CodigoRes = Valor     FROM @campos     WHERE Pos = 39;      SELECT @Responsable = Valor     FROM @campos     WHERE Pos = 40;      SELECT @EntidadBancaria = Valor     FROM @campos     WHERE Pos = 41;      SELECT @Efectivo =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 42;      SELECT @Deposito =         CONVERT(             decimal(18,2),             ISNULL(NULLIF(Valor, ''), '0')         )     FROM @campos     WHERE Pos = 43;      SELECT @NroOperacion = Valor     FROM @campos     WHERE Pos = 44;      SET @NotaDocu =         ISNULL(             NULLIF(LTRIM(RTRIM(@NotaDocu)), ''),             'BOLETA'         );      SET @NotaUsuario =         ISNULL(@NotaUsuario, '');      SET @NotaFormaPago =         ISNULL(             NULLIF(@NotaFormaPago, ''),             'EFECTIVO'         );      SET @NotaCondicion =         ISNULL(             NULLIF(@NotaCondicion, ''),             'ALCONTADO'         );      SET @NotaDireccion =         ISNULL(             NULLIF(@NotaDireccion, ''),             '-'         );      SET @NotaEstado =         ISNULL(             NULLIF(@NotaEstado, ''),             'PENDIENTE'         );      SET @CompaniaId =         ISNULL(             NULLIF(@CompaniaId, 0),             1         );      SET @NotaEntrega =         ISNULL(             NULLIF(@NotaEntrega, ''),             'INMEDIATA'         );      SET @NotaConcepto =         ISNULL(             NULLIF(@NotaConcepto, ''),             'MERCADERIA'         );      SET @Serie =         ISNULL(             NULLIF(@Serie, ''),             CASE                 WHEN @NotaDocu = 'FACTURA'                     THEN 'FA01'                 ELSE 'BA01'             END         );      SET @Letra = ISNULL(@Letra, '');     SET @DocuHash = ISNULL(@DocuHash, '');      SET @EstadoSunat =         ISNULL(             NULLIF(@EstadoSunat, ''),             'PENDIENTE'         );      SET @NotaTransaccion = ISNULL(@NotaTransaccion, '');     SET @Miembro = ISNULL(@Miembro, '');     SET @CodigoCliente = ISNULL(@CodigoCliente, '');      SET @ConceptoOBS =         ISNULL(             NULLIF(@ConceptoOBS, ''),             'VENTA'         );      SET @EstadoOBS =         ISNULL(             NULLIF(@EstadoOBS, ''),             'EMITIDO'         );      SET @CodigoRes = ISNULL(@CodigoRes, '');     SET @Responsable = ISNULL(@Responsable, '');      SET @EntidadBancaria =         ISNULL(             NULLIF(@EntidadBancaria, ''),             '-'         );      SET @NroOperacion =         ISNULL(@NroOperacion, '');      IF @NotaDocu = 'FACTURA'         SET @TipoCodigo = '01';     ELSE IF @NotaDocu = 'PROFORMA V'         SET @TipoCodigo = '00';     ELSE         SET @TipoCodigo = '03';      SELECT TOP 1         @ClienteRazon =             NULLIF(                 LTRIM(RTRIM(ClienteRazon)),                 ''             ),          @ClienteRuc =             NULLIF(                 LTRIM(RTRIM(ClienteRuc)),                 ''             ),          @ClienteDni =             NULLIF(                 LTRIM(RTRIM(ClienteDni)),                 ''             ),          @DireccionFiscal =             NULLIF(                 LTRIM(RTRIM(ClienteDireccion)),                 ''             )     FROM Cliente     WHERE ClienteId = @ClienteId;      SET @ClienteRazon =         ISNULL(             @ClienteRazon,             CASE                 WHEN @Miembro <> ''                     THEN @Miembro                 ELSE 'VARIOS'             END         );      SET @ClienteRuc = ISNULL(@ClienteRuc, '');     SET @ClienteDni = ISNULL(@ClienteDni, '');      IF @NotaDocu = 'BOLETA'        AND @ClienteRuc = ''        AND @ClienteDni = ''     BEGIN         SET @ClienteDni = '00000000';     END;      SET @DireccionFiscal =         ISNULL(             @DireccionFiscal,             @NotaDireccion         );      IF NULLIF(@DireccionFiscal, '') IS NULL         SET @DireccionFiscal = '-';      IF @NotaFormaPago <> 'EFECTIVO'     BEGIN         IF @Efectivo IS NULL             SET @Efectivo = 0;          IF @Deposito IS NULL            OR @Deposito = 0             SET @Deposito = @NotaPagar;     END;     ELSE     BEGIN         IF @Efectivo IS NULL            OR @Efectivo = 0             SET @Efectivo = @NotaPagar;          IF @Deposito IS NULL             SET @Deposito = 0;     END;      IF @NotaCondicion = 'CREDITO'     BEGIN         SET @NotaEstado = 'EMITIDO';         SET @NotaSaldo = @NotaPagar;         SET @NotaAcuenta = 0;     END;     ELSE IF @NotaDocu <> 'FACTURA'         AND @NotaDocu <> 'PROFORMA V'     BEGIN         SET @NotaEstado = 'CANCELADO';         SET @NotaSaldo = 0;         SET @NotaAcuenta = @NotaPagar;     END;      IF @NotaTransaccion <> ''        AND EXISTS        (             SELECT 1             FROM NotaPedido             WHERE NotaTransaccion = @NotaTransaccion               AND ISNULL(NotaEstado, '') <> 'ANULADO'        )     BEGIN         SELECT 'EXISTE';         RETURN;     END;      IF @Deposito > 0        AND @NotaCondicion <> 'PAGO/VARIOS'        AND NULLIF(LTRIM(RTRIM(@NroOperacion)), '') IS NULL     BEGIN         SELECT 'OPERACION_REQUERIDA';         RETURN;     END;      IF @NroOperacion <> ''        AND ISNULL(@EntidadBancaria, '-') <> '-'        AND EXISTS        (             SELECT 1             FROM NotaPedido             WHERE EntidadBancaria = @EntidadBancaria               AND NroOperacion = @NroOperacion               AND ISNULL(NotaEstado, '') <> 'ANULADO'        )     BEGIN         SELECT 'OPERACION';         RETURN;     END;      DECLARE @CajaId numeric(38);      SELECT TOP (1)         @CajaId = CajaId     FROM Caja     WHERE CajaEstado = 'ACTIVO'       AND UsuarioId = @UsuarioId     ORDER BY CajaId DESC;      IF ISNULL(@CajaId, 0) = 0     BEGIN         SELECT 'false';         RETURN;     END;      SELECT @CompaniaUbigeo = NULLIF(LTRIM(RTRIM(CompaniaNomUBG)), '')     FROM Compania     WHERE CompaniaId = @CompaniaId;      SET @CompaniaUbigeo = ISNULL(@CompaniaUbigeo, '');      BEGIN TRY          BEGIN TRANSACTION;          UPDATE Cliente         SET ClienteDespacho = @NotaDireccion         WHERE ClienteId = @ClienteId;          SET @NotaDireccion = @CompaniaUbigeo;          DELETE FROM TemporalVenta         WHERE UsuarioID = @UsuarioId;          SELECT @cod =             ISNULL(                 (                     SELECT TOP 1                         dbo.genenerarNroFactura(                             @Serie,                             @CompaniaId,                             @NotaDocu                         )                     FROM DocumentoVenta                 ),                 '00000001'             );          INSERT INTO NotaPedido         (             NotaDocu,             ClienteId,             NotaFecha,             NotaUsuario,             NotaFormaPago,             NotaCondicion,             NotaFechaPago,             NotaDireccion,             NotaSubtotal,             NotaMovilidad,             NotaDescuento,             NotaTotal,             NotaAcuenta,             NotaSaldo,             NotaAdicional,             NotaTarjeta,             NotaPagar,             NotaEstado,             CompaniaId,             NotaEntrega,             ModificadoPor,             FechaEdita,             NotaConcepto,             NotaSerie,             NotaNumero,             NotaGanancia,             CajaId,             NotaTransaccion,             ICBPER,             ConceptoOBS,             EstadoOBS,             CodigoRes,             Responsable,             EntidadBancaria,             NroOperacion,             Efectivo,             Deposito         )         VALUES         (             @NotaDocu,             @ClienteId,             GETDATE(),             @NotaUsuario,             @NotaFormaPago,             @NotaCondicion,             GETDATE(),             @NotaDireccion,             @NotaSubtotal,             @NotaMovilidad,             @NotaDescuento,             @NotaTotal,             @NotaAcuenta,             @NotaSaldo,             @NotaAdicional,             @NotaTarjeta,             @NotaPagar,             @NotaEstado,             @CompaniaId,             @NotaEntrega,             '',             '',             @NotaConcepto,             @Serie,             @cod,             @NotaGanancia,             @CajaId,             @NotaTransaccion,             @ICBPER,             @ConceptoOBS,             @EstadoOBS,             @CodigoRes,             @Responsable,             @EntidadBancaria,             @NroOperacion,             @Efectivo,             @Deposito         );          SET @NotaId = SCOPE_IDENTITY();          INSERT INTO DocumentoVenta         (             CompaniaId,             NotaId,             DocuDocumento,             DocuNumero,             ClienteId,             DocuRegistro,             DocuEmision,             DocuCondicion,             DocuLetras,             DocuSubTotal,             DocuIgv,             DocuTotal,             DocuSaldo,             DocuUsuario,             DocuEstado,             DocuSerie,             TipoCodigo,             DocuAdicional,             DocuAsociado,             DocuConcepto,             DocuNroGuia,             DocuHash,             EstadoSunat,             DocuOperacion,             DocuTransaccion,             ICBPER,             CodigoSunat,             MensajeSunat,             FormaPago,             EntidadBancaria,             NroOperacion,             Efectivo,             Deposito         )         VALUES         (             @CompaniaId,             @NotaId,             @NotaDocu,             @cod,             @ClienteId,             GETDATE(),             GETDATE(),             @NotaCondicion,             @Letra,             @DocuSubtotal,             @DocuIGV,             @NotaPagar,             0,             @NotaUsuario,             'EMITIDO',             @Serie,             @TipoCodigo,             @DocuAdicional,             '',             'VENTA',             '',             @DocuHash,              CASE                 WHEN @NotaDocu = 'PROFORMA V'                     THEN 'ENVIADO'                 ELSE @EstadoSunat             END,              @NotaConcepto,             @NotaTransaccion,             @ICBPER,             '',             '',             @NotaFormaPago,             @EntidadBancaria,             @NroOperacion,             @Efectivo,             @Deposito         );          SET @DocuId = SCOPE_IDENTITY();          INSERT INTO dbo.DocumentoVentaCpeWeb         (             DocuId,             ClienteRazon,             ClienteRuc,             ClienteDni,             DireccionFiscal,             DocuPdfUrl,             DocuXmlUrl,             DocuCdrUrl,             DocuFechaPago         )         VALUES         (             @DocuId,             @ClienteRazon,             @ClienteRuc,             @ClienteDni,             @DireccionFiscal,             '',             '',             '',             GETDATE()         );          IF @NotaCondicion = 'ALCONTADO'            AND @NotaDocu <> 'PROFORMA V'         BEGIN             IF UPPER(LTRIM(RTRIM(@ConceptoOBS))) = 'VENTA LIBRE'             BEGIN                 INSERT INTO dbo.CajaDetalle                 (                     CajaId, DetalleFecha, NotaId, DetalleMovimiento,                     DetalleConcepto, DetalleMonto, DetalleEfectivo,                     DetalleVuelto, RutaImagen, Estado, Vista,                     NotaIdB, LiquidaId, FormaPago, EntidadBancaria, NroOperacion                 )                 VALUES                 (                     @CajaId, GETDATE(), 0, 'INGRESO',                     'VENTA LIBRE DOCUMENTO ' + @Serie + '-' + @cod +                     ' CODIGO: ' + @CodigoCliente + ' (' + @Miembro + ')' +                     ' FORMA DE PAGO: ' + @NotaFormaPago,                     @NotaTotal, @NotaTotal, 0, @Image, 'D', '',                     @NotaId, '', @NotaFormaPago, @EntidadBancaria, @NroOperacion                 );             END;              IF @Deposito > 0                AND UPPER(LTRIM(RTRIM(@ConceptoOBS))) IN ('VENTA', 'IOC', 'CASHBILL', 'VENTA LIBRE')             BEGIN                 INSERT INTO dbo.CajaDetalle                 (                     CajaId, DetalleFecha, NotaId, DetalleMovimiento,                     DetalleConcepto, DetalleMonto, DetalleEfectivo,                     DetalleVuelto, RutaImagen, Estado, Vista,                     NotaIdB, LiquidaId, FormaPago, EntidadBancaria, NroOperacion                 )                 VALUES                 (                     @CajaId, GETDATE(), 0, 'SALIDA',                     'VENTA DEL OBS DOCUMENTO ' + @Serie + '-' + @cod +                     ' CODIGO: ' + @CodigoCliente + ' (' + @Miembro + ')' +                     ' FORMA DE PAGO: ' + @NotaFormaPago +        ' ENTIDAD BANCARIA: ' + @EntidadBancaria +                     ' NRO OPERACION: ' + @NroOperacion,                     @Deposito, @Deposito, 0, @Image, 'D', '',                     @NotaId, '', @NotaFormaPago, @EntidadBancaria, @NroOperacion                 );             END;         END;          DECLARE detalle_cursor CURSOR LOCAL FAST_FORWARD         FOR             SELECT splitdata             FROM dbo.fnSplitString(@detalle, ';')             WHERE LEN(LTRIM(RTRIM(splitdata))) > 0;          DECLARE @Columna varchar(max);          DECLARE @detalleCampos TABLE         (             Pos int NOT NULL PRIMARY KEY,             Valor varchar(max) NULL         );          DECLARE @campoPos int;          OPEN detalle_cursor;          FETCH NEXT FROM detalle_cursor         INTO @Columna;          WHILE @@FETCH_STATUS = 0         BEGIN              DELETE FROM @detalleCampos;              SET @campoPos = 1;             SET @start = 1;              WHILE @start <= LEN(@Columna) + 1             BEGIN                  SET @end =                     CHARINDEX(                         '|',                         @Columna,                         @start                     );                  IF @end = 0                     SET @end = LEN(@Columna) + 1;                  INSERT INTO @detalleCampos                 (                     Pos,                     Valor                 )                 VALUES                 (                     @campoPos,                     SUBSTRING(                         @Columna,                         @start,                         @end - @start                     )                 );                  SET @campoPos = @campoPos + 1;                 SET @start = @end + 1;             END;              DECLARE                 @IdProducto numeric(20),                 @DetalleCantidad decimal(18,2),                 @DetalleUm varchar(40),                 @Descripcion varchar(max),                 @DetalleCosto decimal(18,4),                 @DetallePrecio decimal(18,2),                 @DetallePV decimal(18,2),                 @DetalleSV decimal(18,2),                 @DetalleImporte decimal(18,2),                 @DetalleEstado varchar(60),                 @ValorUM decimal(18,4),                 @CantidadSaldo decimal(18,2),                 @IniciaStock decimal(18,2),                 @StockFinal decimal(18,2);              SELECT @IdProducto =                 CONVERT(                     numeric(20),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 1;              SELECT @DetalleCantidad =                 CONVERT(                     decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 2;              SELECT @DetalleUm = Valor             FROM @detalleCampos             WHERE Pos = 3;              SELECT @Descripcion = Valor             FROM @detalleCampos             WHERE Pos = 4;              SELECT @DetalleCosto =                 CONVERT(                     decimal(18,4),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 5;              SELECT @DetallePrecio =                 CONVERT(                     decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 6;              SELECT @DetallePV =                 CONVERT(                     decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 7;              SELECT @DetalleSV =                 CONVERT(                     decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 8;              SELECT @DetalleImporte =                 CONVERT(    decimal(18,2),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 9;              SELECT @DetalleEstado = Valor             FROM @detalleCampos             WHERE Pos = 10;              SELECT @ValorUM =                 CONVERT(                     decimal(18,4),                     ISNULL(NULLIF(Valor, ''), '0')                 )             FROM @detalleCampos             WHERE Pos = 11;              SET @DetalleUm =                 ISNULL(                     NULLIF(@DetalleUm, ''),                     'UNIDAD'                 );              SET @Descripcion =                 ISNULL(@Descripcion, '');              SET @DetalleEstado =                 ISNULL(                     NULLIF(@DetalleEstado, ''),                     'PENDIENTE'                 );              IF @ValorUM IS NULL                OR @ValorUM = 0             BEGIN                 SET @ValorUM = 1;             END;              IF @NotaEntrega = 'INMEDIATA'                 SET @CantidadSaldo = 0;             ELSE                 SET @CantidadSaldo = @DetalleCantidad;              INSERT INTO DetallePedido             (                 NotaId,                 IdProducto,                 DetalleCantidad,                 DetalleUm,                 DetalleDescripcion,                 DetalleCosto,                 DetallePrecio,                 DetalleImporte,                 DetalleEstado,                 CantidadSaldo,                 ValorUM,                 DetallePV,                 DetalleSV             )             VALUES             (                 @NotaId,                 @IdProducto,                 @DetalleCantidad,                 @DetalleUm,                 @Descripcion,                 @DetalleCosto,                 @DetallePrecio,                 @DetalleImporte,                 @DetalleEstado,                 @CantidadSaldo,                 @ValorUM,                 @DetallePV,                 @DetalleSV             );              IF @DocuId <> 0             BEGIN                  INSERT INTO DetalleDocumento                 (                     DocuId,                     IdProducto,                     DetalleCantidad,                     DetallPrecio,                     DetalleImporte,                     DetalleNotaId,                     DetalleUM,                     ValorUM                 )                 VALUES                 (                     @DocuId,                     @IdProducto,                     @DetalleCantidad,                     @DetallePrecio,                     @DetalleImporte,                     @NotaId,                     @DetalleUm,                     @ValorUM                 );              END;              IF @NotaDocu <> 'FACTURA'             BEGIN                  SELECT TOP 1                     @IniciaStock = ProductoCantidad                 FROM Producto                 WHERE IdProducto = @IdProducto;                  SET @IniciaStock =                     ISNULL(@IniciaStock, 0);                  SET @StockFinal =                     @IniciaStock - @DetalleCantidad;                  INSERT INTO Kardex                 (                     IdProducto,                     KardexFecha,                     KardexMotivo,                     KardexDocumento,                     StockInicial,                     CantidadIngreso,                     CantidadSalida,                     PrecioCosto,                     StockFinal,                     KadexConcepto,                     Usuario,                     CLIENTE,                     CODIGOCLIENTE,                     NROTRANSAC,                     TipoCodigo,                     Serie,                     TipoOperacion,                     Consideracion,                     DocuId,                     CompraId,                     Estado                 )                 VALUES                 (                     @IdProducto,                     GETDATE(),               'Salida por Venta',                     @cod,                     @IniciaStock,                     0,                     @DetalleCantidad,                     @DetalleCosto,                     @StockFinal,                     'SALIDA',                     @NotaUsuario,                     @Miembro,                     @CodigoCliente,                     @NotaTransaccion,                     @TipoCodigo,                     @Serie,                     '01',                      CASE                         WHEN @NotaEntrega = 'INMEDIATA'                             THEN 'S'                         ELSE 'N'                     END,                      CONVERT(varchar(40), @DocuId),                     '',                     'E'                 );                  IF @NotaEntrega = 'INMEDIATA'                 BEGIN                      UPDATE Producto                     SET ProductoCantidad =                         ProductoCantidad - @DetalleCantidad                     WHERE IdProducto = @IdProducto;                  END;              END;              FETCH NEXT FROM detalle_cursor             INTO @Columna;          END;          CLOSE detalle_cursor;         DEALLOCATE detalle_cursor;          COMMIT TRANSACTION;          SELECT             CONVERT(varchar(38), @NotaId)             + N'¬'             + @cod;      END TRY      BEGIN CATCH          IF CURSOR_STATUS('local', 'detalle_cursor') > -1         BEGIN             CLOSE detalle_cursor;             DEALLOCATE detalle_cursor;         END;          IF @@TRANCOUNT > 0             ROLLBACK TRANSACTION;          DECLARE             @ErrMsg nvarchar(4000),             @ErrSeverity int,             @ErrState int;          SELECT             @ErrMsg = ERROR_MESSAGE(),             @ErrSeverity = ERROR_SEVERITY(),             @ErrState = ERROR_STATE();          RAISERROR(             @ErrMsg,             @ErrSeverity,             @ErrState         );      END CATCH;  END;
GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO

CREATE PROCEDURE dbo.uspinsertarRBweb
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO

CREATE   PROCEDURE dbo.uspListarCajaWEB
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
CREATE   PROCEDURE dbo.uspListarComprasweb
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
CREATE   PROCEDURE dbo.uspObtenerCajaActivaWEB
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO

CREATE PROCEDURE dbo.uspObtenerCredencialesSunatweb
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO

CREATE PROCEDURE dbo.uspResumenFechaweb
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
CREATE   PROCEDURE dbo.uspValidaCantCajas
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
CREATE   PROCEDURE dbo.uspValidaUsuarioweb
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
                    + ISNULL(CONVERT(VARCHAR(20), c.DescuentoMax), '0') + '|'
                    + ISNULL(c.CompaniaRUC, '') + '|'
                    + ISNULL(c.CompaniaNomUBG, '') + '|'
                    + ISNULL(c.CompaniaComercial, '') + '|'
                    + ISNULL(c.CompaniaDirecSunat, '') + '|'
                    + ISNULL(c.CompaniaUserSecun, '') + '|'
                    + ISNULL(c.ComapaniaPWD, '') + '|'
                    + ISNULL(c.CompaniaPFX, '') + '|'
                    + ISNULL(c.CompaniaClave, '') + '|'
                    + ISNULL(CONVERT(VARCHAR, c.TIPO_PROCESO), '3') + '|'
                    + ISNULL(c.CompaniaTelefono, '') + '|'
                    + ISNULL(CONVERT(VARCHAR, c.BoletaPorLote), '1') + '|'
                    + ISNULL(CONVERT(VARCHAR, c.FlagCaptura), '0')
                FROM dbo.Usuarios U
                INNER JOIN dbo.Personal p
                    ON p.PersonalId = U.PersonalId
                INNER JOIN dbo.Area a
                    ON a.AreaId = p.AreaId
                INNER JOIN dbo.Compania c
                    ON c.CompaniaId = p.CompaniaId
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
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspValidaUsuario]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[listaCompraComputo]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[listaNotaComE]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[listaNotaCompra]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspinsertarRB]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[listaCompraEmision]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[listaDocuCompania]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usplistaResumen]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspTraerDV]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspTraerPFXB]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[listaPedidosFecha]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspTraerPFX]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[reporteVentaCompania]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[listarCompras]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[listarPedidos]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspResumenFecha]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[listaNotaComC]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspListaSeries]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[listaDocumentos]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[CuentasCorreienteCompania]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editarCompania]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[listarPersonal]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspValidarAperturaB]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspEditarRB]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspRetornaBoletaPorTicket]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspRetornarBoletas]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspValidarAperturaC]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspinsertaSeries]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspInsertarOBS]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspinsertarGuiaSP]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspInsertaHtmlGuia]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[ingresarUsuario]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspInsertarHtmlGSI]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspInsertarHtml]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspUsuarioBaja]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[editarUsuario]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[uspAsistenciaListaCsvB]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO
GO
EXECUTE sp_refreshsqlmodule N'[dbo].[listarUsuario]';


GO
IF @@ERROR <> 0
   AND @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
    END

IF OBJECT_ID(N'tempdb..#tmpErrors') IS NULL
    CREATE TABLE [#tmpErrors] (
        Error INT
    );

IF @@TRANCOUNT = 0
    BEGIN
        INSERT  INTO #tmpErrors (Error)
        VALUES                 (1);
        BEGIN TRANSACTION;
    END


GO

IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
COMMIT TRANSACTION
END
GO
IF (SELECT OBJECT_ID('tempdb..#tmpErrors')) IS NOT NULL DROP TABLE #tmpErrors
GO
GO
GO

