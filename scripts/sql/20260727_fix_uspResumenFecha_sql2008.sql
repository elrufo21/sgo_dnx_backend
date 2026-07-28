/*
    Corrige uspResumenFecha para SQL Server 2008 R2.
    - Acepta fechas ISO yyyy-MM-dd desde el frontend/API.
    - Compara columnas date contra date, no strings convertidos.
    - Incluye TieneCDR y CDRBase64 para consulta de tickets.

    Ejecutar:
    sqlcmd -S "localhost\SQLEXPSS_2008" -d "DXN_CUSCO_D2707" -E -i scripts\sql\20260727_fix_uspResumenFecha_sql2008.sql
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.uspResumenFecha', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspResumenFecha
GO

CREATE PROCEDURE dbo.uspResumenFecha
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @p1 int, @p2 int
    DECLARE @fechainicio date, @fechafin date
    DECLARE @sep char(1)
    SET @sep = CHAR(172)

    SET @Data = LTRIM(RTRIM(@Data))
    SET @p1 = CHARINDEX('|', @Data, 0)
    SET @p2 = LEN(@Data) + 1

    SET @fechainicio = CONVERT(date, SUBSTRING(@Data, 1, @p1 - 1), 120)
    SET @fechafin = CONVERT(date, SUBSTRING(@Data, @p1 + 1, @p2 - @p1 - 1), 120)

    SELECT
        'Id|Compania|FechaEmision|FechaEnvio|Serie|RangoNumeros|SubTotal|IGV|ICBPER|Total|Ticket|CDSunat|HASHCDR|Mensaje|Usuario|RUC|UserSol|ClaveSol|ESTADO|Intentos|TokenApi|IdToken|TieneCDR|CDRBase64'
        + @sep +
        '100|100|100|100|100|100|110|110|110|100|100|100|100|100|100|100|100|100|100|100|100|100|80|300'
        + @sep +
        'String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String|String'
        + @sep +
        ISNULL((
            SELECT STUFF((
                SELECT @sep + CONVERT(varchar, r.ResumenId) + '|' + CONVERT(varchar, r.CompaniaId) + '|' +
                       ISNULL(CONVERT(varchar, r.FechaReferencia, 103), '') + '|' +
                       ISNULL(CONVERT(varchar, r.FechaEnvio, 103), '') + ' ' + ISNULL(SUBSTRING(CONVERT(varchar, r.FechaEnvio, 114), 1, 8), '') + '|' +
                       ISNULL(r.ResumenSerie, '') + '-' + CONVERT(varchar, r.Secuencia) + '|' +
                       ISNULL(r.RangoNumero, '') + '|' +
                       CONVERT(varchar(50), CAST(r.SubTotal AS money), 1) + '|' +
                       CONVERT(varchar(50), CAST(r.IGV AS money), 1) + '|' +
                       CONVERT(varchar(50), CAST(r.ICBPER AS money), 1) + '|' +
                       CONVERT(varchar(50), CAST(r.Total AS money), 1) + '|' +
                       ISNULL(r.ResumenTiket, '') + '|' +
                       REPLACE(ISNULL(r.CodigoSunat, ''), '|', ' ') + '|' +
                       REPLACE(ISNULL(r.HASHCDR, ''), '|', ' ') + '|' +
                       REPLACE(ISNULL(r.MensajeSunat, ''), '|', ' ') + '|' +
                       REPLACE(ISNULL(r.Usuario, ''), '|', ' ') + '|' +
                       ISNULL(c.CompaniaRUC, '') + '|' +
                       ISNULL(c.CompaniaUserSecun, '') + '|' +
                       ISNULL(c.ComapaniaPWD, '') + '|' +
                       ISNULL(r.Estado, '') + '||' +
                       ISNULL(c.TokenApi, '') + '|' +
                       ISNULL(c.ClienIdToken, '') + '|' +
                       CASE WHEN ISNULL(r.CDRBase64, '') = '' THEN 'NO' ELSE 'SI' END + '|' +
                       REPLACE(ISNULL(r.CDRBase64, ''), '|', ' ')
                FROM dbo.ResumenBoletas r
                INNER JOIN dbo.Compania c ON c.CompaniaId = r.CompaniaId
                WHERE r.FechaReferencia BETWEEN @fechainicio AND @fechafin
                ORDER BY r.CompaniaId, r.FechaEnvio ASC
                FOR XML PATH('')
            ), 1, 1, '')
        ), '~')
END
GO

PRINT 'Verificacion uspResumenFecha'
GO

EXEC dbo.uspResumenFecha @Data = '2026-03-01|2026-07-27'
GO
