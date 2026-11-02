-- Consulta de referencia de solo lectura. Reemplazar los parámetros antes de ejecutar.
DECLARE @ClienteId numeric(20) = 1, @FechaInicio date = '20261101', @FechaFin date = '20261130';
SELECT n.NotaId, n.NotaFechaPago, n.NotaTransaccion, c.ClienteCodigo, c.ClienteRazon,
       CAST(COALESCE(SUM(d.DetallePV), 0) AS decimal(19, 2)) AS PV,
       CAST(COALESCE(SUM(d.DetalleSV), 0) AS decimal(19, 2)) AS SV,
       CAST(n.NotaPagar AS decimal(19, 2)) AS Importe
FROM dbo.NotaPedido n
INNER JOIN dbo.Cliente c ON c.ClienteId = n.ClienteId
INNER JOIN dbo.DetallePedido d ON d.NotaId = n.NotaId
WHERE n.ClienteId = @ClienteId AND n.NotaEstado = 'CANCELADO'
  AND n.NotaFechaPago >= @FechaInicio AND n.NotaFechaPago <= @FechaFin
GROUP BY n.NotaId, n.NotaFechaPago, n.NotaTransaccion, c.ClienteCodigo, c.ClienteRazon, n.NotaPagar
ORDER BY n.NotaId DESC;
