///|
/// Map draw parameters from miniMap node.
pub(all) struct MapDrawData {
  /// map scale factor (`2^mag`)
  scale : Float
  /// horizontal center offset
  center_x : Int
  /// vertical center offset
  center_y : Int
}

///|
/// Mini map resource decoded from map json.
pub struct MiniMapResource {
  mag : Int
  center_x : Int
  center_y : Int
  canvas_path : String
  canvas_width : Int
  canvas_height : Int
}

///|
pub impl @json.FromJson for MiniMapResource with fn from_json(json, path) {
  match json {
    {
      "mag": Number(mag, ..),
      "centerX": Number(center_x, ..),
      "centerY": Number(center_y, ..),
      "canvas": {
        "__i": String(canvas_path),
        "__w": Number(canvas_width, ..),
        "__h": Number(canvas_height, ..),
        ..
      },
      ..
    } =>
      {
        mag: mag.to_int(),
        center_x: center_x.to_int(),
        center_y: center_y.to_int(),
        canvas_path,
        canvas_width: canvas_width.to_int(),
        canvas_height: canvas_height.to_int(),
      }
    {
      "mag": Number(mag, ..),
      "centerX": Number(center_x, ..),
      "centerY": Number(center_y, ..),
      "canvas_path": String(canvas_path),
      ..
    } =>
      {
        mag: mag.to_int(),
        center_x: center_x.to_int(),
        center_y: center_y.to_int(),
        canvas_path,
        canvas_width: if json is { "canvas_width": Number(w, ..), .. } {
          w.to_int()
        } else {
          0
        },
        canvas_height: if json is { "canvas_height": Number(h, ..), .. } {
          h.to_int()
        } else {
          0
        },
      }
    _ => raise @json.JsonDecodeError((path, "invalid mini map resource"))
  }
}

///|
pub enum MiniMapPortalType {
  SPAWN
  INVISIBLE
  REGULAR
  TOUCH
  TYPE4
  TYPE5
  WARP
  SCRIPTED
  SCRIPTED_INVISIBLE
  SCRIPTED_TOUCH
  HIDDEN
  SCRIPTED_HIDDEN
  SPRING1
  SPRING2
  TYPE14
} derive(Eq, Debug)

///|
pub fn MiniMapPortalType::from_int(id : Int) -> MiniMapPortalType {
  match id {
    0 => SPAWN
    1 => INVISIBLE
    2 => REGULAR
    3 => TOUCH
    4 => TYPE4
    5 => TYPE5
    6 => WARP
    7 => SCRIPTED
    8 => SCRIPTED_INVISIBLE
    9 => SCRIPTED_TOUCH
    10 => HIDDEN
    11 => SCRIPTED_HIDDEN
    12 => SPRING1
    13 => SPRING2
    14 => TYPE14
    _ => SPAWN
  }
}

///|
pub(all) struct MiniMapPortal {
  x : Int
  y : Int
  tm : Int
  pt : MiniMapPortalType
}

///|
pub fn MiniMapPortal::MiniMapPortal(
  x : Int,
  y : Int,
  tm : Int,
  pt : MiniMapPortalType,
) -> MiniMapPortal {
  { x, y, tm, pt }
}

///|
/// Full runtime mini map resource for rendering.
pub(all) struct MiniMapRuntimeResource {
  canvas : MiniMapCanvas
  draw_data : MapDrawData
  portals : Array[MiniMapPortal]
}

///|
pub(all) struct MiniMapCanvas {
  path : String
  width : Int
  height : Int
}

///|
pub fn MiniMapRuntimeResource::load(
  resource : MiniMapResource,
  portals : Array[MiniMapPortal],
) -> MiniMapRuntimeResource {
  let draw_data = {
    scale: Float::from_double(@math.pow(2.0, resource.mag.to_double())),
    center_x: resource.center_x,
    center_y: resource.center_y,
  }
  {
    canvas: {
      path: resource.canvas_path,
      width: resource.canvas_width,
      height: resource.canvas_height,
    },
    draw_data,
    portals,
  }
}

///|
pub fn MiniMapRuntimeResource::from_tiled(
  resource : MiniMapResource,
  portals : MapPortals,
) -> MiniMapRuntimeResource {
  let mini_map_portals = []
  for _, portal in portals.id_portal_map {
    let pt_id = match portal.get_type() {
      PortalType::SPAWN => 0
      PortalType::INVISIBLE => 1
      PortalType::REGULAR => 2
      PortalType::COLLISION => 3
      PortalType::TYPE4 => 4
      PortalType::TYPE5 => 5
      PortalType::WARP => 6
      PortalType::SCRIPTED => 7
      PortalType::SCRIPTED_INVISIBLE => 8
      PortalType::SCRIPTED_COLLISION => 9
      PortalType::HIDDEN => 10
      PortalType::SCRIPTED_HIDDEN => 11
      PortalType::SPRING1 => 12
      PortalType::SPRING2 => 13
      PortalType::TYPE14 => 14
    }
    let pos = portal.get_position()
    let target = portal.getwarpinfo().map_id
    mini_map_portals.push(
      MiniMapPortal(pos.x, pos.y, target, MiniMapPortalType::from_int(pt_id)),
    )
  }
  MiniMapRuntimeResource::load(resource, mini_map_portals)
}

///|
pub fn from_tiled_mini_map_resource(
  map : @tiled.TiledMap,
) -> MiniMapResource? raise {
  guard map.object_layer("miniMap") is Some(layer) else { return None }
  if layer.objects.length() != 1 {
    fail("`miniMap` layer must contain exactly one object")
  }
  let obj = layer.objects[0]
  let mag = minimap_object_int_required(obj, "mag")
  let center_x = minimap_object_int_required(obj, "centerX")
  let center_y = minimap_object_int_required(obj, "centerY")
  let (canvas_path, canvas_width, canvas_height) = if obj.gid is Some(gid) {
    resolve_canvas_from_gid(map, obj, gid.tile_id)
  } else {
    let path = minimap_object_string_required(obj, "canvas_path")
    (
      map.resolve_path(path),
      minimap_object_int_optional(obj, "canvas_width").unwrap_or(
        obj.width.to_int(),
      ),
      minimap_object_int_optional(obj, "canvas_height").unwrap_or(
        obj.height.to_int(),
      ),
    )
  }
  if canvas_width <= 0 || canvas_height <= 0 {
    fail("invalid miniMap canvas size: \{canvas_width}x\{canvas_height}")
  }
  Some({ mag, center_x, center_y, canvas_path, canvas_width, canvas_height })
}

///|
fn resolve_canvas_from_gid(
  map : @tiled.TiledMap,
  obj : @tiled.TiledObject,
  gid : Int,
) -> (String, Int, Int) raise {
  guard map.tileset_for_gid(gid) is Some(tileset) else {
    fail("miniMap gid references missing tileset, object_id=\{obj.id}")
  }
  let local_id = gid - tileset.first_gid
  let image = match tileset.tile_definition(local_id) {
    Some(def) =>
      match def.image {
        Some(path) => map.resolve_tileset_asset_path(tileset, path)
        None =>
          match tileset.image {
            Some(path) => map.resolve_tileset_asset_path(tileset, path)
            None =>
              fail("miniMap gid has no image, object_id=\{obj.id}, gid=\{gid}")
          }
      }
    None =>
      match tileset.image {
        Some(path) => map.resolve_tileset_asset_path(tileset, path)
        None => fail("miniMap gid has no tileset image, object_id=\{obj.id}")
      }
  }
  let width = if obj.width > 0.0 {
    obj.width.to_int()
  } else {
    tileset.tile_width.unwrap_or(0)
  }
  let height = if obj.height > 0.0 {
    obj.height.to_int()
  } else {
    tileset.tile_height.unwrap_or(0)
  }
  (image, width, height)
}

///|
fn minimap_object_string_required(
  obj : @tiled.TiledObject,
  name : String,
) -> String raise {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::String(value)) => value
    Some(_) =>
      fail("object property '\{name}' must be string, object_id=\{obj.id}")
    None => fail("missing object property '\{name}', object_id=\{obj.id}")
  }
}

///|
fn minimap_object_int_optional(
  obj : @tiled.TiledObject,
  name : String,
) -> Int? raise {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::Int(value)) => Some(value)
    Some(@tiled.TiledPropertyValue::Float(value)) => Some(value.to_int())
    Some(_) =>
      fail("object property '\{name}' must be int, object_id=\{obj.id}")
    None => None
  }
}

///|
fn minimap_object_int_required(
  obj : @tiled.TiledObject,
  name : String,
) -> Int raise {
  match minimap_object_int_optional(obj, name) {
    Some(value) => value
    None => fail("missing object property '\{name}', object_id=\{obj.id}")
  }
}
