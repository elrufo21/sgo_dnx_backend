/*
  Controla la validación de asistencia web con dbo.Indicador.
  Crea ASISTENCIA activado para las compañías existentes y actualiza
  dbo.uspinsertarNotaBweb para respetar el flag.
  Compatible con SQL Server 2008. Ejecutar en la base usada por la API.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.Indicador', N'U') IS NULL
BEGIN
    RAISERROR('No existe dbo.Indicador. Ejecute primero la configuración de Indicador.', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'dbo.uspinsertarNotaBweb', N'P') IS NULL
BEGIN
    RAISERROR('No existe dbo.uspinsertarNotaBweb.', 16, 1);
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    /* Valor inicial 1 conserva la validación que ya estaba vigente. */
    INSERT INTO dbo.Indicador
        (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
    SELECT c.CompaniaId,
           'CAJA',
           1,
           NULL,
           'ASISTENCIA',
           'Exigir asistencia en ventas y caja',
           1
    FROM dbo.Compania AS c
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Indicador AS i
        WHERE i.CompaniaId = c.CompaniaId
          AND i.Descripcion = 'ASISTENCIA'
    );

    DECLARE @definition nvarchar(max);
    DECLARE @ancla nvarchar(100);
    DECLARE @inicio int;
    DECLARE @fin int;
    DECLARE @posicionProcedimiento int;
    DECLARE @validacion nvarchar(max);

    SET @definition = OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarNotaBweb'));
    IF @definition IS NULL
    BEGIN
        RAISERROR('No se pudo leer la definición de dbo.uspinsertarNotaBweb.', 16, 1);
    END;

    IF CHARINDEX(N'DNX_VALIDACION_ASISTENCIA_FLAG', @definition) = 0
    BEGIN
        SET @inicio = CHARINDEX(N'/* DNX_VALIDACION_ASISTENCIA */', @definition);
        SET @validacion = N'/* DNX_VALIDACION_ASISTENCIA_FLAG */
    IF ISNULL
    (
        (
            SELECT CASE
                     WHEN MAX(CASE WHEN ISNULL(i.ValorNum, 1) <> 0 THEN 1 ELSE 0 END) = 0 THEN 0
                     ELSE 1
                   END
            FROM dbo.Usuarios AS u
            INNER JOIN dbo.Personal AS p ON p.PersonalId = u.PersonalId
            LEFT JOIN dbo.Indicador AS i
              ON i.CompaniaId = p.CompaniaId
             AND i.Descripcion = ''ASISTENCIA''
            WHERE u.UsuarioID = @UsuarioId
        ),
        1
    ) = 1
    AND NOT EXISTS
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

        IF @inicio > 0
        BEGIN
            SET @fin = CHARINDEX(N'SET @NotaEstado =', @definition, @inicio);
            IF @fin = 0
                RAISERROR('No se reconoció el final de la validación de asistencia. No se modificó el procedimiento.', 16, 1);

            SET @definition = STUFF
            (
                @definition,
                @inicio,
                @fin - @inicio,
                @validacion + CHAR(13) + CHAR(10) + N'    '
            );
        END
        ELSE
        BEGIN
            SET @ancla = N'FROM @campos     WHERE Pos = 29;';
            SET @inicio = CHARINDEX(@ancla, @definition);
            IF @inicio = 0
                RAISERROR('No se reconoció dónde se lee UsuarioId en uspinsertarNotaBweb. No se modificó el procedimiento.', 16, 1);

            SET @definition = STUFF
            (
                @definition,
                @inicio + LEN(@ancla),
                0,
                CHAR(13) + CHAR(10) + N'    ' + @validacion
            );
        END;

        SET @posicionProcedimiento = CHARINDEX(N'PROCEDURE', @definition);
        IF @posicionProcedimiento = 0
        BEGIN
            RAISERROR('No se reconoció la cabecera de dbo.uspinsertarNotaBweb.', 16, 1);
        END;

        SET @definition = STUFF(@definition, 1, @posicionProcedimiento - 1, N'ALTER ');
        EXEC sys.sp_executesql @definition;
    END;

    IF CHARINDEX
       (
           N'DNX_VALIDACION_ASISTENCIA_FLAG',
           OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspinsertarNotaBweb'))
       ) = 0
    BEGIN
        RAISERROR('No se pudo confirmar la actualización de dbo.uspinsertarNotaBweb.', 16, 1);
    END;

    COMMIT TRANSACTION;
    SELECT N'OK: flag ASISTENCIA configurado y validación web actualizada.' AS Resultado;
END TRY
BEGIN CATCH
    DECLARE @MensajeError nvarchar(4000);
    DECLARE @Severidad int;
    DECLARE @Estado int;

    SELECT @MensajeError = ERROR_MESSAGE(),
           @Severidad = ERROR_SEVERITY(),
           @Estado = ERROR_STATE();

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    RAISERROR(@MensajeError, @Severidad, @Estado);
END CATCH;
GO
