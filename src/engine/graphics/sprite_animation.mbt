///|
let single_clip_graphs : Map[
  @animation.AnimationClipHandle,
  (@animation.AnimationGraphHandle, @animation.AnimationNodeIndex),
] = Map([])

///|
/// Return the process-lifetime playback graph shared by one sprite clip.
///
/// Gameplay and UI controllers keep their own players and repeat policy. This
/// cache only deduplicates the immutable one-node graph derived from a clip.
///
/// # Example
/// ```moonbit nocheck
/// let (graph, node) = sprite_clip_graph(clip)
/// ignore((graph, node))
/// ```
pub fn sprite_clip_graph(
  clip : @res.SpriteClip,
) -> (@animation.AnimationGraphHandle, @animation.AnimationNodeIndex) {
  match single_clip_graphs.get(clip.clip) {
    Some(playback) => playback
    None => {
      let (graph, node) = @animation.AnimationGraph::from_clip(clip.clip)
      let playback = (@animation.register_animation_graph_asset(graph), node)
      single_clip_graphs[clip.clip] = playback
      playback
    }
  }
}

///|
/// Remove all Selene components owned by sprite-clip playback on an entity.
///
/// The caller remains responsible for domain components and for destroying the
/// entity itself. Calling this for an entity without playback is harmless.
///
/// # Example
/// ```moonbit nocheck
/// clear_sprite_animation(entity)
/// entity.destroy()
/// ```
pub fn clear_sprite_animation(entity : @entity.Entity) -> Unit {
  if @animation.animation_players().get(entity) is Some(player) {
    ignore(player.stop_all())
  }
  @animation.animation_players().remove(entity) |> ignore
  @animation.animation_transitions().remove(entity) |> ignore
  @animation.animation_graph_handles().remove(entity) |> ignore
  @animation.animation_target_ids().remove(entity) |> ignore
  @animation.animated_bys().remove(entity) |> ignore
  @sprite.sprites().remove(entity) |> ignore
}
