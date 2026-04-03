///|
/// A resource loader that reads JSON by file path under `root_path`.
struct FileJsonResourceLoader {
  root_path : String
}

///|
/// Create a file-path-based JSON loader rooted at `root_path`.
pub fn FileJsonResourceLoader::new(
  root_path : String,
) -> FileJsonResourceLoader {
  { root_path, }
}

///|
pub impl AsyncResourceLoader for FileJsonResourceLoader with load_data(
  self,
  path,
) -> Json {
  let full_path = join_dir(self.root_path, path.to_string())
  fetch_json(full_path)
}
