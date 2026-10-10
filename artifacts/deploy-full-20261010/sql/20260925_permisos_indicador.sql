/*
  Permisos por área y usuario, almacenados exclusivamente en dbo.Indicador.
  El perfil del usuario sobrescribe al perfil de su área. No se crean tablas.
*/
SET NOCOUNT ON;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_PermisoIndicador
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
        THROW 50001, 'CompaniaId y AreaId son obligatorios.', 1;

    DECLARE @AreaNombre varchar(100) =
        (SELECT TOP (1) AreaNombre FROM dbo.Area WHERE AreaId = @AreaId);

    IF @AreaNombre IS NULL
        THROW 50002, 'El área indicada no existe.', 1;

    IF @UsuarioId IS NOT NULL AND NOT EXISTS
    (
        SELECT 1
        FROM dbo.Usuarios U
        INNER JOIN dbo.Personal P ON P.PersonalId = U.PersonalId
        WHERE U.UsuarioID = @UsuarioId
          AND P.AreaId = @AreaId
          AND P.CompaniaId = @CompaniaId
    )
        THROW 50007, 'El usuario no pertenece al área o compañía indicada.', 1;

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

    DECLARE @DescripcionArea varchar(500) = CONCAT('PERMISOS_AREA_', @AreaId);
    DECLARE @IdPerfilArea int =
    (
        SELECT TOP (1) Id
        FROM dbo.Indicador
        WHERE CompaniaId = @CompaniaId
          AND Area = 'SEGURIDAD'
          AND TipoIndicador = 90
          AND IdIndicador IS NULL
          AND Descripcion = @DescripcionArea
        ORDER BY Id DESC
    );

    IF @IdPerfilArea IS NULL AND @Operacion = 'GUARDAR'
    BEGIN
        INSERT INTO dbo.Indicador
            (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
        VALUES
            (@CompaniaId, 'SEGURIDAD', 90, NULL, @DescripcionArea, @AreaNombre, NULL);
        SET @IdPerfilArea = SCOPE_IDENTITY();
    END;

    DECLARE @IdPerfilUsuario int = NULL;
    IF @UsuarioId IS NOT NULL
    BEGIN
        SET @IdPerfilUsuario =
        (
            SELECT TOP (1) Id
            FROM dbo.Indicador
            WHERE CompaniaId = @CompaniaId
              AND Area = 'SEGURIDAD'
              AND TipoIndicador = 91
              AND IdIndicador = @IdPerfilArea
              AND Descripcion = CONCAT('USUARIO_', @UsuarioId)
            ORDER BY Id DESC
        );

        IF @IdPerfilUsuario IS NULL AND @Operacion = 'GUARDAR'
        BEGIN
            INSERT INTO dbo.Indicador
                (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
            VALUES
                (@CompaniaId, 'SEGURIDAD', 91, @IdPerfilArea,
                 CONCAT('USUARIO_', @UsuarioId), CONVERT(varchar(20), @UsuarioId), NULL);
            SET @IdPerfilUsuario = SCOPE_IDENTITY();
        END;
    END;

    IF @Operacion = 'GUARDAR'
    BEGIN
        IF NULLIF(LTRIM(RTRIM(@Permisos)), '') IS NULL
            THROW 50003, 'Permisos es obligatorio.', 1;

        DECLARE @Solicitados TABLE
        (
            Codigo varchar(100) NOT NULL PRIMARY KEY,
            Permitido int NOT NULL
        );

        DECLARE @PermisosXml xml = CONVERT(xml, '<r><i>' + REPLACE(@Permisos, '|', '</i><i>') + '</i></r>');
        INSERT INTO @Solicitados (Codigo, Permitido)
        SELECT UPPER(LTRIM(RTRIM(LEFT(Item, CHARINDEX('=', Item + '=') - 1)))),
               IIF(RIGHT(Item, 1) = '1', 1, 0)
        FROM
        (
            SELECT LTRIM(RTRIM(Nodo.value('.', 'varchar(150)'))) AS Item
            FROM @PermisosXml.nodes('/r/i') AS T(Nodo)
        ) AS Valores
        WHERE CHARINDEX('=', Item) > 1;

        IF EXISTS (SELECT 1 FROM @Solicitados s LEFT JOIN @Catalogo c ON c.Codigo = s.Codigo WHERE c.Codigo IS NULL)
            THROW 50004, 'Se recibió un código de permiso no permitido.', 1;

        IF (SELECT COUNT(*) FROM @Solicitados) <> (SELECT COUNT(*) FROM @Catalogo)
            THROW 50005, 'Debe guardar el catálogo completo de permisos.', 1;

        DECLARE @IdDestino int = COALESCE(@IdPerfilUsuario, @IdPerfilArea);
        MERGE dbo.Indicador AS destino
        USING @Solicitados AS origen
          ON destino.CompaniaId = @CompaniaId
         AND destino.Area = 'SEGURIDAD'
         AND destino.TipoIndicador = 92
         AND destino.IdIndicador = @IdDestino
         AND destino.Descripcion = CONCAT('PERMISO.', origen.Codigo)
        WHEN MATCHED THEN
            UPDATE SET ValorNum = origen.Permitido,
                       ValorTexto1 = origen.Codigo,
                       FechaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN
            INSERT (CompaniaId, Area, TipoIndicador, IdIndicador, Descripcion, ValorTexto1, ValorNum)
            VALUES (@CompaniaId, 'SEGURIDAD', 92, @IdDestino,
                    CONCAT('PERMISO.', origen.Codigo), origen.Codigo, origen.Permitido);

        SELECT @AreaId AS AreaId, @UsuarioId AS UsuarioId;
        RETURN;
    END;

    IF @Operacion NOT IN ('OBTENER', 'EFECTIVOS')
        THROW 50006, 'Operación de permisos no válida.', 1;

    ;WITH PerfilArea AS
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
               CONVERT(bit, COALESCE(u.Permitido, a.Permitido, 0)) AS Permitido
        FROM @Catalogo c
        LEFT JOIN PerfilArea a ON a.Codigo = c.Codigo
        LEFT JOIN PerfilUsuario u ON u.Codigo = c.Codigo
    )
    SELECT Codigo, Permitido
    FROM Resultado
    WHERE @Operacion = 'OBTENER' OR Permitido = 1
    ORDER BY Codigo;
END;
GO
