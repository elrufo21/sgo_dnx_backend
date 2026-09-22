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

`TipoIndicador = 0` representa una categoría y `TipoIndicador = 1` representa un flag booleano: `ValorNum = 0` desactiva y `ValorNum = 1` activa. `Descripcion` es la clave estable que consumirá la aplicación; `ValorTexto1` contiene la etiqueta legible.

## Uso

Ejecutar [20260918_crear_tabla_indicador.sql](../scripts/sql/20260918_crear_tabla_indicador.sql) en la instancia que contiene `DXN_ICA`. El script solo crea la tabla si aún no existe.

Para una tabla ya creada, ejecutar después [20260918_configurar_flags_indicador.sql](../scripts/sql/20260918_configurar_flags_indicador.sql). El script agrega el alcance por compañía y crea, desactivados por defecto, los flags `MULTIPLES_CAJAS`, `CAPTURA_HTML` y `BOLETA_POR_LOTE` bajo las categorías `CONFIGURACION_CAJA` y `CONFIGURACION_VENTAS`.
