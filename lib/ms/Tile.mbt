/// Represents a tile on a map.
struct Tile {
  texture : @graphics.Texture
  pos : Point[Int]
  z : Int
}

pub fn Tile::from_resource(src : NxNode, tileset : String) -> Tile {
  let map_loader = map_loader()
  let src_u = src["u"].as_string().unwrap()
  let src_no = src["no"].get_string()
  let dsrc = map_loader.load_res(["Tile", tileset, src_u, src_no])
  let mut z = dsrc["z"].get_int?().unwrap()
  if z == 0 {
    z = dsrc["zM"].get_int?().unwrap()
  }
  {
    texture: @graphics.Texture::from_resource(dsrc),
    pos: Point::new(src["x"].get_int?().unwrap(), src["y"].get_int?().unwrap()),
    z,
  }
}

pub fn draw(self : Tile, viewpos : Point[Int]) -> Unit {
  self.texture.draw(DrawArgument::from_point(self.pos + viewpos))
}

pub fn get_z(self : Tile) -> Int {
  self.z
}
