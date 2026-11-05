/* SQL Server 2008 R2. Ejecutar en la BD elegida antes de publicar la API.
   Solo crea/actualiza este procedimiento de lectura; no modifica los SP del escritorio. */
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'dbo.uspListarControlCajaWeb', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.uspListarControlCajaWeb AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.uspListarControlCajaWeb
    @FechaInicio date = NULL,
    @FechaFin date = NULL,
    @Page int = NULL,
    @PageSize int = 50,
    @Buscar nvarchar(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @FechaInicio IS NULL AND @FechaFin IS NULL
    BEGIN
        SET @FechaInicio = DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0);
        SET @FechaFin = DATEADD(day, -1, DATEADD(month, 1, @FechaInicio));
    END;
    IF @FechaInicio IS NULL OR @FechaFin IS NULL OR @FechaInicio > @FechaFin
       OR @FechaFin = '99991231'
    BEGIN
        RAISERROR('El rango de fechas de caja no es valido.', 16, 1);
        RETURN;
    END;
    IF @Page IS NOT NULL AND @Page < 1 SET @Page = 1;
    IF @PageSize < 1 OR @PageSize > 200 SET @PageSize = 50;
    DECLARE @Terminos TABLE (Termino nvarchar(150) NOT NULL);
    DECLARE @Texto nvarchar(150), @Espacio int;
    SET @Texto = LTRIM(RTRIM(ISNULL(@Buscar, N'')));
    WHILE LEN(@Texto) > 0
    BEGIN
        SET @Espacio = CHARINDEX(N' ', @Texto + N' ');
        INSERT INTO @Terminos VALUES (LEFT(@Texto, @Espacio - 1));
        SET @Texto = LTRIM(SUBSTRING(@Texto, @Espacio + 1, 150));
    END;

    SELECT c.CajaId, ROW_NUMBER() OVER (ORDER BY c.CajaId DESC) AS RowNum
    INTO #Filtradas
    FROM dbo.Caja c
    WHERE c.CajaFecha >= @FechaInicio
      AND c.CajaFecha < DATEADD(day, 1, @FechaFin)
      AND NOT EXISTS (
          SELECT 1 FROM @Terminos t
          WHERE CHARINDEX(t.Termino,
              (CONVERT(nvarchar(40), c.CajaId) + N' ' + ISNULL(c.CajaEncargado, '')
               + N' ' + ISNULL(c.CajaEstado, '') + N' '
               + CASE WHEN UPPER(LTRIM(RTRIM(c.CajaEstado))) = 'ACTIVO' THEN N'ABIERTA' ELSE N'' END)
               COLLATE Latin1_General_CI_AI) = 0
      )
    OPTION (RECOMPILE);
    CREATE UNIQUE CLUSTERED INDEX IX_Filtradas_Id ON #Filtradas(CajaId);

    DECLARE @TotalRows int;
    SELECT @TotalRows = COUNT(*) FROM #Filtradas;
    IF @Page IS NOT NULL AND @Page > 1 AND (@Page - 1) * CONVERT(bigint, @PageSize) >= @TotalRows
        SET @Page = CASE WHEN @TotalRows = 0 THEN 1 ELSE ((@TotalRows - 1) / @PageSize) + 1 END;
    SELECT @TotalRows AS TotalRows, ISNULL(@Page, 1) AS Page, @PageSize AS PageSize;

    SELECT c.* INTO #Pagina
    FROM #Filtradas f
    INNER JOIN dbo.Caja c ON c.CajaId = f.CajaId
    WHERE @Page IS NULL OR f.RowNum BETWEEN (CONVERT(bigint, @Page) - 1) * @PageSize + 1
                                                   AND CONVERT(bigint, @Page) * @PageSize;
    CREATE UNIQUE CLUSTERED INDEX IX_Pagina_Id ON #Pagina(CajaId);
    SELECT CajaId INTO #Cerradas FROM #Pagina
    WHERE UPPER(CajaEstado) LIKE 'CERRAD%';
    CREATE UNIQUE CLUSTERED INDEX IX_Cerradas_Id ON #Cerradas(CajaId);

    ;WITH Monedas AS (
        SELECT m.CajaId, SUM(ISNULL(m.Monto, 0)) AS MontoContado
        FROM dbo.Monedas m INNER JOIN #Cerradas c ON c.CajaId = m.CajaId
        GROUP BY m.CajaId
    ), Ventas AS (
        SELECT n.CajaId,
               SUM(CASE WHEN t.TipoVenta = 'OBS' THEN ISNULL(t.Importe, 0) ELSE 0 END) AS SistemaObs,
               SUM(CASE WHEN t.TipoVenta = 'IOC' THEN ISNULL(t.Importe, 0) ELSE 0 END) AS SistemaIoc
        FROM #Cerradas c
        INNER JOIN dbo.NotaPedido n ON n.CajaId = c.CajaId
        INNER JOIN dbo.TABLAOBS t ON t.NotaTransaccion = n.NotaTransaccion
                                AND t.TipoVenta IN ('OBS', 'IOC')
        GROUP BY n.CajaId
    ), Movimientos AS (
        SELECT d.CajaId,
               SUM(CASE WHEN d.DetalleMovimiento = 'SALIDA' AND ISNULL(d.NotaId, 0) = 0
                        THEN ISNULL(d.DetalleMonto, 0) ELSE 0 END) AS Salidas,
               SUM(CASE WHEN d.DetalleMovimiento = 'INGRESO' AND ISNULL(d.NotaId, 0) = 0
                          AND ISNULL(d.DetalleConcepto, '') NOT IN ('TOTAL EFECTIVO', 'SENCILLO')
                        THEN ISNULL(d.DetalleMonto, 0) ELSE 0 END) AS IngresosManuales
        FROM #Cerradas c INNER JOIN dbo.CajaDetalle d ON d.CajaId = c.CajaId
        GROUP BY d.CajaId
    )
    SELECT c.CajaId, c.CajaFecha, c.CajaCierre,
           ISNULL(c.MontoIniSol, 0) AS MontoIniSol,
           ISNULL(c.CajaIngresos, 0) AS CajaIngresos,
           ISNULL(c.CajaSalidas, 0) AS CajaSalidas,
           ISNULL(c.CajaTotal, 0) AS CajaTotal,
           c.CajaEncargado, c.CajaUsuario, c.CajaEstado, c.Observacion,
           CASE WHEN cerr.CajaId IS NULL THEN ISNULL(c.CajaTotal, 0) - ISNULL(c.CajaIngresos, 0)
                ELSE ISNULL(m.MontoContado, 0) - (ISNULL(c.MontoIniSol, 0)
                     + ISNULL(v.SistemaObs, 0) + ISNULL(v.SistemaIoc, 0)
                     - ISNULL(mv.Salidas, 0) + ISNULL(mv.IngresosManuales, 0)) END AS Diferencia
    FROM #Pagina c
    LEFT JOIN #Cerradas cerr ON cerr.CajaId = c.CajaId
    LEFT JOIN Monedas m ON m.CajaId = c.CajaId
    LEFT JOIN Ventas v ON v.CajaId = c.CajaId
    LEFT JOIN Movimientos mv ON mv.CajaId = c.CajaId
    ORDER BY c.CajaId DESC;
END;
GO
