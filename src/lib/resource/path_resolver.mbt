///|
fn is_http_url(path : String) -> Bool {
  path.has_prefix("http://") || path.has_prefix("https://")
}

///|
fn is_absolute_path(path : String) -> Bool {
  path.has_prefix("/")
}

///|
fn split_ref_path(path : String) -> Array[String] {
  path
  .split("/")
  .to_array()
  .map(fn(part) { part.to_string() })
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
fn normalize_absolute_resource_path(path : String) -> String {
  let normalized = path.replace(old="\\", new="/")
  let absolute = normalized.has_prefix("/")
  let parts = normalize_ref_path_parts(split_ref_path(normalized))
  let joined = join_path(parts)
  if absolute {
    if joined == "" {
      "/"
    } else {
      "/\{joined}"
    }
  } else if joined == "" {
    "/assets"
  } else if joined.has_prefix("assets/") || joined == "assets" {
    "/\{joined}"
  } else {
    "/assets/\{joined}"
  }
}

///|
fn base_file_dir(path : String) -> String {
  let normalized = normalize_absolute_resource_path(path)
  let parts = split_ref_path(normalized)
  if parts.length() <= 1 {
    return "/"
  }
  let dir_parts : Array[String] = []
  for i = 0; i + 1 < parts.length(); i = i + 1 {
    dir_parts.push(parts[i])
  }
  "/\{join_path(dir_parts)}"
}

///|
/// Resolve one resource reference against a declaration file path.
///
/// `base_path` must be the declaration file path (for example
/// `Mob/1210102.img/mx.json` or `/assets/Mob/1210102.img/mx.json`), not a
/// directory.
///
/// Rules:
/// - `http(s)` is forbidden.
/// - absolute `ref_path` (`/...`) is normalized and returned.
/// - relative `ref_path` is resolved against `base_path` directory.
/// - output is canonical absolute logical resource path (`/assets/...`).
pub fn resolve_ref(base_path : String, ref_path : String) -> String {
  if is_http_url(base_path) {
    abort("network base path is forbidden: \{base_path}")
  }
  if is_http_url(ref_path) {
    abort("network ref path is forbidden: \{ref_path}")
  }
  let normalized_ref = ref_path.replace(old="\\", new="/")
  if is_absolute_path(normalized_ref) {
    return normalize_absolute_resource_path(normalized_ref)
  }
  let base_dir = base_file_dir(base_path)
  normalize_absolute_resource_path(join_dir(base_dir, normalized_ref))
}

///|
/// Resolve one resource reference against a base directory path.
///
/// `base_dir` is treated as directory path (for example `/assets/Mob/1210102.img`
/// or `Mob/1210102.img`).
///
/// Rules:
/// - `http(s)` is forbidden.
/// - absolute `ref_path` (`/...`) is normalized and returned.
/// - relative `ref_path` is resolved against `base_dir`.
/// - output is canonical absolute logical resource path (`/assets/...`).
pub fn resolve_ref_from_dir(base_dir : String, ref_path : String) -> String {
  if is_http_url(base_dir) {
    abort("network base dir is forbidden: \{base_dir}")
  }
  if is_http_url(ref_path) {
    abort("network ref path is forbidden: \{ref_path}")
  }
  let normalized_ref = ref_path.replace(old="\\", new="/")
  if is_absolute_path(normalized_ref) {
    return normalize_absolute_resource_path(normalized_ref)
  }
  let normalized_base_dir = normalize_absolute_resource_path(base_dir)
  normalize_absolute_resource_path(
    join_dir(normalized_base_dir, normalized_ref),
  )
}

///|
let source_root_map : Map[String, String] = {
  // mapx keeps dedicated map root for tiled source-path semantics.
  "mapx": "/assets/map",
  "empty_mapx_loader": "/assets/map",

  // builtin runtime loaders
  "map_latest": "/assets",
  "map_world_map": "/assets",
  "background_set_loader": "/assets",
  "object_loader": "/assets",
  "tile": "/assets",
  "mob": "/assets/mob",
  "skill": "/assets/skill",
  "character": "/assets",
  "afterimage": "/assets",
  "body": "/assets",
  "effect": "/assets",
  "face": "/assets",
  "hair": "/assets",
  "item_special": "/assets",
  "item": "/assets",
  "ui_window_2": "/assets",
  "ui_window_4": "/assets",
  "ui_slice": "/assets",
  "npc": "/assets",
  "string": "/assets",
  "quest": "/assets",

  // app-specific loaders
  "starter_character_loader": "/assets",
  "starter_string_loader": "/assets",
  "empty_item_loader": "/assets",
  "Etc": "/assets",
  "map001": "/assets",
  "Login": "/assets",
}

///|
/// Resolve a logical resource path by `source` root mapping.
///
/// This API is shared by production and test environments. `source` must be a
/// business-domain source key (for example `mob`, `skill`, `item`).
pub fn resolve_resource_path(source : String, path : String) -> String {
  let base_dir = match source_root_map.get(source) {
    Some(root) => root
    None =>
      abort("path resolver source not registered: \{source}, path=\{path}")
  }
  resolve_ref_from_dir(base_dir, path)
}
