check:
    moon check --target js --deny-warn --warn-list=-28-79-82 --diagnostic-limit 200
    moon check --target native --deny-warn --warn-list=-28-79-82 --diagnostic-limit 200
fmt:
    moon fmt moon.mod src/engine src/game src/apps src/graphics_test src/cmd
    moon info
test:
    moon test --target native --deny-warn --warn-list=-28-79-82 --diagnostic-limit 200
update-graphics-snaps:
    UPDATE_GRAPHICS_SNAPS=true moon test --target native --deny-warn --warn-list=-28-79-82 --diagnostic-limit 200 src/graphics_test
build:
    moon build --target js --release src/apps/game_web

build-native:
    moon build --target native --release src/apps/game_native

run-native:
    moon run --target native --release src/apps/game_native

dev:
    npm run dev
