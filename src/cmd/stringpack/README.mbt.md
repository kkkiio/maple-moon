# Stringpack

Split one `String.nx` JSON dump into loader-friendly shards under `assets/String`.

## Usage

```bash
moon run src/cmd/stringpack/main.mbt -- .local/string.nx.json assets/String
```

This command writes files like:

- `assets/String/Cash.img.json`
- `assets/String/Consume.img.json`
- `assets/String/Eqp.img.json`
- `assets/String/Npc.img.json`
- `assets/String/Skill.img.json`
