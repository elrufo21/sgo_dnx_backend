IF COL_LENGTH('dbo.Compania', 'FlagCaptura') IS NULL
    ALTER TABLE dbo.Compania ADD FlagCaptura bit NOT NULL CONSTRAINT DF_Compania_FlagCaptura DEFAULT ((0))
GO

IF OBJECT_ID('dbo.uspValidaUsuarioweb', 'P') IS NOT NULL
    DROP PROCEDURE dbo.uspValidaUsuarioweb
GO

CREATE PROCEDURE dbo.uspValidaUsuarioweb
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @p1 int, @p2 int
    DECLARE @Usuario varchar(150), @Clave varchar(150)

    SET @Data = LTRIM(RTRIM(@Data))
    SET @p1 = CHARINDEX('|', @Data, 0)
    SET @p2 = CHARINDEX('|', @Data, @p1 + 1)
    IF (@p2 = 0) SET @p2 = LEN(@Data) + 1

    SET @Usuario = SUBSTRING(@Data, 1, @p1 - 1)
    SET @Clave = SUBSTRING(@Data, @p1 + 1, @p2 - @p1 - 1)

    SELECT ISNULL((
        SELECT STUFF((
            SELECT TOP 1
                '¬' + CONVERT(varchar, U.UsuarioID) + '|' +
                CONVERT(varchar, p.PersonalId) + '|' +
                ISNULL(a.AreaNombre, '') + '|' +
                (
                    SUBSTRING(ISNULL(p.PersonalNombres, '') + ' ', 1, CHARINDEX(' ', ISNULL(p.PersonalNombres, '') + ' ') - 1) + ' ' +
                    SUBSTRING(ISNULL(p.PersonalApellidos, '') + ' ', 1, CHARINDEX(' ', ISNULL(p.PersonalApellidos, '') + ' ') - 1)
                ) + '|' +
                CONVERT(varchar, p.CompaniaId) + '|' +
                ISNULL(c.CompaniaRazonSocial, '') + '|' +
                ISNULL(CONVERT(varchar(10), U.FechaVencimientoClave, 23), '') + '|' +
                ISNULL(CONVERT(varchar(20), c.DescuentoMax), '0') + '|' +
                ISNULL(c.CompaniaRUC, '') + '|' +
                ISNULL(c.CompaniaNomUBG, '') + '|' +
                ISNULL(c.CompaniaComercial, '') + '|' +
                ISNULL(c.CompaniaDirecSunat, '') + '|' +
                ISNULL(c.CompaniaUserSecun, '') + '|' +
                ISNULL(c.ComapaniaPWD, '') + '|' +
                ISNULL(c.CompaniaPFX, '') + '|' +
                ISNULL(c.CompaniaClave, '') + '|' +
                ISNULL(CONVERT(varchar, c.TIPO_PROCESO), '3') + '|' +
                ISNULL(c.CompaniaTelefono, '') + '|' +
                ISNULL(CONVERT(varchar, c.BoletaPorLote), '1') + '|' +
                ISNULL(CONVERT(varchar, c.FlagCaptura), '0')
            FROM dbo.Usuarios U
            INNER JOIN dbo.Personal p ON p.PersonalId = U.PersonalId
            INNER JOIN dbo.Area a ON a.AreaId = p.AreaId
            INNER JOIN dbo.Compania c ON c.CompaniaId = p.CompaniaId
            WHERE U.UsuarioAlias = @Usuario
              AND dbo.desincrectar(U.UsuarioClave) = @Clave
              AND U.UsuarioEstado = 'ACTIVO'
              AND p.PersonalEstado = 'ACTIVO'
            FOR XML PATH('')
        ), 1, 1, '')
    ), '~')
END
GO
