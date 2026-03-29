///|
/// Backward-compatible facade for character presentation APIs.
pub type CharLook = @cp.CharLook

///|
/// Backward-compatible facade for character presentation module runtime.
pub type CharacterPresentationResource = @cp.CharacterPresentationResource

///|
/// Backward-compatible facade for serialized look entry.
pub type LookEntry = @cp.LookEntry

///|
/// Backward-compatible facade for body visual resource container.
pub type FullBody = @cp.FullBody

///|
/// Backward-compatible facade for hair visual resource container.
pub type Hair = @cp.Hair

///|
/// Backward-compatible facade for face visual resource container.
pub type Face = @cp.Face

///|
/// Backward-compatible facade for face expression id.
pub type ExpressionId = @cp.ExpressionId

///|
/// Backward-compatible facade for hair layer id.
pub type HairLayer = @cp.HairLayer

///|
/// Backward-compatible facade for stance animation maps.
pub type NxStanceLooks[T] = @cb.NxStanceLooks[T]

///|
/// Backward-compatible facade for after-image runtime object.
pub type AfterImage = @vfx_afterimage.AfterImage

///|
/// Backward-compatible facade for after-image resource.
pub type NxAfterImage = @vfx_afterimage.NxAfterImage

///|
/// Backward-compatible facade for parsed after-image collections.
pub type NxAfterImages = @vfx_afterimage.NxAfterImages

///|
/// Backward-compatible facade for expression table.
pub let expression_names : @sorted_map.SortedMap[ExpressionId, String] = @cp.expression_names

///|
/// Backward-compatible facade for hair layer lookup table.
pub let layers_by_name : @sorted_map.SortedMap[String, HairLayer] = @cp.layers_by_name

///|
/// Backward-compatible facade for hair name table.
pub let hair_names : Map[String, String] = @cp.hair_names

///|
pub fn byaction(action : Int) -> ExpressionId {
  @cp.byaction(action)
}

///|
pub fn get_resource() -> CharacterPresentationResource? {
  @cp.get_resource()
}

///|
pub fn insert_resource(resource : CharacterPresentationResource) -> Unit {
  @cp.insert_resource(resource)
}

///|
pub fn clear_resource() -> Unit {
  @cp.clear_resource()
}

///|
pub fn char_look_system(world : @ecs.World) -> Unit {
  @cp.char_look_system(world)
}

///|
pub fn set_after_images(name : String, after_images : NxAfterImages) -> Unit {
  @vfx_afterimage.set_after_images(name, after_images)
}

///|
pub fn add_after_image(
  entity : @entity.Entity,
  get_frame_fn : () -> Int,
  after_image : NxAfterImage,
  facing_right : Bool,
) -> Unit {
  @vfx_afterimage.add_after_image(
    entity, get_frame_fn, after_image, facing_right,
  )
}

///|
pub fn get_after_image(entity : @entity.Entity) -> AfterImage? {
  @vfx_afterimage.get_after_image(entity)
}

///|
pub fn clear_after_image(entity : @entity.Entity) -> Unit {
  @vfx_afterimage.clear_after_image(entity)
}

///|
pub fn update_after_image_system(world : @ecs.World) -> Unit {
  @vfx_afterimage.update_after_image_system(world)
}
