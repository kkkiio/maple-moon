# maple-moon

A from-scratch game client for MapleStory. Built with [MoonBit](https://www.moonbitlang.com/) and [Selene](https://github.com/Yoorkin/selene), a small 2D game engine.

Reimplementing every feature of the original game is not a goal.

## Installation

```bash
git clone <repo-url>
cd maple-moon
npm install
```

Requires [Node.js](https://nodejs.org/) and [MoonBit](https://www.moonbitlang.com/download/).

## Usage

### Play in browser

```bash
npm run dev
moon build --watch
```

Open http://localhost:8080.

### Build native executable

```bash
just build-native
```

Produces an executable with the `assets/` directory alongside it. Place both in the same folder and run the executable.

