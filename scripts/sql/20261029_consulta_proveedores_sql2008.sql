/* Consulta de solo lectura utilizada por GET /api/v1/Proveedor/list.
   No crea ni modifica objetos. Ajustar los parametros para diagnostico. */
DECLARE @Estado varchar(20) = 'ACTIVO';
DECLARE @Offset bigint = 0;
DECLARE @PageSize int = 50;

SELECT ProveedorId, ProveedorRazon, ProveedorRuc, ProveedorContacto, ProveedorCelular,
       ProveedorTelefono, ProveedorCorreo, ProveedorDireccion, ProveedorEstado
FROM (
    SELECT ProveedorId, ProveedorRazon, ProveedorRuc, ProveedorContacto, ProveedorCelular,
           ProveedorTelefono, ProveedorCorreo, ProveedorDireccion, ProveedorEstado,
           ROW_NUMBER() OVER (ORDER BY ProveedorId DESC) AS NumeroFila
    FROM Proveedor
    WHERE (@Estado IS NULL OR ProveedorEstado = @Estado)
) AS proveedores
WHERE NumeroFila > @Offset AND NumeroFila <= @Offset + @PageSize
ORDER BY NumeroFila;
