/*
  DXNCOMAS - esquema requerido por los flujos llamados desde el frontend web
  Fuente de definiciones: DXN_ICA15102026, comparada con el alcance frontend confirmado.
  No contiene datos ni configuraciones propias de ICA.
  Aplicar en DXNCOMAS. Revisar docs/migracion-sql-dxncomas-20261019.md.
*/
USE [DXNCOMAS];
GO

/* Tabla de indicadores y parámetros. Cargar luego los valores propios de COMAS. */
IF OBJECT_ID(N'dbo.Indicador', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Indicador
    (
        Id int IDENTITY(1,1) NOT NULL,
        CompaniaId int NULL,
        Area varchar(100) NOT NULL,
        TipoIndicador int NOT NULL,
        IdIndicador int NULL,
        Descripcion varchar(500) NOT NULL,
        ValorTexto1 varchar(max) NULL,
        ValorNum int NULL,
        ValorDecimal decimal(18,2) NULL,
        FechaActualizacion datetime2(0) NOT NULL
            CONSTRAINT DF_Indicador_FechaActualizacion DEFAULT (sysdatetime()),
        CONSTRAINT PK_Indicador PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT CK_Indicador_NoEsSuPropioPadre
            CHECK (IdIndicador IS NULL OR IdIndicador <> Id),
        CONSTRAINT FK_Indicador_Compania
            FOREIGN KEY (CompaniaId) REFERENCES dbo.Compania (CompaniaId),
        CONSTRAINT FK_Indicador_IndicadorPadre
            FOREIGN KEY (IdIndicador) REFERENCES dbo.Indicador (Id)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Indicador') AND name = N'IX_Indicador_IdIndicador')
    CREATE NONCLUSTERED INDEX IX_Indicador_IdIndicador ON dbo.Indicador (IdIndicador);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Indicador') AND name = N'IX_Indicador_Compania_Descripcion')
    CREATE NONCLUSTERED INDEX IX_Indicador_Compania_Descripcion ON dbo.Indicador (CompaniaId, Descripcion);
GO

/* Metadatos de documentos CPE locales. No incluye certificados ni archivos. */
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
        FechaRegistro datetime NOT NULL
            CONSTRAINT DF_DocumentoVentaCpeWeb_FechaRegistro DEFAULT (getdate()),
        CONSTRAINT PK_DocumentoVentaCpeWeb PRIMARY KEY CLUSTERED (DocuId)
    );
END;
GO

/* Índice de cobertura presente en la definición de referencia. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.DocumentoVentaCpeWeb') AND name = N'IX_DocumentoVentaCpeWeb_DocuId')
    CREATE NONCLUSTERED INDEX IX_DocumentoVentaCpeWeb_DocuId
        ON dbo.DocumentoVentaCpeWeb (DocuId)
        INCLUDE (DocuPdfUrl, DocuXmlUrl, DocuCdrUrl, DocuFechaPago);
GO
