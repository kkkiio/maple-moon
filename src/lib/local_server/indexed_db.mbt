///|
let local_server_db_name : String = "MapleMoonLocalServerDB"

///|
let character_meta_store_name : String = "character_meta"

///|
let character_core_store_name : String = "character_core"

///|
let character_inventory_store_name : String = "character_inventory"

///|
let character_quest_store_name : String = "character_quest"

///|
let character_roster_store_name : String = "character_roster"

///|
/// Generic async persistence backend.
pub(open) trait DB {
  async save_json(Self, String, String, Json) -> Unit
  async load_json(Self, String, String) -> Json?
}

///|
pub struct BrowserDB {
  db_ref : Ref[@indexed_db.IndexedDB?]
}

///|
pub fn BrowserDB::new() -> BrowserDB {
  { db_ref: Ref::new(None) }
}

///|
async fn BrowserDB::ensure_indexed_db(
  self : BrowserDB,
) -> @indexed_db.IndexedDB {
  if self.db_ref.val is Some(db) {
    return db
  }
  let db = @indexed_db.open(local_server_db_name, 4, [
    character_meta_store_name, character_core_store_name, character_inventory_store_name,
    character_quest_store_name, character_roster_store_name,
  ])
  self.db_ref.val = Some(db)
  db
}

///|
pub impl DB for BrowserDB with save_json(self, store, key, data) {
  let db = self.ensure_indexed_db()
  let _ = db.save_json_promise(store, key, data).wait()
}

///|
pub impl DB for BrowserDB with load_json(self, store, key) {
  let db = self.ensure_indexed_db()
  db.load_json(store, key)
}

///|
/// In-memory DB implementation for tests.
pub struct MemoryDB {
  stores : Ref[Map[String, Map[String, Json]]]
}

///|
pub fn MemoryDB::new() -> MemoryDB {
  { stores: Ref::new({}) }
}

///|
pub fn MemoryDB::get_json(
  self : MemoryDB,
  store : String,
  key : String,
) -> Json? {
  guard self.stores.val.get(store) is Some(store_map) else { return None }
  match store_map.get(key) {
    Some(data) => Some(clone_json(data))
    None => None
  }
}

///|
fn MemoryDB::get_or_init_store(
  self : MemoryDB,
  store : String,
) -> Map[String, Json] {
  self.stores.val.get_or_init(store, fn() { Map::new() })
}

///|
pub impl DB for MemoryDB with save_json(self, store, key, data) {
  self.get_or_init_store(store).set(key, clone_json(data))
}

///|
pub impl DB for MemoryDB with load_json(self, store, key) {
  guard self.stores.val.get(store) is Some(store_map) else { return None }
  match store_map.get(key) {
    Some(data) => Some(clone_json(data))
    None => None
  }
}

///|
fn clone_json(data : Json) -> Json {
  @json.parse(data.stringify()) catch {
    err => abort("failed to clone json: \{err.to_string()}")
  }
}

///|
fn character_meta_key(character_id : Int) -> String {
  "char:\{character_id}:meta"
}

///|
fn character_core_key(character_id : Int) -> String {
  "char:\{character_id}:core"
}

///|
fn character_inventory_tab_key(
  character_id : Int,
  invtype : @server_proto.InventoryType,
) -> String {
  "char:\{character_id}:inventory:\{invtype.int_value()}"
}

///|
fn character_quest_key(character_id : Int) -> String {
  "char:\{character_id}:quests"
}

///|
fn inventory_tabs() -> Array[@server_proto.InventoryType] {
  [
    @server_proto.InventoryType::EQUIP,
    @server_proto.InventoryType::USE,
    @server_proto.InventoryType::SETUP,
    @server_proto.InventoryType::ETC,
    @server_proto.InventoryType::CASH,
    @server_proto.InventoryType::EQUIPPED,
  ]
}

///|
fn character_roster_key() -> String {
  "account:default:characters"
}

///|
pub async fn LocalServer::save_character_roster(self : LocalServer) -> Unit {
  self.db.save_json(character_roster_store_name, character_roster_key(), {
    "characters": self.character_roster.to_json(),
  })
}

///|
pub async fn LocalServer::load_character_roster(self : LocalServer) -> Bool {
  guard self.db.load_json(character_roster_store_name, character_roster_key())
    is Some(data) else {
    return false
  }
  match data {
    { "characters": Array(chars), .. } => {
      self.character_roster.clear()
      for char_json in chars {
        let entry : @server_proto.CharacterListEntry = @json.from_json(
          char_json,
        )
        self.character_roster.push(entry)
      }
      true
    }
    _ => false
  }
}

///|
async fn LocalServer::save_character_meta(
  self : LocalServer,
  character_id : Int,
  revision : Int,
  segment : String,
) -> Unit {
  self.db.save_json(
    character_meta_store_name,
    character_meta_key(character_id),
    {
      "version": 2,
      "character_id": character_id,
      "revision": revision,
      "updated_segment": segment,
    },
  )
}

///|
async fn LocalServer::save_character_core_data(
  self : LocalServer,
  character_id : Int,
  revision : Int,
) -> Unit {
  self.db.save_json(
    character_core_store_name,
    character_core_key(character_id),
    {
      "character_id": character_id,
      "revision": revision,
      "map_id": self.last_map_id,
      "portal_id": self.last_portal_id,
      "meso": self.player_meso,
    },
  )
}

///|
pub async fn LocalServer::save_character_core(
  self : LocalServer,
  character_id : Int,
) -> Unit {
  let revision = self.bump_character_revision()
  self.save_character_core_data(character_id, revision)
  self.save_character_meta(character_id, revision, "core")
}

///|
pub async fn LocalServer::save_character_inventory(
  self : LocalServer,
  character_id : Int,
) -> Unit {
  let revision = self.bump_character_revision()
  self.save_character_inventory_data(character_id, revision)
  self.save_character_meta(character_id, revision, "inventory")
}

///|
pub async fn LocalServer::save_character(
  self : LocalServer,
  character_id : Int,
) -> Unit {
  let revision = self.bump_character_revision()
  self.save_character_core_data(character_id, revision)
  self.save_character_inventory_data(character_id, revision)
  self.save_character_quest_data(character_id, revision)
  self.save_character_meta(character_id, revision, "full")
}

///|
fn LocalServer::load_character_core_data(
  self : LocalServer,
  data : Json,
) -> Unit {
  match data {
    {
      "map_id": Number(map_id, ..),
      "portal_id": Number(portal_id, ..),
      "meso": Number(meso, ..),
      "revision": Number(revision, ..),
      ..
    } => {
      self.last_map_id = map_id.to_int()
      self.last_portal_id = portal_id.to_int()
      self.player_meso = meso.to_int()
      self.character_revision = revision.to_int()
    }
    {
      "map_id": Number(map_id, ..),
      "portal_id": Number(portal_id, ..),
      "meso": Number(meso, ..),
      ..
    } => {
      self.last_map_id = map_id.to_int()
      self.last_portal_id = portal_id.to_int()
      self.player_meso = meso.to_int()
    }
    _ => ()
  }
}

///|
pub async fn LocalServer::load_character(
  self : LocalServer,
  character_id : Int,
) -> Bool {
  self.reset_player_inventory_state()
  let mut loaded_any = false
  if self.db.load_json(
      character_core_store_name,
      character_core_key(character_id),
    )
    is Some(data) {
    loaded_any = true
    self.load_character_core_data(data)
  }
  for invtype in inventory_tabs() {
    if self.db.load_json(
        character_inventory_store_name,
        character_inventory_tab_key(character_id, invtype),
      )
      is Some(data) {
      loaded_any = true
      self.load_character_inventory_tab_data(data)
    }
  }
  if self.db.load_json(
      character_quest_store_name,
      character_quest_key(character_id),
    )
    is Some(data) {
    loaded_any = true
    self.load_character_quest_data(data)
  } else {
    self.set_default_quest_state()
  }
  loaded_any
}

///|
pub async fn LocalServer::save_character_quest_data(
  self : LocalServer,
  character_id : Int,
  revision : Int,
) -> Unit {
  self.db.save_json(
    character_quest_store_name,
    character_quest_key(character_id),
    {
      "character_id": character_id,
      "revision": revision,
      "started": self.started_quests.to_json(),
      "completed": self.completed_quests.to_json(),
    },
  )
}

///|
fn LocalServer::load_character_quest_data(
  self : LocalServer,
  data : Json,
) -> Unit {
  match data {
    { "started": Object(started_map), "completed": Object(completed_map), .. } => {
      self.started_quests.clear()
      for quest_id_str, progress_json in started_map {
        let quest_id = @strconv.parse_int(quest_id_str) catch { _ => continue }
        guard progress_json is String(progress) else { continue }
        self.started_quests.set(quest_id, progress)
      }
      self.completed_quests.clear()
      for quest_id_str, time_json in completed_map {
        let quest_id = @strconv.parse_int(quest_id_str) catch { _ => continue }
        guard time_json is Number(completion_time, ..) else { continue }
        self.completed_quests.set(quest_id, completion_time.to_int64())
      }
      if data is { "revision": Number(revision, ..), .. } &&
        revision.to_int() > self.character_revision {
        self.character_revision = revision.to_int()
      }
    }
    _ => self.set_default_quest_state()
  }
}
