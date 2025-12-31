# KKKIIO/maple-moon

A make from scratch game client for Maplestory.

It is not a goal to implement all features of the original game.

## Development

```bash
npm run dev
moon build --watch
```

Visit http://localhost:8080 to play the game.

Visit http://localhost:8080/mapeditor to open the map editor.

## Test

```bash
# run all unit tests
moon test
# test specific file
moon test src/lib/map/background.mbt
```

## Project Structure

- **`features.yaml`**: High-level feature tracking and status.
- **`docs/`**: Game Design & Features documentation.
- **`src/lib/game_server`**: Local server simulation and authoritative game state.
- **`src/lib/ui`**: Game UI components.
