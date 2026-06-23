check:
    moon check --target js --deny-warn --diagnostic-limit 200
    moon check --target native --deny-warn --diagnostic-limit 200
fmt:
    moon fmt moon.mod src/engine src/game src/apps src/tests src/cmd
    moon info
test:
    MOONBIT_NEW_NATIVE=1 moon test --target native --deny-warn --diagnostic-limit 200
update-graphics-snaps:
    MOONBIT_NEW_NATIVE=1 UPDATE_GRAPHICS_SNAPS=true moon test --target native --deny-warn --diagnostic-limit 200 $(find src/tests -mindepth 2 -maxdepth 2 -name moon.pkg -print | sed 's#/moon.pkg##' | sort)
build:
    moon build --target js --release src/apps/game_web

build-native:
    moon build --target native --release src/apps/game_native

run-native:
    moon run --target native --release src/apps/game_native

run-web:
    npm run dev
