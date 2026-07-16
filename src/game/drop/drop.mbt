///|
trait Drop {
  fn get_oid(Self) -> Int
  fn update(Self, @physics.Physics) -> Int
  fn destroy(Self) -> Unit
  fn get_position(Self) -> @struct.Point[Int]
  fn get_bounds(Self) -> @struct.Rectangle[Int]
  fn expire(Self, Int, @physics.PhysicsObject?) -> Unit
}

///|
priv struct DropBase {
  entity : @entity.Entity
  oid : Int
  phobj : @physics.PhysicsObject
  opacity : @utils.Linear
  angle : @utils.Linear
  mut looter : @physics.PhysicsObject?
  mut state : DropState
  dest : @struct.Point[Int]
  base_y : Double
  mut moved : Double
}

///|
priv enum DropState {
  DROPPED
  FLOATING
  PICKED_UP
} derive(Eq)

///|
fn DropBase::DropBase(
  id : Int,
  _owner : Int,
  start : @struct.Point[Int],
  dest : @struct.Point[Int],
  _pickup_type : Int,
  mode : Int,
  _player_drop : Bool,
) -> DropBase {
  let entity = @entity.Entity()
  let phobj = PhysicsObject(on_pos_change=fn(pos) {
    @transform2d.set_xy(entity, pos)
  })
  phobj.set_position(
    @selene_math.Vec2(start.x.to_double(), (start.y - 4).to_double()),
  )
  let (state, base_y) = match mode {
    0 | 1 => {
      phobj.set_vspeed(-5.0)
      phobj.set_hspeed((dest.x - start.x).to_double() / 48)
      (DropState::DROPPED, (dest.y - 4).to_double())
    }
    2 => {
      phobj.set_t(@physics.PhysicsObjectType::FIXATED)
      (DropState::FLOATING, phobj.moving_object.crnt_y())
    }
    3 => (DropState::PICKED_UP, -5.0)
    _ => abort("Invalid drop mode: \{mode}")
  }
  {
    entity,
    oid: id,
    phobj,
    angle: Linear(0.0),
    opacity: Linear(1.0),
    looter: None,
    state,
    dest,
    base_y,
    moved: 0.0,
  }
}

///|
fn DropBase::update(self : DropBase, physics : @physics.Physics) -> Int {
  physics.move_object(self.phobj)
  if self.state == DropState::DROPPED {
    if self.phobj.on_ground {
      self.phobj.set_hspeed(0.0)
      self.phobj.set_t(@physics.PhysicsObjectType::FIXATED)
      self.state = DropState::FLOATING
      self.angle.set(0.0)
      self.phobj.set_position(
        @selene_math.Vec2(
          self.dest.x.to_double(),
          (self.dest.y - 4).to_double(),
        ),
      )
    } else {
      let spinstep = 0.2
      self.angle.add(spinstep)
    }
  }
  if self.state == DropState::FLOATING {
    self.phobj.moving_object.y.set(
      self.base_y + 5.0 + (@math.cos(self.moved) - 1.0) * 2.5,
    )
    self.moved = if self.moved < 360.0 { self.moved + 0.025 } else { 0.0 }
  }
  if self.state == DropState::PICKED_UP {
    let pickuptime = 48.0
    let opcstep = 1.0 / pickuptime
    match self.looter {
      Some(looter) => {
        let hdelta = looter.moving_object.x.get() -
          self.phobj.moving_object.x.get()
        self.phobj.set_hspeed(
          looter.moving_object.hspeed / 2.0 + (hdelta - 16.0) / pickuptime,
        )
      }
      None => ()
    }
    self.opacity.add(-opcstep)
    if self.opacity.last() <= opcstep {
      self.opacity.set(1.0)
      self.entity.destroy()
      return -1
    }
  }
  self.phobj.fhlayer
}

///|
fn DropBase::bounds(self : DropBase) -> @struct.Rectangle[Int] {
  let lt = self.phobj.get_position()
  let rb = lt + Point(32, 32)
  Rectangle(lt, rb)
}

///|
fn DropBase::expire(
  self : DropBase,
  t : Int,
  lt : @physics.PhysicsObject?,
) -> Unit {
  match t {
    0 => self.state = DropState::PICKED_UP
    1 => self.entity.destroy()
    2 => {
      self.angle.set(0.0)
      self.state = DropState::PICKED_UP
      self.looter = lt
      self.phobj.set_vspeed(-4.5)
      self.phobj.set_t(@physics.PhysicsObjectType::NORMAL)
    }
    _ => abort("Invalid drop type: \{t}")
  }
}

///|
struct MesoDrop {
  base : DropBase
  icon : @ms_animation.Animation
}

///|
pub fn MesoDrop::MesoDrop(
  oid : Int,
  owner : Int,
  start : @struct.Point[Int],
  dest : @struct.Point[Int],
  t : Int,
  mode : Int,
  player_drop : Bool,
  icon : @res.NxAnimation,
) -> MesoDrop {
  let base = DropBase(oid, owner, start, dest, t, mode, player_drop)
  let selene_anim = @ms_animation.from_nx_animation(icon, loop_=true)
  { base, icon: selene_anim }
}

///|
// pub impl Drop for MesoDrop with draw(
//   self : MesoDrop,
//   viewx : Double,
//   viewy : Double,
//   alpha : Double,
// ) -> Unit {
//   if !(self.base.entity.is_alive()) {
//     return
//   }
//   let absp = self.base.phobj.get_absolute(viewx, viewy, alpha)
//   self.icon.draw(
//     @graphics.DrawArgument::new(
//       pos=absp,
//       angle=self.base.angle.get(alpha~),
//       opacity=self.base.opacity.get(alpha~),
//     ),
//     alpha,
//   )
// }

///|
pub impl Drop for MesoDrop with fn get_oid(self : MesoDrop) -> Int {
  self.base.oid
}

///|
pub impl Drop for MesoDrop with fn update(
  self : MesoDrop,
  physics : @physics.Physics,
) -> Int {
  let layer = self.base.update(physics)
  let entity = self.base.entity
  let y = self.base.phobj.get_position().y
  let z = @graphics.map_drop_z(layer, y)
  let angle = self.base.angle.get()
  let opacity = self.base.opacity.get()
  // Check if sprite already exists
  match @sprite.sprites().get(entity) {
    Some(sprite) => {
      // Update existing sprite: alpha and transform
      sprite.color = @sprite.color_from_css("rgba(255, 255, 255, \{opacity})")
      @ms_animation.set_animation_transform(
        entity,
        @selene_math.Transform::from_rotation_rad(angle),
      )
    }
    None => {
      // Create new sprite with initial transform
      let sprite = @ms_animation.sprite_from_animation(
        self.icon,
        z,
        alpha=opacity,
        transform=@selene_math.Transform::from_rotation_rad(angle),
      )
      @sprite.sprites().set(entity, sprite)
    }
  }
  layer
}

///|
pub impl Drop for MesoDrop with fn destroy(self : MesoDrop) -> Unit {
  @sprite.sprites().remove(self.base.entity)
  self.base.entity.destroy()
}

///|
pub impl Drop for MesoDrop with fn get_position(self : MesoDrop) -> @struct.Point[
  Int,
] {
  self.base.phobj.get_position()
}

///|
pub impl Drop for MesoDrop with fn get_bounds(self : MesoDrop) -> @struct.Rectangle[
  Int,
] {
  self.base.bounds()
}

///|
pub impl Drop for MesoDrop with fn expire(
  self : MesoDrop,
  t : Int,
  lt : @physics.PhysicsObject?,
) -> Unit {
  self.base.expire(t, lt)
}

///|
struct ItemDrop {
  base : DropBase
  icon : @ms_animation.Picture
}

///|
pub fn ItemDrop::ItemDrop(
  oid : Int,
  owner : Int,
  start : @struct.Point[Int],
  dest : @struct.Point[Int],
  t : Int,
  mode : Int,
  _iid : Int,
  player_drop : Bool,
  icon : @res.NxTexture,
) -> ItemDrop {
  let base = DropBase(oid, owner, start, dest, t, mode, player_drop)
  let selene_picture = @ms_animation.from_nx_texture(icon)
  { base, icon: selene_picture }
}

///|
// pub impl Drop for ItemDrop with draw(
//   self : ItemDrop,
//   viewx : Double,
//   viewy : Double,
//   alpha : Double,
// ) -> Unit {
//   if !(self.base.entity.is_alive()) {
//     return
//   }
//   let absp = self.base.phobj.get_absolute(viewx, viewy, alpha)
//   // self.icon.draw(
//   //   @graphics.DrawArgument::new(
//   //     pos=absp,
//   //     angle=self.base.angle.get(alpha~),
//   //     opacity=self.base.opacity.get(alpha~),
//   //   ),
//   // )
//   ...
// }

///|
pub impl Drop for ItemDrop with fn get_oid(self : ItemDrop) -> Int {
  self.base.oid
}

///|
pub impl Drop for ItemDrop with fn update(
  self : ItemDrop,
  physics : @physics.Physics,
) -> Int {
  let layer = self.base.update(physics)
  let entity = self.base.entity
  let y = self.base.phobj.get_position().y
  let z = @graphics.map_drop_z(layer, y)
  let opacity = self.base.opacity.get()
  // For ItemDrop, we use Picture which doesn't support rotation transform
  // We only update alpha for PICKED_UP fade effect
  match @sprite.sprites().get(entity) {
    Some(sprite) =>
      // Update existing sprite: alpha only
      sprite.color = @sprite.color_from_css("rgba(255, 255, 255, \{opacity})")
    None => {
      // Create new sprite with initial alpha
      let sprite = @ms_animation.sprite_from_picture(
        self.icon,
        z,
        alpha=opacity,
      )
      @sprite.sprites().set(entity, sprite)
    }
  }
  layer
}

///|

///|
pub impl Drop for ItemDrop with fn destroy(self : ItemDrop) -> Unit {
  @sprite.sprites().remove(self.base.entity)
  self.base.entity.destroy()
}

///|
pub impl Drop for ItemDrop with fn get_position(self : ItemDrop) -> @struct.Point[
  Int,
] {
  self.base.phobj.get_position()
}

///|
pub impl Drop for ItemDrop with fn get_bounds(self : ItemDrop) -> @struct.Rectangle[
  Int,
] {
  self.base.bounds()
}

///|
pub impl Drop for ItemDrop with fn expire(
  self : ItemDrop,
  t : Int,
  lt : @physics.PhysicsObject?,
) -> Unit {
  self.base.expire(t, lt)
}

///|
using @physics {type PhysicsObject}
