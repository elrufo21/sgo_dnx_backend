SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.uspValidarArqueoCajaWEB
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FechaArqueo date = DATEADD(DAY, -1, CONVERT(date, GETDATE()));

    -- When yesterday is Sunday, the legacy rule checks the preceding Friday.
    IF DATEDIFF(DAY, CONVERT(date, '19000107', 112), @FechaArqueo) % 7 = 0
        SET @FechaArqueo = DATEADD(DAY, -2, @FechaArqueo);

    IF EXISTS
    (
        SELECT 1
          FROM dbo.ConteoMonedas
         WHERE FechaConteo >= @FechaArqueo
           AND FechaConteo < DATEADD(DAY, 1, @FechaArqueo)
    )
       OR EXISTS
    (
        SELECT 1
          FROM dbo.Feriados
         WHERE Fecha = @FechaArqueo
    )
    BEGIN
        SELECT 'true';
        RETURN;
    END;

    SELECT 'NO ARQUEO';
END;
GO
