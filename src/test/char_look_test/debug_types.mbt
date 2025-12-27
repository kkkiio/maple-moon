///|
pub(all) struct DebugSprite(@sprite.Sprite)

///|
pub impl ToJson for DebugSprite with to_json(self) {
  let r : Map[String, Json] = {
    "draw": match self.sprite_type {
      @sprite.SpriteType::Picture(picture) => ...
      @sprite.SpriteType::Animation(animation, frame~, ..) =>
        ["Animation", DebugAnimation(animation, frame).to_json()]
      @sprite.SpriteType::Text(text) => ...
      @sprite.SpriteType::ColorRect(color_rect) => ...
      @sprite.SpriteType::ColorCircle(color_circle) => ...
    },
    "zindex": self.zindex,
    "visible": self.visible,
  }
  if self.offset != @math.Vec2D::zero() {
    r["offset"] = [self.offset.0, self.offset.1]
  }
  Json::object(r)
}

///|
pub(all) struct DebugAnimation(@sprite.Animation, Int)

///|
pub impl ToJson for DebugAnimation with to_json(self) {
  let animation = self.0
  let frame = self.1
  let r : Map[String, Json] = {
    "current": DebugFrame(animation.frames[frame]).to_json(),
    "loop_": animation.loop_,
  }
  let transform = animation.transform
  if transform is { a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 0.0, ty: 0.0 } {

  } else {
    r["transform"] = {
      "a": transform.a,
      "b": transform.b,
      "c": transform.c,
      "d": transform.d,
      "tx": transform.tx,
      "ty": transform.ty,
    }
  }
  Json::object(r)
}

///|
pub(all) struct DebugFrame(@sprite.AnimationFrame)

///|
pub impl ToJson for DebugFrame with to_json(self) {
  let r : Map[String, Json] = {
    "sprite_path": self.sprite_path,
    "size": [self.size.0, self.size.1],
  }
  if self.offset != @math.Vec2D::zero() {
    r["offset"] = [self.offset.0, self.offset.1]
  }
  if self.pivot != @math.Vec2D::zero() {
    r["pivot"] = [self.pivot.0, self.pivot.1]
  }
  Json::object(r)
}
