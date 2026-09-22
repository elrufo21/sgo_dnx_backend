# Migración de DXN_ICA

## Propósito

Adaptar `DXN_ICA` tomando exclusivamente `DXN_CUSCO_D0109` como base funcional. El backend también está en adaptación, por lo que sus contratos que no existen en la base de referencia quedan fuera de esta migración.

## Script final

Ejecutar [20260919_adaptar_dxn_ica_backend_completo.sql](../scripts/sql/20260919_adaptar_dxn_ica_backend_completo.sql).

El script:

- incorpora únicamente las columnas de `DXN_CUSCO_D0109` que faltan en `DXN_ICA`;
- incluye dentro del archivo las definiciones completas de los 40 procedimientos que difieren de la base de referencia y `listaNotaPedido`, requerido por la API de notas;
- restaura cuatro relaciones con `Producto` y `NotaPedido`, después de validar que no existen datos huérfanos;
- crea o completa la tabla recursiva `Indicador` y registra por compañía los flags `MULTIPLES_CAJAS`, `CAPTURA_HTML` y `BOLETA_POR_LOTE`;
- conserva los objetos adicionales de `DXN_ICA` y no copia ni elimina datos de negocio.

No se agregan columnas ni procedimientos que existan solamente en el backend adaptado. `Indicador` es la única ampliación fuera de `DXN_CUSCO_D0109`, porque fue solicitada expresamente para la configuración de la migración.

`DetalleGuiaLiquida.IdProducto` se alinea a `numeric(20,0)` únicamente si todos sus valores caben en ese tipo. `TipoComprobante.TipoDescripcion` permanece como `varchar(max)` porque existen valores mayores de 80 caracteres y el tipo amplio es compatible con el backend.

## Uso

1. Respaldar `DXN_ICA`.
2. Ejecutar el script completo en producción con una cuenta que pueda modificar `DXN_ICA`.
3. Comprobar que el resultado final indique `OK`, `41` procedimientos incluidos y la cantidad de flags creados.

El archivo es autónomo: `DXN_CUSCO_D0109` no necesita existir en el servidor de producción.

La migración se ejecuta dentro de una transacción, es idempotente para columnas y configuraciones, y usa `CREATE OR ALTER` para módulos. Requiere SQL Server 2016 SP1 o posterior. Los únicos datos agregados son los registros idempotentes de `Indicador`.

## Validación realizada

El 19 de septiembre de 2026 se ejecutó el paquete autónomo completo sobre `DXN_ICA` dentro de una transacción externa y se hizo `ROLLBACK`. Terminó con `OK`, 40 procedimientos incluidos y 3 flags, sin dejar cambios persistentes.
