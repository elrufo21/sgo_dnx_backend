# PDT Empresa web

## Propósito

El módulo PDT Empresa consulta procedimientos exclusivos de la web, sin modificar los procedimientos usados por el escritorio.

## Procedimientos

- `dbo.LDdocumentosweb`: recibe `@FechaInicio` y `@FechaFin`, y devuelve las ventas en el formato delimitado que usa PDT Empresa.
- `dbo.uspListarComprasweb`: lista compras paginadas. Incluye `CompraPercepcion` como `NULL` porque la columna no existe en la base D2108 actual, manteniendo el contrato de la API.

## Aplicación

Ejecutar los scripts de `scripts/sql` con fecha `20260825` antes de publicar o reiniciar la API. Los procedimientos originales no se modifican.
