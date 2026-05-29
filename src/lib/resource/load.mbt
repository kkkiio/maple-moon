///|
/// Errors raised while loading raw resource files.
pub(all) suberror ResourceLoadError {
  /// The path is forbidden or is not a resolved asset path.
  InvalidPath(String)
  /// The resource file exists but its JSON payload cannot be parsed.
  InvalidJson(String)
} derive(Debug)



///|
/// Require an image by resolved asset path.
///
/// `path` must be a resolved asset path such as `assets/foo.png`.
/// Terminates if the path is invalid or the engine cannot load the image.
///
/// # Example
/// ```moonbit nocheck
/// let image = @resource.require_image("assets/UI/Basic.img/Cursor/cursor_animation.png")
/// ignore(image)
/// ```
pub fn require_image(path : String) -> @asset.ImageHandle {
  ensure_resolved_asset_io_path("image", path)
  @asset.load_image(path)
}

///|
/// Load an image by resolved asset path.
///
/// This is a compatibility alias of `require_image`; new code should use
/// `require_image` when a missing image is fatal.
///
/// # Example
/// ```moonbit nocheck
/// let image = @resource.load_image("assets/UI/Basic.img/Cursor/cursor_animation.png")
/// ignore(image)
/// ```
pub fn load_image(path : String) -> @asset.ImageHandle {
  require_image(path)
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
/// Fetch a JSON object from a path.
///
/// Returns `None` if the path is not found.
/// Panics if the JSON is invalid.
pub fn fetch_json(path : String) -> Json? {
  load_json(path) catch {
    err => abort("failed to fetch JSON resource: path=\{path}, error=\{err}")
  }
}

///|
/// Load a JSON object from a resolved asset path.
///
/// Returns `None` if the path is not found. Raises if the path is invalid or
/// the JSON payload is malformed.
///
/// # Example
/// ```moonbit nocheck
/// let json = @resource.load_json("assets/UI/Basic.img/Cursor/cursor_animation.json")
/// ignore(json)
/// ```
pub fn load_json(path : String) -> Json? raise {
  check_resolved_asset_io_path("JSON", path)
  guard @asset.read_bytes(path) is Some(bytes) else { return None }
  Some(
    @json.parse(@encoding/utf8.decode(bytes)) catch {
      err =>
        raise ResourceLoadError::InvalidJson(
          "invalid JSON resource: path=\{path}, error=\{err}",
        )
    },
  )
}

///|
/// Require a JSON object from a resolved asset path.
///
/// Terminates if the path is invalid, the file is missing, or the JSON payload
/// is malformed. Use this for predefined assets that must exist at runtime.
///
/// # Example
/// ```moonbit nocheck
/// let json = @resource.require_json("assets/UI/Basic.img/Cursor/cursor_animation.json")
/// ignore(json)
/// ```
pub fn require_json(path : String) -> Json {
  try load_json(path) catch {
    err =>
      abort(
        "failed to require JSON resource: path=\{path}, error=\{to_repr(err)}",
      )
  } noraise {
    value =>
      match value {
        Some(json) => json
        None => abort("required JSON resource not found: \{path}")
      }
  }
}

///|
/// Load a JSON file, then navigate to nested keys.
/// With empty keys, returns the full JSON tree.
///
/// # Panics
/// Panics if the file is not found, JSON is invalid, or a key is not found.
pub fn json_navigate(json_path : String, keys : Array[String]) -> Json {
  let root = require_json(json_path)
  keys.fold(init=root, fn(acc, key) {
    match acc {
      Object(obj) => match obj.get(key) {
        Some(v) => v
        None => abort("key not found: \{key} in \{json_path}")
      }
      _ => abort("expected JSON object at key \{key} in \{json_path}")
    }
  })
}

///|
fn ensure_resolved_asset_io_path(kind : String, path : String) -> Unit {
  check_resolved_asset_io_path(kind, path) catch {
    err => abort("\{to_repr(err)}")
  }
}

///|
fn check_resolved_asset_io_path(
  kind : String,
  path : String,
) -> Unit raise ResourceLoadError {
  if is_http_url(path) {
    raise ResourceLoadError::InvalidPath(
      "network \{kind} path is forbidden: \{path}",
    )
  }
  if has_leading_slash(path) {
    raise ResourceLoadError::InvalidPath(
      "resource \{kind} path must be relative, got: \{path}",
    )
  }
  guard is_resolved_asset_path(path.replace(old="\\", new="/")) else {
    raise ResourceLoadError::InvalidPath(
      "\{kind} path must be a resolved asset path: \{path}",
    )
  }
}


