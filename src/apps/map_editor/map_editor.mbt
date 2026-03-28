///|
const MAP_ID : Int = 100030000

///|
const CAMERA_SPEED : Double = 640.0

///|
pub fn start_editor() -> Unit {
  let mut app = @app.App::new()
    .with_image_smooth(false)
    .with_viewport_width(@graphics.view_size.0 |> Double::from_int)
    .with_viewport_height(@graphics.view_size.1 |> Double::from_int)
    .with_fps(@graphics.fps)
    .with_fixed_hz(125U)
    .add_plugin(@plugins.default_plugin)
  app = app.add_system(
    Startup,
    fn(_world) { start_map_loading_system(@time.delta()) },
    system_name="viewer_startup",
  )
  app = app.add_system(
    Update,
    fn(_world) { map_loading_poll_system(@time.delta()) },
    system_name="map_loader",
  )
  app = app.add_system(
    Update,
    fn(_world) { camera_control_system(@time.delta()) },
    system_name="camera_controller",
  )
  app = app.add_system(
    Update,
    fn(world) { @map.background_system(world) },
    system_name="background_system",
  )
  app = app.add_system(
    Update,
    fn(world) { @map.tile_objects_system(world) },
    system_name="tile_objects_system",
  )
  app = app.add_system(
    Update,
    fn(world) { @map.portal_system(world) },
    system_name="portal_system",
  )
  app = app.add_system(
    Update,
    fn(world) { @monster.map_monsters_render_system(world) },
    system_name="monster_rendering_system",
  )
  app = app.add_system(
    FixedUpdate,
    fn(world) { @monster.map_monsters_fixed_system(world) },
    system_name="monster_fixed_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { viewer_visibility_input_system(@time.delta()) },
    system_name="viewer_visibility_controls",
  )
  app = app.add_system(
    Update,
    fn(_world) { render_debug_overlay(@time.delta()) },
    system_name="debug_overlay",
  )
  app.run()
}

///|
pub fn load_map_ffi(id : Int) -> Unit {
  viewer_state.val.current_map_id = id
  viewer_state.val.map_future = Some(
    @io_service.submit_background_task(async fn() {
      let portal_animations = @map.Module::load().get_portals_animations()
      let raw = @map.load_map_resources_by_id(id)
      let scene = @map.create_scene_map(raw, portal_animations)
      (raw, scene)
    }),
  )
  viewer_state.val.scene_state = None
  viewer_state.val.error_message = None
}

///|
pub fn set_background_visible_ffi(show_bg : Bool) -> Unit {
  viewer_state.val.layer_visibility.backgrounds = show_bg
  apply_visibility_to_modules()
}

///|
pub fn set_layer_visibility_ffi(
  layer : Int,
  tiles_visible : Bool,
  objs_visible : Bool,
) -> Unit {
  @map.set_layer_visibility(layer, tiles_visible, objs_visible)
}

///|
pub fn set_tile_visibility_ffi(
  layer : Int,
  resource_index : Int,
  visible : Bool,
) -> Unit {
  @map.set_tile_visibility(layer, resource_index, visible)
}

///|
pub fn set_obj_visibility_ffi(
  layer : Int,
  resource_index : Int,
  visible : Bool,
) -> Unit {
  @map.set_obj_visibility(layer, resource_index, visible)
}

///|
pub fn set_tiles_scope_visibility_ffi(visible : Bool) -> Unit {
  @map.set_tiles_visible(visible)
}

///|
pub fn set_objs_scope_visibility_ffi(visible : Bool) -> Unit {
  @map.set_objs_visible(visible)
}

///|
pub fn reset_tile_obj_visibility_ffi() -> Unit {
  @map.reset_tile_obj_visibility()
}

///|
pub struct MapLimits {
  left : Double
  right : Double
  top : Double
  bottom : Double
} derive(Show)

///|
pub struct LayerVisibility {
  mut backgrounds : Bool
}

///|
fn default_visibility() -> LayerVisibility {
  { backgrounds: true }
}

///|
pub struct ViewerState {
  mut current_map_id : Int
  mut scene_revision : Int
  mut map_future : @utils.Future[
    Result[(@map.MapRawResources, @map.SceneMap), Error],
  ]?
  mut error_message : String?
  mut scene_state : SceneState?
  mut camera_entity : @entity.Entity?
  layer_visibility : LayerVisibility
  mut fps : Double
  mut physics : @physics.Physics?
}

///|
pub struct SceneState {
  raw_resources : @map.MapRawResources
  scene_map : @map.SceneMap
  map_limits : MapLimits
}

///|
let viewer_state : Ref[ViewerState] = Ref::new({
  current_map_id: MAP_ID,
  scene_revision: 0,
  map_future: None,
  scene_state: None,
  error_message: None,
  camera_entity: None,
  layer_visibility: default_visibility(),
  fps: 0.0,
  physics: None,
})

///|
fn start_map_loading_system(_delta : Double) -> Unit {
  if viewer_state.val.scene_state is Some(_) ||
    viewer_state.val.map_future is Some(_) {
    return
  }
  viewer_state.val.error_message = None
  viewer_state.val.current_map_id = MAP_ID
  let portal_animations = @map.Module::load().get_portals_animations()
  viewer_state.val.map_future = Some(
    @io_service.submit_background_task(async fn() {
      let raw = @map.load_map_resources_by_id(MAP_ID)
      let scene = @map.create_scene_map(raw, portal_animations)
      (raw, scene)
    }),
  )
  @log.info("start loading map for viewer", data={ "map_id": MAP_ID })
}

///|
fn map_loading_poll_system(_delta : Double) -> Unit {
  guard viewer_state.val.map_future is Some(future) else { return }
  guard future.poll() is Some(result) else { return }
  viewer_state.val.map_future = None
  match result {
    Ok((raw_resources, scene_map)) => {
      viewer_state.val.current_map_id = raw_resources.id
      finalize_scene(raw_resources, scene_map)
    }
    Err(e) => {
      viewer_state.val.error_message = Some(e.to_string())
      @log.error("load map failed", data={
        "map_id": viewer_state.val.current_map_id,
        "error": e,
      })
    }
  }
}

///|
fn finalize_scene(
  raw_resources : @map.MapRawResources,
  scene_map : @map.SceneMap,
) -> Unit {
  let map_info = scene_map.map_info
  let tiles_objs = scene_map.tiles_objs
  let backgrounds = scene_map.backgrounds
  let walls = map_info.get_walls()
  let borders = map_info.get_borders()
  @map.set_backgrounds(backgrounds)
  @map.set_tiles_objs(tiles_objs)
  @map.set_portals(scene_map.portals)
  apply_visibility_to_modules()
  let center = @selene_math.Vec2D(
    ((walls.first() + walls.second()) / 2).to_double(),
    ((borders.first() + borders.second()) / 2).to_double(),
  )
  let entity = ensure_camera_entity()
  @transform2d.set_xy(entity, center)
  let map_limits = MapLimits::{
    left: walls.first().to_double(),
    right: walls.second().to_double(),
    top: borders.first().to_double(),
    bottom: borders.second().to_double(),
  }
  let (left, right, top, bottom) = normalize_camera_limits(
    map_limits.left,
    map_limits.right,
    map_limits.top,
    map_limits.bottom,
  )
  @ms_camera.set_limits(left, right, top, bottom)
  viewer_state.val.scene_state = Some({ raw_resources, scene_map, map_limits })

  // Initialize Physics
  let physics = @physics.Physics::from_resource(raw_resources.nx_map.foothold) catch {
    e => {
      viewer_state.val.error_message = Some("Physics Error: " + e.to_string())
      @physics.empty_physics() // Fallback to empty physics
    }
  }
  viewer_state.val.physics = Some(physics)

  // Initialize Monsters
  let mobs = @monster.MapMobs::new()
  let mut oid_counter = 100000
  for life in raw_resources.nx_map.life {
    guard life.type_ == "m" else { continue }
    let oid = oid_counter
    oid_counter += 1
    let id = @strconv.parse_int(life.id) catch { _ => 0 }
    mobs.spawn(
      @monster.create_mob_spawn(
        oid,
        id,
        0, // mode
        0, // stance
        life.fh,
        true, // new_spawn
        0, // team
        @struct.Point::new(life.x, life.y),
      ),
    )
  }
  @monster.set_mobs({ map_mobs: mobs, physics })
  viewer_state.val.scene_revision += 1
  @log.info("map ready in viewer", data={
    "map_id": raw_resources.id,
    "scene_revision": viewer_state.val.scene_revision,
    "map_limits": map_limits,
    "mob_count": oid_counter - 100000,
  })
}

///|
fn ensure_camera_entity() -> @entity.Entity {
  match viewer_state.val.camera_entity {
    Some(entity) => entity
    None => {
      let entity = @entity.Entity::new()
      @ms_camera.setup_camera_entity(entity, center=@selene_math.Vec2D::zero())
      viewer_state.val.camera_entity = Some(entity)
      entity
    }
  }
}

///|
fn camera_control_system(delta : Double) -> Unit {
  guard viewer_state.val.camera_entity is Some(entity) else { return }
  let direction = @inputs.key_vector(
    @inputs.Code::ArrowUp,
    @inputs.Code::ArrowDown,
    @inputs.Code::ArrowLeft,
    @inputs.Code::ArrowRight,
  )
  if direction.distance() == 0.0 {
    return
  }
  let current_pos = @transform2d.get_xy(entity).unwrap_or(
    @selene_math.Vec2D::zero(),
  )
  let next_pos = current_pos +
    direction.normalize().scalar_mul(CAMERA_SPEED * delta)
  let clamped_pos = match viewer_state.val.scene_state {
    Some({ map_limits, .. }) => clamp_vec(next_pos, map_limits)
    None => next_pos
  }
  @transform2d.set_xy(entity, clamped_pos)
}

///|
fn viewer_visibility_input_system(_delta : Double) -> Unit {
  if viewer_state.val.scene_state is None {
    return
  }
  if @inputs.is_just_pressed(@inputs.Code::KeyQ) {
    toggle_background_visibility()
  }
  if @inputs.is_just_pressed(@inputs.Code::KeyR) {
    @map.step_background_debug(-1)
  }
  if @inputs.is_just_pressed(@inputs.Code::KeyT) {
    @map.step_background_debug(1)
  }
  if @inputs.is_just_pressed(@inputs.Code::Escape) {
    @map.clear_background_debug()
  }
}

///|
fn clamp_vec(
  pos : @selene_math.Vec2D,
  limits : MapLimits,
) -> @selene_math.Vec2D {
  let x = pos[@selene_math.Axis::X]
  let y = pos[@selene_math.Axis::Y]
  @selene_math.Vec2D(
    clamp(x, limits.left, limits.right),
    clamp(y, limits.top, limits.bottom),
  )
}

///|
fn render_debug_overlay(delta : Double) -> Unit {
  if delta > 0.0 {
    viewer_state.val.fps = 1.0 / delta
  }
}

///|
fn normalize_camera_limits(
  left : Double,
  right : Double,
  top : Double,
  bottom : Double,
) -> (Double, Double, Double, Double) {
  let viewport_width = @graphics.view_size.0.to_double()
  let viewport_height = @graphics.view_size.1.to_double()
  let right = if right - left < viewport_width {
    left + viewport_width
  } else {
    right
  }
  let top = if bottom - top < viewport_height {
    bottom - viewport_height
  } else {
    top
  }
  (left, right, top, bottom)
}

///|

///|
fn toggle_background_visibility() -> Unit {
  viewer_state.val.layer_visibility.backgrounds = not(
    viewer_state.val.layer_visibility.backgrounds,
  )
  apply_visibility_to_modules()
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
fn apply_visibility_to_modules() -> Unit {
  let visibility = viewer_state.val.layer_visibility
  @map.set_background_visibility(visibility.backgrounds, visibility.backgrounds)
  if not(visibility.backgrounds) {
    @map.clear_background_debug()
  }
}
