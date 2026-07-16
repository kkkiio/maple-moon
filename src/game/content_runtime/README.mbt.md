# Content Runtime

`content_runtime` defines the target-independent NPC script contract shared by
statically compiled first-party content and the authoritative local server.

```moonbit nocheck
let scripts = @content_runtime.NpcScriptRegistry()
inspect(scripts.contains("example"), content="false")
```
