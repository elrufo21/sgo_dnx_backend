/* Adaptador WEB: no crea tablas ni modifica procedimientos del escritorio. */
CREATE OR ALTER PROCEDURE dbo.uspInsertarConteoCajaWEB
    @ListaOrden varchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.uspInsertarConteoCaja @ListaOrden = @ListaOrden;
END;

GO

CREATE OR ALTER PROCEDURE dbo.uspEditarConteoCajaWEB
    @ListaOrden varchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.uspEditarConteoCaja @ListaOrden = @ListaOrden;
END;
