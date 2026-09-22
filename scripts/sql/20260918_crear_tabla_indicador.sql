/*
  Configuración jerárquica de indicadores para DXN_ICA.
  IdIndicador es el padre; NULL identifica un indicador raíz.
*/
USE [DXN_ICA];
GO

IF OBJECT_ID(N'dbo.Indicador', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Indicador
    (
        Id                  int IDENTITY(1, 1) NOT NULL,
        CompaniaId          int NULL,
        Area                varchar(100) NOT NULL,
        TipoIndicador       int NOT NULL,
        IdIndicador         int NULL,
        Descripcion         varchar(500) NOT NULL,
        ValorTexto1         varchar(500) NULL,
        ValorNum            int NULL,
        FechaActualizacion  datetime2(0) NOT NULL
            CONSTRAINT DF_Indicador_FechaActualizacion DEFAULT (SYSDATETIME()),

        CONSTRAINT PK_Indicador PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_Indicador_Compania
            FOREIGN KEY (CompaniaId) REFERENCES dbo.Compania (CompaniaId),
        CONSTRAINT FK_Indicador_IndicadorPadre
            FOREIGN KEY (IdIndicador) REFERENCES dbo.Indicador (Id),
        CONSTRAINT CK_Indicador_NoEsSuPropioPadre
            CHECK (IdIndicador IS NULL OR IdIndicador <> Id)
    );

    CREATE INDEX IX_Indicador_IdIndicador ON dbo.Indicador (IdIndicador);
    CREATE INDEX IX_Indicador_Compania_Descripcion
        ON dbo.Indicador (CompaniaId, Descripcion);
END;
GO
