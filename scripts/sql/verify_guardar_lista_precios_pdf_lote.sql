/* Verificación reversible: no deja productos ni kardex de prueba. */
SET QUOTED_IDENTIFIER ON;
GO
BEGIN TRANSACTION;

DECLARE @Productos xml = N'
<productos>
  <producto codigo="ZZ-CODEX-LOTE" nombre="ALOE V HYDRATING MASK" costo="168.00" observacion="PRUEBA" pv="1" sv="2" />
</productos>';

EXEC dbo.uspGuardarListaPreciosPdf @Productos, 'ANDRE RAMIREZ';

IF NOT EXISTS
(
    SELECT 1
    FROM Producto
    WHERE ProductoCodigo = 'ZZ-CODEX-LOTE'
      AND IdSubLinea = 1
      AND ProductoNombre = 'ALOE V HYDRATING MASK'
      AND ProductoMarca = 'DNX'
      AND ProductoCosto = 168
      AND ProductoVenta = 168
      AND ProductoINV = N'S'
      AND AlmacenId = 1
      AND ProductoUbicacion = ''
      AND ProductoUsuario = 'ANDRE RAMIREZ'
)
BEGIN
    RAISERROR('La verificación del lote no pasó.', 16, 1);
END;

SET @Productos = N'
<productos>
  <producto codigo="ZZ-CODEX-LOTE" nombre="ALOE V HYDRATING MASK ACTUALIZADO" costo="169.00" observacion="PRUEBA ACTUALIZADA" pv="3" sv="4" />
</productos>';

EXEC dbo.uspGuardarListaPreciosPdf @Productos, 'ANDRE RAMIREZ';

IF NOT EXISTS
(
    SELECT 1
    FROM Producto
    WHERE ProductoCodigo = 'ZZ-CODEX-LOTE'
      AND ProductoNombre = 'ALOE V HYDRATING MASK ACTUALIZADO'
      AND ProductoCosto = 169
      AND ProductoVenta = 169
      AND ProductoPV = 3
      AND ProductoSV = 4
)
BEGIN
    RAISERROR('La verificación de actualización del lote no pasó.', 16, 1);
END;

ROLLBACK TRANSACTION;
