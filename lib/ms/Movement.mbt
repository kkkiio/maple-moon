enum MovementType {
  NONE
  ABSOLUTE
  RELATIVE
  CHAIR
  JUMPDOWN
} derive(Debug, Eq, Compare)

struct Movement {
  t : MovementType
  command : Int
  xpos : Int
  ypos : Int
  lastx : Int
  lasty : Int
  fh : Int
  newstate : Int
  duration : Int
}

pub fn Movement::default() -> Movement {
  Movement::new(MovementType::NONE, 0, 0, 0, 0, 0, 0, 0, 0)
}

pub fn Movement::new(
  t : MovementType,
  c : Int,
  x : Int,
  y : Int,
  lx : Int,
  ly : Int,
  f : Int,
  s : Int,
  d : Int
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

pub fn Movement::from_coords(
  x : Int,
  y : Int,
  lx : Int,
  ly : Int,
  s : Int,
  d : Int
) -> Movement {
  Movement::new(MovementType::ABSOLUTE, 0, x, y, lx, ly, 0, s, d)
}

pub fn Movement::from_physics_object(
  phobj : PhysicsObject,
  s : Int
) -> Movement {
  Movement::new(
    MovementType::ABSOLUTE,
    0,
    phobj.get_x(),
    phobj.get_y(),
    phobj.get_last_x(),
    phobj.get_last_y(),
    phobj.fhid,
    s,
    1,
  )
}

pub fn hasmoved(self : Movement, newmove : Movement) -> Bool {
  newmove.newstate != self.newstate || newmove.xpos != self.xpos || newmove.ypos !=
  self.ypos || newmove.lastx != self.lastx || newmove.lasty != self.lasty
}
