/*
   FlagCaja por compañía:
   0 = una sola caja activa
   1 = múltiples cajas activas
*/
SET XACT_ABORT ON;
GO

CREATE OR ALTER PROCEDURE dbo.uspCajaInsertaCsv
    @Data varchar(max)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @p1 int, @p2 int, @p3 int, @p4 int, @p5 int, @p6 int,
            @p7 int, @p8 int, @p9 int, @p10 int, @p11 int, @p12 int;
    DECLARE @CajaId numeric(38), @CajaCierre varchar(40), @MontoIniSOl decimal(18, 2),
            @CajaEncargado varchar(60), @CajaUsuario varchar(60), @CajaEstado varchar(40),
            @CajaIngresos decimal(18, 2), @CajaDeposito decimal(18, 2),
            @CajaSalidas decimal(18, 2), @CajaTotal decimal(18, 2), @UsuarioId int,
            @Observacion varchar(max), @CompaniaId int, @FlagCaja bit = 0;

    SET @Data = LTRIM(RTRIM(@Data));
    SET @p1 = CHARINDEX('|', @Data, 0);
    SET @p2 = CHARINDEX('|', @Data, @p1 + 1);
    SET @p3 = CHARINDEX('|', @Data, @p2 + 1);
    SET @p4 = CHARINDEX('|', @Data, @p3 + 1);
    SET @p5 = CHARINDEX('|', @Data, @p4 + 1);
    SET @p6 = CHARINDEX('|', @Data, @p5 + 1);
    SET @p7 = CHARINDEX('|', @Data, @p6 + 1);
    SET @p8 = CHARINDEX('|', @Data, @p7 + 1);
    SET @p9 = CHARINDEX('|', @Data, @p8 + 1);
    SET @p10 = CHARINDEX('|', @Data, @p9 + 1);
    SET @p11 = CHARINDEX('|', @Data, @p10 + 1);
    SET @p12 = LEN(@Data) + 1;

    SET @CajaId = CONVERT(numeric(38), SUBSTRING(@Data, 1, @p1 - 1));
    SET @CajaCierre = SUBSTRING(@Data, @p1 + 1, @p2 - @p1 - 1);
    SET @MontoIniSOl = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p2 + 1, @p3 - @p2 - 1));
    SET @CajaEncargado = SUBSTRING(@Data, @p3 + 1, @p4 - @p3 - 1);
    SET @CajaUsuario = SUBSTRING(@Data, @p4 + 1, @p5 - @p4 - 1);
    SET @CajaEstado = SUBSTRING(@Data, @p5 + 1, @p6 - @p5 - 1);
    SET @CajaIngresos = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p6 + 1, @p7 - @p6 - 1));
    SET @CajaDeposito = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p7 + 1, @p8 - @p7 - 1));
    SET @CajaSalidas = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p8 + 1, @p9 - @p8 - 1));
    SET @CajaTotal = CONVERT(decimal(18, 2), SUBSTRING(@Data, @p9 + 1, @p10 - @p9 - 1));
    SET @UsuarioId = CONVERT(int, SUBSTRING(@Data, @p10 + 1, @p11 - @p10 - 1));
    SET @Observacion = SUBSTRING(@Data, @p11 + 1, @p12 - @p11 - 1);

    IF @CajaId = 0
    BEGIN
        BEGIN TRANSACTION;

        SELECT @CompaniaId = p.CompaniaId
          FROM dbo.Usuarios u WITH (UPDLOCK, HOLDLOCK)
          INNER JOIN dbo.Personal p ON p.PersonalId = u.PersonalId
         WHERE u.UsuarioID = @UsuarioId;

        SELECT @FlagCaja = ISNULL(c.FlagCaja, 0)
          FROM dbo.Compania c WITH (UPDLOCK, HOLDLOCK)
         WHERE c.CompaniaId = @CompaniaId;

        IF ISNULL(@FlagCaja, 0) = 0
           AND EXISTS
           (
               SELECT 1
                 FROM dbo.Caja c WITH (UPDLOCK, HOLDLOCK)
                 INNER JOIN dbo.Usuarios u ON u.UsuarioID = c.UsuarioId
                 INNER JOIN dbo.Personal p ON p.PersonalId = u.PersonalId
                WHERE c.CajaEstado = 'ACTIVO'
                  AND p.CompaniaId = @CompaniaId
           )
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'SOLO_UNA_CAJA';
            RETURN;
        END;

        INSERT INTO dbo.Caja
        VALUES (GETDATE(), @CajaCierre, @MontoIniSOl, @CajaEncargado, @CajaUsuario,
                @CajaEstado, @CajaIngresos, @CajaDeposito, @CajaSalidas, @CajaTotal,
                @UsuarioId, @Observacion);
        SET @CajaId = @@IDENTITY;

        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'TOTAL EFECTIVO', 0, 0, 0, '', 'T', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'VITRINA', 0, 0, 0, '', 'D', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'SENCILLO', 0, 0, 0, '', 'T', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'IOC', 0, 0, 0, '', 'T', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'REVISTAS', 0, 0, 0, '', 'D', 'V', 0, '', '', '', '');
        INSERT INTO dbo.CajaDetalle VALUES (@CajaId, GETDATE(), 0, 'INGRESO', 'COPIAS Y OTROS', 0, 0, 0, '', 'D', 'V', 0, '', '', '', '');
        INSERT INTO dbo.Monedas VALUES (0, 0, '200.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '100.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '50.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '20.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '10.00', 0, 'B', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '5.00', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '2.00', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '1.00', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '0.50', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '0.20', 0, 'M', @CajaId);
        INSERT INTO dbo.Monedas VALUES (0, 0, '0.10', 0, 'M', @CajaId);

        COMMIT TRANSACTION;
        SELECT 'true';
        RETURN;
    END;

    IF @CajaEstado = 'CERRADA'
    BEGIN
        DECLARE @Descripcion varchar(max);
        SET @Descripcion = ISNULL((SELECT TOP 1 d.DetalleConcepto + ' TOTAL S/ ' + CONVERT(varchar(max), CAST(d.DetalleMonto AS money), 1)
                                    FROM dbo.CajaDetalle d
                                    WHERE d.RutaImagen LIKE '%file.png%'
                                      AND d.CajaId = @CajaId
                                      AND d.NotaId = 0
                                      AND d.DetalleMonto >= 500000
                                    ORDER BY d.DetalleId ASC), '0');
        IF @Descripcion <> '0'
        BEGIN
            SELECT 'Falta Adjuntar el Archivo de: ' + @Descripcion;
            RETURN;
        END;
    END;

    UPDATE dbo.Caja
       SET CajaCierre = @CajaCierre,
           MontoIniSOl = @MontoIniSOl,
           CajaEncargado = @CajaEncargado,
           CajaUsuario = @CajaUsuario,
           CajaEstado = @CajaEstado,
           CajaIngresos = @CajaIngresos,
           CajaDeposito = @CajaDeposito,
           CajaSalidas = @CajaSalidas,
           CajaTotal = @CajaTotal,
           UsuarioId = @UsuarioId,
           Observacion = @Observacion
     WHERE CajaId = @CajaId;
    SELECT 'true';
END;
GO

CREATE OR ALTER PROCEDURE dbo.uspValidaCantCajas
    @CajaId numeric(38, 0),
    @UsuarioId int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompaniaId int, @FlagCaja bit = 0;

    SELECT @CompaniaId = p.CompaniaId
      FROM dbo.Usuarios u
      INNER JOIN dbo.Personal p ON p.PersonalId = u.PersonalId
     WHERE u.UsuarioID = @UsuarioId;

    SELECT @FlagCaja = ISNULL(c.FlagCaja, 0)
      FROM dbo.Compania c
     WHERE c.CompaniaId = @CompaniaId;

    IF ISNULL(@FlagCaja, 0) = 1
    BEGIN
        SELECT 'true';
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
          FROM dbo.Caja c WITH (UPDLOCK, HOLDLOCK)
          INNER JOIN dbo.Usuarios u ON u.UsuarioID = c.UsuarioId
          INNER JOIN dbo.Personal p ON p.PersonalId = u.PersonalId
         WHERE c.CajaEstado = 'ACTIVO'
           AND p.CompaniaId = @CompaniaId
           AND c.CajaId <> @CajaId
    )
    BEGIN
        SELECT 'SOLO_UNA_CAJA';
        RETURN;
    END;

    SELECT 'true';
END;
GO
