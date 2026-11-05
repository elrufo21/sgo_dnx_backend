/* Revisar y ejecutar por el responsable SQL en la base de cada sede.
   No migra perfiles existentes: cada permiso individual existente se conserva.
   Respaldar Indicador y revisar duplicados de perfiles de usuario antes de aplicar. */
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'dbo.usp_PermisoIndicador', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.usp_PermisoIndicador AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.usp_PermisoIndicador
    @Operacion varchar(20),
    @CompaniaId int,
    @AreaId int,
    @UsuarioId int = NULL,
    @Permisos varchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CompaniaId <= 0 OR @AreaId <= 0
    BEGIN
        RAISERROR('CompaniaId y AreaId son obligatorios.', 16, 1);
        RETURN;
    END;

    DECLARE @AreaNombre varchar(100);
    SELECT TOP 1 @AreaNombre = AreaNombre FROM dbo.Area WHERE AreaId = @AreaId;

    IF @AreaNombre IS NULL
    BEGIN
        RAISERROR('El área indicada no existe.', 16, 1);
        RETURN;
    END;

    IF @UsuarioId IS NOT NULL AND NOT EXISTS
    (
        SELECT 1
        FROM dbo.Usuarios U
        INNER JOIN dbo.Personal P ON P.PersonalId = U.PersonalId
        WHERE U.UsuarioID = @UsuarioId
          AND P.AreaId = @AreaId
          AND P.CompaniaId = @CompaniaId
    )
    BEGIN
        RAISERROR('El usuario no pertenece al área o compañía indicada.', 16, 1);
        RETURN;
    END;

    DECLARE @Catalogo TABLE (Codigo varchar(100) NOT NULL PRIMARY KEY);
    INSERT INTO @Catalogo (Codigo) VALUES
        ('VENTAS.VER'), ('VENTAS.POS'), ('VENTAS.CAPTURAR'), ('VENTAS.LISTA'),
        ('VENTAS.OBS'), ('VENTAS.GUIA_REMISION'), ('VENTAS.NOTA_PEDIDO'),
        ('VENTAS.RESUMEN_BOLETAS'), ('VENTAS.ANULAR'),
        ('CAJA.VER'), ('CAJA.CONTROL'), ('CAJA.APERTURA'), ('CAJA.INFORME_FINAL'),
        ('CAJA.CHICA'), ('CAJA.GESTIONAR'),
        ('COMPRAS.GESTIONAR'), ('FACTURAS_SERVICIO.GESTIONAR'), ('CLIENTES.GESTIONAR'),
        ('CONTABILIDAD.VER'), ('CONTABILIDAD.PDT_EMPRESA'),
        ('CONTABILIDAD.ENVIO_FACTURAS'), ('CONTABILIDAD.RESUMEN_BOLETAS'),
        ('MANTENIMIENTO.VER'), ('MANTENIMIENTO.AREAS'), ('MANTENIMIENTO.CATEGORIAS'),
        ('MANTENIMIENTO.PROVEEDORES'), ('MANTENIMIENTO.FERIADOS'),
        ('MANTENIMIENTO.COMPUTADORAS'), ('MANTENIMIENTO.PRODUCTOS'),
        ('MANTENIMIENTO.EMPLEADOS'), ('MANTENIMIENTO.USUARIOS'),
        ('MANTENIMIENTO.RESUMEN_BOLETAS'),
        ('CONFIGURACION.VER'), ('CONFIGURACION.FACTURACION'),
        ('CONFIGURACION.VENTAS_BOLETAS'), ('CONFIGURACION.CAJA'),
        ('CONFIGURACION.PERMISOS');

    DECLARE @DescripcionArea varchar(500);
    SET @DescripcionArea = 'PERMISOS_AREA_' + CAST(@AreaId AS varchar(20));

    DECLARE @IdPerfilArea int;
    SELECT TOP 1 @IdPerfilArea = Id
    FROM dbo.Indicador
    WHERE CompaniaId = @CompaniaId
      AND Area = 'SEGURIDAD'
      AND TipoIndicador = 90
      AND IdIndicador IS NULL
      AND Descripcion = @DescripcionArea
    ORDER BY Id DESC;

    IF @IdPerfilArea IS NULL AND @Operacion = 'GUARDAR'
    BEGIN
        INSERT INTO dbo.Indicador
            (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
        VALUES
            (@CompaniaId, 'SEGURIDAD', 90, NULL, @DescripcionArea, @AreaNombre, NULL);
        SET @IdPerfilArea = SCOPE_IDENTITY();
    END;

    DECLARE @IdPerfilUsuario int;
    SET @IdPerfilUsuario = NULL;

    IF @UsuarioId IS NOT NULL
    BEGIN
        DECLARE @DescripcionUsuario varchar(500);
        SET @DescripcionUsuario = 'USUARIO_' + CAST(@UsuarioId AS varchar(20));

        SELECT TOP 1 @IdPerfilUsuario = Id
        FROM dbo.Indicador
        WHERE CompaniaId = @CompaniaId
          AND Area = 'SEGURIDAD'
          AND TipoIndicador = 91
          AND Descripcion = @DescripcionUsuario
        ORDER BY Id DESC;

        IF @IdPerfilUsuario IS NULL AND @Operacion = 'GUARDAR'
        BEGIN
            INSERT INTO dbo.Indicador
                (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
            VALUES
                (@CompaniaId, 'SEGURIDAD', 91, @IdPerfilArea,
                 @DescripcionUsuario, CAST(@UsuarioId AS varchar(20)), NULL);
            SET @IdPerfilUsuario = SCOPE_IDENTITY();
        END;
    END;

    IF @Operacion = 'GUARDAR'
    BEGIN
        IF NULLIF(LTRIM(RTRIM(@Permisos)), '') IS NULL
        BEGIN
            RAISERROR('Permisos es obligatorio.', 16, 1);
            RETURN;
        END;

        DECLARE @Solicitados TABLE
        (
            Codigo varchar(100) NOT NULL PRIMARY KEY,
            Permitido int NULL
        );

        DECLARE @PermisosXml xml;
        SET @PermisosXml = CONVERT(xml, '<r><i>' + REPLACE(@Permisos, '|', '</i><i>') + '</i></r>');

        INSERT INTO @Solicitados (Codigo, Permitido)
        SELECT UPPER(LTRIM(RTRIM(LEFT(Item, CHARINDEX('=', Item + '=') - 1)))),
               CASE RIGHT(Item, 1) WHEN '1' THEN 1 WHEN '0' THEN 0 ELSE NULL END
        FROM
        (
            SELECT LTRIM(RTRIM(Nodo.value('.', 'varchar(150)'))) AS Item
            FROM @PermisosXml.nodes('/r/i') AS T(Nodo)
        ) AS Valores
        WHERE CHARINDEX('=', Item) > 1;

        IF @UsuarioId IS NULL AND EXISTS (SELECT 1 FROM @Solicitados WHERE Permitido IS NULL)
        BEGIN
            RAISERROR('El perfil del área requiere permisos permitidos o denegados.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM @Solicitados s LEFT JOIN @Catalogo c ON c.Codigo = s.Codigo WHERE c.Codigo IS NULL)
        BEGIN
            RAISERROR('Se recibió un código de permiso no permitido.', 16, 1);
            RETURN;
        END;

        IF (SELECT COUNT(*) FROM @Solicitados) <> (SELECT COUNT(*) FROM @Catalogo)
        BEGIN
            RAISERROR('Debe guardar el catálogo completo de permisos.', 16, 1);
            RETURN;
        END;

        DECLARE @IdDestino int;
        SET @IdDestino = COALESCE(@IdPerfilUsuario, @IdPerfilArea);

        BEGIN TRANSACTION;
        DELETE destino FROM dbo.Indicador AS destino
        INNER JOIN @Solicitados AS s ON destino.Descripcion = 'PERMISO.' + s.Codigo
        WHERE destino.CompaniaId = @CompaniaId AND destino.Area = 'SEGURIDAD'
          AND destino.TipoIndicador = 92 AND destino.IdIndicador = @IdDestino
          AND s.Permitido IS NULL;

        MERGE dbo.Indicador AS destino
        USING (SELECT Codigo, Permitido FROM @Solicitados WHERE Permitido IS NOT NULL) AS origen
          ON destino.CompaniaId = @CompaniaId
         AND destino.Area = 'SEGURIDAD'
         AND destino.TipoIndicador = 92
         AND destino.IdIndicador = @IdDestino
         AND destino.Descripcion = 'PERMISO.' + origen.Codigo
        WHEN MATCHED THEN
            UPDATE SET ValorNum = origen.Permitido,
                       ValorTexto1 = origen.Codigo,
                       FechaActualizacion = GETUTCDATE()
        WHEN NOT MATCHED THEN
            INSERT (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
            VALUES (@CompaniaId, 'SEGURIDAD', 92, @IdDestino,
                    'PERMISO.' + origen.Codigo, origen.Codigo, origen.Permitido);

        COMMIT TRANSACTION;
        SELECT @AreaId AS AreaId, @UsuarioId AS UsuarioId;
        RETURN;
    END;

    IF @Operacion NOT IN ('OBTENER', 'EFECTIVOS')
    BEGIN
        RAISERROR('Operación de permisos no válida.', 16, 1);
        RETURN;
    END;

    WITH PerfilArea AS
    (
        SELECT REPLACE(Descripcion, 'PERMISO.', '') AS Codigo, ValorNum AS Permitido
        FROM dbo.Indicador
        WHERE CompaniaId = @CompaniaId AND Area = 'SEGURIDAD'
          AND TipoIndicador = 92 AND IdIndicador = @IdPerfilArea
    ), PerfilUsuario AS
    (
        SELECT REPLACE(Descripcion, 'PERMISO.', '') AS Codigo, ValorNum AS Permitido
        FROM dbo.Indicador
        WHERE CompaniaId = @CompaniaId AND Area = 'SEGURIDAD'
          AND TipoIndicador = 92 AND IdIndicador = @IdPerfilUsuario
    ), Resultado AS
    (
        SELECT c.Codigo,
               CONVERT(bit, COALESCE(u.Permitido, a.Permitido, 0)) AS Permitido,
               CONVERT(bit, COALESCE(a.Permitido, 0)) AS PermisoArea,
               CONVERT(bit, u.Permitido) AS ExcepcionUsuario
        FROM @Catalogo c
        LEFT JOIN PerfilArea a ON a.Codigo = c.Codigo
        LEFT JOIN PerfilUsuario u ON u.Codigo = c.Codigo
    )
    SELECT Codigo, Permitido, PermisoArea, ExcepcionUsuario
    FROM Resultado
    WHERE @Operacion = 'OBTENER' OR Permitido = 1
    ORDER BY Codigo;
END;
GO

