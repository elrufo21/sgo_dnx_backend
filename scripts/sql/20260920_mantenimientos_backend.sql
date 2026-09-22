/* Mantenimientos consumidos por el backend; extraídos de DXN_CUSCO_D2108. */
USE [DXN_ICA];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
GO

/* usp_Area */
CREATE OR ALTER PROCEDURE dbo.usp_Area
    @Data VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @accion      VARCHAR(20),
        @AreaId      INT,
        @AreaNombre  VARCHAR(150),
        @idTexto     VARCHAR(20),
        @p1          INT,
        @p2          INT;

    SET @Data = LTRIM(RTRIM(ISNULL(@Data, '')));


    -- =====================================================
    -- VALIDAR DATA
    -- =====================================================

    IF @Data = ''
    BEGIN
        SELECT 'ERROR|No se enviaron datos.' AS Data;
        RETURN;
    END;


    -- =====================================================
    -- OBTENER ACCION
    -- =====================================================

    SET @p1 = CHARINDEX('|', @Data);

    IF @p1 = 0
        SET @accion = UPPER(LTRIM(RTRIM(@Data)));
    ELSE
        SET @accion = UPPER(
            LTRIM(RTRIM(
                SUBSTRING(@Data, 1, @p1 - 1)
            ))
        );


    -- =====================================================
    -- LISTAR
    -- LISTAR
    -- =====================================================

    IF @accion = 'LISTAR'
    BEGIN

        SELECT
            CAST(AreaId AS VARCHAR(20)) + '|' +
            ISNULL(AreaNombre, '') AS Data
        FROM Area
        ORDER BY AreaNombre;

        RETURN;
    END;


    -- =====================================================
    -- CREAR
    -- CREAR|RECURSOS HUMANOS
    -- =====================================================

    IF @accion = 'CREAR'
    BEGIN

        IF @p1 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar el nombre del area.' AS Data;
            RETURN;
        END;


        -- OBTENER NOMBRE
        SET @AreaNombre = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                LEN(@Data)
            )
        ));


        -- VALIDAR NOMBRE VACIO
        IF ISNULL(@AreaNombre, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el nombre del area.' AS Data;
            RETURN;
        END;


        -- VALIDAR NOMBRE DUPLICADO
        IF EXISTS
        (
            SELECT 1
            FROM Area
            WHERE UPPER(LTRIM(RTRIM(AreaNombre)))
                = UPPER(LTRIM(RTRIM(@AreaNombre)))
        )
        BEGIN
            SELECT 'ERROR|Ya existe un area con ese nombre.' AS Data;
            RETURN;
        END;


        -- INSERTAR
        BEGIN TRY

            INSERT INTO Area
            (
                AreaNombre
            )
            VALUES
            (
                @AreaNombre
            );


            SET @AreaId = SCOPE_IDENTITY();


            SELECT
                'OK|' +
                CAST(@AreaId AS VARCHAR(20)) +
                '|Area registrada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE()
                AS Data;

        END CATCH;


        RETURN;
    END;


    -- =====================================================
    -- ACTUALIZAR
    -- ACTUALIZAR|3|VENTAS
    -- =====================================================

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
            SELECT 'ERROR|Debe ingresar el ID y el nombre del area.' AS Data;
            RETURN;
        END;


        -- OBTENER ID
        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                @p2 - @p1 - 1
            )
        ));


        -- VALIDAR ID
        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN
            SELECT 'ERROR|El ID del area no es valido.' AS Data;
            RETURN;
        END;


        SET @AreaId = CONVERT(INT, @idTexto);


        -- VALIDAR QUE EXISTA
        IF NOT EXISTS
        (
            SELECT 1
            FROM Area
            WHERE AreaId = @AreaId
        )
        BEGIN
            SELECT 'ERROR|El area que intenta actualizar no existe.' AS Data;
            RETURN;
        END;


        -- OBTENER NOMBRE
        SET @AreaNombre = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p2 + 1,
                LEN(@Data)
            )
        ));


        -- VALIDAR NOMBRE
        IF ISNULL(@AreaNombre, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el nombre del area.' AS Data;
            RETURN;
        END;


        -- VALIDAR NOMBRE DUPLICADO
        -- EXCLUYENDO EL REGISTRO ACTUAL
        IF EXISTS
        (
            SELECT 1
            FROM Area
            WHERE UPPER(LTRIM(RTRIM(AreaNombre)))
                = UPPER(LTRIM(RTRIM(@AreaNombre)))
              AND AreaId <> @AreaId
        )
        BEGIN
            SELECT 'ERROR|Ya existe otra area con ese nombre.' AS Data;
            RETURN;
        END;


        -- ACTUALIZAR
        BEGIN TRY

            UPDATE Area
            SET AreaNombre = @AreaNombre
            WHERE AreaId = @AreaId;


            SELECT
                'OK|Area actualizada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE()
                AS Data;

        END CATCH;


        RETURN;
    END;


    -- =====================================================
    -- ELIMINAR
    -- ELIMINAR|3
    -- =====================================================

    IF @accion = 'ELIMINAR'
    BEGIN

        IF @p1 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar el ID del area.' AS Data;
            RETURN;
        END;


        -- OBTENER ID
        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                LEN(@Data)
            )
        ));


        -- VALIDAR ID
        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN
            SELECT 'ERROR|El ID del area no es valido.' AS Data;
            RETURN;
        END;


        SET @AreaId = CONVERT(INT, @idTexto);


        -- VALIDAR QUE EXISTA
        IF NOT EXISTS
        (
            SELECT 1
            FROM Area
            WHERE AreaId = @AreaId
        )
        BEGIN
            SELECT 'ERROR|El area que intenta eliminar no existe.' AS Data;
            RETURN;
        END;


        -- ELIMINAR
        BEGIN TRY

            DELETE FROM Area
            WHERE AreaId = @AreaId;


            SELECT
                'OK|Area eliminada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            -- ERROR 547 = EXISTE UNA RELACION / FOREIGN KEY
            IF ERROR_NUMBER() = 547
            BEGIN

                SELECT
                    'ERROR|No se puede eliminar el area porque tiene registros relacionados.'
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


    -- =====================================================
    -- ACCION INVALIDA
    -- =====================================================

    SELECT
        'ERROR|La accion ingresada no es valida.'
        AS Data;

END;
GO

/* usp_Feriado */
CREATE OR ALTER PROCEDURE dbo.usp_Feriado
    @Data VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @accion            VARCHAR(20),
        @idFeriado         INT,
        @fecha             DATETIME,
        @motivo            VARCHAR(250),
        @fechaTexto        VARCHAR(20),
        @fechaNormalizada  VARCHAR(20),
        @idTexto           VARCHAR(20),
        @p1                INT,
        @p2                INT,
        @p3                INT;

    ---------------------------------------------------------
    -- LIMPIAR DATA
    ---------------------------------------------------------
    SET @Data = LTRIM(RTRIM(ISNULL(@Data, '')));

    IF @Data = ''
    BEGIN
        SELECT 'ERROR|No se enviaron datos.' AS Data;
        RETURN;
    END;


    ---------------------------------------------------------
    -- OBTENER ACCION
    ---------------------------------------------------------
    SET @p1 = CHARINDEX('|', @Data);

    IF @p1 = 0
        SET @accion = UPPER(LTRIM(RTRIM(@Data)));
    ELSE
        SET @accion = UPPER(
            LTRIM(RTRIM(
                SUBSTRING(@Data, 1, @p1 - 1)
            ))
        );



    -- LISTAR
    -- LISTAR

    IF @accion = 'LISTAR'
    BEGIN

        SELECT
            CAST(idFeriado AS VARCHAR(20)) + '|' +
            CONVERT(VARCHAR(10), fecha, 23) + '|' +
            ISNULL(motivo, '') AS Data
        FROM Feriados
        ORDER BY fecha ASC;

        RETURN;
    END;



    -- CREAR
    -- CREAR|2026-08-30|Santa Rosa de Lima

    IF @accion = 'CREAR'
    BEGIN

        -----------------------------------------------------
        -- VALIDAR ESTRUCTURA
        -----------------------------------------------------
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


        -----------------------------------------------------
        -- OBTENER FECHA
        -----------------------------------------------------
        SET @fechaTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                @p2 - @p1 - 1
            )
        ));

        -----------------------------------------------------
        -- NORMALIZAR FECHA
        -- Permite:
        -- 2026-08-30
        -- 20260830
        -----------------------------------------------------
        SET @fechaNormalizada = REPLACE(@fechaTexto, '-', '');


        -----------------------------------------------------
        -- VALIDAR FECHA
        -----------------------------------------------------
        IF LEN(@fechaNormalizada) <> 8
           OR @fechaNormalizada LIKE '%[^0-9]%'
           OR ISDATE(@fechaNormalizada) = 0
        BEGIN
            SELECT 'ERROR|La fecha ingresada no es válida.' AS Data;
            RETURN;
        END;

        SET @fecha = CONVERT(DATETIME, @fechaNormalizada, 112);


        -----------------------------------------------------
        -- OBTENER MOTIVO
        -----------------------------------------------------
        SET @motivo = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p2 + 1,
                LEN(@Data)
            )
        ));


        -----------------------------------------------------
        -- VALIDAR MOTIVO
        -----------------------------------------------------
        IF ISNULL(@motivo, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el motivo del feriado.' AS Data;
            RETURN;
        END;


        -----------------------------------------------------
        -- VALIDAR LONGITUD
        -----------------------------------------------------
        IF LEN(@motivo) > 250
        BEGIN
            SELECT 'ERROR|El motivo no puede superar los 250 caracteres.' AS Data;
            RETURN;
        END;


        -----------------------------------------------------
        -- VALIDAR FECHA DUPLICADA
        -----------------------------------------------------
        IF EXISTS
        (
            SELECT 1
            FROM Feriados
            WHERE DATEDIFF(DAY, fecha, @fecha) = 0
        )
        BEGIN
            SELECT 'ERROR|Ya existe un feriado registrado en esa fecha.' AS Data;
            RETURN;
        END;


        -----------------------------------------------------
        -- VALIDAR MOTIVO DUPLICADO
        -----------------------------------------------------
        IF EXISTS
        (
            SELECT 1
            FROM Feriados
            WHERE UPPER(LTRIM(RTRIM(motivo)))
                = UPPER(LTRIM(RTRIM(@motivo)))
        )
        BEGIN
            SELECT 'ERROR|Ya existe un feriado con el mismo motivo.' AS Data;
            RETURN;
        END;


        -----------------------------------------------------
        -- INSERTAR
        -----------------------------------------------------
        BEGIN TRY

            INSERT INTO Feriados
            (
                fecha,
                motivo
            )
            VALUES
            (
                @fecha,
                @motivo
            );

            SET @idFeriado = SCOPE_IDENTITY();

            SELECT
                'OK|' +
                CAST(@idFeriado AS VARCHAR(20)) +
                '|Feriado registrado correctamente.' AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE() AS Data;

        END CATCH;

        RETURN;
    END;



    -- ACTUALIZAR
    -- ACTUALIZAR|5|2026-08-30|Santa Rosa de Lima

    IF @accion = 'ACTUALIZAR'
    BEGIN

        -----------------------------------------------------
        -- VALIDAR ESTRUCTURA
        -----------------------------------------------------
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


        -----------------------------------------------------
        -- OBTENER ID
        -----------------------------------------------------
        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                @p2 - @p1 - 1
            )
        ));


        -----------------------------------------------------
        -- VALIDAR ID
        -----------------------------------------------------
        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN
            SELECT 'ERROR|El ID del feriado no es válido.' AS Data;
            RETURN;
        END;

        SET @idFeriado = CONVERT(INT, @idTexto);


        -----------------------------------------------------
        -- VALIDAR QUE EL FERIADO EXISTA
        -----------------------------------------------------
        IF NOT EXISTS
        (
            SELECT 1
            FROM Feriados
            WHERE idFeriado = @idFeriado
        )
        BEGIN
            SELECT 'ERROR|El feriado que intenta actualizar no existe.' AS Data;
            RETURN;
        END;


        -----------------------------------------------------
        -- OBTENER FECHA
        -----------------------------------------------------
        SET @fechaTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p2 + 1,
                @p3 - @p2 - 1
            )
        ));

        SET @fechaNormalizada = REPLACE(@fechaTexto, '-', '');


        -----------------------------------------------------
        -- VALIDAR FECHA
        -----------------------------------------------------
        IF LEN(@fechaNormalizada) <> 8
           OR @fechaNormalizada LIKE '%[^0-9]%'
           OR ISDATE(@fechaNormalizada) = 0
        BEGIN
            SELECT 'ERROR|La fecha ingresada no es válida.' AS Data;
            RETURN;
        END;

        SET @fecha = CONVERT(DATETIME, @fechaNormalizada, 112);


        -----------------------------------------------------
        -- OBTENER MOTIVO
        -----------------------------------------------------
        SET @motivo = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p3 + 1,
                LEN(@Data)
            )
        ));


        -----------------------------------------------------
        -- VALIDAR MOTIVO
        -----------------------------------------------------
        IF ISNULL(@motivo, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el motivo del feriado.' AS Data;
            RETURN;
        END;


        -----------------------------------------------------
        -- VALIDAR LONGITUD
        -----------------------------------------------------
        IF LEN(@motivo) > 250
        BEGIN
            SELECT 'ERROR|El motivo no puede superar los 250 caracteres.' AS Data;
            RETURN;
        END;


        -----------------------------------------------------
        -- VALIDAR FECHA DUPLICADA
        -- EXCLUYE AL MISMO REGISTRO
        -----------------------------------------------------
        IF EXISTS
        (
            SELECT 1
            FROM Feriados
            WHERE DATEDIFF(DAY, fecha, @fecha) = 0
              AND idFeriado <> @idFeriado
        )
        BEGIN
            SELECT 'ERROR|Ya existe otro feriado registrado en esa fecha.' AS Data;
            RETURN;
        END;


        -----------------------------------------------------
        -- VALIDAR MOTIVO DUPLICADO
        -- EXCLUYE AL MISMO REGISTRO
        -----------------------------------------------------
        IF EXISTS
        (
            SELECT 1
            FROM Feriados
            WHERE UPPER(LTRIM(RTRIM(motivo)))
                = UPPER(LTRIM(RTRIM(@motivo)))
              AND idFeriado <> @idFeriado
        )
        BEGIN
            SELECT 'ERROR|Ya existe otro feriado con el mismo motivo.' AS Data;
            RETURN;
        END;


        -----------------------------------------------------
        -- ACTUALIZAR
        -----------------------------------------------------
        BEGIN TRY

            UPDATE Feriados
            SET
                fecha  = @fecha,
                motivo = @motivo
            WHERE idFeriado = @idFeriado;


            SELECT
                'OK|Feriado actualizado correctamente.' AS Data;

        END TRY

        BEGIN CATCH

            SELECT
                'ERROR|' + ERROR_MESSAGE() AS Data;

        END CATCH;

        RETURN;
    END;



    -- ELIMINAR
    -- ELIMINAR|5

    IF @accion = 'ELIMINAR'
    BEGIN

        -----------------------------------------------------
        -- VALIDAR ESTRUCTURA
        -----------------------------------------------------
        IF @p1 = 0
        BEGIN
            SELECT 'ERROR|Debe ingresar el ID del feriado.' AS Data;
            RETURN;
        END;


        -----------------------------------------------------
        -- OBTENER ID
        -----------------------------------------------------
        SET @idTexto = LTRIM(RTRIM(
            SUBSTRING(
                @Data,
                @p1 + 1,
                LEN(@Data)
            )
        ));


        -----------------------------------------------------
        -- VALIDAR ID
        -----------------------------------------------------
        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN
            SELECT 'ERROR|El ID del feriado no es válido.' AS Data;
            RETURN;
        END;

        SET @idFeriado = CONVERT(INT, @idTexto);


        -----------------------------------------------------
        -- VALIDAR QUE EXISTA
        -----------------------------------------------------
        IF NOT EXISTS
        (
            SELECT 1
            FROM Feriados
            WHERE idFeriado = @idFeriado
        )
        BEGIN
            SELECT 'ERROR|El feriado que intenta eliminar no existe.' AS Data;
            RETURN;
        END;


        -----------------------------------------------------
        -- ELIMINAR
        -----------------------------------------------------
        BEGIN TRY

            DELETE FROM Feriados
            WHERE idFeriado = @idFeriado;

            SELECT
                'OK|Feriado eliminado correctamente.' AS Data;

        END TRY

        BEGIN CATCH

            -------------------------------------------------
            -- ERROR 547:
            -- EL REGISTRO TIENE RELACIONES / FOREIGN KEY
            -------------------------------------------------
            IF ERROR_NUMBER() = 547
            BEGIN

                SELECT
                    'ERROR|No se puede eliminar el feriado porque tiene registros relacionados.'
                    AS Data;

            END
            ELSE
            BEGIN

                SELECT
                    'ERROR|' + ERROR_MESSAGE() AS Data;

            END

        END CATCH;

        RETURN;
    END;



    -- ACCION NO VALIDA
    SELECT
        'ERROR|La acción ingresada no es válida.' AS Data;

END;
GO

/* usp_Maquina */
CREATE OR ALTER PROCEDURE dbo.usp_Maquina
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


    -- =====================================================
    -- VALIDAR DATA
    -- =====================================================

    IF @Data = ''
    BEGIN
        SELECT 'ERROR|No se enviaron datos.' AS Data;
        RETURN;
    END;


    -- =====================================================
    -- OBTENER ACCION
    -- =====================================================

    SET @p1 = CHARINDEX('|', @Data);

    IF @p1 = 0
        SET @accion = UPPER(LTRIM(RTRIM(@Data)));
    ELSE
        SET @accion = UPPER(
            LTRIM(RTRIM(
                SUBSTRING(@Data, 1, @p1 - 1)
            ))
        );


    -- =====================================================
    -- LISTAR
    -- LISTAR
    -- =====================================================

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


    -- =====================================================
    -- CREAR
    --
    -- CREAR|VENTAS-A|FA02|FN01|BA01|EPSON TM-T20III
    -- =====================================================

    IF @accion = 'CREAR'
    BEGIN

        -- Buscar separadores
        SET @p2 = CHARINDEX('|', @Data, @p1 + 1);
        SET @p3 = CHARINDEX('|', @Data, @p2 + 1);
        SET @p4 = CHARINDEX('|', @Data, @p3 + 1);
        SET @p5 = CHARINDEX('|', @Data, @p4 + 1);


        -- Validar estructura
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


        -- Obtener valores
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


        -- =================================================
        -- VALIDAR NOMBRE DE MAQUINA
        -- =================================================

        IF ISNULL(@Maquina, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar el nombre de la máquina.' AS Data;
            RETURN;
        END;


        -- =================================================
        -- VALIDAR MAQUINA DUPLICADA
        -- =================================================

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


        -- =================================================
        -- VALIDAR SERIE FACTURA DUPLICADA
        -- Solo valida si tiene valor
        -- =================================================

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


        -- =================================================
        -- VALIDAR SERIE NC DUPLICADA
        -- =================================================

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


        -- =================================================
        -- VALIDAR SERIE BOLETA DUPLICADA
        -- =================================================

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


        -- =================================================
        -- INSERTAR
        -- =================================================

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


    -- =====================================================
    -- ACTUALIZAR
    --
    -- ACTUALIZAR|2|VENTAS-A|FA02|FN01|BA01|EPSON TM-T20III
    -- =====================================================

    IF @accion = 'ACTUALIZAR'
    BEGIN

        SET @p2 = CHARINDEX('|', @Data, @p1 + 1);
        SET @p3 = CHARINDEX('|', @Data, @p2 + 1);
        SET @p4 = CHARINDEX('|', @Data, @p3 + 1);
        SET @p5 = CHARINDEX('|', @Data, @p4 + 1);
        SET @p6 = CHARINDEX('|', @Data, @p5 + 1);


        -- Validar estructura
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


        -- =================================================
        -- OBTENER ID
        -- =================================================

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


        -- =================================================
        -- VALIDAR QUE EXISTA
        -- =================================================

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


        -- =================================================
        -- OBTENER DATOS
        -- =================================================

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


        -- =================================================
        -- VALIDAR MAQUINA
        -- =================================================

        IF ISNULL(@Maquina, '') = ''
        BEGIN

            SELECT
                'ERROR|Debe ingresar el nombre de la máquina.'
                AS Data;

            RETURN;
        END;


        -- =================================================
        -- VALIDAR NOMBRE DUPLICADO
        -- Excluye el registro actual
        -- =================================================

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


        -- =================================================
        -- VALIDAR SERIE FACTURA
        -- =================================================

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


        -- =================================================
        -- VALIDAR SERIE NC
        -- =================================================

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


        -- =================================================
        -- VALIDAR SERIE BOLETA
        -- =================================================

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


        -- =================================================
        -- ACTUALIZAR
        -- =================================================

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


    -- =====================================================
    -- ELIMINAR
    --
    -- ELIMINAR|2
    -- =====================================================

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


        -- Validar ID
        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
        BEGIN

            SELECT
                'ERROR|El ID de la máquina no es válido.'
                AS Data;

            RETURN;
        END;


        SET @idMaquina = CONVERT(INT, @idTexto);


        -- =================================================
        -- VALIDAR EXISTENCIA
        -- =================================================

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


        -- =================================================
        -- ELIMINAR
        -- =================================================

        BEGIN TRY

            DELETE FROM MAQUINAS
            WHERE IdMaquina = @idMaquina;


            SELECT
                'OK|Máquina eliminada correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            -- Foreign Key / registro relacionado
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


    -- =====================================================
    -- ACCION NO VALIDA
    -- =====================================================

    SELECT
        'ERROR|La acción ingresada no es válida.'
        AS Data;

END;
GO

/* usp_Personal */
CREATE OR ALTER PROCEDURE dbo.usp_Personal
    @Data VARCHAR(MAX),
    @Huella VARBINARY(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @accion                VARCHAR(20),
        @PersonalId            NUMERIC(20,0),
        @PersonalNombres       VARCHAR(140),
        @PersonalApellidos     VARCHAR(140),
        @AreaId                NUMERIC(20,0),
        @PersonalCodigo        VARCHAR(80),
        @PersonalNacimiento    DATE,
        @PersonalIngreso       VARCHAR(20),
        @PersonalDNI           VARCHAR(20),
        @PersonalDireccion     VARCHAR(140),
        @PersonalTelefono      VARCHAR(40),
        @PersonalTelefonoAsi   VARCHAR(40),
        @PersonalEmail         VARCHAR(100),
        @PersonalSueldo        DECIMAL(18,2),
        @PersonalEstado        VARCHAR(60),
        @PersonalBajaFecha     VARCHAR(60),
        @PersonalRuc           VARCHAR(20),
        @PersonalImagen        VARCHAR(MAX),
        @CompaniaId            INT,

        @idTexto               VARCHAR(30),
        @areaTexto             VARCHAR(30),
        @companiaTexto         VARCHAR(30),
        @sueldoTexto           VARCHAR(50),
        @nacimientoTexto       VARCHAR(30),
        @fechaNormalizada      VARCHAR(20),

        @resto                 VARCHAR(MAX),
        @valor                 VARCHAR(MAX),
        @separador             INT,
        @posicion              INT,
        @cantidad              INT,
        @numeroCompania        NUMERIC(20,0);

    DECLARE @Partes TABLE
    (
        Posicion INT,
        Valor VARCHAR(MAX)
    );


    -- =====================================================
    -- VALIDAR DATA
    -- =====================================================

    SET @Data = LTRIM(RTRIM(ISNULL(@Data, '')));

    IF @Data = ''
    BEGIN
        SELECT 'ERROR|No se enviaron datos.' AS Data;
        RETURN;
    END;


    -- =====================================================
    -- SEPARAR @Data POR |
    -- Compatible con SQL Server antiguo
    -- =====================================================

    SET @resto = @Data;
    SET @posicion = 1;

    WHILE 1 = 1
    BEGIN

        SET @separador = CHARINDEX('|', @resto);

        IF @separador = 0
        BEGIN

            INSERT INTO @Partes
            (
                Posicion,
                Valor
            )
            VALUES
            (
                @posicion,
                @resto
            );

            BREAK;
        END;


        SET @valor = SUBSTRING(
            @resto,
            1,
            @separador - 1
        );


        INSERT INTO @Partes
        (
            Posicion,
            Valor
        )
        VALUES
        (
            @posicion,
            @valor
        );


        SET @resto = SUBSTRING(
            @resto,
            @separador + 1,
            LEN(@resto)
        );

        SET @posicion = @posicion + 1;

    END;


    SELECT @cantidad = COUNT(*)
    FROM @Partes;


    SELECT
        @accion = UPPER(LTRIM(RTRIM(Valor)))
    FROM @Partes
    WHERE Posicion = 1;


    -- =====================================================
    -- LISTAR
    -- =====================================================

    IF @accion = 'LISTAR'
    BEGIN

        SELECT
            CAST(PersonalId AS VARCHAR(30)) + '|' +
            ISNULL(PersonalNombres, '') + '|' +
            ISNULL(PersonalApellidos, '') + '|' +
            ISNULL(CAST(AreaId AS VARCHAR(30)), '') + '|' +
            ISNULL(PersonalCodigo, '') + '|' +
            ISNULL(CONVERT(VARCHAR(10), PersonalNacimiento, 23), '') + '|' +
            ISNULL(PersonalIngreso, '') + '|' +
            ISNULL(PersonalDNI, '') + '|' +
            ISNULL(PersonalDireccion, '') + '|' +
            ISNULL(PersonalTelefono, '') + '|' +
            ISNULL(PersonalTelefonoAsi, '') + '|' +
            ISNULL(PersonalEmail, '') + '|' +
            ISNULL(CAST(PersonalSueldo AS VARCHAR(50)), '') + '|' +
            ISNULL(PersonalEstado, '') + '|' +
            ISNULL(PersonalBajaFecha, '') + '|' +
            ISNULL(PersonalRuc, '') + '|' +
            ISNULL(PersonalImagen, '') + '|' +
            ISNULL(CAST(CompaniaId AS VARCHAR(20)), '') + '|' +
            CASE
                WHEN HUELLA IS NULL THEN '0'
                ELSE '1'
            END
            AS Data
        FROM Personal
        ORDER BY PersonalApellidos, PersonalNombres;

        RETURN;
    END;


    -- =====================================================
    -- CREAR
    --
    -- Posiciones:
    --
    -- CREAR
    -- |Nombres
    -- |Apellidos
    -- |AreaId
    -- |Codigo
    -- |Nacimiento
    -- |Ingreso
    -- |DNI
    -- |Direccion
    -- |Telefono
    -- |TelefonoAsi
    -- |Email
    -- |Sueldo
    -- |Estado
    -- |BajaFecha
    -- |Ruc
    -- |Imagen
    -- |CompaniaId
    -- =====================================================

    IF @accion = 'CREAR'
    BEGIN

        SELECT @PersonalNombres =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 2;

        SELECT @PersonalApellidos =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 3;

        SELECT @areaTexto =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 4;

        SELECT @PersonalCodigo =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 5;

        SELECT @nacimientoTexto =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 6;

        SELECT @PersonalIngreso =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 7;

        SELECT @PersonalDNI =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 8;

        SELECT @PersonalDireccion =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 9;

        SELECT @PersonalTelefono =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 10;

        SELECT @PersonalTelefonoAsi =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 11;

        SELECT @PersonalEmail =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 12;

        SELECT @sueldoTexto =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 13;

        SELECT @PersonalEstado =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 14;

        SELECT @PersonalBajaFecha =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 15;

        SELECT @PersonalRuc =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 16;

        SELECT @PersonalImagen =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 17;

        SELECT @companiaTexto =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 18;


        -- =================================================
        -- VALIDAR NOMBRES
        -- =================================================

        IF ISNULL(@PersonalNombres, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar los nombres del personal.' AS Data;
            RETURN;
        END;


        IF ISNULL(@PersonalApellidos, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar los apellidos del personal.' AS Data;
            RETURN;
        END;


        -- =================================================
        -- AREA
        -- =================================================

        IF ISNULL(@areaTexto, '') <> ''
        BEGIN

            IF @areaTexto LIKE '%[^0-9]%'
               OR LEN(@areaTexto) > 20
            BEGIN
                SELECT 'ERROR|El AreaId no es valido.' AS Data;
                RETURN;
            END;


            SET @AreaId = CONVERT(NUMERIC(20,0), @areaTexto);


            IF NOT EXISTS
            (
                SELECT 1
                FROM Area
                WHERE AreaId = @AreaId
            )
            BEGIN
                SELECT 'ERROR|El area seleccionada no existe.' AS Data;
                RETURN;
            END;

        END
        ELSE
        BEGIN
            SET @AreaId = NULL;
        END;


        -- =================================================
        -- FECHA DE NACIMIENTO
        -- =================================================

        IF ISNULL(@nacimientoTexto, '') <> ''
        BEGIN

            SET @fechaNormalizada =
                REPLACE(@nacimientoTexto, '-', '');


            IF LEN(@fechaNormalizada) <> 8
               OR @fechaNormalizada LIKE '%[^0-9]%'
               OR ISDATE(@fechaNormalizada) = 0
            BEGIN
                SELECT 'ERROR|La fecha de nacimiento no es valida.' AS Data;
                RETURN;
            END;


            SET @PersonalNacimiento =
                CONVERT(DATE, @fechaNormalizada, 112);

        END
        ELSE
        BEGIN
            SET @PersonalNacimiento = NULL;
        END;


        -- =================================================
        -- SUELDO
        -- =================================================

        IF ISNULL(@sueldoTexto, '') <> ''
        BEGIN

            IF ISNUMERIC(@sueldoTexto) = 0
            BEGIN
                SELECT 'ERROR|El sueldo ingresado no es valido.' AS Data;
                RETURN;
            END;


            BEGIN TRY

                SET @PersonalSueldo =
                    CONVERT(DECIMAL(18,2), @sueldoTexto);

            END TRY
            BEGIN CATCH

                SELECT 'ERROR|El sueldo ingresado no es valido.' AS Data;
                RETURN;

            END CATCH;

        END
        ELSE
        BEGIN
            SET @PersonalSueldo = NULL;
        END;


        -- =================================================
        -- COMPANIA
        -- =================================================

        IF ISNULL(@companiaTexto, '') <> ''
        BEGIN

            IF @companiaTexto LIKE '%[^0-9]%'
            BEGIN
                SELECT 'ERROR|El CompaniaId no es valido.' AS Data;
                RETURN;
            END;


            SET @numeroCompania =
                CONVERT(NUMERIC(20,0), @companiaTexto);


            IF @numeroCompania > 2147483647
            BEGIN
                SELECT 'ERROR|El CompaniaId no es valido.' AS Data;
                RETURN;
            END;


            SET @CompaniaId =
                CONVERT(INT, @numeroCompania);

        END
        ELSE
        BEGIN
            SET @CompaniaId = NULL;
        END;


        -- =================================================
        -- CODIGO DUPLICADO
        -- =================================================

        IF ISNULL(@PersonalCodigo, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE UPPER(LTRIM(RTRIM(PersonalCodigo)))
                    = UPPER(LTRIM(RTRIM(@PersonalCodigo)))
            )
            BEGIN
                SELECT 'ERROR|Ya existe un personal con el mismo codigo.' AS Data;
                RETURN;
            END;

        END;


        -- =================================================
        -- DNI DUPLICADO
        -- =================================================

        IF ISNULL(@PersonalDNI, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE LTRIM(RTRIM(PersonalDNI))
                    = LTRIM(RTRIM(@PersonalDNI))
            )
            BEGIN
                SELECT 'ERROR|Ya existe un personal con el mismo DNI.' AS Data;
                RETURN;
            END;

        END;


        -- =================================================
        -- EMAIL DUPLICADO
        -- =================================================

        IF ISNULL(@PersonalEmail, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE UPPER(LTRIM(RTRIM(PersonalEmail)))
                    = UPPER(LTRIM(RTRIM(@PersonalEmail)))
            )
            BEGIN
                SELECT 'ERROR|Ya existe un personal con el mismo correo.' AS Data;
                RETURN;
            END;

        END;


        -- =================================================
        -- RUC DUPLICADO
        -- =================================================

        IF ISNULL(@PersonalRuc, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE LTRIM(RTRIM(PersonalRuc))
                    = LTRIM(RTRIM(@PersonalRuc))
            )
            BEGIN
                SELECT 'ERROR|Ya existe un personal con el mismo RUC.' AS Data;
                RETURN;
            END;

        END;


        -- =================================================
        -- INSERTAR
        -- =================================================

        BEGIN TRY

            INSERT INTO Personal
            (
                PersonalNombres,
                PersonalApellidos,
                AreaId,
                PersonalCodigo,
                PersonalNacimiento,
                PersonalIngreso,
                PersonalDNI,
                PersonalDireccion,
                PersonalTelefono,
                PersonalTelefonoAsi,
                PersonalEmail,
                PersonalSueldo,
                PersonalEstado,
                PersonalBajaFecha,
                PersonalRuc,
                PersonalImagen,
                CompaniaId,
                HUELLA
            )
            VALUES
            (
                @PersonalNombres,
                @PersonalApellidos,
                @AreaId,
                NULLIF(@PersonalCodigo, ''),
                @PersonalNacimiento,
                NULLIF(@PersonalIngreso, ''),
                NULLIF(@PersonalDNI, ''),
                NULLIF(@PersonalDireccion, ''),
                NULLIF(@PersonalTelefono, ''),
                NULLIF(@PersonalTelefonoAsi, ''),
                NULLIF(@PersonalEmail, ''),
                @PersonalSueldo,
                NULLIF(@PersonalEstado, ''),
                NULLIF(@PersonalBajaFecha, ''),
                NULLIF(@PersonalRuc, ''),
                NULLIF(@PersonalImagen, ''),
                @CompaniaId,
                @Huella
            );


            SET @PersonalId = SCOPE_IDENTITY();


            SELECT
                'OK|' +
                CAST(@PersonalId AS VARCHAR(30)) +
                '|Personal registrado correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            IF ERROR_NUMBER() = 547
            BEGIN
                SELECT
                    'ERROR|No se pudo registrar. Verifique las relaciones de AreaId o CompaniaId.'
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


    -- =====================================================
    -- ACTUALIZAR
    --
    -- ACTUALIZAR|PersonalId|Nombres|Apellidos|AreaId|
    -- Codigo|Nacimiento|Ingreso|DNI|Direccion|Telefono|
    -- TelefonoAsi|Email|Sueldo|Estado|BajaFecha|Ruc|
    -- Imagen|CompaniaId
    -- =====================================================

    IF @accion = 'ACTUALIZAR'
    BEGIN

        SELECT @idTexto =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 2;


        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
           OR LEN(@idTexto) > 20
        BEGIN
            SELECT 'ERROR|El PersonalId no es valido.' AS Data;
            RETURN;
        END;


        SET @PersonalId =
            CONVERT(NUMERIC(20,0), @idTexto);


        IF NOT EXISTS
        (
            SELECT 1
            FROM Personal
            WHERE PersonalId = @PersonalId
        )
        BEGIN
            SELECT 'ERROR|El personal que intenta actualizar no existe.' AS Data;
            RETURN;
        END;


        SELECT @PersonalNombres = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 3;

        SELECT @PersonalApellidos = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 4;

        SELECT @areaTexto = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 5;

        SELECT @PersonalCodigo = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 6;

        SELECT @nacimientoTexto = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 7;

        SELECT @PersonalIngreso = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 8;

        SELECT @PersonalDNI = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 9;

        SELECT @PersonalDireccion = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 10;

        SELECT @PersonalTelefono = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 11;

        SELECT @PersonalTelefonoAsi = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 12;

        SELECT @PersonalEmail = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 13;

        SELECT @sueldoTexto = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 14;

        SELECT @PersonalEstado = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 15;

        SELECT @PersonalBajaFecha = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 16;

        SELECT @PersonalRuc = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 17;

        SELECT @PersonalImagen = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 18;

        SELECT @companiaTexto = LTRIM(RTRIM(Valor))
        FROM @Partes WHERE Posicion = 19;


        -- NOMBRES
        IF ISNULL(@PersonalNombres, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar los nombres del personal.' AS Data;
            RETURN;
        END;


        -- APELLIDOS
        IF ISNULL(@PersonalApellidos, '') = ''
        BEGIN
            SELECT 'ERROR|Debe ingresar los apellidos del personal.' AS Data;
            RETURN;
        END;


        -- AREA
        IF ISNULL(@areaTexto, '') <> ''
        BEGIN

            IF @areaTexto LIKE '%[^0-9]%'
               OR LEN(@areaTexto) > 20
            BEGIN
                SELECT 'ERROR|El AreaId no es valido.' AS Data;
                RETURN;
            END;


            SET @AreaId =
                CONVERT(NUMERIC(20,0), @areaTexto);


            IF NOT EXISTS
            (
                SELECT 1
                FROM Area
                WHERE AreaId = @AreaId
            )
            BEGIN
                SELECT 'ERROR|El area seleccionada no existe.' AS Data;
                RETURN;
            END;

        END
        ELSE
        BEGIN
            SET @AreaId = NULL;
        END;


        -- NACIMIENTO
        IF ISNULL(@nacimientoTexto, '') <> ''
        BEGIN

            SET @fechaNormalizada =
                REPLACE(@nacimientoTexto, '-', '');


            IF LEN(@fechaNormalizada) <> 8
               OR @fechaNormalizada LIKE '%[^0-9]%'
               OR ISDATE(@fechaNormalizada) = 0
            BEGIN
                SELECT 'ERROR|La fecha de nacimiento no es valida.' AS Data;
                RETURN;
            END;


            SET @PersonalNacimiento =
                CONVERT(DATE, @fechaNormalizada, 112);

        END
        ELSE
        BEGIN
            SET @PersonalNacimiento = NULL;
        END;


        -- SUELDO
        IF ISNULL(@sueldoTexto, '') <> ''
        BEGIN

            IF ISNUMERIC(@sueldoTexto) = 0
            BEGIN
                SELECT 'ERROR|El sueldo ingresado no es valido.' AS Data;
                RETURN;
            END;


            BEGIN TRY

                SET @PersonalSueldo =
                    CONVERT(DECIMAL(18,2), @sueldoTexto);

            END TRY
            BEGIN CATCH

                SELECT 'ERROR|El sueldo ingresado no es valido.' AS Data;
                RETURN;

            END CATCH;

        END
        ELSE
        BEGIN
            SET @PersonalSueldo = NULL;
        END;


        -- COMPANIA
        IF ISNULL(@companiaTexto, '') <> ''
        BEGIN

            IF @companiaTexto LIKE '%[^0-9]%'
            BEGIN
                SELECT 'ERROR|El CompaniaId no es valido.' AS Data;
                RETURN;
            END;


            SET @numeroCompania =
                CONVERT(NUMERIC(20,0), @companiaTexto);


            IF @numeroCompania > 2147483647
            BEGIN
                SELECT 'ERROR|El CompaniaId no es valido.' AS Data;
                RETURN;
            END;


            SET @CompaniaId =
                CONVERT(INT, @numeroCompania);

        END
        ELSE
        BEGIN
            SET @CompaniaId = NULL;
        END;


        -- CODIGO DUPLICADO
        IF ISNULL(@PersonalCodigo, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE UPPER(LTRIM(RTRIM(PersonalCodigo)))
                    = UPPER(LTRIM(RTRIM(@PersonalCodigo)))
                  AND PersonalId <> @PersonalId
            )
            BEGIN
                SELECT 'ERROR|Ya existe otro personal con el mismo codigo.' AS Data;
                RETURN;
            END;

        END;


        -- DNI DUPLICADO
        IF ISNULL(@PersonalDNI, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE LTRIM(RTRIM(PersonalDNI))
                    = LTRIM(RTRIM(@PersonalDNI))
                  AND PersonalId <> @PersonalId
            )
            BEGIN
                SELECT 'ERROR|Ya existe otro personal con el mismo DNI.' AS Data;
                RETURN;
            END;

        END;


        -- EMAIL DUPLICADO
        IF ISNULL(@PersonalEmail, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE UPPER(LTRIM(RTRIM(PersonalEmail)))
                    = UPPER(LTRIM(RTRIM(@PersonalEmail)))
                  AND PersonalId <> @PersonalId
            )
            BEGIN
                SELECT 'ERROR|Ya existe otro personal con el mismo correo.' AS Data;
                RETURN;
            END;

        END;


        -- RUC DUPLICADO
        IF ISNULL(@PersonalRuc, '') <> ''
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM Personal
                WHERE LTRIM(RTRIM(PersonalRuc))
                    = LTRIM(RTRIM(@PersonalRuc))
                  AND PersonalId <> @PersonalId
            )
            BEGIN
                SELECT 'ERROR|Ya existe otro personal con el mismo RUC.' AS Data;
                RETURN;
            END;

        END;


        -- ACTUALIZAR
        BEGIN TRY

            UPDATE Personal
            SET
                PersonalNombres     = @PersonalNombres,
                PersonalApellidos   = @PersonalApellidos,
                AreaId              = @AreaId,
                PersonalCodigo      = NULLIF(@PersonalCodigo, ''),
                PersonalNacimiento  = @PersonalNacimiento,
                PersonalIngreso     = NULLIF(@PersonalIngreso, ''),
                PersonalDNI         = NULLIF(@PersonalDNI, ''),
                PersonalDireccion   = NULLIF(@PersonalDireccion, ''),
                PersonalTelefono    = NULLIF(@PersonalTelefono, ''),
                PersonalTelefonoAsi = NULLIF(@PersonalTelefonoAsi, ''),
                PersonalEmail       = NULLIF(@PersonalEmail, ''),
                PersonalSueldo      = @PersonalSueldo,
                PersonalEstado      = NULLIF(@PersonalEstado, ''),
                PersonalBajaFecha   = NULLIF(@PersonalBajaFecha, ''),
                PersonalRuc         = NULLIF(@PersonalRuc, ''),
                PersonalImagen      = NULLIF(@PersonalImagen, ''),
                CompaniaId          = @CompaniaId,
                HUELLA =
                    CASE
                        WHEN @Huella IS NULL THEN HUELLA
                        ELSE @Huella
                    END
            WHERE PersonalId = @PersonalId;


            SELECT
                'OK|Personal actualizado correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            IF ERROR_NUMBER() = 547
            BEGIN
                SELECT
                    'ERROR|No se pudo actualizar. Verifique las relaciones de AreaId o CompaniaId.'
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


    -- =====================================================
    -- ELIMINAR
    -- ELIMINAR|5
    -- =====================================================

    IF @accion = 'ELIMINAR'
    BEGIN

        SELECT @idTexto =
            LTRIM(RTRIM(Valor))
        FROM @Partes
        WHERE Posicion = 2;


        IF ISNULL(@idTexto, '') = ''
           OR @idTexto LIKE '%[^0-9]%'
           OR LEN(@idTexto) > 20
        BEGIN
            SELECT 'ERROR|El PersonalId no es valido.' AS Data;
            RETURN;
        END;


        SET @PersonalId =
            CONVERT(NUMERIC(20,0), @idTexto);


        IF NOT EXISTS
        (
            SELECT 1
            FROM Personal
            WHERE PersonalId = @PersonalId
        )
        BEGIN
            SELECT 'ERROR|El personal que intenta eliminar no existe.' AS Data;
            RETURN;
        END;


        BEGIN TRY

            DELETE FROM Personal
            WHERE PersonalId = @PersonalId;


            SELECT
                'OK|Personal eliminado correctamente.'
                AS Data;

        END TRY

        BEGIN CATCH

            IF ERROR_NUMBER() = 547
            BEGIN
                SELECT
                    'ERROR|No se puede eliminar el personal porque tiene registros relacionados.'
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


    -- =====================================================
    -- ACCION INVALIDA
    -- =====================================================

    SELECT
        'ERROR|La accion ingresada no es valida.'
        AS Data;

END;
GO

/* usp_Usuario */

-- ============================================================
-- usp_Usuario
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_Usuario  
    @Data VARCHAR(MAX),  
    @UsuarioClave VARBINARY(500) = NULL  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    DECLARE  
        @accion                    VARCHAR(20),  
        @UsuarioID                 INT,  
        @PersonalId                NUMERIC(20,0),  
        @UsuarioAlias              VARCHAR(60),  
        @UsuarioEstado             VARCHAR(40),  
        @UsuarioSerie              VARCHAR(4),  
        @EnviaBoleta               BIT,  
        @EnviarFactura             BIT,  
        @EnviaNC                   BIT,  
        @EnviaND                   BIT,  
        @UserRuta                  VARCHAR(MAX),  
        @UserRutaOBS               VARCHAR(MAX),  
        @Administrador             BIT,  
        @RutaVentaOBS              VARCHAR(MAX),  
        @RutaIOC                   VARCHAR(MAX),  
        @RutaApertura              VARCHAR(MAX),  
        @FechaVencimientoClave     DATE,  
  
        @idTexto                   VARCHAR(30),  
        @personalTexto             VARCHAR(30),  
  
        @enviaBoletaTexto          VARCHAR(10),  
        @enviarFacturaTexto        VARCHAR(10),  
        @enviaNCTexto              VARCHAR(10),  
        @enviaNDTexto              VARCHAR(10),  
        @administradorTexto        VARCHAR(10),  
  
        @fechaTexto                VARCHAR(30),  
        @fechaNormalizada          VARCHAR(20),  
  
        @resto                     VARCHAR(MAX),  
        @valor                     VARCHAR(MAX),  
        @separador                 INT,  
        @posicion                  INT;  
  
  
    DECLARE @Partes TABLE  
    (  
        Posicion INT,  
        Valor VARCHAR(MAX)  
    );  
  
  
    -- =====================================================  
    -- VALIDAR DATA  
    -- =====================================================  
  
    SET @Data = LTRIM(RTRIM(ISNULL(@Data, '')));  
  
    IF @Data = ''  
    BEGIN  
        SELECT 'ERROR|No se enviaron datos.' AS Data;  
        RETURN;  
    END;  
  
  
    -- =====================================================  
    -- SEPARAR DATA POR |  
    -- =====================================================  
  
    SET @resto = @Data;  
    SET @posicion = 1;  
  
    WHILE 1 = 1  
    BEGIN  
  
        SET @separador = CHARINDEX('|', @resto);  
  
        IF @separador = 0  
        BEGIN  
  
            INSERT INTO @Partes  
            (  
                Posicion,  
                Valor  
            )  
            VALUES  
            (  
                @posicion,  
                @resto  
            );  
  
            BREAK;  
  
        END;  
  
  
        SET @valor =  
            SUBSTRING(  
                @resto,  
                1,  
                @separador - 1  
            );  
  
  
        INSERT INTO @Partes  
        (  
            Posicion,  
            Valor  
        )  
        VALUES  
        (  
            @posicion,  
            @valor  
        );  
  
  
        SET @resto =  
            SUBSTRING(  
                @resto,  
                @separador + 1,  
                LEN(@resto)  
            );  
  
  
        SET @posicion = @posicion + 1;  
  
    END;  
  
  
    SELECT  
        @accion = UPPER(LTRIM(RTRIM(Valor)))  
    FROM @Partes  
    WHERE Posicion = 1;  
  
  
    -- =====================================================  
    -- LISTAR  
    -- =====================================================  
  
    IF @accion = 'LISTAR'  
    BEGIN  
  
        SELECT  
            CAST(U.UsuarioID AS VARCHAR(20)) + '|' +  
            ISNULL(CAST(U.PersonalId AS VARCHAR(30)), '') + '|' +  
            ISNULL(U.UsuarioAlias, '') + '|' +  
            ISNULL(CONVERT(VARCHAR(23), U.UsuarioFechaReg, 121), '') + '|' +  
            ISNULL(U.UsuarioEstado, '') + '|' +  
            ISNULL(U.UsuarioSerie, '') + '|' +  
            CAST(ISNULL(U.EnviaBoleta, 0) AS VARCHAR(1)) + '|' +  
            CAST(ISNULL(U.EnviarFactura, 0) AS VARCHAR(1)) + '|' +  
            CAST(ISNULL(U.EnviaNC, 0) AS VARCHAR(1)) + '|' +  
            CAST(ISNULL(U.EnviaND, 0) AS VARCHAR(1)) + '|' +  
            ISNULL(U.UserRuta, '') + '|' +  
            ISNULL(U.UserRutaOBS, '') + '|' +  
            CAST(ISNULL(U.Administrador, 0) AS VARCHAR(1)) + '|' +  
            ISNULL(U.RutaVentaOBS, '') + '|' +  
            ISNULL(U.RutaIOC, '') + '|' +  
            ISNULL(U.RutaApertura, '') + '|' +  
            ISNULL(CONVERT(VARCHAR(10), U.FechaVencimientoClave, 23), '') + '|' +  
            CASE  
                WHEN U.UsuarioClave IS NULL THEN '0'  
                ELSE '1'  
            END  
            AS Data  
        FROM Usuarios U  
        ORDER BY U.UsuarioAlias;  
  
        RETURN;  
  
    END;  
  
  
    -- =====================================================  
    -- CREAR  
    --  
    -- CREAR  
    -- |PersonalId  
    -- |UsuarioAlias  
    -- |UsuarioEstado  
    -- |UsuarioSerie  
    -- |EnviaBoleta  
    -- |EnviarFactura  
    -- |EnviaNC  
    -- |EnviaND  
    -- |UserRuta  
    -- |UserRutaOBS  
    -- |Administrador  
    -- |RutaVentaOBS  
    -- |RutaIOC  
    -- |RutaApertura  
    -- |FechaVencimientoClave  
    -- =====================================================  
  
    IF @accion = 'CREAR'  
    BEGIN  
  
        SELECT @personalTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 2;  
  
        SELECT @UsuarioAlias =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 3;  
  
        SELECT @UsuarioEstado =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 4;  
  
        SELECT @UsuarioSerie =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 5;  
  
        SELECT @enviaBoletaTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 6;  
  
        SELECT @enviarFacturaTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 7;  
  
        SELECT @enviaNCTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 8;  
  
        SELECT @enviaNDTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 9;  
  
        SELECT @UserRuta =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 10;  
  
        SELECT @UserRutaOBS =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 11;  
  
        SELECT @administradorTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 12;  
  
        SELECT @RutaVentaOBS =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 13;  
  
        SELECT @RutaIOC =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 14;  
  
        SELECT @RutaApertura =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 15;  
  
        SELECT @fechaTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 16;  
  
  
        -- =================================================  
        -- VALIDAR PERSONAL  
        -- =================================================  
  
        IF ISNULL(@personalTexto, '') = ''  
        BEGIN  
            SELECT 'ERROR|Debe seleccionar un personal.' AS Data;  
            RETURN;  
        END;  
  
  
        IF @personalTexto LIKE '%[^0-9]%'  
           OR LEN(@personalTexto) > 20  
        BEGIN  
            SELECT 'ERROR|El PersonalId no es valido.' AS Data;  
            RETURN;  
        END;  
  
  
        SET @PersonalId =  
            CONVERT(NUMERIC(20,0), @personalTexto);  
  
  
        IF NOT EXISTS  
        (  
            SELECT 1  
            FROM Personal  
            WHERE PersonalId = @PersonalId  
        )  
        BEGIN  
            SELECT 'ERROR|El personal seleccionado no existe.' AS Data;  
            RETURN;  
        END;  
  
  
        -- =================================================  
        -- VALIDAR QUE EL PERSONAL NO TENGA OTRO USUARIO  
        -- =================================================  
  
        IF EXISTS  
(  
            SELECT 1  
            FROM Usuarios  
            WHERE PersonalId = @PersonalId  
        )  
        BEGIN  
            SELECT  
                'ERROR|El personal seleccionado ya tiene un usuario registrado.'  
                AS Data;  
            RETURN;  
        END;  
  
  
        -- =================================================  
        -- VALIDAR ALIAS  
        -- =================================================  
  
        IF ISNULL(@UsuarioAlias, '') = ''  
        BEGIN  
            SELECT 'ERROR|Debe ingresar el alias del usuario.' AS Data;  
            RETURN;  
        END;  
  
  
        IF LEN(@UsuarioAlias) > 60  
        BEGIN  
            SELECT 'ERROR|El alias no puede superar los 60 caracteres.' AS Data;  
            RETURN;  
        END;  
  
  
        IF EXISTS  
        (  
            SELECT 1  
            FROM Usuarios  
            WHERE UPPER(LTRIM(RTRIM(UsuarioAlias)))  
                = UPPER(LTRIM(RTRIM(@UsuarioAlias)))  
        )  
        BEGIN  
            SELECT 'ERROR|El alias ingresado ya existe.' AS Data;  
            RETURN;  
        END;  
  
  
        -- =================================================  
        -- ESTADO  
        -- =================================================  
  
        IF ISNULL(@UsuarioEstado, '') = ''  
            SET @UsuarioEstado = 'ACTIVO';  
  
  
        -- =================================================  
        -- SERIE  
        -- =================================================  
  
        IF LEN(ISNULL(@UsuarioSerie, '')) > 4  
        BEGIN  
            SELECT  
                'ERROR|La serie del usuario no puede superar los 4 caracteres.'  
                AS Data;  
            RETURN;  
        END;  
  
  
        -- =================================================  
        -- CAMPOS BIT  
        -- VACIO = 0  
        -- =================================================  
  
        IF ISNULL(@enviaBoletaTexto, '') = ''  
            SET @enviaBoletaTexto = '0';  
  
        IF ISNULL(@enviarFacturaTexto, '') = ''  
            SET @enviarFacturaTexto = '0';  
  
        IF ISNULL(@enviaNCTexto, '') = ''  
            SET @enviaNCTexto = '0';  
  
        IF ISNULL(@enviaNDTexto, '') = ''  
            SET @enviaNDTexto = '0';  
  
        IF ISNULL(@administradorTexto, '') = ''  
            SET @administradorTexto = '0';  
  
  
        -- EnviaBoleta  
        IF @enviaBoletaTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviaBoleta solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        -- EnviarFactura  
        IF @enviarFacturaTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviarFactura solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        -- EnviaNC  
        IF @enviaNCTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviaNC solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        -- EnviaND  
        IF @enviaNDTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviaND solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        -- Administrador  
        IF @administradorTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|Administrador solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        SET @EnviaBoleta =  
            CONVERT(BIT, @enviaBoletaTexto);  
  
        SET @EnviarFactura =  
            CONVERT(BIT, @enviarFacturaTexto);  
  
        SET @EnviaNC =  
            CONVERT(BIT, @enviaNCTexto);  
  
        SET @EnviaND =  
            CONVERT(BIT, @enviaNDTexto);  
  
        SET @Administrador =  
            CONVERT(BIT, @administradorTexto);  
  
  
        -- =================================================  
        -- FECHA VENCIMIENTO CLAVE  
        -- =================================================  
  
        IF ISNULL(@fechaTexto, '') <> ''  
        BEGIN  
  
            SET @fechaNormalizada =  
                REPLACE(@fechaTexto, '-', '');  
  
  
            IF LEN(@fechaNormalizada) <> 8  
               OR @fechaNormalizada LIKE '%[^0-9]%'  
               OR ISDATE(@fechaNormalizada) = 0  
            BEGIN  
                SELECT  
                    'ERROR|La fecha de vencimiento de clave no es valida.'  
                    AS Data;  
                RETURN;  
            END;  
  
  
            SET @FechaVencimientoClave =  
                CONVERT(DATE, @fechaNormalizada, 112);  
  
        END  
        ELSE  
        BEGIN  
  
            SET @FechaVencimientoClave = NULL;  
  
        END;  
  
  
        -- =================================================  
        -- INSERTAR  
        -- =================================================  
  
        BEGIN TRY  
  
            INSERT INTO Usuarios  
            (  
                PersonalId,  
                UsuarioAlias,  
                UsuarioClave,  
                UsuarioFechaReg,  
                UsuarioEstado,  
                UsuarioSerie,  
                EnviaBoleta,  
                EnviarFactura,  
                EnviaNC,  
                EnviaND,  
                UserRuta,  
                UserRutaOBS,  
                Administrador,  
                RutaVentaOBS,  
                RutaIOC,  
                RutaApertura,  
                FechaVencimientoClave  
            )  
            VALUES  
            (  
                @PersonalId,  
                @UsuarioAlias,  
                @UsuarioClave,  
                GETDATE(),  
                @UsuarioEstado,  
                NULLIF(@UsuarioSerie, ''),  
                @EnviaBoleta,  
                @EnviarFactura,  
                @EnviaNC,  
                @EnviaND,  
                NULLIF(@UserRuta, ''),  
                NULLIF(@UserRutaOBS, ''),  
                @Administrador,  
                NULLIF(@RutaVentaOBS, ''),  
                NULLIF(@RutaIOC, ''),  
                NULLIF(@RutaApertura, ''),  
                @FechaVencimientoClave  
            );  
  
  
            SET @UsuarioID = SCOPE_IDENTITY();  
  
  
            SELECT  
                'OK|' +  
                CAST(@UsuarioID AS VARCHAR(20)) +  
                '|Usuario registrado correctamente.'  
                AS Data;  
  
        END TRY  
  
        BEGIN CATCH  
  
            IF ERROR_NUMBER() = 547  
            BEGIN  
                SELECT  
                    'ERROR|No se pudo registrar el usuario porque existe una relacion invalida.'  
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
  
  
    -- =====================================================  
    -- ACTUALIZAR  
    --  
    -- ACTUALIZAR  
    -- |UsuarioID  
    -- |PersonalId  
    -- |UsuarioAlias  
    -- |UsuarioEstado  
    -- |UsuarioSerie  
    -- |EnviaBoleta  
    -- |EnviarFactura  
    -- |EnviaNC  
    -- |EnviaND  
    -- |UserRuta  
    -- |UserRutaOBS  
    -- |Administrador  
    -- |RutaVentaOBS  
    -- |RutaIOC  
    -- |RutaApertura  
    -- |FechaVencimientoClave  
    -- =====================================================  
  
    IF @accion = 'ACTUALIZAR'  
    BEGIN  
  
        SELECT @idTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 2;  
  
  
        IF ISNULL(@idTexto, '') = ''  
           OR @idTexto LIKE '%[^0-9]%'  
        BEGIN  
            SELECT 'ERROR|El UsuarioID no es valido.' AS Data;  
            RETURN;  
        END;  
  
  
        SET @UsuarioID =  
            CONVERT(INT, @idTexto);  
  
  
        IF NOT EXISTS  
        (  
            SELECT 1  
            FROM Usuarios  
            WHERE UsuarioID = @UsuarioID  
        )  
        BEGIN  
            SELECT  
                'ERROR|El usuario que intenta actualizar no existe.'  
                AS Data;  
            RETURN;  
        END;  
  
  
        SELECT @personalTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 3;  
  
      SELECT @UsuarioAlias =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 4;  
  
        SELECT @UsuarioEstado =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 5;  
  
        SELECT @UsuarioSerie =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 6;  
  
        SELECT @enviaBoletaTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 7;  
  
        SELECT @enviarFacturaTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 8;  
  
        SELECT @enviaNCTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 9;  
  
        SELECT @enviaNDTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 10;  
  
        SELECT @UserRuta =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 11;  
  
        SELECT @UserRutaOBS =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 12;  
  
        SELECT @administradorTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 13;  
  
        SELECT @RutaVentaOBS =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 14;  
  
        SELECT @RutaIOC =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 15;  
  
        SELECT @RutaApertura =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 16;  
  
        SELECT @fechaTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 17;  
  
  
        -- =================================================  
        -- PERSONAL  
        -- =================================================  
  
        IF ISNULL(@personalTexto, '') = ''  
        BEGIN  
            SELECT 'ERROR|Debe seleccionar un personal.' AS Data;  
            RETURN;  
        END;  
  
  
        IF @personalTexto LIKE '%[^0-9]%'  
           OR LEN(@personalTexto) > 20  
        BEGIN  
            SELECT 'ERROR|El PersonalId no es valido.' AS Data;  
            RETURN;  
        END;  
  
  
        SET @PersonalId =  
            CONVERT(NUMERIC(20,0), @personalTexto);  
  
  
        IF NOT EXISTS  
        (  
            SELECT 1  
            FROM Personal  
            WHERE PersonalId = @PersonalId  
        )  
        BEGIN  
            SELECT 'ERROR|El personal seleccionado no existe.' AS Data;  
            RETURN;  
        END;  
  
  
        -- Validar que otro usuario no tenga ese personal  
        IF EXISTS  
        (  
            SELECT 1  
            FROM Usuarios  
            WHERE PersonalId = @PersonalId  
              AND UsuarioID <> @UsuarioID  
        )  
        BEGIN  
            SELECT  
                'ERROR|El personal seleccionado ya pertenece a otro usuario.'  
                AS Data;  
            RETURN;  
        END;  
  
  
        -- =================================================  
        -- ALIAS  
        -- =================================================  
  
        IF ISNULL(@UsuarioAlias, '') = ''  
        BEGIN  
            SELECT 'ERROR|Debe ingresar el alias del usuario.' AS Data;  
            RETURN;  
        END;  
  
  
        IF EXISTS  
        (  
            SELECT 1  
            FROM Usuarios  
            WHERE UPPER(LTRIM(RTRIM(UsuarioAlias)))  
                = UPPER(LTRIM(RTRIM(@UsuarioAlias)))  
              AND UsuarioID <> @UsuarioID  
        )  
        BEGIN  
            SELECT  
                'ERROR|Ya existe otro usuario con el mismo alias.'  
                AS Data;  
            RETURN;  
        END;  
  
  
        -- =================================================  
        -- ESTADO  
        -- =================================================  
  
        IF ISNULL(@UsuarioEstado, '') = ''  
            SET @UsuarioEstado = 'ACTIVO';  
  
  
        -- =================================================  
        -- SERIE  
        -- =================================================  
  
        IF LEN(ISNULL(@UsuarioSerie, '')) > 4  
        BEGIN  
            SELECT  
                'ERROR|La serie del usuario no puede superar los 4 caracteres.'  
                AS Data;  
            RETURN;  
        END;  
  
  
        -- =================================================  
        -- BITS  
        -- =================================================  
  
        IF ISNULL(@enviaBoletaTexto, '') = ''  
            SET @enviaBoletaTexto = '0';  
  
        IF ISNULL(@enviarFacturaTexto, '') = ''  
            SET @enviarFacturaTexto = '0';  
  
        IF ISNULL(@enviaNCTexto, '') = ''  
            SET @enviaNCTexto = '0';  
  
        IF ISNULL(@enviaNDTexto, '') = ''  
            SET @enviaNDTexto = '0';  
  
        IF ISNULL(@administradorTexto, '') = ''  
            SET @administradorTexto = '0';  
  
  
        IF @enviaBoletaTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviaBoleta solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        IF @enviarFacturaTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviarFactura solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        IF @enviaNCTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviaNC solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        IF @enviaNDTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|EnviaND solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        IF @administradorTexto NOT IN ('0', '1')  
        BEGIN  
            SELECT 'ERROR|Administrador solo acepta 0 o 1.' AS Data;  
            RETURN;  
        END;  
  
  
        SET @EnviaBoleta =  
            CONVERT(BIT, @enviaBoletaTexto);  
  
        SET @EnviarFactura =  
            CONVERT(BIT, @enviarFacturaTexto);  
  
        SET @EnviaNC =  
            CONVERT(BIT, @enviaNCTexto);  
  
        SET @EnviaND =  
            CONVERT(BIT, @enviaNDTexto);  
  
        SET @Administrador =  
            CONVERT(BIT, @administradorTexto);  
  
  
        -- =================================================  
        -- FECHA VENCIMIENTO  
        -- =================================================  
  
        IF ISNULL(@fechaTexto, '') <> ''  
        BEGIN  
  
            SET @fechaNormalizada =  
                REPLACE(@fechaTexto, '-', '');  
  
  
            IF LEN(@fechaNormalizada) <> 8  
               OR @fechaNormalizada LIKE '%[^0-9]%'  
               OR ISDATE(@fechaNormalizada) = 0  
            BEGIN  
                SELECT  
                    'ERROR|La fecha de vencimiento de clave no es valida.'  
                    AS Data;  
                RETURN;  
            END;  
  
  
            SET @FechaVencimientoClave =  
                CONVERT(DATE, @fechaNormalizada, 112);  
  
        END  
        ELSE  
        BEGIN  
  
            SET @FechaVencimientoClave = NULL;  
  
        END;  
  
  
        -- =================================================  
        -- ACTUALIZAR  
        -- =================================================  
  
        BEGIN TRY  
  
            UPDATE Usuarios  
            SET  
                PersonalId            = @PersonalId,  
                UsuarioAlias          = @UsuarioAlias,  
  
                UsuarioClave =  
                    CASE  
                        WHEN @UsuarioClave IS NULL  
                            THEN UsuarioClave  
                        ELSE @UsuarioClave  
                    END,  
  
                UsuarioEstado         = @UsuarioEstado,  
                UsuarioSerie          = NULLIF(@UsuarioSerie, ''),  
                EnviaBoleta           = @EnviaBoleta,  
                EnviarFactura         = @EnviarFactura,  
                EnviaNC               = @EnviaNC,  
                EnviaND               = @EnviaND,  
                UserRuta              = NULLIF(@UserRuta, ''),  
                UserRutaOBS           = NULLIF(@UserRutaOBS, ''),  
                Administrador      = @Administrador,  
                RutaVentaOBS          = NULLIF(@RutaVentaOBS, ''),  
                RutaIOC               = NULLIF(@RutaIOC, ''),  
                RutaApertura          = NULLIF(@RutaApertura, ''),  
                FechaVencimientoClave = @FechaVencimientoClave  
  
            WHERE UsuarioID = @UsuarioID;  
  
  
            SELECT  
                'OK|Usuario actualizado correctamente.'  
                AS Data;  
  
        END TRY  
  
        BEGIN CATCH  
  
            IF ERROR_NUMBER() = 547  
            BEGIN  
                SELECT  
                    'ERROR|No se pudo actualizar el usuario porque existe una relacion invalida.'  
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
  
  
    -- =====================================================  
    -- ELIMINAR  
    -- ELIMINAR|5  
    -- =====================================================  
  
    IF @accion = 'ELIMINAR'  
    BEGIN  
  
        SELECT @idTexto =  
            LTRIM(RTRIM(Valor))  
        FROM @Partes  
        WHERE Posicion = 2;  
  
  
        IF ISNULL(@idTexto, '') = ''  
           OR @idTexto LIKE '%[^0-9]%'  
        BEGIN  
            SELECT 'ERROR|El UsuarioID no es valido.' AS Data;  
            RETURN;  
        END;  
  
  
        SET @UsuarioID =  
            CONVERT(INT, @idTexto);  
  
  
        IF NOT EXISTS  
        (  
            SELECT 1  
            FROM Usuarios  
            WHERE UsuarioID = @UsuarioID  
        )  
        BEGIN  
            SELECT  
                'ERROR|El usuario que intenta eliminar no existe.'  
                AS Data;  
            RETURN;  
        END;  
  
  
        BEGIN TRY  
  
            DELETE FROM Usuarios  
            WHERE UsuarioID = @UsuarioID;  
  
  
            SELECT  
                'OK|Usuario eliminado correctamente.'  
                AS Data;  
  
        END TRY  
  
        BEGIN CATCH  
  
            IF ERROR_NUMBER() = 547  
            BEGIN  
                SELECT  
                    'ERROR|No se puede eliminar el usuario porque tiene registros relacionados.'  
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
  
  
    -- =====================================================  
    -- ACCION INVALIDA  
    -- =====================================================  
  
    SELECT  
        'ERROR|La accion ingresada no es valida.'  
        AS Data;  
  
END;
GO



IF EXISTS
(
    SELECT 1
    FROM (VALUES ('usp_Area'),('usp_Feriado'),('usp_Maquina'),('usp_Personal'),('usp_Usuario')) p(Nombre)
    WHERE OBJECT_ID(N'dbo.'+p.Nombre,N'P') IS NULL
)
    THROW 51020,'No se crearon todos los procedimientos de mantenimiento.',1;

COMMIT TRANSACTION;

SELECT 'OK' Estado,5 ProcedimientosMantenimiento;
GO
