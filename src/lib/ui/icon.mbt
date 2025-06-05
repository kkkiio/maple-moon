///|
pub(all) struct IconModel {
  countset : @graphics.Charset
  mut count : Int?
  mut dragged : Bool
  mut cursor_offset : @struct.Point[Int]
} derive(ToJson)

///|
pub fn IconModel::new(countset : @graphics.Charset, count : Int?) -> IconModel {
  { countset, count, dragged: false, cursor_offset: @struct.Point::default() }
}

///|
pub fn IconModel::draw(
  self : IconModel,
  position : @struct.Point[Int],
  texture : @graphics.Texture
) -> Unit {
  let opacity = if self.dragged { 0.5 } else { 1.0 }
  texture.draw(@graphics.DrawArgument::new7(position.shift_y(32), opacity))
  match self.count {
    Some(count) =>
      self.countset.draw_text(
        count.to_string(),
        @graphics.DrawArgument::new(pos=position + @struct.Point::new(0, 20)),
      )
      |> ignore
    None => ()
  }
}

///|
pub fn IconModel::get_bounds(
  texture : @graphics.Texture
) -> @struct.Rectangle[Int] {
  let lt = @struct.Point::new(0, 32) - texture.origin
  let rb = lt + texture.dimensions
  @struct.Rectangle::new(lt, rb)
}
