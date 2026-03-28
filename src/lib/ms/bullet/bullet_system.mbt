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
let current_bullet_system_ref : Ref[BulletSystem?] = Ref::new(None)

///|

///|
/// Create an empty bullet runtime state.
pub fn BulletSystem::new() -> BulletSystem {
  { pending: @utils.TimedQueue::new(), active: [] }
}

///|
/// Queue a bullet spawn request.
///
/// The bullet will be instantiated after `delay` milliseconds.
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
/// Advance bullet simulation by one fixed logic timestep.
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
/// Clear all active and pending bullets in this runtime state.
pub fn BulletSystem::clear(self : BulletSystem) -> Unit {
  for active_bullet in self.active {
    clear_entity(active_bullet.entity)
  }
  self.active.clear()
  self.pending = @utils.TimedQueue::new()
}

///|
/// Register the current scene's bullet runtime state.
pub fn set_current_bullet_system(system : BulletSystem?) -> Unit {
  current_bullet_system_ref.val = system
}

///|
/// Spawn a bullet through the current scene-level bullet runtime.
///
/// Panics if the runtime has not been initialized.
pub fn spawn_bullet(
  delay : Int64,
  animation : @resource.NxAnimation,
  origin : @struct.Point[Int],
  toleft : Bool,
  target : @struct.Point[Int],
  on_hit : () -> Unit,
  update_target : (@struct.Point[Int]) -> @struct.Point[Int],
) -> Unit {
  guard current_bullet_system_ref.val is Some(system) else {
    @log.fatal("bullet system is not initialized")
  }
  system.spawn(delay, animation, origin, toleft, target, on_hit, update_target)
}

///|
/// Clear and unregister the current scene-level bullet runtime state.
pub fn clear_current_bullet_system() -> Unit {
  match current_bullet_system_ref.val {
    Some(system) => system.clear()
    None => ()
  }
  current_bullet_system_ref.val = None
}

///|
/// Get the current scene-level bullet runtime state.
pub fn get_current_bullet_system() -> BulletSystem? {
  current_bullet_system_ref.val
}

///|
pub fn clear_for_change_map() -> Unit {
  clear_current_bullet_system()
}

///|
pub fn clear_for_leave_world() -> Unit {
  clear_current_bullet_system()
}

///|
/// Selene system entry for bullet simulation.
///
/// This runs only during `GameActive` and advances by fixed logic steps.
// TODO: Split non-fixed-step logic out of this FixedUpdate system into a separate Update system function.
pub fn bullet_system(_world : @ecs.World) -> Unit {
  guard @game_state.current_phase() is GameActive(..) else { return }
  guard @monster.get_map_mobs() is Some(_) else { return }
  guard current_bullet_system_ref.val is Some(system) else { return }
  system.update(timestep=@logic_fps.STEP_TIME_MS.to_int64())
}

///|
fn clear_entity(entity : @entity.Entity) -> Unit {
  @sprite.sprites().remove(entity)
  @transform2d.remove(entity)
  if entity.is_alive() {
    entity.destroy()
  }
}
