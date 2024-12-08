///| Represents a tile on a map.
struct Tile {
  texture : @graphics.Texture
  pos : Point[Int]
  z : Int
}

///|
pub fn Tile::new(src : NxNode, tileset : @resource.NxNode?) -> Tile {
  let pos = Point::new(
    src["x"].get_int?().unwrap(),
    src["y"].get_int?().unwrap(),
  )
  guard let Some(tileset) = tileset else {
    None => return { texture: @graphics.Texture::default(), pos, z: 0 }
  }
  let src_u = src["u"].as_string?().unwrap()
  let src_no = src["no"].get_string()
  let dsrc = tileset[src_u][src_no]
  let mut z = dsrc["z"].get_int?().unwrap()
  if z == 0 {
    z = dsrc["zM"].get_int?().unwrap()
  }
  { texture: @graphics.Texture::from_resource(dsrc), pos, z }
}

///|
pub fn draw(self : Tile, viewpos : Point[Int]) -> Unit {
  self.texture.draw(@graphics.DrawArgument::new(self.pos + viewpos))
}

///|
pub fn get_z(self : Tile) -> Int {
  self.z
}

///|
let tile_loader : @resource.AsyncLoader = @resource.AsyncLoader::new("tile")
