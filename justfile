check:
    moon check --deny-warn
fmt:
    moon fmt
    moon info
build:
    moon build --target native --release

run:
    moon run --target native --release src/apps/game/main.mbt