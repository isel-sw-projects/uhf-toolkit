"""
One-click wire measurement across the four traced stacks.

Purpose: replace per-slice readings (an SSE frame here, an XHR pair there) with one
unit that is the same on every stack: every WebSocket frame and every HTTP
request/response exchanged from the moment the click is dispatched until the DOM shows
the new value.

What is counted, per stack:
  - bytes sent by the browser (request bodies + WebSocket frames client->server)
  - bytes received by the browser (response bodies + WebSocket frames server->client)
  - the number of messages that carried those bytes

What is NOT counted, deliberately: the initial document load (measured separately),
the WebSocket handshake, and dev-mode tooling traffic, which is named explicitly in
the output when it appears.

Run with the four servers up. Each measurement is repeated to expose variance.
"""

import json
import sys
from pathlib import Path
from statistics import median

from playwright.sync_api import sync_playwright

CHROME = Path.home() / "AppData/Local/ms-playwright/chromium-1140/chrome-win/chrome.exe"

STACKS = {
    "HtmlFlow-Datastar": {
        "url": "http://localhost:8192/multi-client-counter/htmlflow",
        "button": "button[data-on\\:click]",
        "value_selector": "#shared-counter",
    },
    "Blazor Server": {
        "url": "http://localhost:5193/multi-client-counter",
        "button": "button.btn-primary",
        "value_selector": "p.fs-3 strong",
    },
    "Phoenix LiveView": {
        "url": "http://localhost:4000/multi-client-counter",
        "button": "button[phx-click='increment']",
        "value_selector": "p.fs-3 strong",
    },
    "Vaadin Flow": {
        "url": "http://localhost:8282/example/multi-client-counter",
        "button": "vaadin-button",
        "value_selector": None,  # shadow DOM; read the host parent text text
    },
}

REPEATS = 3

# Development tooling that travels on the same socket but is not application payload.
DEV_TOOLING_MARKERS = ("phoenix:live_reload", "phx_live_reload", "live_reload")


def header_bytes(headers):
    return sum(len(k) + len(str(v)) + 4 for k, v in headers.items())


def read_value(page, spec):
    if spec.get("value_selector"):
        try:
            return page.inner_text(spec["value_selector"], timeout=300).strip()
        except Exception:
            return None
    try:
        return page.evaluate("""() => {
                const host = document.querySelector('vaadin-button');
                if (!host || !host.parentElement) return null;
                const m = host.parentElement.innerText.match(/\\d+/);
                return m ? m[0] : null;
            }""")
    except Exception:
        return None


def payload_text(params):
    return params.get("response", {}).get("payloadData", "")


def payload_size(params):
    return len(payload_text(params).encode())


def is_dev_tooling(text):
    return any(marker in text for marker in DEV_TOOLING_MARKERS)


class WireRecorder:
    """Accumulates the bytes one click exchanges, transport by transport.

    The recorder owns the state the CDP callbacks need, so each callback stays a few
    lines. The SSE stream is the reason this state cannot be local to a callback: it is
    opened before the click and never finishes, so its request has to be remembered and
    charged to the click when its first byte arrives, not when it was opened.
    """

    def __init__(self):
        self.active = False
        self.sent = 0
        self.received = 0
        self.dev = 0
        self.msgs = 0
        self.kinds = []
        self.opened = {}

    def attach(self, cdp):
        cdp.on("Network.requestWillBeSent", self.on_request)
        cdp.on("Network.dataReceived", self.on_data)
        cdp.on("Network.webSocketFrameSent", self.on_ws_sent)
        cdp.on("Network.webSocketFrameReceived", self.on_ws_received)

    def snapshot(self, before, after):
        return {
            "sent": self.sent,
            "received": self.received,
            "total": self.sent + self.received,
            "msgs": self.msgs,
            "dev": self.dev,
            "before": before,
            "after": after,
            "kinds": self.kinds,
        }

    def _add(self, size, label):
        self.msgs += 1
        self.kinds.append(label)
        return size

    def _charge_request(self, request_id, already_open):
        info = self.opened[request_id]
        info["counted"] = True
        suffix = " (already open)" if already_open else ""
        self.sent += self._add(
            info["bytes"], "req %s %d%s" % (info["method"], info["bytes"], suffix)
        )

    def on_request(self, params):
        request = params.get("request", {})
        size = header_bytes(request.get("headers", {}))
        post = request.get("postData")
        if post:
            size += len(post.encode())
        method = request.get("method")
        self.opened[params["requestId"]] = {
            "bytes": size,
            "counted": False,
            "method": method,
        }
        if self.active:
            self._charge_request(params["requestId"], already_open=False)

    def on_data(self, params):
        request_id = params["requestId"]
        size = params.get("dataLength", 0)
        if not self.active or not size or request_id not in self.opened:
            return
        if not self.opened[request_id]["counted"]:
            self._charge_request(request_id, already_open=True)
        self.received += self._add(size, "res %d" % size)

    def on_ws_sent(self, params):
        if not self.active:
            return
        size = payload_size(params)
        self.sent += self._add(size, "ws> %d" % size)

    def on_ws_received(self, params):
        if not self.active:
            return
        data = payload_text(params)
        size = len(data.encode())
        if is_dev_tooling(data):
            self.dev += size
            self.msgs += 1
            self.kinds.append("ws< %d DEV-TOOLING" % size)
            return
        self.received += self._add(size, "ws< %d" % size)


def wait_until_changed(page, spec, before, attempts=60, interval_ms=100):
    """Wait for the rendered value to differ from its pre-click text."""
    for _ in range(attempts):
        page.wait_for_timeout(interval_ms)
        if read_value(page, spec) not in (None, before):
            return True
    return False


def measure(page, spec):
    cdp = page.context.new_cdp_session(page)
    cdp.send("Network.enable")

    recorder = WireRecorder()
    recorder.attach(cdp)

    page.goto(spec["url"], wait_until="load")
    page.wait_for_timeout(3000)

    before = read_value(page, spec)
    recorder.active = True
    page.locator(spec["button"]).first.click(force=True)
    wait_until_changed(page, spec, before)
    page.wait_for_timeout(400)
    recorder.active = False
    after = read_value(page, spec)

    cdp.send("Network.disable")
    cdp.detach()
    return recorder.snapshot(before, after)


def warm_up(browser, spec, runs=2):
    """Open and click the page before measuring, discarding what it loads.

    A development server compiles and serves assets on first use, and a framework may
    lazy-load a chunk on the first event it ever handles. Neither belongs to the click
    being measured, so the page is opened and clicked a couple of times first and the
    traffic of those runs is thrown away.
    """
    for _ in range(runs):
        context = browser.new_context()
        page = context.new_page()
        try:
            measure(page, spec)
        finally:
            context.close()


def main():
    results = {}
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, executable_path=str(CHROME))
        for name, spec in STACKS.items():
            warm_up(browser, spec)
            runs = []
            for _ in range(REPEATS):
                context = browser.new_context()
                page = context.new_page()
                try:
                    runs.append(measure(page, spec))
                except Exception as exc:
                    runs.append({"error": "%s: %s" % (type(exc).__name__, exc)})
                finally:
                    context.close()
            ok = [r for r in runs if "error" not in r]
            if not ok:
                results[name] = {"error": runs[0]["error"]}
                continue
            results[name] = {
                "repeats": len(ok),
                "sent_bytes": [r["sent"] for r in ok],
                "received_bytes": [r["received"] for r in ok],
                "total_bytes": [r["total"] for r in ok],
                "total_median": median([r["total"] for r in ok]),
                "messages": [r["msgs"] for r in ok],
                "dev_tooling_bytes": [r["dev"] for r in ok],
                "value_changed": all(r["after"] not in (None, r["before"]) for r in ok),
                "sample": {
                    "before": ok[0]["before"],
                    "after": ok[0]["after"],
                    "breakdown": ok[0]["kinds"],
                },
            }
        browser.close()
    print(json.dumps(results, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
