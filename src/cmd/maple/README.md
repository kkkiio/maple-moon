# cmd/maple

Maple Moon browser debugging CLI implemented as a MoonBit JS target main package.

Run this development tool through MoonBit:

```bash
moon run --target js src/cmd/maple start
moon run --target js src/cmd/maple open --wait
moon run --target js src/cmd/maple status --wait
moon run --target js src/cmd/maple wait-ready
moon run --target js src/cmd/maple cmd new_character
moon run --target js src/cmd/maple cmd select_char 0
moon run --target js src/cmd/maple cmd warp 100000000 0
moon run --target js src/cmd/maple logs --level error
moon run --target js src/cmd/maple logs --clear
moon run --target js src/cmd/maple logs --follow --out logs/browser.log
```

`maple start` only launches or reuses `src/cmd/mapled`. `maple open --wait`
waits for the requested URL and explicitly opens the controlled Chrome.
`maple logs --follow` streams collected entries to stdout and the requested
file. `maple status --wait` waits for the daemon socket without starting it.
`just dev` uses `concurrently` to compose these commands with foreground Vite
and `mapled` processes.
