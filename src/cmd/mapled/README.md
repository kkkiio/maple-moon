# cmd/mapled

Maple Moon CDP daemon used by `src/cmd/maple`.

This daemon is implemented in MoonBit. Node.js process, socket, filesystem, and
CDP WebSocket APIs are accessed through inline JS FFI in `main.mbt`.

The daemon is normally started by:

```bash
moon run --target js src/cmd/maple start
```
