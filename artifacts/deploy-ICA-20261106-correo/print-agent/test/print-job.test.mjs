import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { access, mkdtemp, readFile, readdir, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import { join } from "node:path";
import test from "node:test";
import { processPrintJob } from "../src/print-job.mjs";

const config = {
  maxPdfBytes: 1024,
  defaultPrinter: "",
  printScale: "fit",
  diagnosticMode: true,
};
const pdf = Buffer.from("%PDF-1.3\ncontenido original\n%%EOF\n");
const body = {
  pdfBase64: "data:application/pdf;base64," + pdf.toString("base64"),
  printer: "EPSON de prueba",
  token: "no debe registrarse",
};

test("captura el PDF byte por byte y registra opciones sin invocar la impresora", async () => {
  const directory = await mkdtemp(join(os.tmpdir(), "dnx-capture-test-"));
  let calls = 0;
  try {
    const result = await processPrintJob(body, config, {
      directory,
      origin: "http://192.168.18.47:8080",
      print: async () => { calls++; },
    });
    assert.equal(calls, 0);
    assert.equal(result.ok, false);
    assert.equal(result.printed, false);
    assert.equal(result.captured, true);
    assert.deepEqual(await readFile(result.pdfPath), pdf);
    const metadata = JSON.parse(await readFile(result.metadataPath, "utf8"));
    assert.equal(metadata.status, "captured_not_printed");
    assert.equal(metadata.options.scale, "fit");
    assert.equal(metadata.options.printer, body.printer);
    assert.equal(metadata.pdfSha256, createHash("sha256").update(pdf).digest("hex"));
    const log = await readFile(join(directory, "jobs.jsonl"), "utf8");
    assert.equal(JSON.parse(log).jobId, result.jobId);
    assert.ok(!log.includes(body.pdfBase64));
    assert.ok(!log.includes(body.token));
    const second = await processPrintJob(body, config, { directory, print: async () => { calls++; } });
    assert.notEqual(result.pdfPath, second.pdfPath);
    assert.equal(calls, 0);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test("PDF inválido falla y deja un error; nunca intenta imprimir", async () => {
  const directory = await mkdtemp(join(os.tmpdir(), "dnx-capture-invalid-"));
  let calls = 0;
  try {
    await assert.rejects(processPrintJob({ pdfBase64: "bm8gZXMgcGRm" }, config, {
      directory,
      print: async () => { calls++; },
    }), /no es un PDF/);
    assert.equal(calls, 0);
    assert.deepEqual(await readdir(directory), ["jobs.jsonl"]);
    assert.equal(JSON.parse(await readFile(join(directory, "jobs.jsonl"), "utf8")).status, "error");
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test("si no puede guardar, falla sin volver a la impresión física", async () => {
  const directory = await mkdtemp(join(os.tmpdir(), "dnx-capture-failure-"));
  const blocked = join(directory, "no-es-directorio");
  let calls = 0;
  try {
    await writeFile(blocked, "ocupado");
    await assert.rejects(processPrintJob(body, config, {
      directory: blocked,
      print: async () => { calls++; },
    }));
    assert.equal(calls, 0);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test("modo normal conserva el PDF y las opciones y limpia el temporal", async () => {
  let submittedPath;
  let calls = 0;
  const result = await processPrintJob(body, { ...config, diagnosticMode: false }, {
    print: async (filePath, options) => {
      submittedPath = filePath;
      calls++;
      assert.deepEqual(await readFile(filePath), pdf);
      assert.deepEqual(options, { printer: body.printer, scale: "fit", silent: true });
    },
  });
  assert.equal(calls, 1);
  assert.equal(result.ok, true);
  assert.equal(result.submitted, true);
  await assert.rejects(access(submittedPath));
});
