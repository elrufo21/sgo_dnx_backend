# DNX Print Agent

Servicio local para Windows que permite a DNX imprimir un PDF sin abrir el diálogo de impresión del navegador y consultar el nombre del equipo.

El agente escucha únicamente en `127.0.0.1`; no expone impresoras a la red. Acepta solicitudes solo de los orígenes configurados; las operaciones de impresión exigen un token Bearer.

## Instalación

1. Instalar Node.js 20 o superior.
2. Abrir una consola en esta carpeta y ejecutar `npm install`.
3. Copiar `agent.config.example.json` como `agent.config.json`.
4. El paquete de producción ya incluye el origen `http://192.168.1.38:8080` y su token. Mantener ambos valores sincronizados con el frontend.
5. Ejecutar `run-agent.cmd` o `npm start`.

El agente permanece en `127.0.0.1:5174`: debe instalarse en cada PC que use Chrome y tenga una impresora. Si Chrome se usa mediante sesión remota directamente en el servidor, se instala en el servidor.

En `agent.config.json`, `allowedOrigins` debe contener la dirección desde la cual se abre DNX. La configuración de este proyecto contempla producción (`http://192.168.1.38:8080`) y desarrollo local (`http://localhost:5173` y `http://localhost:8080`). Después de cambiarla, reiniciar la tarea **DNX Print Agent**.

Para los tickets DNX, la impresora se configura en `MAQUINAS.Tiketera`: la web identifica el equipo y le entrega ese nombre al agente. El campo opcional `defaultPrinter` queda solo como compatibilidad para solicitudes que no indiquen impresora; no se usa para decidir la ticketera de DNX.

## Inicio automático

Usar el **Programador de tareas**, no un servicio Windows, para conservar acceso a las impresoras del usuario. Un servicio de Windows no puede usar de forma fiable la impresora predeterminada del usuario que inició sesión.

Después de instalar dependencias y configurar `agent.config.json`, ejecutar una sola vez con PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-auto-start.ps1
```

El instalador crea o actualiza la tarea **DNX Print Agent** para el usuario actual. La tarea inicia al ingresar a Windows, queda ejecutándose sin límite de tiempo y reintenta el agente cada minuto si se detiene. También lo inicia y valida inmediatamente en `http://127.0.0.1:5174/health`.

Debe ejecutarse con el mismo usuario que usa Chrome y tiene la impresora predeterminada. No requiere convertir el agente en un servicio de red ni exponer el puerto fuera del equipo.

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
