USE DXN_CUSCO_D1508;
GO

CREATE OR ALTER PROCEDURE dbo.uspValidaCantCajas
    @CajaId numeric(38, 0),
    @UsuarioId int
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM Caja WITH (UPDLOCK, HOLDLOCK)
        WHERE CajaEstado = 'ACTIVO'
          AND UsuarioId = @UsuarioId
          AND CajaId <> @CajaId
    )
    BEGIN
        SELECT 'USUARIO_ACTIVO';
        RETURN;
    END;

    IF (
        SELECT COUNT(*)
        FROM Caja WITH (UPDLOCK, HOLDLOCK)
        WHERE CajaEstado = 'ACTIVO'
          AND CajaId <> @CajaId
    ) >= 3
    BEGIN
        SELECT 'NO CERRO';
        RETURN;
    END;

    SELECT 'true';
END;
GO
