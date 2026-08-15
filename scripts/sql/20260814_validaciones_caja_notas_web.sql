/* Validaciones de caja en los procedimientos que ya consume la web. */
SET NOCOUNT ON;
GO

DECLARE @definition nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarNotaBweb'));

IF @definition IS NULL
    THROW 50000, 'No existe dbo.uspinsertarNotaBweb.', 1;

SET @definition = REPLACE(@definition, CHAR(13) + CHAR(10), CHAR(10));

IF CHARINDEX(N'@CajaId numeric(38)', @definition) = 0
BEGIN
    SET @definition = REPLACE(
        @definition,
        N'AND EXISTS (SELECT 1 FROM NotaPedido WHERE NotaTransaccion = @NotaTransaccion)',
        N'AND EXISTS (SELECT 1 FROM NotaPedido WHERE NotaTransaccion = @NotaTransaccion AND ISNULL(NotaEstado, '''') <> ''ANULADO'')');

    SET @definition = REPLACE(
        @definition,
        N'BEGIN TRY',
        N'    IF @Deposito > 0 AND NULLIF(LTRIM(RTRIM(@NroOperacion)), '''') IS NULL' + CHAR(10) +
        N'    BEGIN' + CHAR(10) +
        N'        SELECT ''OPERACION_REQUERIDA'';' + CHAR(10) +
        N'        RETURN;' + CHAR(10) +
        N'    END' + CHAR(10) + CHAR(10) +
        N'    IF @NroOperacion <> '''' AND ISNULL(@EntidadBancaria, ''-'') <> ''-''' + CHAR(10) +
        N'       AND EXISTS (SELECT 1 FROM NotaPedido WHERE EntidadBancaria = @EntidadBancaria' + CHAR(10) +
        N'                       AND NroOperacion = @NroOperacion AND ISNULL(NotaEstado, '''') <> ''ANULADO'')' + CHAR(10) +
        N'    BEGIN' + CHAR(10) +
        N'        SELECT ''OPERACION'';' + CHAR(10) +
        N'        RETURN;' + CHAR(10) +
        N'    END' + CHAR(10) + CHAR(10) +
        N'    DECLARE @CajaId numeric(38);' + CHAR(10) +
        N'    SELECT TOP (1) @CajaId = CajaId FROM Caja' + CHAR(10) +
        N'     WHERE CajaEstado = ''ACTIVO'' AND UsuarioId = @UsuarioId' + CHAR(10) +
        N'     ORDER BY CajaId DESC;' + CHAR(10) +
        N'    IF ISNULL(@CajaId, 0) = 0' + CHAR(10) +
        N'    BEGIN' + CHAR(10) +
        N'        SELECT ''false'';' + CHAR(10) +
        N'        RETURN;' + CHAR(10) +
        N'    END' + CHAR(10) + CHAR(10) +
        N'BEGIN TRY');

    SET @definition = REPLACE(
        @definition,
        N'@cod, @NotaGanancia, NULL, @NotaTransaccion, @ICBPER,',
        N'@cod, @NotaGanancia, @CajaId, @NotaTransaccion, @ICBPER,');
END;

IF CHARINDEX(N'@CajaId numeric(38)', @definition) = 0
   OR CHARINDEX(N'''OPERACION_REQUERIDA''', @definition) = 0
   OR CHARINDEX(N'@cod, @NotaGanancia, @CajaId, @NotaTransaccion', @definition) = 0
    THROW 50000, 'No se pudo aplicar la validacion de caja a uspinsertarNotaBweb.', 1;

SET @definition = STUFF(@definition, 1, LEN(N'CREATE PROCEDURE'), N'ALTER PROCEDURE');
EXEC sys.sp_executesql @definition;
GO

/* El procedimiento de edición ya es consumido por la web; se instala con la misma validación. */
CREATE OR ALTER PROCEDURE dbo.uspEditarNotaPedido
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @open int, @Cabecera varchar(max), @Detalle varchar(max);
    DECLARE @p1 int, @p2 int, @p3 int, @p4 int, @p5 int, @p6 int, @p7 int, @p8 int;

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

    IF @open = 0 OR @p1 = 0 OR @p2 = 0 OR @p3 = 0 OR @p4 = 0 OR @p5 = 0 OR @p6 = 0 OR @p7 = 0
    BEGIN
        SELECT 'FORMATO_INVALIDO';
        RETURN;
    END;

    DECLARE @NotaId numeric(38), @UsuarioId int;
    DECLARE @CajaId numeric(38);

    SET @NotaId = CONVERT(numeric(38), SUBSTRING(@Cabecera, 1, @p1 - 1));
    SET @UsuarioId = CONVERT(int, SUBSTRING(@Cabecera, @p7 + 1, @p8 - @p7 - 1));

    IF @NotaId IS NULL OR ISNULL(@UsuarioId, 0) <= 0
    BEGIN
        SELECT 'FORMATO_INVALIDO';
        RETURN;
    END;

    SELECT TOP (1) @CajaId = CajaId
      FROM Caja
     WHERE CajaEstado = 'ACTIVO' AND UsuarioId = @UsuarioId
     ORDER BY CajaId DESC;

    IF ISNULL(@CajaId, 0) = 0
    BEGIN
        SELECT 'false';
        RETURN;
    END;

    BEGIN TRANSACTION;

    UPDATE p
       SET ProductoCantidad = ProductoCantidad + (d.DetalleCantidad * ISNULL(NULLIF(d.ValorUM, 0), 1))
      FROM Producto p
      INNER JOIN DetallePedido d ON d.IdProducto = p.IdProducto
     WHERE d.NotaId = @NotaId;

    UPDATE NotaPedido
       SET NotaDocu = SUBSTRING(@Cabecera, @p1 + 1, @p2 - @p1 - 1),
           ClienteId = CONVERT(int, SUBSTRING(@Cabecera, @p2 + 1, @p3 - @p2 - 1)),
           NotaFecha = CONVERT(datetime, SUBSTRING(@Cabecera, @p3 + 1, @p4 - @p3 - 1)),
           NotaUsuario = SUBSTRING(@Cabecera, @p4 + 1, @p5 - @p4 - 1),
           NotaFormaPago = SUBSTRING(@Cabecera, @p5 + 1, @p6 - @p5 - 1),
           NotaCondicion = SUBSTRING(@Cabecera, @p6 + 1, @p7 - @p6 - 1),
           CajaId = @CajaId
     WHERE NotaId = @NotaId;

    DELETE FROM DetallePedido WHERE NotaId = @NotaId;

    DECLARE @fila varchar(max), @c1 int, @c2 int, @c3 int, @c4 int, @c5 int, @c6 int, @c7 int, @c8 int, @c9 int;
    DECLARE @IdProducto numeric(20), @Cantidad decimal(18,2), @ValorUM decimal(18,6);

    WHILE LEN(@Detalle) > 0
    BEGIN
        SET @c1 = CHARINDEX(';', @Detalle);
        IF @c1 = 0
        BEGIN
            SET @fila = @Detalle;
            SET @Detalle = '';
        END
        ELSE
        BEGIN
            SET @fila = SUBSTRING(@Detalle, 1, @c1 - 1);
            SET @Detalle = SUBSTRING(@Detalle, @c1 + 1, LEN(@Detalle));
        END;

        SET @c1 = CHARINDEX('|', @fila);
        SET @c2 = CHARINDEX('|', @fila, @c1 + 1);
        SET @c3 = CHARINDEX('|', @fila, @c2 + 1);
        SET @c4 = CHARINDEX('|', @fila, @c3 + 1);
        SET @c5 = CHARINDEX('|', @fila, @c4 + 1);
        SET @c6 = CHARINDEX('|', @fila, @c5 + 1);
        SET @c7 = CHARINDEX('|', @fila, @c6 + 1);
        SET @c8 = CHARINDEX('|', @fila, @c7 + 1);
        IF @c8 = 0 SET @c8 = LEN(@fila) + 1;
        SET @c9 = CHARINDEX('|', @fila, @c8 + 1);
        IF @c9 = 0 SET @c9 = LEN(@fila) + 1;

        SET @IdProducto = CONVERT(numeric(20), SUBSTRING(@fila, 1, @c1 - 1));
        SET @Cantidad = CONVERT(decimal(18,2), SUBSTRING(@fila, @c1 + 1, @c2 - @c1 - 1));
        SET @ValorUM = CONVERT(decimal(18,6), REPLACE(SUBSTRING(@fila, @c8 + 1, @c9 - @c8 - 1), ',', '.'));
        IF @ValorUM <= 0 SET @ValorUM = 1;

        INSERT INTO DetallePedido
            (NotaId, IdProducto, DetalleCantidad, DetalleUm, DetalleDescripcion, DetalleCosto, DetallePrecio, DetalleImporte, DetalleEstado, ValorUM)
        VALUES
            (@NotaId, @IdProducto, @Cantidad,
             SUBSTRING(@fila, @c2 + 1, @c3 - @c2 - 1),
             SUBSTRING(@fila, @c3 + 1, @c4 - @c3 - 1),
             CONVERT(decimal(18,2), SUBSTRING(@fila, @c4 + 1, @c5 - @c4 - 1)),
             CONVERT(decimal(18,2), SUBSTRING(@fila, @c5 + 1, @c6 - @c5 - 1)),
             CONVERT(decimal(18,2), SUBSTRING(@fila, @c6 + 1, @c7 - @c6 - 1)),
             SUBSTRING(@fila, @c7 + 1, @c8 - @c7 - 1), @ValorUM);

        UPDATE Producto
           SET ProductoCantidad = ProductoCantidad - (@Cantidad * @ValorUM)
         WHERE IdProducto = @IdProducto;
    END;

    COMMIT TRANSACTION;
    SELECT 'UPDATED';
END;
GO
