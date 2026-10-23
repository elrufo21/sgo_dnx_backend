# SGO DXN Capture - COMAS (Chrome/Brave)

Extensión para capturar ventas y resúmenes visibles en DXN OBS y enviarlos al SGO de COMAS.

- SGO web: `http://192.168.18.47:8080`
- Captura de venta: `/sales/html_capture/new`
- Captura de resumen OBS/IOC: `/sales/obs_capture`

## Instalar

1. Extrae este ZIP en una carpeta permanente de la PC.
2. Abre `chrome://extensions` en Chrome o `brave://extensions` en Brave.
3. Activa **Modo desarrollador**.
4. Pulsa **Cargar descomprimida** y selecciona la carpeta `extension` que contiene `manifest.json`.
5. Recarga las pestañas de OBS y SGO que ya estuvieran abiertas.

Si ya estaba instalada otra variante de SGO Capture, desactívala o elimínala primero para que no se dupliquen los botones.

## Uso

1. Inicia sesión en el SGO de COMAS en el mismo navegador.
2. En DXN OBS, abre la venta o el reporte de resumen.
3. Pulsa **Enviar a SGO** para una venta o **Enviar resumen a SGO** para el reporte.

El paquete es específico de COMAS y solo contiene como destino web `http://192.168.18.47:8080`.