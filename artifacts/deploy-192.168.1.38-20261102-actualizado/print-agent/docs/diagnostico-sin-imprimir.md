# Capturar el PDF recibido sin imprimir

## Propósito y alcance

El modo diagnóstico interrumpe el trabajo antes de llamar a pdf-to-printer/Sumatra.
Guarda los bytes originales del PDF recibido por la API local y las opciones que
habría utilizado. No vuelve a renderizar el documento ni consulta la impresora.
Se activa por estación: no requiere cambiar el frontend, backend ni SQL.

## Activar en una estación con el servicio instalado

Extraer el paquete completo en cualquier carpeta y abrir PowerShell como administrador
dentro de esa carpeta. Ejecutar:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\configurar-diagnostico.ps1

El script obtiene del servicio DNXPrintAgent su ruta instalada real. Respalda src y
agent.config.json, detiene el servicio, copia los cuatro módulos, habilita
diagnosticMode con el booleano true, reinicia y comprueba build y modo mediante
/health. Conserva token, orígenes, impresora, puerto y escala. No instala otro
servicio. Si la actualización falla después de detenerlo, lo deja detenido;
no vuelve automáticamente a una versión que podría imprimir.

Antes de volver a pulsar Imprimir, comprobar:

    Invoke-RestMethod http://127.0.0.1:5174/health

Debe indicar build 20261021-diagnostics-v1 y diagnosticMode true.

Si se ejecuta manualmente con npm start, actualizar la misma carpeta y agregar
diagnosticMode: true al JSON válido antes de iniciarlo. El valor predeterminado es
false, por lo que actualizar solo el código no bloquea la impresión.

## Archivos y respuesta de la web

Al reimprimir un comprobante existente, la carpeta diagnostics junto al agente
instalado recibe:

- fecha_UUID.pdf: el PDF original, sin modificar.
- fecha_UUID.json: fecha UTC, ID, equipo, usuario Windows del proceso, origen web,
  impresora solicitada, escala y opciones, bytes, SHA-256, tiempo y resultado.
- jobs.jsonl: un registro JSON por intento procesado, incluidos errores de PDF.

El PDF queda guardado localmente en esa PC; no se abre una ventana desde el servicio
ni se descarga automáticamente por el navegador. Abrir diagnostics desde el
Explorador permite abrir, copiar o compartir el PDF y su JSON correspondiente.
La carpeta no se publica por HTTP. Los registros no incluyen token, cabeceras de
autenticación, base64 ni texto del comprobante.

POST /v1/print devuelve HTTP 409 deliberadamente con captured true y printed false.
El campo error contiene “Impresión bloqueada por diagnóstico. PDF guardado en: …”.
Así la web ya desplegada informa del bloqueo y no anuncia una impresión enviada.
No es una caída del agente; /health continúa respondiendo HTTP 200.

Un error de guardado también impide imprimir. No se utiliza impresión como
alternativa. El registro de stdout/stderr del servicio incluye inicio, build,
modo y metadatos de cada intento. En modo normal, submitted_to_printer significa
que el proceso de impresión terminó sin error; no certifica la salida física.

Los PDF contienen comprobantes reales. Los archivos se conservan para la revisión;
no hay limpieza automática. Retirar los archivos desde el Explorador al terminar
el diagnóstico.

## Desactivar

Para volver a la impresión normal, ejecutar desde el paquete como administrador:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\configurar-diagnostico.ps1 -Desactivar

El script pone diagnosticMode false y reinicia el servicio. Conserva los archivos
capturados y las demás opciones. No ejecutar este comando hasta concluir la revisión.

## Validación y límites

Las pruebas automatizadas comprueban igualdad de bytes y SHA-256, ausencia de
llamadas a la impresora en diagnóstico, fallos de escritura sin impresión de
respaldo, registros sin secretos, autenticación y respuesta HTTP 409 para la web.
La prueba HTTP usa un proceso temporal en otro puerto y no modifica el servicio.
El modo normal se verifica con una función de impresión simulada; no se envían
trabajos físicos durante las pruebas.

Esto permite determinar si el archivo recibido ya tiene el espacio en blanco.
Si el PDF es correcto, el fallo queda pendiente de aislar entre renderizador,
configuración del servicio, controlador y ticketera: guardar el PDF no determina
por sí solo cuál de esos componentes es responsable.
