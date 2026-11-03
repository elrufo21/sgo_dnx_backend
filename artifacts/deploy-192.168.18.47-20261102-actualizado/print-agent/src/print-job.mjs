import { createHash, randomUUID } from "node:crypto";
import { appendFile, mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { parsePdfBase64 } from "./pdf.mjs";

export const AGENT_BUILD = "20261021-diagnostics-v1";
const diagnosticsDirectory = fileURLToPath(new URL("../diagnostics/", import.meta.url));

const printableOptions = (body, config) => {
  const copies = body.copies === undefined ? undefined : Number(body.copies);
  if (copies !== undefined && (!Number.isInteger(copies) || copies < 1 || copies > 99)) {
    throw new Error("copies debe ser un entero entre 1 y 99.");
  }
  const printer = String(body.printer ?? config.defaultPrinter ?? "").trim();
  return {
    ...(printer ? { printer } : {}),
    ...(copies ? { copies } : {}),
    ...(body.paperSize ? { paperSize: String(body.paperSize) } : {}),
    ...(body.orientation === "landscape" ? { orientation: "landscape" } : {}),
    ...(config.printScale ? { scale: config.printScale } : {}),
    silent: true,
  };
};

export async function processPrintJob(
  body,
  config,
  { print, origin = "", directory = diagnosticsDirectory },
) {
  const started = Date.now();
  const jobId = randomUUID();
  const record = {
    jobId,
    timestamp: new Date(started).toISOString(),
    build: AGENT_BUILD,
    mode: config.diagnosticMode ? "capture" : "print",
    hostname: os.hostname(),
    windowsUser: os.userInfo().username,
    pid: process.pid,
    origin,
    requestedPrinter: String(body.printer ?? ""),
  };
  let temporaryDirectory;
  try {
    const pdf = parsePdfBase64(body.pdfBase64, config.maxPdfBytes);
    record.pdfBytes = pdf.length;
    record.pdfSha256 = createHash("sha256").update(pdf).digest("hex");
    record.options = printableOptions(body, config);

    if (config.diagnosticMode) {
      await mkdir(directory, { recursive: true });
      const filename = record.timestamp.replace(/[:.]/g, "-") + "_" + jobId;
      record.pdfPath = join(directory, filename + ".pdf");
      record.metadataPath = join(directory, filename + ".json");
      record.status = "captured_not_printed";
      // Si guardar falla, el diagnóstico tampoco continúa hacia la impresora.
      await writeFile(record.pdfPath, pdf, { flag: "wx" });
      record.elapsedMs = Date.now() - started;
      await writeFile(record.metadataPath, JSON.stringify(record, null, 2) + "\n", { flag: "wx" });
      await appendFile(join(directory, "jobs.jsonl"), JSON.stringify(record) + "\n");
      console.log(JSON.stringify(record));
      return {
        ok: false,
        captured: true,
        printed: false,
        diagnosticMode: true,
        jobId,
        pdfPath: record.pdfPath,
        metadataPath: record.metadataPath,
        error: "Impresión bloqueada por diagnóstico. PDF guardado en: " + record.pdfPath,
      };
    }

    temporaryDirectory = await mkdtemp(join(os.tmpdir(), "dnx-print-"));
    const filePath = join(temporaryDirectory, "documento.pdf");
    await writeFile(filePath, pdf);
    await print(filePath, record.options);
    record.status = "submitted_to_printer";
    record.elapsedMs = Date.now() - started;
    console.log(JSON.stringify(record));
    return { ok: true, submitted: true, jobId, message: "Impresión enviada." };
  } catch (error) {
    record.status = "error";
    record.elapsedMs = Date.now() - started;
    record.error = error instanceof Error ? error.message : String(error);
    console.error(JSON.stringify(record));
    if (config.diagnosticMode) {
      try {
        await mkdir(directory, { recursive: true });
        await appendFile(join(directory, "jobs.jsonl"), JSON.stringify(record) + "\n");
      } catch (logError) {
        console.error("No se pudo escribir el registro de diagnóstico: " + logError.message);
      }
    }
    throw error;
  } finally {
    if (temporaryDirectory) await rm(temporaryDirectory, { force: true, recursive: true });
  }
}
