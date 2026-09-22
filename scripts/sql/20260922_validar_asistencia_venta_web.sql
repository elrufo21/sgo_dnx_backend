/*
  Bloquea ventas web si el usuario no tiene asistencia registrada hoy.
  Solo modifica dbo.uspinsertarNotaBweb; no cambia procedimientos de escritorio.
*/
USE [DXN_ICA];
GO
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

DECLARE @definition nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarNotaBweb'));
DECLARE @ancla nvarchar(max) = N'FROM @campos     WHERE Pos = 29;';
DECLARE @validacion nvarchar(max) = N'
    /* DNX_VALIDACION_ASISTENCIA */
    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Asistencia AS a
        INNER JOIN dbo.Usuarios AS u ON u.PersonalId = a.PersonalId
        WHERE u.UsuarioID = @UsuarioId
          AND a.Fecha = CONVERT(date, GETDATE())
    )
    BEGIN
        SELECT ''NO ASISTIO'';
        RETURN;
    END;';

IF @definition IS NULL
    THROW 51000, 'No existe dbo.uspinsertarNotaBweb.', 1;

IF CHARINDEX(N'DNX_VALIDACION_ASISTENCIA', @definition) = 0
BEGIN
    IF CHARINDEX(@ancla, @definition) = 0
        THROW 51000, 'No se reconoció el punto de inserción de UsuarioId en dbo.uspinsertarNotaBweb.', 1;

    SET @definition = REPLACE(@definition, @ancla, @ancla + @validacion);
    DECLARE @posicionProcedimiento int = CHARINDEX(N'PROCEDURE', @definition);
    IF @posicionProcedimiento = 0
        THROW 51000, 'No se reconoció la cabecera de dbo.uspinsertarNotaBweb.', 1;

    SET @definition = STUFF(@definition, 1, @posicionProcedimiento - 1, N'ALTER ');
    EXEC sys.sp_executesql @definition;
END;

COMMIT TRANSACTION;
SELECT N'OK: validación de asistencia aplicada a ventas web.' AS Resultado;
GO
