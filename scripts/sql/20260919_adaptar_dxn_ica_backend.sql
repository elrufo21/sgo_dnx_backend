/*
  Script autónomo de producción para adaptar DXN_ICA.
  Generado tomando exclusivamente DXN_CUSCO_D0109 como referencia.
  Excepción solicitada: crea dbo.Indicador y sus flags iniciales.
  No incorpora objetos que existan únicamente en el backend adaptado.
  No requiere que DXN_CUSCO_D0109 exista en el servidor de producción.
*/
USE [DXN_ICA];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;
GO

/* Columnas presentes en DXN_CUSCO_D0109 y ausentes en DXN_ICA. */
IF COL_LENGTH('dbo.CajaDetalle', 'DetalleConcepto') IS NULL
    ALTER TABLE dbo.CajaDetalle ADD DetalleConcepto varchar(max) NULL;
IF COL_LENGTH('dbo.Compania', 'FechaRenovacion') IS NULL
    ALTER TABLE dbo.Compania ADD FechaRenovacion date NULL;
IF COL_LENGTH('dbo.Compania', 'CorreosAdmin') IS NULL
    ALTER TABLE dbo.Compania ADD CorreosAdmin varchar(max) NULL;
IF COL_LENGTH('dbo.Compania', 'FlagCaja') IS NULL
    ALTER TABLE dbo.Compania ADD FlagCaja bit NOT NULL
        CONSTRAINT DF_Compania_FlagCaja DEFAULT (0) WITH VALUES;
IF COL_LENGTH('dbo.DetalleGuiaLiquida', 'IdProducto') IS NULL
    ALTER TABLE dbo.DetalleGuiaLiquida ADD IdProducto numeric(20,0) NULL;
IF COL_LENGTH('dbo.DetallePVarios', 'Efectivo') IS NULL
    ALTER TABLE dbo.DetallePVarios ADD Efectivo decimal(18,2) NULL;
IF COL_LENGTH('dbo.DetallePVarios', 'Deposito') IS NULL
    ALTER TABLE dbo.DetallePVarios ADD Deposito decimal(18,2) NULL;
IF COL_LENGTH('dbo.MAQUINAS', 'Registro') IS NULL
    ALTER TABLE dbo.MAQUINAS ADD Registro datetime NULL;
IF COL_LENGTH('dbo.MAQUINAS', 'SerieBoleta') IS NULL
    ALTER TABLE dbo.MAQUINAS ADD SerieBoleta nvarchar(4) NULL;
IF COL_LENGTH('dbo.MAQUINAS', 'Tiketera') IS NULL
    ALTER TABLE dbo.MAQUINAS ADD Tiketera varchar(300) NULL;
IF COL_LENGTH('dbo.NotaPedido', 'Entrega') IS NULL
    ALTER TABLE dbo.NotaPedido ADD Entrega varchar(20) NULL;
IF COL_LENGTH('dbo.NotaPedido', 'Hora') IS NULL
    ALTER TABLE dbo.NotaPedido ADD Hora datetime NULL;
IF COL_LENGTH('dbo.NotaPedido', 'Almacen') IS NULL
    ALTER TABLE dbo.NotaPedido ADD Almacen varchar(80) NULL;
IF COL_LENGTH('dbo.Producto', 'ProductoNombre') IS NULL
    ALTER TABLE dbo.Producto ADD ProductoNombre varchar(max) NULL;
IF COL_LENGTH('dbo.Producto', 'UltimoINV') IS NULL
    ALTER TABLE dbo.Producto ADD UltimoINV decimal(18,2) NULL;
IF COL_LENGTH('dbo.TipoComprobante', 'TipoCodigo') IS NULL
    ALTER TABLE dbo.TipoComprobante ADD TipoCodigo varchar(10) NULL;
IF COL_LENGTH('dbo.TipoComprobante', 'TipoDescripcion') IS NULL
    ALTER TABLE dbo.TipoComprobante ADD TipoDescripcion varchar(80) NULL;
GO

/* Normalizaciones compatibles con la referencia, sin truncar datos. */
IF COL_LENGTH('dbo.CajaDetalle', 'DetalleConcepto') <> -1
    ALTER TABLE dbo.CajaDetalle ALTER COLUMN DetalleConcepto varchar(max) NULL;
IF COL_LENGTH('dbo.Producto', 'ProductoNombre') <> -1
    ALTER TABLE dbo.Producto ALTER COLUMN ProductoNombre varchar(max) NULL;
IF EXISTS (SELECT 1 FROM dbo.TipoComprobante WHERE DATALENGTH(TipoCodigo) > 10)
    THROW 51001, 'TipoComprobante.TipoCodigo contiene valores mayores de 10 caracteres.', 1;
IF COL_LENGTH('dbo.TipoComprobante', 'TipoCodigo') <> 10
    ALTER TABLE dbo.TipoComprobante ALTER COLUMN TipoCodigo varchar(10) NULL;

IF EXISTS
(
    SELECT 1
    FROM dbo.DetalleGuiaLiquida
    WHERE IdProducto > CONVERT(numeric(38,0), 99999999999999999999)
       OR IdProducto < CONVERT(numeric(38,0),-99999999999999999999)
)
    THROW 51002, 'DetalleGuiaLiquida.IdProducto contiene valores que no caben en numeric(20,0).', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.DetalleGuiaLiquida')
      AND name = N'IdProducto'
      AND (precision <> 20 OR scale <> 0)
)
    ALTER TABLE dbo.DetalleGuiaLiquida ALTER COLUMN IdProducto numeric(20,0) NULL;
GO

/* Relaciones presentes en la referencia y sin datos huérfanos en DXN_ICA. */
IF NOT EXISTS
(
    SELECT 1 FROM sys.foreign_key_columns fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'dbo.DetalleCompra')
      AND COL_NAME(fkc.parent_object_id,fkc.parent_column_id) = N'IdProducto'
      AND fkc.referenced_object_id = OBJECT_ID(N'dbo.Producto')
)
    ALTER TABLE dbo.DetalleCompra WITH CHECK
        ADD CONSTRAINT FK_Migracion_DetalleCompra_Producto
        FOREIGN KEY (IdProducto) REFERENCES dbo.Producto(IdProducto);

IF NOT EXISTS
(
    SELECT 1 FROM sys.foreign_key_columns fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'dbo.DetalleGuiaInterna')
      AND COL_NAME(fkc.parent_object_id,fkc.parent_column_id) = N'IdProducto'
      AND fkc.referenced_object_id = OBJECT_ID(N'dbo.Producto')
)
    ALTER TABLE dbo.DetalleGuiaInterna WITH CHECK
        ADD CONSTRAINT FK_Migracion_DetalleGuiaInterna_Producto
        FOREIGN KEY (IdProducto) REFERENCES dbo.Producto(IdProducto);

IF NOT EXISTS
(
    SELECT 1 FROM sys.foreign_key_columns fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'dbo.DetalleGuiaLiquida')
      AND COL_NAME(fkc.parent_object_id,fkc.parent_column_id) = N'IdProducto'
      AND fkc.referenced_object_id = OBJECT_ID(N'dbo.Producto')
)
    ALTER TABLE dbo.DetalleGuiaLiquida WITH CHECK
        ADD CONSTRAINT FK_Migracion_DetalleGuiaLiquida_Producto
        FOREIGN KEY (IdProducto) REFERENCES dbo.Producto(IdProducto);

IF NOT EXISTS
(
    SELECT 1 FROM sys.foreign_key_columns fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'dbo.DetallesPVS')
      AND COL_NAME(fkc.parent_object_id,fkc.parent_column_id) = N'NotaId'
      AND fkc.referenced_object_id = OBJECT_ID(N'dbo.NotaPedido')
)
    ALTER TABLE dbo.DetallesPVS WITH CHECK
        ADD CONSTRAINT FK_Migracion_DetallesPVS_NotaPedido
        FOREIGN KEY (NotaId) REFERENCES dbo.NotaPedido(NotaId);
GO

/* Tabla recursiva de configuración solicitada. */
IF OBJECT_ID(N'dbo.Indicador',N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Indicador
    (
        Id int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Indicador PRIMARY KEY,
        CompaniaId int NULL,
        Area varchar(100) NOT NULL,
        TipoIndicador int NOT NULL,
        IdIndicador int NULL,
        Descripcion varchar(500) NOT NULL,
        ValorTexto1 varchar(500) NULL,
        ValorNum int NULL,
        FechaActualizacion datetime2(0) NOT NULL
            CONSTRAINT DF_Indicador_FechaActualizacion DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_Indicador_Compania
            FOREIGN KEY (CompaniaId) REFERENCES dbo.Compania(CompaniaId),
        CONSTRAINT FK_Indicador_IndicadorPadre
            FOREIGN KEY (IdIndicador) REFERENCES dbo.Indicador(Id),
        CONSTRAINT CK_Indicador_NoEsSuPropioPadre
            CHECK (IdIndicador IS NULL OR IdIndicador <> Id)
    );

    CREATE INDEX IX_Indicador_IdIndicador
        ON dbo.Indicador(IdIndicador);
    CREATE INDEX IX_Indicador_Compania_Descripcion
        ON dbo.Indicador(CompaniaId,Descripcion);
END;
GO

IF COL_LENGTH('dbo.Indicador','CompaniaId') IS NULL
    ALTER TABLE dbo.Indicador ADD CompaniaId int NULL;
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.foreign_keys
    WHERE name=N'FK_Indicador_Compania'
      AND parent_object_id=OBJECT_ID(N'dbo.Indicador')
)
    ALTER TABLE dbo.Indicador WITH CHECK
        ADD CONSTRAINT FK_Indicador_Compania
        FOREIGN KEY (CompaniaId) REFERENCES dbo.Compania(CompaniaId);

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE name=N'IX_Indicador_Compania_Descripcion'
      AND object_id=OBJECT_ID(N'dbo.Indicador')
)
    CREATE INDEX IX_Indicador_Compania_Descripcion
        ON dbo.Indicador(CompaniaId,Descripcion);
GO

INSERT dbo.Indicador
    (CompaniaId,Area,TipoIndicador,IdIndicador,Descripcion,ValorTexto1,ValorNum)
SELECT c.CompaniaId,r.Area,0,NULL,r.Descripcion,r.Etiqueta,NULL
FROM dbo.Compania c
CROSS JOIN
(
    VALUES
        ('CAJA',  'CONFIGURACION_CAJA',  'Configuración de caja'),
        ('VENTAS','CONFIGURACION_VENTAS','Configuración de ventas')
) r(Area,Descripcion,Etiqueta)
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Indicador i
    WHERE i.CompaniaId=c.CompaniaId AND i.Descripcion=r.Descripcion
);

INSERT dbo.Indicador
    (CompaniaId,Area,TipoIndicador,IdIndicador,Descripcion,ValorTexto1,ValorNum)
SELECT c.CompaniaId,f.Area,1,p.Id,f.Descripcion,f.Etiqueta,0
FROM dbo.Compania c
CROSS JOIN
(
    VALUES
        ('CAJA',  'CONFIGURACION_CAJA',  'MULTIPLES_CAJAS','Permitir múltiples cajas abiertas'),
        ('VENTAS','CONFIGURACION_VENTAS','CAPTURA_HTML',   'Habilitar captura HTML de ventas'),
        ('VENTAS','CONFIGURACION_VENTAS','BOLETA_POR_LOTE','Habilitar emisión de boletas por lote')
) f(Area,DescripcionPadre,Descripcion,Etiqueta)
JOIN dbo.Indicador p
  ON p.CompaniaId=c.CompaniaId AND p.Descripcion=f.DescripcionPadre
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Indicador i
    WHERE i.CompaniaId=c.CompaniaId AND i.Descripcion=f.Descripcion
);
GO

/* Procedimientos modificados respecto de DXN_ICA, exportados desde DXN_CUSCO_D0109. */
CREATE OR ALTER procedure [dbo].[ingresarProducto]
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

CREATE OR ALTER procedure [dbo].[insertaClienteLD]    
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

CREATE OR ALTER procedure [dbo].[LDdocumentos]
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

CREATE OR ALTER procedure [dbo].[listaPedidosFecha]  
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

CREATE OR ALTER procedure [dbo].[listarPedidos]  
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

CREATE OR ALTER procedure [dbo].[upsInsertaTemGuiaB]      
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

CREATE OR ALTER procedure [dbo].[uspAsistenciaListaCsvB]
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

CREATE OR ALTER procedure [dbo].[uspCajaInsertaCsv]    
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

CREATE OR ALTER proc [dbo].[uspCorregirKardex]    
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

CREATE OR ALTER procedure [dbo].[uspCruzeOBS]
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

CREATE OR ALTER proc [dbo].[uspDetaAperturaB]
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

CREATE OR ALTER procedure [dbo].[uspEditarNotaB]    
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

CREATE OR ALTER proc [dbo].[uspEliminarPagoV]  
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


CREATE OR ALTER PROCEDURE dbo.uspGuardarListaPreciosPdf
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
        RAISERROR('Cada producto debe tener código y nombre.', 16, 1);
        RETURN;
    END;

    IF EXISTS (SELECT Codigo FROM @Filas GROUP BY Codigo HAVING COUNT(*) > 1)
    BEGIN
        RAISERROR('La lista contiene códigos repetidos.', 16, 1);
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

CREATE OR ALTER procedure [dbo].[uspinsertaFactura]    
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

CREATE OR ALTER procedure [dbo].[uspInsertarConteoCaja]  
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

CREATE OR ALTER procedure [dbo].[uspinsertarNotaB]            
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

CREATE OR ALTER procedure [dbo].[uspInsertarOBS]  
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

CREATE OR ALTER PROCEDURE [dbo].[uspInsertarPagoVarios]        
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
   EntidadBancaria=@Entidad,NroOperacion=@NroOperacion,NotaSaldo=0       
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
		 EntidadBancaria=@Entidad,NroOperacion=@NroOperacion,NotaSaldo=0          
		 Where NotaId=@NotaId        
        
		 update DocumentoVenta        
		 set Efectivo=0,Deposito=@Monto,FormaPago=@FormaPago,EntidadBancaria=@Entidad,        
		 NroOperacion=@NroOperacion,DocuSaldo=0          
		 Where DocuId=@DocuId   
  
	   End  
    Else  
      begin
	  
		update NotaPedido        
		set Efectivo=@EfectivoD,Deposito=@DepositoD,NotaEstado='CANCELADO',NotaFormaPago=@FormaPago,        
		EntidadBancaria=@Entidad,NroOperacion=@NroOperacion,NotaSaldo=0        
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

select top 10 * from DocumentoVenta
GO

CREATE OR ALTER procedure [dbo].[uspInventarioProducto]  
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

CREATE OR ALTER proc [dbo].[uspListaDespachoFecha]
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

CREATE OR ALTER procedure [dbo].[uspListaDocumentos]
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

CREATE OR ALTER proc [dbo].[usplistaINV]  
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

CREATE OR ALTER proc [dbo].[uspListarDespacho]
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

CREATE OR ALTER PROC usplistarPagoVarios    
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

CREATE OR ALTER PROCEDURE [dbo].[uspObtenerPVMensual]    
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

CREATE OR ALTER procedure [dbo].[uspResumenPVS]  
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

CREATE OR ALTER proc [dbo].[usptraerCajeros]
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

CREATE OR ALTER proc [dbo].[uspTraerGastos]    
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

CREATE OR ALTER proc [dbo].[usptraerSecuenciaResumen]  
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

CREATE OR ALTER proc [dbo].[uspTraeTodasMonedas]
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

CREATE OR ALTER procedure [dbo].[uspValidarApertura]
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

CREATE OR ALTER procedure [dbo].[uspValidarAperturaB]
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

CREATE OR ALTER procedure [dbo].[uspValidaUsuario]  
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



/* Procedimiento consumido por GET /api/v1/Nota/lista-cadena. */
CREATE OR ALTER PROCEDURE [dbo].[listaNotaPedido]
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
END
GO

/* Verificación del alcance: referencia + Indicador; no contratos exclusivos del backend. */
IF COL_LENGTH('dbo.CajaDetalle','DetalleConcepto') IS NULL
 OR COL_LENGTH('dbo.Compania','FechaRenovacion') IS NULL
 OR COL_LENGTH('dbo.Compania','CorreosAdmin') IS NULL
 OR COL_LENGTH('dbo.Compania','FlagCaja') IS NULL
 OR COL_LENGTH('dbo.DetalleGuiaLiquida','IdProducto') IS NULL
 OR COL_LENGTH('dbo.DetallePVarios','Efectivo') IS NULL
 OR COL_LENGTH('dbo.DetallePVarios','Deposito') IS NULL
 OR COL_LENGTH('dbo.MAQUINAS','Registro') IS NULL
 OR COL_LENGTH('dbo.MAQUINAS','SerieBoleta') IS NULL
 OR COL_LENGTH('dbo.MAQUINAS','Tiketera') IS NULL
 OR COL_LENGTH('dbo.NotaPedido','Entrega') IS NULL
 OR COL_LENGTH('dbo.NotaPedido','Hora') IS NULL
 OR COL_LENGTH('dbo.NotaPedido','Almacen') IS NULL
 OR COL_LENGTH('dbo.Producto','ProductoNombre') IS NULL
 OR COL_LENGTH('dbo.Producto','UltimoINV') IS NULL
 OR COL_LENGTH('dbo.TipoComprobante','TipoCodigo') IS NULL
 OR COL_LENGTH('dbo.TipoComprobante','TipoDescripcion') IS NULL
    THROW 51005,'La migración terminó con columnas de referencia faltantes.',1;

IF OBJECT_ID(N'dbo.Indicador',N'U') IS NULL
    THROW 51006,'No se creó la tabla dbo.Indicador.',1;

IF OBJECT_ID(N'dbo.listaNotaPedido',N'P') IS NULL
    THROW 51007,'No se creó dbo.listaNotaPedido, requerido por la API de notas.',1;

COMMIT TRANSACTION;

SELECT 'OK' Estado,
       41 ProcedimientosIncluidos,
       (SELECT COUNT(*) FROM dbo.Indicador WHERE TipoIndicador=1) FlagsIndicador;
GO
