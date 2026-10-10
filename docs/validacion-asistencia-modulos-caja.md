# Validación de asistencia en Caja

## Propósito

Replicar en las operaciones web de Caja la validación que se ejecuta al guardar una captura de venta: cada operación de escritura requiere que el usuario autenticado tenga asistencia registrada para el día actual.

## Regla

El backend busca una fila en `dbo.Asistencia` para el `PersonalId` asociado al claim `userId` de la sesión y con `Fecha = CONVERT(date, GETDATE())`, igual que la validación de ventas web. Si no existe, responde HTTP 409 con el código `ASISTENCIA_REQUERIDA` y el mensaje `NO PODRÁ REALIZAR NINGUNA OPERACIÓN EN CAJA PORQUE NO MARCÓ SU ASISTENCIA.`

## Alcance

El filtro común `RequireAttendance` bloquea las solicitudes de escritura en:

- Control de flujo de caja: abrir, cerrar, editar, reactivar y eliminar.
- Caja Chica: registrar movimientos, adjuntar imágenes y eliminar movimientos.
- Depósitos centros: registrar/actualizar comprobantes y eliminar depósitos.
- Informe final de caja: registrar o editar el informe y enviar sus correos.
- Extraer Ventas OBS/IOC: guardar o actualizar la extracción.

Las consultas `GET` permanecen disponibles para revisar datos. La validación usa el usuario autenticado, no el encargado que se seleccione en el formulario. No modifica los procedimientos almacenados ni las validaciones de escritorio.

## Implementación

El filtro está en `src/Api/Security/RequireAttendanceAttribute.cs` y se aplica a los controladores y acciones de escritura de Caja. La validación existente de ventas sigue en `dbo.uspinsertarNotaBweb`.
