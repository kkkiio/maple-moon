# cmd/mapled

`mapled` is the native background daemon used by `src/cmd/maple`. It owns the
controlled Chrome process and CDP WebSocket, executes browser commands, and
keeps bounded console-log and network-request buffers for later CLI queries.

Start or reuse it through `maple`:

```bash
moon run --target native src/cmd/maple start
```

Starting the daemon does not open Chrome and does not require Vite. Open the
browser explicitly after the Web server is ready:

```bash
moon run --target native src/cmd/maple open --wait
```

The daemon keeps accepting commands after Chrome disconnects. Run `maple open`
again to reconnect. It exits on `maple close`, SIGINT, SIGTERM, or SIGHUP and
terminates the Chrome child process it owns. Vite and the MoonBit watch build
remain owned by `npm run dev`.

For foreground diagnosis, run the daemon directly:

```bash
moon build --target native src/cmd/mapled
_build/native/debug/build/KKKIIO/maple-moon/cmd/mapled/mapled.exe \
  --cdp-port 9333 --url http://localhost:8080
```
