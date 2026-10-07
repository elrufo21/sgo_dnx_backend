# Búsqueda de clientes por RUC

## Propósito

Permitir que los formularios que capturan un RUC consulten únicamente el campo `ClienteRuc`. La búsqueda general de clientes continúa consultando código, razón social, RUC y DNI.

## Uso

`GET /api/v1/Cliente/list?estado=ACTIVO&search=1048&page=1&pageSize=20&rucOnly=true`

Con `rucOnly=true`, la API filtra las sugerencias exclusivamente por `ClienteRuc`. Sin ese parámetro, conserva la búsqueda general existente. El cliente debe exigir coincidencia exacta de los 11 dígitos antes de autoseleccionar un resultado.

## Alcance

El filtro vive en la consulta del repositorio; no agrega ni modifica tablas, índices ni procedimientos almacenados. Se usa para separar la búsqueda del campo RUC de la búsqueda general por DNI, nombre o código.
