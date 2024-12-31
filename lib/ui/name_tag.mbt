///|
struct NameTag {
  name : @graphics.OutlinedText
  textures : @utils.BoolPair[
    (@graphics.Texture, @graphics.Texture, @graphics.Texture),
  ]
  mut selected : Bool
}

///|
pub(all) type NameTagResource (
  (@graphics.Texture, @graphics.Texture, @graphics.Texture),
  (@graphics.Texture, @graphics.Texture, @graphics.Texture),
) derive(Default)

///|
pub fn NameTagResource::from_resource(
  src : @resource.NxNode
) -> NameTagResource {
  (
    (
      src["0"]["0"] |> @graphics.Texture::from_resource,
      src["0"]["1"] |> @graphics.Texture::from_resource,
      src["0"]["2"] |> @graphics.Texture::from_resource,
    ),
    (
      src["1"]["0"] |> @graphics.Texture::from_resource,
      src["1"]["1"] |> @graphics.Texture::from_resource,
      src["1"]["2"] |> @graphics.Texture::from_resource,
    ),
  )
}

///|
pub fn NameTag::new(
  f : @graphics.FontId,
  n : String,
  textures : NameTagResource
) -> NameTag {
  let name = @graphics.OutlinedText::new(
    f,
    @graphics.TextAlignment::CENTER,
    @struct.ColorName::EAGLE,
    @struct.ColorName::JAMBALAYA,
  )
  name.change_text(n)
  let textures = @utils.BoolPair::new(textures._.0, textures._.1)
  { name, textures, selected: false }
}

///|
pub impl @graphics.Drawable for NameTag with draw(
  self : NameTag,
  args : @graphics.DrawArgument
) -> Unit {
  let position = args.pos + { x: 1, y: 2 }
  let (t1, t2, t3) = self.textures[self.selected]
  let width = self.name.width()
  let startpos = position - { x: 6 + width / 2, y: -1 }
  t1.draw({ ..args, pos: startpos })
  t2.draw({
    ..args,
    pos: startpos + { x: 6, y: 0 },
    stretch: { x: width, y: 0 },
  })
  t3.draw({ ..args, pos: startpos + { x: width + 6, y: 0 } })
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

///|
pub impl ToJson for NameTag with to_json(self) -> Json {
  { "name": self.name.to_json(), "selected": self.selected.to_json() }
}
