CREATE OR ALTER PROCEDURE dbo.uspAbrirCajaWEB
    @UsuarioId INT,
    @Encargado VARCHAR(100),
    @Usuario VARCHAR(100),
    @MontoInicial DECIMAL(18, 2),
    @Observacion VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRANSACTION;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.Caja WITH (UPDLOCK, HOLDLOCK)
        WHERE UsuarioId = @UsuarioId
          AND UPPER(LTRIM(RTRIM(ISNULL(CajaEstado, '')))) = 'ACTIVO'
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, 'El usuario ya tiene una caja abierta.', 1;
    END;

    DECLARE @CajaId numeric(38);

    INSERT INTO dbo.Caja
    (
        CajaFecha, CajaCierre, MontoIniSOl, CajaEncargado, CajaUsuario,
        CajaEstado, CajaIngresos, CajaDeposito, CajaSalidas, CajaTotal,
        UsuarioId, Observacion
    )
    VALUES
    (
        GETDATE(), '', @MontoInicial, @Encargado, @Usuario,
        'ACTIVO', 0, 0, 0, @MontoInicial,
        @UsuarioId, NULLIF(@Observacion, '')
    );

    SET @CajaId = SCOPE_IDENTITY();

    INSERT INTO dbo.CajaPincipal
        (CajaConcepto, CajaFecha, CajaId, CajaDescripcion, CajaMonto, CajaUsuario, IdGeneral, RutaImagen)
    VALUES
        ('SALIDA', GETDATE(), @CajaId, 'SENCILLO PARA LA CAJA NRO ' + CONVERT(varchar(38), @CajaId), @MontoInicial, @Usuario, 0, ''),
        ('INGRESO', GETDATE(), @CajaId, 'INGRESO DE CAJA CHICA', 0, @Usuario, 0, '');

    INSERT INTO dbo.Monedas (ConteoId, Efectivo, Billete, Monto, Concepto, CajaId)
    VALUES
        (0, 0, '200.00', 0, 'B', @CajaId),
        (0, 0, '100.00', 0, 'B', @CajaId),
        (0, 0, '50.00', 0, 'B', @CajaId),
        (0, 0, '20.00', 0, 'B', @CajaId),
        (0, 0, '10.00', 0, 'B', @CajaId),
        (0, 0, '5.00', 0, 'M', @CajaId),
        (0, 0, '2.00', 0, 'M', @CajaId),
        (0, 0, '1.00', 0, 'M', @CajaId),
        (0, 0, '0.50', 0, 'M', @CajaId),
        (0, 0, '0.20', 0, 'M', @CajaId),
        (0, 0, '0.10', 0, 'M', @CajaId);

    SELECT CONVERT(BIGINT, @CajaId) AS CajaId;

    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.uspListarCajaWEB
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CONVERT(BIGINT, CajaId) AS CajaId,
        CONVERT(VARCHAR(19), CajaFecha, 126) AS FechaApertura,
        ISNULL(CajaCierre, '') AS FechaCierre,
        ISNULL(MontoIniSOl, 0) AS MontoInicial,
        ISNULL(CajaEncargado, '') AS Encargado,
        ISNULL(CajaUsuario, '') AS Usuario,
        ISNULL(CajaEstado, '') AS Estado,
        ISNULL(Observacion, '') AS Observacion
    FROM dbo.Caja
    ORDER BY CajaId DESC;
END;
GO
