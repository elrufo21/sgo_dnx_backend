# Optimizacion de Caja y Facturas de servicio — 20/10/2026

Compatible con SQL Server 2008 R2. Sirve para ICA y COMAS cuando ya tienen el esquema web migrado, incluyendo `DocumentoVentaCpeWeb`. Los archivos no contienen `USE`: seleccionar y verificar la base destino en SSMS antes de ejecutar cada uno. No ejecutar en otra base por defecto.

## Orden de aplicacion

1. `01_indices_listados.sql`: indices de acceso para fechas de Caja, monedas, movimientos, cruces OBS, documentos y detalles. Omite indices equivalentes por prefijo de claves habilitadas y sin filtro, aunque tengan otro nombre. La creacion de indices puede bloquear temporalmente escrituras; coordinar la ejecucion con el administrador SQL.
2. `02_procedimiento_caja.sql`: crea/actualiza `dbo.uspListarControlCajaWeb`. Filtra, pagina y calcula las diferencias solo para cajas cerradas de la pagina. No modifica `listarCajaWEB`, `listarCajaFechaWEB` ni los procedimientos de cierre.
3. `03_procedimiento_facturas_servicio.sql`: crea/actualiza `dbo.uspListarFacturasServicioWeb`. Filtra candidatos por tipo/fecha/compania, conserva los criterios historicos de servicio y obtiene los datos complementarios solo para la pagina. Conserva el modo de documentos pendientes OSE.
4. Despues de aplicar 01–03, publicar juntos el backend y el frontend actualizados. La nueva API requiere ambos procedimientos. Verificar la misma entrega en cada base/servidor por separado.

`04_reversion.sql` NO forma parte de la instalacion. Para revertir, publicar primero la API y el frontend anteriores; despues se puede ejecutar este archivo para retirar solo los objetos nuevos de esta entrega.

No se alteran columnas, estados SUNAT, credenciales ni valores de Indicador. Los procedimientos son de lectura: las inserciones/borrados internos ocurren exclusivamente en tablas temporales o variables de tabla. Los indices y procedimientos si crean objetos SQL; esta entrega solo prepara los archivos y no los ejecuta.

## Contratos

- Caja: `GET /api/v1/CashFlow?fechaInicio=2026-10-01&fechaFin=2026-10-31&page=1&pageSize=50&buscar=LIZ` devuelve `{ items, totalRows, page, pageSize }`. Sin `page`, conserva la respuesta de tipo array para clientes anteriores y usa el mismo rango/default mensual.
- Facturas: `GET /api/v1/Nota/facturas-servicio?fechaInicio=2026-10-01&fechaFin=2026-10-31&page=1&pageSize=50&buscar=servicio` conserva `{ ok, page, pageSize, items }` y agrega `totalRows`.
- La fecha final incluye todo ese dia. La busqueda tiene hasta 150 caracteres, admite varias palabras, y compara sin distinguir mayusculas ni acentos. La pagina maxima de la API es de 200 registros.
- Los importes de Caja salen como numeros. La diferencia de una caja cerrada conserva la formula: contado - (inicial + OBS + IOC - salidas + ingresos manuales). `TOTAL EFECTIVO` y `SENCILLO` no se duplican. Una caja abierta conserva CajaTotal - CajaIngresos.
- Facturas conserva la preferencia de nota de credito enviada y luego de mayor ID. Resuelve las referencias historicas con espacios en temporales, sin actualizar documentos. El conteo de detalles no se multiplica por relaciones a notas de credito.
- Una pagina de facturas fuera del rango devuelve `items: []`, permitiendo terminar la iteracion de Despacho cuando el total es multiplo exacto del tamano de pagina.

## Validaciones sin BD

Desde la carpeta del backend: `dotnet run --project scripts/verificar-listados-sql/VerificarListados.csproj -- .`. Analiza sintaxis con el parser SQL 2008, comprueba que el DML solo tenga destinos temporales, y cruza columnas con los snapshots locales disponibles (no representa un esquema de produccion actualizado).

Desde el frontend: `node --experimental-vm-modules scripts/verify-listados-optimizados.mjs`. Comprueba transporte simulado, paginacion, orden, errores, deduplicacion y cancelacion; no llama a una API.

Estas comprobaciones no ejecutan los procedimientos en una BD real ni garantizan un tiempo de respuesta concreto.
