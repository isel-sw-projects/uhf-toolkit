# One click, four stacks - measurement record

Data collected to replace the earlier per-slice readings in Chapter 2. The unit is the
same on every stack: **everything exchanged from the moment the click is dispatched until
the rendered value changes**, the initial document excluded.

## Instrument

`measure-one-click.py` - Playwright driving Chromium through the
DevTools protocol, because:

- an SSE response never finishes, so a completed-response API never reports its body;
- WebSocket traffic is not a request/response pair at all.

The script counts:

- `Network.requestWillBeSent` -> request line + headers + post body (client to server)
- `Network.dataReceived` -> HTTP response body chunks, SSE included (server to client)
- `Network.webSocketFrameSent` / `Received` -> WebSocket payloads

Dev tooling (`phoenix:live_reload`) is reported apart and never inside the application
total. Two warm-up runs per stack are discarded, because a development server compiles and
serves assets on first use and Vaadin lazy-loads a chunk on the first event it handles;
neither belongs to the click being measured. Three measured runs per stack.

## Result

| Stack             | Sent (B) | Received (B) | Total (B) | Messages | Initial document (B) |
| ----------------- | -------: | -----------: | --------: | -------: | -------------------: |
| HtmlFlow-Datastar |      796 |          146 |   **942** |        3 |                  493 |
| Blazor Server     |      532 |          344 |   **876** |        4 |               12 694 |
| Phoenix LiveView  |      102 |          106 |   **208** |        4 |               14 642 |
| Vaadin Flow       |      684 |          212 |   **893** |        2 |               14 189 |

Run variance: zero bytes for HtmlFlow and Blazor; a byte or two on the Vaadin response.

Messages are counted per delivery: the HtmlFlow click is a `POST` plus the request line of
the SSE stream that was already open, plus one frame, so three messages for 796 bytes sent
and 146 received. An earlier count of two was wrong: the already-open stream added its
bytes without incrementing the counter.

Per-run breakdown:

- HtmlFlow: `POST 415` + `GET 381` (the SSE stream, opened before the click, charged to
  it because it is what delivers the change) + `res 146`.
- Blazor: `ws> 496`, `ws< 300`, `ws> 36`, `ws< 44`.
- LiveView: `ws> 102`, `ws< 106`, plus 439 B of `phoenix:live_reload` tooling excluded.
- Vaadin: `POST 684`, `res 212` (the XHR half; the server push travels on a WebSocket and
  is not part of this total).

## Initial documents

| Route                                   |                                                 Bytes |
| --------------------------------------- | ----------------------------------------------------: |
| `/multi-client-counter/htmlflow` (Ktor) |                                                   493 |
| `/multi-client-counter/html` (static)   |                                                   843 |
| `/counter/htmlflow`                     | 0 (no such route; the counter ships as a static page) |
| `/counter/html`                         |                                                   744 |
| Blazor `/multi-client-counter`          |                                         12 674–12 694 |
| Blazor `/counter`                       |                                                12 300 |
| LiveView `/multi-client-counter`        |                                                14 642 |
| LiveView `/counter`                     |                                                14 434 |
| Vaadin `/example/multi-client-counter`  |                                                14 190 |
| Vaadin `/example/counter`               |                                                14 190 |

## Environment

Exact versions used for the numbers above, so the measurement can be repeated or
disputed:

| Component       | Version                                |
| --------------- | -------------------------------------- |
| JDK             | 21.0.8 LTS                             |
| Kotlin          | 2.3.0                                  |
| .NET SDK        | 10.0.403                               |
| Elixir / Erlang | 1.20.4 / OTP 29                        |
| Vaadin Flow     | 25.2.8                                 |
| Chromium        | the build shipped with Playwright 1140 |

## Scripts

- `count-wiring-points.py` - counts wiring points per view against a fixed list of
  markers; produces Table 2.5 of the dissertation.

## What this does not establish

- It does not compare functional equivalence beyond the shared counter.
- It does not measure concurrency under load; it establishes only that a single click on
  the corrected code is correct, and that the increment path is atomic.
- It does not measure latency. The earlier single-run latency note was withdrawn rather
  than kept without a protocol.
- Run on localhost, development mode, one machine.
