/*
   Evita mezclar boletas anuladas de distintas fechas de emisión en una baja.
   Devuelve la fecha pendiente más antigua; al actualizarse su estado SUNAT,
   la siguiente consulta devuelve la próxima fecha.
*/
CREATE OR ALTER PROCEDURE [dbo].[uspListaBajas]
    @Data varchar(max)
AS
BEGIN
    DECLARE @CompaniaId int;
    DECLARE @fechaReferencia date;

    SET @Data = LTRIM(RTRIM(@Data));
    SET @CompaniaId = @Data;

    SELECT @fechaReferencia = MIN(d.DocuEmision)
    FROM DocumentoVenta d
    WHERE d.TipoCodigo = '03'
      AND d.CompaniaId = @CompaniaId
      AND d.DocuEstado = 'ANULADO'
      AND d.EstadoSunat = 'ENVIADO';

    SELECT ISNULL((
        SELECT STUFF((
            SELECT
                '¬' + CONVERT(varchar, d.DocuId)
                + '|' + CONVERT(varchar, d.CompaniaId)
                + '|' + CONVERT(varchar, d.NotaId)
                + '|' + CONVERT(char(10), d.DocuEmision, 103)
                + '|' + d.DocuDocumento
                + '|' + d.DocuSerie + '-' + d.DocuNumero
                + '|' + c.ClienteRazon
                + '|' + c.ClienteDni
                + '|' + CONVERT(varchar(50), CAST(d.DocuSubTotal AS money), -1)
                + '|' + CONVERT(varchar(50), CAST(d.DocuIgv AS money), -1)
                + '|' + CONVERT(varchar(50), CAST(d.ICBPER AS money), -1)
                + '|' + CONVERT(varchar(50), CAST(d.DocuTotal AS money), -1)
                + '|' + d.DocuUsuario
                + '|' + d.EstadoSunat
            FROM DocumentoVenta d
            INNER JOIN Cliente c ON c.ClienteId = d.ClienteId
            WHERE d.TipoCodigo = '03'
              AND d.CompaniaId = @CompaniaId
              AND d.DocuEstado = 'ANULADO'
              AND d.EstadoSunat = 'ENVIADO'
              AND d.DocuEmision = @fechaReferencia
            ORDER BY d.DocuSerie, d.DocuNumero ASC
            FOR XML PATH('')
        ), 1, 1, '')
    ), '~');
END;
GO
