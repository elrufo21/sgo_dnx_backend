SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.LDdocumentosweb
    @FechaInicio date,
    @FechaFin date
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Cabecera varchar(max) = 'Fecha|Documento|NroDoc|Cliente|RUC|DNI|SubTotal|IGV|ICBPER|Total|Usuario|Estado|Referencia|Codigo|Mensaje|Condicion|FormaPago|Entidad|NroOperacion|Efectivo|Deposito';
    DECLARE @Anchos varchar(max) = '85|90|110|250|80|80|115|115|90|115|150|150|110|0|0|0|0|0|0|0|0';
    DECLARE @Detalle varchar(max);

    IF @FechaInicio IS NULL OR @FechaFin IS NULL
    BEGIN
        SELECT @Cabecera + '¬' + @Anchos;
        RETURN;
    END;

    IF @FechaInicio > @FechaFin
    BEGIN
        DECLARE @FechaTemporal date = @FechaInicio;
        SET @FechaInicio = @FechaFin;
        SET @FechaFin = @FechaTemporal;
    END;

    SET @Detalle = (
        SELECT STUFF((
            SELECT '¬' + CONVERT(char(10), d.DocuEmision, 103) + '|'
                + ISNULL(d.DocuDocumento, '') + '|'
                + ISNULL(d.DocuSerie, '') + '-' + ISNULL(d.DocuNumero, '') + '|'
                + ISNULL(c.ClienteRazon, '') + '|' + ISNULL(c.ClienteRuc, '') + '|' + ISNULL(c.ClienteDni, '') + '|'
                + CASE WHEN ISNULL(d.TipoCodigo, '') = '07' THEN '-' ELSE '' END + CONVERT(varchar(50), CAST(ISNULL(d.DocuSubTotal, 0) AS money), 1) + '|'
                + CASE WHEN ISNULL(d.TipoCodigo, '') = '07' THEN '-' ELSE '' END + CONVERT(varchar(50), CAST(ISNULL(d.DocuIgv, 0) AS money), 1) + '|'
                + CASE WHEN ISNULL(d.TipoCodigo, '') = '07' THEN '-' ELSE '' END + CONVERT(varchar(50), CAST(ISNULL(d.ICBPER, 0) AS money), 1) + '|'
                + CASE WHEN ISNULL(d.TipoCodigo, '') = '07' THEN '-' ELSE '' END + CONVERT(varchar(50), CAST(ISNULL(d.DocuTotal, 0) AS money), 1) + '|'
                + ISNULL(d.DocuUsuario, '') + '|'
                + CASE
                    WHEN UPPER(LTRIM(RTRIM(ISNULL(n.NotaEstado, '')))) = 'ANULADO' THEN 'ANULADO'
                    ELSE ISNULL(d.DocuEstado, '')
                  END + '|'
                + ISNULL(d.DocuNroGuia, '') + '|' + ISNULL(d.CodigoSunat, '') + '|'
                + REPLACE(ISNULL(d.MensajeSunat, ''), '|', ' ') + '|' + ISNULL(d.DocuCondicion, '') + '|' + ISNULL(d.FormaPago, '') + '|'
                + ISNULL(d.EntidadBancaria, '') + '|' + ISNULL(d.NroOperacion, '') + '|'
                + CONVERT(varchar(50), CAST(ISNULL(d.Efectivo, 0) AS money), 1) + '|'
                + CONVERT(varchar(50), CAST(ISNULL(d.Deposito, 0) AS money), 1)
            FROM DocumentoVenta d
            INNER JOIN Cliente c ON c.ClienteId = d.ClienteId
            LEFT JOIN NotaPedido n ON n.NotaId = d.NotaId
            WHERE d.DocuEmision >= @FechaInicio
              AND d.DocuEmision < DATEADD(day, 1, @FechaFin)
              AND d.DocuDocumento <> 'PROFORMA V'
            ORDER BY d.DocuEmision, d.DocuSerie + '-' + d.DocuNumero
            FOR XML PATH('')
        ), 1, 1, '')
    );

    SELECT @Cabecera + '¬' + @Anchos
        + CASE WHEN NULLIF(LTRIM(RTRIM(@Detalle)), '') IS NULL THEN '' ELSE '¬' + @Detalle END;
END;
GO
