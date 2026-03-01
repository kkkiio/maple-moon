///|
priv struct BulletSpawn {
  animation : @resource.NxAnimation
  origin : @struct.Point[Int]
  toleft : Bool
  target : @struct.Point[Int]
  on_hit : () -> Unit
  update_target : (@struct.Point[Int]) -> @struct.Point[Int]
}

///|
priv struct ActiveBullet {
  entity : @entity.Entity
  bullet : @combat_proto.Bullet
  mut target : @struct.Point[Int]
  on_hit : () -> Unit
  update_target : (@struct.Point[Int]) -> @struct.Point[Int]
}

///|
struct BulletSystem {
  mut pending : @utils.TimedQueue[BulletSpawn]
  active : Array[ActiveBullet]
}

///|
pub fn BulletSystem::new() -> BulletSystem {
  { pending: @utils.TimedQueue::new(), active: [] }
}

///|
pub fn BulletSystem::spawn(
  self : BulletSystem,
  delay : Int64,
  animation : @resource.NxAnimation,
  origin : @struct.Point[Int],
  toleft : Bool,
  target : @struct.Point[Int],
  on_hit : () -> Unit,
  update_target : (@struct.Point[Int]) -> @struct.Point[Int],
) -> Unit {
  self.pending.push(delay, {
    animation,
    origin,
    toleft,
    target,
    on_hit,
    update_target,
  })
}

///|
pub fn BulletSystem::update(self : BulletSystem, timestep~ : Int64) -> Unit {
  for spawn in self.pending.process(timestep~) {
    let entity = @entity.Entity::new()
    let bullet = @combat_proto.Bullet::new(
      entity,
      spawn.animation,
      spawn.origin,
      spawn.toleft,
    )
    let active_bullet : ActiveBullet = {
      entity,
      bullet,
      target: spawn.target,
      on_hit: spawn.on_hit,
      update_target: spawn.update_target,
    }
    active_bullet.target = (active_bullet.update_target)(active_bullet.target)
    if active_bullet.bullet.set_target(active_bullet.target) {
      (active_bullet.on_hit)()
      clear_entity(active_bullet.entity)
    } else {
      self.active.push(active_bullet)
    }
  }
  self.active.retain(fn(active_bullet) {
    active_bullet.target = (active_bullet.update_target)(active_bullet.target)
    let hit = active_bullet.bullet.update(active_bullet.target)
    if hit {
      (active_bullet.on_hit)()
      clear_entity(active_bullet.entity)
    }
    not(hit)
  })
}

///|
pub fn BulletSystem::clear(self : BulletSystem) -> Unit {
  for active_bullet in self.active {
    clear_entity(active_bullet.entity)
  }
  self.active.clear()
  self.pending = @utils.TimedQueue::new()
}

///|
fn clear_entity(entity : @entity.Entity) -> Unit {
  @sprite.sprites.remove(entity)
  @position.positions.remove(entity)
  if entity.is_alive() {
    entity.destroy()
  }
}
