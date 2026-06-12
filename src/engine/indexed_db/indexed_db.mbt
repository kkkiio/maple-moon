///|
/// Synchronous browser storage facade kept behind the old package name.
pub struct IndexedDB {
  name : String
}

///|
/// Open a browser-local store namespace.
pub fn open(name : String, version : Int, stores : Array[String]) -> IndexedDB {
  ignore(version)
  ignore(stores)
  { name, }
}

///|
pub fn IndexedDB::save_json(
  self : IndexedDB,
  store : String,
  key : String,
  data : Json,
) -> Unit {
  local_storage_set(storage_key(self.name, store, key), data.stringify())
}

///|
pub fn IndexedDB::load_json(
  self : IndexedDB,
  store : String,
  key : String,
) -> Json? {
  match local_storage_get(storage_key(self.name, store, key)) {
    Some(json_str) => (@json.parse(json_str) |> Some) catch { _ => None }
    None => None
  }
}

///|
fn storage_key(name : String, store : String, key : String) -> String {
  "maple-moon:\{name}:\{store}:\{key}"
}

///|
extern "js" fn local_storage_set(key : String, value : String) -> Unit =
  #| (key, value) => {
  #|   globalThis.localStorage?.setItem(key, value);
  #| }

///|
extern "js" fn local_storage_get(key : String) -> String? =
  #| (key) => {
  #|   const value = globalThis.localStorage?.getItem(key);
  #|   return value == null ? undefined : value;
  #| }
