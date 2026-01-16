///|
using @struct {type Point}

///|
pub struct MovingObject {
  x : @utils.Linear
  y : @utils.Linear
  mut hspeed : Double
  mut vspeed : Double
  mut on_pos_change : (@selene_math.Vec2D) -> Unit
}

///|
pub fn MovingObject::new(
  on_pos_change~ : (@selene_math.Vec2D) -> Unit,
) -> MovingObject {
  {
    x: @utils.Linear::default(),
    y: @utils.Linear::default(),
    hspeed: 0.0,
    vspeed: 0.0,
    on_pos_change,
  }
}

///|
pub fn MovingObject::normalize(self : MovingObject) -> Unit {
  self.x.normalize()
  self.y.normalize()
}

///|
pub fn MovingObject::do_move(self : MovingObject) -> Unit {
  let x = self.x.get() + self.hspeed
  let y = self.y.get() + self.vspeed
  self.x.set(x)
  self.y.set(y)
  (self.on_pos_change)(@selene_math.Vec2D(x, y))
}

///|
pub fn MovingObject::set_x(self : MovingObject, d : Double) -> Unit {
  self.x.set(d)
  (self.on_pos_change)(@selene_math.Vec2D(d, self.y.get()))
}

///|
pub fn MovingObject::set_y(self : MovingObject, d : Double) -> Unit {
  self.y.set(d)
  (self.on_pos_change)(@selene_math.Vec2D(self.x.get(), d))
}

///|
pub fn MovingObject::set_position(
  self : MovingObject,
  d : @selene_math.Vec2D,
) -> Unit {
  self.x.set(d.0)
  self.y.set(d.1)
  (self.on_pos_change)(d)
}

///|
pub fn MovingObject::limitx(self : MovingObject, d : Double) -> Unit {
  self.x.set(d)
  self.hspeed = 0.0
  (self.on_pos_change)(@selene_math.Vec2D(d, self.y.get()))
}

///|
pub fn MovingObject::limity(self : MovingObject, d : Double) -> Unit {
  self.y.set(d)
  self.vspeed = 0.0
  (self.on_pos_change)(@selene_math.Vec2D(self.x.get(), d))
}

///|
pub fn MovingObject::movexuntil(
  self : MovingObject,
  d : Double,
  delay : Int,
) -> Unit {
  if delay != 0 {
    let hdelta = d - self.x.get()
    self.hspeed = @logic_fps.STEP_TIME_MS.to_double() *
      hdelta /
      delay.to_double()
  }
}

///|
pub fn MovingObject::moveyuntil(
  self : MovingObject,
  d : Double,
  delay : Int,
) -> Unit {
  if delay != 0 {
    let vdelta = d - self.y.get()
    self.vspeed = @logic_fps.STEP_TIME_MS.to_double() *
      vdelta /
      delay.to_double()
  }
}

///|
pub fn MovingObject::hmobile(self : MovingObject) -> Bool {
  self.hspeed != 0.0
}

///|
pub fn MovingObject::vmobile(self : MovingObject) -> Bool {
  self.vspeed != 0.0
}

///|
pub fn MovingObject::mobile(self : MovingObject) -> Bool {
  self.hmobile() || self.vmobile()
}

///|
pub fn MovingObject::crnt_x(self : MovingObject) -> Double {
  self.x.get()
}

///|
pub fn MovingObject::crnt_y(self : MovingObject) -> Double {
  self.y.get()
}

///|
pub fn MovingObject::next_x(self : MovingObject) -> Double {
  self.x.plus(self.hspeed)
}

///|
pub fn MovingObject::next_y(self : MovingObject) -> Double {
  self.y.plus(self.vspeed)
}

///|
pub fn MovingObject::get_x(self : MovingObject) -> Int {
  self.x.get().round().to_int()
}

///|
pub fn MovingObject::get_y(self : MovingObject) -> Int {
  self.y.get().round().to_int()
}

///|
pub fn MovingObject::get_last_x(self : MovingObject) -> Int {
  self.x.last().round().to_int()
}

///|
pub fn MovingObject::get_last_y(self : MovingObject) -> Int {
  self.y.last().round().to_int()
}

///|
pub fn MovingObject::get_position(self : MovingObject) -> Point[Int] {
  { x: self.get_x(), y: self.get_y() }
}

///|
pub fn MovingObject::get_absolute_x(
  self : MovingObject,
  viewx : Double,
  alpha : Double,
) -> Int {
  get_absolute_coord(self.x, viewx, alpha)
}

///|
pub fn MovingObject::get_absolute_y(
  self : MovingObject,
  viewy : Double,
  alpha : Double,
) -> Int {
  get_absolute_coord(self.y, viewy, alpha)
}

///|
pub fn get_absolute_coord(
  coord : @utils.Linear,
  view : Double,
  alpha : Double,
) -> Int {
  let inter = if coord.normalized() {
    coord.get().round()
  } else {
    coord.get(alpha~)
  }
  (inter + view).round().to_int()
}

///|
pub fn MovingObject::get_absolute(
  self : MovingObject,
  viewx : Double,
  viewy : Double,
  alpha : Double,
) -> Point[Int] {
  { x: self.get_absolute_x(viewx, alpha), y: self.get_absolute_y(viewy, alpha) }
}

///|
pub fn MovingObject::set_vspeed(self : MovingObject, vspeed : Double) -> Unit {
  self.vspeed = vspeed
}

///|
pub fn MovingObject::set_hspeed(self : MovingObject, hspeed : Double) -> Unit {
  self.hspeed = hspeed
}

///|
pub fn MovingObject::set_on_pos_change(
  self : MovingObject,
  on_pos_change : (@selene_math.Vec2D) -> Unit,
) -> Unit {
  self.on_pos_change = on_pos_change
}

///|
pub(all) enum PhysicsObjectType {
  NORMAL
  ICE
  SWIMMING
  FLYING
  FIXATED
} derive(Eq, Compare, Show, ToJson)

///|
pub(all) enum PhysicsObjectFlag {
  NO_GRAVITY = 0x0001
  TURN_AT_EDGES = 0x0002
  CHECK_BELOW = 0x0004
} derive(Eq, Compare, Show, ToJson)

///|
pub fn PhysicsObjectFlag::int_value(self : PhysicsObjectFlag) -> Int = "%identity"

///|
pub struct PhysicsObject {
  moving_object : MovingObject
  mut t : PhysicsObjectType
  mut flags : Int
  mut fh_id : Int
  mut fh_slope : Double
  mut fhlayer : Int
  mut groundbelow : Double
  mut on_ground : Bool
  mut enablejd : Bool
  /// 水平瞬时力
  mut hforce : Double
  /// 垂直瞬时力
  mut vforce : Double
  mut hacc : Double
  mut vacc : Double
}

///|
pub fn PhysicsObject::new(
  on_pos_change~ : (@selene_math.Vec2D) -> Unit,
) -> PhysicsObject {
  {
    moving_object: MovingObject::new(on_pos_change~),
    t: PhysicsObjectType::NORMAL,
    flags: 0,
    fh_id: 0,
    fh_slope: 0.0,
    fhlayer: 0,
    groundbelow: 0.0,
    on_ground: true,
    enablejd: false,
    hforce: 0.0,
    vforce: 0.0,
    hacc: 0.0,
    vacc: 0.0,
  }
}

///|
pub fn PhysicsObject::is_flag_set(
  self : PhysicsObject,
  f : PhysicsObjectFlag,
) -> Bool {
  (self.flags & f.int_value()) != 0
}

///|
pub fn PhysicsObject::is_flag_not_set(
  self : PhysicsObject,
  f : PhysicsObjectFlag,
) -> Bool {
  not(self.is_flag_set(f))
}

///|
pub fn PhysicsObject::set_flag(
  self : PhysicsObject,
  f : PhysicsObjectFlag,
) -> Unit {
  self.flags = self.flags | f.int_value()
}

///|
pub fn PhysicsObject::clear_flag(
  self : PhysicsObject,
  f : PhysicsObjectFlag,
) -> Unit {
  self.flags = self.flags & f.int_value().lnot()
}

///|
pub fn PhysicsObject::clear_flags(self : PhysicsObject) -> Unit {
  self.flags = 0
}

///|
pub fn PhysicsObject::do_move(self : PhysicsObject) -> Unit {
  self.moving_object.do_move()
}

///|
pub fn PhysicsObject::set_x(self : PhysicsObject, x : Double) -> Unit {
  self.moving_object.set_x(x)
}

///|
pub fn PhysicsObject::set_y(self : PhysicsObject, y : Double) -> Unit {
  self.moving_object.set_y(y)
}

///|
pub fn PhysicsObject::limitx(self : PhysicsObject, x : Double) -> Unit {
  self.moving_object.limitx(x)
}

///|
pub fn PhysicsObject::limity(self : PhysicsObject, y : Double) -> Unit {
  self.moving_object.limity(y)
}

///|
pub fn PhysicsObject::get_x(self : PhysicsObject) -> Int {
  self.moving_object.get_x()
}

///|
pub fn PhysicsObject::get_y(self : PhysicsObject) -> Int {
  self.moving_object.get_y()
}

///|
pub fn PhysicsObject::get_position(self : PhysicsObject) -> Point[Int] {
  self.moving_object.get_position()
}

///|
pub fn PhysicsObject::set_position(
  self : PhysicsObject,
  d : @selene_math.Vec2D,
) -> Unit {
  self.moving_object.set_position(d)
}

///|
pub fn PhysicsObject::get_absolute_x(
  self : PhysicsObject,
  viewx : Double,
  alpha : Double,
) -> Int {
  self.moving_object.get_absolute_x(viewx, alpha)
}

///|
pub fn PhysicsObject::get_absolute_y(
  self : PhysicsObject,
  viewy : Double,
  alpha : Double,
) -> Int {
  self.moving_object.get_absolute_y(viewy, alpha)
}

///|
pub fn PhysicsObject::get_absolute(
  self : PhysicsObject,
  viewx : Double,
  viewy : Double,
  alpha : Double,
) -> Point[Int] {
  self.moving_object.get_absolute(viewx, viewy, alpha)
}

///|
pub fn PhysicsObject::get_last_x(self : PhysicsObject) -> Int {
  self.moving_object.get_last_x()
}

///|
pub fn PhysicsObject::get_last_y(self : PhysicsObject) -> Int {
  self.moving_object.get_last_y()
}

///|
pub fn PhysicsObject::set_hspeed(self : PhysicsObject, hspeed : Double) -> Unit {
  self.moving_object.hspeed = hspeed
}

///|
pub fn PhysicsObject::set_vspeed(self : PhysicsObject, vspeed : Double) -> Unit {
  self.moving_object.vspeed = vspeed
}

///|
pub fn PhysicsObject::set_t(
  self : PhysicsObject,
  t : PhysicsObjectType,
) -> Unit {
  self.t = t
}

///|
pub fn PhysicsObject::set_fhid(self : PhysicsObject, fhid : Int) -> Unit {
  self.fh_id = fhid
}

///|
pub fn PhysicsObject::set_fhlayer(self : PhysicsObject, fhlayer : Int) -> Unit {
  self.fhlayer = fhlayer
}

///|
pub fn PhysicsObject::set_hforce(self : PhysicsObject, hforce : Double) -> Unit {
  self.hforce = hforce
}

///|
pub fn PhysicsObject::set_vforce(self : PhysicsObject, vforce : Double) -> Unit {
  self.vforce = vforce
}
