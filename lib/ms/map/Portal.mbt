pub enum PortalType {
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
} derive(Eq, Compare)

pub let all_portal_types : FixedArray[PortalType] = [
  SPAWN,
  INVISIBLE,
  REGULAR,
  TOUCH,
  TYPE4,
  TYPE5,
  WARP,
  SCRIPTED,
  SCRIPTED_INVISIBLE,
  SCRIPTED_TOUCH,
  HIDDEN,
  SCRIPTED_HIDDEN,
  SPRING1,
  SPRING2,
  TYPE14,
]

pub fn PortalType::typebyid(id : Int) -> PortalType {
  all_portal_types[id]
}

pub struct PortalWarpInfo {
  mapid : Int
  toname : String
  name : String
  intramap : Bool
  valid : Bool
}

fn PortalWarpInfo::new(
  m : Int,
  i : Bool,
  tn : String,
  n : String
) -> PortalWarpInfo {
  { mapid: m, toname: tn, name: n, intramap: i, valid: m < 999999999 }
}

fn PortalWarpInfo::default() -> PortalWarpInfo {
  { mapid: 999999999, toname: "", name: "", intramap: false, valid: false }
}

struct Portal {
  animation : @graphics.Animation?
  type_ : PortalType
  name : String
  position : Point[Int]
  warp_info : PortalWarpInfo
  mut touched : Bool
}

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

pub fn Portal::default() -> Portal {
  {
    animation: None,
    type_: PortalType::SPAWN,
    name: "",
    position: Point::default(),
    warp_info: PortalWarpInfo::default(),
    touched: false,
  }
}

pub fn update(self : Portal, playerpos : Point[Int]) -> Unit {
  self.touched = self.bounds().contains(playerpos)
}

pub fn draw(self : Portal, viewpos : Point[Int], inter : Double) -> Unit {
  match self.animation {
    Some(animation) =>
      if self.type_ != PortalType::HIDDEN || self.touched {
        animation.draw(
          @graphics.DrawArgument::from_point(self.position + viewpos),
          inter,
        )
      }
    None => ()
  }
}

pub fn get_name(self : Portal) -> String {
  self.name
}

pub fn get_type(self : Portal) -> PortalType {
  self.type_
}

pub fn get_position(self : Portal) -> Point[Int] {
  self.position
}

pub fn bounds(self : Portal) -> @struct.Rectangle[Int] {
  let lt = self.position + Point::new(-25, -100)
  let rb = self.position + Point::new(25, 25)
  @struct.Rectangle::new(lt, rb)
}

pub fn getwarpinfo(self : Portal) -> PortalWarpInfo {
  self.warp_info
}
