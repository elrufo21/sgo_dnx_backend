# Envío del cierre de caja por correo

## Propósito

Permitir que una caja cerrada envíe por correo su mismo reporte PDF generado en la web.

## Uso

En **Configuración > Caja**, registrar los destinatarios. En la pantalla de una caja cerrada siempre aparecerá el botón con el ícono de correo, sin depender del indicador `MULTIPLES_CAJAS`, para permitir reintentos ante fallas de conexión. El sistema genera el PDF del cierre y lo envía a las direcciones configuradas en `Compania.CorreosAdmin`. Admite varias direcciones separadas por coma o punto y coma.

En esa misma vista, **Permitir múltiples cajas abiertas** administra el indicador `dbo.Indicador` con `Area = 'CAJA'` y `Descripcion = 'MULTIPLES_CAJAS'`: `ValorNum = 0` permite una sola caja activa por compañía y oculta el módulo **Generar informe final**; `ValorNum = 1` permite varias cajas activas y muestra el módulo en el menú. La API conserva `FlagCaja` como nombre del campo de configuración que recibe y devuelve, pero el dato persistido está en `Indicador`, no en una columna de `Compania`.

El asunto conserva el formato del escritorio: `DXN CIERRE DE CAJA GENERAL DEL DIA dd-MM-yyyy`. El correo usa una plantilla HTML con el número de caja, fecha, estado del cuadre, detalle de la diferencia y el aviso del PDF adjunto. La firma muestra el primer nombre y apellido del responsable de la caja.

## Alcance técnico

- El endpoint `POST /api/v1/Correo/enviar-cierre-caja` requiere sesión autenticada.
- `Indicador.MULTIPLES_CAJAS` controla el límite de cajas activas y se valida en los procedimientos propios de DNX (`uspCajaInsertaCsvWeb` y `uspValidaCantCajasWeb`). Su valor inicial es `0`; los procedimientos heredados no se modifican.
- Antes de abrir, la API también valida si el usuario ya tiene una caja activa para devolver un mensaje útil sin intentar crear otra.
- El destinatario se obtiene únicamente de `Compania.CorreosAdmin`, identificando la compañía desde la caja; no se recibe desde el navegador.
- Se usa exclusivamente `EmailSettings` para la conexión SMTP, que mantiene las mismas credenciales de correo de SGO. No se usa ninguna credencial SUNAT/OSE.
- Se acepta un único PDF de hasta 10 MB.

## Base de datos

La configuración del indicador se instala junto con la estructura/configuración de `dbo.Indicador`; ver [tabla-indicador.md](tabla-indicador.md) y [procedimientos-web.md](procedimientos-web.md). Los scripts `20260829_compania_flag_caja.sql` y `20260829_flag_caja_multiples_cajas.sql` pertenecen a la implementación antigua basada en `Compania.FlagCaja`; no se deben usar para esta versión.
