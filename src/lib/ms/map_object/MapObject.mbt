///|
pub(open) trait MapObject {
  get_oid(Self) -> Int
  draw(Self, Double, Double, Double) -> Unit
  update(Self, @physics.Physics) -> Int
  makeactive(Self) -> Unit
  // deactivate(Self) -> Unit
  is_active(Self) -> Bool
  get_layer(Self) -> Int
  get_position(Self) -> @struct.Point[Int]
}

///|
pub struct MapObjectBase {
  phobj : @physics.PhysicsObject
  oid : Int
  mut active : Bool
}

///|
pub fn MapObjectBase::new(
  oid : Int,
  position? : @struct.Point[Int] = { x: 0, y: 0 },
  on_pos_change~ : (@selene_math.Vec2D) -> Unit,
) -> MapObjectBase {
  let obj = {
    phobj: @physics.PhysicsObject::new(on_pos_change~),
    oid,
    active: true,
  }
  obj.set_position(position)
  obj
}

///|
pub fn MapObjectBase::update(
  self : MapObjectBase,
  physics : @physics.Physics,
) -> Int {
  physics.move_object(self.phobj)
  self.phobj.fhlayer
}

///|
pub fn MapObjectBase::set_positionxy(
  self : MapObjectBase,
  x : Int,
  y : Int,
) -> Unit {
  self.phobj.set_position(@selene_math.Vec2D(x.to_double(), y.to_double()))
}

///|
pub fn MapObjectBase::set_position(
  self : MapObjectBase,
  position : @struct.Point[Int],
) -> Unit {
  self.set_positionxy(position.x, position.y)
}

///|
pub fn MapObjectBase::makeactive(self : MapObjectBase) -> Unit {
  self.active = true
}

///|
pub fn MapObjectBase::deactivate(self : MapObjectBase) -> Unit {
  self.active = false
}

///|
pub fn MapObjectBase::is_active(self : MapObjectBase) -> Bool {
  self.active
}

///|
pub fn MapObjectBase::get_layer(self : MapObjectBase) -> Int {
  self.phobj.fhlayer
}

///|
pub fn MapObjectBase::get_oid(self : MapObjectBase) -> Int {
  self.oid
}

///|
pub fn MapObjectBase::get_position(self : MapObjectBase) -> @struct.Point[Int] {
  self.phobj.get_position()
}
