check:
    moon check --target js --deny-warn --diagnostic-limit 200
    moon check --target native --deny-warn --diagnostic-limit 200
fmt:
    moon fmt moon.mod src/engine src/game src/apps src/tests src/cmd
    moon info
test:
    node scripts/moon-webgpu-test.mjs
build:
    moon build --target js --release src/apps/game_web

build-native:
    moon build --target native --release src/apps/game_native

run-native:
    moon run --target native --release src/apps/game_native

run-web:
    npm run dev
