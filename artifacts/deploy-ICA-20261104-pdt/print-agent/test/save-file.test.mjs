import assert from "node:assert/strict";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { saveFile } from "../src/save-file.mjs";

test("guarda bytes, conserva duplicados y rechaza rutas y archivos inválidos", async () => {
  const dir = await mkdtemp(path.join(os.tmpdir(), "dnx-files-"));
  try {
    const bytes = Buffer.from("%PDF-1.4\nprueba\n%%EOF");
    const body = { fileName: "BA01-001.pdf", fileBase64: bytes.toString("base64") };
    const [first, second] = await Promise.all([saveFile(body, dir, 1024), saveFile(body, dir, 1024)]);
    assert.notEqual(first.path, second.path);
    assert.deepEqual(await readFile(first.path), bytes);
    assert.deepEqual(await readFile(second.path), bytes);
    for (const fileName of ["../otro.pdf", "C:\\otro.pdf", "CON.pdf", "archivo.exe"]) {
      await assert.rejects(saveFile({ ...body, fileName }, dir, 1024));
    }
    await assert.rejects(saveFile({ ...body, fileBase64: "@@@" }, dir, 1024));
    await assert.rejects(saveFile({ ...body, fileBase64: Buffer.from("invalido").toString("base64") }, dir, 1024));
    await assert.rejects(saveFile(body, dir, 2));
    const excel = Buffer.from("archivo excel");
    const saved = await saveFile({ fileName: "export.xlsx", fileBase64: excel.toString("base64") }, dir, 1024);
    assert.deepEqual(await readFile(saved.path), excel);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});
