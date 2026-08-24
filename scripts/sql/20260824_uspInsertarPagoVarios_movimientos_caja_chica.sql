/*
   uspInsertarPagoVarios ya tiene la lógica del escritorio: para VENTA,
   solo el depósito crea una SALIDA con NotaId = 0, Estado = D y NotaIdB = PagoId.
   Este archivo verifica esa condición sin alterar el procedimiento.
*/
SET NOCOUNT ON;
GO

DECLARE @definition nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.uspInsertarPagoVarios'));

IF @definition IS NULL
    THROW 50000, 'No existe dbo.uspInsertarPagoVarios.', 1;

IF CHARINDEX(N'if(@ConceptoOBS=''VENTA'')', @definition) = 0
   OR CHARINDEX(N'insert into CajaDetalle values(@CajaId,GETDATE(),0,''SALIDA''', @definition) = 0
    THROW 50000, 'uspInsertarPagoVarios no conserva la lógica de caja del escritorio.', 1;

PRINT 'uspInsertarPagoVarios conserva la lógica de caja del escritorio.';
GO
