///|
pub(all) struct NxTexture {
  /// File path to the sprite sheet image containing this frame.
  i : String
  w : Int
  h : Int
  /// 图片在 spritesheet 里的偏移量, 相对于 spritesheet 左上角的位置.
  offset : Point[Int]
  /// 图片的坐标原点, 相对于图片左上角的位置.
  /// 绘制sprite时, sprite的位置是与origin重合的, 再根据width和height确定绘制范围.
  /// 翻转x轴时, 是以origin.x为对称轴, 翻转x轴.
  /// ```mbt
  /// let t = NxTexture::{
  ///     i: "/assets/character/body/male_1_white_face.png",
  ///     w: 39,
  ///     h: 35,
  ///     offset: {x: 41, y: 0},
  ///     origin: {x: 19, y: 17},
  /// }
  /// let sprite_pos : @struct.Point[Int] = {x: 100, y: 100}
  /// let left_top = sprite_pos - t.origin
  /// ignore(left_top)
  /// ```
  origin : Point[Int]
}

///|
pub impl @json.FromJson for NxTexture with from_json(json, path) -> NxTexture raise @json.JsonDecodeError {
  guard json
    is { "__i": String(i), "__w": Number(w, ..), "__h": Number(h, ..), .. } else {
    raise @json.JsonDecodeError((path, "invalid nx texture=\{json}"))
  }
  let i = i
  let w = w.to_int()
  let h = h.to_int()
  let offset = if json is { "__off": [Number(offx, ..), Number(offy, ..)], .. } {
    Point::new(offx.to_int(), offy.to_int())
  } else {
    Point::default()
  }
  let origin = if json
    is { "origin": [Number(originx, ..), Number(originy, ..)], .. } {
    Point::new(originx.to_int(), originy.to_int())
  } else {
    Point::default()
  }
  { i, w, h, offset, origin }
}

///|
pub fn NxTexture::get_size(self : NxTexture) -> (Int, Int) {
  (self.w, self.h)
}

///|
pub(all) struct NxFrame {
  texture : NxTexture
  delay : Int?
}

///|
pub impl @json.FromJson for NxFrame with from_json(json, path) -> NxFrame raise @json.JsonDecodeError {
  let texture = @json.from_json(json, path~)
  let delay = match json {
    { "delay": Number(delay, ..), .. } => Some(delay.to_int())
    _ => None
  }
  { texture, delay }
}

///|
pub(all) struct NxAnimation {
  frames : Array[NxFrame]
  blend : Bool
  zigzag : Bool
}

///|
/// animation is a map based array or a single frame
pub impl @json.FromJson for NxAnimation with from_json(json, path) -> NxAnimation raise @json.JsonDecodeError {
  let frames = if json is { "0": _, .. } {
    parse_map_based_array(json, path~)
  } else {
    [@json.from_json(json, path~)]
  }
  let blend = json is { "blend": Number(1, ..), .. }
  let zigzag = json is { "zigzag": Number(1, ..), .. }
  { frames, blend, zigzag }
}

///|
pub fn NxAnimation::get_size(self : NxAnimation) -> (Int, Int) {
  let texture = self.frames[0].texture
  (texture.w, texture.h)
}

///|
using @struct {type Point}
