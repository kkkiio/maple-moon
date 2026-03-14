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
  rows? : Int = 1,
  cols? : Int = 1,
  row_height? : Int = texture.get_dimensions().y,
  col_width? : Int = texture.get_dimensions().x,
) -> TileUnit {
  { texture, rows, cols, row_height, col_width }
}
