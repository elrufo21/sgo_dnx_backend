/*
  Migra DXN_ICA con los cambios funcionales vigentes en DXN_CUSCO_D0109.
  Requisitos: ambas bases deben estar en la misma instancia de SQL Server.
  No transfiere datos; agrega columnas faltantes y sincroniza procedimientos.
*/
USE [DXN_ICA];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
GO

/* Cambios de tablas detectados. Son idempotentes. */
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
    ALTER TABLE dbo.DetalleGuiaLiquida ADD IdProducto numeric(20, 0) NULL;

IF COL_LENGTH('dbo.DetallePVarios', 'Efectivo') IS NULL
    ALTER TABLE dbo.DetallePVarios ADD Efectivo decimal(18, 2) NULL;

IF COL_LENGTH('dbo.DetallePVarios', 'Deposito') IS NULL
    ALTER TABLE dbo.DetallePVarios ADD Deposito decimal(18, 2) NULL;

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
    ALTER TABLE dbo.Producto ADD UltimoINV decimal(18, 2) NULL;

IF COL_LENGTH('dbo.TipoComprobante', 'TipoCodigo') IS NULL
    ALTER TABLE dbo.TipoComprobante ADD TipoCodigo varchar(10) NULL;

IF COL_LENGTH('dbo.TipoComprobante', 'TipoDescripcion') IS NULL
    ALTER TABLE dbo.TipoComprobante ADD TipoDescripcion varchar(80) NULL;

/* Normalizaciones sin pérdida de información. */
IF COL_LENGTH('dbo.CajaDetalle', 'DetalleConcepto') <> -1
    ALTER TABLE dbo.CajaDetalle ALTER COLUMN DetalleConcepto varchar(max) NULL;

IF COL_LENGTH('dbo.Producto', 'ProductoNombre') <> -1
    ALTER TABLE dbo.Producto ALTER COLUMN ProductoNombre varchar(max) NULL;

IF EXISTS
(
    SELECT 1
    FROM dbo.TipoComprobante
    WHERE DATALENGTH(TipoCodigo) > 10
)
    THROW 51003, 'TipoComprobante.TipoCodigo contiene valores que no caben en varchar(10).', 1;

IF COL_LENGTH('dbo.TipoComprobante', 'TipoCodigo') <> 10
    ALTER TABLE dbo.TipoComprobante ALTER COLUMN TipoCodigo varchar(10) NULL;

/*
  DetalleGuiaLiquida.IdProducto permanece numeric(38,0) y
  TipoComprobante.TipoDescripcion permanece varchar(max): ambos tipos son
  superconjuntos del origen y evitar reducirlos preserva datos existentes.
*/
GO

/*
  Los procedimientos se leen de la base fuente al ejecutar el script para
  conservar literalmente su definición vigente. CREATE se convierte a
  CREATE OR ALTER en DXN_ICA; el script funciona tanto para crear como actualizar.
*/
DECLARE @Procedimientos table (Nombre sysname NOT NULL PRIMARY KEY);

INSERT INTO @Procedimientos (Nombre) VALUES
    ('ingresarProducto'),
    ('insertaClienteLD'),
    ('LDdocumentos'),
    ('listaPedidosFecha'),
    ('listarPedidos'),
    ('upsInsertaTemGuiaB'),
    ('uspAsistenciaListaCsvB'),
    ('uspCajaInsertaCsv'),
    ('uspConsultaDNI'),
    ('uspCorregirKardex'),
    ('uspCruzeOBS'),
    ('uspDetaAperturaB'),
    ('uspEditarNotaB'),
    ('uspEliminarPagoV'),
    ('uspGuardarListaPreciosPdf'),
    ('uspinsertaFactura'),
    ('uspInsertarConteoCaja'),
    ('uspinsertarNotaB'),
    ('uspInsertarOBS'),
    ('uspInsertarPagoVarios'),
    ('uspInventarioProducto'),
    ('uspListaDespachoFecha'),
    ('uspListaDocumentos'),
    ('usplistaINV'),
    ('uspListaPersonalED'),
    ('uspListarDespacho'),
    ('usplistarPagoVarios'),
    ('uspObtenerPVMensual'),
    ('uspResumenPVS'),
    ('usptraerCajeros'),
    ('uspTraerEscaneo'),
    ('uspTraerEscaneoB'),
    ('uspTraerGastos'),
    ('usptraerSecuenciaResumen'),
    ('uspTraeTodasMonedas'),
    ('uspValidarApertura'),
    ('uspValidarAperturaB'),
    ('uspValidarNotaCre'),
    ('uspValidaUsuario'),
    ('usp_DeleteOldBackupFiles');

DECLARE @Nombre sysname, @Definicion nvarchar(max), @PosicionCreate int;
DECLARE procedimientos_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT Nombre FROM @Procedimientos ORDER BY Nombre;

OPEN procedimientos_cursor;
FETCH NEXT FROM procedimientos_cursor INTO @Nombre;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @Definicion = m.definition
    FROM [DXN_CUSCO_D0109].sys.procedures p
    INNER JOIN [DXN_CUSCO_D0109].sys.schemas s ON s.schema_id = p.schema_id
    INNER JOIN [DXN_CUSCO_D0109].sys.sql_modules m ON m.object_id = p.object_id
    WHERE s.name = 'dbo' AND p.name = @Nombre;

    IF @Definicion IS NULL
        THROW 51000, 'No se encontro un procedimiento fuente en DXN_CUSCO_D0109.', 1;

    SET @PosicionCreate = CHARINDEX('CREATE', @Definicion COLLATE Latin1_General_100_CI_AS);
    IF @PosicionCreate = 0
        THROW 51001, 'La definicion fuente no contiene CREATE.', 1;

    SET @Definicion = STUFF(@Definicion, @PosicionCreate + 6, 0, ' OR ALTER');
    EXEC sys.sp_executesql @Definicion;

    FETCH NEXT FROM procedimientos_cursor INTO @Nombre;
END;

CLOSE procedimientos_cursor;
DEALLOCATE procedimientos_cursor;
GO

/* Verificacion final: no debe encontrar diferencias. */
IF EXISTS
(
    SELECT 1
    FROM [DXN_CUSCO_D0109].sys.procedures p
    INNER JOIN [DXN_CUSCO_D0109].sys.schemas s ON s.schema_id = p.schema_id
    INNER JOIN [DXN_CUSCO_D0109].sys.sql_modules origen ON origen.object_id = p.object_id
    LEFT JOIN sys.procedures destino_p ON destino_p.name = p.name AND SCHEMA_NAME(destino_p.schema_id) = s.name
    LEFT JOIN sys.sql_modules destino ON destino.object_id = destino_p.object_id
    WHERE s.name = 'dbo'
      AND p.name IN
      (
          'ingresarProducto', 'insertaClienteLD', 'LDdocumentos', 'listaPedidosFecha', 'listarPedidos',
          'upsInsertaTemGuiaB', 'uspAsistenciaListaCsvB', 'uspCajaInsertaCsv', 'uspConsultaDNI',
          'uspCorregirKardex', 'uspCruzeOBS', 'uspDetaAperturaB', 'uspEditarNotaB', 'uspEliminarPagoV',
          'uspGuardarListaPreciosPdf', 'uspinsertaFactura', 'uspInsertarConteoCaja', 'uspinsertarNotaB',
          'uspInsertarOBS', 'uspInsertarPagoVarios', 'uspInventarioProducto', 'uspListaDespachoFecha',
          'uspListaDocumentos', 'usplistaINV', 'uspListaPersonalED', 'uspListarDespacho',
          'usplistarPagoVarios', 'uspObtenerPVMensual', 'uspResumenPVS', 'usptraerCajeros',
          'uspTraerEscaneo', 'uspTraerEscaneoB', 'uspTraerGastos', 'usptraerSecuenciaResumen',
          'uspTraeTodasMonedas', 'uspValidarApertura', 'uspValidarAperturaB', 'uspValidarNotaCre',
          'uspValidaUsuario', 'usp_DeleteOldBackupFiles'
      )
      AND
      (
          destino_p.object_id IS NULL
          OR REPLACE(REPLACE(REPLACE(origen.definition, CHAR(13), ''), CHAR(10), ''), ' ', '')
             <> REPLACE(REPLACE(REPLACE(destino.definition, CHAR(13), ''), CHAR(10), ''), ' ', '')
      )
)
    THROW 51002, 'La verificacion de procedimientos no coincidio.', 1;

COMMIT TRANSACTION;
GO
