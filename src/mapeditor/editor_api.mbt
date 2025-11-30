///|
/// 编辑器场景图数据结构定义
/// 用于序列化为 JSON 传给 JS 前端
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
