///|
struct NameTag {
  name : @graphics.OutlinedText
  textures : @utils.BoolPair[Array[@graphics.Texture]]
  mut selected : Bool
}

///|
pub fn NameTag::new(
  src : @resource.NxNode,
  f : @graphics.FontId,
  n : String
) -> NameTag {
  let name = @graphics.OutlinedText::new(
    f,
    @graphics.TextAlignment::CENTER,
    @struct.ColorName::EAGLE,
    @struct.ColorName::JAMBALAYA,
  )
  name.change_text(n)
  let textures = @utils.BoolPair::new(Array::new(), Array::new())
  textures[false].push(src["0"]["0"] |> @graphics.Texture::from_resource)
  textures[false].push(src["0"]["1"] |> @graphics.Texture::from_resource)
  textures[false].push(src["0"]["2"] |> @graphics.Texture::from_resource)
  textures[true].push(src["1"]["0"] |> @graphics.Texture::from_resource)
  textures[true].push(src["1"]["1"] |> @graphics.Texture::from_resource)
  textures[true].push(src["1"]["2"] |> @graphics.Texture::from_resource)
  { name, textures, selected: false }
}

///|
pub fn draw(self : NameTag, position : Point[Int]) -> Unit {
  let position = position + { x: 1, y: 2 }
  let tag = self.textures[self.selected]
  let width = self.name.width()
  let startpos = position - { x: 6 + width / 2, y: -1 }
  tag[0].draw(startpos |> @graphics.DrawArgument::new)
  tag[1].draw(
    @graphics.DrawArgument::new4(startpos + { x: 6, y: 0 }, { x: width, y: 0 }),
  )
  tag[2].draw(@graphics.DrawArgument::new(startpos + { x: width + 6, y: 0 }))
  self.name.draw(position)
}

///|
pub fn set_selected(self : NameTag, s : Bool) -> Unit {
  self.selected = s
  if s {
    self.name.change_color(@struct.ColorName::WHITE)
  } else {
    self.name.change_color(@struct.ColorName::EAGLE)
  }
}
