# Capturar OBS desde Firefox hacia SGO local

Destino exclusivo: http://localhost:5173. Venta: /sales/html_capture/new.
Resumen OBS/IOC: /sales/obs_capture. El frontend local debe estar iniciado y la
sesión SGO iniciada en la misma instancia de Firefox que muestra OBS.

## Instalación temporal

1. En Firefox abre about:debugging#/runtime/this-firefox.
2. Retira la variante local anterior si estaba cargada. Deshabilita otra extensión
   de captura mientras pruebas para no confundir sus botones.
3. Pulsa **Cargar complemento temporal...** y selecciona el XPI
   SGO-DXN-Capture-Firefox-local-0.2.1.xpi, o el manifest.json de local-unpacked.
4. Recarga las pestañas de OBS y SGO que estaban abiertas antes de instalar.
5. En OBS pulsa **Enviar a SGO (Desarrollo)** o **Enviar resumen a SGO (Desarrollo)**.
   Se abrirá/enfocará SGO local con los datos de la venta o del resumen.

El XPI no tiene firma Mozilla: la carga temporal desaparece al cerrar Firefox.
Para instalación permanente se requiere firma. No usar este paquete para COMAS o ICA.

## Causa y alcance de la corrección

Firefox ignora patrones de extensión que incluyen puerto, por ejemplo
http://localhost:5173/*. Eso dejaba abrir una pestaña mediante tabs.create,
pero no cargaba content-sgo.js para transferir la captura al formulario.
Los patrones del manifest y la consulta de pestañas ahora omiten el puerto.
include_globs y la comprobación explícita del origen en background.js conservan
el destino localhost:5173 e impiden reutilizar aplicaciones de otros puertos.

Además, el formulario de ventas no consume capturas de tipo obs_summary:
un mensaje READY tardío de la pantalla anterior no puede descartar el resumen
mientras la pestaña navega hacia OBS/IOC.

La captura usa los datos visibles de OBS. No confirma ventas automáticamente.
No cambia la API, SQL ni el agente de impresión.

## Generar el paquete

Desde la carpeta sgo_dnx_extension_dev:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-firefox.ps1

El generador reutiliza los scripts de desarrollo y crea el manifest Firefox,
XPI, ZIP y carpeta local-unpacked bajo artifacts/firefox-local-20261021.
Mantiene el manifest Chrome/Edge original.

## Verificación del 21/10/2026

- `node --test test/capture-bridge.test.cjs`: cinco pruebas pasan para separación
  venta/resumen, caducidad, rechazo de otra ventana y selección del puerto correcto.
- Firefox 158.0.1 en un perfil temporal aislado, con el manifest generado:
  entrega de venta en pestaña nueva, cambio a resumen, resumen en pestaña existente,
  vuelta a venta y venta en pestaña existente. La página receptora simula 1,2 segundos
  de arranque de React y verifica el origen del mensaje.
- El ensayo usa capturas inventadas y un servidor local de prueba; no accede a
  la cuenta OBS, no confirma ventas y no modifica el perfil personal de Firefox.
  Resta comprobar la captura de un comprobante real en la sesión del usuario.

Referencia de los patrones admitidos por Firefox:
https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Match_patterns
