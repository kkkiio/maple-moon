///|
fn is_http_url(path : String) -> Bool {
  path.has_prefix("http://") || path.has_prefix("https://")
}

///|
fn has_leading_slash(path : String) -> Bool {
  path.has_prefix("/")
}

///|
fn is_resolved_asset_path(path : String) -> Bool {
  path == "assets" || path.has_prefix("assets/")
}

///|
fn split_ref_path(path : String) -> Array[String] {
  path
  .split("/")
  .to_array()
  .map(fn(part) { part.to_owned() })
  .filter(fn(part) { part.length() > 0 })
}

///|
fn normalize_ref_path_parts(parts : Array[String]) -> Array[String] {
  let out : Array[String] = []
  for part in parts {
    if part == "." || part == "" {
      continue
    }
    if part == ".." {
      if !out.is_empty() {
        ignore(out.pop())
      }
      continue
    }
    out.push(part)
  }
  out
}

///|
fn guard_allowed_resource_path(kind : String, path : String) -> Unit {
  if is_http_url(path) {
    abort("network \{kind} path is forbidden: \{path}")
  }
  if has_leading_slash(path) {
    abort("resource \{kind} path must be relative, got: \{path}")
  }
}

///|
fn normalize_resolved_asset_path(path : String) -> String {
  guard_allowed_resource_path("asset", path)
  let normalized = path.replace(old="\\", new="/")
  let parts = normalize_ref_path_parts(split_ref_path(normalized))
  let joined = join_path(parts)
  if joined == "" {
    "assets"
  } else if is_resolved_asset_path(joined) {
    joined
  } else {
    "assets/\{joined}"
  }
}

///|
fn base_file_dir(path : String) -> String {
  let normalized = normalize_resolved_asset_path(path)
  let parts = split_ref_path(normalized)
  if parts.length() <= 1 {
    return "assets"
  }
  let dir_parts : Array[String] = []
  for i = 0; i + 1 < parts.length(); i = i + 1 {
    dir_parts.push(parts[i])
  }
  join_path(dir_parts)
}

///|
/// Resolve one resource reference against a declaration file path.
///
/// `base_path` must be the declaration file path (for example
/// `Mob/1210102.img/mx.json` or `assets/Mob/1210102.img/mx.json`), not a
/// directory.
///
/// Rules:
/// - `http(s)` is forbidden.
/// - leading-slash paths (`/...`) are forbidden.
/// - resolved asset paths (`assets/...`) are normalized and returned.
/// - relative `ref_path` is resolved against `base_path` directory.
/// - output is resolved asset path (`assets/...`).
pub fn resolve_ref(base_path : String, ref_path : String) -> String {
  guard_allowed_resource_path("base", base_path)
  guard_allowed_resource_path("ref", ref_path)
  let normalized_ref = ref_path.replace(old="\\", new="/")
  if is_resolved_asset_path(normalized_ref) {
    return normalize_resolved_asset_path(normalized_ref)
  }
  let base_dir = base_file_dir(base_path)
  normalize_resolved_asset_path(join_dir(base_dir, normalized_ref))
}

///|
/// Resolve one resource reference against a base directory path.
///
/// `base_dir` is treated as directory path (for example `assets/Mob/1210102.img`
/// or `Mob/1210102.img`).
///
/// Rules:
/// - `http(s)` is forbidden.
/// - leading-slash paths (`/...`) are forbidden.
/// - resolved asset paths (`assets/...`) are normalized and returned.
/// - relative `ref_path` is resolved against `base_dir`.
/// - output is resolved asset path (`assets/...`).
pub fn resolve_ref_from_dir(base_dir : String, ref_path : String) -> String {
  guard_allowed_resource_path("base dir", base_dir)
  guard_allowed_resource_path("ref", ref_path)
  let normalized_ref = ref_path.replace(old="\\", new="/")
  if is_resolved_asset_path(normalized_ref) {
    return normalize_resolved_asset_path(normalized_ref)
  }
  let normalized_base_dir = normalize_resolved_asset_path(base_dir)
  normalize_resolved_asset_path(join_dir(normalized_base_dir, normalized_ref))
}

///|
let source_root_map : Map[String, String] = {
  "mapx": "assets/map",
  "map_latest": "assets",
  "map_world_map": "assets/Map/WorldMap",
  "background_set_loader": "assets/Map/back",
  "object_loader": "assets/Map/obj",
  "tile": "assets/Map/tile",
  "mob": "assets/mob",
  "skill": "assets/Skill",
  "character": "assets/Character",
  "afterimage": "assets/Character/Afterimage",
  "body": "assets/Character/Body",
  "effect": "assets/Effect",
  "face": "assets/Character/Face",
  "hair": "assets/Character/Hair",
  "item_special": "assets/Item/Special",
  "item": "assets/Item",
  "ui_window_2": "assets/UI/UIWindow2.img",
  "ui_window_4": "assets/UI/UIWindow4.img",
  "ui_slice": "assets",
  "npc": "assets",
  "string": "assets/String",
  "quest": "assets/Quest",
  "Etc": "assets/Etc",
  "map001": "assets/map001",
  "Login": "assets/UI",
}

///|
let json_file_segment_count_map : Map[String, Int] = {
  "item": 2,
  "character": 2,
  "effect": 2,
}

///|
fn source_root(source : String, path : String) -> String {
  match source_root_map.get(source) {
    Some(root) => root
    None =>
      abort("path resolver source not registered: \{source}, path=\{path}")
  }
}

///|
fn json_file_segment_count(source : String) -> Int {
  json_file_segment_count_map.get(source).unwrap_or(1)
}

///|
fn has_json_file_suffix(path : String) -> Bool {
  path.has_suffix(".json") || path.has_suffix(".tmj") || path.has_suffix(".tsj")
}

///|
fn push_json_suffix(path : String) -> String {
  if has_json_file_suffix(path) {
    path
  } else {
    path + ".json"
  }
}

///|
fn strip_prefix_parts(
  parts : Array[String],
  prefix : Array[String],
) -> Array[String]? {
  if parts.length() < prefix.length() {
    return None
  }
  for i = 0; i < prefix.length(); i = i + 1 {
    if parts[i] != prefix[i] {
      return None
    }
  }
  let rest : Array[String] = []
  for i = prefix.length(); i < parts.length(); i = i + 1 {
    rest.push(parts[i])
  }
  Some(rest)
}

///|
fn join_absolute_parts(parts : Array[String]) -> String {
  let joined = join_path(parts)
  if joined == "" {
    "assets"
  } else {
    joined
  }
}

///|
/// Resolve a logical resource path by `source` root mapping.
///
/// This API is shared by production and test environments. `source` must be a
/// business-domain source key (for example `mob`, `skill`, `item`).
pub fn resolve_resource_path(source : String, path : String) -> String {
  guard_allowed_resource_path("resource", path)
  if is_resolved_asset_path(path.replace(old="\\", new="/")) {
    return normalize_resolved_asset_path(path)
  }
  let base_dir = source_root(source, path)
  resolve_ref_from_dir(base_dir, path)
}

///|
/// Resolve a JSON-backed resource path to its JSON file path and node path.
///
/// This function only resolves paths. It does not fetch files or parse JSON.
/// The returned file path is a resolved asset path, and the node path contains
/// keys to look up inside that JSON file.
///
/// # Example
/// ```moonbit nocheck
/// inspect(
///   resolve_json_resource_path("item", "Consume/0206.img/02060000").0,
///   content="assets/Item/Consume/0206.img.json",
/// )
/// inspect(
///   resolve_json_resource_path("item", "Consume/0206.img/02060000").1,
///   content="[\"02060000\"]",
/// )
/// ```
pub fn resolve_json_resource_path(
  source : String,
  path : String,
) -> (String, Array[String]) {
  let resolved = resolve_resource_path(source, path)
  let root = normalize_resolved_asset_path(source_root(source, path))
  let resolved_parts = split_ref_path(resolved)
  let root_parts = split_ref_path(root)
  let relative_parts = match strip_prefix_parts(resolved_parts, root_parts) {
    Some(parts) => parts
    None =>
      abort(
        "resolved resource path is outside source root: source=\{source}, path=\{path}, resolved=\{resolved}",
      )
  }
  guard !relative_parts.is_empty() else {
    abort("empty JSON resource path: source=\{source}, path=\{path}")
  }
  if has_json_file_suffix(resolved) {
    return (resolved, [])
  }
  let file_segment_count = json_file_segment_count(source)
  let file_segment_count = if relative_parts.length() < file_segment_count {
    relative_parts.length()
  } else {
    file_segment_count
  }
  let file_parts = root_parts.copy()
  for i = 0; i < file_segment_count; i = i + 1 {
    file_parts.push(relative_parts[i])
  }
  let node_path : Array[String] = []
  for i = file_segment_count; i < relative_parts.length(); i = i + 1 {
    node_path.push(relative_parts[i])
  }
  (push_json_suffix(join_absolute_parts(file_parts)), node_path)
}
