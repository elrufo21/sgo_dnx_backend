USE [DXN_CUSCO_D1508];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[listaNotaPedido]
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ISNULL((
        SELECT STUFF((
            SELECT NCHAR(172) +
                CONVERT(VARCHAR, n.NotaId) + '|' +
                ISNULL(n.NotaDocu, '') + '|' +
                CONVERT(VARCHAR, c.ClienteId) + '|' +
                ISNULL(c.ClienteRazon, '') + '|' +
                ISNULL(c.ClienteRuc, '') + '|' +
                ISNULL(c.ClienteDni, '') + '|' +
                ISNULL(c.ClienteDireccion, '') + '|' +
                ISNULL(c.ClienteTelefono, '') + '|' +
                ISNULL(c.ClienteCorreo, '') + '|' +
                ISNULL(c.ClienteEstado, '') + '|' +
                ISNULL(c.ClienteDespacho, '') + '|' +
                ISNULL(c.ClienteUsuario, '') + '|' +
                CONVERT(VARCHAR, c.ClienteFecha, 103) + '|' +
                CONVERT(VARCHAR, n.NotaFecha, 103) + '|' +
                ISNULL(n.NotaUsuario, '') + '|' +
                ISNULL(n.NotaFormaPago, '') + '|' +
                ISNULL(n.NotaCondicion, '') + '|' +
                CONVERT(VARCHAR, n.NotaFechaPago, 103) + '|' +
                ISNULL(n.NotaDireccion, '') + '|' +
                '' + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaSubtotal AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaMovilidad AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaDescuento AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaTotal AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaAcuenta AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaSaldo AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaAdicional AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaTarjeta AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaPagar AS MONEY), 1) + '|' +
                ISNULL(n.NotaEstado, '') + '|' +
                CONVERT(VARCHAR, n.CompaniaId) + '|' +
                ISNULL(n.NotaEntrega, '') + '|' +
                ISNULL(n.ModificadoPor, '') + '|' +
                ISNULL(n.FechaEdita, '') + '|' +
                ISNULL(n.NotaConcepto, '') + '|' +
                ISNULL(n.NotaSerie, '') + '|' +
                ISNULL(n.NotaNumero, '') + '|' +
                CONVERT(VARCHAR(50), CAST(n.NotaGanancia AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.ICBPER AS MONEY), 1) + '|' +
                ISNULL(CONVERT(VARCHAR, n.CajaId), '') + '|' +
                ISNULL(n.EntidadBancaria, '') + '|' +
                ISNULL(n.NroOperacion, '') + '|' +
                CONVERT(VARCHAR(50), CAST(n.Efectivo AS MONEY), 1) + '|' +
                CONVERT(VARCHAR(50), CAST(n.Deposito AS MONEY), 1) + '|' +
                ISNULL((
                    SELECT TOP (1) d.EstadoSunat
                    FROM DocumentoVenta d WITH (NOLOCK)
                    WHERE d.NotaId = n.NotaId
                      AND d.TipoCodigo IN ('01', '03')
                    ORDER BY d.DocuId DESC
                ), 'PENDIENTE') + '|' +
                ISNULL(c.ClienteCodigo, '')
            FROM NotaPedido n WITH (NOLOCK)
            LEFT JOIN Cliente c WITH (NOLOCK) ON c.ClienteId = n.ClienteId
            WHERE n.NotaFecha >= @FechaInicio
              AND n.NotaFecha < DATEADD(DAY, 1, @FechaFin)
            ORDER BY n.NotaId DESC
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')
    ), '~') AS Resultado;
END
GO
