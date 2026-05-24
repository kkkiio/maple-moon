///|
pub(open) trait MapObject {
  fn get_oid(Self) -> Int
  fn update(Self, @physics.Physics) -> Int
  fn destroy(Self) -> Unit
  fn get_layer(Self) -> Int
  fn get_position(Self) -> @struct.Point[Int]
}

///|
pub struct MapObjectBase {
  phobj : @physics.PhysicsObject
  oid : Int
}

///|
pub fn MapObjectBase::new(
  oid : Int,
  position? : @struct.Point[Int] = { x: 0, y: 0 },
  on_pos_change~ : (@selene_math.Vec2) -> Unit,
) -> MapObjectBase {
  let obj = { phobj: @physics.PhysicsObject::new(on_pos_change~), oid }
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
  self.phobj.set_position(@selene_math.Vec2(x.to_double(), y.to_double()))
}

///|
pub fn MapObjectBase::set_position(
  self : MapObjectBase,
  position : @struct.Point[Int],
) -> Unit {
  self.set_positionxy(position.x, position.y)
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
