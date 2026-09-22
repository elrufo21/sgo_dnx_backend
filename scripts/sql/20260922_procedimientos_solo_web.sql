/*
  Migra únicamente los procedimientos usados por los endpoints activos de la web.
  Ejecutar conectado a la BASE DESTINO (por ejemplo DXN_ICA2209).
  Requiere que la base fuente DXN_ICA esté en la misma instancia de SQL Server.
  Los procedimientos compartidos cuya lógica difiere se crean con sufijo WEB;
  los procedimientos originales se preservan para el escritorio.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @BaseFuente sysname = N'DXN_ICA';

IF DB_ID(@BaseFuente) IS NULL
BEGIN
    RAISERROR('No existe la base fuente DXN_ICA en esta instancia.', 16, 1);
    RETURN;
END;

DECLARE @Procedimientos TABLE
(
    NombreFuente sysname NOT NULL,
    NombreDestino sysname NOT NULL PRIMARY KEY
);

INSERT INTO @Procedimientos (NombreFuente, NombreDestino)
VALUES
    (N'anularDocumento', N'anularDocumento'),
    (N'editarCompania', N'editarCompania'),
    (N'editarProducto', N'editarProducto'),
    (N'ingresarProducto', N'ingresarProducto'),
    (N'LDdocumentosweb', N'LDdocumentosweb'),
    (N'listaNotaPedido', N'listaNotaPedido'),
    (N'listarCaja', N'listarCaja'),
    (N'listarCajaFecha', N'listarCajaFecha'),
    (N'listarDetaCaja', N'listarDetaCaja'),
    (N'usp_Area', N'usp_Area'),
    (N'usp_Feriado', N'usp_Feriado'),
    (N'usp_Maquina', N'usp_Maquina'),
    (N'usp_Personal', N'usp_Personal'),
    (N'usp_Usuario', N'usp_Usuario'),
    (N'uspCajaInsertaCsvWeb', N'uspCajaInsertaCsvWeb'),
    (N'uspEditarConteoCajaWEB', N'uspEditarConteoCajaWEB'),
    (N'uspEditarNotaPedido', N'uspEditarNotaPedido'),
    (N'uspEditarRBweb', N'uspEditarRBweb'),
    (N'uspEliminarCajaDetalle', N'uspEliminarCajaDetalleWEB'),
    (N'uspEliminarPagoV', N'uspEliminarPagoVWEB'),
    (N'uspGuardarCredencialesSunatweb', N'uspGuardarCredencialesSunatweb'),
    (N'uspGuardarListaPreciosPdf', N'uspGuardarListaPreciosPdf'),
    (N'uspInsertarConteoCaja', N'uspInsertarConteoCajaWEB'),
    (N'uspinsertarNotaBweb', N'uspinsertarNotaBweb'),
    (N'uspInsertarPagoVarios', N'uspInsertarPagoVariosWEB'),
    (N'uspinsertarRBweb', N'uspinsertarRBweb'),
    (N'usplistaConteo', N'usplistaConteo'),
    (N'usplistaDetalleConteo', N'usplistaDetalleConteo'),
    (N'uspListarComprasweb', N'uspListarComprasweb'),
    (N'usplistarPagoVarios', N'usplistarPagoVariosWEB'),
    (N'uspObtenerCajaActivaWEB', N'uspObtenerCajaActivaWEB'),
    (N'uspObtenerCredencialesSunatweb', N'uspObtenerCredencialesSunatweb'),
    (N'uspResumenFechaweb', N'uspResumenFechaweb'),
    (N'uspRetornaBoletaPorTicket', N'uspRetornaBoletaPorTicket'),
    (N'uspRetornarBoletas', N'uspRetornarBoletas'),
    (N'usptraerCajeros', N'usptraerCajerosWEB'),
    (N'uspTraerGastos', N'uspTraerGastosWEB'),
    (N'uspTraerGastosA', N'uspTraerGastosAWEB'),
    (N'usptraerSecuenciaResumen', N'usptraerSecuenciaResumen'),
    (N'uspTraeTodasMonedas', N'uspTraeTodasMonedasWEB'),
    (N'uspValidaCantCajasWeb', N'uspValidaCantCajasWeb'),
    (N'uspValidarApertura', N'uspValidarAperturaWEB'),
    (N'uspValidaUsuarioweb', N'uspValidaUsuarioweb');

DECLARE
    @NombreFuente sysname,
    @NombreDestino sysname,
    @Definicion nvarchar(max),
    @ConsultaFuente nvarchar(max),
    @PosicionProcedimiento int,
    @PosicionParametro int;

SET @ConsultaFuente = N'
    SELECT @DefinicionSalida = sm.definition
    FROM ' + QUOTENAME(@BaseFuente) + N'.sys.procedures AS p
    INNER JOIN ' + QUOTENAME(@BaseFuente) + N'.sys.sql_modules AS sm
        ON sm.object_id = p.object_id
    WHERE SCHEMA_NAME(p.schema_id) = N''dbo''
      AND p.name = @NombreProcedimiento;';

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE CursorProcedimientos CURSOR LOCAL FAST_FORWARD FOR
        SELECT NombreFuente, NombreDestino
        FROM @Procedimientos
        ORDER BY NombreDestino;

    OPEN CursorProcedimientos;
    FETCH NEXT FROM CursorProcedimientos INTO @NombreFuente, @NombreDestino;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Definicion = NULL;

        EXEC sys.sp_executesql
            @ConsultaFuente,
            N'@NombreProcedimiento sysname, @DefinicionSalida nvarchar(max) OUTPUT',
            @NombreProcedimiento = @NombreFuente,
            @DefinicionSalida = @Definicion OUTPUT;

        IF @Definicion IS NULL
        BEGIN
            RAISERROR('Falta el procedimiento dbo.%s en la base fuente.', 16, 1, @NombreFuente);
        END;

        SET @PosicionProcedimiento = CHARINDEX(N'PROCEDURE', UPPER(@Definicion));

        IF @PosicionProcedimiento = 0
        BEGIN
            RAISERROR('La definición de dbo.%s no es válida.', 16, 1, @NombreFuente);
        END;

        IF @NombreFuente = @NombreDestino
            SET @Definicion = STUFF(@Definicion, 1, @PosicionProcedimiento - 1, N'CREATE OR ALTER ');
        ELSE
        BEGIN
            SET @PosicionParametro = CHARINDEX(N'@', @Definicion, @PosicionProcedimiento);

            IF @PosicionParametro = 0
                RAISERROR('No se pudo renombrar dbo.%s como dbo.%s.', 16, 1, @NombreFuente, @NombreDestino);

            SET @Definicion = STUFF(
                @Definicion,
                1,
                @PosicionParametro - 1,
                N'CREATE OR ALTER PROCEDURE dbo.' + QUOTENAME(@NombreDestino) + N' '
            );
        END;

        EXEC sys.sp_executesql @Definicion;

        FETCH NEXT FROM CursorProcedimientos INTO @NombreFuente, @NombreDestino;
    END;

    CLOSE CursorProcedimientos;
    DEALLOCATE CursorProcedimientos;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF CURSOR_STATUS('local', 'CursorProcedimientos') >= -1
    BEGIN
        CLOSE CursorProcedimientos;
        DEALLOCATE CursorProcedimientos;
    END;

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    DECLARE @MensajeError nvarchar(2048) = ERROR_MESSAGE();
    RAISERROR('%s', 16, 1, @MensajeError);
END CATCH;
GO

DECLARE @Esperados int = 43;
DECLARE @Instalados int;

SELECT @Instalados = COUNT(*)
FROM sys.procedures
WHERE schema_id = SCHEMA_ID(N'dbo')
  AND name IN
  (
      N'anularDocumento', N'editarCompania', N'editarProducto', N'ingresarProducto',
      N'LDdocumentosweb', N'listaNotaPedido', N'listarCaja', N'listarCajaFecha',
      N'listarDetaCaja', N'usp_Area', N'usp_Feriado', N'usp_Maquina', N'usp_Personal',
      N'usp_Usuario', N'uspCajaInsertaCsvWeb', N'uspEditarConteoCajaWEB',
      N'uspEditarNotaPedido', N'uspEditarRBweb', N'uspEliminarCajaDetalleWEB',
      N'uspEliminarPagoVWEB', N'uspGuardarCredencialesSunatweb',
      N'uspGuardarListaPreciosPdf', N'uspInsertarConteoCajaWEB',
      N'uspinsertarNotaBweb', N'uspInsertarPagoVariosWEB', N'uspinsertarRBweb',
      N'usplistaConteo', N'usplistaDetalleConteo', N'uspListarComprasweb',
      N'usplistarPagoVariosWEB', N'uspObtenerCajaActivaWEB',
      N'uspObtenerCredencialesSunatweb', N'uspResumenFechaweb',
      N'uspRetornaBoletaPorTicket', N'uspRetornarBoletas', N'usptraerCajerosWEB',
      N'uspTraerGastosWEB', N'uspTraerGastosAWEB', N'usptraerSecuenciaResumen',
      N'uspTraeTodasMonedasWEB', N'uspValidaCantCajasWeb', N'uspValidarAperturaWEB',
      N'uspValidaUsuarioweb'
  );

IF @Instalados <> @Esperados
BEGIN
    RAISERROR('Validación fallida: se esperaban %d procedimientos web y se encontraron %d.', 16, 1, @Esperados, @Instalados);
    RETURN;
END;

PRINT 'OK: 43 procedimientos web migrados desde DXN_ICA.';
GO
