///|
pub(all) struct DebugSprite(@sprite.Sprite)

///|
pub impl ToJson for DebugSprite with to_json(self) {
  let r : Map[String, Json] = {
    "draw": match self.sprite_type {
      @sprite.SpriteType::Picture(picture) =>
        [
          "Picture",
          {
            "size": [picture.size.0, picture.size.1],
            "tile_path": @asset.image_path(picture.image).unwrap_or(""),
            "transform": {
              "a": picture.transform.a,
              "b": picture.transform.b,
              "c": picture.transform.c,
              "d": picture.transform.d,
              "tx": picture.transform.tx,
              "ty": picture.transform.ty,
            },
            "repeat": picture.repeat.to_string().to_json(),
          },
        ]
      @sprite.SpriteType::Animation(animation, frame~, ..) =>
        ["Animation", DebugAnimation(animation, frame).to_json()]
      @sprite.SpriteType::Text(text) => ["Text", Json::string(text.content)]
      @sprite.SpriteType::ColorRect(_) => ["ColorRect", Json::null()]
      @sprite.SpriteType::ColorCircle(_) => ["ColorCircle", Json::null()]
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
  // Note: transform is now at Sprite level, not Animation level
  Json::object(r)
}

///|
pub(all) struct DebugFrame(@sprite.AnimationFrame)

///|
pub impl ToJson for DebugFrame with to_json(self) {
  let r : Map[String, Json] = {
    "sprite_path": @asset.image_path(self.image).unwrap_or(""),
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
