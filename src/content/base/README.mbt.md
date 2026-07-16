# Base Content

`content/base` registers first-party implementations for script names exported
from NX resources.

```moonbit nocheck
let scripts = npc_scripts()
inspect(scripts.contains("mTaxi"), content="true")
```
