# cmd/maple

Maple Moon browser debugging CLI implemented as a MoonBit JS target main package.

Run this development tool through MoonBit:

```bash
moon run --target js src/cmd/maple start
moon run --target js src/cmd/maple wait-ready
moon run --target js src/cmd/maple cmd new_character
moon run --target js src/cmd/maple cmd select_char 0
moon run --target js src/cmd/maple cmd warp 100000000 0
moon run --target js src/cmd/maple logs --level error
```

`maple start` launches `src/cmd/mapled`; no external runtime script is required.
