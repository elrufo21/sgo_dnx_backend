const PDF_HEADER = "%PDF-";

export function parsePdfBase64(value, maxPdfBytes) {
  const raw = String(value ?? "").trim();
  const encoded = raw.replace(/^data:application\/pdf;base64,/i, "");
  if (!encoded) throw new Error("pdfBase64 es obligatorio.");

  const pdf = Buffer.from(encoded, "base64");
  if (!pdf.length || pdf.length > maxPdfBytes) {
    throw new Error(`El PDF debe medir entre 1 y ${maxPdfBytes} bytes.`);
  }
  if (pdf.subarray(0, PDF_HEADER.length).toString("ascii") !== PDF_HEADER) {
    throw new Error("El contenido recibido no es un PDF válido.");
  }

  return pdf;
}
