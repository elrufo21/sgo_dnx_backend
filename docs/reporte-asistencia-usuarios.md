# Reporte de asistencia Web

## Propósito

Consultar las marcaciones de asistencia de los usuarios en una fecha y mostrar los datos que aparecen en la sección **Reporte de asistencia del día** del cierre de caja.

## Uso

- Abrir **Reportes > Reporte de asistencia Web**.
- Seleccionar la fecha en el calendario (formato `DD/MM/YY`); el listado se actualiza automáticamente.
- Buscar en la tabla por nombre o `PersonalId`.

La pantalla muestra ingreso, salida a refrigerio, retorno, salida, estado de asistencia, cantidad de tardanzas y si el refrigerio superó 60 minutos. La paginación, búsqueda y tamaño de tabla usan el componente compartido `DataTable`.

## API y permisos

- `GET /api/v1/AttendanceReport?fecha=YYYY-MM-DD`
- Requiere el permiso `VENTAS.VER`; los administradores mantienen acceso.
- El backend web consulta `dbo.uspAsistenciaListaCsvBWeb` con la fecha seleccionada y adapta su respuesta delimitada a JSON. El procedimiento tiene sufijo `Web` para mantener independiente el procedimiento usado por escritorio.
- Aplicar `scripts/sql/20261012_create_uspAsistenciaListaCsvBWeb.sql` en la base de datos para instalar el procedimiento del reporte web.

El mismo endpoint alimenta la sección de asistencia incluida en los PDF de cierre de caja e informe final.

## Alcance de los datos

El procedimiento filtra el día como un rango (`>= fecha` y `< día siguiente`) para incluir filas cuya columna `Fecha` conserva la hora de marcación. Incluye administradores y demás usuarios vinculados a personal; omite personas sin usuario asociado. Los nombres los construye con el primer nombre y el primer apellido. `HoraREF` representa una bandera de tardanza en refrigerio (`T`/`A`), no una hora.
