///|
/// Async resource loader that reads test JSON resources from local filesystem.
pub struct LocalDirResourceLoader {
  root_path : String
}

///|
/// Async resource loader that reads a JSON file by full relative path.
pub struct LocalFileJsonResourceLoader {
  root_path : String
}

///|
/// Async resource loader that always returns `null`.
pub struct NullResourceLoader {
  dummy : Unit
}

///|
/// CSV text loader that reads test CSV files from local filesystem.
pub struct LocalCsvTextLoader {
  dummy : Unit
}

///|
/// Creates a local directory loader rooted at `root_path`.
pub fn LocalDirResourceLoader::new(
  root_path : String,
) -> LocalDirResourceLoader {
  { root_path, }
}

///|
/// Creates a local file-json loader rooted at `root_path`.
pub fn LocalFileJsonResourceLoader::new(
  root_path : String,
) -> LocalFileJsonResourceLoader {
  { root_path, }
}

///|
/// Creates a null resource loader.
pub fn NullResourceLoader::new() -> NullResourceLoader {
  { dummy: () }
}

///|
/// Creates a local CSV text loader.
pub fn LocalCsvTextLoader::new() -> LocalCsvTextLoader {
  { dummy: () }
}

///|
pub impl @resource.AsyncResourceLoader for LocalDirResourceLoader with load_data(
  self,
  path,
) -> Json {
  let (child, rest) = if path.find("/") is Some(i) {
    (path.view(start_offset=0, end_offset=i), path.view(start_offset=i + 1))
  } else {
    (path, "")
  }
  let file_path = join_dir(self.root_path, child.to_string() + ".json")
  let text = @fs.read_file_to_string(file_path)
  let root_value : Json = @json.parse(text) catch {
    _ => abort("invalid json in local loader: \{file_path}")
  }
  get_by_path(root_value, rest.to_string())
}

///|
pub impl @resource.AsyncResourceLoader for NullResourceLoader with load_data(
  self,
  path,
) -> Json {
  ignore(self.dummy)
  ignore(path)
  Json::null()
}

///|
pub impl @resource.AsyncResourceLoader for LocalFileJsonResourceLoader with load_data(
  self,
  path,
) -> Json {
  let normalized = path.strip_prefix("/").unwrap_or(path)
  let file_path = join_dir(self.root_path, normalized.to_string())
  let text = @fs.read_file_to_string(file_path)
  @json.parse(text) catch {
    _ => abort("invalid json in local file loader: \{file_path}")
  }
}

///|
pub impl @resource.CsvTextLoader for LocalCsvTextLoader with load_text(
  self,
  path,
) -> String {
  ignore(self.dummy)
  let fs_path = path.strip_prefix("/").unwrap_or(path)
  @fs.read_file_to_string(fs_path.to_string())
}

///|
/// Creates an item loader that always reads from local `assets/Item`.
pub fn make_local_item_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "test_local_item",
    loader=@resource.CompositeAsyncResourceLoader::new({
      "Consume/": LocalDirResourceLoader::new("assets/Item/Consume"),
      "Cash/": LocalDirResourceLoader::new("assets/Item/Cash"),
      "Etc/": LocalDirResourceLoader::new("assets/Item/Etc"),
      "Install/": LocalDirResourceLoader::new("assets/Item/Install"),
      "Pet/": LocalDirResourceLoader::new("assets/Item/Pet"),
    }),
  )
}

///|
/// Creates an item-data system wired to the local test item loader.
pub fn make_local_item_data_system() -> @item.ItemDataSystem {
  @item.ItemDataSystem::new(make_local_item_loader())
}

///|
/// Installs the local-loader-backed item-data system for tests.
pub fn use_local_item_data_system() -> Unit {
  @item.set_item_data_system(make_local_item_data_system())
}

///|
/// Creates a character loader that always reads from local `assets/Character`.
pub fn make_local_character_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "test_local_character",
    loader=@resource.CompositeAsyncResourceLoader::new({
      "Pants/": LocalDirResourceLoader::new("assets/Character/Pants"),
      "Weapon/": LocalDirResourceLoader::new("assets/Character/Weapon"),
      "Coat/": LocalDirResourceLoader::new("assets/Character/Coat"),
      "Cap/": LocalDirResourceLoader::new("assets/Character/Cap"),
      "Longcoat/": LocalDirResourceLoader::new("assets/Character/Longcoat"),
      "Shield/": LocalDirResourceLoader::new("assets/Character/Shield"),
      "Shoes/": LocalDirResourceLoader::new("assets/Character/Shoes"),
      "Glove/": LocalDirResourceLoader::new("assets/Character/Glove"),
      "Accessory/": LocalDirResourceLoader::new("assets/Character/Accessory"),
    }),
  )
}

///|
/// Creates a string loader that reads from local `assets/String`.
pub fn make_local_string_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "test_local_string",
    loader=LocalDirResourceLoader::new("assets/String"),
  )
}

///|
/// Creates a quest loader that reads from local `assets/Quest`.
pub fn make_local_quest_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "test_local_quest",
    loader=LocalDirResourceLoader::new("assets/Quest"),
  )
}

///|
/// Creates a string loader that always returns empty JSON.
///
/// This is useful for snapshot tests that intentionally assert UI layout without
/// localized item-name text.
pub fn make_null_string_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "test_null_string",
    loader=NullResourceLoader::new(),
  )
}

///|
/// Creates a CSV loader that reads local files.
pub fn make_local_csv_loader() -> @resource.CsvLoader {
  @resource.CsvLoader::new(loader=LocalCsvTextLoader::new())
}

///|
/// Installs local CSV loader into resource registry.
pub fn install_local_csv_loader() -> Unit {
  @resource.set_csv_loader(make_local_csv_loader())
}

///|
/// Installs a default local-fs-backed resource environment for tests.
///
/// This keeps test path-resolution rules aligned with runtime rules while
/// swapping the underlying JSON/CSV I/O backend to local filesystem.
pub fn install_resource_env_for_test() -> Unit {
  @resource.register_async_loader("item", make_local_item_loader())
  @resource.register_async_loader("character", make_local_character_loader())
  @resource.register_async_loader("string", make_local_string_loader())
  @resource.register_async_loader("quest", make_local_quest_loader())
  @resource.register_async_loader(
    "npc",
    @resource.AsyncLoader::new(
      "test_npc",
      loader=LocalFileJsonResourceLoader::new("assets"),
    ),
  )
  @resource.register_async_loader(
    "mapx",
    @resource.AsyncLoader::new(
      "test_mapx",
      loader=LocalFileJsonResourceLoader::new("assets/map"),
    ),
  )
  @resource.register_async_loader(
    "ui_window_2",
    @resource.AsyncLoader::new(
      "test_local_ui_window_2",
      loader=LocalDirResourceLoader::new("assets/ui/UIWindow2.img"),
    ),
  )
  @resource.register_async_loader(
    "ui_slice",
    @resource.AsyncLoader::new(
      "test_local_ui_slice",
      loader=LocalFileJsonResourceLoader::new("assets"),
    ),
  )
  install_local_csv_loader()
}

///|
fn join_dir(root : String, path : String) -> String {
  let normalized_root = root.strip_suffix("/").unwrap_or(root)
  let normalized_path = path.strip_prefix("/").unwrap_or(path)
  "\{normalized_root}/\{normalized_path}"
}

///|
fn get_by_path(obj : Json, path : String) -> Json {
  if path.is_empty() {
    return obj
  }
  let parts = path.split("/")
  parts.fold(init=obj, fn(acc, part) {
    match acc {
      Object(map) => map.get(part.to_string()).unwrap_or(null)
      _ => null
    }
  })
}
