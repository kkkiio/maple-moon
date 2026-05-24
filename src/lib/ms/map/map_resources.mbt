///|
pub(all) struct MapRawResources {
  id : Int
  mx_map : MxMap
  tiled_map : @tiled.TiledMap
  background_animations : Map[String, @resource.SeleneClip]
}

///|
pub struct MxMap {
  tiled_path : String
}

///|
pub impl @json.FromJson for MxMap with fn from_json(json, path) {
  match json {
    { "tiled_path": String(tiled_path), .. } if tiled_path.length() > 0 =>
      { tiled_path, }
    _ => raise @json.JsonDecodeError((path, "missing `tiled_path`"))
  }
}

///|
/// Loads the raw map resources by map id.
pub fn load_map_resources_by_id(map_id : Int) -> MapRawResources {
  guard map_id >= 0 else { abort("invalid map_id=\{map_id}") }
  let prefix = (map_id / 100000000).to_string()
  let strid = @utils.stoi_left_pad0(map_id, 9)
  let mx_path = ["Map", "Map\{prefix}", "\{strid}.img", "mx.json"]
  @log.info("loading map mx resource", data={ "path": mx_path })
  let loader = @resource.require_async_loader("mapx")
  let (tiled_path, tiled_map) = @resource.load_tiled_map_from_mx(
    loader, mx_path,
  )
  let animation_loader = @resource.AnimationLoader::new(loader)
  let background_animations = load_tiled_background_animations(
    tiled_path, tiled_map, animation_loader,
  )
  { id: map_id, mx_map: { tiled_path, }, tiled_map, background_animations }
}

///|
fn aseprite_to_json_path(path : String) -> String? {
  if path.has_suffix(".aseprite") {
    return Some(path.strip_suffix(".aseprite").unwrap().to_owned() + ".json")
  }
  None
}

///|
fn load_tiled_background_animations(
  tiled_path : String,
  tiled_map : @tiled.TiledMap,
  animation_loader : @resource.AnimationLoader,
) -> Map[String, @resource.SeleneClip] {
  let loaded : Map[String, @resource.SeleneClip] = {}
  for layer in tiled_map.layers {
    guard layer.kind is ImageLayer(image_layer) else { continue }
    guard image_layer.image is Some(image_path) else { continue }
    guard aseprite_to_json_path(image_path) is Some(json_path) else { continue }
    let resolved_json_path = @resource.resolve_ref(tiled_path, json_path)
    let clips = animation_loader.load(resolved_json_path)
    let clip = if clips.list_tags().contains("main") {
      clips.clip("main") catch {
        err =>
          abort(
            "missing main background animation: \{resolved_json_path}, error=\{err}",
          )
      }
    } else if clips.list_tags().is_empty() {
      abort("no tags in background animation: \{resolved_json_path}")
    } else {
      clips.clip(clips.list_tags()[0]) catch {
        err =>
          abort(
            "missing fallback background animation: \{resolved_json_path}, error=\{err}",
          )
      }
    }
    loaded[layer.name] = clip
  }
  loaded
}

///|
pub struct NxLife {
  cy : Int
  f : Int
  fh : Int
  hide : Int
  id : String
  mob_time : Int? // mobTime can be null or missing
  rx0 : Int
  rx1 : Int
  type_ : String
  x : Int
  y : Int
} derive(Debug)

///|
pub impl @json.FromJson for NxLife with fn from_json(json, path) {
  match json {
    {
      "cy": Number(cy, ..),
      "fh": Number(fh, ..),
      "id": String(id),
      "rx0": Number(rx0, ..),
      "rx1": Number(rx1, ..),
      "type": String(type_),
      "x": Number(x, ..),
      "y": Number(y, ..),
      ..
    } => {
      // f, hide, mobTime are optional
      let f = if json is { "f": Number(f, ..), .. } { f.to_int() } else { 0 }
      let hide = if json is { "hide": Number(hide, ..), .. } {
        hide.to_int()
      } else {
        0
      }
      let mob_time = if json is { "mobTime": Number(mob_time, ..), .. } {
        Some(mob_time.to_int())
      } else {
        None
      }
      {
        cy: cy.to_int(),
        f,
        fh: fh.to_int(),
        hide,
        id,
        mob_time,
        rx0: rx0.to_int(),
        rx1: rx1.to_int(),
        type_,
        x: x.to_int(),
        y: y.to_int(),
      }
    }
    _ => raise @json.JsonDecodeError((path, "missing life fields"))
  }
}

///|
test "parse misssing" {
  let src : Json = {
    "cy": 274,
    "fh": 126,
    "id": "1012000",
    "rx0": 99,
    "rx1": 199,
    "type": "n",
    "x": 149,
    "y": 267,
  }
  let life : NxLife = @json.from_json(src)
  debug_inspect(
    life,
    content=(
      #|{
      #|  cy: 274,
      #|  f: 0,
      #|  fh: 126,
      #|  hide: 0,
      #|  id: "1012000",
      #|  mob_time: None,
      #|  rx0: 99,
      #|  rx1: 199,
      #|  type_: "n",
      #|  x: 149,
      #|  y: 267,
      #|}
    ),
  )
}
