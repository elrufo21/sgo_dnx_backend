/*
  DXNCOMAS - esquema requerido por los flujos llamados desde el frontend web
  Fuente de definiciones: DXN_ICA15102026, comparada con el alcance frontend confirmado.
  No contiene datos ni configuraciones propias de ICA.
  Aplicar en DXNCOMAS. Revisar docs/migracion-sql-dxncomas-20261019.md.
*/
USE [DXNCOMAS];
GO

/*
  Agrega columnas ausentes en tablas existentes de COMAS.
  Almacen y Hora son complementarias: la web actual tolera que falten.
  Si el sistema de escritorio seguirá activo, revisar los INSERT posicionales
  indicados en docs/migracion-sql-dxncomas-20261019.md antes de aplicar.
*/
IF COL_LENGTH(N'dbo.DetallePVarios', N'Efectivo') IS NULL
    ALTER TABLE dbo.[DetallePVarios] ADD [Efectivo] decimal(18,2) NULL;
GO

IF COL_LENGTH(N'dbo.DetallePVarios', N'Deposito') IS NULL
    ALTER TABLE dbo.[DetallePVarios] ADD [Deposito] decimal(18,2) NULL;
GO

IF COL_LENGTH(N'dbo.MAQUINAS', N'Registro') IS NULL
    ALTER TABLE dbo.[MAQUINAS] ADD [Registro] datetime NULL;
GO

IF COL_LENGTH(N'dbo.MAQUINAS', N'SerieBoleta') IS NULL
    ALTER TABLE dbo.[MAQUINAS] ADD [SerieBoleta] nvarchar(4) NULL;
GO

IF COL_LENGTH(N'dbo.MAQUINAS', N'Tiketera') IS NULL
    ALTER TABLE dbo.[MAQUINAS] ADD [Tiketera] varchar(300) NULL;
GO

IF COL_LENGTH(N'dbo.NotaPedido', N'Entrega') IS NULL
    ALTER TABLE dbo.[NotaPedido] ADD [Entrega] varchar(20) NULL;
GO

IF COL_LENGTH(N'dbo.NotaPedido', N'Hora') IS NULL
    ALTER TABLE dbo.[NotaPedido] ADD [Hora] datetime NULL;
GO

IF COL_LENGTH(N'dbo.NotaPedido', N'Almacen') IS NULL
    ALTER TABLE dbo.[NotaPedido] ADD [Almacen] varchar(80) NULL;
GO

IF COL_LENGTH(N'dbo.Producto', N'UltimoINV') IS NULL
    ALTER TABLE dbo.[Producto] ADD [UltimoINV] decimal(18,2) NULL;
GO

IF COL_LENGTH(N'dbo.Producto', N'ProductoVentaB') IS NULL
    ALTER TABLE dbo.[Producto] ADD [ProductoVentaB] decimal(18,2) NULL;
GO

IF COL_LENGTH(N'dbo.Producto', N'AplicaINV') IS NULL
    ALTER TABLE dbo.[Producto] ADD [AplicaINV] varchar(1) NULL;
GO

IF COL_LENGTH(N'dbo.ResumenBoletas', N'CDRBase64') IS NULL
    ALTER TABLE dbo.[ResumenBoletas] ADD [CDRBase64] varchar(max) NULL;
GO

IF COL_LENGTH(N'dbo.UnidadMedida', N'unidadImagen') IS NULL
    ALTER TABLE dbo.[UnidadMedida] ADD [unidadImagen] varchar(255) NULL;
GO

IF COL_LENGTH(N'dbo.Usuarios', N'FechaVencimientoClave') IS NULL
    ALTER TABLE dbo.[Usuarios] ADD [FechaVencimientoClave] date NULL;
GO

