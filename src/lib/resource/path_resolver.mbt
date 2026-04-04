///|
fn is_http_url(path : String) -> Bool {
  path.has_prefix("http://") || path.has_prefix("https://")
}

///|
fn is_absolute_path(path : String) -> Bool {
  path.has_prefix("/")
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
  if is_http_url(path) {
    abort("network path is forbidden: \{path}")
  }
  if is_absolute_path(path) {
    return path
  }
  let root = match source_root_map.get(source) {
    Some(root) => root
    None =>
      abort("path resolver source not registered: \{source}, path=\{path}")
  }
  join_dir(root, path)
}
