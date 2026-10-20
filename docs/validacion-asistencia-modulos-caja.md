# Validación de asistencia en Caja

## Propósito

Replicar en las operaciones web de Caja la validación que se ejecuta al guardar una captura de venta: cada operación de escritura requiere que el usuario correspondiente tenga asistencia registrada para el día actual.

## Regla

La configuración por compañía está en `dbo.Indicador`, `Area = 'CAJA'`, `Descripcion = 'ASISTENCIA'`, `TipoIndicador = 1`: `ValorNum = 1` exige asistencia y `ValorNum = 0` la omite. Si el indicador falta o tiene un valor nulo, la validación se mantiene activada para conservar el comportamiento actual.

Cuando está activada, el backend busca una fila en `dbo.Asistencia` para el `PersonalId` asociado al usuario correspondiente y con `Fecha = CONVERT(date, GETDATE())`, igual que la validación de ventas web. Al abrir, la asistencia se comprueba para el usuario seleccionado como encargado (`UsuarioId` del registro). Al cerrar, se comprueba para el dueño real de la caja leído por el backend; el identificador del request debe coincidir con ese dueño. Esto cubre a quien abre o cierra una caja ajena y evita confiar en un usuario distinto enviado por el navegador. En las demás operaciones se comprueba el usuario autenticado. Si no existe asistencia, responde HTTP 409 con el código `ASISTENCIA_REQUERIDA` y el mensaje `NO PODRÁ REALIZAR NINGUNA OPERACIÓN EN CAJA PORQUE NO MARCÓ SU ASISTENCIA.`

## Alcance

El filtro común `RequireAttendance` bloquea las solicitudes de escritura en:

- Control de flujo de caja: abrir, cerrar, editar, reactivar y eliminar.
- Caja Chica: registrar movimientos, adjuntar imágenes y eliminar movimientos.
- Depósitos centros: registrar/actualizar comprobantes y eliminar depósitos.
- Informe final de caja: registrar o editar el informe y enviar sus correos.
- Extraer Ventas OBS/IOC: guardar o actualizar la extracción.

Las consultas `GET` permanecen disponibles para revisar datos. Al abrir una caja, la validación usa el usuario seleccionado como encargado; al cerrar usa el propietario persistido de la caja; en las demás operaciones de Caja usa el usuario autenticado. El flag solo cambia las validaciones web; los procedimientos de escritorio no se modifican.

## Implementación

El filtro está en `src/Api/Security/RequireAttendanceAttribute.cs` y se aplica a los controladores y acciones de escritura de Caja. La validación de ventas web está en `dbo.uspinsertarNotaBweb`. Configuración > Caja permite activar o desactivar el indicador, filtrado por compañía, área `CAJA`, tipo `1` y `IdIndicador IS NULL`. El script `scripts/sql/20261014_configurar_validacion_asistencia_indicador.sql` crea el flag activado para las compañías que aún no lo tienen y adapta el procedimiento de ventas.

Las solicitudes de lectura (`GET`, `HEAD` y `OPTIONS`) no requieren asistencia, pero el filtro debe continuar la tubería de MVC con `await next()` para que se ejecute la acción. Si solo retorna, ASP.NET puede responder `200` sin cuerpo y dejar vacíos los listados.
