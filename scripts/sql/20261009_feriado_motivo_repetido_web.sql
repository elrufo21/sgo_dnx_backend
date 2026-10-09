SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_FeriadoWEB
    @Data VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @accion VARCHAR(20),
        @idFeriado INT,
        @fecha DATETIME,
        @motivo VARCHAR(250),
        @fechaTexto VARCHAR(20),
        @fechaNormalizada VARCHAR(20),
        @idTexto VARCHAR(20),
        @p1 INT,
        @p2 INT,
        @p3 INT;

    SET @Data = LTRIM(RTRIM(ISNULL(@Data, '')));

    IF @Data = ''
    BEGIN
        SELECT 'ERROR|No se enviaron datos.' AS Data;
        RETURN;
    END;

    SET @p1 = CHARINDEX('|', @Data);
    IF @p1 = 0
        SET @accion = UPPER(LTRIM(RTRIM(@Data)));
    ELSE
        SET @accion = UPPER(LTRIM(RTRIM(SUBSTRING(@Data, 1, @p1 - 1))));

    -- Listing and deletion keep the existing desktop behavior.
    IF @accion IN ('LISTAR', 'ELIMINAR')
    BEGIN
        EXEC dbo.usp_Feriado @Data = @Data;
        RETURN;
    END;

    IF @accion = 'CREAR'
    BEGIN
        IF @p1 = 0
        BEGIN
            SELECT 'ERROR|Formato incorrecto para crear.' AS Data;
            RETURN;
        END;

        SET @p2 = CHARINDEX('|', @Data, @p1 + 1);
        IF @p2 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar fecha y motivo.' AS Data;
            RETURN;
        END;

        SET @fechaTexto = LTRIM(RTRIM(SUBSTRING(@Data, @p1 + 1, @p2 - @p1 - 1)));
        SET @fechaNormalizada = REPLACE(@fechaTexto, '-', '');
        IF LEN(@fechaNormalizada) <> 8
           OR @fechaNormalizada LIKE '%[^0-9]%'
           OR ISDATE(@fechaNormalizada) = 0
        BEGIN
            SELECT 'ERROR|La fecha ingresada no es válida.' AS Data;
            RETURN;
        END;

        SET @fecha = CONVERT(DATETIME, @fechaNormalizada, 112);
        SET @motivo = LTRIM(RTRIM(SUBSTRING(@Data, @p2 + 1, LEN(@Data))));
        IF ISNULL(@motivo, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el motivo del feriado.' AS Data;
            RETURN;
        END;

        IF LEN(@motivo) > 250
        BEGIN
            SELECT 'ERROR|El motivo no puede superar los 250 caracteres.' AS Data;
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM dbo.Feriados WHERE DATEDIFF(DAY, Fecha, @fecha) = 0)
        BEGIN
            SELECT 'ERROR|Ya existe un feriado registrado en esa fecha.' AS Data;
            RETURN;
        END;

        BEGIN TRY
            INSERT INTO dbo.Feriados (Fecha, Motivo) VALUES (@fecha, @motivo);
            SET @idFeriado = SCOPE_IDENTITY();
            SELECT 'OK|' + CAST(@idFeriado AS VARCHAR(20)) + '|Feriado registrado correctamente.' AS Data;
        END TRY
        BEGIN CATCH
            SELECT 'ERROR|' + ERROR_MESSAGE() AS Data;
        END CATCH;
        RETURN;
    END;

    IF @accion = 'ACTUALIZAR'
    BEGIN
        IF @p1 = 0
        BEGIN
            SELECT 'ERROR|Formato incorrecto para actualizar.' AS Data;
            RETURN;
        END;

        SET @p2 = CHARINDEX('|', @Data, @p1 + 1);
        IF @p2 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar el ID del feriado.' AS Data;
            RETURN;
        END;

        SET @p3 = CHARINDEX('|', @Data, @p2 + 1);
        IF @p3 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar fecha y motivo.' AS Data;
            RETURN;
        END;

        SET @idTexto = LTRIM(RTRIM(SUBSTRING(@Data, @p1 + 1, @p2 - @p1 - 1)));
        IF ISNULL(@idTexto, '') = '' OR @idTexto LIKE '%[^0-9]%'
        BEGIN
            SELECT 'ERROR|El ID del feriado no es válido.' AS Data;
            RETURN;
        END;

        SET @idFeriado = CONVERT(INT, @idTexto);
        IF NOT EXISTS (SELECT 1 FROM dbo.Feriados WHERE IdFeriado = @idFeriado)
        BEGIN
            SELECT 'ERROR|El feriado que intenta actualizar no existe.' AS Data;
            RETURN;
        END;

        SET @fechaTexto = LTRIM(RTRIM(SUBSTRING(@Data, @p2 + 1, @p3 - @p2 - 1)));
        SET @fechaNormalizada = REPLACE(@fechaTexto, '-', '');
        IF LEN(@fechaNormalizada) <> 8
           OR @fechaNormalizada LIKE '%[^0-9]%'
           OR ISDATE(@fechaNormalizada) = 0
        BEGIN
            SELECT 'ERROR|La fecha ingresada no es válida.' AS Data;
            RETURN;
        END;

        SET @fecha = CONVERT(DATETIME, @fechaNormalizada, 112);
        SET @motivo = LTRIM(RTRIM(SUBSTRING(@Data, @p3 + 1, LEN(@Data))));
        IF ISNULL(@motivo, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el motivo del feriado.' AS Data;
            RETURN;
        END;

        IF LEN(@motivo) > 250
        BEGIN
            SELECT 'ERROR|El motivo no puede superar los 250 caracteres.' AS Data;
            RETURN;
        END;

        IF EXISTS
        (
            SELECT 1
              FROM dbo.Feriados
             WHERE DATEDIFF(DAY, Fecha, @fecha) = 0
               AND IdFeriado <> @idFeriado
        )
        BEGIN
            SELECT 'ERROR|Ya existe otro feriado registrado en esa fecha.' AS Data;
            RETURN;
        END;

        BEGIN TRY
            UPDATE dbo.Feriados
               SET Fecha = @fecha,
                   Motivo = @motivo
             WHERE IdFeriado = @idFeriado;

            SELECT 'OK|Feriado actualizado correctamente.' AS Data;
        END TRY
        BEGIN CATCH
            SELECT 'ERROR|' + ERROR_MESSAGE() AS Data;
        END CATCH;
        RETURN;
    END;

    SELECT 'ERROR|La acción ingresada no es válida.' AS Data;
END;
GO
