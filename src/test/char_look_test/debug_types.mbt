///|
pub(all) struct TestSprite(@sprite.Sprite)

///|
pub impl ToJson for TestSprite with to_json(self) {
  let r : Map[String, Json] = {
    "sprite_type": match self.sprite_type {
      @sprite.SpriteType::Picture(picture) => ...
      @sprite.SpriteType::Animation(animation, frame~, ..) =>
        ["Animation", TestAnimation(animation).to_json(), frame]
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
pub(all) struct TestAnimation(@sprite.Animation)

///|
pub impl ToJson for TestAnimation with to_json(self) {
  let r : Map[String, Json] = {
    "frames": self.frames.map(fn(f) -> Json {
      let r : Map[String, Json] = {
        "sprite_path": f.sprite_path,
        "size": [f.size.0, f.size.1],
      }
      if f.offset != @math.Vec2D::zero() {
        r["offset"] = [f.offset.0, f.offset.1]
      }
      if f.pivot != @math.Vec2D::zero() {
        r["pivot"] = [f.pivot.0, f.pivot.1]
      }
      Json::object(r)
    }),
    "loop_": self.loop_,
  }
  if self.transform is { a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 0.0, ty: 0.0 } {

  } else {
    r["transform"] = {
      "a": self.transform.a,
      "b": self.transform.b,
      "c": self.transform.c,
      "d": self.transform.d,
      "tx": self.transform.tx,
      "ty": self.transform.ty,
    }
  }
  Json::object(r)
}
