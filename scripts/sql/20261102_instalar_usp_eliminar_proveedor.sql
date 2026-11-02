-- Seleccionar y verificar la base de destino antes de ejecutar.
-- Compatible con SQL Server 2008 R2; no reemplaza procedimientos existentes.
IF OBJECT_ID(N'dbo.Proveedor', N'U') IS NULL
   OR COL_LENGTH(N'dbo.Proveedor', N'ProveedorId') IS NULL
BEGIN
    RAISERROR('Revise dbo.Proveedor y su columna ProveedorId antes de instalar.', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'dbo.uspEliminarProveedor', N'P') IS NULL
BEGIN
    EXEC(N'CREATE PROCEDURE [dbo].[uspEliminarProveedor]
@Id int
AS
BEGIN TRY
    DELETE FROM dbo.Proveedor WHERE ProveedorId = @Id;
END TRY
BEGIN CATCH
    DECLARE @ErrorNum INT = ERROR_NUMBER();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    IF (@ErrorNum = 547 AND @ErrorSeverity = 16)
        PRINT ''No se pudo eliminar, ya que tiene relacion con otros modulos'';
END CATCH');
    PRINT 'Se instaló dbo.uspEliminarProveedor.';
END
ELSE
    PRINT 'dbo.uspEliminarProveedor ya existe; no se modificó.';
