const STORAGE_KEY = "sgoDxnCapture";
const SGO_URL = "http://localhost:5173/sales/html_capture/new";
const SGO_OBS_URL = "http://localhost:5173/sales/obs_capture";
const SGO_MATCHES = [
  "http://localhost/*",
];
const SGO_ORIGIN = new URL(SGO_URL).origin;

async function injectCapture(tabId, payload) {
  await chrome.scripting.executeScript({
    target: { tabId },
    args: [payload],
    func: (capturePayload) => {
      window.postMessage(
        {
          type:
            capturePayload?.kind === "obs_summary"
              ? "SGO_DXN_OBS_CAPTURE"
              : "SGO_DXN_CAPTURE",
          payload: capturePayload,
        },
        window.location.origin,
      );
    },
  });
}

function injectWhenReady(tabId, payload) {
  const tryInject = () =>
    injectCapture(tabId, payload).catch(() => {
      chrome.tabs.sendMessage(
        tabId,
        { type: "SGO_DXN_CAPTURE_DELIVER", payload },
        () => chrome.runtime.lastError,
      );
    });

  chrome.tabs.get(tabId, (tab) => {
    if (tab.status === "complete") {
      tryInject();
      return;
    }

    const onUpdated = (updatedTabId, changeInfo) => {
      if (updatedTabId !== tabId || changeInfo.status !== "complete") return;
      chrome.tabs.onUpdated.removeListener(onUpdated);
      tryInject();
    };
    chrome.tabs.onUpdated.addListener(onUpdated);
  });
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (
    message?.type !== "SGO_DXN_CAPTURE_SEND" &&
    message?.type !== "SGO_DXN_OBS_CAPTURE_SEND"
  ) return false;

  const isObsCapture = message.type === "SGO_DXN_OBS_CAPTURE_SEND";
  const targetUrl = isObsCapture ? SGO_OBS_URL : SGO_URL;

  void (async () => {
    try {
      await chrome.storage.local.set({
        [STORAGE_KEY]: { payload: message.payload, savedAt: Date.now() },
      });
      // Firefox ignores match patterns with ports; restrict the origin after querying.
      const tabs = (await chrome.tabs.query({ url: SGO_MATCHES })).filter(
        (tab) => tab.url?.startsWith(`${SGO_ORIGIN}/`),
      );
      const target =
        tabs.find((tab) =>
          tab.url?.includes(
            isObsCapture ? "/sales/obs_capture" : "/sales/html_capture/new",
          ),
        ) ??
        tabs.find((tab) =>
          tab.url?.includes(
            isObsCapture ? "/sales/obs_capture" : "/sales/html_capture",
          ),
        ) ??
        tabs[0];

      if (!target?.id) {
        await chrome.tabs.create({ url: targetUrl });
        sendResponse({ ok: true, opened: true });
        return;
      }

      if (target.windowId) {
        await chrome.windows.update(target.windowId, { focused: true });
      }
      await chrome.tabs.update(
        target.id,
        target.url?.includes(
          isObsCapture ? "/sales/obs_capture" : "/sales/html_capture/new",
        )
          ? { active: true }
          : { active: true, url: targetUrl },
      );
      injectWhenReady(target.id, message.payload);
      sendResponse({ ok: true, reused: true });
    } catch (error) {
      console.error("No se pudo enviar la captura a SGO.", error);
      sendResponse({
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  })();

  return true;
});
