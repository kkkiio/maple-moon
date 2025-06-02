///| Represents a tile on a map.
struct Tile {
  texture : @graphics.Texture
  pos : Point[Int]
  z : Int
}

///|
pub fn Tile::new(tile : TileResource, tileset : @resource.NxNode?) -> Tile {
  let pos = @struct.Point::new(tile.x, tile.y)
  guard tileset is Some(tileset) else {
    return { texture: @graphics.Texture::default(), pos, z: 0 }
  }
  let src_u = tile.u
  let src_no = tile.no.to_string()
  let dsrc = tileset[src_u][src_no]
  let mut z = dsrc["z"].get_int?().unwrap()
  if z == 0 {
    z = dsrc["zM"].get_int?().unwrap()
  }
  { texture: @graphics.Texture::from_resource(dsrc), pos, z }
}

///|
pub fn Tile::draw(self : Tile, viewpos : Point[Int]) -> Unit {
  self.texture.draw(@graphics.DrawArgument::new(pos=self.pos + viewpos))
}

///|
pub fn Tile::get_z(self : Tile) -> Int {
  self.z
}

///|
let tile_loader : @resource.AsyncLoader = @resource.AsyncLoader::new("tile")
