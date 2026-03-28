// This acts as a manual component system for "LifeTime".

///|
let active_effects : Array[EffectEntity] = []

///|
priv struct EffectEntity {
  entity : @entity.Entity
  mut ttl : Double
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
  animation : @resource.NxAnimation,
  z? : Int = 0,
  speed? : Double = 1.0,
  flip? : Bool = false,
) -> Unit {
  ignore(speed)
  let loop_ = false
  let sprite_anim = @ms_animation.from_nx_animation(animation, loop_~)
  let transform = if flip {
    @selene_math.Transform::from_scale(-1.0, 1.0)
  } else {
    @selene_math.Transform::new()
  }
  let sprite = @ms_animation.sprite_from_animation(sprite_anim, z, transform~)
  let child = parent.spawn_child()
  @sprite.sprites().set(child, sprite)
  // Selene uses transform.z as render depth. Keep the legacy `z` contract.
  @transform.transforms().set(
    child,
    @transform.Transform::from_xyz(0.0, 0.0, z.to_double()),
  )
  @ms_animation.play_animation(child, sprite_anim, loop_~, transform~)
  let duration = nx_animation_duration(animation)
  let ttl = duration.to_double() / 1000

  // Register to global list
  active_effects.push({ entity: child, ttl })
}

///|
fn nx_animation_duration(src : @resource.NxAnimation) -> Int {
  let delays = src.frames.map(fn(frame) {
    match frame.delay {
      Some(d) => if d <= 0 { 100 } else { d }
      None => 100
    }
  })
  let base_duration = delays.iter().fold(init=0, fn(acc, d) { acc + d })
  if src.zigzag && delays.length() > 2 {
    let mut extra = 0
    // add durations of frames N-2 down to 1
    for i = delays.length() - 2; i >= 1; i = i - 1 {
      extra += delays[i]
    }
    base_duration + extra
  } else {
    base_duration
  }
}
