# Capturar OBS desde Firefox hacia COMAS

Destino exclusivo: http://192.168.18.47:8080. Ventas en /sales/html_capture/new;
resumen OBS/IOC en /sales/obs_capture. Iniciar sesión SGO en la misma instancia de
Firefox que muestra OBS (https://obs6.dxn2u.com).

## Instalación temporal

1. Abre about:debugging#/runtime/this-firefox en Firefox.
2. Retira la extensión COMAS anterior. Deshabilita otras variantes de captura
   mientras pruebas para no confundir los botones.
3. Pulsa **Cargar complemento temporal...** y selecciona
   SGO-DXN-Capture-Firefox-comas-0.2.1.xpi, o el manifest.json de comas-unpacked.
4. Recarga las pestañas de OBS y SGO abiertas antes de instalar.
5. En OBS pulsa **Enviar a SGO** o **Enviar resumen a SGO**.

El XPI no tiene firma Mozilla: la instalación temporal desaparece al cerrar
Firefox. Para instalación permanente se requiere firma. Este paquete es para
COMAS; no apunta a ICA ni a localhost.

## Corrección 0.2.1

El nombre visible del complemento es “SGO DXN Capture - COMAS”; no incluye la
marca Firefox, que Mozilla rechaza en el nombre durante la validación.

El paquete 0.2.0 incluía :8080 en los patrones del manifest. Firefox ignora
patrones con puerto, por lo que podía abrir SGO sin cargar el script que entrega
los datos. Los patrones ahora usan http://192.168.18.47/*; include_globs y la
comprobación del origen en background.js mantienen el destino exacto :8080.
Una aplicación en :8081 no se selecciona ni se redirige.

El formulario de ventas tampoco consume capturas de tipo obs_summary mientras
la pestaña cambia al resumen. Se reutilizan las mismas correcciones verificadas
para Firefox local. No requiere desplegar frontend/API ni ejecutar SQL.

## Generación y verificación

Desde sgo_dnx_extension_dev:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-firefox.ps1 -Target comas

El generador comparte el puente corregido con la variante local y toma el
extractor y los botones de producción de sgo_dnx_extension/content-dxn.js.
Produce XPI, ZIP y comas-unpacked en artifacts/firefox-comas-20261021.

Se comprueban patrones sin puerto, globs/origen exacto COMAS, ausencia de ICA y
localhost en los scripts/manifest y sintaxis JavaScript. La entrega venta/resumen
se prueba en Firefox aislado con datos simulados y una página que demora en iniciar.
La captura de un comprobante real en la sesión del usuario requiere comprobación
en la PC de COMAS. No se confirma ninguna venta desde las pruebas.

Referencia de patrones Firefox:
https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Match_patterns
