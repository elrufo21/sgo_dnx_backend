/* Referencia de las consultas parametrizadas utilizadas por la API.
   No ejecutar por separado: la API valida la caja activa y la imagen,
   y ejecuta ambas consultas en una transaccion. No se modifica ningun objeto SQL.

SELECT ISNULL(RutaImagen, '') FROM CajaDetalle WITH (UPDLOCK, HOLDLOCK)
 WHERE DetalleId = @DetalleId AND CajaId = @CajaId
   AND ISNULL(NotaId, 0) = 0 AND ISNULL(Vista, '') = '';

UPDATE CajaDetalle SET RutaImagen = @RutaImagen
 WHERE DetalleId = @DetalleId AND CajaId = @CajaId
   AND ISNULL(NotaId, 0) = 0 AND ISNULL(Vista, '') = ''
   AND ISNULL(RutaImagen, '') = '';
*/
