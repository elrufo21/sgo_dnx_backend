# PDT Empresa web

## Propósito

El módulo PDT Empresa consulta procedimientos exclusivos de la web, sin modificar los procedimientos usados por el escritorio.

La columna **Estado** usa `DocumentoVenta.DocuEstado`, excepto cuando la nota vinculada tiene `NotaPedido.NotaEstado = 'ANULADO'`; en ese caso muestra `ANULADO`. El reporte incluye documentos anulados dentro del rango. Las notas de crédito se muestran como filas separadas y con importes negativos. El procedimiento convierte a texto vacío o cero los datos nulos opcionales para evitar que la concatenación SQL omita la fila completa.

## Consulta de notas de crédito

`GET /api/v1/NotasCredito?fechaInicio=YYYY-MM-DD&fechaFin=YYYY-MM-DD` lista por fecha de emisión los documentos `TipoCodigo = '07'` de la compañía del usuario autenticado. `GET /api/v1/NotasCredito/{id}` devuelve la cabecera y las filas de `DetalleDocumento` de esa nota, cuando existen. Ambos requieren `CONTABILIDAD.VER`, son de solo lectura y no crean ni modifican objetos SQL. La descripción del detalle procede del producto vinculado; si no existe, se muestra vacía. La referencia procede de `DocuNroGuia`.

## Procedimientos

- `dbo.LDdocumentosweb`: recibe `@FechaInicio` y `@FechaFin`, y devuelve las ventas en el formato delimitado que usa PDT Empresa.
- `dbo.uspListarComprasweb`: lista compras paginadas. Incluye `CompraPercepcion` como `NULL` porque la columna no existe en la base D2108 actual, manteniendo el contrato de la API.

Para que los anulados aparezcan y el estado de la nota vinculada prevalezca en el PDT, ejecutar [20261007_pdt_empresa_estado_anulado.sql](../scripts/sql/20261007_pdt_empresa_estado_anulado.sql). Si se ejecutó una versión anterior de ese archivo, volver a ejecutar la versión actualizada.

## Aplicación

Ejecutar los scripts de `scripts/sql` con fecha `20260825` antes de publicar o reiniciar la API. Los procedimientos originales no se modifican.
