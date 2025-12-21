///|
pub const BACKGROUND_ZINDEX = 1000

///|
/// 地图物品和瓦片的 z 值起始点.
pub const OBJECT_TILE_LAYER_ZINDEX = 30000

///|
pub const CHAR_LOOK_ZINDEX = 70000

///|
pub const DAMAGE_NUMBER_ZINDEX = 75000

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
