///|
/// 表示地图中的一个 Tile, 保存纹理以及静态位置数据。
struct Tile {
  texture : @resource.NxTexture?
  pos : Point[Int]
  z : Int
  layer : Int
  resource_index : Int
}

///|
pub struct NxTileSet {
  groups : Map[String, Array[NxTile]]
}

///|
pub struct NxTile {
  texture : @resource.NxTexture
  z : Int
  zm : Int?
}

///|
pub impl @json.FromJson for NxTile with from_json(json, path) {
  let zm = if json is { "zM": Number(zm, ..), .. } {
    Some(zm.to_int())
  } else {
    None
  }
  let texture = @json.from_json(json, path~)
  match json {
    { "z": Number(z, ..), .. } => { texture, z: z.to_int(), zm }
    _ => raise @json.JsonDecodeError((path, "missing tile fields"))
  }
}

///|
pub impl @json.FromJson for NxTileSet with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expected object"))
  }
  let groups = Map::new(capacity=obj.length())
  for name, tiles in obj {
    guard tiles is { "0": _, .. } else { continue }
    let tiles = @resource.parse_map_based_array(tiles, path=path.add_key(name))
    groups[name] = tiles
  }
  { groups, }
}

///|
pub fn Tile::new(
  tile : NxTileRef,
  tileset : NxTileSet?,
  layer : Int,
  resource_index : Int,
) -> Tile {
  let pos = @struct.Point::new(tile.x, tile.y)
  guard tileset is Some(tileset) else {
    return { texture: None, pos, z: 0, layer, resource_index }
  }
  let src_u = tile.u
  let dsrc = tileset.groups[src_u][tile.no]
  let z = if dsrc.z == 0 && dsrc.zm is Some(zm) { zm } else { dsrc.z }
  { texture: Some(dsrc.texture), pos, z, layer, resource_index }
}

///|
/// 将 Tile 的纹理绑定到传入的实体上，若纹理缺失则移除该实体的 sprite。
/// - `entity`: 需要绑定 sprite 的实体。
/// - `z_offset`: z 值偏移量，用于计算最终的 z 值。
pub fn Tile::attach_entity(
  self : Tile,
  entity : @entity.Entity,
  z_offset : Int,
) -> Unit {
  guard self.texture is Some(texture) else {
    @sprite.sprites().remove(entity)
    return
  }
  let animation = nx_animation_to_selene_animation(@resource.NxAnimation::{
    frames: [
      @resource.NxFrame::{ texture, delay: None, head: None, bounds: None },
    ],
    blend: false,
    zigzag: false,
  })
  let sprite = @sprite.Sprite::from_animation(animation, self.z + z_offset)
  @sprite.sprites().set(entity, sprite)
  @position.positions().set(
    entity,
    @position.Position(
      @selene_math.Vec2D(self.pos.x.to_double(), self.pos.y.to_double()),
    ),
  )
}
