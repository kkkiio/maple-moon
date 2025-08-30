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
  (@graphics.NxFrame, @graphics.NxFrame, @graphics.NxFrame),
  (@graphics.NxFrame, @graphics.NxFrame, @graphics.NxFrame),
)

///|
pub impl @json.FromJson for NameTagResource with from_json(
  src : Json,
  path : @json.JsonPath,
) -> NameTagResource {
  match src {
    {
      "0": { "0": j00, "1": j01, "2": j02, .. },
      "1": { "0": j10, "1": j11, "2": j12, .. },
      ..
    } =>
      (
        (
          @graphics.NxFrame::from_json(j00, path.add_key("0").add_key("0")),
          @graphics.NxFrame::from_json(j01, path.add_key("0").add_key("1")),
          @graphics.NxFrame::from_json(j02, path.add_key("0").add_key("2")),
        ),
        (
          @graphics.NxFrame::from_json(j10, path.add_key("1").add_key("0")),
          @graphics.NxFrame::from_json(j11, path.add_key("1").add_key("1")),
          @graphics.NxFrame::from_json(j12, path.add_key("1").add_key("2")),
        ),
      )
    _ => raise @json.JsonDecodeError((path, "invalid name tag resource"))
  }
}

///|
pub fn NameTag::new(
  f : @graphics.FontId,
  n : String,
  textures : NameTagResource,
) -> NameTag {
  let name = @graphics.OutlinedText::new(
    f,
    @graphics.TextAlignment::CENTER,
    @struct.ColorName::EAGLE,
    @struct.ColorName::JAMBALAYA,
  )
  name.change_text(n)
  let textures = @utils.BoolPair::new(textures.inner().0, textures.inner().1)
  ...
  // { name, textures, selected: false }
}

///|
pub impl @graphics.Drawable for NameTag with draw(
  self : NameTag,
  args : @graphics.DrawArgument,
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
