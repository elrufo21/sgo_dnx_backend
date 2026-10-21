USE [DXNCOMASWEB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE [dbo].[usp_Maquina]
    @Data VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @accion        VARCHAR(20),
        @idMaquina     INT,
        @idTexto       VARCHAR(20),
        @Maquina       VARCHAR(150),
        @SerieFactura  VARCHAR(50),
        @SerieNC       VARCHAR(50),
        @SerieBoleta   VARCHAR(50),
        @Tiketera      VARCHAR(250),
        @p1            INT,
        @p2            INT,
        @p3            INT,
        @p4            INT,
        @p5            INT,
        @p6            INT;


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
        SET @accion = UPPER(
            LTRIM(RTRIM(
                SUBSTRING(@Data, 1, @p1 - 1)
            ))
        );

    IF @accion = 'LISTAR'
    BEGIN

        SELECT
            CAST(IdMaquina AS VARCHAR(20)) + '|' +
            ISNULL(Maquina, '') + '|' +
            ISNULL(CONVERT(VARCHAR(23), Registro, 121), '') + '|' +
            ISNULL(SerieFactura, '') + '|' +
            ISNULL(SerieNC, '') + '|' +
            ISNULL(SerieBoleta, '') + '|' +
            ISNULL(Tiketera, '') AS Data
        FROM MAQUINAS
        ORDER BY Maquina;

        RETURN;
    END;

    IF @accion = 'CREAR'
    BEGIN
        SET @p2 = CHARINDEX('|', @Data, @p1 + 1);
        SET @p3 = CHARINDEX('|', @Data, @p2 + 1);
        SET @p4 = CHARINDEX('|', @Data, @p3 + 1);
        SET @p5 = CHARINDEX('|', @Data, @p4 + 1);
        IF @p1 = 0
           OR @p2 = 0
           OR @p3 = 0
           OR @p4 = 0
           OR @p5 = 0
        BEGIN
            SELECT
                'ERROR|Formato incorrecto. Use CREAR|Maquina|SerieFactura|SerieNC|SerieBoleta|Tiketera'
                AS Data;
            RETURN;
        END;
        SET @Maquina = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                @p2 - @p1 - 1
            )
        ));

        SET @SerieFactura = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p2 + 1,
                @p3 - @p2 - 1
            )
        ));

        SET @SerieNC = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p3 + 1,
                @p4 - @p3 - 1
            )
        ));

        SET @SerieBoleta = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p4 + 1,
                @p5 - @p4 - 1
            )
        ));

        SET @Tiketera = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p5 + 1,
                LEN(@Data)
            )
        ));

        IF ISNULL(@Maquina, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el nombre de la máquina.' AS Data;
            RETURN;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM MAQUINAS
            WHERE UPPER(LTRIM(RTRIM(Maquina)))
                = UPPER(LTRIM(RTRIM(@Maquina)))
        )
        BEGIN
            SELECT
                'ERROR|Ya existe una máquina registrada con ese nombre.'
                AS Data;
            RETURN;
        END;

        IF ISNULL(@SerieFactura, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM MAQUINAS
                WHERE UPPER(LTRIM(RTRIM(SerieFactura)))
                    = UPPER(LTRIM(RTRIM(@SerieFactura)))
            )
            BEGIN
                SELECT
                    'ERROR|La serie de factura ya está registrada en otra máquina.'
                    AS Data;
                RETURN;
            END;

        END;

        IF ISNULL(@SerieNC, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM MAQUINAS
                WHERE UPPER(LTRIM(RTRIM(SerieNC)))
                    = UPPER(LTRIM(RTRIM(@SerieNC)))
            )
            BEGIN
                SELECT
                    'ERROR|La serie de nota de crédito ya está registrada en otra máquina.'
                    AS Data;
                RETURN;
            END;

        END;

        IF ISNULL(@SerieBoleta, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM MAQUINAS
                WHERE UPPER(LTRIM(RTRIM(SerieBoleta)))
                    = UPPER(LTRIM(RTRIM(@SerieBoleta)))
            )
            BEGIN
                SELECT
                    'ERROR|La serie de boleta ya está registrada en otra máquina.'
                    AS Data;
                RETURN;
            END;

        END;

        BEGIN TRY

            INSERT INTO MAQUINAS
            (
                Maquina,
                Registro,
                SerieFactura,
                SerieNC,
                SerieBoleta,
                Tiketera
            )
            VALUES
            (
                @Maquina,
                GETDATE(),
                @SerieFactura,
                @SerieNC,
                @SerieBoleta,
                @Tiketera
            );


            SET @idMaquina = SCOPE_IDENTITY();


            SELECT
                'OK|' +
                CAST(@idMaquina AS VARCHAR(20)) +
                '|Máquina registrada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE()
                AS Data;

        END CATCH;


        RETURN;
    END;

    IF @accion = 'ACTUALIZAR'
    BEGIN

        SET @p2 = CHARINDEX('|', @Data, @p1 + 1);
        SET @p3 = CHARINDEX('|', @Data, @p2 + 1);
        SET @p4 = CHARINDEX('|', @Data, @p3 + 1);
        SET @p5 = CHARINDEX('|', @Data, @p4 + 1);
        SET @p6 = CHARINDEX('|', @Data, @p5 + 1);
        IF @p1 = 0
           OR @p2 = 0
           OR @p3 = 0
           OR @p4 = 0
           OR @p5 = 0
           OR @p6 = 0
        BEGIN

            SELECT
                'ERROR|Formato incorrecto. Use ACTUALIZAR|Id|Maquina|SerieFactura|SerieNC|SerieBoleta|Tiketera'
                AS Data;

            RETURN;
        END;

        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                @p2 - @p1 - 1
            )
        ));


        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN

            SELECT
                'ERROR|El ID de la máquina no es válido.'
                AS Data;

            RETURN;
        END;


        SET @idMaquina = CONVERT(INT, @idTexto);

        IF NOT EXISTS
        (
            SELECT 1
            FROM MAQUINAS
            WHERE IdMaquina = @idMaquina
        )
        BEGIN

            SELECT
                'ERROR|La máquina que intenta actualizar no existe.'
                AS Data;

            RETURN;
        END;

        SET @Maquina = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p2 + 1,
                @p3 - @p2 - 1
            )
        ));


        SET @SerieFactura = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p3 + 1,
                @p4 - @p3 - 1
            )
        ));


        SET @SerieNC = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p4 + 1,
                @p5 - @p4 - 1
            )
        ));


        SET @SerieBoleta = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p5 + 1,
                @p6 - @p5 - 1
            )
        ));


        SET @Tiketera = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p6 + 1,
                LEN(@Data)
            )
        ));

        IF ISNULL(@Maquina, '') = ''
        BEGIN

            SELECT
                'ERROR|Debe ingresar el nombre de la máquina.'
                AS Data;

            RETURN;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM MAQUINAS
            WHERE UPPER(LTRIM(RTRIM(Maquina)))
                = UPPER(LTRIM(RTRIM(@Maquina)))
              AND IdMaquina <> @idMaquina
        )
        BEGIN

            SELECT
                'ERROR|Ya existe otra máquina registrada con ese nombre.'
                AS Data;

            RETURN;
        END;

        IF ISNULL(@SerieFactura, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM MAQUINAS
                WHERE UPPER(LTRIM(RTRIM(SerieFactura)))
                    = UPPER(LTRIM(RTRIM(@SerieFactura)))
                  AND IdMaquina <> @idMaquina
            )
            BEGIN

                SELECT
                    'ERROR|La serie de factura pertenece a otra máquina.'
                    AS Data;

                RETURN;
            END;

        END;

        IF ISNULL(@SerieNC, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM MAQUINAS
                WHERE UPPER(LTRIM(RTRIM(SerieNC)))
                    = UPPER(LTRIM(RTRIM(@SerieNC)))
                  AND IdMaquina <> @idMaquina
            )
            BEGIN

                SELECT
                    'ERROR|La serie de nota de crédito pertenece a otra máquina.'
                    AS Data;

                RETURN;
            END;

        END;

        IF ISNULL(@SerieBoleta, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM MAQUINAS
                WHERE UPPER(LTRIM(RTRIM(SerieBoleta)))
                    = UPPER(LTRIM(RTRIM(@SerieBoleta)))
                  AND IdMaquina <> @idMaquina
            )
            BEGIN

                SELECT
                    'ERROR|La serie de boleta pertenece a otra máquina.'
                    AS Data;

                RETURN;
            END;

        END;

        BEGIN TRY

            UPDATE MAQUINAS
            SET
                Maquina      = @Maquina,
                SerieFactura = @SerieFactura,
                SerieNC      = @SerieNC,
                SerieBoleta  = @SerieBoleta,
                Tiketera     = @Tiketera
            WHERE IdMaquina = @idMaquina;


            SELECT
                'OK|Máquina actualizada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE()
                AS Data;

        END CATCH;


        RETURN;
    END;

    IF @accion = 'ELIMINAR'
    BEGIN

        IF @p1 = 0
        BEGIN

            SELECT
                'ERROR|Debe ingresar el ID de la máquina.'
                AS Data;

            RETURN;
        END;


        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                LEN(@Data)
            )
        ));
        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN

            SELECT
                'ERROR|El ID de la máquina no es válido.'
                AS Data;

            RETURN;
        END;


        SET @idMaquina = CONVERT(INT, @idTexto);

        IF NOT EXISTS
        (
            SELECT 1
            FROM MAQUINAS
            WHERE IdMaquina = @idMaquina
        )
        BEGIN

            SELECT
                'ERROR|La máquina que intenta eliminar no existe.'
                AS Data;

            RETURN;
        END;

        BEGIN TRY

            DELETE FROM MAQUINAS
            WHERE IdMaquina = @idMaquina;


            SELECT
                'OK|Máquina eliminada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH
            IF ERROR_NUMBER() = 547
            BEGIN

                SELECT
                    'ERROR|No se puede eliminar la máquina porque tiene registros relacionados.'
                    AS Data;

            END
            ELSE
            BEGIN

                SELECT
                    'ERROR|' + ERROR_MESSAGE()
                    AS Data;

            END

        END CATCH;


        RETURN;
    END;

    SELECT
        'ERROR|La acción ingresada no es válida.'
        AS Data;

END;


GO

