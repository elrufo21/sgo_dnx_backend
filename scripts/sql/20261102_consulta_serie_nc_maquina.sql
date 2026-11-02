-- Referencia de solo lectura para la API. Sustituir los valores antes de consultar.
-- No crea objetos ni reserva un correlativo.
DECLARE @Maquina nvarchar(140) = N'NOMBRE-DE-LA-PC';
DECLARE @Serie nvarchar(4) = N'FB01';
DECLARE @CompaniaId int = 1;

SELECT COUNT(*) AS Cantidad, MIN(NULLIF(UPPER(LTRIM(RTRIM(SerieNC))), '')) AS SerieNC
FROM dbo.MAQUINAS
WHERE UPPER(LTRIM(RTRIM(Maquina))) = UPPER(@Maquina);

SELECT ISNULL(MAX(CONVERT(INT, CASE
    WHEN LEN(RTRIM(ISNULL(DocuNumero, ''))) >= 8
     AND RIGHT(ISNULL(DocuNumero, ''), 8) NOT LIKE '%[^0-9]%'
    THEN RIGHT(DocuNumero, 8) ELSE '0' END)), 0) AS UltimoCorrelativo
FROM dbo.DocumentoVenta
WHERE TipoCodigo = '07' AND DocuDocumento = 'NOTA DE CREDITO'
  AND LTRIM(RTRIM(ISNULL(DocuSerie, ''))) = @Serie
  AND (@CompaniaId <= 0 OR CompaniaId = @CompaniaId);
