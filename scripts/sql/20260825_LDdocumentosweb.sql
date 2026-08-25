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
    END

    IF @FechaInicio > @FechaFin
    BEGIN
        DECLARE @FechaTemporal date = @FechaInicio;
        SET @FechaInicio = @FechaFin;
        SET @FechaFin = @FechaTemporal;
    END

    SET @Detalle = (
        SELECT STUFF((
            SELECT '¬' + CONVERT(char(10), d.DocuEmision, 103) + '|'
                + d.DocuDocumento + '|'
                + CONVERT(varchar, d.DocuSerie + '-' + d.DocuNumero) + '|'
                + c.ClienteRazon + '|' + ISNULL(c.ClienteRuc, '') + '|' + ISNULL(c.ClienteDni, '') + '|'
                + CASE WHEN d.TipoCodigo = '07' THEN '-' ELSE '' END + CONVERT(varchar(50), CAST(d.DocuSubTotal AS money), 1) + '|'
                + CASE WHEN d.TipoCodigo = '07' THEN '-' ELSE '' END + CONVERT(varchar(50), CAST(d.DocuIgv AS money), 1) + '|'
                + CASE WHEN d.TipoCodigo = '07' THEN '-' ELSE '' END + CONVERT(varchar(50), CAST(d.ICBPER AS money), 1) + '|'
                + CASE WHEN d.TipoCodigo = '07' THEN '-' ELSE '' END + CONVERT(varchar(50), CAST(d.DocuTotal AS money), 1) + '|'
                + d.DocuUsuario + '|' + d.DocuEstado + '|' + d.DocuNroGuia + '|' + d.CodigoSunat + '|'
                + REPLACE(d.MensajeSunat, '|', ' ') + '|' + d.DocuCondicion + '|' + d.FormaPago + '|'
                + d.EntidadBancaria + '|' + d.NroOperacion + '|'
                + CONVERT(varchar(50), CAST(d.Efectivo AS money), 1) + '|'
                + CONVERT(varchar(50), CAST(d.Deposito AS money), 1)
            FROM DocumentoVenta d
            INNER JOIN Cliente c ON c.ClienteId = d.ClienteId
            WHERE d.DocuEmision >= @FechaInicio
              AND d.DocuEmision < DATEADD(day, 1, @FechaFin)
              AND d.DocuDocumento <> 'PROFORMA V'
            ORDER BY d.DocuEmision, d.DocuSerie + '-' + d.DocuNumero
            FOR XML PATH('')
        ), 1, 1, '')
    );

    SELECT @Cabecera + '¬' + @Anchos
        + CASE WHEN NULLIF(LTRIM(RTRIM(@Detalle)), '') IS NULL THEN '' ELSE '¬' + @Detalle END;
END
