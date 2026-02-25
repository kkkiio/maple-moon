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
  canvas : @resource.NxAnimation
} derive (
  @json.FromJson(fields(center_x(rename="centerX"), center_y(rename="centerY"))),
)

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
} derive(Eq, Show)

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
pub fn MiniMapPortal::new(
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
  canvas : @resource.NxAnimation
  draw_data : MapDrawData
  portals : Array[MiniMapPortal]
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
  { canvas: resource.canvas, draw_data, portals }
}
