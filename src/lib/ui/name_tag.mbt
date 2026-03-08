///|
struct NameTag {
  name : @graphics.OutlinedText
  textures : @utils.BoolPair[
    (@sprite.AnimationFrame, @sprite.AnimationFrame, @sprite.AnimationFrame),
  ]
  mut selected : Bool
}

///|
pub(all) struct NameTagResource {
  not_selected : (@resource.NxFrame, @resource.NxFrame, @resource.NxFrame)
  selected : (@resource.NxFrame, @resource.NxFrame, @resource.NxFrame)
}

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
      {
        not_selected: (
          @resource.NxFrame::from_json(j00, path.add_key("0").add_key("0")),
          @resource.NxFrame::from_json(j01, path.add_key("0").add_key("1")),
          @resource.NxFrame::from_json(j02, path.add_key("0").add_key("2")),
        ),
        selected: (
          @resource.NxFrame::from_json(j10, path.add_key("1").add_key("0")),
          @resource.NxFrame::from_json(j11, path.add_key("1").add_key("1")),
          @resource.NxFrame::from_json(j12, path.add_key("1").add_key("2")),
        ),
      }
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
  let textures = @utils.BoolPair::new(
    (
      nx_frame_to_animation_frame(textures.not_selected.0),
      nx_frame_to_animation_frame(textures.not_selected.1),
      nx_frame_to_animation_frame(textures.not_selected.2),
    ),
    (
      nx_frame_to_animation_frame(textures.selected.0),
      nx_frame_to_animation_frame(textures.selected.1),
      nx_frame_to_animation_frame(textures.selected.2),
    ),
  )
  { name, textures, selected: false }
}

///|
pub impl @graphics.Drawable for NameTag with draw(
  _self : NameTag,
  _args : @graphics.DrawArgument,
) -> Unit {
  // let position = args.pos + { x: 1, y: 2 }
  // let (t1, t2, t3) = self.textures[self.selected]
  // let width = self.name.width()
  // let startpos = position - { x: 6 + width / 2, y: -1 }
  // t1.draw({ ..args, pos: startpos })
  // t2.draw({
  //   ..args,
  //   pos: startpos + { x: 6, y: 0 },
  //   stretch: { x: width, y: 0 },
  // })
  // t3.draw({ ..args, pos: startpos + { x: width + 6, y: 0 } })
  // self.name.draw(position)
}

///|
pub fn NameTag::set_selected(self : NameTag, s : Bool) -> Unit {
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

///|
fn nx_frame_to_animation_frame(
  frame : @resource.NxFrame,
) -> @sprite.AnimationFrame {
  {
    image: @asset.load_image(frame.texture.i),
    size: @selene_math.Vec2D(
      frame.texture.w.to_double(),
      frame.texture.h.to_double(),
    ),
    offset: @selene_math.Vec2D(
      frame.texture.offset.x.to_double(),
      frame.texture.offset.y.to_double(),
    ),
    pivot: @selene_math.Vec2D(
      frame.texture.origin.x.to_double(),
      frame.texture.origin.y.to_double(),
    ),
    duration: 0.0,
  }
}
