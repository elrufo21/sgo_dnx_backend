import assert from "node:assert/strict";
import test from "node:test";
import { parsePdfBase64 } from "../src/pdf.mjs";

test("acepta un PDF base64 con prefijo data URL", () => {
  const pdf = Buffer.from("%PDF-1.4\ncontenido").toString("base64");
  assert.equal(
    parsePdfBase64(`data:application/pdf;base64,${pdf}`, 1024).toString("ascii"),
    "%PDF-1.4\ncontenido",
  );
});

test("rechaza un contenido que no es PDF", () => {
  const text = Buffer.from("no es pdf").toString("base64");
  assert.throws(() => parsePdfBase64(text, 1024), /no es un PDF válido/);
});
