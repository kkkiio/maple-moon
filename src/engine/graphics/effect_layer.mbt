// This acts as a manual component system for "LifeTime".

///|
let active_effects : Array[EffectEntity] = []

///|
priv struct EffectEntity {
  entity : @entity.Entity
  mut ttl : Double
}

///|
pub(all) struct EffectAnimation {
  animation : @ms_animation.Animation
  duration_ms : Int
}

///|
pub fn effect_layer_system(_world : @ecs.World) -> Unit {
  let delta = @time.delta()
  active_effects.retain(fn(effect) {
    effect.ttl -= delta
    if effect.ttl > 0 {
      return true
    }
    effect.entity.destroy()
    false
  })
}

///|
/// Adds an effect to the given parent entity.
///
/// TODO: support speed
pub fn add_effect(
  parent : @entity.Entity,
  effect : EffectAnimation,
  z? : Int = 0,
  speed? : Double = 1.0,
  flip? : Bool = false,
  offset? : @selene_math.Vec2 = @selene_math.Vec2(0.0, 0.0),
) -> Unit {
  let sprite_anim = effect.animation
  let loop_ = false
  let transform = if flip {
    @selene_math.Transform::from_scale(-1.0, 1.0)
  } else {
    @selene_math.Transform()
  }
  let sprite = @ms_animation.sprite_from_animation(sprite_anim, z, transform~)
  let child = parent.spawn_child()
  @sprite.sprites().set(child, sprite)
  @ms_animation.play_animation(child, sprite_anim, loop_~, transform~)
  @ms_animation.set_animation_speed(child, speed)
  // Selene uses transform.z as render depth. Keep the legacy `z` contract.
  @transform.transforms().set(
    child,
    @transform.Transform::from_xyz(offset.0, offset.1, z.to_double()),
  )
  let ttl = if effect.duration_ms <= 0 {
    0.001
  } else {
    effect.duration_ms.to_double() / 1000
  }

  // Register to global list
  active_effects.push({ entity: child, ttl })
}
