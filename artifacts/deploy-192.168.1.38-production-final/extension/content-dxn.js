const BUTTON_ID = "sgo-dxn-capture-button";
const OBS_BUTTON_ID = "sgo-dxn-obs-capture-button";
let sending = false;

const safeText = (node) => (node?.textContent || "").trim();
const normalizeCode = (value) => String(value || "").trim().toUpperCase();
const normalizeText = (value) => String(value || "").replace(/\s+/g, " ").trim();
const normalizeLabel = (value) =>
  normalizeText(value)
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
const parseNumber = (value) => {
  const chunks = String(value || "").match(/-?\d+(?:[.,]\d+)?/g) || [];
  return chunks.reduce((total, chunk) => {
    const parsed = Number(chunk.replace(",", "."));
    return Number.isFinite(parsed) ? total + parsed : total;
  }, 0);
};
const readText = (selector) => safeText(document.querySelector(selector));
const isCustomerLabel = (value) =>
  /^(senores|senor\(a\)|cliente)\s*:?/.test(normalizeLabel(value));
const cleanCustomerName = (value) =>
  normalizeText(value)
    .replace(/^(Señores|Senores|Señor\(a\)|Senor\(a\)|Cliente)\s*:?\s*/i, "")
    .replace(/\b(Fecha|Domicilio|Direcci[oó]n|Email|R\.?\s*U\.?\s*C|DNI)\s*:.*$/i, "")
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, "")
    .replace(/\b\d{1,2}[-/]\d{1,2}[-/]\d{2,4}\b/g, "")
    .trim();
const readValueAfterCustomerLabel = (section) => {
  const nodes = Array.from(section?.querySelectorAll("label,span,td,div,p") || []);
  for (let index = 0; index < nodes.length; index += 1) {
    if (!isCustomerLabel(nodes[index].textContent)) continue;
    for (let next = index + 1; next < Math.min(nodes.length, index + 5); next += 1) {
      const candidate = cleanCustomerName(nodes[next].textContent);
      if (candidate && !isCustomerLabel(candidate)) return candidate;
    }
  }
  return "";
};
const readCustomerName = () => {
  const direct = cleanCustomerName(readText("#section-2 span.fleft"));
  if (direct) return direct;

  const sections = ["#section-2", "#section-3", "#section-4", "#section-5"]
    .map((selector) => document.querySelector(selector))
    .filter(Boolean);

  for (const section of sections) {
    const name = readValueAfterCustomerLabel(section);
    if (name) return name;
  }

  for (const section of sections) {
    const match = normalizeText(section.textContent).match(
      /(?:Se(?:ñ|n)ores|Se(?:ñ|n)or\(a\)|Cliente)\s*:?\s*(.+?)(?:\s+(?:Fecha|Domicilio|Direcci[oó]n|Email|R\.?\s*U\.?\s*C|DNI)\s*:|$)/i,
    );
    const name = cleanCustomerName(match?.[1] || "");
    if (name) return name;
  }

  return "";
};
const readEmail = () =>
  (document.body?.innerText || "").match(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i)?.[0] || "";
const readMemberCode = () =>
  readText("#section-6").match(/No\.\s*de\s*Membres[ií]a\s*:?\s*([A-Z0-9-]+)/i)?.[1]?.trim() ||
  readText("#section-6 .fright.left-align")
    .replace("Miembro Telefono", "#")
    .replace("Miembro Teléfono", "#")
    .replace("No. de Membresia", "")
    .replace(":", "")
    .split("#")[0]
    .trim();

function parseCapture() {
  const section = document.getElementById("section-6");
  const table = section?.querySelector("table") || document.querySelector("table");
  const ruc = `${readText("#section-1 .medium-font.center-align")} ${readText("#section-4")}`.trim();
  const discountText = readText("#discount .sections.summary")
    .replace("DISCOUNT", "")
    .trim();

  const lines = table
    ? Array.from(table.querySelectorAll("tr"))
        .slice(1)
        .map((row) => {
          const cells = Array.from(row.querySelectorAll("td"));
          return {
            code: normalizeCode(cells[0]?.textContent),
            quantity: parseNumber(cells[5]?.textContent),
          };
        })
        .filter((line) => line.code && line.quantity > 0)
    : [];

  return {
    transactionNumber: readText("#section-6 .center.medium-font"),
    memberCode: readMemberCode(),
    customerName: readCustomerName(),
    customerEmail: readEmail(),
    ruc,
    date: readText(
      ruc.toUpperCase().includes("FACTURA")
        ? "#section-5 .fleft"
        : "#section-3 .fleft",
    ),
    discount: parseNumber(discountText),
    lines,
  };
}

function injectButton() {
  if (document.getElementById(BUTTON_ID)) return;
  if (!document.getElementById("section-6")) return;

  const button = document.createElement("button");
  button.id = BUTTON_ID;
  button.type = "button";
  button.textContent = "Enviar a SGO";
  button.style.cssText = [
    "position:fixed",
    "right:16px",
    "top:16px",
    "z-index:2147483647",
    "background:#0f172a",
    "color:white",
    "border:0",
    "border-radius:6px",
    "padding:10px 14px",
    "font:600 13px Arial,sans-serif",
    "box-shadow:0 6px 18px rgba(15,23,42,.25)",
    "cursor:pointer",
  ].join(";");

  button.addEventListener("click", () => {
    if (sending) return;
    const payload = parseCapture();
    if (!payload.lines.length) {
      alert("SGO: no se encontraron productos en esta pantalla.");
      return;
    }

    sending = true;
    button.disabled = true;
    button.textContent = "Enviando...";
    chrome.runtime.sendMessage(
      { type: "SGO_DXN_CAPTURE_SEND", payload },
      (response) => {
        sending = false;
        button.disabled = false;
        button.textContent = "Enviar a SGO";
        if (chrome.runtime.lastError) {
          alert(`SGO: ${chrome.runtime.lastError.message}`);
          return;
        }
        if (!response?.ok) alert("SGO: no se pudo enviar la captura.");
      },
    );
  });

  document.documentElement.appendChild(button);
}

const toIsoDate = (value) => {
  const match = normalizeText(value).match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  return match ? `${match[3]}-${match[2].padStart(2, "0")}-${match[1].padStart(2, "0")}` : "";
};
const parseAmount = (value) => {
  const raw = normalizeText(value).replace(/[^0-9,.-]/g, "");
  if (!raw) return 0;
  const lastComma = raw.lastIndexOf(",");
  const lastDot = raw.lastIndexOf(".");
  const decimal = Math.max(lastComma, lastDot);
  const normalized = decimal < 0
    ? raw
    : `${raw.slice(0, decimal).replace(/[,.]/g, "")}.${raw.slice(decimal + 1).replace(/[,.]/g, "")}`;
  const number = Number(normalized);
  return Number.isFinite(number) ? number : 0;
};
function findObsTable() {
  return Array.from(document.querySelectorAll("table")).find((table) => {
    const header = normalizeLabel(table.querySelector("tr")?.textContent);
    return header.includes("fecha de transaccion") && header.includes("nombre de miembro") && header.includes("no. de transaccion");
  });
}
function parseObsSummary() {
  const table = findObsTable();
  const rows = table ? Array.from(table.querySelectorAll("tr")) : [];
  const hasIocLayout = rows.some((row) => row.querySelectorAll(":scope > td").length > 10);
  const lines = table
    ? rows.map((row) => {
        const cells = Array.from(row.querySelectorAll(":scope > td"));
        return {
          date: toIsoDate(cells[0]?.textContent),
          customerName: normalizeText(cells[1]?.textContent),
          memberCode: normalizeCode(cells[2]?.textContent),
          transactionNumber: normalizeText(cells[3]?.textContent),
          amount: parseAmount(cells[hasIocLayout ? 10 : 8]?.textContent),
        };
      }).filter((line) => line.date && line.transactionNumber && line.amount > 0)
    : [];
  const saleType = lines.some((line) => line.transactionNumber.toUpperCase().includes("RS")) ? "IOC" : "OBS";
  return { kind: "obs_summary", saleType, lines };
}
function injectObsSummaryButton() {
  if (document.getElementById(OBS_BUTTON_ID) || !findObsTable()) return;
  const button = document.createElement("button");
  button.id = OBS_BUTTON_ID;
  button.type = "button";
  button.textContent = "Enviar resumen a SGO";
  button.style.cssText = [
    "position:fixed", "right:16px", "top:16px", "z-index:2147483647",
    "background:#7c3aed", "color:white", "border:0", "border-radius:6px",
    "padding:10px 14px", "font:600 13px Arial,sans-serif",
    "box-shadow:0 6px 18px rgba(15,23,42,.25)", "cursor:pointer",
  ].join(";");
  button.addEventListener("click", () => {
    const payload = parseObsSummary();
    if (!payload.lines.length) return alert("SGO: no se encontraron transacciones OBS o IOC.");
    button.disabled = true;
    button.textContent = "Enviando...";
    chrome.runtime.sendMessage({ type: "SGO_DXN_OBS_CAPTURE_SEND", payload }, (response) => {
      button.disabled = false;
      button.textContent = "Enviar resumen a SGO";
      if (chrome.runtime.lastError) return alert(`SGO: ${chrome.runtime.lastError.message}`);
      if (!response?.ok) alert("SGO: no se pudo enviar la captura.");
    });
  });
  document.documentElement.appendChild(button);
}

injectButton();
injectObsSummaryButton();
new MutationObserver(() => {
  injectButton();
  injectObsSummaryButton();
}).observe(document.documentElement, {
  childList: true,
  subtree: true,
});
