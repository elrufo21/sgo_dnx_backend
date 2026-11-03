import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

const allowedExtensions = new Set([".pdf", ".xml", ".zip", ".xlsx", ".txt"]);

export async function saveFile(body, directory, maxBytes) {
  const name = String(body?.fileName ?? "");
  if (!name || name.length > 180 || /[\\/:*?"<>|\x00-\x1f]/.test(name) || name === "." || name === ".." || /[. ]$/.test(name)) {
    throw new Error("Nombre de archivo inválido.");
  }
  const extension = path.extname(name).toLowerCase();
  if (!allowedExtensions.has(extension) || /^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)/i.test(name)) {
    throw new Error("Tipo o nombre de archivo no permitido.");
  }
  const encoded = body?.fileBase64;
  if (typeof encoded !== "string" || !encoded || encoded.length > Math.ceil(maxBytes / 3) * 4 || !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(encoded)) {
    throw new Error("Contenido del archivo inválido o demasiado grande.");
  }
  const bytes = Buffer.from(encoded, "base64");
  if (!bytes.length || bytes.length > maxBytes) throw new Error("Tamaño de archivo no permitido.");
  if (extension === ".pdf" && !bytes.subarray(0, 5).equals(Buffer.from("%PDF-"))) throw new Error("El archivo no es un PDF válido.");
  await mkdir(directory, { recursive: true });
  const base = name.slice(0, -extension.length);
  for (let i = 0; i < 10000; i++) {
    const candidate = i ? `${base} (${i})${extension}` : name;
    const target = path.join(directory, candidate);
    try {
      await writeFile(target, bytes, { flag: "wx" });
      return { ok: true, fileName: candidate, path: target };
    } catch (error) {
      if (error.code !== "EEXIST") throw error;
    }
  }
  throw new Error("No se pudo asignar un nombre libre al archivo.");
}
