///|
struct TileUnit {
  texture : Texture
  rows : Int
  cols : Int
  row_height : Int
  col_width : Int
} derive(ToJson)

///|
pub fn TileUnit::new(
  texture : Texture,
  rows~ : Int = 1,
  cols~ : Int = 1,
  row_height~ : Int = texture.get_dimensions().y,
  col_width~ : Int = texture.get_dimensions().x
) -> TileUnit {
  { texture, rows, cols, row_height, col_width }
}

///|
pub impl Drawable for TileUnit with draw(self : TileUnit, args : DrawArgument) -> Unit {
  for row in 0..<self.rows {
    for col in 0..<self.cols {
      self.texture.draw({
        ..args,
        pos: args.pos +
        @struct.Point::new(col * self.col_width, row * self.row_height),
      })
    }
  }
}
