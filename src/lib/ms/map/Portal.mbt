///|
pub(all) enum PortalType {
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
    _ => return None
  }
  Some(t)
}

///|
pub impl @json.FromJson for PortalType with from_json(json, path) -> PortalType {
  match json {
    Number(n, ..) =>
      PortalType::typebyid(n.to_int()).or_error(
        @json.JsonDecodeError((path, "Unknown portal type \{n}")),
      )
    _ => raise @json.JsonDecodeError((path, "Expected a number"))
  }
}

///|
pub(all) struct PortalWarpInfo {
  mapid : Int?
  toname : String
  name : String
  /// whether the target is in the current map
  intra_map : Bool
}

///|
fn PortalWarpInfo::new(
  m : Int,
  i : Bool,
  tn : String,
  n : String,
) -> PortalWarpInfo {
  {
    mapid: if m < 999999999 {
      Some(m)
    } else {
      None
    },
    toname: tn,
    name: n,
    intra_map: i,
  }
}

///|
fn PortalWarpInfo::default() -> PortalWarpInfo {
  { mapid: None, toname: "", name: "", intra_map: false }
}

///|
struct Portal {
  entity : @entity.Entity
  animation : @sprite.Sprite?
  t : PortalType
  name : String
  position : Point[Int]
  warp_info : PortalWarpInfo
  mut touched : Bool
}

///|
pub fn Portal::new(
  animation : @sprite.Sprite?,
  t : PortalType,
  name : String,
  intramap : Bool,
  position : Point[Int],
  tomap : Int,
  toname : String,
) -> Portal {
  let entity = @entity.Entity::new()
  @position.positions.set(
    entity,
    @position.Position(
      @selene_math.Vec2D(position.x.to_double(), position.y.to_double()),
    ),
  )
  if animation is Some(animation) {
    @sprite.sprites.set(entity, animation)
  }
  {
    entity,
    animation,
    t,
    name,
    position,
    warp_info: PortalWarpInfo::new(tomap, intramap, toname, name),
    touched: false,
  }
}

///|
pub fn Portal::update(self : Portal, playerpos : Point[Int]) -> Unit {
  self.touched = self.bounds().contains(playerpos)
  guard self.animation is Some(animation) else { return }
  if self.t != PortalType::HIDDEN || self.touched {
    animation.visible = true
  } else {
    animation.visible = false
  }
}

///|
pub fn Portal::draw(
  self : Portal,
  viewpos : Point[Int],
  inter : Double,
) -> Unit {

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
