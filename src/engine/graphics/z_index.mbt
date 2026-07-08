///|
pub const BACKGROUND_ZINDEX = 1000

///|
/// 地图物品和瓦片的 z 值起始点.
pub const OBJECT_TILE_LAYER_ZINDEX = 30000

///|
/// 地图可用层号最小值.
pub const MAP_LAYER_MIN = 0

///|
/// 地图可用层号最大值.
pub const MAP_LAYER_MAX = 7

///|
/// 地图层之间的 z 间距.
pub const MAP_LAYER_STRIDE = 5000

///|
/// 同层内 obj pass 偏移.
pub const MAP_PASS_OBJ = 200

///|
/// 同层内 tile pass 偏移.
pub const MAP_PASS_TILE = 400

///|
/// 同层内 reactor pass 偏移.
pub const MAP_PASS_REACTOR = 800

///|
/// 同层内 npc pass 偏移.
pub const MAP_PASS_NPC = 1200

///|
/// 同层内 mob pass 偏移.
pub const MAP_PASS_MOB = 1400

///|
/// 同层内角色 pass 偏移.
pub const MAP_PASS_CHAR = 1600

///|
/// 同层内玩家 pass 偏移.
pub const MAP_PASS_PLAYER = 1800

///|
/// 同层内掉落物 pass 偏移.
pub const MAP_PASS_DROP = 2000

///|
/// 局部排序上限.
pub const MAP_LOCAL_MAX = 999

///|
/// y bias 上限.
pub const MAP_Y_BIAS_MAX = 1023

///|
fn clamp_map_layer(layer : Int) -> Int {
  if layer < MAP_LAYER_MIN {
    return MAP_LAYER_MIN
  }
  if layer > MAP_LAYER_MAX {
    return MAP_LAYER_MAX
  }
  layer
}

///|
/// 裁剪 local 值到合法范围.
pub fn clamp_map_local(v : Int) -> Int {
  if v < 0 {
    return 0
  }
  if v > MAP_LOCAL_MAX {
    return MAP_LOCAL_MAX
  }
  v
}

///|
/// 裁剪 y_bias 值到合法范围.
pub fn clamp_map_y_bias(v : Int) -> Int {
  if v < 0 {
    return 0
  }
  if v > MAP_Y_BIAS_MAX {
    return MAP_Y_BIAS_MAX
  }
  v
}

///|
/// 组合地图场景 z 值.
///
/// 公式：`z = base + layer*stride + pass + local + y_bias`.
pub fn compose_map_z(
  layer : Int,
  pass : Int,
  local_offset : Int,
  y_bias : Int,
) -> Int {
  let layer = clamp_map_layer(layer)
  let local_offset = clamp_map_local(local_offset)
  let y_bias = clamp_map_y_bias(y_bias)
  let lane = pass + local_offset + y_bias
  let lane = if lane >= MAP_LAYER_STRIDE { MAP_LAYER_STRIDE - 1 } else { lane }
  OBJECT_TILE_LAYER_ZINDEX + layer * MAP_LAYER_STRIDE + lane
}

///|
/// 计算 map tile zM 使用的 local 值.
pub fn map_tile_local(zM : Int) -> Int {
  clamp_map_local(zM)
}

///|
/// 计算 map obj 使用的 local 值：优先 z，z<=0 时回退 zM.
pub fn map_obj_local(z : Int, zM : Int) -> Int {
  let raw = if z > 0 { z } else { zM }
  clamp_map_local(raw)
}

///|
/// 由世界 y 计算 y_bias.
pub fn map_y_bias_from_world_y(y : Int) -> Int {
  clamp_map_y_bias(y)
}

///|
/// 计算静态 map obj 的 z.
pub fn map_obj_z(layer : Int, z : Int, zM : Int) -> Int {
  compose_map_z(layer, MAP_PASS_OBJ, map_obj_local(z, zM), 0)
}

///|
/// 计算静态 map tile 的 z.
pub fn map_tile_z(layer : Int, zM : Int) -> Int {
  compose_map_z(layer, MAP_PASS_TILE, map_tile_local(zM), 0)
}

///|
/// 计算 npc z.
pub fn map_npc_z(layer : Int, world_y : Int) -> Int {
  compose_map_z(layer, MAP_PASS_NPC, 0, map_y_bias_from_world_y(world_y))
}

///|
/// 计算 mob z.
pub fn map_mob_z(layer : Int, world_y : Int) -> Int {
  compose_map_z(layer, MAP_PASS_MOB, 0, map_y_bias_from_world_y(world_y))
}

///|
/// 计算玩家 z.
pub fn map_player_z(layer : Int, world_y : Int) -> Int {
  compose_map_z(layer, MAP_PASS_PLAYER, 0, map_y_bias_from_world_y(world_y))
}

///|
/// 计算掉落物 z.
pub fn map_drop_z(layer : Int, world_y : Int) -> Int {
  compose_map_z(layer, MAP_PASS_DROP, 0, map_y_bias_from_world_y(world_y))
}

///|
pub const CHAR_LOOK_ZINDEX = 70000

///|
pub const DAMAGE_NUMBER_ZINDEX = 75000

///|
pub const MOB_HP_BAR_ZINDEX = 74000

///|
pub const DROP_LAYER_ZINDEX = 76000

///|
pub const PORTAL_ZINDEX = 79000

///|
pub const FOREGROUND_ZINDEX = 80000

///|
pub const EFFECT_ZINDEX = 90000

///|
pub const UI_ZINDEX = 100000

///|
pub const MINI_MAP_ZINDEX_ = 101000

///|
pub const CURSOR_ZINDEX : Int = 200000

///|
/// 地图场景的层级. 用于组织地图瓦片和物品的渲染顺序.
pub let map_layers : FixedArray[Int] = [0, 1, 2, 3, 4, 5, 6, 7]

///|
test "map dynamic pass order is stable on same layer and y" {
  let layer = 3
  let y = 120
  let npc = map_npc_z(layer, y)
  let mob = map_mob_z(layer, y)
  let player = map_player_z(layer, y)
  let drop = map_drop_z(layer, y)
  inspect(npc < mob, content="true")
  inspect(mob < player, content="true")
  inspect(player < drop, content="true")
}

///|
test "map static and dynamic order follows formula lane" {
  let layer = 1
  let obj = map_obj_z(layer, 10, 0)
  let tile = map_tile_z(layer, 10)
  let npc = map_npc_z(layer, 10)
  let mob = map_mob_z(layer, 10)
  let player = map_player_z(layer, 10)
  let drop = map_drop_z(layer, 10)
  inspect(obj < tile, content="true")
  inspect(tile < npc, content="true")
  inspect(npc < mob, content="true")
  inspect(mob < player, content="true")
  inspect(player < drop, content="true")
}
