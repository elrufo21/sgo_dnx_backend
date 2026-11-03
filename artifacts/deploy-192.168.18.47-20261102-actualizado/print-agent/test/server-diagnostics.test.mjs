import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { cp, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { createServer } from "node:net";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { AGENT_BUILD } from "../src/print-job.mjs";

test("HTTP de diagnóstico guarda, informa que no imprimió y conserva autenticación", {
  skip: process.platform !== "win32",
  timeout: 20000,
}, async () => {
  const root = fileURLToPath(new URL("../", import.meta.url));
  const directory = await mkdtemp(join(root, ".diagnostics-http-test-"));
  const listener = createServer();
  listener.listen(0, "127.0.0.1");
  await once(listener, "listening");
  const port = listener.address().port;
  await new Promise((resolve) => listener.close(resolve));
  const token = "token-solo-de-prueba-no-es-un-secreto-real";
  const origin = "http://192.168.18.47:8080";
  const pdf = Buffer.from("%PDF-1.3\nPDF original para prueba HTTP\n%%EOF");
  let child;
  let output = "";
  try {
    await cp(join(root, "src"), join(directory, "src"), { recursive: true });
    await writeFile(join(directory, "agent.config.json"), JSON.stringify({
      port, token, allowedOrigins: [origin], diagnosticMode: true, printScale: "fit",
    }));
    child = spawn(process.execPath, [join(directory, "src/server.mjs")], {
      cwd: directory, windowsHide: true,
    });
    child.stdout.on("data", (chunk) => { output += chunk; });
    child.stderr.on("data", (chunk) => { output += chunk; });
    let health;
    const base = "http://127.0.0.1:" + port;
    const deadline = Date.now() + 10000;
    while (Date.now() < deadline) {
      try {
        health = await (await fetch(base + "/health")).json();
        break;
      } catch {
        if (child.exitCode !== null) throw new Error(output);
        await new Promise((resolve) => setTimeout(resolve, 50));
      }
    }
    assert.equal(health?.build, AGENT_BUILD, output);
    assert.equal(health?.diagnosticMode, true);
    const unauthorized = await fetch(base + "/v1/print", {
      method: "POST", headers: { "Content-Type": "application/json", Origin: origin },
      body: JSON.stringify({ pdfBase64: pdf.toString("base64") }),
    });
    assert.equal(unauthorized.status, 401);
    const headers = {
      "Content-Type": "application/json", Authorization: "Bearer " + token, Origin: origin,
    };
    const invalid = await fetch(base + "/v1/print", {
      method: "POST", headers, body: JSON.stringify({ pdfBase64: "bm8gcGRm" }),
    });
    assert.equal(invalid.status, 400);
    const response = await fetch(base + "/v1/print", {
      method: "POST", headers,
      body: JSON.stringify({ pdfBase64: "data:application/pdf;base64," + pdf.toString("base64") }),
    });
    assert.equal(response.status, 409);
    assert.equal(response.headers.get("Access-Control-Allow-Origin"), origin);
    const result = await response.json();
    assert.equal(result.ok, false);
    assert.equal(result.printed, false);
    assert.equal(result.captured, true);
    assert.match(result.error, /Impresión bloqueada por diagnóstico/);
    assert.deepEqual(await readFile(result.pdfPath), pdf);
    const records = (await readFile(join(directory, "diagnostics/jobs.jsonl"), "utf8"))
      .trim().split("\n").map((line) => JSON.parse(line));
    assert.deepEqual(records.map((r) => r.status), ["error", "captured_not_printed"]);
    assert.ok(!output.includes(token));
    assert.ok(!output.includes(pdf.toString("base64")));
  } finally {
    if (child && child.exitCode === null) {
      const exited = once(child, "exit");
      child.kill();
      await exited;
    }
    assert.ok(directory.startsWith(join(root, ".diagnostics-http-test-")));
    await rm(directory, { recursive: true, force: true });
  }
});
