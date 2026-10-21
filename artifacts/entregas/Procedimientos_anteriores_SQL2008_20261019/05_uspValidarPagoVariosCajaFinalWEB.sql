SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.uspValidarPagoVariosCajaFinalWEB', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.uspValidarPagoVariosCajaFinalWEB AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.uspValidarPagoVariosCajaFinalWEB
@Fecha date
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
          FROM dbo.DocumentoVenta d
          INNER JOIN dbo.NotaPedido n ON n.NotaId = d.NotaId
         WHERE n.NotaCondicion = 'PAGO/VARIOS'
           AND n.NotaEstado <> 'CANCELADO'
           AND n.NotaEstado <> 'ANULADO'
           AND n.NotaFecha >= @Fecha
           AND n.NotaFecha < DATEADD(DAY, 1, @Fecha)
    )
    BEGIN
        SELECT 'PAGO/VARIOS';
        RETURN;
    END;

    SELECT 'true';
END;
GO
