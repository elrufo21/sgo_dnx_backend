/*
  =============================================================================
  Script compatible con SQL Server 2008 / 2008 R2
  Propósito:
    1. Instala el procedimiento dbo.usp_PermisoIndicador con sintaxis compatible
       (reemplaza CREATE OR ALTER, THROW, CONCAT, IIF por estándares de SQL 2008).
    2. Registra el catálogo completo de permisos para el Área de ADMINISTRACIÓN
       o GERENCIA Y ADMINISTRACION en dbo.Indicador.
  =============================================================================
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- 1. PROCEDIMIENTO COMPATIBLE CON SQL SERVER 2008
IF OBJECT_ID('dbo.usp_PermisoIndicador', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_PermisoIndicador;
GO

CREATE PROCEDURE dbo.usp_PermisoIndicador
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
          AND IdIndicador = @IdPerfilArea
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
            Permitido int NOT NULL
        );

        DECLARE @PermisosXml xml;
        SET @PermisosXml = CONVERT(xml, '<r><i>' + REPLACE(@Permisos, '|', '</i><i>') + '</i></r>');

        INSERT INTO @Solicitados (Codigo, Permitido)
        SELECT UPPER(LTRIM(RTRIM(LEFT(Item, CHARINDEX('=', Item + '=') - 1)))),
               CASE WHEN RIGHT(Item, 1) = '1' THEN 1 ELSE 0 END
        FROM
        (
            SELECT LTRIM(RTRIM(Nodo.value('.', 'varchar(150)'))) AS Item
            FROM @PermisosXml.nodes('/r/i') AS T(Nodo)
        ) AS Valores
        WHERE CHARINDEX('=', Item) > 1;

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

        MERGE dbo.Indicador AS destino
        USING @Solicitados AS origen
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

-- 2. ASIGNACIÓN DE PERMISOS PARA EL ÁREA DE ADMINISTRACIÓN
DECLARE @CompaniaId int;
SET @CompaniaId = 1;

DECLARE @AreaId int;
SELECT TOP 1 @AreaId = AreaId
FROM dbo.Area
WHERE AreaNombre = 'ADMINISTRACION'
   OR AreaNombre = 'GERENCIA Y ADMINISTRACION'
   OR AreaId = 6;

IF @AreaId IS NULL
BEGIN
    RAISERROR('No se encontró el área de ADMINISTRACION o GERENCIA Y ADMINISTRACION en dbo.Area.', 16, 1);
    RETURN;
END;

DECLARE @Permisos varchar(max);
SET @Permisos = 'VENTAS.VER=1|VENTAS.POS=1|VENTAS.CAPTURAR=1|VENTAS.LISTA=1|VENTAS.OBS=1|VENTAS.GUIA_REMISION=1|VENTAS.NOTA_PEDIDO=1|VENTAS.RESUMEN_BOLETAS=1|VENTAS.ANULAR=1|CAJA.VER=1|CAJA.CONTROL=1|CAJA.APERTURA=1|CAJA.INFORME_FINAL=1|CAJA.CHICA=1|CAJA.GESTIONAR=1|COMPRAS.GESTIONAR=1|FACTURAS_SERVICIO.GESTIONAR=1|CLIENTES.GESTIONAR=1|CONTABILIDAD.VER=1|CONTABILIDAD.PDT_EMPRESA=1|CONTABILIDAD.ENVIO_FACTURAS=1|CONTABILIDAD.RESUMEN_BOLETAS=1|MANTENIMIENTO.VER=1|MANTENIMIENTO.AREAS=1|MANTENIMIENTO.CATEGORIAS=1|MANTENIMIENTO.PROVEEDORES=1|MANTENIMIENTO.FERIADOS=1|MANTENIMIENTO.COMPUTADORAS=1|MANTENIMIENTO.PRODUCTOS=1|MANTENIMIENTO.EMPLEADOS=1|MANTENIMIENTO.USUARIOS=1|MANTENIMIENTO.RESUMEN_BOLETAS=1|CONFIGURACION.VER=1|CONFIGURACION.FACTURACION=1|CONFIGURACION.VENTAS_BOLETAS=1|CONFIGURACION.CAJA=1|CONFIGURACION.PERMISOS=1';

EXEC dbo.usp_PermisoIndicador
    @Operacion = 'GUARDAR',
    @CompaniaId = @CompaniaId,
    @AreaId = @AreaId,
    @UsuarioId = NULL,
    @Permisos = @Permisos;

PRINT 'Permisos del área de administración configurados correctamente.';
GO
