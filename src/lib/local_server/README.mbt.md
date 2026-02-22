# Local Server

A local server implementation for playing the game offline.

Although there is a open-source server implementation `Cosmic`,
it is burdensome to implement the full client features, so we implement a local server here to play the game offline.

## Persistence

`LocalServer::new` requires a `db` dependency:

```moonbit nocheck
///|
let server = LocalServer::new(db=@local_server.BrowserDB::new())
```

- Character snapshot data is persisted by local server through `save_character/load_character`.
- The storage backend contract is `DB` in this package.
- Client preference storage (UI layout/size etc.) should use a separate client-side DB package, not this local-server DB.

### Character Save Layout

Local server persists character data with segmented keys:

- `db name`: `MapleMoonLocalServerDB`
- `store`: `character_meta`
  - `key`: `char:{character_id}:meta`
  - fields: `version`, `character_id`, `revision`, `updated_segment`
- `store`: `character_core`
  - `key`: `char:{character_id}:core`
  - fields: `character_id`, `revision`, `map_id`, `portal_id`, `meso`
- `store`: `character_inventory`
  - `key`: `char:{character_id}:inventory:{invtype}`
  - fields: `character_id`, `revision`, `invtype`, `slot_max`, `items`
  - `items` entry shape: `{ "slot": Int, "item_id": Int, "count": Int }`

Save timing:

- `save_character_core`: map/portal/meso updates.
- `save_character_inventory`: inventory tab updates.
- `save_character`: full save (core + inventory).

Load timing:

- Load happens after `SelectChar` with the selected `character_id`.
