USE [DXNCOMASWEB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE [dbo].[uspListaDocumentosWEB]
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompaniaId int;
    DECLARE @FechaReferencia date;
    DECLARE @CompaniaIdBigint bigint;

    SET @Data = LTRIM(RTRIM(@Data));
    SET @CompaniaId = NULL;

    IF @Data IS NOT NULL
       AND @Data <> ''
       AND LEN(@Data) <= 10
       AND @Data NOT LIKE '%[^0-9]%'
    BEGIN
        SET @CompaniaIdBigint = CONVERT(bigint, @Data);

        IF @CompaniaIdBigint <= 2147483647
            SET @CompaniaId = CONVERT(int, @CompaniaIdBigint);
    END;

    SET @FechaReferencia = (
        SELECT TOP (1) DocuEmision
        FROM dbo.DocumentoVenta
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
                    + '|' + CONVERT(varchar(50), CAST(ISNULL(d.ICBPER, 0) AS money), -1)
                    + '|' + CONVERT(varchar(50), CAST(d.DocuTotal AS money), -1)
                    + '|' + d.DocuUsuario
                    + '|' + d.EstadoSunat
                FROM dbo.DocumentoVenta d
                INNER JOIN dbo.Cliente c ON c.ClienteId = d.ClienteId
                WHERE d.TipoCodigo = '03'
                  AND d.CompaniaId = @CompaniaId
                  AND d.EstadoSunat = 'PENDIENTE'
                  AND d.DocuEmision = @FechaReferencia
                ORDER BY d.DocuSerie, d.DocuNumero ASC
                FOR XML PATH('')
            ), 1, 1, '')
        ), '~');
END;


GO

