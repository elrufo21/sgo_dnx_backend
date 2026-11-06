import assert from "node:assert/strict";
import test from "node:test";
import { normalizeDiagnosticMode, normalizePrintScale } from "../src/config.mjs";

test("printScale vacía conserva la escala predeterminada", () => {
  assert.equal(normalizePrintScale(""), "");
  assert.equal(normalizePrintScale(undefined), "");
});

test("printScale acepta las opciones de SumatraPDF", () => {
  assert.equal(normalizePrintScale("fit"), "fit");
  assert.equal(normalizePrintScale(" SHRINK "), "shrink");
  assert.equal(normalizePrintScale("noscale"), "noscale");
});

test("printScale rechaza valores no admitidos", () => {
  assert.throws(() => normalizePrintScale("stretch"), /printScale debe ser/);
});

test("el diagnóstico solo se habilita con un booleano explícito", () => {
  assert.equal(normalizeDiagnosticMode(undefined), false);
  assert.equal(normalizeDiagnosticMode(false), false);
  assert.equal(normalizeDiagnosticMode(true), true);
  assert.throws(() => normalizeDiagnosticMode("false"), /diagnosticMode debe ser/);
  assert.throws(() => normalizeDiagnosticMode(1), /diagnosticMode debe ser/);
});
