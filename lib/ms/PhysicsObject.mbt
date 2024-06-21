struct MovingObject {
  mut x : Linear
  mut y : Linear
  mut hspeed : Double
  mut vspeed : Double
} derive(Debug, Show)

pub fn MovingObject::default() -> MovingObject {
  { x: Linear::default(), y: Linear::default(), hspeed: 0.0, vspeed: 0.0 }
}

pub fn normalize(self : MovingObject) -> Unit {
  self.x.normalize()
  self.y.normalize()
}

pub fn move(self : MovingObject) -> Unit {
  if self.vspeed != 0.0 {
    println("MovingObject::move y \(self)")
  }
  self.x.set(self.x.now + self.hspeed)
  self.y.set(self.y.now + self.vspeed)
}

pub fn set_x(self : MovingObject, d : Double) -> Unit {
  self.x.set(d)
}

pub fn set_y(self : MovingObject, d : Double) -> Unit {
  println("MovingObject::set_y d=\(d)")
  self.y.set(d)
}

pub fn limitx(self : MovingObject, d : Double) -> Unit {
  self.x.set(d)
  self.hspeed = 0.0
}

pub fn limity(self : MovingObject, d : Double) -> Unit {
  println("MovingObject::limity d=\(d)")
  self.y.set(d)
  self.vspeed = 0.0
}

pub fn movexuntil(self : MovingObject, d : Double, delay : Int) -> Unit {
  if delay != 0 {
    let hdelta = d - self.x.now
    self.hspeed = @Constants.timestep.to_double() * hdelta / delay.to_double()
  }
}

pub fn moveyuntil(self : MovingObject, d : Double, delay : Int) -> Unit {
  if delay != 0 {
    let vdelta = d - self.y.now
    self.vspeed = @Constants.timestep.to_double() * vdelta / delay.to_double()
  }
}

pub fn hmobile(self : MovingObject) -> Bool {
  self.hspeed != 0.0
}

pub fn vmobile(self : MovingObject) -> Bool {
  self.vspeed != 0.0
}

pub fn mobile(self : MovingObject) -> Bool {
  self.hmobile() || self.vmobile()
}

pub fn crnt_x(self : MovingObject) -> Double {
  self.x.now
}

pub fn crnt_y(self : MovingObject) -> Double {
  self.y.now
}

pub fn next_x(self : MovingObject) -> Double {
  self.x.plus(self.hspeed)
}

pub fn next_y(self : MovingObject) -> Double {
  self.y.plus(self.vspeed)
}

pub fn get_x(self : MovingObject) -> Int {
  self.x.now.round().to_int()
}

pub fn get_y(self : MovingObject) -> Int {
  self.y.now.round().to_int()
}

pub fn get_last_x(self : MovingObject) -> Int {
  self.x.last().round().to_int()
}

pub fn get_last_y(self : MovingObject) -> Int {
  self.y.last().round().to_int()
}

pub fn get_position(self : MovingObject) -> Point[Int] {
  { x: self.get_x(), y: self.get_y() }
}

pub fn get_absolute_x(
  self : MovingObject,
  viewx : Double,
  alpha : Double
) -> Int {
  let interx = if self.x.normalized() {
    self.x.now.round()
  } else {
    self.x.get(alpha)
  }
  (interx + viewx).round().to_int()
}

pub fn get_absolute_y(
  self : MovingObject,
  viewy : Double,
  alpha : Double
) -> Int {
  let intery = if self.y.normalized() {
    self.y.now.round()
  } else {
    self.y.get(alpha)
  }
  (intery + viewy).round().to_int()
}

pub fn get_absolute(
  self : MovingObject,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Point[Int] {
  { x: self.get_absolute_x(viewx, alpha), y: self.get_absolute_y(viewy, alpha) }
}

pub enum PhysicsObjectType {
  NORMAL
  ICE
  SWIMMING
  FLYING
  FIXATED
} derive(Eq, Compare, Debug, Show)

pub enum PhysicsObjectFlag {
  NO_GRAVITY
  TURN_AT_EDGES
  CHECK_BELOW
} derive(Eq, Compare)

pub let all_physic_object_flags : @immut/sorted_map.Map[PhysicsObjectFlag, Int] = @immut/sorted_map.Map::[
  (PhysicsObjectFlag::NO_GRAVITY, 0x0001),
  (PhysicsObjectFlag::TURN_AT_EDGES, 0x0002),
  (PhysicsObjectFlag::CHECK_BELOW, 0x0004),
]

pub fn int_value(self : PhysicsObjectFlag) -> Int {
  all_physic_object_flags[self].unwrap()
}

struct PhysicsObject {
  moving_object : MovingObject
  mut type_ : PhysicsObjectType
  mut flags : Int
  mut fhid : Int
  mut fhslope : Double
  mut fhlayer : Int
  mut groundbelow : Double
  mut onground : Bool
  mut enablejd : Bool
  mut hforce : Double
  mut vforce : Double
  mut hacc : Double
  mut vacc : Double
}

pub fn PhysicsObject::default() -> PhysicsObject {
  {
    moving_object: MovingObject::default(),
    type_: PhysicsObjectType::NORMAL,
    flags: 0,
    fhid: 0,
    fhslope: 0.0,
    fhlayer: 0,
    groundbelow: 0.0,
    onground: true,
    enablejd: false,
    hforce: 0.0,
    vforce: 0.0,
    hacc: 0.0,
    vacc: 0.0,
  }
}

pub fn is_flag_set(self : PhysicsObject, f : PhysicsObjectFlag) -> Bool {
  self.flags.land(f.int_value()) != 0
}

pub fn is_flag_not_set(self : PhysicsObject, f : PhysicsObjectFlag) -> Bool {
  self.is_flag_set(f).not()
}

pub fn set_flag(self : PhysicsObject, f : PhysicsObjectFlag) -> Unit {
  self.flags = self.flags.lor(f.int_value())
}

pub fn clear_flag(self : PhysicsObject, f : PhysicsObjectFlag) -> Unit {
  self.flags = self.flags.land(f.int_value().lnot())
}

pub fn clear_flags(self : PhysicsObject) -> Unit {
  self.flags = 0
}

pub fn move(self : PhysicsObject) -> Unit {
  self.moving_object.move()
}

pub fn set_x(self : PhysicsObject, x : Double) -> Unit {
  self.moving_object.set_x(x)
}

pub fn set_y(self : PhysicsObject, y : Double) -> Unit {
  self.moving_object.set_y(y)
}

pub fn limitx(self : PhysicsObject, x : Double) -> Unit {
  self.moving_object.limitx(x)
}

pub fn limity(self : PhysicsObject, y : Double) -> Unit {
  self.moving_object.limity(y)
}

pub fn get_x(self : PhysicsObject) -> Int {
  self.moving_object.get_x()
}

pub fn get_y(self : PhysicsObject) -> Int {
  self.moving_object.get_y()
}

pub fn get_position(self : PhysicsObject) -> Point[Int] {
  self.moving_object.get_position()
}

pub fn get_absolute_x(
  self : PhysicsObject,
  viewx : Double,
  alpha : Double
) -> Int {
  self.moving_object.get_absolute_x(viewx, alpha)
}

pub fn get_absolute_y(
  self : PhysicsObject,
  viewy : Double,
  alpha : Double
) -> Int {
  self.moving_object.get_absolute_y(viewy, alpha)
}

pub fn get_absolute(
  self : PhysicsObject,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Point[Int] {
  self.moving_object.get_absolute(viewx, viewy, alpha)
}

pub fn get_last_x(self : PhysicsObject) -> Int {
  self.moving_object.get_last_x()
}

pub fn get_last_y(self : PhysicsObject) -> Int {
  self.moving_object.get_last_y()
}
