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
let source_root_map : Map[String, String] = {
  // mapx keeps dedicated map root for tiled source-path semantics.
  "mapx": "/assets/map",
  "empty_mapx_loader": "/assets/map",
  "test_mapx": "/assets/map",

  // builtin runtime loaders
  "map_latest": "/assets",
  "map_world_map": "/assets",
  "background_set_loader": "/assets",
  "object_loader": "/assets",
  "tile": "/assets",
  "mob": "/assets",
  "skill": "/assets",
  "character": "/assets",
  "afterimage": "/assets",
  "body": "/assets",
  "effect": "/assets",
  "face": "/assets",
  "hair": "/assets",
  "item_special": "/assets",
  "item": "/assets",
  "UI/UIWindow2.img": "/assets",
  "UI/UIWindow4.img": "/assets",
  "ui_slice": "/assets",
  "npc": "/assets",
  "string": "/assets",
  "quest": "/assets",

  // tests / fixtures / local loaders
  "starter_character_loader": "/assets",
  "starter_string_loader": "/assets",
  "empty_item_loader": "/assets",
  "dummy": "/assets",
  "test_local_skill": "/assets",
  "test_local_string": "/assets",
  "Etc": "/assets",
  "map001": "/assets",
  "Login": "/assets",
  "counting_item_loader": "/assets",
  "mock_string_loader": "/assets",
  "mock_basic_item_loader": "/assets",
  "mock_basic_string_loader": "/assets",
  "test_local_body": "/assets",
  "test_local_face": "/assets",
  "test_local_hair": "/assets",
  "test_npc": "/assets",
  "test_string": "/assets",
  "test_local_effect": "/assets",
  "test_local_item": "/assets",
  "test_local_character": "/assets",
  "test_local_quest": "/assets",
  "test_null_string": "/assets",
  "test_local_ui_window_2": "/assets",
  "test_local_ui_slice": "/assets",
}

///|
fn resolve_resource_path(source : String, path : String) -> String {
  let base_path = match source_root_map.get(source) {
    Some(root) => join_dir(root, "__source__.json")
    None =>
      abort("path resolver source not registered: \{source}, path=\{path}")
  }
  resolve_ref(base_path, path)
}
