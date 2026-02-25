///|
/// 传送门
struct NxPortal {
  /// portal name
  pn : String
  /// target map id. `999999999` 通常表示无目标 (常用于出生点).
  tm : Int
  /// target portal name.
  tn : String
  x : Int
  y : Int
  /// portal type
  pt : PortalType
} derive(Show, @json.FromJson, ToJson)

///|
pub(all) enum PortalType {
  /// 出生点
  SPAWN = 0
  /// A normal portal that is not visible and not hidden.
  INVISIBLE = 1
  /// A shining portal.
  REGULAR = 2
  TOUCH = 3
  TYPE4 = 4
  TYPE5 = 5
  WARP = 6
  SCRIPTED = 7
  SCRIPTED_INVISIBLE = 8
  SCRIPTED_TOUCH = 9
  HIDDEN = 10
  SCRIPTED_HIDDEN = 11
  SPRING1 = 12
  SPRING2 = 13
  TYPE14 = 14
} derive(Eq, Compare, Show, ToJson, Hash)

///|
pub fn PortalType::typebyid(id : Int) -> PortalType? {
  let t = match id {
    0 => PortalType::SPAWN
    1 => PortalType::INVISIBLE
    2 => PortalType::REGULAR
    3 => PortalType::TOUCH
    4 => PortalType::TYPE4
    5 => PortalType::TYPE5
    6 => PortalType::WARP
    7 => PortalType::SCRIPTED
    8 => PortalType::SCRIPTED_INVISIBLE
    9 => PortalType::SCRIPTED_TOUCH
    10 => PortalType::HIDDEN
    11 => PortalType::SCRIPTED_HIDDEN
    12 => PortalType::SPRING1
    13 => PortalType::SPRING2
    14 => PortalType::TYPE14
    _ => return None
  }
  Some(t)
}

///|
pub impl @json.FromJson for PortalType with from_json(json, path) -> PortalType {
  match json {
    Number(n, ..) =>
      PortalType::typebyid(n.to_int()).unwrap_or_error(
        @json.JsonDecodeError((path, "Unknown portal type \{n}")),
      )
    _ => raise @json.JsonDecodeError((path, "Expected a number"))
  }
}

///|
pub(all) struct PortalWarpInfo {
  map_id : Int
  toname : String
  name : String
  /// whether the target is in the current map
  intra_map : Bool
} derive(Show)

///|
fn PortalWarpInfo::new(
  m : Int,
  i : Bool,
  tn : String,
  n : String,
) -> PortalWarpInfo {
  { map_id: m, toname: tn, name: n, intra_map: i }
}

///|
struct Portal {
  animation : @sprite.Animation?
  t : PortalType
  name : String
  position : Point[Int]
  warp_info : PortalWarpInfo
  mut touched : Bool
}

///|
pub fn Portal::new(
  animation : @sprite.Animation?,
  t : PortalType,
  name : String,
  intramap : Bool,
  position : Point[Int],
  tomap : Int,
  toname : String,
) -> Portal {
  {
    animation,
    t,
    name,
    position,
    warp_info: PortalWarpInfo::new(tomap, intramap, toname, name),
    touched: false,
  }
}

///|
/// Update the portal's touched state based on the touch position.
pub fn Portal::update_touched(
  self : Portal,
  entity : @entity.Entity,
  touch_pos : Point[Int]?,
) -> Unit {
  self.touched = touch_pos is Some(touch_pos) &&
    self.bounds().contains(touch_pos)
  guard @sprite.sprites.get(entity) is Some(sp) else { return }
  if self.t != PortalType::HIDDEN || self.touched {
    sp.visible = true
  } else {
    sp.visible = false
  }
}

///|
pub fn Portal::get_name(self : Portal) -> String {
  self.name
}

///|
pub fn Portal::get_type(self : Portal) -> PortalType {
  self.t
}

///|
pub fn Portal::get_position(self : Portal) -> Point[Int] {
  self.position
}

///|
pub fn Portal::bounds(self : Portal) -> @struct.Rectangle[Int] {
  let lt = self.position + @struct.Point::new(-25, -100)
  let rb = self.position + @struct.Point::new(25, 25)
  @struct.Rectangle::new(lt, rb)
}

///|
pub fn Portal::getwarpinfo(self : Portal) -> PortalWarpInfo {
  self.warp_info
}
