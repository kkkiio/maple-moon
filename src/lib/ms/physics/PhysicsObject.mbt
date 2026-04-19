///|
using @struct {type Point}

///|
/// Mutable kinematic state used by physics integration.
pub struct MovingObject {
  x : @utils.Linear
  y : @utils.Linear
  mut hspeed : Double
  mut vspeed : Double
  mut on_pos_change : (@selene_math.Vec2D) -> Unit
}

///|
/// Create a moving object with zeroed position/speed.
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
/// Normalize interpolation state of both axes.
pub fn MovingObject::normalize(self : MovingObject) -> Unit {
  self.x.normalize()
  self.y.normalize()
}

///|
/// Apply current speed to position for one tick.
pub fn MovingObject::do_move(self : MovingObject) -> Unit {
  let x = self.x.get() + self.hspeed
  let y = self.y.get() + self.vspeed
  self.x.set(x)
  self.y.set(y)
  (self.on_pos_change)(@selene_math.Vec2D(x, y))
}

///|
/// Set x immediately and notify position callback.
pub fn MovingObject::set_x(self : MovingObject, d : Double) -> Unit {
  self.x.set(d)
  (self.on_pos_change)(@selene_math.Vec2D(d, self.y.get()))
}

///|
/// Set y immediately and notify position callback.
pub fn MovingObject::set_y(self : MovingObject, d : Double) -> Unit {
  self.y.set(d)
  (self.on_pos_change)(@selene_math.Vec2D(self.x.get(), d))
}

///|
/// Set full position immediately and notify callback.
pub fn MovingObject::set_position(
  self : MovingObject,
  d : @selene_math.Vec2D,
) -> Unit {
  self.x.set(d.0)
  self.y.set(d.1)
  (self.on_pos_change)(d)
}

///|
/// Clamp x and clear horizontal speed.
pub fn MovingObject::limitx(self : MovingObject, d : Double) -> Unit {
  self.x.set(d)
  self.hspeed = 0.0
  (self.on_pos_change)(@selene_math.Vec2D(d, self.y.get()))
}

///|
/// Clamp y and clear vertical speed.
pub fn MovingObject::limity(self : MovingObject, d : Double) -> Unit {
  self.y.set(d)
  self.vspeed = 0.0
  (self.on_pos_change)(@selene_math.Vec2D(self.x.get(), d))
}

///|
/// Set horizontal speed so object reaches target x after `delay`.
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
/// Set vertical speed so object reaches target y after `delay`.
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
/// Whether horizontal speed is non-zero.
pub fn MovingObject::hmobile(self : MovingObject) -> Bool {
  self.hspeed != 0.0
}

///|
/// Whether vertical speed is non-zero.
pub fn MovingObject::vmobile(self : MovingObject) -> Bool {
  self.vspeed != 0.0
}

///|
/// Whether either axis is moving.
pub fn MovingObject::mobile(self : MovingObject) -> Bool {
  self.hmobile() || self.vmobile()
}

///|
/// Current x in double precision.
pub fn MovingObject::crnt_x(self : MovingObject) -> Double {
  self.x.get()
}

///|
/// Current y in double precision.
pub fn MovingObject::crnt_y(self : MovingObject) -> Double {
  self.y.get()
}

///|
/// Predicted next x using current horizontal speed.
pub fn MovingObject::next_x(self : MovingObject) -> Double {
  self.x.plus(self.hspeed)
}

///|
/// Predicted next y using current vertical speed.
pub fn MovingObject::next_y(self : MovingObject) -> Double {
  self.y.plus(self.vspeed)
}

///|
/// Current x rounded to integer.
pub fn MovingObject::get_x(self : MovingObject) -> Int {
  self.x.get().round().to_int()
}

///|
/// Current y rounded to integer.
pub fn MovingObject::get_y(self : MovingObject) -> Int {
  self.y.get().round().to_int()
}

///|
/// Previous tick x rounded to integer.
pub fn MovingObject::get_last_x(self : MovingObject) -> Int {
  self.x.last().round().to_int()
}

///|
/// Previous tick y rounded to integer.
pub fn MovingObject::get_last_y(self : MovingObject) -> Int {
  self.y.last().round().to_int()
}

///|
/// Current position rounded to integer point.
pub fn MovingObject::get_position(self : MovingObject) -> Point[Int] {
  { x: self.get_x(), y: self.get_y() }
}

///|
/// Interpolated absolute x in screen space.
pub fn MovingObject::get_absolute_x(
  self : MovingObject,
  viewx : Double,
  alpha : Double,
) -> Int {
  get_absolute_coord(self.x, viewx, alpha)
}

///|
/// Interpolated absolute y in screen space.
pub fn MovingObject::get_absolute_y(
  self : MovingObject,
  viewy : Double,
  alpha : Double,
) -> Int {
  get_absolute_coord(self.y, viewy, alpha)
}

///|
/// Convert linear coordinate to absolute screen coordinate.
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
/// Interpolated absolute position in screen space.
pub fn MovingObject::get_absolute(
  self : MovingObject,
  viewx : Double,
  viewy : Double,
  alpha : Double,
) -> Point[Int] {
  { x: self.get_absolute_x(viewx, alpha), y: self.get_absolute_y(viewy, alpha) }
}

///|
/// Set vertical speed directly.
pub fn MovingObject::set_vspeed(self : MovingObject, vspeed : Double) -> Unit {
  self.vspeed = vspeed
}

///|
/// Set horizontal speed directly.
pub fn MovingObject::set_hspeed(self : MovingObject, hspeed : Double) -> Unit {
  self.hspeed = hspeed
}

///|
/// Replace position-change callback.
pub fn MovingObject::set_on_pos_change(
  self : MovingObject,
  on_pos_change : (@selene_math.Vec2D) -> Unit,
) -> Unit {
  self.on_pos_change = on_pos_change
}

///|
/// High-level movement mode for a physics object.
pub(all) enum PhysicsObjectType {
  /// Ground physics with gravity and foothold friction.
  NORMAL
  /// Reserved: icy movement behavior.
  ICE
  /// Water-like movement mode.
  SWIMMING
  /// Free-flying movement mode.
  FLYING
  /// Fixed foothold attachment without auto update.
  FIXATED
} derive(Eq, Compare, Debug, ToJson)

///|
/// Bit flags controlling optional physics behaviors.
pub(all) enum PhysicsObjectFlag {
  /// Disable gravity integration.
  NO_GRAVITY = 0x0001
  /// Turn around when reaching edge instead of falling.
  TURN_AT_EDGES = 0x0002
  /// Re-check foothold below for jump-down support.
  CHECK_BELOW = 0x0004
} derive(Eq, Compare, Debug, ToJson)

///|
/// Return underlying bit value of flag.
pub fn PhysicsObjectFlag::int_value(self : PhysicsObjectFlag) -> Int = "%identity"

///|
/// Physical state bound to one gameplay object/entity.
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
/// Create a physics object with default NORMAL state.
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
/// Check whether flag is set.
pub fn PhysicsObject::is_flag_set(
  self : PhysicsObject,
  f : PhysicsObjectFlag,
) -> Bool {
  (self.flags & f.int_value()) != 0
}

///|
/// Check whether flag is not set.
pub fn PhysicsObject::is_flag_not_set(
  self : PhysicsObject,
  f : PhysicsObjectFlag,
) -> Bool {
  !self.is_flag_set(f)
}

///|
/// Enable one flag bit.
pub fn PhysicsObject::set_flag(
  self : PhysicsObject,
  f : PhysicsObjectFlag,
) -> Unit {
  self.flags = self.flags | f.int_value()
}

///|
/// Clear one flag bit.
pub fn PhysicsObject::clear_flag(
  self : PhysicsObject,
  f : PhysicsObjectFlag,
) -> Unit {
  self.flags = self.flags & f.int_value().lnot()
}

///|
/// Clear all flag bits.
pub fn PhysicsObject::clear_flags(self : PhysicsObject) -> Unit {
  self.flags = 0
}

///|
/// Move using wrapped moving object integration.
pub fn PhysicsObject::do_move(self : PhysicsObject) -> Unit {
  self.moving_object.do_move()
}

///|
/// Set x immediately.
pub fn PhysicsObject::set_x(self : PhysicsObject, x : Double) -> Unit {
  self.moving_object.set_x(x)
}

///|
/// Set y immediately.
pub fn PhysicsObject::set_y(self : PhysicsObject, y : Double) -> Unit {
  self.moving_object.set_y(y)
}

///|
/// Clamp x and stop horizontal speed.
pub fn PhysicsObject::limitx(self : PhysicsObject, x : Double) -> Unit {
  self.moving_object.limitx(x)
}

///|
/// Clamp y and stop vertical speed.
pub fn PhysicsObject::limity(self : PhysicsObject, y : Double) -> Unit {
  self.moving_object.limity(y)
}

///|
/// Current x rounded to integer.
pub fn PhysicsObject::get_x(self : PhysicsObject) -> Int {
  self.moving_object.get_x()
}

///|
/// Current y rounded to integer.
pub fn PhysicsObject::get_y(self : PhysicsObject) -> Int {
  self.moving_object.get_y()
}

///|
/// Current position rounded to integer point.
pub fn PhysicsObject::get_position(self : PhysicsObject) -> Point[Int] {
  self.moving_object.get_position()
}

///|
/// Return whether the object is currently attached to ground.
pub fn PhysicsObject::is_on_ground(self : PhysicsObject) -> Bool {
  self.on_ground
}

///|
/// Return the current horizontal speed.
pub fn PhysicsObject::get_hspeed(self : PhysicsObject) -> Double {
  self.moving_object.hspeed
}

///|
/// Return the current vertical speed.
pub fn PhysicsObject::get_vspeed(self : PhysicsObject) -> Double {
  self.moving_object.vspeed
}

///|
/// Set full position immediately.
pub fn PhysicsObject::set_position(
  self : PhysicsObject,
  d : @selene_math.Vec2D,
) -> Unit {
  self.moving_object.set_position(d)
}

///|
/// Interpolated absolute x in screen space.
pub fn PhysicsObject::get_absolute_x(
  self : PhysicsObject,
  viewx : Double,
  alpha : Double,
) -> Int {
  self.moving_object.get_absolute_x(viewx, alpha)
}

///|
/// Interpolated absolute y in screen space.
pub fn PhysicsObject::get_absolute_y(
  self : PhysicsObject,
  viewy : Double,
  alpha : Double,
) -> Int {
  self.moving_object.get_absolute_y(viewy, alpha)
}

///|
/// Interpolated absolute position in screen space.
pub fn PhysicsObject::get_absolute(
  self : PhysicsObject,
  viewx : Double,
  viewy : Double,
  alpha : Double,
) -> Point[Int] {
  self.moving_object.get_absolute(viewx, viewy, alpha)
}

///|
/// Previous tick x rounded to integer.
pub fn PhysicsObject::get_last_x(self : PhysicsObject) -> Int {
  self.moving_object.get_last_x()
}

///|
/// Previous tick y rounded to integer.
pub fn PhysicsObject::get_last_y(self : PhysicsObject) -> Int {
  self.moving_object.get_last_y()
}

///|
/// Set horizontal speed directly.
pub fn PhysicsObject::set_hspeed(self : PhysicsObject, hspeed : Double) -> Unit {
  self.moving_object.hspeed = hspeed
}

///|
/// Set vertical speed directly.
pub fn PhysicsObject::set_vspeed(self : PhysicsObject, vspeed : Double) -> Unit {
  self.moving_object.vspeed = vspeed
}

///|
/// Set high-level movement mode.
pub fn PhysicsObject::set_t(
  self : PhysicsObject,
  t : PhysicsObjectType,
) -> Unit {
  self.t = t
}

///|
/// Set current foothold id manually.
pub fn PhysicsObject::set_fhid(self : PhysicsObject, fhid : Int) -> Unit {
  self.fh_id = fhid
}

///|
/// Set current foothold layer manually.
pub fn PhysicsObject::set_fhlayer(self : PhysicsObject, fhlayer : Int) -> Unit {
  self.fhlayer = fhlayer
}

///|
/// Add horizontal force for next integration step.
pub fn PhysicsObject::set_hforce(self : PhysicsObject, hforce : Double) -> Unit {
  self.hforce = hforce
}

///|
/// Add vertical force for next integration step.
pub fn PhysicsObject::set_vforce(self : PhysicsObject, vforce : Double) -> Unit {
  self.vforce = vforce
}
