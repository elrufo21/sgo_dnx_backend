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

Para iniciarlo al ingresar a Windows, crear una tarea en el Programador de tareas que ejecute `run-agent.cmd` con el usuario que usa la impresora.

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
