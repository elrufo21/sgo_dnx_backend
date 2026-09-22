# Tabla `Indicador`

## Propósito

`dbo.Indicador` concentra configuraciones organizadas por área y tipo. Su relación consigo misma permite modelar árboles de indicadores sin crear una tabla por nivel.

## Estructura

- `Id`: identificador correlativo.
- `CompaniaId`: compañía dueña de la configuración; puede ser `NULL` solo para una futura configuración global.
- `Area`: ámbito funcional de la configuración.
- `TipoIndicador`: clasificador numérico definido por la aplicación.
- `IdIndicador`: identificador del padre; `NULL` representa la raíz.
- `Descripcion`: nombre o detalle legible del indicador.
- `ValorTexto1` y `ValorNum`: valores configurables de texto y número.
- `FechaActualizacion`: fecha de creación o última actualización registrada por la aplicación.

La clave foránea evita padres inexistentes y el índice de `IdIndicador` soporta la navegación padre–hijo. La restricción impide que un registro sea su propio padre; los ciclos de varios niveles deben validarse en la lógica que actualice la jerarquía.

`TipoIndicador = 0` representa una categoría; `TipoIndicador = 1`, un flag booleano (`ValorNum = 0` desactiva y `1` activa); y `TipoIndicador = 2`, un valor numérico. `Descripcion` es la clave estable que consume la aplicación; `ValorTexto1` contiene la etiqueta legible.

## Uso

Ejecutar [20260918_crear_tabla_indicador.sql](../scripts/sql/20260918_crear_tabla_indicador.sql) en la instancia que contiene `DXN_ICA`. El script solo crea la tabla si aún no existe.

Para una tabla ya creada, ejecutar después [20260918_configurar_flags_indicador.sql](../scripts/sql/20260918_configurar_flags_indicador.sql). El script agrega el alcance por compañía y crea, desactivados por defecto, los flags `MULTIPLES_CAJAS`, `CAPTURA_HTML` y `BOLETA_POR_LOTE` bajo las categorías `CONFIGURACION_CAJA` y `CONFIGURACION_VENTAS`.

Para configurar los plazos de anulación, ejecutar [20260922_configurar_anulacion_indicador.sql](../scripts/sql/20260922_configurar_anulacion_indicador.sql). Agrega tres indicadores por compañía bajo `CONFIGURACION_VENTAS`, sin reemplazar valores existentes. Los plazos se pueden modificar actualizando `ValorNum` y `FechaActualizacion` del indicador y la compañía correspondientes.
