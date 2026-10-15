# Validación de asistencia en Caja

## Propósito

Replicar en las operaciones web de Caja la validación que se ejecuta al guardar una captura de venta: cada operación de escritura requiere que el usuario autenticado tenga asistencia registrada para el día actual.

## Regla

La configuración por compañía está en `dbo.Indicador`, `Area = 'CAJA'`, `Descripcion = 'ASISTENCIA'`, `TipoIndicador = 1`: `ValorNum = 1` exige asistencia y `ValorNum = 0` la omite. Si el indicador falta o tiene un valor nulo, la validación se mantiene activada para conservar el comportamiento actual.

Cuando está activada, el backend busca una fila en `dbo.Asistencia` para el `PersonalId` asociado al claim `userId` de la sesión y con `Fecha = CONVERT(date, GETDATE())`, igual que la validación de ventas web. Si no existe, responde HTTP 409 con el código `ASISTENCIA_REQUERIDA` y el mensaje `NO PODRÁ REALIZAR NINGUNA OPERACIÓN EN CAJA PORQUE NO MARCÓ SU ASISTENCIA.`

## Alcance

El filtro común `RequireAttendance` bloquea las solicitudes de escritura en:

- Control de flujo de caja: abrir, cerrar, editar, reactivar y eliminar.
- Caja Chica: registrar movimientos, adjuntar imágenes y eliminar movimientos.
- Depósitos centros: registrar/actualizar comprobantes y eliminar depósitos.
- Informe final de caja: registrar o editar el informe y enviar sus correos.
- Extraer Ventas OBS/IOC: guardar o actualizar la extracción.

Las consultas `GET` permanecen disponibles para revisar datos. La validación usa el usuario autenticado, no el encargado que se seleccione en el formulario. El flag solo cambia las validaciones web; los procedimientos de escritorio no se modifican.

## Implementación

El filtro está en `src/Api/Security/RequireAttendanceAttribute.cs` y se aplica a los controladores y acciones de escritura de Caja. La validación de ventas web está en `dbo.uspinsertarNotaBweb`. Configuración > Caja permite activar o desactivar el indicador. El script `scripts/sql/20261014_configurar_validacion_asistencia_indicador.sql` crea el flag activado para las compañías que aún no lo tienen y adapta el procedimiento de ventas.
