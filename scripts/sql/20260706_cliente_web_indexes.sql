IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ClienteWeb_Estado_Razon' AND object_id = OBJECT_ID('dbo.Cliente'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_ClienteWeb_Estado_Razon
    ON dbo.Cliente (ClienteEstado, ClienteRazon, ClienteId)
    INCLUDE (ClienteCodigo, ClienteRuc, ClienteDni);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ClienteWeb_Codigo' AND object_id = OBJECT_ID('dbo.Cliente'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_ClienteWeb_Codigo
    ON dbo.Cliente (ClienteCodigo)
    INCLUDE (ClienteId, ClienteRazon, ClienteRuc, ClienteDni, ClienteEstado);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ClienteWeb_Ruc' AND object_id = OBJECT_ID('dbo.Cliente'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_ClienteWeb_Ruc
    ON dbo.Cliente (ClienteRuc)
    INCLUDE (ClienteId, ClienteCodigo, ClienteRazon, ClienteDni, ClienteEstado);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ClienteWeb_Dni' AND object_id = OBJECT_ID('dbo.Cliente'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_ClienteWeb_Dni
    ON dbo.Cliente (ClienteDni)
    INCLUDE (ClienteId, ClienteCodigo, ClienteRazon, ClienteRuc, ClienteEstado);
END
GO
