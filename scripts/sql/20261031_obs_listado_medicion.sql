/* Solo lectura. Ejecuta la consulta completa del API para el ultimo dia OBS
   disponible; leer todas las filas y medir tiempo antes y despues del indice. */
DECLARE @FechaInicio date;
DECLARE @FechaFin date;
DECLARE @TipoVenta nvarchar(3) = N'OBS';
SELECT @FechaInicio = MAX(FechaTransaccion) FROM dbo.TABLAOBS WHERE TipoVenta = @TipoVenta;
SET @FechaFin = @FechaInicio;
SELECT T.ID, CONVERT(char(10), T.FechaTransaccion, 23) AS Fecha,
       T.NotaTransaccion, T.CodigoMiembro, T.NombreMiembro, T.Importe,
       ISNULL(N.NotaUsuario, 'NO EXISTE') AS Usuario,
       ISNULL(N.NotaEstado, 'NO EXISTE') AS Estado,
       ISNULL(CONVERT(varchar(30), N.CajaId), 'NO EXISTE') AS CajaId
FROM dbo.TABLAOBS AS T
LEFT JOIN dbo.NotaPedido AS N ON N.NotaTransaccion = T.NotaTransaccion
WHERE T.TipoVenta = @TipoVenta
  AND T.FechaTransaccion BETWEEN @FechaInicio AND @FechaFin
ORDER BY T.FechaTransaccion, T.ID;
