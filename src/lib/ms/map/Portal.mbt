///|
pub(all) enum PortalType {
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
} derive(Eq, Compare, Show)

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
    Number(n) =>
      PortalType::typebyid(n.to_int()).or_error!(
        @json.JsonDecodeError((path, "Unknown portal type \{n}")),
      )
    _ => raise @json.JsonDecodeError((path, "Expected a number"))
  }
}

///|
pub(all) struct PortalWarpInfo {
  mapid : Int
  toname : String
  name : String
  intramap : Bool
  valid : Bool
}

///|
fn PortalWarpInfo::new(
  m : Int,
  i : Bool,
  tn : String,
  n : String
) -> PortalWarpInfo {
  { mapid: m, toname: tn, name: n, intramap: i, valid: m < 999999999 }
}

///|
fn PortalWarpInfo::default() -> PortalWarpInfo {
  { mapid: 999999999, toname: "", name: "", intramap: false, valid: false }
}

///|
struct Portal {
  animation : @graphics.Animation?
  type_ : PortalType
  name : String
  position : Point[Int]
  warp_info : PortalWarpInfo
  mut touched : Bool
}

///|
pub fn Portal::new(
  animation : @graphics.Animation?,
  type_ : PortalType,
  name : String,
  intramap : Bool,
  position : Point[Int],
  tomap : Int,
  toname : String
) -> Portal {
  {
    animation,
    type_,
    name,
    position,
    warp_info: PortalWarpInfo::new(tomap, intramap, toname, name),
    touched: false,
  }
}

///|
pub fn Portal::default() -> Portal {
  {
    animation: None,
    type_: PortalType::SPAWN,
    name: "",
    position: @struct.Point::default(),
    warp_info: PortalWarpInfo::default(),
    touched: false,
  }
}

///|
pub fn Portal::update(self : Portal, playerpos : Point[Int]) -> Unit {
  self.touched = self.bounds().contains(playerpos)
}

///|
pub fn Portal::draw(
  self : Portal,
  viewpos : Point[Int],
  inter : Double
) -> Unit {
  match self.animation {
    Some(animation) =>
      if self.type_ != PortalType::HIDDEN || self.touched {
        animation.draw(
          @graphics.DrawArgument::new(pos=self.position + viewpos),
          inter,
        )
      }
    None => ()
  }
}

///|
pub fn get_name(self : Portal) -> String {
  self.name
}

///|
pub fn get_type(self : Portal) -> PortalType {
  self.type_
}

///|
pub fn get_position(self : Portal) -> Point[Int] {
  self.position
}

///|
pub fn bounds(self : Portal) -> @struct.Rectangle[Int] {
  let lt = self.position + @struct.Point::new(-25, -100)
  let rb = self.position + @struct.Point::new(25, 25)
  @struct.Rectangle::new(lt, rb)
}

///|
pub fn getwarpinfo(self : Portal) -> PortalWarpInfo {
  self.warp_info
}
