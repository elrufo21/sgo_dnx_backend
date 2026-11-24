-- Ejecutar en la base principal configurada para la API.
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
    RAISERROR('Ya existe la version anterior de InventarioSaldoInicial. Revisar sus datos antes de migrarla.', 16, 1);
    RETURN;
END;
