import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

const sourceDirectory = resolve(fileURLToPath(new URL(".", import.meta.url)));
const configPath = resolve(sourceDirectory, "..", "agent.config.json");

export async function loadConfig() {
  let rawConfig;
  try {
    rawConfig = await readFile(configPath, "utf8");
  } catch {
    throw new Error(
      "Falta agent.config.json. Copia agent.config.example.json y configura el token.",
    );
  }

  let config;
  try {
    config = JSON.parse(rawConfig);
  } catch {
    throw new Error("agent.config.json no contiene JSON válido.");
  }

  const token = String(config.token ?? "").trim();
  const allowedOrigins = Array.isArray(config.allowedOrigins)
    ? config.allowedOrigins.map((origin) => String(origin).trim()).filter(Boolean)
    : [];
  const port = Number(config.port ?? 5174);
  const maxPdfBytes = Number(config.maxPdfBytes ?? 10 * 1024 * 1024);

  if (token.length < 24 || token.includes("REEMPLAZA")) {
    throw new Error("Configura un token aleatorio de al menos 24 caracteres.");
  }
  if (!Number.isInteger(port) || port < 1024 || port > 65535) {
    throw new Error("El puerto debe estar entre 1024 y 65535.");
  }
  if (!allowedOrigins.length) {
    throw new Error("Configura al menos un origen web permitido.");
  }
  if (!Number.isInteger(maxPdfBytes) || maxPdfBytes < 1) {
    throw new Error("maxPdfBytes debe ser un entero positivo.");
  }

  return { allowedOrigins, maxPdfBytes, port, token };
}
