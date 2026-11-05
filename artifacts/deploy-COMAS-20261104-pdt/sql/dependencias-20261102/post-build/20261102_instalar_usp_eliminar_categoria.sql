-- Seleccionar y verificar la base de destino antes de ejecutar.
-- Compatible con SQL Server 2008 R2; no reemplaza procedimientos existentes.
IF OBJECT_ID(N'dbo.Sublinea', N'U') IS NULL
   OR COL_LENGTH(N'dbo.Sublinea', N'IdSubLinea') IS NULL
BEGIN
    RAISERROR('Revise dbo.Sublinea y su columna IdSubLinea antes de instalar.', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'dbo.uspEliminarCategoria', N'P') IS NULL
BEGIN
    EXEC(N'CREATE PROCEDURE [dbo].[uspEliminarCategoria]
@Id int
AS
BEGIN TRY
    DELETE FROM dbo.Sublinea WHERE IdSubLinea = @Id;
END TRY
BEGIN CATCH
    DECLARE @ErrorNum INT = ERROR_NUMBER();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    IF (@ErrorNum = 547 AND @ErrorSeverity = 16)
        PRINT ''No se pudo eliminar, ya que tiene relacion con otros modulos'';
END CATCH');
    PRINT 'Se instaló dbo.uspEliminarCategoria.';
END
ELSE
    PRINT 'dbo.uspEliminarCategoria ya existe; no se modificó.';
