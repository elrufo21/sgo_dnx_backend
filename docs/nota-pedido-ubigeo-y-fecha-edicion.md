# Ubigeo y fecha de edición de NotaPedido

Fecha: 2026-08-24

## Alcance

Las notas creadas desde la web mediante `dbo.uspinsertarNotaBweb` guardan el nombre de ubigeo de su compañía (`Compania.CompaniaNomUBG`) en `NotaPedido.NotaDireccion`.

`FechaEdita` se guarda como texto vacío (`''`) al crear la nota. Solo debe contener una fecha cuando una edición o anulación la registre.

## Conservación de datos

La dirección recibida de la venta se conserva para actualizar `Cliente.ClienteDespacho`; no se reemplaza con el ubigeo.

## Instalación

Ejecutar `scripts/sql/20260824_uspinsertarNotaBweb_completo_ubigeo_y_fecha_edita.sql` en la base de datos de destino.
