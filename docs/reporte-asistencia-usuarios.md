# Reporte de asistencia Web

## Propósito

Consultar las marcaciones de asistencia por personal o de todo el personal en un rango de fechas, con opción de imprimir el resultado. El reporte conserva los campos que aparecen en la sección **Reporte de asistencia del día** del cierre de caja.

## Uso

- Abrir **Reportes > Reporte de asistencia Web**.
- Seleccionar **Reporte General** para consultar a todo el personal, o desmarcarlo y elegir una persona.
- Elegir **Fecha inicio** y **Fecha fin**, y pulsar **Buscar**. El rango inicial cubre el mes actual completo.
- **Limpiar** restablece el rango inicial, activa Reporte General y descarta los resultados mostrados.
- **Imprimir** prepara una versión horizontal con todas las filas consultadas, sin limitarse a la página actual de la tabla.
- Buscar en la tabla por nombre, `PersonalId` o estado.

La pantalla muestra fecha, día, personal, ingreso, salida a refrigerio, retorno, salida, cantidad de tardanzas y estado de asistencia, además del total de días trabajados en las filas consultadas. La paginación, búsqueda y tamaño de tabla usan el componente compartido `DataTable`.

## API y permisos

- `GET /api/v1/AttendanceReport?fecha=YYYY-MM-DD` conserva la consulta de un día utilizada por los PDF de caja.
- `GET /api/v1/AttendanceReport?fechaInicio=YYYY-MM-DD&fechaFin=YYYY-MM-DD&personalId={id}` consulta un rango para una persona; `personalId` se omite para todas.
- `GET /api/v1/AttendanceReport/personas` entrega el personal activo disponible en el selector.
- Requiere el permiso `VENTAS.VER`; los administradores mantienen acceso.
- La consulta de un día ejecuta `dbo.uspAsistenciaListaCsvBWeb` y adapta su respuesta delimitada a JSON. El procedimiento tiene sufijo `Web` para mantener independiente el procedimiento usado por escritorio. La consulta por rango devuelve las mismas columnas directamente en JSON.
- Aplicar `scripts/sql/20261012_create_uspAsistenciaListaCsvBWeb.sql` en la base de datos para instalar el procedimiento del reporte web.

El mismo endpoint alimenta la sección de asistencia incluida en los PDF de cierre de caja e informe final.

## Alcance de los datos

El procedimiento filtra el día como un rango (`>= fecha` y `< día siguiente`) para incluir filas cuya columna `Fecha` conserva la hora de marcación. Incluye administradores y demás usuarios vinculados a personal; omite personas sin usuario asociado. Los nombres los construye con el primer nombre y el primer apellido. `HoraREF` representa una bandera de tardanza en refrigerio (`T`/`A`), no una hora.
