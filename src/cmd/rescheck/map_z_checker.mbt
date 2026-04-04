///|
fn register_map_z_checker() -> Checker {
  { name: "map_z", run: fn(ctx) { check_map_z_resources(ctx) } }
}

///|
fn check_map_z_resources(ctx : RescheckContext) -> Array[CheckIssue] {
  let issues : Array[CheckIssue] = []
  for abs_path in ctx.all_files {
    let rel_path = path_relative(abs_path, ctx.assets_root)
    if !rel_path.has_suffix("/map.tmj") {
      continue
    }
    check_one_map_tmj(ctx, abs_path, rel_path, issues)
  }
  issues
}

///|
fn check_one_map_tmj(
  ctx : RescheckContext,
  abs_path : String,
  rel_path : String,
  issues : Array[CheckIssue],
) -> Unit {
  let tmj = @json.parse(read_text_file(abs_path)) catch {
    e => {
      issues.push(make_issue("map_z", Error, rel_path, "invalid json: \{e}"))
      return
    }
  }
  guard tmj is { "layers": Array(layers), .. } else {
    issues.push(make_issue("map_z", Error, rel_path, "missing layers array"))
    return
  }
  let last_bucket = Ref::new(-1)
  let last_map_layer = Ref::new(-1)
  let obj_index_by_layer : Map[Int, Int] = Map::new()
  let tile_index_by_layer : Map[Int, Int] = Map::new()
  for idx, layer in layers {
    guard layer is { "name": String(name), "type": String(layer_type), .. } else {
      continue
    }
    let bucket = layer_order_bucket(name)
    if bucket >= 0 && bucket < last_bucket.val {
      issues.push(
        make_issue(
          "map_z",
          Error,
          rel_path,
          "layer order violation: '\{name}' appears after higher-priority bucket",
        ),
      )
    }
    if bucket >= 0 {
      last_bucket.val = bucket
    }
    guard parse_map_layer_name(name) is Some((layer_id, kind)) else { continue }
    if layer_type != "objectgroup" {
      issues.push(
        make_issue(
          "map_z",
          Error,
          rel_path,
          "layer '\{name}' must be objectgroup, got \{layer_type}",
        ),
      )
    }
    if layer_id < MAP_LAYER_MIN || layer_id > MAP_LAYER_MAX {
      issues.push(
        make_issue(
          "map_z",
          Error,
          rel_path,
          "layer '\{name}' id out of range: \{layer_id}",
        ),
      )
    }
    if last_map_layer.val > layer_id {
      issues.push(
        make_issue(
          "map_z",
          Error,
          rel_path,
          "map layer order must be ascending, got layer_\{layer_id} after layer_\{last_map_layer.val}",
        ),
      )
    }
    last_map_layer.val = layer_id
    if kind == "obj" {
      if obj_index_by_layer.contains(layer_id) {
        issues.push(
          make_issue(
            "map_z",
            Error,
            rel_path,
            "duplicate obj layer group for layer \{layer_id}",
          ),
        )
      }
      obj_index_by_layer[layer_id] = idx
    } else if kind == "tile" {
      if tile_index_by_layer.contains(layer_id) {
        issues.push(
          make_issue(
            "map_z",
            Error,
            rel_path,
            "duplicate tile layer group for layer \{layer_id}",
          ),
        )
      }
      tile_index_by_layer[layer_id] = idx
    }
    check_map_layer_objects(rel_path, name, layer, layer_id, kind, issues)
  }
  for layer_id, obj_idx in obj_index_by_layer {
    guard tile_index_by_layer.contains(layer_id) else { continue }
    let tile_idx = tile_index_by_layer[layer_id]
    if obj_idx >= tile_idx {
      issues.push(
        make_issue(
          "map_z",
          Error,
          rel_path,
          "layer_\{layer_id}_obj must appear before layer_\{layer_id}_tile",
        ),
      )
    }
  }
  ignore(ctx)
}

///|
fn check_map_layer_objects(
  rel_path : String,
  layer_name : String,
  layer : Json,
  layer_id : Int,
  kind : String,
  issues : Array[CheckIssue],
) -> Unit {
  guard layer is { "objects": Array(objects), .. } else {
    issues.push(
      make_issue(
        "map_z",
        Error,
        rel_path,
        "layer '\{layer_name}' missing objects array",
      ),
    )
    return
  }
  for obj in objects {
    guard obj is Object(obj_map) else {
      issues.push(
        make_issue(
          "map_z",
          Error,
          rel_path,
          "object in '\{layer_name}' must be object",
        ),
      )
      continue
    }
    let object_id = json_object_int_field(obj_map, "id").unwrap_or(-1)
    guard obj_map.get("properties") is Some(Array(properties)) else {
      issues.push(
        make_issue(
          "map_z",
          Error,
          rel_path,
          "object id=\{object_id} in '\{layer_name}' missing properties",
        ),
      )
      continue
    }
    guard find_property_int(properties, "layer") is Some(prop_layer) else {
      issues.push(
        make_issue(
          "map_z",
          Error,
          rel_path,
          "object id=\{object_id} in '\{layer_name}' missing int property 'layer'",
        ),
      )
      continue
    }
    if prop_layer != layer_id {
      issues.push(
        make_issue(
          "map_z",
          Error,
          rel_path,
          "object id=\{object_id} in '\{layer_name}' has layer=\{prop_layer}, expect \{layer_id}",
        ),
      )
    }
    match kind {
      "obj" => {
        guard find_property_int(properties, "z") is Some(z) else {
          issues.push(
            make_issue(
              "map_z",
              Error,
              rel_path,
              "object id=\{object_id} in '\{layer_name}' missing int property 'z'",
            ),
          )
          continue
        }
        guard find_property_int(properties, "zM") is Some(zM) else {
          issues.push(
            make_issue(
              "map_z",
              Error,
              rel_path,
              "object id=\{object_id} in '\{layer_name}' missing int property 'zM'",
            ),
          )
          continue
        }
        check_local_and_lane(
          rel_path,
          layer_name,
          object_id,
          MAP_PASS_OBJ,
          z,
          zM,
          issues,
        )
      }
      "tile" => {
        guard find_property_int(properties, "zM") is Some(zM) else {
          issues.push(
            make_issue(
              "map_z",
              Error,
              rel_path,
              "object id=\{object_id} in '\{layer_name}' missing int property 'zM'",
            ),
          )
          continue
        }
        check_local_and_lane(
          rel_path,
          layer_name,
          object_id,
          MAP_PASS_TILE,
          0,
          zM,
          issues,
        )
      }
      _ => ()
    }
  }
}

///|
fn check_local_and_lane(
  rel_path : String,
  layer_name : String,
  object_id : Int,
  pass : Int,
  z : Int,
  zM : Int,
  issues : Array[CheckIssue],
) -> Unit {
  if z < 0 || z > MAP_LOCAL_MAX {
    issues.push(
      make_issue(
        "map_z",
        Error,
        rel_path,
        "object id=\{object_id} in '\{layer_name}' has z=\{z} out of range [0,\{MAP_LOCAL_MAX}]",
      ),
    )
  }
  if zM < 0 || zM > MAP_LOCAL_MAX {
    issues.push(
      make_issue(
        "map_z",
        Error,
        rel_path,
        "object id=\{object_id} in '\{layer_name}' has zM=\{zM} out of range [0,\{MAP_LOCAL_MAX}]",
      ),
    )
  }
  let local_offset = if z > 0 { z } else { zM }
  let lane = pass + local_offset
  if lane >= MAP_LAYER_STRIDE {
    issues.push(
      make_issue(
        "map_z",
        Error,
        rel_path,
        "object id=\{object_id} in '\{layer_name}' lane overflow: pass+local=\{lane}, stride=\{MAP_LAYER_STRIDE}",
      ),
    )
  }
}

///|
fn layer_order_bucket(name : String) -> Int {
  if name.has_prefix("background_back_") {
    return 0
  }
  if parse_map_layer_name(name) is Some(_) {
    return 1
  }
  if is_debug_layer_name(name) {
    return 2
  }
  if name.has_prefix("background_front_") {
    return 3
  }
  -1
}

///|
fn is_debug_layer_name(name : String) -> Bool {
  match name {
    "portal"
    | "life"
    | "reactor"
    | "foothold"
    | "ladderRope"
    | "seat"
    | "miniMap"
    | "background_back"
    | "background_front" => true
    _ => false
  }
}

///|
fn parse_map_layer_name(name : String) -> (Int, String)? {
  let parts = name.split("_").to_array()
  if parts.length() != 3 || parts[0] != "layer" {
    return None
  }
  if parts[2] != "obj" && parts[2] != "tile" {
    return None
  }
  let parsed = try? @string.parse_int(parts[1])
  match parsed {
    Ok(layer) => Some((layer, parts[2].to_string()))
    Err(_) => None
  }
}

///|
fn json_object_int_field(obj : Map[String, Json], key : String) -> Int? {
  match obj.get(key) {
    Some(Number(v, ..)) => Some(v.to_int())
    _ => None
  }
}

///|
fn find_property_int(properties : Array[Json], key : String) -> Int? {
  for property in properties {
    match property {
      { "name": String(name), "value": Number(value, ..), .. } if name == key =>
        return Some(value.to_int())
      _ => ()
    }
  }
  None
}

///|
const MAP_LAYER_MIN = 0

///|
const MAP_LAYER_MAX = 7

///|
const MAP_LAYER_STRIDE = 5000

///|
const MAP_PASS_OBJ = 200

///|
const MAP_PASS_TILE = 400

///|
const MAP_LOCAL_MAX = 999
