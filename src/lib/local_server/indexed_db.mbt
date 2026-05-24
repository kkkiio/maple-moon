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
/// Generic persistence backend.
pub(open) trait DB {
  fn save_json(Self, String, String, Json) -> Unit
  fn load_json(Self, String, String) -> Json?
}

///|
/// File-backed DB for the native local server.
pub struct FileDB {
  root_path : String
}

///|
/// Create a file-backed DB under `root_path`.
///
/// # Example
/// ```moonbit nocheck
/// let db = FileDB::new(root_path=".local/maple-moon/local_server")
/// inspect(db.root_path_for_debug(), content=".local/maple-moon/local_server")
/// ```
pub fn FileDB::new(
  root_path? : String = ".local/maple-moon/local_server",
) -> FileDB {
  { root_path, }
}

///|
/// Return the root path used by this DB. Intended for diagnostics and tests.
pub fn FileDB::root_path_for_debug(self : FileDB) -> String {
  self.root_path
}

///|
fn FileDB::store_dir(self : FileDB, store : String) -> String {
  join_file_path(self.root_path, safe_file_part(store))
}

///|
fn FileDB::data_file_path(
  self : FileDB,
  store : String,
  key : String,
) -> String {
  join_file_path(self.store_dir(store), safe_file_part(key) + ".json")
}

///|
fn safe_file_part(value : String) -> String {
  value
  .replace(old="\\", new="-")
  .replace(old="/", new="-")
  .replace(old=":", new="-")
  .replace(old=" ", new="_")
}

///|
fn join_file_path(root : String, child : String) -> String {
  let root = root.strip_suffix("/").unwrap_or(root)
  let child = child.strip_prefix("/").unwrap_or(child)
  "\{root}/\{child}"
}

///|
fn ensure_dir_recursive(path : String) -> Unit {
  let normalized = path.replace(old="\\", new="/")
  let mut current = if normalized.has_prefix("/") { "/" } else { "" }
  for part in normalized.split("/") {
    if part.is_empty() {
      continue
    }
    current = if current.is_empty() || current == "/" {
      current + part.to_owned()
    } else {
      current + "/" + part.to_owned()
    }
    if !@fs.path_exists(current) {
      @fs.create_dir(current) catch {
        err =>
          if !@fs.path_exists(current) {
            abort("failed to create directory: \{current}, error=\{err}")
          }
      }
    }
  }
}

///|
pub impl DB for FileDB with fn save_json(self, store, key, data) {
  let dir = self.store_dir(store)
  ensure_dir_recursive(dir)
  let path = self.data_file_path(store, key)
  @fs.write_string_to_file(path, data.stringify()) catch {
    err => abort("failed to write local server data: \{path}, error=\{err}")
  }
}

///|
pub impl DB for FileDB with fn load_json(self, store, key) {
  let path = self.data_file_path(store, key)
  if !@fs.path_exists(path) {
    return None
  }
  let content = @fs.read_file_to_string(path) catch {
    err => abort("failed to read local server data: \{path}, error=\{err}")
  }
  Some(
    @json.parse(content) catch {
      _ => abort("failed to parse local server data: \{path}")
    },
  )
}

///|
/// In-memory DB implementation for tests.
pub struct MemoryDB {
  stores : Ref[Map[String, Map[String, Json]]]
}

///|
pub fn MemoryDB::new() -> MemoryDB {
  { stores: Ref({}) }
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
  self.stores.val.get_or_init(store, fn() { Map([]) })
}

///|
pub impl DB for MemoryDB with fn save_json(self, store, key, data) {
  self.get_or_init_store(store).set(key, clone_json(data))
}

///|
pub impl DB for MemoryDB with fn load_json(self, store, key) {
  guard self.stores.val.get(store) is Some(store_map) else { return None }
  match store_map.get(key) {
    Some(data) => Some(clone_json(data))
    None => None
  }
}

///|
/// Browser-local DB for JS/WebGPU builds.
///
/// # Example
/// ```moonbit nocheck
/// let db = BrowserDB::new()
/// db.save_json("store", "key", { "ok": true })
/// ```
#cfg(target="js")
pub struct BrowserDB {
  name : String
}

///|
/// Create a browser-local DB under the Maple Moon local-server namespace.
///
/// # Example
/// ```moonbit nocheck
/// let db = BrowserDB::new()
/// ```
#cfg(target="js")
pub fn BrowserDB::new(name? : String = "MapleMoonLocalServerDB") -> BrowserDB {
  { name, }
}

///|
#cfg(target="js")
fn browser_storage_key(name : String, store : String, key : String) -> String {
  "maple-moon:\{name}:\{safe_file_part(store)}:\{safe_file_part(key)}"
}

///|
#cfg(target="js")
extern "js" fn browser_storage_set(key : String, value : String) -> Unit =
  #| (key, value) => {
  #|   globalThis.localStorage?.setItem(key, value);
  #| }

///|
#cfg(target="js")
extern "js" fn browser_storage_get(key : String) -> String? =
  #| (key) => {
  #|   const value = globalThis.localStorage?.getItem(key);
  #|   return value == null ? undefined : value;
  #| }

///|
#cfg(target="js")
pub impl DB for BrowserDB with fn save_json(self, store, key, data) {
  browser_storage_set(
    browser_storage_key(self.name, store, key),
    data.stringify(),
  )
}

///|
#cfg(target="js")
pub impl DB for BrowserDB with fn load_json(self, store, key) {
  match browser_storage_get(browser_storage_key(self.name, store, key)) {
    Some(json_str) =>
      Some(
        @json.parse(json_str) catch {
          _ => abort("failed to parse browser local server data")
        },
      )
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
pub fn LocalServer::save_character_roster(self : LocalServer) -> Unit {
  self.db.save_json(character_roster_store_name, character_roster_key(), {
    "characters": self.character_roster.to_json(),
  })
}

///|
pub fn LocalServer::load_character_roster(self : LocalServer) -> Bool {
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
        ) catch {
          _ => abort("invalid character roster entry")
        }
        self.character_roster.push(entry)
      }
      true
    }
    _ => false
  }
}

///|
fn LocalServer::save_character_meta(
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
fn LocalServer::save_character_core_data(
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
pub fn LocalServer::save_character_core(
  self : LocalServer,
  character_id : Int,
) -> Unit {
  let revision = self.bump_character_revision()
  self.save_character_core_data(character_id, revision)
  self.save_character_meta(character_id, revision, "core")
}

///|
pub fn LocalServer::save_character_inventory(
  self : LocalServer,
  character_id : Int,
) -> Unit {
  let revision = self.bump_character_revision()
  self.save_character_inventory_data(character_id, revision)
  self.save_character_meta(character_id, revision, "inventory")
}

///|
pub fn LocalServer::save_character(
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
pub fn LocalServer::load_character(
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
pub fn LocalServer::save_character_quest_data(
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
        let quest_id = @string.parse_int(quest_id_str) catch { _ => continue }
        guard progress_json is String(progress) else { continue }
        self.started_quests.set(quest_id, progress)
      }
      self.completed_quests.clear()
      for quest_id_str, time_json in completed_map {
        let quest_id = @string.parse_int(quest_id_str) catch { _ => continue }
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
