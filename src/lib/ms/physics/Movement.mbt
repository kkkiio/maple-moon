///|
/// Network movement record type.
enum MovementType {
  NONE
  ABSOLUTE
  RELATIVE
  CHAIR
  JUMPDOWN
} derive(Eq, Compare, Show, ToJson, FromJson)

///|
/// One movement segment parsed from packet or built from physics state.
pub struct Movement {
  t : MovementType
  command : Int
  xpos : Int
  ypos : Int
  lastx : Int
  lasty : Int
  fh : Int
  newstate : Int
  duration : Int
} derive(Show, ToJson, FromJson)

///|
/// Build an empty movement segment.
pub fn Movement::default() -> Movement {
  Movement::new(MovementType::NONE, 0, 0, 0, 0, 0, 0, 0, 0)
}

///|
/// Construct a movement segment with all raw fields.
pub fn Movement::new(
  t : MovementType,
  c : Int,
  x : Int,
  y : Int,
  lx : Int,
  ly : Int,
  f : Int,
  s : Int,
  d : Int,
) -> Movement {
  {
    t,
    command: c,
    xpos: x,
    ypos: y,
    lastx: lx,
    lasty: ly,
    fh: f,
    newstate: s,
    duration: d,
  }
}

///|
/// Construct an ABSOLUTE movement from coordinates.
pub fn Movement::from_coords(
  x : Int,
  y : Int,
  lx : Int,
  ly : Int,
  s : Int,
  d : Int,
) -> Movement {
  Movement::new(MovementType::ABSOLUTE, 0, x, y, lx, ly, 0, s, d)
}

///|
/// Build an ABSOLUTE movement from current physics object state.
pub fn Movement::from_physics_object(
  phobj : PhysicsObject,
  s : Int,
) -> Movement {
  Movement::new(
    MovementType::ABSOLUTE,
    0,
    phobj.get_x(),
    phobj.get_y(),
    phobj.get_last_x(),
    phobj.get_last_y(),
    phobj.fh_id,
    s,
    1,
  )
}

///|
/// Check whether two movement segments are different in visible state.
pub fn Movement::hasmoved(self : Movement, newmove : Movement) -> Bool {
  newmove.newstate != self.newstate ||
  newmove.xpos != self.xpos ||
  newmove.ypos != self.ypos ||
  newmove.lastx != self.lastx ||
  newmove.lasty != self.lasty
}
