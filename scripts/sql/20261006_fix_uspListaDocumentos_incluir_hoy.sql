/*
   Incluye los documentos pendientes emitidos hoy en el resumen de boletas.
   Aplicar en la base de datos usada por el backend.
*/
CREATE OR ALTER PROCEDURE [dbo].[uspListaDocumentos]
    @Data varchar(max)
AS
BEGIN
    DECLARE @p1 int;
    DECLARE @CompaniaId int;
    DECLARE @fechaReferencia date;

    SET @Data = LTRIM(RTRIM(@Data));
    SET @CompaniaId = @Data;

    SET @fechaReferencia = (
        SELECT TOP 1 DocuEmision
        FROM DocumentoVenta
        WHERE TipoCodigo = '03'
          AND CompaniaId = @CompaniaId
          AND EstadoSunat = 'PENDIENTE'
          AND DocuEmision <= CONVERT(date, GETDATE())
        GROUP BY DocuEmision
        ORDER BY DocuEmision ASC
    );

    SELECT
        'DocuId|Compania|NotaId|FechaEmision|Documento|Numero|RazonSocial|DNI|SubTotal|IGV|ICBPER|Total|Usuario|Estado¬100|80|100|115|95|130|350|90|115|115|100|115|160|125¬String|String|String|String|String|String|String|String|String|String|String|String|String|String|String¬'
        + ISNULL((
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
                  AND d.EstadoSunat = 'PENDIENTE'
                  AND d.DocuEmision = @fechaReferencia
                ORDER BY d.DocuSerie, d.DocuNumero ASC
                FOR XML PATH('')
            ), 1, 1, '')
        ), '~');
END;
GO
