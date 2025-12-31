///|
struct IndexedDB {
  db : @js.Value
}

///|
pub async fn init_db() -> IndexedDB {
  let db = indexed_db_open_promise("MapleMoonDB", 1).wait()
  IndexedDB::{ db: @js.Value::cast_from(db) }
}

///|
pub fn IndexedDB::save_character_data(self : IndexedDB, data : Json) -> Unit {
  let json_str = data.stringify()
  let _ = save_character_data_promise(self.db, json_str)

}

///|
pub async fn IndexedDB::load_character_data(
  self : IndexedDB,
  character_id : Int,
) -> Json? {
  let val = load_character_data_promise(self.db, character_id).wait()
  if @js.Value::is_null(val) || @js.Value::is_undefined(val) {
    None
  } else {
    let json_str : String = @js.Value::cast(val)
    Some(@json.parse(json_str))
  }
}

// FFI

///|
extern "js" fn indexed_db_open_promise(
  name : String,
  version : Int,
) -> @js.Promise =
  #| (name, version) => new Promise((resolve, reject) => {
  #|   const req = indexedDB.open(name, version);
  #|   req.onsuccess = () => resolve(req.result);
  #|   req.onerror = () => reject(req.error);
  #|   req.onupgradeneeded = (e) => {
  #|     const db = e.target.result;
  #|     if (!db.objectStoreNames.contains("characters")) {
  #|       db.createObjectStore("characters", { keyPath: "character_id" });
  #|     }
  #|   }
  #| })

///|
extern "js" fn save_character_data_promise(
  db : @js.Value,
  json_str : String,
) -> @js.Promise =
  #| (db, json_str) => new Promise((resolve, reject) => {
  #|   const tx = db.transaction("characters", "readwrite");
  #|   const store = tx.objectStore("characters");
  #|   const req = store.put(JSON.parse(json_str));
  #|   req.onsuccess = () => resolve(req.result);
  #|   req.onerror = () => reject(req.error);
  #| })

///|
extern "js" fn load_character_data_promise(
  db : @js.Value,
  key : Int,
) -> @js.Promise =
  #| (db, key) => new Promise((resolve, reject) => {
  #|   const tx = db.transaction("characters", "readonly");
  #|   const store = tx.objectStore("characters");
  #|   const req = store.get(key);
  #|   req.onsuccess = () => resolve(req.result ? JSON.stringify(req.result) : null);
  #|   req.onerror = () => reject(req.error);
  #| })
