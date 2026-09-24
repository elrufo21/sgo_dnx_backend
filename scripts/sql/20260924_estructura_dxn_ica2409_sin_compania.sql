
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
        ValorDecimal decimal(18, 2) NULL,
        FechaActualizacion datetime2(0) NOT NULL CONSTRAINT DF_Indicador_FechaActualizacion DEFAULT (sysdatetime()),
        CONSTRAINT PK_Indicador PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT CK_Indicador_NoEsSuPropioPadre CHECK (IdIndicador IS NULL OR IdIndicador <> Id)
    );
END;
GO

IF COL_LENGTH(N'dbo.Indicador', N'ValorDecimal') IS NULL
    ALTER TABLE dbo.Indicador ADD ValorDecimal decimal(18, 2) NULL;
GO

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

IF COL_LENGTH(N'dbo.CajaDetalle', N'DetalleConcepto') IS NOT NULL
   AND COL_LENGTH(N'dbo.CajaDetalle', N'DetalleConcepto') <> -1
    ALTER TABLE dbo.CajaDetalle ALTER COLUMN DetalleConcepto varchar(max) NULL;

IF EXISTS (SELECT 1 FROM dbo.DetalleGuiaLiquida WHERE Idproducto IS NOT NULL AND (Idproducto > 99999999999999999999 OR Idproducto < -99999999999999999999))
    THROW 51000, 'DetalleGuiaLiquida.Idproducto contiene valores incompatibles con numeric(20,0).', 1;
ALTER TABLE dbo.DetalleGuiaLiquida ALTER COLUMN Idproducto numeric(20, 0) NULL;

IF COL_LENGTH(N'dbo.Producto', N'ProductoNombre') IS NOT NULL
   AND COL_LENGTH(N'dbo.Producto', N'ProductoNombre') <> -1
    ALTER TABLE dbo.Producto ALTER COLUMN ProductoNombre varchar(max) NULL;

IF EXISTS (SELECT 1 FROM dbo.TipoComprobante WHERE DATALENGTH(RTRIM(TipoCodigo)) > 10)
    THROW 51000, 'TipoComprobante.TipoCodigo contiene valores de más de 10 caracteres.', 1;
ALTER TABLE dbo.TipoComprobante ALTER COLUMN TipoCodigo varchar(10) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Indicador') AND name = N'IX_Indicador_IdIndicador')
    CREATE NONCLUSTERED INDEX IX_Indicador_IdIndicador ON dbo.Indicador (IdIndicador);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Indicador') AND name = N'IX_Indicador_Compania_Descripcion')
    CREATE NONCLUSTERED INDEX IX_Indicador_Compania_Descripcion ON dbo.Indicador (CompaniaId, Descripcion);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Indicador_Compania')
    ALTER TABLE dbo.Indicador WITH CHECK ADD CONSTRAINT FK_Indicador_Compania FOREIGN KEY (CompaniaId) REFERENCES dbo.Compania (CompaniaId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Indicador_IndicadorPadre')
    ALTER TABLE dbo.Indicador WITH CHECK ADD CONSTRAINT FK_Indicador_IndicadorPadre FOREIGN KEY (IdIndicador) REFERENCES dbo.Indicador (Id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Migracion_DetalleCompra_Producto')
    ALTER TABLE dbo.DetalleCompra WITH CHECK ADD CONSTRAINT FK_Migracion_DetalleCompra_Producto FOREIGN KEY (IdProducto) REFERENCES dbo.Producto (IdProducto);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Migracion_DetalleGuiaInterna_Producto')
    ALTER TABLE dbo.DetalleGuiaInterna WITH CHECK ADD CONSTRAINT FK_Migracion_DetalleGuiaInterna_Producto FOREIGN KEY (IdProducto) REFERENCES dbo.Producto (IdProducto);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Migracion_DetalleGuiaLiquida_Producto')
    ALTER TABLE dbo.DetalleGuiaLiquida WITH CHECK ADD CONSTRAINT FK_Migracion_DetalleGuiaLiquida_Producto FOREIGN KEY (Idproducto) REFERENCES dbo.Producto (IdProducto);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Migracion_DetallesPVS_NotaPedido')
    ALTER TABLE dbo.DetallesPVS WITH CHECK ADD CONSTRAINT FK_Migracion_DetallesPVS_NotaPedido FOREIGN KEY (NotaId) REFERENCES dbo.NotaPedido (NotaId);
GO

COMMIT TRANSACTION;
GO
