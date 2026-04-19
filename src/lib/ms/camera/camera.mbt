///|
pub(all) struct CameraLimits {
  left : Double
  right : Double
  top : Double
  bottom : Double
}

///|
pub(all) struct FollowTarget {
  entity : @entity.Entity
  offset : @math.Vec2
}

///|
pub(all) struct CameraRuntime {
  mut camera_entity : @entity.Entity?
  mut follow_target : FollowTarget?
  mut limits : CameraLimits?
}

///|
let runtime_ref : Ref[CameraRuntime] = Ref::new({
  camera_entity: None,
  follow_target: None,
  limits: None,
})

///|
pub fn setup_camera_entity(
  entity : @entity.Entity,
  center? : @math.Vec2 = @system.get_screen_size().scalar_mul(0.5),
) -> Unit {
  runtime_ref.val.camera_entity = Some(entity)
  @selene_camera.cameras().set(entity, @selene_camera.Camera::new())
  @selene_camera.camera2ds().set(entity, @selene_camera.Camera2d::new())
  if !@selene_camera.orthographic_projections().contains(entity) {
    @selene_camera.orthographic_projections().set(
      entity,
      @selene_camera.OrthographicProjection::new(),
    )
  }
  @transform2d.set_xy(entity, center)
}

///|
pub fn ensure_camera_entity(
  center? : @math.Vec2 = @system.get_screen_size().scalar_mul(0.5),
) -> @entity.Entity {
  match runtime_ref.val.camera_entity {
    Some(entity) if entity.is_alive() => entity
    _ => {
      let entity = @entity.Entity::new()
      setup_camera_entity(entity, center~)
      entity
    }
  }
}

///|
pub fn camera_entity() -> @entity.Entity? {
  runtime_ref.val.camera_entity
}

///|
pub fn set_follow_target(
  entity : @entity.Entity,
  offset? : @math.Vec2 = @math.Vec2::zero(),
) -> Unit {
  runtime_ref.val.follow_target = Some({ entity, offset })
}

///|
pub fn clear_follow_target() -> Unit {
  runtime_ref.val.follow_target = None
}

///|
pub fn set_limits(
  left : Double,
  right : Double,
  top : Double,
  bottom : Double,
) -> Unit {
  runtime_ref.val.limits = Some({ left, right, top, bottom })
}

///|
pub fn clear_limits() -> Unit {
  runtime_ref.val.limits = None
}

///|
pub fn current_camera_center() -> @math.Vec2 {
  match runtime_ref.val.camera_entity {
    Some(entity) =>
      @transform2d.get_xy(entity).unwrap_or(
        @system.get_screen_size().scalar_mul(0.5),
      )
    None => @system.get_screen_size().scalar_mul(0.5)
  }
}

///|
pub fn set_camera_center(pos : @math.Vec2) -> Unit {
  let entity = ensure_camera_entity(center=pos)
  @transform2d.set_xy(entity, pos)
}

///|
pub fn viewport_to_world(viewport_pos : @math.Vec2) -> @math.Vec2 {
  match active_camera_view() {
    Some((camera, global, projection)) =>
      camera.viewport_to_world_2d(global, projection, viewport_pos)
    None => @system.unscale_vec2(viewport_pos)
  }
}

///|
pub fn world_to_viewport(world_pos : @math.Vec2) -> @math.Vec2 {
  match active_camera_view() {
    Some((camera, global, projection)) =>
      camera.world_to_viewport(global, projection, world_pos)
    None => @system.scale_vec2(world_pos)
  }
}

///|
pub fn current_camera_top_left() -> @math.Vec2 {
  viewport_to_world(@math.Vec2(0.0, 0.0))
}

///|
pub fn camera_follow_system(_world : @ecs.World) -> Unit {
  guard runtime_ref.val.follow_target is Some(follow) else { return }
  guard runtime_ref.val.camera_entity is Some(camera_entity) else { return }
  guard @transform2d.get_xy(follow.entity) is Some(target_pos) else { return }
  let mut center = target_pos + follow.offset
  center = clamp_center(center)
  @transform2d.set_xy(camera_entity, center)
}

///|
fn clamp_center(center : @math.Vec2) -> @math.Vec2 {
  guard runtime_ref.val.limits is Some(limits) else { return center }
  let half = @system.get_screen_size().scalar_mul(0.5 / @system.get_zoom())
  let min_x = limits.left + half[@math.X]
  let max_x = limits.right - half[@math.X]
  let min_y = limits.top + half[@math.Y]
  let max_y = limits.bottom - half[@math.Y]
  let x = if min_x > max_x {
    (limits.left + limits.right) * 0.5
  } else {
    clamp(center[@math.X], min_x, max_x)
  }
  let y = if min_y > max_y {
    (limits.top + limits.bottom) * 0.5
  } else {
    clamp(center[@math.Y], min_y, max_y)
  }
  @math.Vec2(x, y)
}

///|
fn clamp(value : Double, min_value : Double, max_value : Double) -> Double {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn active_camera_view() -> (
  @selene_camera.Camera,
  @transform.GlobalTransform,
  @selene_camera.OrthographicProjection,
)? {
  match runtime_ref.val.camera_entity {
    Some(entity) => {
      guard @selene_camera.cameras().get(entity) is Some(cam) else {
        return None
      }
      guard @transform.compute_global_transform(entity) is Some(global) else {
        return None
      }
      let projection = @selene_camera.orthographic_projections()
        .get(entity)
        .unwrap_or_default()
      Some((cam, global, projection))
    }
    None => None
  }
}
