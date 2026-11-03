# DNX Print Agent

Servicio local para Windows que permite a DNX imprimir un PDF sin abrir el diálogo de impresión del navegador y consultar el nombre del equipo.

El agente escucha únicamente en `127.0.0.1`; no expone impresoras a la red. Acepta solicitudes solo de los orígenes configurados; las operaciones de impresión exigen un token Bearer.

## Instalación

1. Instalar Node.js 20 o superior.
2. Abrir una consola en esta carpeta y ejecutar `npm ci`.
3. Copiar `agent.config.example.json` como `agent.config.json`.
4. El paquete de producción ya incluye el origen `http://192.168.1.38:8080` y su token. Mantener ambos valores sincronizados con el frontend.
5. Ejecutar `install-service.ps1` desde PowerShell como administrador para instalarlo como servicio de Windows.

El agente permanece en `127.0.0.1:5174`: debe instalarse en cada PC que use Chrome y tenga una impresora. Si Chrome se usa mediante sesión remota directamente en el servidor, se instala en el servidor.

En `agent.config.json`, `allowedOrigins` debe contener la dirección desde la cual se abre DNX. La configuración de este proyecto contempla producción (`http://192.168.1.38:8080`) y desarrollo local (`http://localhost:5173` y `http://localhost:8080`). Después de cambiarla, reiniciar el servicio con `Restart-Service DNXPrintAgent`.

`printScale` permite elegir cómo SumatraPDF acomoda el PDF en el papel: `noscale`, `shrink` o `fit`. Déjalo vacío para conservar el comportamiento predeterminado. Para diagnosticar tickets que salen reducidos desde la impresión silenciosa, configura `"printScale": "fit"` en esa PC y reinicia el agente; la opción `fit` se aplica solo a ese equipo si solo ahí se cambia la configuración.

Para los tickets DNX, la impresora se configura en `MAQUINAS.Tiketera`: la web identifica el equipo y le entrega ese nombre al agente. El campo opcional `defaultPrinter` queda solo como compatibilidad para solicitudes que no indiquen impresora; no se usa para decidir la ticketera de DNX.

## Diagnóstico sin gastar papel

Con diagnosticMode activado, el agente guarda el PDF recibido y los registros en
la carpeta diagnostics junto a su configuración, sin llamar a la impresora.
El script configurar-diagnostico.ps1 actualiza el servicio instalado y activa ese
modo conservando los demás valores. La guía de activación y desactivación está en
[docs/diagnostico-sin-imprimir.md](docs/diagnostico-sin-imprimir.md).
En este modo, POST /v1/print responde HTTP 409 con el mensaje de bloqueo y la ruta
del PDF; es deliberado para que la web actual no anuncie una impresión que no ocurrió.
GET /health informa el build y si el diagnóstico está activo.

## Servicio de Windows

El servicio inicia con Windows y WinSW lo reinicia si el proceso termina. La instalación descarga WinSW 2.12.0 desde su publicación oficial y verifica el SHA-256 antes de registrarlo. Requiere Node.js 20 o superior instalado para todo el equipo, `npm ci`, un `agent.config.json` válido y permisos de administrador.

Desde una consola de PowerShell como administrador, ejecutar:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-service.ps1
```

El instalador comprueba `http://127.0.0.1:5174/health`. Si detecta la tarea antigua **DNX Print Agent**, la detiene durante la migración y la quita solo después de validar el servicio. También configura el inicio automático y la recuperación ante fallos.

El servicio se instala como **LocalSystem** por defecto. Si la impresora solo está instalada para un usuario o es una impresora de red, configura la pestaña **Iniciar sesión** del servicio para usar una cuenta que tenga acceso a esa impresora y reinícialo. Prueba una impresión real después de instalarlo: los servicios no comparten necesariamente las impresoras predeterminadas de una sesión de escritorio.

Los registros de WinSW quedan junto al agente. `run-agent.cmd` y `npm start` siguen disponibles para diagnóstico manual; no deben ejecutarse a la vez que el servicio porque ocuparían el puerto 5174.

Para retirar el servicio y la tarea antigua sin borrar configuración ni registros, ejecutar `uninstall-agent.ps1` como administrador. La guía de instalación, verificación y desinstalación del servidor está en [`docs/servicio-windows-y-desinstalacion.md`](docs/servicio-windows-y-desinstalacion.md).

## API local

Las rutas de impresión requieren:

```http
Authorization: Bearer <token configurado>
```

| Método | Ruta | Resultado |
| --- | --- | --- |
| GET | `/health` | Estado del agente. |
| GET | `/v1/system` | `hostname`, plataforma e impresora predeterminada. No requiere token; solo responde a un origen permitido y no permite imprimir. |
| GET | `/v1/printers` | Impresoras instaladas en Windows. |
| POST | `/v1/print` | Envía un PDF a la impresora. |

Ejemplo para imprimir:

```js
await fetch("http://127.0.0.1:5174/v1/print", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    Authorization: "Bearer <token configurado>",
  },
  body: JSON.stringify({
    pdfBase64: "data:application/pdf;base64,...",
    printer: "Nombre de la impresora", // Opcional: usa la predeterminada.
    copies: 1,
    paperSize: "A4",
    orientation: "portrait",
  }),
});
```

`pdfBase64` admite como máximo el tamaño configurado en `maxPdfBytes` (10 MB por defecto). Las solicitudes de impresión se procesan una por una para no mezclar trabajos en la impresora.

## Verificación

```powershell
npm test
Invoke-WebRequest http://127.0.0.1:5174/health
```

La impresión usa [`pdf-to-printer`](https://github.com/artiebits/pdf-to-printer), que imprime PDFs directamente en impresoras Windows.

## Serie y correlativo por equipo

La web consulta `GET /v1/system` para obtener el `hostname` de Windows. Después lo envía a su API, que busca la máquina en `MAQUINAS` y usa su `SerieBoleta` o `SerieFactura`. Si el agente no está activo o la máquina no está configurada, la web bloquea la emisión de boletas y facturas; no usa una serie fija de respaldo.
