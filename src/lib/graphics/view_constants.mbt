///|
pub let view_size : (Int, Int) = (1366, 768) // Fixed to 1366x768

///|
pub let fps : UInt = 60

///|
pub const BACKGROUND_ZINDEX = 1

///|
/// 地图物品和瓦片的 z 值起始点.
pub const OBJECT_TILE_LAYER_ZINDEX = 30

///|
pub const CHAR_LOOK_ZINDEX = 70

///|
pub const PORTAL_ZINDEX = 79

///|
pub const FOREGROUND_ZINDEX = 80

///|
pub const UI_ZINDEX = 100

///|
pub const MINI_MAP_ZINDEX_ = 101

///|
/// 地图场景的层级. 用于组织地图瓦片和物品的渲染顺序.
pub let map_layers : FixedArray[Int] = [0, 1, 2, 3, 4, 5, 6, 7]
