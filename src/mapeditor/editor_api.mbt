///|
/// 编辑器场景图数据结构定义
pub(all) struct EditorSceneGraph {
  backgrounds : Array[EditorBackground]
  layers : Array[EditorLayer]
} derive(Show)

///|
pub(all) struct EditorBackground {
  id : Int
  type_ : String
  bS : String // 需要从 BackgroundResource 获取
  no : Int // 需要从 BackgroundResource 获取
  x : Int
  y : Int
  rx : Int
  ry : Int
  type_val : Int
  front : Bool
} derive(ToJson, Show)

///|
pub(all) struct EditorLayer {
  index : Int
  tiles : Array[@map.NxTileRef]
  objects : Array[@map.NxObj]
} derive(Show)

///|
pub(all) struct MouseInfo {
  screen_x : Int
  screen_y : Int
  world_x : Int
  world_y : Int
} derive(Show)

///|
/// 获取当前场景的结构图
fn get_scene_graph() -> EditorSceneGraph? {
  guard viewer_state.val.scene_state is Some(scene_state) else { return None }
  let backgrounds = scene_state.raw_resources.nx_map.back.0.mapi(fn(
    index,
    meta,
  ) {
    {
      id: index,
      type_: meta.type_.to_string(),
      bS: meta.bS,
      no: meta.no,
      x: meta.x,
      y: meta.y,
      rx: meta.rx,
      ry: meta.ry,
      type_val: meta.type_.int_value(),
      front: meta.front,
    }
  })
  let layers = scene_state.raw_resources.nx_map.layers.mapi(fn(index, layer) {
    let tiles = layer.tile
    let objects = layer.obj
    { index, tiles, objects }
  })
  Some({ backgrounds, layers })
}

///|
pub fn export_scene_graph_ffi() -> @js.Optional[EditorSceneGraph] {
  @js.Optional::from_option(get_scene_graph())
}

///|
fn get_mouse_info() -> MouseInfo {
  let mouse_screen = @inputs.mouse.pos
  let camera_pos = @camera.get_position()
  let zoom = @backend.get_zoom()
  let mouse_world = camera_pos + mouse_screen.scalar_div(zoom)
  {
    screen_x: mouse_screen.0.to_int(),
    screen_y: mouse_screen.1.to_int(),
    world_x: mouse_world.0.to_int(),
    world_y: mouse_world.1.to_int(),
  }
}

///|
pub fn export_mouse_info_ffi() -> MouseInfo {
  get_mouse_info()
}
