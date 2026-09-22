/*
  Solo estructura nueva: tablas y columnas incorporadas en DXN_ICA
  respecto de DXN_ICA2209. No incluye procedimientos, cambios de tipo,
  índices o relaciones de tablas preexistentes. No mueve datos de negocio.
*/
USE [DXN_ICA2209];
GO
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

/* Tablas nuevas. */
IF OBJECT_ID(N'dbo.DocumentoVentaCpeWeb', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DocumentoVentaCpeWeb
    (
        DocuId numeric(38, 0) NOT NULL,
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

IF OBJECT_ID(N'dbo.Indicador', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Indicador
    (
        Id int IDENTITY(1, 1) NOT NULL,
        CompaniaId int NULL,
        Area varchar(100) NOT NULL,
        TipoIndicador int NOT NULL,
        IdIndicador int NULL,
        Descripcion varchar(500) NOT NULL,
        ValorTexto1 varchar(500) NULL,
        ValorNum int NULL,
        FechaActualizacion datetime2(0) NOT NULL CONSTRAINT DF_Indicador_FechaActualizacion DEFAULT (sysdatetime()),
        CONSTRAINT PK_Indicador PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT CK_Indicador_NoEsSuPropioPadre CHECK (IdIndicador IS NULL OR IdIndicador <> Id)
    );
END;
GO

/* Columnas nuevas en tablas ya existentes. */
IF COL_LENGTH(N'dbo.Compania', N'FechaRenovacion') IS NULL ALTER TABLE dbo.Compania ADD FechaRenovacion date NULL;
IF COL_LENGTH(N'dbo.Compania', N'CorreosAdmin') IS NULL ALTER TABLE dbo.Compania ADD CorreosAdmin varchar(max) NULL;
IF COL_LENGTH(N'dbo.Compania', N'FlagCaja') IS NULL ALTER TABLE dbo.Compania ADD FlagCaja bit NOT NULL CONSTRAINT DF_Compania_FlagCaja DEFAULT ((0)) WITH VALUES;
IF COL_LENGTH(N'dbo.Compania', N'TIPO_PROCESO') IS NULL ALTER TABLE dbo.Compania ADD TIPO_PROCESO int NULL;
IF COL_LENGTH(N'dbo.Compania', N'DescuentoMax') IS NULL ALTER TABLE dbo.Compania ADD DescuentoMax decimal(18, 2) NULL;
IF COL_LENGTH(N'dbo.Compania', N'CorreoSGO') IS NULL ALTER TABLE dbo.Compania ADD CorreoSGO varchar(250) NULL;
IF COL_LENGTH(N'dbo.Compania', N'PasswordCorreo') IS NULL ALTER TABLE dbo.Compania ADD PasswordCorreo varchar(250) NULL;
IF COL_LENGTH(N'dbo.Compania', N'BoletaPorLote') IS NULL ALTER TABLE dbo.Compania ADD BoletaPorLote bit NOT NULL CONSTRAINT DF_Compania_BoletaPorLote DEFAULT ((0)) WITH VALUES;
IF COL_LENGTH(N'dbo.Compania', N'FlagCaptura') IS NULL ALTER TABLE dbo.Compania ADD FlagCaptura bit NOT NULL CONSTRAINT DF_Compania_FlagCaptura DEFAULT ((0)) WITH VALUES;
IF COL_LENGTH(N'dbo.DetallePVarios', N'Efectivo') IS NULL ALTER TABLE dbo.DetallePVarios ADD Efectivo decimal(18, 2) NULL;
IF COL_LENGTH(N'dbo.DetallePVarios', N'Deposito') IS NULL ALTER TABLE dbo.DetallePVarios ADD Deposito decimal(18, 2) NULL;
IF COL_LENGTH(N'dbo.MAQUINAS', N'Registro') IS NULL ALTER TABLE dbo.MAQUINAS ADD Registro datetime NULL;
IF COL_LENGTH(N'dbo.MAQUINAS', N'SerieBoleta') IS NULL ALTER TABLE dbo.MAQUINAS ADD SerieBoleta nvarchar(4) NULL;
IF COL_LENGTH(N'dbo.MAQUINAS', N'Tiketera') IS NULL ALTER TABLE dbo.MAQUINAS ADD Tiketera varchar(300) NULL;
IF COL_LENGTH(N'dbo.NotaPedido', N'Entrega') IS NULL ALTER TABLE dbo.NotaPedido ADD Entrega varchar(20) NULL;
IF COL_LENGTH(N'dbo.NotaPedido', N'Hora') IS NULL ALTER TABLE dbo.NotaPedido ADD Hora datetime NULL;
IF COL_LENGTH(N'dbo.NotaPedido', N'Almacen') IS NULL ALTER TABLE dbo.NotaPedido ADD Almacen varchar(80) NULL;
IF COL_LENGTH(N'dbo.Producto', N'UltimoINV') IS NULL ALTER TABLE dbo.Producto ADD UltimoINV decimal(18, 2) NULL;
IF COL_LENGTH(N'dbo.Producto', N'ProductoVentaB') IS NULL ALTER TABLE dbo.Producto ADD ProductoVentaB decimal(18, 2) NULL;
IF COL_LENGTH(N'dbo.Producto', N'AplicaINV') IS NULL ALTER TABLE dbo.Producto ADD AplicaINV varchar(1) NULL;
IF COL_LENGTH(N'dbo.ResumenBoletas', N'CDRBase64') IS NULL ALTER TABLE dbo.ResumenBoletas ADD CDRBase64 varchar(max) NULL;
IF COL_LENGTH(N'dbo.UnidadMedida', N'unidadImagen') IS NULL ALTER TABLE dbo.UnidadMedida ADD unidadImagen varchar(255) NULL;
IF COL_LENGTH(N'dbo.Usuarios', N'FechaVencimientoClave') IS NULL ALTER TABLE dbo.Usuarios ADD FechaVencimientoClave date NULL;
GO

/* Índices y relaciones propios de la tabla nueva Indicador. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Indicador') AND name = N'IX_Indicador_IdIndicador')
    CREATE NONCLUSTERED INDEX IX_Indicador_IdIndicador ON dbo.Indicador (IdIndicador);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Indicador') AND name = N'IX_Indicador_Compania_Descripcion')
    CREATE NONCLUSTERED INDEX IX_Indicador_Compania_Descripcion ON dbo.Indicador (CompaniaId, Descripcion);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Indicador_Compania')
    ALTER TABLE dbo.Indicador WITH CHECK ADD CONSTRAINT FK_Indicador_Compania FOREIGN KEY (CompaniaId) REFERENCES dbo.Compania (CompaniaId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Indicador_IndicadorPadre')
    ALTER TABLE dbo.Indicador WITH CHECK ADD CONSTRAINT FK_Indicador_IndicadorPadre FOREIGN KEY (IdIndicador) REFERENCES dbo.Indicador (Id);
GO

COMMIT TRANSACTION;
SELECT N'OK: tablas y columnas nuevas aplicadas.' AS Resultado;
GO
