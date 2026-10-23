/*
  Flag ListaProductosTabla por compania. Compatible con SQL Server 2008 R2.
  Ejecutar con la base destino seleccionada; no cambia la conexion ni otros indicadores.
  ValorNum = 0 conserva el autocomplete; 1 muestra las pestanas Productos y Detalle.
  Las filas y valores existentes se conservan. No consulta ni actualiza productos.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.Indicador', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Compania', N'U') IS NULL
BEGIN
    RAISERROR('Se requieren dbo.Indicador y dbo.Compania en la base seleccionada.', 16, 1);
    RETURN;
END;

IF EXISTS
(
    SELECT CompaniaId
    FROM dbo.Indicador
    WHERE Descripcion = 'ListaProductosTabla'
    GROUP BY CompaniaId
    HAVING COUNT(*) > 1
)
BEGIN
    RAISERROR('Hay indicadores ListaProductosTabla duplicados. Resolver la ambiguedad antes de continuar.', 16, 1);
    RETURN;
END;

IF EXISTS
(
    SELECT 1
    FROM dbo.Indicador
    WHERE Descripcion = 'ListaProductosTabla'
      AND (CompaniaId IS NULL OR ISNULL(Area, '') <> 'VENTAS'
           OR TipoIndicador <> 1 OR IdIndicador IS NOT NULL
           OR ValorNum IS NULL OR ValorNum NOT IN (0, 1))
)
BEGIN
    RAISERROR('Un indicador ListaProductosTabla existente tiene un alcance, tipo o valor incompatible. No se modifico.', 16, 1);
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.Indicador
        (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
    SELECT c.CompaniaId, 'VENTAS', 1, NULL, 'ListaProductosTabla',
           'Mostrar productos en tabla con cantidades y detalle de venta', 0
    FROM dbo.Compania AS c
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Indicador AS i WITH (UPDLOCK, HOLDLOCK)
        WHERE i.CompaniaId = c.CompaniaId
          AND i.Descripcion = 'ListaProductosTabla'
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @Mensaje nvarchar(4000);
    SET @Mensaje = ERROR_MESSAGE();
    RAISERROR('%s', 16, 1, @Mensaje);
    RETURN;
END CATCH;

SELECT CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorNum
FROM dbo.Indicador
WHERE Descripcion = 'ListaProductosTabla'
ORDER BY CompaniaId;
