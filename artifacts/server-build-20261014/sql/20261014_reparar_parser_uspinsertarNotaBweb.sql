/*
  Completa el parser de cabecera de dbo.uspinsertarNotaBweb.
  La versión afectada solo leía los campos 1-29, aunque la API envía los
  campos 30-44. En particular, NroOperacion llega en la posición 44.
  El script conserva el resto del procedimiento instalado y es idempotente.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Definicion nvarchar(max);
DECLARE @Ancla nvarchar(40);
DECLARE @Posicion int;
DECLARE @Mapeo nvarchar(max);
DECLARE @Indice int;
DECLARE @MarcadoresEncontrados int;

SET @Definicion = OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarNotaBweb'));

IF @Definicion IS NULL
BEGIN
    RAISERROR('No existe dbo.uspinsertarNotaBweb o no se puede leer su definición.', 16, 1);
    RETURN;
END;

SET @MarcadoresEncontrados = 0;
SET @Indice = 30;
WHILE @Indice <= 44
BEGIN
    IF CHARINDEX(N'WHERE Pos = ' + CONVERT(nvarchar(10), @Indice) + N';', @Definicion) > 0
        SET @MarcadoresEncontrados = @MarcadoresEncontrados + 1;

    SET @Indice = @Indice + 1;
END;

IF @MarcadoresEncontrados = 15
   AND CHARINDEX(N'@NroOperacion = Valor', @Definicion) > 0
BEGIN
    PRINT 'El parser de los campos 30-44 ya está instalado.';
    RETURN;
END;

IF @MarcadoresEncontrados <> 0
BEGIN
    RAISERROR('El parser de dbo.uspinsertarNotaBweb está parcialmente actualizado. No se modificó el procedimiento.', 16, 1);
    RETURN;
END;

SET @Ancla = N'WHERE Pos = 29;';
SET @Posicion = CHARINDEX(@Ancla, @Definicion);

IF @Posicion = 0
BEGIN
    RAISERROR('No se encontró el final del campo 29 en dbo.uspinsertarNotaBweb. No se modificó el procedimiento.', 16, 1);
    RETURN;
END;

SET @Mapeo =
    CHAR(13) + CHAR(10) +
    N'    SELECT @NotaTransaccion = Valor FROM @campos WHERE Pos = 30;' + CHAR(13) + CHAR(10) +
    N'    SELECT @Miembro = Valor FROM @campos WHERE Pos = 31;' + CHAR(13) + CHAR(10) +
    N'    SELECT @CodigoCliente = Valor FROM @campos WHERE Pos = 32;' + CHAR(13) + CHAR(10) +
    N'    SELECT @ICBPER = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''''), ''0'')) FROM @campos WHERE Pos = 33;' + CHAR(13) + CHAR(10) +
    N'    SELECT @DocuGravada = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''''), ''0'')) FROM @campos WHERE Pos = 34;' + CHAR(13) + CHAR(10) +
    N'    SELECT @ConceptoOBS = Valor FROM @campos WHERE Pos = 35;' + CHAR(13) + CHAR(10) +
    N'    SELECT @EstadoOBS = Valor FROM @campos WHERE Pos = 36;' + CHAR(13) + CHAR(10) +
    N'    SELECT @PV = Valor FROM @campos WHERE Pos = 37;' + CHAR(13) + CHAR(10) +
    N'    SELECT @Image = Valor FROM @campos WHERE Pos = 38;' + CHAR(13) + CHAR(10) +
    N'    SELECT @CodigoRes = Valor FROM @campos WHERE Pos = 39;' + CHAR(13) + CHAR(10) +
    N'    SELECT @Responsable = Valor FROM @campos WHERE Pos = 40;' + CHAR(13) + CHAR(10) +
    N'    SELECT @EntidadBancaria = Valor FROM @campos WHERE Pos = 41;' + CHAR(13) + CHAR(10) +
    N'    SELECT @Efectivo = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''''), ''0'')) FROM @campos WHERE Pos = 42;' + CHAR(13) + CHAR(10) +
    N'    SELECT @Deposito = CONVERT(decimal(18,2), ISNULL(NULLIF(Valor, ''''), ''0'')) FROM @campos WHERE Pos = 43;' + CHAR(13) + CHAR(10) +
    N'    SELECT @NroOperacion = Valor FROM @campos WHERE Pos = 44;' + CHAR(13) + CHAR(10);

SET @Definicion = STUFF(@Definicion, @Posicion + LEN(@Ancla), 0, @Mapeo);

IF UPPER(LEFT(@Definicion, LEN(N'CREATE PROCEDURE'))) <> N'CREATE PROCEDURE'
BEGIN
    RAISERROR('La definición de dbo.uspinsertarNotaBweb no inicia con CREATE PROCEDURE. No se modificó el procedimiento.', 16, 1);
    RETURN;
END;

SET @Definicion = STUFF(@Definicion, 1, LEN(N'CREATE PROCEDURE'), N'ALTER PROCEDURE');

BEGIN TRY
    BEGIN TRANSACTION;

    EXEC sys.sp_executesql @Definicion;

    SET @Definicion = OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarNotaBweb'));
    SET @MarcadoresEncontrados = 0;
    SET @Indice = 30;
    WHILE @Indice <= 44
    BEGIN
        IF CHARINDEX(N'WHERE Pos = ' + CONVERT(nvarchar(10), @Indice) + N';', @Definicion) > 0
            SET @MarcadoresEncontrados = @MarcadoresEncontrados + 1;

        SET @Indice = @Indice + 1;
    END;

    IF @MarcadoresEncontrados <> 15
       OR CHARINDEX(N'@NroOperacion = Valor', @Definicion) = 0
    BEGIN
        RAISERROR('La validación posterior del parser falló. Se revertirá el cambio.', 16, 1);
    END;

    COMMIT TRANSACTION;
    PRINT 'Parser de dbo.uspinsertarNotaBweb actualizado: campos 30-44.';
END TRY
BEGIN CATCH
    DECLARE @MensajeError nvarchar(4000);
    SET @MensajeError = ERROR_MESSAGE();

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    RAISERROR('%s', 16, 1, @MensajeError);
END CATCH;
