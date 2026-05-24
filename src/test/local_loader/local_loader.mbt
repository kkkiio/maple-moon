///|
/// Local JSON loader that delegates resource path semantics to `resource`.
priv struct LocalJsonResourceLoader {
  source : String
}

///|
priv struct LocalCsvTextLoader {}

///|
fn LocalJsonResourceLoader::new(source : String) -> LocalJsonResourceLoader {
  { source, }
}

///|
fn LocalCsvTextLoader::new() -> LocalCsvTextLoader {
  LocalCsvTextLoader::{  }
}

///|
impl @resource.AsyncResourceLoader for LocalJsonResourceLoader with fn load_data(
  self,
  path,
) -> Json? {
  let (file_path, node_path) = @resource.resolve_json_resource_path(
    self.source,
    path.to_owned(),
  )
  let root_value = load_json_from_local_path(file_path) catch {
    _ => abort("failed to load local json resource: \{file_path}")
  }
  get_by_path(root_value, node_path) |> Some
}

///|
impl @resource.CsvTextLoader for LocalCsvTextLoader with fn load_text(
  self,
  path,
) -> String {
  ignore(self)
  @fs.read_file_to_string(path) catch {
    _ => abort("failed to load local text resource: \{path}")
  }
}

///|
fn make_local_loader(source : String) -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    source,
    loader=LocalJsonResourceLoader::new(source),
  )
}

///|
/// Creates a string loader that reads String resources from the local assets.
pub fn make_local_string_loader() -> @resource.AsyncLoader {
  make_local_loader("string")
}

///|
fn make_local_csv_loader() -> @resource.CsvLoader {
  @resource.CsvLoader::new(loader=LocalCsvTextLoader::new())
}

///|
fn install_local_csv_loader() -> Unit {
  @resource.set_csv_loader(make_local_csv_loader())
}

///|
/// Installs a default local-fs-backed resource environment for tests.
///
/// Path resolution stays in `resource`; this package only reads the resolved
/// JSON or CSV files from the local filesystem.
pub fn install_resource_env_for_test() -> Unit {
  @resource.register_async_loader("item", make_local_loader("item"))
  @resource.register_async_loader(
    "item_special",
    make_local_loader("item_special"),
  )
  @resource.register_async_loader("character", make_local_loader("character"))
  @resource.register_async_loader("mob", make_local_loader("mob"))
  @resource.register_async_loader("skill", make_local_loader("skill"))
  @resource.register_async_loader("body", make_local_loader("body"))
  @resource.register_async_loader("face", make_local_loader("face"))
  @resource.register_async_loader("hair", make_local_loader("hair"))
  @resource.register_async_loader("string", make_local_string_loader())
  @resource.register_async_loader("quest", make_local_loader("quest"))
  @resource.register_async_loader("npc", make_local_loader("npc"))
  @resource.register_async_loader("mapx", make_local_loader("mapx"))
  @resource.register_async_loader(
    "ui_window_2",
    make_local_loader("ui_window_2"),
  )
  @resource.register_async_loader("ui_slice", make_local_loader("ui_slice"))
  @resource.register_async_loader("effect", make_local_loader("effect"))
  install_local_csv_loader()
}

///|
fn load_json_from_local_path(path : String) -> Json raise {
  let text = @fs.read_file_to_string(path)
  @json.parse(text)
}

///|
fn get_by_path(obj : Json, path : Array[String]) -> Json {
  path.fold(init=obj, fn(acc, part) {
    match acc {
      Object(map) => map.get(part).unwrap_or(null)
      _ => null
    }
  })
}
