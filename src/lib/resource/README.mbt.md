# Resource

Define resource loader interface and runtime loader registry.
Concrete builtin loader wiring should be installed by upper-level packages (for example `src/game`).

Do not add cache here, cache should be added in the caller.
