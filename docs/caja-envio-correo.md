# Envío del cierre de caja por correo

## Propósito

Enviar automáticamente por correo el reporte PDF cuando una caja se cierra por primera vez. Si se edita una caja ya cerrada, regenerar y enviar el PDF únicamente cuando los datos del reporte hayan cambiado.

## Uso

En **Configuración > Caja**, registrar los destinatarios. Al cerrar una caja por primera vez, el sistema genera el PDF y lo envía automáticamente a las direcciones del indicador `dbo.Indicador` de la compañía, identificado por `Area = 'CORREO'`, `TipoIndicador = 3`, `IdIndicador IS NULL` y `Descripcion = 'CORREOS_ADMIN'`. No depende del `Id` autoincremental de la fila; se usa la descripción para distinguir este valor de los otros indicadores de correo, que comparten tipo y padre. Al guardar cambios en una caja cerrada, vuelve a generar y enviar el reporte solo si cambió alguno de sus datos. El botón de correo permanece disponible para reintentar manualmente si el envío automático falla. Admite varias direcciones separadas por coma o punto y coma.

En esa misma vista, **Permitir múltiples cajas abiertas** administra el indicador `dbo.Indicador` con `Area = 'CAJA'` y `Descripcion = 'MULTIPLES_CAJAS'`: `ValorNum = 0` permite una sola caja activa por compañía y oculta el módulo **Generar informe final**; `ValorNum = 1` permite varias cajas activas y muestra el módulo en el menú. **Exigir asistencia** administra el indicador `ASISTENCIA` de esa compañía: activado, ventas web y escrituras de Caja requieren asistencia del día; desactivado, esas validaciones no bloquean. La API conserva `FlagCaja` como nombre del campo de configuración que recibe y devuelve, pero el dato persistido está en `Indicador`, no en una columna de `Compania`.

Toda la configuración de **Configuración > Caja** solo se puede editar cuando no queda ninguna caja en estado `ACTIVO` para la compañía. La web consulta ese estado y deshabilita los campos y el guardado mientras haya una caja abierta. El endpoint de estado es informativo; el `PATCH /api/v1/Compania/{id}/caja-configuracion` vuelve a revisar el estado dentro de una transacción serializable y responde `409 Conflict` si hay cajas abiertas, para cubrir datos desactualizados y llamadas directas a la API. El resto de los indicadores de compañía no está sujeto a esta regla.

El asunto conserva el formato del escritorio: `DXN CIERRE DE CAJA GENERAL DEL DIA dd-MM-yyyy`. El encabezado del correo muestra primero el nombre comercial de la compañía y usa la razón social como alternativa, seguido del saludo, la indicación del PDF adjunto, el diferencial con su monto y la observación ingresada en el formulario. La firma muestra el primer nombre y apellido del responsable de la caja. Para el informe final se aplica la misma plantilla y se incluye su observación.

## Alcance técnico

- El endpoint `POST /api/v1/Correo/enviar-cierre-caja` requiere sesión autenticada.
- `Indicador.MULTIPLES_CAJAS` controla el límite de cajas activas y se valida en los procedimientos propios de DNX (`uspCajaInsertaCsvWeb` y `uspValidaCantCajasWeb`). Su valor inicial es `0`; los procedimientos heredados no se modifican.
- Antes de abrir, la API también valida si el usuario ya tiene una caja activa para devolver un mensaje útil sin intentar crear otra.
- El destinatario se obtiene únicamente de `dbo.Indicador.CORREOS_ADMIN`, identificando la compañía desde la caja y filtrando por área, tipo y padre; no se depende del ID autoincremental ni se recibe desde el navegador.
- Se usa exclusivamente `EmailSettings` para la conexión SMTP, que mantiene las mismas credenciales de correo de SGO. No se usa ninguna credencial SUNAT/OSE.
- Se acepta un único PDF de hasta 10 MB.

## Base de datos

La configuración del indicador se instala junto con la estructura/configuración de `dbo.Indicador`; ver [tabla-indicador.md](tabla-indicador.md) y [procedimientos-web.md](procedimientos-web.md). Los scripts `20260829_compania_flag_caja.sql` y `20260829_flag_caja_multiples_cajas.sql` pertenecen a la implementación antigua basada en `Compania.FlagCaja`; no se deben usar para esta versión.
