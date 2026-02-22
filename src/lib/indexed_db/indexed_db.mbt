///|
/// Browser IndexedDB-backed implementation.
pub struct IndexedDB {
  db : @js.Value
}

///|
/// Open an IndexedDB database and ensure all stores exist.
pub async fn open(
  name : String,
  version : Int,
  stores : Array[String],
) -> IndexedDB {
  let stores_value = @js.Value::cast_from(stores)
  let db = indexed_db_open_promise(name, version, stores_value).wait()
  IndexedDB::{ db: @js.Value::cast_from(db) }
}

///|
pub fn IndexedDB::save_json(
  self : IndexedDB,
  store : String,
  key : String,
  data : Json,
) -> Unit {
  let json_str = data.stringify()
  let _ = save_json_promise(self.db, store, key, json_str)
}

///|
pub fn IndexedDB::save_json_promise(
  self : IndexedDB,
  store : String,
  key : String,
  data : Json,
) -> @js.Promise {
  let json_str = data.stringify()
  save_json_promise(self.db, store, key, json_str)
}

///|
pub fn IndexedDB::load_json_promise(
  self : IndexedDB,
  store : String,
  key : String,
) -> @js.Promise {
  load_json_promise(self.db, store, key)
}

///|
pub async fn IndexedDB::load_json(
  self : IndexedDB,
  store : String,
  key : String,
) -> Json? {
  let val = load_json_promise(self.db, store, key).wait()
  if @js.Value::is_null(val) || @js.Value::is_undefined(val) {
    None
  } else {
    let json_str : String = @js.Value::cast(val)
    (@json.parse(json_str) |> Some) catch {
      _ => None
    }
  }
}

// FFI

///|
extern "js" fn indexed_db_open_promise(
  name : String,
  version : Int,
  stores : @js.Value,
) -> @js.Promise =
  #| (name, version, stores) => new Promise((resolve, reject) => {
  #|   const req = indexedDB.open(name, version);
  #|   req.onsuccess = () => resolve(req.result);
  #|   req.onerror = () => reject(req.error);
  #|   req.onupgradeneeded = (e) => {
  #|     const db = e.target.result;
  #|     for (const store of stores) {
  #|       if (!db.objectStoreNames.contains(store)) {
  #|         db.createObjectStore(store);
  #|       }
  #|     }
  #|   };
  #| })

///|
extern "js" fn save_json_promise(
  db : @js.Value,
  store : String,
  key : String,
  json_str : String,
) -> @js.Promise =
  #| (db, store, key, json_str) => new Promise((resolve, reject) => {
  #|   const tx = db.transaction(store, "readwrite");
  #|   const objStore = tx.objectStore(store);
  #|   const req = objStore.put(JSON.parse(json_str), key);
  #|   req.onsuccess = () => resolve(req.result);
  #|   req.onerror = () => reject(req.error);
  #| })

///|
extern "js" fn load_json_promise(
  db : @js.Value,
  store : String,
  key : String,
) -> @js.Promise =
  #| (db, store, key) => new Promise((resolve, reject) => {
  #|   const tx = db.transaction(store, "readonly");
  #|   const objStore = tx.objectStore(store);
  #|   const req = objStore.get(key);
  #|   req.onsuccess = () => resolve(req.result ? JSON.stringify(req.result) : null);
  #|   req.onerror = () => reject(req.error);
  #| })
