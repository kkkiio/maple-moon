///|
/// Async resource loader that reads test JSON resources from local filesystem.
pub struct LocalDirResourceLoader {
  root_path : String
}

///|
/// Creates a local directory loader rooted at `root_path`.
pub fn LocalDirResourceLoader::new(
  root_path : String,
) -> LocalDirResourceLoader {
  { root_path, }
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
/// Creates an item loader that always reads from local `assets/Item`.
pub fn make_local_item_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "test_local_item",
    base_url="/assets",
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
    base_url="/assets",
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
