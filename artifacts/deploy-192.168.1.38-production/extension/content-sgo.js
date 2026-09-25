const STORAGE_KEY = "sgoDxnCapture";
const MAX_CAPTURE_AGE_MS = 2 * 60 * 1000;

function deliver(payload, type = "SGO_DXN_CAPTURE") {
  if (!payload?.lines?.length) return;
  window.postMessage({ type, payload }, window.location.origin);
}

function deliverStored(expectedKind, type) {
  chrome.storage.local.get(STORAGE_KEY, (result) => {
    const payload = readStoredPayload(result?.[STORAGE_KEY]);
    if (!payload || (expectedKind && payload.kind !== expectedKind)) return;
    chrome.storage.local.remove(STORAGE_KEY);
    deliver(payload, type);
  });
}

function readStoredPayload(stored) {
  if (!stored?.payload || Date.now() - Number(stored.savedAt || 0) > MAX_CAPTURE_AGE_MS) {
    chrome.storage.local.remove(STORAGE_KEY);
    return null;
  }

  return stored.payload;
}

chrome.runtime.onMessage.addListener((message) => {
  if (message?.type !== "SGO_DXN_CAPTURE_DELIVER") return;
  chrome.storage.local.remove(STORAGE_KEY);
  deliver(message.payload, message.payload?.kind === "obs_summary" ? "SGO_DXN_OBS_CAPTURE" : "SGO_DXN_CAPTURE");
});

window.addEventListener("message", (event) => {
  if (event.source !== window) return;
  if (event.data?.type === "SGO_DXN_CAPTURE_COMPLETED") {
    chrome.storage.local.get(STORAGE_KEY, (result) => {
      const payload = readStoredPayload(result?.[STORAGE_KEY]);
      if (payload?.kind !== "obs_summary") chrome.storage.local.remove(STORAGE_KEY);
    });
    return;
  }
  if (event.data?.type === "SGO_DXN_CAPTURE_READY") {
    deliverStored(undefined, "SGO_DXN_CAPTURE");
    return;
  }
  if (event.data?.type === "SGO_DXN_OBS_CAPTURE_READY") {
    deliverStored("obs_summary", "SGO_DXN_OBS_CAPTURE");
  }
});
