pub trait MapObject {
  get_oid(Self) -> Int
  draw(Self, Double, Double, Double) -> Unit
  update(Self, @physics.Physics) -> Int
  makeactive(Self) -> Unit
  // deactivate(Self) -> Unit
  is_active(Self) -> Bool
  get_layer(Self) -> Int
}

pub struct MapObjectBase {
  mut phobj : @physics.PhysicsObject
  mut oid : Int
  mut active : Bool
} derive(Default)

pub fn MapObjectBase::new(
  oid : Int,
  ~position : @struct.Point[Int] = { x: 0, y: 0 }
) -> MapObjectBase {
  let obj = { phobj: @physics.PhysicsObject::default(), oid, active: true }
  obj.set_position(position)
  obj
}

pub fn update(self : MapObjectBase, physics : @physics.Physics) -> Int {
  physics.move_object(self.phobj)
  self.phobj.fhlayer
}

pub fn set_positionxy(self : MapObjectBase, x : Int, y : Int) -> Unit {
  self.phobj.set_x(x.to_double())
  self.phobj.set_y(y.to_double())
}

pub fn set_position(
  self : MapObjectBase,
  position : @struct.Point[Int]
) -> Unit {
  self.set_positionxy(position.x, position.y)
}

pub fn makeactive(self : MapObjectBase) -> Unit {
  self.active = true
}

pub fn deactivate(self : MapObjectBase) -> Unit {
  self.active = false
}

pub fn is_active(self : MapObjectBase) -> Bool {
  self.active
}

pub fn get_layer(self : MapObjectBase) -> Int {
  self.phobj.fhlayer
}

pub fn get_oid(self : MapObjectBase) -> Int {
  self.oid
}

pub fn get_position(self : MapObjectBase) -> @struct.Point[Int] {
  self.phobj.get_position()
}
