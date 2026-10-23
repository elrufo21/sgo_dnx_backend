/* SQL Server 2008 R2. No escribe en tablas comerciales ni normaliza datos historicos. */
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'dbo.uspListarFacturasServicioWeb', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.uspListarFacturasServicioWeb AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.uspListarFacturasServicioWeb
    @FechaInicio date = NULL,
    @FechaFin date = NULL,
    @EstadoSunat varchar(50) = NULL,
    @CompaniaId int = NULL,
    @SoloServicio bit = 1,
    @PendientesOse bit = 0,
    @Page int = 1,
    @PageSize int = 50,
    @Buscar nvarchar(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF (@FechaInicio IS NOT NULL AND @FechaFin IS NOT NULL AND @FechaInicio > @FechaFin)
       OR @FechaFin = '99991231'
    BEGIN
        RAISERROR('El rango de fechas de facturas no es valido.', 16, 1);
        RETURN;
    END;
    IF @Page < 1 SET @Page = 1;
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

    /* Los modos se separan antes de la clasificacion de servicios y los joins de presentacion. */
    SELECT d.DocuId, d.DocuEmision INTO #Candidatas
    FROM dbo.DocumentoVenta d
    WHERE @PendientesOse = 0 AND d.TipoCodigo = '01'
      AND LTRIM(RTRIM(ISNULL(d.DocuDocumento, ''))) = 'FACTURA'
      AND (@CompaniaId IS NULL OR d.CompaniaId = @CompaniaId)
      AND (@EstadoSunat IS NULL OR LTRIM(RTRIM(ISNULL(d.EstadoSunat, ''))) = @EstadoSunat)
      AND (@FechaInicio IS NULL OR d.DocuEmision >= @FechaInicio)
      AND (@FechaFin IS NULL OR d.DocuEmision < DATEADD(day, 1, @FechaFin))
    OPTION (RECOMPILE);

    IF @PendientesOse = 1
        INSERT INTO #Candidatas(DocuId, DocuEmision)
        SELECT d.DocuId, d.DocuEmision FROM dbo.DocumentoVenta d
        WHERE d.TipoCodigo IN ('01', '07')
          AND LTRIM(RTRIM(ISNULL(d.EstadoSunat, ''))) = 'PENDIENTE'
          AND (@CompaniaId IS NULL OR d.CompaniaId = @CompaniaId)
          AND (@EstadoSunat IS NULL OR LTRIM(RTRIM(ISNULL(d.EstadoSunat, ''))) = @EstadoSunat)
          AND (@FechaInicio IS NULL OR d.DocuEmision >= @FechaInicio)
          AND (@FechaFin IS NULL OR d.DocuEmision < DATEADD(day, 1, @FechaFin))
        OPTION (RECOMPILE);
    CREATE UNIQUE CLUSTERED INDEX IX_Candidatas_Id ON #Candidatas(DocuId);

    /* Conserva los tres criterios historicos de servicio, antes de paginar. */
    IF @SoloServicio = 1
        DELETE f FROM #Candidatas f INNER JOIN dbo.DocumentoVenta d ON d.DocuId = f.DocuId
        WHERE UPPER(LTRIM(RTRIM(ISNULL(d.DocuCondicion, '')))) <> 'SERVICIO'
          AND UPPER(LTRIM(RTRIM(ISNULL(d.DocuAsociado, '')))) <> 'FACTURA_SERVICIO_OSE'
          AND NOT EXISTS (
              SELECT 1 FROM dbo.DetalleDocumento ds
              LEFT JOIN dbo.Producto p ON p.IdProducto = ds.IdProducto
              WHERE ds.DocuId = f.DocuId
                AND (UPPER(LTRIM(RTRIM(ISNULL(ds.DetalleUM, '')))) = 'ZZ'
                  OR UPPER(LTRIM(RTRIM(ISNULL(p.ProductoINV, '')))) <> 'S')
          );

    IF EXISTS (SELECT 1 FROM @Terminos)
        DELETE f FROM #Candidatas f
        INNER JOIN dbo.DocumentoVenta d ON d.DocuId = f.DocuId
        LEFT JOIN dbo.Cliente c ON c.ClienteId = d.ClienteId
        WHERE EXISTS (
            SELECT 1 FROM @Terminos t
            WHERE CHARINDEX(t.Termino,
                (CONVERT(nvarchar(40), d.DocuId) + N' '
                 + LTRIM(RTRIM(ISNULL(d.DocuSerie, ''))) + N'-' + LTRIM(RTRIM(ISNULL(d.DocuNumero, '')))
                 + N' ' + ISNULL(c.ClienteRazon, '') + N' ' + ISNULL(c.ClienteRuc, '')
                 + N' ' + ISNULL(c.ClienteDni, '') + N' ' + ISNULL(d.DocuConcepto, '')
                 + N' ' + ISNULL(d.DocuEstado, '') + N' ' + ISNULL(d.EstadoSunat, ''))
                  COLLATE Latin1_General_CI_AI) = 0
              AND NOT EXISTS (
                  SELECT 1 FROM dbo.DetalleDocumento ds
                  INNER JOIN dbo.Producto sp ON sp.IdProducto = ds.IdProducto
                  WHERE ds.DocuId = f.DocuId
                    AND CHARINDEX(t.Termino, ISNULL(sp.ProductoNombre, '') COLLATE Latin1_General_CI_AI) > 0
              )
        );

    DECLARE @TotalRows int;
    SELECT @TotalRows = COUNT(*) FROM #Candidatas;
    SELECT @TotalRows AS TotalRows, @Page AS Page, @PageSize AS PageSize;

    ;WITH Ordenadas AS (
        SELECT DocuId, ROW_NUMBER() OVER (ORDER BY DocuEmision DESC, DocuId DESC) AS RowNum
        FROM #Candidatas
    )
    SELECT DocuId, RowNum INTO #Pagina FROM Ordenadas
    WHERE RowNum BETWEEN (CONVERT(bigint, @Page) - 1) * @PageSize + 1
                         AND CONVERT(bigint, @Page) * @PageSize;
    CREATE UNIQUE CLUSTERED INDEX IX_Pagina_Id ON #Pagina(DocuId);

    /* Normaliza referencias antiguas solo en temporales; evita un escaneo de NC por factura. */
    SELECT n.DocuId,
           LTRIM(RTRIM(ISNULL(n.DocuAsociado, ''))) AS IdReferencia,
           LTRIM(RTRIM(ISNULL(n.DocuNroGuia, ''))) AS GuiaReferencia,
           CASE WHEN LTRIM(RTRIM(ISNULL(n.EstadoSunat, ''))) = 'ENVIADO' THEN 0 ELSE 1 END AS Prioridad
    INTO #NotasCredito
    FROM dbo.DocumentoVenta n
    WHERE n.TipoCodigo = '07'
      AND EXISTS (SELECT 1 FROM #Pagina p INNER JOIN dbo.DocumentoVenta d ON d.DocuId = p.DocuId
                  WHERE UPPER(LTRIM(RTRIM(d.DocuEstado))) = 'ANULADO');
    CREATE INDEX IX_NC_IdReferencia ON #NotasCredito(IdReferencia);
    CREATE INDEX IX_NC_GuiaReferencia ON #NotasCredito(GuiaReferencia);

    ;WITH Coincidencias AS (
        SELECT p.DocuId AS OriginalId, n.DocuId, n.Prioridad
        FROM #Pagina p INNER JOIN dbo.DocumentoVenta d ON d.DocuId = p.DocuId
        INNER JOIN #NotasCredito n ON n.IdReferencia = CONVERT(varchar(30), p.DocuId)
        WHERE UPPER(LTRIM(RTRIM(d.DocuEstado))) = 'ANULADO'
        UNION
        SELECT p.DocuId, n.DocuId, n.Prioridad
        FROM #Pagina p INNER JOIN dbo.DocumentoVenta d ON d.DocuId = p.DocuId
        INNER JOIN #NotasCredito n ON n.GuiaReferencia = LTRIM(RTRIM(ISNULL(d.DocuSerie, ''))) + '-'
                                                     + LTRIM(RTRIM(ISNULL(d.DocuNumero, '')))
        WHERE UPPER(LTRIM(RTRIM(d.DocuEstado))) = 'ANULADO'
    ), Preferidas AS (
        SELECT OriginalId, DocuId,
               ROW_NUMBER() OVER (PARTITION BY OriginalId ORDER BY Prioridad, DocuId DESC) AS Posicion
        FROM Coincidencias
    )
    SELECT OriginalId, DocuId INTO #Relacionadas FROM Preferidas WHERE Posicion = 1;
    CREATE UNIQUE CLUSTERED INDEX IX_Relacionadas_Id ON #Relacionadas(OriginalId);

    ;WITH Detalles AS (
        SELECT dd.DocuId, COUNT(dd.DetalleId) AS TotalDetalles
        FROM #Pagina p INNER JOIN dbo.DetalleDocumento dd ON dd.DocuId = p.DocuId
        GROUP BY dd.DocuId
    )
    SELECT d.DocuId, d.NotaId, d.CompaniaId, d.DocuDocumento, d.DocuSerie, d.DocuNumero,
           d.DocuEmision, w.DocuFechaPago, d.ClienteId,
           c.ClienteRazon, c.ClienteRuc, c.ClienteDni, c.ClienteDireccion AS DireccionFiscal,
           d.DocuSubTotal, d.DocuIgv, d.DocuTotal, d.DocuSaldo, d.DocuEstado,
           d.EstadoSunat, d.CodigoSunat, d.MensajeSunat, d.DocuHash,
           ISNULL(w.DocuPdfUrl, '') AS DocuPdfUrl, ISNULL(w.DocuXmlUrl, '') AS DocuXmlUrl,
           ISNULL(w.DocuCdrUrl, '') AS DocuCdrUrl, d.FormaPago, d.DocuCondicion, d.DocuConcepto,
           d.DocuAsociado, n.DocuId AS DocuRelacionadoId, n.DocuDocumento AS DocuRelacionadoDocumento,
           n.DocuSerie AS DocuRelacionadoSerie, n.DocuNumero AS DocuRelacionadoNumero,
           nw.DocuFechaPago AS DocuRelacionadoFechaPago, n.TipoCodigo AS DocuRelacionadoTipoCodigo,
           n.DocuEstado AS DocuRelacionadoEstado, n.EstadoSunat AS DocuRelacionadoEstadoSunat,
           ISNULL(dt.TotalDetalles, 0) AS TotalDetalles
    FROM #Pagina p
    INNER JOIN dbo.DocumentoVenta d ON d.DocuId = p.DocuId
    LEFT JOIN dbo.Cliente c ON c.ClienteId = d.ClienteId
    LEFT JOIN dbo.DocumentoVentaCpeWeb w ON w.DocuId = d.DocuId
    LEFT JOIN Detalles dt ON dt.DocuId = d.DocuId
    LEFT JOIN #Relacionadas r ON r.OriginalId = d.DocuId
    LEFT JOIN dbo.DocumentoVenta n ON n.DocuId = r.DocuId
    LEFT JOIN dbo.DocumentoVentaCpeWeb nw ON nw.DocuId = n.DocuId
    ORDER BY p.RowNum;
END;
GO
