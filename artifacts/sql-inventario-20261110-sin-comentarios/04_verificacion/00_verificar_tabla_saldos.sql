SET NOCOUNT ON;
SELECT DB_NAME() AS BasePrincipal,
       CASE WHEN OBJECT_ID(N'dbo.InventarioSaldoInicial', N'U') IS NULL THEN 0 ELSE 1 END AS TablaExiste,
       CASE WHEN COL_LENGTH(N'dbo.InventarioSaldoInicial', N'FechaFin') IS NULL THEN 0 ELSE 1 END AS VersionAnterior;
