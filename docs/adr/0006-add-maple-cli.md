# ADR 0006: Add maple CLI for Interactive Debugging and Verification

Date: 2026-06-15

## Status

Accepted, amended by [ADR 0008](0008-testing-strategy-boundaries.md)

## Context

The project currently runs in a browser through the Vite dev server. Debugging
requires:

- Opening browser DevTools and manually typing `$console.cmd(...)` for every
  test action (warp, item, meso, etc.).
- Manually watching the Console tab for JS errors and the Network tab for
  failed resource loads.
- Restarting the game from scratch after a code change, because Vite HMR does
  not apply to MoonBit-compiled JS.

This workflow is slow and repetitive. We want a CLI tool that can:

1. Start or reconnect to a persistent browser controlled through CDP.
2. Send short, one-off debug commands (`warp`, `item`, `meso`, etc.).
3. Read browser console logs to catch JS errors without opening DevTools.
4. Monitor network requests to verify script and resource loading.

The tool should feel like a single project-local command that manages the
interactive verification loop while leaving the existing build workflow intact.
Developers still run Vite and MoonBit watch builds explicitly.

The [browser-use](https://github.com/browser-use/browser-use) project
demonstrates a similar architecture: a CLI talks to a background daemon over
a Unix socket, and the daemon controls a persistent Chromium via CDP
(Chrome DevTools Protocol). We can adapt this pattern with a much simpler
implementation, since we don't need LLM-driven web automation — just CDP
command execution and event collection.

## Decision

### Naming

- **`maple`** — the user-facing CLI tool. In development it is executed with
  `moon run --target js src/cmd/maple ...`, for example
  `moon run --target js src/cmd/maple cmd warp 100000000 0`.
- **`mapled`** — the background daemon process, following the Unix `sshd`/`dockerd` convention.

### Directory structure

Only two main packages under `src/cmd/`:

```
src/cmd/
├── maple/                # CLI entry point (js target, main)
│   ├── moon.pkg
│   └── main.mbt
│
└── mapled/               # Daemon (js target, main)
    ├── moon.pkg
    └── main.mbt
```

Debug commands continue to be registered in existing game modules through
`@console.register_command` in `init` blocks. The current v1 command surface is
the already-registered `warp`, `meso`, `item`, `new_character`, `select_char`,
and `temp_set_field_enter`. Commands such as `jump`, `attack`, `spawn_mob`, and
`set_hp` require separate game-side semantics before the CLI can expose them.

### Architecture

```
Terminal 1: npm run dev
Terminal 2: moon build --watch --target js --release src/apps/game_web
       │
       ▼
  localhost:8080
       ▲
       │
┌──────────┐  Unix Socket   ┌──────────┐  CDP WebSocket   ┌─────────────┐
│  maple   │ ◄─────────────► │  mapled  │ ◄──────────────► │   Chrome    │
│  (CLI)   │  JSON-RPC      │ (Daemon) │                  │ localhost:8080│
└──────────┘                └──────────┘                  └─────────────┘
```

Vite and the MoonBit watch build are **not** managed by `mapled`. The developer
starts them explicitly, keeping the normal browser workflow and avoiding hidden
build state. `maple start` checks `http://localhost:8080`, starts `mapled` if
needed, and asks the daemon to open Chrome at that URL.

- **`maple`** is a short-lived process: parse args with
  `moonbitlang/core/argparse`, send a JSON request to `mapled` over a Unix
  socket, print the response, exit.
- **`mapled`** is a long-lived daemon. It:
  1. Spawns Chrome with `--remote-debugging-port`, navigating to
     `http://localhost:8080`.
  2. Opens a CDP WebSocket connection to Chrome.
  3. Listens on a Unix socket for CLI requests.
  4. Collects console logs and network events into in-memory ring buffers.
  5. Writes small state/PID files in the temp directory so `maple start` and
     `maple close` can distinguish a live daemon from stale socket files.
  6. Exits when Chrome disconnects or when `maple close` requests shutdown.

### Key CDP capabilities used

| Feature | CDP Domain | Events / Methods |
|---------|-----------|-----------------|
| Execute JS in the page | `Runtime` | `Runtime.evaluate` |
| Capture console.log/error/warn | `Runtime` | `Runtime.consoleAPICalled` |
| Capture uncaught exceptions | `Runtime` | `Runtime.exceptionThrown` |
| Broader log entries (CSP, network errors) | `Log` | `Log.entryAdded` |
| Monitor network requests | `Network` | `requestWillBeSent`, `responseReceived`, `loadingFinished`, `loadingFailed` |
| Take screenshots | `Page` | `Page.captureScreenshot` |

### Implementation language

Both `maple` and `mapled` are implemented as **MoonBit JS target** main
packages. They define the command shape with `moonbitlang/core/argparse`, use
`async fn main`, and wait on JavaScript promises through
`moonbitlang/async/js_async`. Development execution uses `moon run --target js`:

```bash
moon run --target js src/cmd/maple start
moon run --target js src/cmd/maple cmd warp 100000000 0
moon run --target js src/cmd/maple logs --level error
```

Node/CDP/socket interop is expressed as inline `extern "js"` FFI inside the
MoonBit source files. There are no separate runtime scripts.

Node.js APIs used by the MoonBit JS FFI:

- `node:child_process` — spawn Chrome and start `mapled` from `maple start`.
- `node:net` — Unix socket server for CLI ↔ daemon communication.
- `node:fs`, `node:os`, `node:path` — temp-directory state/PID/socket files.
- Node 24 native `WebSocket` — CDP WebSocket client. The project does not
  support lower Node versions for this tool and does not add a `ws` dependency.
- `moonbitlang/core/argparse` — declarative subcommand and option parsing.
- `moonbitlang/async/js_async` — wait for Node promises from MoonBit.

### CLI interface

```bash
moon run --target js src/cmd/maple start
moon run --target js src/cmd/maple status
moon run --target js src/cmd/maple wait-ready
moon run --target js src/cmd/maple cmd warp 100000000 0
moon run --target js src/cmd/maple cmd meso 1000000
moon run --target js src/cmd/maple cmd char_list
moon run --target js src/cmd/maple cmd new_character
moon run --target js src/cmd/maple cmd select_char 0
moon run --target js src/cmd/maple logs
moon run --target js src/cmd/maple logs --level error
moon run --target js src/cmd/maple network
moon run --target js src/cmd/maple network --failed
moon run --target js src/cmd/maple screenshot --out screenshot.png
moon run --target js src/cmd/maple eval "globalThis.$console.render_game_to_text()"
moon run --target js src/cmd/maple bot run playtests/henesys_traversal.js
moon run --target js src/cmd/maple reload
moon run --target js src/cmd/maple close
```

All commands are **atomic operations** — each does exactly one thing.
Verification workflows are composed by the caller (human or agent) from
individual commands. The CLI itself does not provide composite verification
routines (see ADR 0008). `maple bot run` is the ADR 0007 exception: it is a
single playtest execution primitive that loads `game_debug.html`, injects one JS
script, and returns a fixed pass/fail report.

## Consequences

### Positive

- **Terminal-driven verify loop**: start Vite and MoonBit watch build once,
  then use `maple start` → `maple cmd ...` → inspect logs/network → fix code →
  reload/retry. No manual DevTools interaction needed.
- **Console and network visibility in terminal**: errors and failed requests are
  immediately visible in the same terminal where commands are sent.
- **Single language stack**: both game and tooling are MoonBit, sharing types
  and toolchain.
- **Daemon keeps browser alive**: game assets load once, then fast iteration
  on commands.

### Risks & mitigation

- **MoonBit JS async and Node interop maturity**: long-lived socket and CDP event
  handling are less exercised than browser gameplay code.
  - *Mitigation*: keep the MoonBit surface thin, implement Node/CDP plumbing in
    explicit JS FFI blocks, and validate the daemon with real browser sessions.
- **CDP connection fragility**: Chrome may disconnect on page crash or navigation.
  - *Mitigation*: v1 reports disconnection clearly and exits on `close`; automatic
    recovery can be added later if repeated sessions need it.
- **Chrome remote debugging port conflict**: the default 9222 may be in use.
  - *Mitigation*: pick a non-default port with a `--cdp-port` flag.

### Non-goals (for now)

- Multi-session support (browser-use's `--session` flag). Single daemon is
  sufficient for local debugging.
- Native binary distribution of `maple`/`mapled`. JS target via Node.js is
  adequate for a dev tool.
- Managing Vite or `moon build --watch`. Those remain explicit developer
  terminals.
- A TUI interface. Plain CLI output is enough for the verification loop.
- Lower Node.js versions without native `WebSocket`.

## Implementation plan

1. **Implement `mapled`**: spawn Chrome, connect CDP with Node native
   `WebSocket`, enable `Runtime`, `Log`, `Network`, and `Page`.
2. **Add Unix socket server** to `mapled` with one-request JSON messages.
3. **Implement `maple` CLI** with `moonbitlang/core/argparse`, connecting to
   `mapled` and printing structured responses.
4. **Collect console and network logs** in daemon-side ring buffers.
5. **Drive map load and verify** by sending console commands, stepping frames
   via `eval`, and checking logs/network failures — as separate atomic steps.
6. **Register additional debug commands later** only after their game-side
   behavior is well-defined.
