///|
/// Represents a tile on a map.
struct Tile {
  entity : @entity.Entity
  texture : @resource.NxTexture?
  pos : Point[Int]
  z : Int
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
pub fn Tile::new(tile : NxTileRef, tileset : NxTileSet?) -> Tile {
  let entity = @entity.Entity::new()
  let pos = @struct.Point::new(tile.x, tile.y)
  guard tileset is Some(tileset) else {
    return { entity, texture: None, pos, z: 0 }
  }
  let src_u = tile.u
  let dsrc = tileset.groups[src_u][tile.no]
  let z = if dsrc.z == 0 && dsrc.zm is Some(zm) { zm } else { dsrc.z }
  { entity, texture: Some(dsrc.texture), pos, z }
}

///|
pub fn Tile::set_sprites(self : Tile) -> Unit {
  guard self.texture is Some(texture) else { return }
  let animation = @graphics.nx_animation_to_selene_animation(@resource.NxAnimation::{
    frames: [@resource.NxFrame::{ texture, delay: None }],
    blend: false,
    zigzag: false,
  })
  let sprite = @sprite.Sprite::from_animation(
    animation,
    self.z + @graphics.SCENE_ZINDEX,
  )
  @sprite.sprites.set(self.entity, sprite)
  @position.positions.set(
    self.entity,
    @position.Position(
      @selene_math.Vec2D(self.pos.x.to_double(), self.pos.y.to_double()),
    ),
  )
}
