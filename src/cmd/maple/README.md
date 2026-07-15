# cmd/maple

`maple` is the native command-line client for debugging and verifying the Web
build of Maple Moon. It starts or reuses `mapled`, sends one command per
invocation, prints structured results, and exits. `logs --follow` stays attached
until interrupted.

Run it from the repository root:

```bash
moon run --target native src/cmd/maple start
moon run --target native src/cmd/maple open --wait
moon run --target native src/cmd/maple status --wait
moon run --target native src/cmd/maple wait-ready
moon run --target native src/cmd/maple cmd new_character
moon run --target native src/cmd/maple cmd select_char 0
moon run --target native src/cmd/maple cmd warp 100000000 0
moon run --target native src/cmd/maple logs --level error
moon run --target native src/cmd/maple logs --clear
moon run --target native src/cmd/maple logs --follow --out logs/browser.log
moon run --target native src/cmd/maple network --failed
moon run --target native src/cmd/maple screenshot --out screenshot.png
moon run --target native src/cmd/maple close
```

`start` launches the native daemon without opening Chrome and returns once the
launch request is accepted. `open` requests a Chrome connection and returns
immediately. Use `open --wait` when the command must wait for the requested Web
URL and an established CDP connection. `status --wait` waits for the daemon
without starting it, and `wait-ready` waits for `$console` and the active game
phase. Other commands perform one attempt and report readiness errors directly.
`close` completes daemon and owned-Chrome cleanup before returning.

`bot run` builds `game_debug`, injects one JavaScript scenario, and returns its
fixed playtest report:

```bash
moon run --target native src/cmd/maple bot run playtests/henesys_traversal.js
```
