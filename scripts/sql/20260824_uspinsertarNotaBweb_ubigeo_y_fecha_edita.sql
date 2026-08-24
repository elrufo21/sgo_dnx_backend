/*
  Las nuevas notas guardan el ubigeo de la compania en NotaPedido.NotaDireccion
  y dejan FechaEdita como texto vacio hasta que exista una edicion real.

  Se conserva la direccion recibida para actualizar Cliente.ClienteDespacho.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @definition nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarNotaBweb'));

IF @definition IS NULL
BEGIN
    RAISERROR('No existe dbo.uspinsertarNotaBweb.', 16, 1);
    RETURN;
END;

IF CHARINDEX(N'DNX_NOTA_UBIGEO_COMPANIA', @definition) > 0
BEGIN
    PRINT 'dbo.uspinsertarNotaBweb ya contiene el guardado de ubigeo de compania.';
    RETURN;
END;

SET @definition = REPLACE(@definition, CHAR(13) + CHAR(10), CHAR(10));

IF CHARINDEX(N'@NotaDireccion varchar(max),', @definition) = 0
   OR CHARINDEX(N'BEGIN TRY', @definition) = 0
   OR CHARINDEX(N'DELETE FROM TemporalVenta', @definition) = 0
   OR CHARINDEX(N'SET @NotaId = SCOPE_IDENTITY();', @definition) = 0
BEGIN
    RAISERROR('La version actual de uspinsertarNotaBweb no coincide con la esperada. No se aplicaron cambios.', 16, 1);
    RETURN;
END;

SET @definition = REPLACE(
    @definition,
    N'@NotaDireccion varchar(max),',
    N'@NotaDireccion varchar(max), @CompaniaUbigeo varchar(10),');

SET @definition = REPLACE(
    @definition,
    N'BEGIN TRY',
    N'-- DNX_NOTA_UBIGEO_COMPANIA' + CHAR(10) +
    N'SELECT @CompaniaUbigeo = NULLIF(LTRIM(RTRIM(CompaniaCodigoUBG)), '''')' + CHAR(10) +
    N'FROM Compania' + CHAR(10) +
    N'WHERE CompaniaId = @CompaniaId;' + CHAR(10) +
    N'SET @CompaniaUbigeo = ISNULL(@CompaniaUbigeo, '''');' + CHAR(10) + CHAR(10) +
    N'BEGIN TRY');

SET @definition = REPLACE(
    @definition,
    N'DELETE FROM TemporalVenta',
    N'SET @NotaDireccion = @CompaniaUbigeo;' + CHAR(10) + CHAR(10) +
    N'DELETE FROM TemporalVenta');

SET @definition = REPLACE(
    @definition,
    N'SET @NotaId = SCOPE_IDENTITY();',
    N'SET @NotaId = SCOPE_IDENTITY();' + CHAR(10) +
    N'UPDATE NotaPedido SET FechaEdita = '''' WHERE NotaId = @NotaId;');

IF CHARINDEX(N'@CompaniaUbigeo varchar(10)', @definition) = 0
   OR CHARINDEX(N'SET @NotaDireccion = @CompaniaUbigeo;', @definition) = 0
   OR CHARINDEX(N'UPDATE NotaPedido SET FechaEdita = '''' WHERE NotaId = @NotaId;', @definition) = 0
BEGIN
    RAISERROR('No se pudo preparar la actualizacion de uspinsertarNotaBweb.', 16, 1);
    RETURN;
END;

SET @definition = STUFF(@definition, 1, LEN(N'CREATE PROCEDURE'), N'ALTER PROCEDURE');
EXEC sys.sp_executesql @definition;

IF CHARINDEX(N'DNX_NOTA_UBIGEO_COMPANIA', OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarNotaBweb'))) = 0
BEGIN
    RAISERROR('No se pudo validar la actualizacion de uspinsertarNotaBweb.', 16, 1);
    RETURN;
END;

PRINT 'dbo.uspinsertarNotaBweb actualizado correctamente.';
