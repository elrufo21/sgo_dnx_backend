IF OBJECT_ID(N'dbo.InventarioSaldoInicial', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.InventarioSaldoInicial
    (
        Codigo varchar(297) NOT NULL,
        FechaInicio date NOT NULL,
        Cantidad decimal(18,2) NOT NULL,
        CONSTRAINT PK_InventarioSaldoInicial PRIMARY KEY (Codigo, FechaInicio)
    );
END
ELSE IF COL_LENGTH(N'dbo.InventarioSaldoInicial', N'FechaFin') IS NOT NULL
BEGIN
    THROW 50001, 'Ya existe la versión anterior de InventarioSaldoInicial. Revisar sus datos antes de migrarla.', 1;
END;
