///|
fn read_resolved_bytes(
  physical_path : String,
  diagnostic_path : String,
) -> Bytes raise ResourceLoadError {
  let physical : @posix.Path = physical_path.replace(old="\\", new="/")
  let normalized = physical.normalize().to_string()
  let mut is_mounted = false
  for mounted in resource_mounts {
    if normalized.has_prefix(mounted.root + "/") {
      is_mounted = true
      break
    }
  }
  guard is_mounted else {
    raise ResourceLoadError::InvalidAddress(
      "resolved resource path is outside mounted packs: \{physical_path}",
    )
  }
  guard @platform_asset_io.read_bytes(normalized) is Some(bytes) else {
    raise ResourceLoadError::NotFound(
      "resource disappeared after resolution: address=\{diagnostic_path}, physical=\{normalized}",
    )
  }
  bytes
}

///|
fn decode_text_bytes(
  bytes : Bytes,
  diagnostic_path : String,
) -> String raise ResourceLoadError {
  @encoding/utf8.decode(bytes) catch {
    error =>
      raise ResourceLoadError::DecodeFailed(
        diagnostic_path,
        "invalid UTF-8: \{to_repr(error)}",
      )
  }
}

///|
fn load_json_from_resolved_path(
  physical_path : String,
) -> Json raise ResourceLoadError {
  let bytes = read_resolved_bytes(physical_path, physical_path)
  let source = decode_text_bytes(bytes, physical_path)
  @json.parse(source) catch {
    error =>
      raise ResourceLoadError::DecodeFailed(
        physical_path,
        "invalid JSON: \{to_repr(error)}",
      )
  }
}

///|
fn resolve_nx_image_refs(
  value : Json,
  physical_json_path : String,
) -> Json raise ResourceLoadError {
  match value {
    Object(fields) => {
      let resolved : Map[String, Json] = Map([])
      for key, child in fields {
        if key == "__i" && child is String(reference) {
          resolved[key] = if reference.has_prefix("res://") {
            child
          } else {
            Json::string(resolve_ref(physical_json_path, reference))
          }
        } else {
          resolved[key] = resolve_nx_image_refs(child, physical_json_path)
        }
      }
      Json::object(resolved)
    }
    Array(items) => {
      let resolved : Array[Json] = []
      for item in items {
        resolved.push(resolve_nx_image_refs(item, physical_json_path))
      }
      Json::array(resolved)
    }
    _ => value
  }
}

///|
/// Load a UTF-8 text resource from a public `res://` address.
///
/// Address validation, pack lookup, missing files, and UTF-8 decoding errors are
/// propagated to the caller.
///
/// # Example
/// ```moonbit nocheck
/// try! configure_packs([("base", "assets/base")])
/// let source = try! load_text("res://Data/shops.tsv")
/// ignore(source)
/// ```
pub fn load_text(address : String) -> String raise ResourceLoadError {
  let physical_path = resolve(address)
  let bytes = read_resolved_bytes(physical_path, address)
  decode_text_bytes(bytes, address)
}

///|
/// Load and parse a JSON resource from a public `res://` address.
///
/// This fallible API preserves invalid-address, missing-resource, UTF-8, and JSON
/// errors for a system or explicit require boundary to handle.
///
/// # Example
/// ```moonbit nocheck
/// try! configure_packs([("base", "assets/base")])
/// let json = try! load_json("res://Quest/nx.json")
/// ignore(json)
/// ```
pub fn load_json(address : String) -> Json raise ResourceLoadError {
  let physical_path = resolve(address)
  let bytes = read_resolved_bytes(physical_path, address)
  let source = decode_text_bytes(bytes, address)
  let parsed = @json.parse(source) catch {
    error =>
      raise ResourceLoadError::DecodeFailed(
        address,
        "invalid JSON: \{to_repr(error)}",
      )
  }
  resolve_nx_image_refs(parsed, physical_path)
}

///|
/// Require and parse a predefined JSON resource.
///
/// This is the explicit termination boundary for JSON resources that must be
/// present and valid in every supported installation.
///
/// # Example
/// ```moonbit nocheck
/// try! configure_packs([("base", "assets/base")])
/// let json = require_json("res://Quest/nx.json")
/// ignore(json)
/// ```
pub fn require_json(address : String) -> Json {
  load_json(address) catch {
    error =>
      abort(
        "failed to require JSON resource: address=\{address}, error=\{to_repr(error)}",
      )
  }
}

///|
/// Require an image from a public `res://` address or a resolved pack path.
///
/// The address is resolved before Selene receives the winning pack's physical
/// path, so renderer caches and file-relative references remain pack-local.
///
/// # Example
/// ```moonbit nocheck
/// try! configure_packs([("base", "assets/base")])
/// let image = require_image("res://UI/Basic.img/Cursor/cursor.png")
/// ignore(image)
/// ```
pub fn require_image(address : String) -> @asset.ImageHandle {
  let physical_path = if address.has_prefix("res://") {
    require_path(address)
  } else {
    ignore(read_resolved_bytes(address, address)) catch {
      error =>
        abort(
          "failed to require resolved image: path=\{address}, error=\{to_repr(error)}",
        )
    }
    let physical : @posix.Path = address.replace(old="\\", new="/")
    physical.normalize().to_string()
  }
  @asset.load_image(physical_path)
}

///|
/// Require a JSON file and navigate through object keys.
///
/// Empty `keys` returns the complete document. Missing keys and non-object
/// intermediate values terminate at this explicit required-resource boundary.
///
/// # Example
/// ```moonbit nocheck
/// try! configure_packs([("base", "assets/base")])
/// let node = require_json_node("res://String/Skill.img.json", ["1000"])
/// ignore(node)
/// ```
///
/// # Panics
/// Panics when the required JSON is missing or invalid, a key is absent, or an
/// intermediate node is not an object.
pub fn require_json_node(address : String, keys : Array[String]) -> Json {
  let root = require_json(address)
  keys.fold(init=root, fn(current, key) {
    match current {
      Object(fields) =>
        match fields.get(key) {
          Some(value) => value
          None =>
            abort("JSON resource key not found: address=\{address}, key=\{key}")
        }
      _ =>
        abort(
          "expected JSON object while navigating resource: address=\{address}, key=\{key}",
        )
    }
  })
}
