# cmd/maple

`maple` is the native command-line client for debugging and verifying the Web
build of Maple Moon. It starts or reuses `mapled`, sends one command per
invocation, prints structured results, and exits. `logs --follow` stays attached
until interrupted.

Run it from the repository root:

```bash
moon run --target native src/cmd/maple start
moon run --target native src/cmd/maple open --wait
moon run --target native src/cmd/maple open --entry web --wait
moon run --target native src/cmd/maple status --wait
moon run --target native src/cmd/maple wait active
moon run --target native src/cmd/maple act character create
moon run --target native src/cmd/maple act character select 0
moon run --target native src/cmd/maple act world warp 100000000 --portal 0
moon run --target native src/cmd/maple act player teleport-to-npc 1002004
moon run --target native src/cmd/maple act npc talk 1002004
moon run --target native src/cmd/maple act ui select 1
moon run --target native src/cmd/maple act inventory ensure 2000000 --quantity 20
moon run --target native src/cmd/maple observe player
moon run --target native src/cmd/maple observe inventory
moon run --target native src/cmd/maple lookup npc Spinel
moon run --target native src/cmd/maple logs --level error
moon run --target native src/cmd/maple logs --clear
moon run --target native src/cmd/maple logs --follow --out logs/browser.log
moon run --target native src/cmd/maple network --failed
moon run --target native src/cmd/maple screenshot --out screenshot.png
moon run --target native src/cmd/maple close
```

`start` launches the native daemon without opening Chrome and returns once the
launch request is accepted. `open` requests a Chrome connection and returns
immediately. The default entry is `game_debug`; use `open --entry web` for the
normal Web entry. `open --wait` waits for the requested URL and an established
CDP connection. `status --wait` waits for the daemon without starting it, and
`wait active` waits for `$console` and the active game phase. `act` performs one
side-effecting action and verifies its postcondition. `observe` returns one
read-only runtime state section. `lookup` searches map, NPC, and item data from
the resource pack without starting Chrome. `close` completes daemon and
owned-Chrome cleanup before returning.

Raw console and JavaScript operations are explicit debug escape hatches:

```bash
moon run --target native src/cmd/maple debug command whereami
moon run --target native src/cmd/maple debug eval 'globalThis.$console.help()'
```

`playtest run` builds `game_debug`, injects one JavaScript scenario, and returns
its fixed playtest report:

```bash
moon run --target native src/cmd/maple playtest run playtests/henesys_traversal.js
```

NPC dialogue uses one stable response convention: `ui select 1` advances or
accepts, `ui select 0` declines or goes back, and `ui select -1` closes. A full
VIP Cab task can therefore stay agent-driven across multiple CLI invocations:

```bash
moon run --target native src/cmd/maple act world warp 104000000
moon run --target native src/cmd/maple act inventory set-meso 1000
moon run --target native src/cmd/maple act player teleport-to-npc 1002004
moon run --target native src/cmd/maple act npc talk 1002004
moon run --target native src/cmd/maple act ui select 1
moon run --target native src/cmd/maple act ui select 1
moon run --target native src/cmd/maple observe summary
```

For a Beginner, the final observation reports map `105070001`, portal `0`, and
the 1,000-meso fare deducted.
