# Maple CLI Architecture for Interactive Web Verification

## Purpose

Maple Moon uses a terminal-driven browser verification loop. The tooling must
open or reconnect a persistent Chrome session, execute atomic debug commands,
collect browser console and network events, take screenshots, and run one
Playtest Bot scenario without moving Vite or the MoonBit watch build into the
browser-control process.

## Process boundary

`maple` and `mapled` are native MoonBit executables with distinct lifetimes:

- `maple` is the user-facing, normally short-lived CLI. It parses arguments,
  starts or reuses the daemon, authenticates an IPC request, prints the result,
  and exits. `logs --follow` remains connected as a streaming client.
- `mapled` is the long-lived state owner. It owns Chrome, the CDP WebSocket,
  request correlation, target selection, command execution, log and network
  ring buffers, streaming subscribers, and shutdown cleanup.
- Vite and `moon build --watch` remain independent foreground processes owned
  by `npm run dev`.

```text
┌──────────────┐  loopback TCP + token  ┌──────────────┐  CDP WebSocket  ┌──────────────┐
│ native maple │ ──────────────────────► │ native mapled│ ──────────────► │ Chrome / Web │
│ CLI/client   │ ◄────────────────────── │ daemon       │ ◄────────────── │ game_debug   │
└──────────────┘       JSON lines        └──────────────┘                 └──────────────┘
```

## Native async implementation

Both executables use the official `moonbitlang/async` packages:

- `async/process` builds `game_debug` and owns Chrome as a structured child
  process. Chrome remains scoped to the daemon task group.
- `async/socket` carries newline-delimited JSON over `127.0.0.1:39933`.
- `async/fs` reads and atomically writes daemon state, scripts, screenshots,
  and streamed log files.
- `async/http` discovers Chrome targets through the remote-debugging endpoint.
- `async/websocket` carries CDP commands, responses, and events.
- `async/signal` maps SIGINT, SIGTERM, and SIGHUP to global structured
  cancellation so task-group cleanup closes IPC, CDP, files, and Chrome.

The daemon binds loopback only. It generates a random capability token from
the macOS system random source and stores the token, endpoint, and browser configuration in a
mode-0600 state file under the system temporary directory. Every request must
present that token. A successful TCP connection plus token validation is the
liveness test; PID probing and Unix-domain-socket cleanup are unnecessary.

The official async Unix process backend does not detach an orphan child from
the caller's terminal session. `maple start` therefore uses a macOS-only,
minimal `posix_spawn` boundary with `POSIX_SPAWN_SETSID`; it resets the signal
mask, redirects stdio, and launches the already-built native daemon executable.
Build execution, explicit waiting, timeout handling, IPC, and daemon
child-process ownership remain in the official async packages.

## Command semantics

Commands are atomic operations. `start` and plain `open` acknowledge launch or
connection requests without polling readiness. Plain `status`, `observe`,
`logs`, `network`, `screenshot`, `reload`, and `close` each make one attempt.
`act` executes one namespaced game action and waits only for that action's
explicit postcondition. Waiting is exposed by `open --wait`, `status --wait`,
`wait active`, the user-supplied `playtest run --timeout-ms` execution bound,
and the streaming
`logs --follow` command. Finite IPC, HTTP, and CDP deadlines protect each
operation from hanging; they do not add readiness polling to plain commands.

`playtest run` is one atomic playtest execution primitive: it builds `game_debug`,
injects one JavaScript scenario, drives its completion, and returns a bounded
report.

`maple open` defaults to `game_debug`, which supports normal human play and
adds BotController actions. `maple open --entry web` selects the normal Web
entry without BotController. `lookup map|npc|item` reads resource-pack data in
the native client and does not require a daemon or browser.

Closing Chrome leaves `mapled` alive and clears only the CDP connection. A later
`maple open` reconnects explicitly. `mapled` never relaunches Chrome in response
to an unexpected browser disconnect. `maple close` shuts down the daemon and
the Chrome child it owns.

## CDP ownership

| Capability | CDP domain | Owner |
|---|---|---|
| Evaluate page JavaScript | `Runtime` | `mapled` |
| Console calls and exceptions | `Runtime`, `Log` | `mapled` ring buffer |
| Network requests and failures | `Network` | `mapled` ring buffer |
| Screenshots | `Page` | `mapled`, written through async FS |
| Verified game actions | `Runtime.evaluate` | one `act` request |
| Structured observation | `Runtime.evaluate` | one `observe` request |
| Playtest script execution | `Runtime.evaluate` | one `playtest run` request |

Web profiling belongs in the same daemon boundary as explicit atomic actions:

- CPU capture uses the CDP `Profiler` domain.
- JavaScript heap capture uses `HeapProfiler`.
- browser and WebGPU timelines use `Tracing`.

`mapled` owns each capture lifecycle and artifact write so an interrupted CLI
request cannot leave a profiling session active. Web profiling remains separate
from native game profiling.

## Package structure

```text
src/cmd/
├── maple/                 # native CLI and authenticated IPC client
├── mapled/                # native daemon and async runtime integration
└── mapled_protocol/       # pure CDP normalization and target selection
```

Pure protocol normalization stays outside the executable package so black-box
snapshot tests can validate CDP event mapping without starting Chrome or an IPC
server.

## Boundaries

- `mapled` does not manage Vite or `moon build --watch`.
- The protocol supports one local daemon and one controlled Chrome profile.
- Game commands remain registered through `@console.register_command`; `act`
  supplies the stable CLI namespace and client-visible completion checks.
- Browser verification complements native raylib snapshot tests and does not
  replace them.
