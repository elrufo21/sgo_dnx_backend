/*
  Sincronización puntual de DXN_CUSCO_D2108 desde DXN_CUSCO_D1508.
  Alcance validado el 2026-08-21:
  - dbo.DocumentoVentaCpeWeb: DocuId 5755 a 5800 (45 registros).
  - dbo.TABLAOBS: ID 6125 a 6466 (342 registros).
  - dbo.listaNotaPedido: incluye la hora en NotaFecha.

  El script es idempotente: no duplica registros ya existentes.
*/

USE [DXN_CUSCO_D2108];
GO

SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.DocumentoVentaCpeWeb (
        DocuId, ClienteRazon, ClienteRuc, ClienteDni, DireccionFiscal,
        DocuPdfUrl, DocuXmlUrl, DocuCdrUrl, DocuFechaPago, FechaRegistro
    )
    SELECT
        s.DocuId, s.ClienteRazon, s.ClienteRuc, s.ClienteDni, s.DireccionFiscal,
        s.DocuPdfUrl, s.DocuXmlUrl, s.DocuCdrUrl, s.DocuFechaPago, s.FechaRegistro
    FROM [DXN_CUSCO_D1508].dbo.DocumentoVentaCpeWeb AS s
    WHERE s.DocuId BETWEEN 5755 AND 5800
      AND NOT EXISTS (
          SELECT 1
          FROM dbo.DocumentoVentaCpeWeb AS t
          WHERE t.DocuId = s.DocuId
      );

    IF EXISTS (
        SELECT 1
        FROM [DXN_CUSCO_D1508].dbo.TABLAOBS AS s
        WHERE s.ID BETWEEN 6125 AND 6466
          AND NOT EXISTS (SELECT 1 FROM dbo.TABLAOBS AS t WHERE t.ID = s.ID)
    )
    BEGIN
        SET IDENTITY_INSERT dbo.TABLAOBS ON;

        INSERT INTO dbo.TABLAOBS (
            ID, FechaTransaccion, NotaTransaccion, CodigoMiembro,
            NombreMiembro, Importe, TipoVenta
        )
        SELECT
            s.ID, s.FechaTransaccion, s.NotaTransaccion, s.CodigoMiembro,
            s.NombreMiembro, s.Importe, s.TipoVenta
        FROM [DXN_CUSCO_D1508].dbo.TABLAOBS AS s
        WHERE s.ID BETWEEN 6125 AND 6466
          AND NOT EXISTS (SELECT 1 FROM dbo.TABLAOBS AS t WHERE t.ID = s.ID);

        SET IDENTITY_INSERT dbo.TABLAOBS OFF;
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET IDENTITY_INSERT dbo.TABLAOBS OFF;
    THROW;
END CATCH;
GO

ALTER PROCEDURE dbo.listaNotaPedido
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
                CONVERT(VARCHAR(10), n.NotaFecha, 103) + ' ' + CONVERT(VARCHAR(8), n.NotaFecha, 108) + '|' +
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
END;
GO

SELECT
    (SELECT COUNT(*) FROM dbo.DocumentoVentaCpeWeb WHERE DocuId BETWEEN 5755 AND 5800) AS DocumentoVentaCpeWeb_esperados_45,
    (SELECT COUNT(*) FROM dbo.TABLAOBS WHERE ID BETWEEN 6125 AND 6466) AS TABLAOBS_esperados_342;
GO
