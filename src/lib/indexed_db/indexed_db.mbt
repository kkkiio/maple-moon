///|
#external
type JSValue

///|
fn[X] JSValue::make(v : X) -> JSValue = "%identity"

///|
fn[X] JSValue::cast(self : JSValue) -> X = "%identity"

///|
extern "js" fn JSValue::is_null(self : JSValue) -> Bool = "(v) => v === null"

///|
extern "js" fn JSValue::is_undefined(self : JSValue) -> Bool = "(v) => v === undefined"

///|
/// Browser IndexedDB-backed implementation.
pub struct IndexedDB {
  db : JSValue
}

///|
/// Open an IndexedDB database and ensure all stores exist.
pub async fn open(
  name : String,
  version : Int,
  stores : Array[String],
) -> IndexedDB {
  let stores_value : JSValue = JSValue::make(stores)
  let db = indexed_db_open_promise(name, version, stores_value).wait()
  IndexedDB::{ db: JSValue::make(db) }
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
) -> @js_async.Promise[JSValue] {
  let json_str = data.stringify()
  save_json_promise(self.db, store, key, json_str)
}

///|
pub fn IndexedDB::load_json_promise(
  self : IndexedDB,
  store : String,
  key : String,
) -> @js_async.Promise[JSValue] {
  load_json_promise(self.db, store, key)
}

///|
pub async fn IndexedDB::load_json(
  self : IndexedDB,
  store : String,
  key : String,
) -> Json? {
  let val = load_json_promise(self.db, store, key).wait()
  if val.is_null() || val.is_undefined() {
    None
  } else {
    let json_str : String = val.cast()
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
  stores : JSValue,
) -> @js_async.Promise[JSValue] =
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
  db : JSValue,
  store : String,
  key : String,
  json_str : String,
) -> @js_async.Promise[JSValue] =
  #| (db, store, key, json_str) => new Promise((resolve, reject) => {
  #|   const tx = db.transaction(store, "readwrite");
  #|   const objStore = tx.objectStore(store);
  #|   const req = objStore.put(JSON.parse(json_str), key);
  #|   req.onsuccess = () => resolve(req.result);
  #|   req.onerror = () => reject(req.error);
  #| })

///|
extern "js" fn load_json_promise(
  db : JSValue,
  store : String,
  key : String,
) -> @js_async.Promise[JSValue] =
  #| (db, store, key) => new Promise((resolve, reject) => {
  #|   const tx = db.transaction(store, "readonly");
  #|   const objStore = tx.objectStore(store);
  #|   const req = objStore.get(key);
  #|   req.onsuccess = () => resolve(req.result ? JSON.stringify(req.result) : null);
  #|   req.onerror = () => reject(req.error);
  #| })
