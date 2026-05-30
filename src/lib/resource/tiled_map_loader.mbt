///|
fn split_resource_path(path : String) -> Array[String] {
  path
  .split("/")
  .to_array()
  .map(fn(part) { part.to_owned() })
  .filter(fn(part) { part.length() > 0 })
}

///|
fn normalize_resource_path_parts(parts : Array[String]) -> Array[String] {
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
fn resolve_relative_resource_path(
  base_file_path : Array[String],
  relative_path : String,
) -> Array[String] {
  let rel = relative_path.replace(old="\\", new="/")
  if rel.has_prefix("/") {
    abort("tiled resource reference must be relative: \{relative_path}")
  }
  let base_dir : Array[String] = []
  for i = 0; i + 1 < base_file_path.length(); i = i + 1 {
    base_dir.push(base_file_path[i])
  }
  let joined = Array::new(capacity=base_dir.length() + 8)
  for part in base_dir {
    joined.push(part)
  }
  for part in split_resource_path(rel) {
    joined.push(part)
  }
  normalize_resource_path_parts(joined)
}

///|
fn resolve_external_tilesets_in_tmj_json(
  tiled_path : Array[String],
  tmj_json : Json,
) -> Json {
  guard tmj_json is Object(root_obj) else {
    abort("map.tmj root must be object, tiled_path=\{join_path(tiled_path)}")
  }
  guard root_obj.get("tilesets") is Some(Array(tilesets)) else {
    abort("map.tmj missing `tilesets`, tiled_path=\{join_path(tiled_path)}")
  }
  let resolved_tilesets : Array[Json] = []
  for tileset_json in tilesets {
    guard tileset_json is Object(tileset_ref) else {
      abort("tileset entry must be object, tiled_path=\{join_path(tiled_path)}")
    }
    match tileset_ref.get("source") {
      Some(String(source)) if source.length() > 0 => {
        let source_path = resolve_relative_resource_path(tiled_path, source)
        let tsj_json = require_json("assets/map/" + join_path(source_path))
        guard tsj_json is Object(tsj_obj) else {
          abort(
            "failed to load external tileset: \{source}, tiled_path=\{join_path(tiled_path)}",
          )
        }
        guard tileset_ref.get("firstgid") is Some(first_gid) else {
          abort("tileset source missing `firstgid`, source=\{source}")
        }
        let merged : Map[String, Json] = {}
        for key, value in tsj_obj {
          merged[key] = value
        }
        merged["firstgid"] = first_gid
        merged["source"] = Json::string(source)
        resolved_tilesets.push(Json::object(merged))
      }
      _ => resolved_tilesets.push(tileset_json)
    }
  }
  let resolved_root : Map[String, Json] = {}
  for key, value in root_obj {
    resolved_root[key] = value
  }
  resolved_root["tilesets"] = Json::array(resolved_tilesets)
  Json::object(resolved_root)
}

///|
/// Load map `mx.json` and the referenced `map.tmj`, then resolve external
/// TSJ tilesets through the same `mapx` loader.
pub fn load_tiled_map_from_mx(
  mx_path : Array[String],
) -> (String, @tiled.TiledMap) {
  let mx_json = require_json("assets/map/" + join_path(mx_path))
  if mx_json is Null {
    abort("mx.json not found, path=\{to_repr(mx_path)}")
  }
  let tiled_path = match mx_json {
    { "tiled_path": String(path), .. } if path.length() > 0 => path
    _ => abort("invalid mx.json, path=\{to_repr(mx_path)}")
  }
  // Resolve tiled_path relative to mx.json directory (handles ../tiles/...)
  let tiled_path_parts = resolve_relative_resource_path(mx_path, tiled_path)
  guard !tiled_path_parts.is_empty() else {
    abort("invalid tiled_path in mx.json: \{tiled_path}")
  }
  let tmj_json = require_json("assets/map/" + join_path(tiled_path_parts))
  if tmj_json is Null {
    abort("map.tmj not found, tiled_path=\{tiled_path}")
  }
  let resolved_tmj_json = resolve_external_tilesets_in_tmj_json(
    tiled_path_parts, tmj_json,
  )
  let tiled_map = @tiled.TiledMap::from_tiled_json(resolved_tmj_json)
  (
    "assets/map/" + join_path(tiled_path_parts),
    @tiled.with_tiled_map_source_path(tiled_map, "assets/map/" + join_path(tiled_path_parts)),
  )
}
