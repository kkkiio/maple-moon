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
    return normalize_resource_path_parts(split_resource_path(rel))
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
async fn resolve_external_tilesets_in_tmj_json(
  loader : AsyncLoader,
  tiled_path : Array[String],
  tmj_json : Json,
) -> Json {
  guard tmj_json is Object(root_obj) else {
    fail("map.tmj root must be object, tiled_path=\{join_path(tiled_path)}")
  }
  guard root_obj.get("tilesets") is Some(Array(tilesets)) else {
    fail("map.tmj missing `tilesets`, tiled_path=\{join_path(tiled_path)}")
  }
  let resolved_tilesets : Array[Json] = []
  for tileset_json in tilesets {
    guard tileset_json is Object(tileset_ref) else {
      fail("tileset entry must be object, tiled_path=\{join_path(tiled_path)}")
    }
    match tileset_ref.get("source") {
      Some(String(source)) if source.length() > 0 => {
        let source_path = resolve_relative_resource_path(tiled_path, source)
        let tsj_json = loader.load_resource(source_path)
        guard tsj_json is Object(tsj_obj) else {
          fail(
            "failed to load external tileset: \{source}, tiled_path=\{join_path(tiled_path)}",
          )
        }
        guard tileset_ref.get("firstgid") is Some(first_gid) else {
          fail("tileset source missing `firstgid`, source=\{source}")
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
pub async fn load_tiled_map_from_mx(
  loader : AsyncLoader,
  mx_path : Array[String],
) -> (String, @tiled.TiledMap) {
  let mx_json = loader.load_resource(mx_path)
  if mx_json is Null {
    fail("mx.json not found, path=\{mx_path}")
  }
  let tiled_path = match mx_json {
    { "tiled_path": String(path), .. } if path.length() > 0 => path
    _ => fail("invalid mx.json, path=\{mx_path}")
  }
  let tiled_path_parts = split_resource_path(tiled_path)
  guard !tiled_path_parts.is_empty() else {
    fail("invalid tiled_path in mx.json: \{tiled_path}")
  }
  let tmj_json = loader.load_resource(tiled_path_parts)
  if tmj_json is Null {
    fail("map.tmj not found, tiled_path=\{tiled_path}")
  }
  let resolved_tmj_json = resolve_external_tilesets_in_tmj_json(
    loader, tiled_path_parts, tmj_json,
  )
  let tiled_map = @tiled.TiledMap::from_tiled_json(resolved_tmj_json)
  (
    tiled_path,
    @tiled.with_tiled_map_source_path(
      tiled_map,
      loader.resolve_json_path(join_path(tiled_path_parts)),
    ),
  )
}
