///|
enum MovementType {
  NONE
  ABSOLUTE
  RELATIVE
  CHAIR
  JUMPDOWN
} derive(Eq, Compare, Show)

///|
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
} derive(Show)

///|
pub fn Movement::default() -> Movement {
  Movement::new(MovementType::NONE, 0, 0, 0, 0, 0, 0, 0, 0)
}

///|
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

///|
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

///|
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

///|
pub fn hasmoved(self : Movement, newmove : Movement) -> Bool {
  newmove.newstate != self.newstate ||
  newmove.xpos != self.xpos ||
  newmove.ypos != self.ypos ||
  newmove.lastx != self.lastx ||
  newmove.lasty != self.lasty
}

///|
pub fn write_movement(out : @net.OutPacket, movement : Movement) -> Unit {
  out.write_byte(movement.command.to_byte())
  out.write_short(movement.xpos)
  out.write_short(movement.ypos)
  out.write_short(movement.lastx)
  out.write_short(movement.lasty)
  out.write_short(movement.fh)
  out.write_byte(movement.newstate.to_byte())
  out.write_short(movement.duration)
}

///|
pub fn parse_movements(recv : @net.InPacket) -> Array[Movement] raise {
  let movements = []
  let length = recv.read_byte()
  for i in 0..<length {
    let command = recv.read_byte()
    let mut t = MovementType::NONE
    let mut xpos = 0
    let mut ypos = 0
    let mut lastx = 0
    let mut lasty = 0
    let mut fh = 0
    let mut newstate = 0
    let mut duration = 0
    match command {
      0 | 5 | 17 => {
        t = MovementType::ABSOLUTE
        xpos = recv.read_short()
        ypos = recv.read_short()
        lastx = recv.read_short()
        lasty = recv.read_short()
        fh = recv.read_short()
        newstate = recv.read_byte()
        duration = recv.read_short()
      }
      1 | 2 | 6 | 12 | 13 | 16 => {
        t = MovementType::RELATIVE
        xpos = recv.read_short()
        ypos = recv.read_short()
        newstate = recv.read_byte()
        duration = recv.read_short()
      }
      11 => {
        t = MovementType::CHAIR
        xpos = recv.read_short()
        ypos = recv.read_short()
        recv.skip(2)
        newstate = recv.read_byte()
        duration = recv.read_short()
      }
      15 => {
        t = MovementType::JUMPDOWN
        xpos = recv.read_short()
        ypos = recv.read_short()
        lastx = recv.read_short()
        lasty = recv.read_short()
        recv.skip(2)
        fh = recv.read_short()
        newstate = recv.read_byte()
        duration = recv.read_short()
      }
      3 | 4 | 7 | 8 | 9 | 14 => t = MovementType::NONE
      10 => t = MovementType::NONE
      _ => ()
    }
    // Change equip
    movements.push(
      Movement::new(
        t, command, xpos, ypos, lastx, lasty, fh, newstate, duration,
      ),
    )
  }
  movements
}
