SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH(N'dbo.Compania', N'CorreosAdmin') IS NULL
BEGIN
    ALTER TABLE dbo.Compania ADD CorreosAdmin varchar(max) NULL;
END;

IF COL_LENGTH(N'dbo.Compania', N'FlagCaja') IS NULL
BEGIN
    ALTER TABLE dbo.Compania ADD FlagCaja bit NOT NULL
        CONSTRAINT DF_Compania_FlagCaja DEFAULT ((0)) WITH VALUES;
END;

COMMIT TRANSACTION;
