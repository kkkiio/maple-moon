///|
pub(all) struct RenderSpec {
  drawables : Array[&Drawable]
  statefuls : Array[&Stateful]
}

///|
pub impl ToJson for RenderSpec with to_json(self) -> Json {
  { "drawables": self.drawables.to_json() }
}

///|
pub(open) trait Drawable: ToJson {
  draw(Self, DrawArgument) -> Unit
}

///|
pub(open) trait Stateful: ToJson {
  update(Self, Int) -> Unit
}
