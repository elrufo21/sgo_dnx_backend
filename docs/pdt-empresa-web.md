# PDT Empresa web

## Propósito

El módulo PDT Empresa consulta procedimientos exclusivos de la web, sin modificar los procedimientos usados por el escritorio.

La columna **Estado** usa `DocumentoVenta.DocuEstado`, excepto cuando la nota vinculada tiene `NotaPedido.NotaEstado = 'ANULADO'`; en ese caso muestra `ANULADO`. El reporte incluye documentos anulados dentro del rango. Las notas de crédito se muestran como filas separadas y con importes negativos. El procedimiento convierte a texto vacío o cero los datos nulos opcionales para evitar que la concatenación SQL omita la fila completa.

## Procedimientos

- `dbo.LDdocumentosweb`: recibe `@FechaInicio` y `@FechaFin`, y devuelve las ventas en el formato delimitado que usa PDT Empresa.
- `dbo.uspListarComprasweb`: lista compras paginadas. Incluye `CompraPercepcion` como `NULL` porque la columna no existe en la base D2108 actual, manteniendo el contrato de la API.

Para que los anulados aparezcan y el estado de la nota vinculada prevalezca en el PDT, ejecutar [20261007_pdt_empresa_estado_anulado.sql](../scripts/sql/20261007_pdt_empresa_estado_anulado.sql). Si se ejecutó una versión anterior de ese archivo, volver a ejecutar la versión actualizada.

## Aplicación

Ejecutar los scripts de `scripts/sql` con fecha `20260825` antes de publicar o reiniciar la API. Los procedimientos originales no se modifican.
