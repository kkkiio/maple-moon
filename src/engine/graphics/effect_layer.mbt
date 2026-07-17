// This acts as a manual component system for "LifeTime".

///|
let active_effects : Array[EffectEntity] = []

///|
priv struct EffectEntity {
  entity : @entity.Entity
  active : @animation.ActiveAnimation
}

///|
/// A compiled one-shot effect together with its playback graph.
///
/// The graph is registered once when the effect resource is loaded and reused
/// by every spawned effect entity.
pub struct EffectAnimation {
  clip : @res.SpriteClip
  graph : @animation.AnimationGraphHandle
  node : @animation.AnimationNodeIndex
}

///|
/// Register the playback graph for a compiled effect clip.
///
/// # Example
/// ```moonbit nocheck
/// let effect = EffectAnimation(clip)
/// ignore(effect)
/// ```
pub fn EffectAnimation::EffectAnimation(
  clip : @res.SpriteClip,
) -> EffectAnimation {
  let (graph, node) = sprite_clip_graph(clip)
  { clip, graph, node }
}

///|
/// Reuse an existing animation graph node as a one-shot effect resource.
///
/// This constructor is intended for domains such as monsters that compile
/// several stance and effect clips into one shared graph. The graph must contain
/// `node`, and `node` must reference `clip.clip`.
///
/// # Example
/// ```moonbit nocheck
/// let effect = EffectAnimation::from_graph(clip, graph, node)
/// ignore(effect)
/// ```
pub fn EffectAnimation::from_graph(
  clip : @res.SpriteClip,
  graph : @animation.AnimationGraphHandle,
  node : @animation.AnimationNodeIndex,
) -> EffectAnimation {
  { clip, graph, node }
}

///|
pub fn effect_layer_system(_world : @ecs.World) -> Unit {
  active_effects.retain(fn(effect) {
    if effect.entity.is_alive() && !effect.active.is_finished() {
      return true
    }
    clear_sprite_animation(effect.entity)
    @transform.transforms().remove(effect.entity) |> ignore
    if effect.entity.is_alive() {
      effect.entity.destroy()
    }
    false
  })
}

///|
/// Adds an effect to the given parent entity.
///
/// The effect owns a child entity and removes it after the one-shot clip has
/// finished. `speed` scales playback and must be positive.
///
/// # Example
/// ```moonbit nocheck
/// add_effect(parent, EffectAnimation(clip), z=10, speed=1.25)
/// ```
///
/// # Panics
/// Panics when `speed` is zero or negative.
pub fn add_effect(
  parent : @entity.Entity,
  effect : EffectAnimation,
  z? : Int = 0,
  speed? : Double = 1.0,
  flip? : Bool = false,
  offset? : @selene_math.Vec2 = @selene_math.Vec2(0.0, 0.0),
) -> Unit {
  guard speed > 0.0 else {
    abort("effect playback speed must be positive: \{speed}")
  }
  let child = parent.spawn_child()
  @sprite.sprites().set(child, effect.clip.sprite(flip_x=flip))
  @animation.animation_target_ids().set(
    child,
    @animation.AnimationTargetId("self"),
  )
  @animation.animated_bys().set(child, @animation.AnimatedBy(child))
  @animation.animation_graph_handles().set(child, effect.graph)
  let player = @animation.AnimationPlayer()
  @animation.animation_players().set(child, player)
  let active = player.start(
    effect.node,
    repeat=@animation.RepeatAnimation::Never,
  )
  ignore(active.set_speed(speed))
  // Selene uses transform.z as render depth. Keep the legacy `z` contract.
  @transform.transforms().set(
    child,
    @transform.Transform::from_xyz(offset.0, offset.1, z.to_double()),
  )
  active_effects.push({ entity: child, active })
}
