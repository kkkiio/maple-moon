///|
const MAP_ID : Int = 100000000

///|
const CAMERA_SPEED : Double = 640.0

///|
/// 地图查看器入口，创建最小化的渲染 App 并挂载调试系统。
fn main {
  @system.App::new()
  .with_image_smooth(false)
  .with_canvas_width(@graphics.view_size.0 |> Double::from_int)
  .with_canvas_height(@graphics.view_size.1 |> Double::from_int)
  .with_fps(@graphics.fps)
  .add_plugin(@plugins.default_plugin)
  .add_system(@config.logic_fps_system, system_name="logic_fps_system")
  .add_system(
    start_map_loading_system,
    schedule=Startup,
    system_name="viewer_startup",
  )
  .add_system(map_loading_poll_system, system_name="map_loader")
  .add_system(camera_control_system, system_name="camera_controller")
  .add_system(@map.background_system, system_name="background_system")
  .add_system(
    render_debug_overlay,
    schedule=Render(1),
    system_name="debug_overlay",
  )
  .run()
}

///|
struct MapLimits {
  left : Double
  right : Double
  top : Double
  bottom : Double
}

///|
struct ViewerState {
  io_service : @io_task.IOService
  mut map_future : @utils.Future[Result[@map.SceneMap, Error]]?
  mut map_info : @map.MapInfo?
  mut map_limits : MapLimits?
  mut camera_entity : @entity.Entity?
  mut map_loaded : Bool
  mut error_message : String?
}

///|
let viewer_state : Ref[ViewerState] = Ref::new({
  io_service: @io_task.IOService::new(),
  map_future: None,
  map_info: None,
  map_limits: None,
  camera_entity: None,
  map_loaded: false,
  error_message: None,
})

///|
fn start_map_loading_system(_delta : Double) -> Unit {
  if viewer_state.val.map_loaded || viewer_state.val.map_future is Some(_) {
    return
  }
  viewer_state.val.error_message = None
  let portal_animations = @map.Module::load().get_portals_animations()
  viewer_state.val.map_future = Some(
    viewer_state.val.io_service.submit(fn() {
      @map.load_map(MAP_ID, portal_animations)
    }),
  )
  @log.info({ "map_id": MAP_ID }, "start loading map for viewer")
}

///|
fn map_loading_poll_system(_delta : Double) -> Unit {
  guard viewer_state.val.map_future is Some(future) else { return }
  match future.poll() {
    None => ()
    Some(result) => {
      viewer_state.val.map_future = None
      match result {
        Ok(scene_map) => finalize_scene(scene_map)
        Err(e) => {
          viewer_state.val.error_message = Some(e.to_string())
          @log.error({ "map_id": MAP_ID, "error": e }, "load map failed")
        }
      }
    }
  }
}

///|
fn finalize_scene(scene_map : @map.SceneMap) -> Unit {
  let map_info = scene_map.map_info
  let tiles_objs = scene_map.tiles_objs
  let backgrounds = scene_map.backgrounds
  let walls = map_info.get_walls()
  let borders = map_info.get_borders()
  let width = walls.delta().to_double()
  let height = borders.delta().to_double()
  let world_size = @selene_math.Vec2D(width, height)
  @map.set_backgrounds(backgrounds, world_size)
  @map.MapTilesObjs::set_sprites(tiles_objs)
  let center = @selene_math.Vec2D(
    ((walls.first() + walls.second()) / 2).to_double(),
    ((borders.first() + borders.second()) / 2).to_double(),
  )
  let entity = ensure_camera_entity()
  @position.positions.set(entity, @position.Position(center))
  let limits = MapLimits::{
    left: walls.first().to_double(),
    right: walls.second().to_double(),
    top: borders.first().to_double(),
    bottom: borders.second().to_double(),
  }
  @camera.set_limits(
    top=limits.top,
    bottom=limits.bottom,
    left=limits.left,
    right=limits.right,
  )
  viewer_state.val.map_limits = Some(limits)
  viewer_state.val.map_info = Some(map_info)
  viewer_state.val.map_loaded = true
  @log.info(
    { "map_id": MAP_ID, "width": width, "height": height },
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
  let wasd = @inputs.key_vector(
    @inputs.Code::KeyW,
    @inputs.Code::KeyS,
    @inputs.Code::KeyA,
    @inputs.Code::KeyD,
  )
  let arrow = @inputs.key_vector(
    @inputs.Code::ArrowUp,
    @inputs.Code::ArrowDown,
    @inputs.Code::ArrowLeft,
    @inputs.Code::ArrowRight,
  )
  let direction = wasd + arrow
  if direction.distance() == 0.0 {
    return
  }
  let current_pos = @position.positions
    .get(entity)
    .map(fn(pos) { pos.0 })
    .unwrap_or(@selene_math.Vec2D::zero())
  let next_pos = current_pos +
    direction.normalize().scalar_mul(CAMERA_SPEED * delta)
  let clamped_pos = match viewer_state.val.map_limits {
    Some(limits) => clamp_vec(next_pos, limits)
    None => next_pos
  }
  @position.positions.set(entity, @position.Position(clamped_pos))
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
fn render_debug_overlay(_delta : Double) -> Unit {
  let status_line = match viewer_state.val.error_message {
    Some(msg) => "载入失败: \{msg}"
    None =>
      if viewer_state.val.map_loaded {
        "地图载入完成"
      } else {
        "正在载入地图..."
      }
  }
  let map_line = match viewer_state.val.map_info {
    Some(info) => "地图 \{MAP_ID}: \{info.get_full_name()}"
    None => "地图 \{MAP_ID}"
  }
  let camera_pos = @camera.get_position()
  let cam_x = camera_pos[@selene_math.Axis::X]
  let cam_y = camera_pos[@selene_math.Axis::Y]
  let zoom = @backend.get_zoom()
  let info = "\{map_line}\n相机: (\{cam_x}, \{cam_y})  Zoom: \{zoom}\n控制: WASD / 方向键 平移镜头\n\{status_line}"
  @backend.draw_text(
    text=info,
    x=12.0,
    y=16.0,
    font="16px monospace",
    color="#f8fafc",
    align=@selene_math.HAlign::Left,
    baseline=@selene_math.VAlign::Top,
  )
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
