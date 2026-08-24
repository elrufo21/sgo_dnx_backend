# Ubigeo y fecha de edición de NotaPedido

Fecha: 2026-08-24

## Alcance

Las notas creadas desde la web mediante `dbo.uspinsertarNotaBweb` guardan el código de ubigeo de su compañía (`Compania.CompaniaCodigoUBG`) en `NotaPedido.NotaDireccion`.

`FechaEdita` se guarda como texto vacío (`''`) al crear la nota. Solo debe contener una fecha cuando una edición o anulación la registre.

## Conservación de datos

La dirección recibida de la venta se conserva para actualizar `Cliente.ClienteDespacho`; no se reemplaza con el ubigeo.

## Instalación

Ejecutar una sola vez `scripts/sql/20260824_uspinsertarNotaBweb_ubigeo_y_fecha_edita.sql` en la base de datos de destino. El script valida la estructura esperada y es idempotente.

Para revisar o instalar la definición completa del procedimiento, usar `scripts/sql/20260824_uspinsertarNotaBweb_completo_ubigeo_y_fecha_edita.sql`.
