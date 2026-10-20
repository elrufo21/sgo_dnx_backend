/* DXNCOMAS - SQL Server 2008: compatibilidad de seis INSERT del escritorio.
   Solo explicita las columnas originales de COMAS; no modifica datos ni reglas.
   La huella SHA1 por bloques comprueba toda la definición sin superar 8000 bytes
   por llamada HASHBYTES. No es un mecanismo para almacenar contraseñas.
   Aborta ante cambios desde la captura y permite repetir una corrección ya aplicada.
*/
USE [DXNCOMAS];
GO
SET XACT_ABORT ON;
GO

/* dbo.ingresarProducto -> dbo.Producto: 23 columnas originales. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @Definition nvarchar(max);
SET @Definition = OBJECT_DEFINITION(OBJECT_ID(N'dbo.ingresarProducto', N'P'));
IF @Definition IS NULL
BEGIN
    RAISERROR('No se pudo leer dbo.ingresarProducto. No se aplicó la compatibilidad.', 16, 1);
    RETURN;
END;
IF CHARINDEX(N'insert into Producto ([IdSubLinea], [ProductoCodigo], [ProductoNombre], [ProductoMarca], [ProductoTipoCambio], [ProductoCostoDolar], [ProductoUM], [ProductoCosto], [ProductoVenta], [AlmacenId], [ProductoUbicacion], [ProductoCantidad], [ProductoObs], [ProductoEstado], [ProductoUsuario], [ProductoFecha], [ProductoImagen], [ValorCritico], [ProductoPV], [ProductoSV], [ProductoxCaja], [ProductoINV], [AplicaFB]) values', @Definition) = 0
BEGIN
    DECLARE @Hash binary(20), @Position int;
    SET @Hash = 0x0000000000000000000000000000000000000000;
    SET @Position = 1;
    WHILE @Position <= DATALENGTH(@Definition) / 2
    BEGIN
        SET @Hash = HASHBYTES('SHA1', CONVERT(varbinary(8000), @Hash + CONVERT(varbinary(max), SUBSTRING(@Definition, @Position, 3900))));
        SET @Position = @Position + 3900;
    END;
    IF @Hash <> 0xb5c88edde25addcf176cdbaef4600864808d4be3
    BEGIN
        RAISERROR('dbo.ingresarProducto cambió después del diagnóstico. Revisar su INSERT antes de continuar.', 16, 1);
        RETURN;
    END;
    SET @Definition = REPLACE(@Definition, N'insert into Producto values', N'insert into Producto ([IdSubLinea], [ProductoCodigo], [ProductoNombre], [ProductoMarca], [ProductoTipoCambio], [ProductoCostoDolar], [ProductoUM], [ProductoCosto], [ProductoVenta], [AlmacenId], [ProductoUbicacion], [ProductoCantidad], [ProductoObs], [ProductoEstado], [ProductoUsuario], [ProductoFecha], [ProductoImagen], [ValorCritico], [ProductoPV], [ProductoSV], [ProductoxCaja], [ProductoINV], [AplicaFB]) values');
    DECLARE @Header int;
    SET @Header = PATINDEX('%PROCEDURE%', UPPER(@Definition));
    IF @Header = 0 SET @Header = PATINDEX('%PROC %', UPPER(@Definition));
    IF @Header = 0
    BEGIN
        RAISERROR('No se reconoció la cabecera de dbo.ingresarProducto.', 16, 1);
        RETURN;
    END;
    SET @Definition = N'ALTER ' + SUBSTRING(@Definition, @Header, LEN(@Definition));
    EXEC sys.sp_executesql @Definition;
END;
GO

/* dbo.ingresarUsuario -> dbo.Usuarios: 16 columnas originales. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @Definition nvarchar(max);
SET @Definition = OBJECT_DEFINITION(OBJECT_ID(N'dbo.ingresarUsuario', N'P'));
IF @Definition IS NULL
BEGIN
    RAISERROR('No se pudo leer dbo.ingresarUsuario. No se aplicó la compatibilidad.', 16, 1);
    RETURN;
END;
IF CHARINDEX(N'insert into Usuarios ([PersonalId], [UsuarioAlias], [UsuarioClave], [UsuarioFechaReg], [UsuarioEstado], [UsuarioSerie], [EnviaBoleta], [EnviarFactura], [EnviaNC], [EnviaND], [UserRuta], [UserRutaOBS], [Administrador], [RutaVentaOBS], [RutaIOC], [RutaApertura]) values', @Definition) = 0
BEGIN
    DECLARE @Hash binary(20), @Position int;
    SET @Hash = 0x0000000000000000000000000000000000000000;
    SET @Position = 1;
    WHILE @Position <= DATALENGTH(@Definition) / 2
    BEGIN
        SET @Hash = HASHBYTES('SHA1', CONVERT(varbinary(8000), @Hash + CONVERT(varbinary(max), SUBSTRING(@Definition, @Position, 3900))));
        SET @Position = @Position + 3900;
    END;
    IF @Hash <> 0xf94bfc3c40f1c1f213ef1ef783cf2350fdd71576
    BEGIN
        RAISERROR('dbo.ingresarUsuario cambió después del diagnóstico. Revisar su INSERT antes de continuar.', 16, 1);
        RETURN;
    END;
    SET @Definition = REPLACE(@Definition, N'insert into Usuarios values', N'insert into Usuarios ([PersonalId], [UsuarioAlias], [UsuarioClave], [UsuarioFechaReg], [UsuarioEstado], [UsuarioSerie], [EnviaBoleta], [EnviarFactura], [EnviaNC], [EnviaND], [UserRuta], [UserRutaOBS], [Administrador], [RutaVentaOBS], [RutaIOC], [RutaApertura]) values');
    DECLARE @Header int;
    SET @Header = PATINDEX('%PROCEDURE%', UPPER(@Definition));
    IF @Header = 0 SET @Header = PATINDEX('%PROC %', UPPER(@Definition));
    IF @Header = 0
    BEGIN
        RAISERROR('No se reconoció la cabecera de dbo.ingresarUsuario.', 16, 1);
        RETURN;
    END;
    SET @Definition = N'ALTER ' + SUBSTRING(@Definition, @Header, LEN(@Definition));
    EXEC sys.sp_executesql @Definition;
END;
GO

/* dbo.InsertarUM -> dbo.UnidadMedida: 6 columnas originales. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @Definition nvarchar(max);
SET @Definition = OBJECT_DEFINITION(OBJECT_ID(N'dbo.InsertarUM', N'P'));
IF @Definition IS NULL
BEGIN
    RAISERROR('No se pudo leer dbo.InsertarUM. No se aplicó la compatibilidad.', 16, 1);
    RETURN;
END;
IF CHARINDEX(N'insert into UnidadMedida ([IdProducto], [UMDescripcion], [ValorUM], [PrecioVenta], [PrecioVentaB], [PrecioCosto]) values', @Definition) = 0
BEGIN
    DECLARE @Hash binary(20), @Position int;
    SET @Hash = 0x0000000000000000000000000000000000000000;
    SET @Position = 1;
    WHILE @Position <= DATALENGTH(@Definition) / 2
    BEGIN
        SET @Hash = HASHBYTES('SHA1', CONVERT(varbinary(8000), @Hash + CONVERT(varbinary(max), SUBSTRING(@Definition, @Position, 3900))));
        SET @Position = @Position + 3900;
    END;
    IF @Hash <> 0x3db369a926ce569ad6d0064259eefe698a6fbce3
    BEGIN
        RAISERROR('dbo.InsertarUM cambió después del diagnóstico. Revisar su INSERT antes de continuar.', 16, 1);
        RETURN;
    END;
    SET @Definition = REPLACE(@Definition, N'insert into UnidadMedida values', N'insert into UnidadMedida ([IdProducto], [UMDescripcion], [ValorUM], [PrecioVenta], [PrecioVentaB], [PrecioCosto]) values');
    DECLARE @Header int;
    SET @Header = PATINDEX('%PROCEDURE%', UPPER(@Definition));
    IF @Header = 0 SET @Header = PATINDEX('%PROC %', UPPER(@Definition));
    IF @Header = 0
    BEGIN
        RAISERROR('No se reconoció la cabecera de dbo.InsertarUM.', 16, 1);
        RETURN;
    END;
    SET @Definition = N'ALTER ' + SUBSTRING(@Definition, @Header, LEN(@Definition));
    EXEC sys.sp_executesql @Definition;
END;
GO

/* dbo.uspinsertarNotaB -> dbo.NotaPedido: 37 columnas originales. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @Definition nvarchar(max);
SET @Definition = OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarNotaB', N'P'));
IF @Definition IS NULL
BEGIN
    RAISERROR('No se pudo leer dbo.uspinsertarNotaB. No se aplicó la compatibilidad.', 16, 1);
    RETURN;
END;
IF CHARINDEX(N'insert into NotaPedido ([NotaDocu], [ClienteId], [NotaFecha], [NotaUsuario], [NotaFormaPago], [NotaCondicion], [NotaFechaPago], [NotaDireccion], [NotaSubtotal], [NotaMovilidad], [NotaDescuento], [NotaTotal], [NotaAcuenta], [NotaSaldo], [NotaAdicional], [NotaTarjeta], [NotaPagar], [NotaEstado], [CompaniaId], [NotaEntrega], [ModificadoPor], [FechaEdita], [NotaConcepto], [NotaSerie], [NotaNumero], [NotaGanancia], [CajaId], [NotaTransaccion], [ICBPER], [ConceptoOBS], [EstadoOBS], [CodigoRes], [Responsable], [EntidadBancaria], [NroOperacion], [Efectivo], [Deposito]) values', @Definition) = 0
BEGIN
    DECLARE @Hash binary(20), @Position int;
    SET @Hash = 0x0000000000000000000000000000000000000000;
    SET @Position = 1;
    WHILE @Position <= DATALENGTH(@Definition) / 2
    BEGIN
        SET @Hash = HASHBYTES('SHA1', CONVERT(varbinary(8000), @Hash + CONVERT(varbinary(max), SUBSTRING(@Definition, @Position, 3900))));
        SET @Position = @Position + 3900;
    END;
    IF @Hash <> 0x7b598d40f302c583847644d8f696c4883fb6e2eb
    BEGIN
        RAISERROR('dbo.uspinsertarNotaB cambió después del diagnóstico. Revisar su INSERT antes de continuar.', 16, 1);
        RETURN;
    END;
    SET @Definition = REPLACE(@Definition, N'insert into NotaPedido values', N'insert into NotaPedido ([NotaDocu], [ClienteId], [NotaFecha], [NotaUsuario], [NotaFormaPago], [NotaCondicion], [NotaFechaPago], [NotaDireccion], [NotaSubtotal], [NotaMovilidad], [NotaDescuento], [NotaTotal], [NotaAcuenta], [NotaSaldo], [NotaAdicional], [NotaTarjeta], [NotaPagar], [NotaEstado], [CompaniaId], [NotaEntrega], [ModificadoPor], [FechaEdita], [NotaConcepto], [NotaSerie], [NotaNumero], [NotaGanancia], [CajaId], [NotaTransaccion], [ICBPER], [ConceptoOBS], [EstadoOBS], [CodigoRes], [Responsable], [EntidadBancaria], [NroOperacion], [Efectivo], [Deposito]) values');
    DECLARE @Header int;
    SET @Header = PATINDEX('%PROCEDURE%', UPPER(@Definition));
    IF @Header = 0 SET @Header = PATINDEX('%PROC %', UPPER(@Definition));
    IF @Header = 0
    BEGIN
        RAISERROR('No se reconoció la cabecera de dbo.uspinsertarNotaB.', 16, 1);
        RETURN;
    END;
    SET @Definition = N'ALTER ' + SUBSTRING(@Definition, @Header, LEN(@Definition));
    EXEC sys.sp_executesql @Definition;
END;
GO

/* dbo.uspInsertarPagoVarios -> dbo.DetallePVarios: 5 columnas originales. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @Definition nvarchar(max);
SET @Definition = OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspInsertarPagoVarios', N'P'));
IF @Definition IS NULL
BEGIN
    RAISERROR('No se pudo leer dbo.uspInsertarPagoVarios. No se aplicó la compatibilidad.', 16, 1);
    RETURN;
END;
IF CHARINDEX(N'insert into DetallePVarios ([PagoId], [DocuId], [NotaId], [Monto], [ConceptoOBS]) values', @Definition) = 0
BEGIN
    DECLARE @Hash binary(20), @Position int;
    SET @Hash = 0x0000000000000000000000000000000000000000;
    SET @Position = 1;
    WHILE @Position <= DATALENGTH(@Definition) / 2
    BEGIN
        SET @Hash = HASHBYTES('SHA1', CONVERT(varbinary(8000), @Hash + CONVERT(varbinary(max), SUBSTRING(@Definition, @Position, 3900))));
        SET @Position = @Position + 3900;
    END;
    IF @Hash <> 0x7b0625865eca8869e629866780eba502f84ac14c
    BEGIN
        RAISERROR('dbo.uspInsertarPagoVarios cambió después del diagnóstico. Revisar su INSERT antes de continuar.', 16, 1);
        RETURN;
    END;
    SET @Definition = REPLACE(@Definition, N'insert into DetallePVarios values', N'insert into DetallePVarios ([PagoId], [DocuId], [NotaId], [Monto], [ConceptoOBS]) values');
    DECLARE @Header int;
    SET @Header = PATINDEX('%PROCEDURE%', UPPER(@Definition));
    IF @Header = 0 SET @Header = PATINDEX('%PROC %', UPPER(@Definition));
    IF @Header = 0
    BEGIN
        RAISERROR('No se reconoció la cabecera de dbo.uspInsertarPagoVarios.', 16, 1);
        RETURN;
    END;
    SET @Definition = N'ALTER ' + SUBSTRING(@Definition, @Header, LEN(@Definition));
    EXEC sys.sp_executesql @Definition;
END;
GO

/* dbo.uspinsertarRB -> dbo.ResumenBoletas: 16 columnas originales. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @Definition nvarchar(max);
SET @Definition = OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarRB', N'P'));
IF @Definition IS NULL
BEGIN
    RAISERROR('No se pudo leer dbo.uspinsertarRB. No se aplicó la compatibilidad.', 16, 1);
    RETURN;
END;
IF CHARINDEX(N'insert into ResumenBoletas ([CompaniaId], [ResumenSerie], [Secuencia], [FechaReferencia], [FechaEnvio], [SubTotal], [IGV], [Total], [ResumenTiket], [CodigoSunat], [HASHCDR], [MensajeSunat], [Usuario], [ESTADO], [RangoNumero], [ICBPER]) values', @Definition) = 0
BEGIN
    DECLARE @Hash binary(20), @Position int;
    SET @Hash = 0x0000000000000000000000000000000000000000;
    SET @Position = 1;
    WHILE @Position <= DATALENGTH(@Definition) / 2
    BEGIN
        SET @Hash = HASHBYTES('SHA1', CONVERT(varbinary(8000), @Hash + CONVERT(varbinary(max), SUBSTRING(@Definition, @Position, 3900))));
        SET @Position = @Position + 3900;
    END;
    IF @Hash <> 0x885cf048b81958fc9a9a8198423a6deb26977da5
    BEGIN
        RAISERROR('dbo.uspinsertarRB cambió después del diagnóstico. Revisar su INSERT antes de continuar.', 16, 1);
        RETURN;
    END;
    SET @Definition = REPLACE(@Definition, N'insert into ResumenBoletas values', N'insert into ResumenBoletas ([CompaniaId], [ResumenSerie], [Secuencia], [FechaReferencia], [FechaEnvio], [SubTotal], [IGV], [Total], [ResumenTiket], [CodigoSunat], [HASHCDR], [MensajeSunat], [Usuario], [ESTADO], [RangoNumero], [ICBPER]) values');
    DECLARE @Header int;
    SET @Header = PATINDEX('%PROCEDURE%', UPPER(@Definition));
    IF @Header = 0 SET @Header = PATINDEX('%PROC %', UPPER(@Definition));
    IF @Header = 0
    BEGIN
        RAISERROR('No se reconoció la cabecera de dbo.uspinsertarRB.', 16, 1);
        RETURN;
    END;
    SET @Definition = N'ALTER ' + SUBSTRING(@Definition, @Header, LEN(@Definition));
    EXEC sys.sp_executesql @Definition;
END;
GO
