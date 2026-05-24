///|
pub(open) trait AsyncResourceLoader {
  fn load_data(self : Self, path : StringView) -> Json?
}

///|
struct AsyncLoader {
  source : String
  loader : &AsyncResourceLoader
}

///|
pub fn AsyncLoader::new(
  name : String,
  loader~ : &AsyncResourceLoader,
) -> AsyncLoader {
  { source: name, loader }
}

///|
pub fn AsyncLoader::require_resource(
  self : AsyncLoader,
  path : ArrayView[String],
) -> Json {
  self.require_data(join_path(path))
}

///|
/// Load a JSON object by resource path segments.
///
/// This is an alias of `require_resource`.
///
/// # Example
/// ```moonbit nocheck
/// let json = loader.load_resource(["Item", "Consume"])
/// ignore(json)
/// ```
pub fn AsyncLoader::load_resource(
  self : AsyncLoader,
  path : ArrayView[String],
) -> Json {
  self.require_resource(path)
}

///|
/// Load a JSON object by source-relative or resolved asset path.
pub fn AsyncLoader::require_data(self : AsyncLoader, path : String) -> Json {
  let loader_path = self.loader_data_path(path)
  match self.loader.load_data(loader_path) {
    Some(json) => json
    None => abort("resource not found: \{path}")
  }
}

///|
/// Load a JSON object by source-relative or resolved asset path.
///
/// This is an alias of `require_data`.
///
/// # Example
/// ```moonbit nocheck
/// let json = loader.load_data("Consume/0200.img")
/// ignore(json)
/// ```
pub fn AsyncLoader::load_data(self : AsyncLoader, path : String) -> Json {
  self.require_data(path)
}

///|
/// Resolve a JSON resource path to a fetchable URL/path.
///
/// Rules:
/// - Resolved asset paths(`assets/...`) are passed through.
/// - Relative paths are resolved by internal source rules.
/// - Leading-slash paths(`/...`) are forbidden.
/// - `http(s)` is forbidden and will fail.
pub fn AsyncLoader::resolve_json_path(
  self : AsyncLoader,
  path : String,
) -> String {
  resolve_resource_path(self.source, path)
}

///|
/// Load an image by resolved asset path.
///
/// `path` must be a resolved asset path such as `assets/foo.png`.
///
/// # Example
/// ```moonbit nocheck
/// let image = @resource.load_image("assets/ui/cursor/cursor_idle.png")
/// ignore(image)
/// ```
pub fn load_image(path : String) -> @asset.ImageHandle {
  ensure_resolved_asset_io_path("image", path)
  @asset.load_image(path)
}

///|
/// Load an image by source-relative or resolved asset path.
///
/// Rules:
/// - Resolved asset paths(`assets/...`) are passed through.
/// - Relative paths are resolved by internal source rules.
/// - Leading-slash paths(`/...`) are forbidden.
/// - `http(s)` is forbidden and will fail.
pub fn AsyncLoader::load_image(
  self : AsyncLoader,
  path : String,
) -> @asset.ImageHandle {
  let resolved = resolve_resource_path(self.source, path)
  load_image(resolved)
}

///|
fn AsyncLoader::loader_data_path(self : AsyncLoader, path : String) -> String {
  guard_allowed_resource_path("loader data", path)
  let normalized = path.replace(old="\\", new="/")
  guard is_resolved_asset_path(normalized) else { return path }
  let resolved = normalize_resolved_asset_path(normalized)
  let root = normalize_resolved_asset_path(source_root(self.source, path))
  let resolved_parts = split_ref_path(resolved)
  let root_parts = split_ref_path(root)
  let relative_parts = match strip_prefix_parts(resolved_parts, root_parts) {
    Some(parts) => parts
    None =>
      abort(
        "resolved resource path is outside source root: source=\{self.source}, path=\{path}, root=\{root}",
      )
  }
  join_path(relative_parts)
}

///|
struct CompositeAsyncResourceLoader {
  prefixLoaderMap : Map[String, &AsyncResourceLoader]
}

///|
pub fn CompositeAsyncResourceLoader::new(
  prefixLoaderMap : Map[String, &AsyncResourceLoader],
) -> CompositeAsyncResourceLoader {
  { prefixLoaderMap, }
}

///|
pub impl AsyncResourceLoader for CompositeAsyncResourceLoader with fn load_data(
  self,
  path,
) -> Json? {
  let (path, loader) = for prefix, loader in self.prefixLoaderMap {
    if path.strip_prefix(prefix) is Some(path) {
      break (path, loader)
    }
  } nobreak {
    return None
  }
  loader.load_data(path)
}

///|
/// A resource loader that loads resources from a directory.
/// The directory splits resources by first level of the path and stores them in json files.
/// For example, if we want to load grassySoil/ani/0, it will load $rootPath/grassySoil.img.json and then get the value of "ani/0".
struct DirResourceLoader {
  rootPath : String
}

///|
pub fn DirResourceLoader::new(rootPath : String) -> DirResourceLoader {
  { rootPath, }
}

///|
pub impl AsyncResourceLoader for DirResourceLoader with fn load_data(self, path) -> Json? {
  let (child, rest) = if path.find("/") is Some(i) {
    (path.view(start_offset=0, end_offset=i), path.view(start_offset=i + 1))
  } else {
    (path, "")
  }
  let path = join_dir(self.rootPath, child.to_owned() + ".json")
  guard fetch_json(path) is Some(root_value) else { return None }
  Some(get_by_path(root_value, rest.to_owned()))
}

///|
/// Fetch a JSON object from a path.
///
/// Returns `None` if the path is not found.
/// Panics if the JSON is invalid.
pub fn fetch_json(path : String) -> Json? {
  ensure_resolved_asset_io_path("JSON", path)
  guard @asset.read_bytes(path) is Some(bytes) else { return None }
  Some(try! @json.parse(@encoding/utf8.decode(bytes)))
}

///|
fn ensure_resolved_asset_io_path(kind : String, path : String) -> Unit {
  guard_allowed_resource_path(kind, path)
  guard is_resolved_asset_path(path.replace(old="\\", new="/")) else {
    abort("\{kind} path must be a resolved asset path: \{path}")
  }
}

///|
fn join_dir(root : String, path : String) -> String {
  if path.has_prefix("/") {
    abort("path must be relative when joining resource path: \{path}")
  }
  let root = root.strip_suffix("/").unwrap_or(root)
  return "\{root}/\{path}"
}

///|
fn get_by_path(obj : Json, path : String) -> Json {
  if path.is_empty() {
    return obj
  }
  let parts = path.split("/")
  parts.fold(init=obj, fn(acc, part) {
    guard acc is Object(obj) else {
      null // TODO: throw error
    }
    guard obj.get(part.to_owned()) is Some(value) else {
      null // TODO: throw error
    }
    value
  })
}
