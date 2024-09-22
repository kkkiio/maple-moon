struct DropBase {
  base : @map_object.MapObjectBase
  opacity : @utils.Linear
  angle : @utils.Linear
  owner : Int
  pickup_type : Int
  player_drop : Bool
  looter : @physics.PhysicsObject?
  mut state : DropState
  dest : @struct.Point[Int]
  base_y : Double
  mut moved : Double
}

enum DropState {
  DROPPED
  FLOATING
  PICKED_UP
} derive(Eq)

fn DropBase::new(
  id : Int,
  owner : Int,
  start : @struct.Point[Int],
  dest : @struct.Point[Int],
  pickup_type : Int,
  mode : Int,
  player_drop : Bool
) -> DropBase {
  let base = @map_object.MapObjectBase::new(id)
  base.set_position(@struct.Point::new(start.x, start.y - 4))
  let (state, base_y) = match mode {
    0 | 1 => {
      base.phobj.moving_object.vspeed = -5.0
      base.phobj.moving_object.hspeed = (dest.x - start.x).to_double() / 48
      (DropState::DROPPED, (dest.y - 4).to_double())
    }
    2 => {
      base.phobj.t = @physics.PhysicsObjectType::FIXATED
      (DropState::FLOATING, base.phobj.moving_object.crnt_y())
    }
    3 => (DropState::PICKED_UP, -5.0)
    _ => abort("Invalid drop mode: \{mode}")
  }
  {
    base,
    angle: @utils.Linear::new(0.0),
    opacity: @utils.Linear::new(1.0),
    owner,
    pickup_type,
    player_drop,
    looter: None,
    state,
    dest,
    base_y,
    moved: 0.0,
  }
}

fn DropBase::update(self : DropBase, physics : @physics.Physics) -> Int {
  physics.move_object(self.base.phobj)
  if self.state == DropState::DROPPED {
    if self.base.phobj.onground {
      self.base.phobj.moving_object.hspeed = 0.0
      self.base.phobj.t = @physics.PhysicsObjectType::FIXATED
      self.state = DropState::FLOATING
      self.angle.set(0.0)
      self.base.set_positionxy(self.dest.x, self.dest.y - 4)
    } else {
      let spinstep = 0.2
      self.angle.add(spinstep)
    }
  }
  if self.state == DropState::FLOATING {
    self.base.phobj.moving_object.y.set(
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
          self.base.phobj.moving_object.x.get()
        self.base.phobj.moving_object.hspeed = looter.moving_object.hspeed / 2.0 +
          (hdelta - 16.0) / pickuptime
      }
      None => ()
    }
    self.opacity.add(-opcstep)
    if self.opacity.last() <= opcstep {
      self.opacity.set(1.0)
      self.base.deactivate()
      return -1
    }
  }
  self.base.phobj.fhlayer
}

struct MesoDrop {
  base : DropBase
  icon : @graphics.Animation
}

pub fn MesoDrop::new(
  oid : Int,
  owner : Int,
  start : @struct.Point[Int],
  dest : @struct.Point[Int],
  t : Int,
  mode : Int,
  player_drop : Bool,
  icon : @graphics.Animation
) -> MesoDrop {
  let base = DropBase::new(oid, owner, start, dest, t, mode, player_drop)
  { base, icon }
}

pub fn MesoDrop::draw(
  self : MesoDrop,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  if self.base.base.active.not() {
    return
  }
  let absp = self.base.base.phobj.get_absolute(viewx, viewy, alpha)
  self.icon.draw(
    @graphics.DrawArgument::new(
      absp,
      angle=self.base.angle.get(~alpha),
      opacity=self.base.opacity.get(~alpha),
    ),
    alpha,
  )
}

pub fn get_oid(self : MesoDrop) -> Int {
  self.base.base.oid
}

pub fn update(self : MesoDrop, physics : @physics.Physics) -> Int {
  self.base.update(physics)
}

pub fn is_active(self : MesoDrop) -> Bool {
  self.base.base.active
}

pub fn makeactive(self : MesoDrop) -> Unit {
  self.base.base.makeactive()
}

pub fn get_layer(self : MesoDrop) -> Int {
  self.base.base.get_layer()
}

struct ItemDrop {
  base : DropBase
  icon : @graphics.Texture
}

pub fn ItemDrop::new(
  oid : Int,
  owner : Int,
  start : @struct.Point[Int],
  dest : @struct.Point[Int],
  t : Int,
  mode : Int,
  iid : Int,
  player_drop : Bool,
  icon : @graphics.Texture
) -> ItemDrop {
  let base = DropBase::new(oid, owner, start, dest, t, mode, player_drop)
  { base, icon }
}

pub fn ItemDrop::draw(
  self : ItemDrop,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  if self.base.base.active.not() {
    return
  }
  let absp = self.base.base.phobj.get_absolute(viewx, viewy, alpha)
  self.icon.draw(
    @graphics.DrawArgument::new(
      absp,
      angle=self.base.angle.get(~alpha),
      opacity=self.base.opacity.get(~alpha),
    ),
  )
}

pub fn get_oid(self : ItemDrop) -> Int {
  self.base.base.oid
}

pub fn update(self : ItemDrop, physics : @physics.Physics) -> Int {
  self.base.update(physics)
}

pub fn is_active(self : ItemDrop) -> Bool {
  self.base.base.active
}

pub fn makeactive(self : ItemDrop) -> Unit {
  self.base.base.makeactive()
}

pub fn get_layer(self : ItemDrop) -> Int {
  self.base.base.get_layer()
}
