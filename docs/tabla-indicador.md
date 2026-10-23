# Tabla `Indicador`

## Propósito

`dbo.Indicador` concentra configuraciones organizadas por área y tipo. Su relación consigo misma permite modelar árboles de indicadores sin crear una tabla por nivel.

## Estructura

- `Id`: identificador correlativo.
- `CompaniaId`: compañía dueña de la configuración; `NULL` identifica la configuración global del correo emisor.
- `Area`: ámbito funcional de la configuración.
- `TipoIndicador`: clasificador numérico definido por la aplicación.
- `IdIndicador`: identificador del padre; `NULL` representa la raíz.
- `Descripcion`: nombre o detalle legible del indicador.
- `ValorTexto1`, `ValorNum` y `ValorDecimal`: valores configurables de texto, enteros y decimales.
- `FechaActualizacion`: fecha de creación o última actualización registrada por la aplicación.

La clave foránea evita padres inexistentes y el índice de `IdIndicador` soporta la navegación padre–hijo. La restricción impide que un registro sea su propio padre; los ciclos de varios niveles deben validarse en la lógica que actualice la jerarquía.

`TipoIndicador = 0` representa una categoría; `TipoIndicador = 1`, un flag booleano (`ValorNum = 0` desactiva y `1` activa); `TipoIndicador = 2`, un valor numérico; y `TipoIndicador = 3`, texto o fecha en `ValorTexto1`.

## Clave que usa la aplicación

Los valores configurables pertenecen a una compañía y se identifican por `CompaniaId + Area + Descripcion`. Para indicadores raíz, `IdIndicador` debe ser `NULL`. `Id` es una identidad local de la base; no se copia ni se asigna manualmente entre ICA y COMAS. `TipoIndicador` describe el tipo de valor, no identifica por sí solo la opción.

Algunas opciones son hijas de una categoría. Por ejemplo, los plazos de anulación dependen de `CONFIGURACION_VENTAS`. Su identidad lógica incluye el nombre estable del padre; el `IdIndicador` guardado es el `Id` local de esa categoría en cada base. Los permisos (`TipoIndicador` 90, 91 y 92) también forman un árbol y quedan fuera de la normalización de opciones raíz.

La configuración global del correo emisor usa `CompaniaId IS NULL`, `Area = 'CORREO'`, `TipoIndicador = 3` e `IdIndicador IS NULL`; el correo se guarda en `ValorTexto1` y la contraseña de aplicación se guarda protegida en ese mismo campo. No se mezcla con los destinatarios `CORREOS_ADMIN`, que siguen siendo por compañía. El descuento máximo se guarda en `ValorDecimal` como importe en soles. Ver [configuración desde la web](configuracion-indicador-desde-web.md).

El backend filtra los indicadores por compañía, área, tipo, descripción y raíz o padre, según el contrato de cada opción. Así una fila mal clasificada no se interpreta como una configuración válida. Cada compañía conserva sus propios valores; normalizar no copia configuraciones de ICA a COMAS.

## Uso

`ListaProductosTabla` es un flag raíz de `VENTAS` por compañía que elige la presentación de productos en captura HTML: 0 mantiene el autocomplete y 1 activa Productos/Detalle con cantidades sincronizadas. Se inicializa en 0 mediante [20261022_configurar_lista_productos_tabla.sql](../scripts/sql/20261022_configurar_lista_productos_tabla.sql), conservando los demás indicadores. Ver [comportamiento e instalación](lista-productos-tabla.md).

Ejecutar [20260918_crear_tabla_indicador.sql](../scripts/sql/20260918_crear_tabla_indicador.sql) en la instancia que contiene `DXN_ICA`. El script solo crea la tabla si aún no existe.

Para una tabla ya creada, ejecutar después [20260918_configurar_flags_indicador.sql](../scripts/sql/20260918_configurar_flags_indicador.sql). El script agrega el alcance por compañía y crea los flags `MULTIPLES_CAJAS`, `CAPTURA_HTML` y `BOLETA_POR_LOTE` como indicadores raíz, desactivados por defecto. Las categorías `CONFIGURACION_CAJA` y `CONFIGURACION_VENTAS` se conservan donde otros indicadores jerárquicos las requieren.

El flag `ASISTENCIA` controla por compañía si la web exige marcación del día en ventas y operaciones de Caja. Se guarda con `Area = 'CAJA'`, `TipoIndicador = 1`, `ValorNum = 1` para exigirla y `0` para omitirla. El valor inicial es `1`. Ejecutar [20261014_configurar_validacion_asistencia_indicador.sql](../scripts/sql/20261014_configurar_validacion_asistencia_indicador.sql) después de instalar la estructura de `Indicador` y el procedimiento `uspinsertarNotaBweb`.

Para configurar los plazos de anulación, ejecutar [20260922_configurar_anulacion_indicador.sql](../scripts/sql/20260922_configurar_anulacion_indicador.sql). Agrega tres indicadores por compañía bajo `CONFIGURACION_VENTAS`, sin reemplazar valores existentes. Los plazos se pueden modificar actualizando `ValorNum` y `FechaActualizacion` del indicador y la compañía correspondientes.

Después de instalar o inicializar los indicadores y antes de publicar esta versión del backend, ejecutar [20261020_normalizar_indicadores_configuracion.sql](../scripts/sql/20261020_normalizar_indicadores_configuracion.sql) en cada base. Es compatible con SQL Server 2008 R2, conserva los valores y normaliza área, tipo y relación padre. Si detecta descripciones duplicadas o falta una categoría padre, se detiene para que una persona resuelva la ambigüedad; no escoge valores ni elimina filas automáticamente. No modifica la base desde la aplicación: su ejecución corresponde a quien administre SQL.
