# Local Server File DB

Native file-backed implementation of the local server's `DB` contract. Keeping
this package native-only prevents `moonbitlang/x/fs` and Node's `node:fs` module
from entering Web builds.

```moonbit nocheck
let db = FileDB(root_path=".local/maple-moon/local_server")
let server = @local_server.LocalServer(db=db)
ignore(server)
```
