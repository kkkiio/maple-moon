# cmd/mapled

Maple Moon CDP daemon used by `src/cmd/maple`.

This daemon is implemented in MoonBit. Command dispatch, daemon state, CDP
event normalization, log/network buffers, and browser lifecycle decisions stay
in MoonBit. `node_ffi.mbt` exposes thin bindings for Node.js process, socket,
filesystem, timer, and WebSocket primitives; its small CDP adapter only owns
request IDs and pending JavaScript promises.

Pure CDP protocol normalization and target selection live in the sibling
`src/cmd/mapled_protocol` package so they can be covered by JS-target blackbox
snapshot tests without importing a main package.

The daemon can be started in the background through the CLI:

```bash
moon run --target js src/cmd/maple start
```

Starting the daemon does not open Chrome or require Vite. The daemon keeps
serving CLI requests after the controlled Chrome disconnects;
`moon run --target js src/cmd/maple open --wait` explicitly waits for the game
URL, opens Chrome, and reconnects it. Live log consumers subscribe through
`maple logs --follow`.

`just dev` runs `mapled` in the foreground under `concurrently`, so terminating
the development command also terminates the daemon and its controlled Chrome.
