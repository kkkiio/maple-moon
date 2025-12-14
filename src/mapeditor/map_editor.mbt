///|
const MAP_ID : Int = 100030000

///|
const CAMERA_SPEED : Double = 640.0

///|
pub fn start_editor() -> Unit {
  @system.App::new()
  .with_image_smooth(false)
  .with_canvas_width(@graphics.view_size.0 |> Double::from_int)
  .with_canvas_height(@graphics.view_size.1 |> Double::from_int)
  .with_fps(@graphics.fps)
  .add_plugin(@plugins.default_plugin)
  .add_system(@logic_fps.logic_fps_system, system_name="logic_fps_system")
  .add_system(
    start_map_loading_system,
    schedule=Startup,
    system_name="viewer_startup",
  )
  .add_system(map_loading_poll_system, system_name="map_loader")
  .add_system(camera_control_system, system_name="camera_controller")
  .add_system(@map.background_system, system_name="background_system")
  .add_system(@map.tile_objects_system, system_name="tile_objects_system")
  .add_system(@map.portal_system, system_name="portal_system")
  .add_system(
    viewer_visibility_input_system,
    system_name="viewer_visibility_controls",
  )
  .add_system(
    render_debug_overlay,
    schedule=Render(1),
    system_name="debug_overlay",
  )
  .run()
}

///|
pub fn load_map_ffi(id : Int) -> Unit {
  viewer_state.val.map_future = Some(
    @io_service.submit_background_task(fn() {
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
pub fn set_view_options_ffi(
  show_bg : Bool,
  show_tiles : Bool,
  show_objs : Bool,
) -> Unit {
  viewer_state.val.layer_visibility.backgrounds = show_bg
  viewer_state.val.layer_visibility.tiles = show_tiles
  viewer_state.val.layer_visibility.objs = show_objs
  apply_visibility_to_modules()
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
  mut tiles : Bool
  mut objs : Bool
}

///|
fn default_visibility() -> LayerVisibility {
  { backgrounds: true, tiles: true, objs: true }
}

///|
pub struct ViewerState {
  mut map_future : @utils.Future[
    Result[(@map.MapRawResources, @map.SceneMap), Error],
  ]?
  mut error_message : String?
  mut scene_state : SceneState?
  mut camera_entity : @entity.Entity?
  layer_visibility : LayerVisibility
  mut fps : Double
}

///|
pub struct SceneState {
  raw_resources : @map.MapRawResources
  scene_map : @map.SceneMap
  map_limits : MapLimits
}

///|
let viewer_state : Ref[ViewerState] = Ref::new({
  map_future: None,
  scene_state: None,
  error_message: None,
  camera_entity: None,
  layer_visibility: default_visibility(),
  fps: 0.0,
})

///|
fn start_map_loading_system(_delta : Double) -> Unit {
  if viewer_state.val.scene_state is Some(_) ||
    viewer_state.val.map_future is Some(_) {
    return
  }
  viewer_state.val.error_message = None
  let portal_animations = @map.Module::load().get_portals_animations()
  viewer_state.val.map_future = Some(
    @io_service.submit_background_task(fn() {
      let raw = @map.load_map_resources_by_id(MAP_ID)
      let scene = @map.create_scene_map(raw, portal_animations)
      (raw, scene)
    }),
  )
  @log.info({ "map_id": MAP_ID }, "start loading map for viewer")
}

///|
fn map_loading_poll_system(_delta : Double) -> Unit {
  guard viewer_state.val.map_future is Some(future) else { return }
  guard future.poll() is Some(result) else { return }
  viewer_state.val.map_future = None
  match result {
    Ok((raw_resources, scene_map)) => finalize_scene(raw_resources, scene_map)
    Err(e) => {
      viewer_state.val.error_message = Some(e.to_string())
      @log.error({ "map_id": MAP_ID, "error": e }, "load map failed")
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
  @position.positions.set(entity, @position.Position(center))
  let map_limits = MapLimits::{
    left: walls.first().to_double(),
    right: walls.second().to_double(),
    top: borders.first().to_double(),
    bottom: borders.second().to_double(),
  }
  @camera.set_limits(
    top=map_limits.top,
    bottom=map_limits.bottom,
    left=map_limits.left,
    right=map_limits.right,
  )
  viewer_state.val.scene_state = Some({ raw_resources, scene_map, map_limits })
  @log.info(
    { "map_id": MAP_ID, "map_limits": map_limits },
    "map ready in viewer",
  )
}

///|
fn ensure_camera_entity() -> @entity.Entity {
  match viewer_state.val.camera_entity {
    Some(entity) => entity
    None => {
      let entity = @entity.Entity::new()
      @camera.attach_entity(entity, @selene_math.Vec2D::zero())
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
  let current_pos = @position.positions
    .get(entity)
    .map(fn(pos) { pos.0 })
    .unwrap_or(@selene_math.Vec2D::zero())
  let next_pos = current_pos +
    direction.normalize().scalar_mul(CAMERA_SPEED * delta)
  let clamped_pos = match viewer_state.val.scene_state {
    Some({ map_limits, .. }) => clamp_vec(next_pos, map_limits)
    None => next_pos
  }
  @position.positions.set(entity, @position.Position(clamped_pos))
}

///|
fn viewer_visibility_input_system(_delta : Double) -> Unit {
  if viewer_state.val.scene_state is None {
    return
  }
  if @inputs.is_just_pressed(@inputs.Code::KeyQ) {
    toggle_background_visibility()
  }
  if @inputs.is_just_pressed(@inputs.Code::KeyW) {
    toggle_tiles_visibility()
  }
  if @inputs.is_just_pressed(@inputs.Code::KeyE) {
    toggle_objs_visibility()
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

///|
fn toggle_background_visibility() -> Unit {
  viewer_state.val.layer_visibility.backgrounds = not(
    viewer_state.val.layer_visibility.backgrounds,
  )
  apply_visibility_to_modules()
}

///|
fn toggle_tiles_visibility() -> Unit {
  viewer_state.val.layer_visibility.tiles = not(
    viewer_state.val.layer_visibility.tiles,
  )
  apply_visibility_to_modules()
}

///|
fn toggle_objs_visibility() -> Unit {
  viewer_state.val.layer_visibility.objs = not(
    viewer_state.val.layer_visibility.objs,
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
  @map.set_tiles_visible(visibility.tiles)
  @map.set_objs_visible(visibility.objs)
  if not(visibility.backgrounds) {
    @map.clear_background_debug()
  }
}
