import { createServer } from "node:http";
import { execFile } from "node:child_process";
import os from "node:os";
import { promisify } from "node:util";
import pdfToPrinter from "pdf-to-printer";
import { loadConfig } from "./config.mjs";
import { AGENT_BUILD, processPrintJob } from "./print-job.mjs";

const { print } = pdfToPrinter;
const execFileAsync = promisify(execFile);

const JSON_CONTENT_TYPE = "application/json; charset=utf-8";

const sendJson = (response, statusCode, body, origin) => {
  response.writeHead(statusCode, {
    "Content-Type": JSON_CONTENT_TYPE,
    ...(origin ? { "Access-Control-Allow-Origin": origin, Vary: "Origin" } : {}),
  });
  response.end(JSON.stringify(body));
};

const readJson = async (request, maxBytes) => {
  const chunks = [];
  let receivedBytes = 0;
  for await (const chunk of request) {
    receivedBytes += chunk.length;
    if (receivedBytes > maxBytes) throw new Error("La solicitud excede el tamaño permitido.");
    chunks.push(chunk);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    throw new Error("El cuerpo debe ser JSON válido.");
  }
};

const getAuthorizedOrigin = (request, config) => {
  const origin = String(request.headers.origin ?? "");
  if (origin && !config.allowedOrigins.includes(origin)) return null;
  return origin;
};

const isAuthorized = (request, token) =>
  request.headers.authorization === `Bearer ${token}`;

const getWindowsDefaultPrinter = async () => {
  const command = [
    "Add-Type -AssemblyName System.Drawing;",
    "$settings = [System.Drawing.Printing.PrinterSettings]::new();",
    "if ($settings.IsValid) { [Console]::Write($settings.PrinterName) }",
  ].join(" ");
  const { stdout } = await execFileAsync(
    "powershell.exe",
    ["-NoProfile", "-NonInteractive", "-Command", command],
    { windowsHide: true },
  );
  return stdout.trim() || null;
};

const getWindowsPrinters = async () => {
  const command = [
    "Get-CimInstance Win32_Printer |",
    "Select-Object @{Name='name';Expression={$_.Name}},",
    "@{Name='isDefault';Expression={$_.Default}},",
    "@{Name='isOffline';Expression={$_.WorkOffline}} |",
    "ConvertTo-Json -Compress",
  ].join(" ");
  const { stdout } = await execFileAsync(
    "powershell.exe",
    ["-NoProfile", "-NonInteractive", "-Command", command],
    { windowsHide: true },
  );
  const parsed = JSON.parse(stdout.trim() || "[]");
  return Array.isArray(parsed) ? parsed : [parsed];
};

const start = async () => {
  if (process.platform !== "win32") {
    throw new Error("DNX Print Agent solo funciona en Windows.");
  }

  const config = await loadConfig();
  const maxRequestBytes = Math.ceil(config.maxPdfBytes * 1.4) + 1024;
  let printQueue = Promise.resolve();
  const resolveDefaultPrinter = async () =>
    config.defaultPrinter || (await getWindowsDefaultPrinter().catch(() => null));

  const server = createServer(async (request, response) => {
    const origin = getAuthorizedOrigin(request, config);
    if (String(request.headers.origin ?? "") && !origin) {
      sendJson(response, 403, { error: "Origen no permitido." });
      return;
    }

    if (request.method === "OPTIONS") {
      response.writeHead(204, {
        "Access-Control-Allow-Headers": "Authorization, Content-Type",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        ...(origin ? { "Access-Control-Allow-Origin": origin, Vary: "Origin" } : {}),
      });
      response.end();
      return;
    }

    const url = new URL(request.url ?? "/", "http://127.0.0.1");
    if (request.method === "GET" && url.pathname === "/health") {
      sendJson(response, 200, {
        ok: true,
        service: "dnx-print-agent",
        build: AGENT_BUILD,
        diagnosticMode: config.diagnosticMode,
      }, origin);
      return;
    }

    // El hostname no permite operar impresoras; se expone al origen permitido
    // para que la web resuelva la serie asignada de esta PC en su API.
    if (request.method === "GET" && url.pathname === "/v1/system") {
      const defaultPrinter = await resolveDefaultPrinter();
      sendJson(response, 200, {
        hostname: os.hostname(),
        platform: process.platform,
        defaultPrinter,
      }, origin);
      return;
    }

    if (!isAuthorized(request, config.token)) {
      sendJson(response, 401, { error: "Token inválido." }, origin);
      return;
    }

    try {
      if (request.method === "GET" && url.pathname === "/v1/printers") {
        sendJson(response, 200, { printers: await getWindowsPrinters() }, origin);
        return;
      }

      if (request.method === "POST" && url.pathname === "/v1/print") {
        const body = await readJson(request, maxRequestBytes);
        if (!body || typeof body !== "object" || Array.isArray(body)) {
          throw new Error("El cuerpo de impresión debe ser un objeto JSON.");
        }
        printQueue = printQueue.catch(() => undefined).then(async () => {
          const defaultPrinter = config.diagnosticMode || body.printer
            ? config.defaultPrinter
            : await resolveDefaultPrinter();
          return processPrintJob(body, { ...config, defaultPrinter }, { print, origin });
        });
        const result = await printQueue;
        sendJson(response, result.diagnosticMode ? 409 : 202, result, origin);
        return;
      }

      sendJson(response, 404, { error: "Ruta no encontrada." }, origin);
    } catch (error) {
      sendJson(response, 400, {
        error: error instanceof Error ? error.message : "No se pudo procesar la solicitud.",
      }, origin);
    }
  });

  server.listen(config.port, "127.0.0.1", () => {
    console.log(JSON.stringify({
      event: "agent_started",
      build: AGENT_BUILD,
      diagnosticMode: config.diagnosticMode,
      printScale: config.printScale || "(predeterminada)",
      hostname: os.hostname(),
      windowsUser: os.userInfo().username,
      pid: process.pid,
    }));
    console.log(`DNX Print Agent activo en http://127.0.0.1:${config.port}`);
  });
};

start().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
