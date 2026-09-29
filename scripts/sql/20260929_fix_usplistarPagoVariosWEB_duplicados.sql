/*
   Fix Pago Varios pending list:
   - Return only the DocumentoVenta whose series/number match the current NotaPedido.
   - Return at most one row per note, even if DocumentoVenta has repeated rows.
   - Exclude notes already linked to a Pago Varios detail.
   This changes the listing procedure only; it does not delete or alter invoices.
*/
CREATE OR ALTER PROCEDURE dbo.usplistarPagoVariosWEB
    @UsuarioId varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CajaId numeric(38);

    SET @CajaId = ISNULL((
        SELECT TOP (1) CajaId
        FROM dbo.Caja
        WHERE CajaEstado = 'ACTIVO'
          AND UsuarioId = @UsuarioId
        ORDER BY CajaId DESC
    ), 0);

    SELECT
        'DocuId|NotaId|Documento|Codigo|RazonSocial|Monto|Selec|ConceptoOBS|FP|MontoD|Efectivo|Depsoito¬100|100|100|100|100|100|100|100|100|100|100|100¬String|String|String|String|String|String|Boolean|String|String|Decimal|String|String¬'
        + ISNULL((
            SELECT STUFF((
                SELECT
                    '¬' + CONVERT(varchar, d.DocuId) + '|'
                    + CONVERT(varchar, n.NotaId) + '|'
                    + d.DocuSerie + '-' + d.DocuNumero + '|'
                    + c.ClienteCodigo + '|'
                    + c.ClienteRazon + '|'
                    + CONVERT(varchar(50), CAST(n.NotaPagar AS money), 1) + '|0|'
                    + n.ConceptoOBS + '||'
                    + CONVERT(varchar, n.NotaPagar) + '|0.00|0.00'
                FROM dbo.NotaPedido n
                CROSS APPLY (
                    SELECT TOP (1) dv.DocuId, dv.DocuSerie, dv.DocuNumero
                    FROM dbo.DocumentoVenta dv
                    WHERE dv.NotaId = n.NotaId
                      AND LTRIM(RTRIM(ISNULL(dv.DocuSerie, ''))) = LTRIM(RTRIM(ISNULL(n.NotaSerie, '')))
                      AND LTRIM(RTRIM(ISNULL(dv.DocuNumero, ''))) = LTRIM(RTRIM(ISNULL(n.NotaNumero, '')))
                    ORDER BY dv.DocuId DESC
                ) d
                INNER JOIN dbo.Cliente c ON c.ClienteId = n.ClienteId
                WHERE n.NotaCondicion = 'PAGO/VARIOS'
                  AND n.CajaId = @CajaId
                  AND n.NotaEstado NOT IN ('CANCELADO', 'ANULADO')
                  AND NOT EXISTS (
                      SELECT 1
                      FROM dbo.DetallePVarios dp
                      WHERE dp.NotaId = n.NotaId
                  )
                ORDER BY n.NotaId DESC
                FOR XML PATH('')
            ), 1, 1, '')
        ), '~');
END;
GO
