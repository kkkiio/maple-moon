///|
/// File-backed persistence for the native local server.
pub struct FileDB {
  root_path : String
}

///|
/// Create a file-backed database under `root_path`.
///
/// # Example
/// ```moonbit nocheck
/// let db = @file_db.FileDB(root_path=".local/maple-moon/local_server")
/// inspect(db.root_path_for_debug(), content=".local/maple-moon/local_server")
/// ```
pub fn FileDB::FileDB(
  root_path? : String = ".local/maple-moon/local_server",
) -> FileDB {
  { root_path, }
}

///|
/// Return the root directory used for persisted JSON files.
///
/// # Example
/// ```moonbit nocheck
/// let db = FileDB(root_path="save")
/// inspect(db.root_path_for_debug(), content="save")
/// ```
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
        @fs.IOError(message) =>
          if !@fs.path_exists(current) {
            abort("failed to create directory: \{current}, error=\{message}")
          }
      }
    }
  }
}

///|
pub impl @local_server.DB for FileDB with fn save_json(self, store, key, data) {
  let dir = self.store_dir(store)
  ensure_dir_recursive(dir)
  let path = self.data_file_path(store, key)
  @fs.write_string_to_file(path, data.stringify()) catch {
    @fs.IOError(message) =>
      abort("failed to write local server data: \{path}, error=\{message}")
  }
}

///|
pub impl @local_server.DB for FileDB with fn load_json(self, store, key) {
  let path = self.data_file_path(store, key)
  if !@fs.path_exists(path) {
    return None
  }
  let content = @fs.read_file_to_string(path) catch {
    @fs.IOError(message) =>
      abort("failed to read local server data: \{path}, error=\{message}")
  }
  Some(
    @json.parse(content) catch {
      _ => abort("failed to parse local server data: \{path}")
    },
  )
}
