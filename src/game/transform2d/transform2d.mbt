///|
/// Read the current 2D position from entity transform.
pub fn get_xy(entity : @entity.Entity) -> @math.Vec2? {
  @transform.transforms()
  .get(entity)
  .map(fn(transform) {
    @math.Vec2(transform.translation.x, transform.translation.y)
  })
}

///|
/// Update entity x/y while preserving existing z/rotation/scale when present.
pub fn set_xy(entity : @entity.Entity, pos : @math.Vec2) -> Unit {
  match @transform.transforms().get(entity) {
    Some(current) =>
      @transform.transforms().set(entity, {
        ..current,
        translation: @math.Vec3(
          pos[@math.X],
          pos[@math.Y],
          current.translation.z,
        ),
      })
    None =>
      @transform.transforms().set(
        entity,
        @transform.Transform::from_xyz(pos[@math.X], pos[@math.Y], 0.0),
      )
  }
}

///|
/// Remove transform from entity.
pub fn remove(entity : @entity.Entity) -> Unit {
  @transform.transforms().remove(entity)
}
