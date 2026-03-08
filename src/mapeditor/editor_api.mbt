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
  let zoom = @system.get_zoom()
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

///|
pub(all) struct EditorStatus {
  loading : Bool
  error_msg : String?
  map_id : Int
  scene_revision : Int
  map_name : String
  cam_x : Int
  cam_y : Int
  zoom : Double
  bg_visible : Bool
  bg_back_visible : Bool
  bg_fore_visible : Bool
  bg_debug_index : Int?
  bg_total_layers : Int
  fps : Double
} derive(ToJson, Show)

///|
fn get_editor_status() -> EditorStatus {
  let viewer = viewer_state.val
  let (loading, map_name) = match viewer.scene_state {
    Some({ scene_map: { map_info: { map_name, .. }, .. }, .. }) =>
      (false, map_name)
    None => (true, "")
  }
  let camera_pos = @camera.get_position()
  let bg_vis = @map.get_background_visibility_state()

  {
    loading,
    error_msg: viewer.error_message,
    map_id: viewer.current_map_id,
    scene_revision: viewer.scene_revision,
    map_name,
    cam_x: camera_pos[@selene_math.Axis::X].to_int(),
    cam_y: camera_pos[@selene_math.Axis::Y].to_int(),
    zoom: @system.get_zoom(),
    bg_visible: viewer.layer_visibility.backgrounds,
    bg_back_visible: bg_vis.back_visible,
    bg_fore_visible: bg_vis.fore_visible,
    bg_debug_index: bg_vis.debug_index,
    bg_total_layers: bg_vis.total_layers,
    fps: viewer.fps,
  }
}

///|
pub fn export_editor_status_ffi() -> EditorStatus {
  get_editor_status()
}

///|
pub(all) struct EditorTileObjLayerVisibility {
  layer : Int
  tiles_visible : Bool
  objs_visible : Bool
} derive(ToJson, Show)

///|
pub(all) struct EditorTileObjVisibilityState {
  tiles_visible : Bool
  objs_visible : Bool
  layers : Array[EditorTileObjLayerVisibility]
  tile_items : Array[Array[Bool]]
  obj_items : Array[Array[Bool]]
} derive(ToJson, Show)

///|
fn get_tile_obj_visibility_state() -> EditorTileObjVisibilityState {
  let st = @map.get_tile_objects_visibility()
  {
    tiles_visible: st.tiles_visible,
    objs_visible: st.objs_visible,
    layers: st.layers.map(fn(layer) {
      {
        layer: layer.layer,
        tiles_visible: layer.tiles_visible,
        objs_visible: layer.objs_visible,
      }
    }),
    tile_items: st.tile_items,
    obj_items: st.obj_items,
  }
}

///|
pub fn export_tile_obj_visibility_state_ffi() -> EditorTileObjVisibilityState {
  get_tile_obj_visibility_state()
}
