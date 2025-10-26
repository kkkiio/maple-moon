///|
pub(all) struct NxTexture {
  /// File path to the sprite sheet image containing this frame.
  i : String
  w : Int
  h : Int
  /// Pixel offset within the sprite sheet where this frame is located.
  offset : @struct.Point[Int]
  /// Coordinate of the drawing origin within the image. In other words, distance from the top-left corner of the image.
  origin : @struct.Point[Int]
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
    @struct.Point::new(offx.to_int(), offy.to_int())
  } else {
    @struct.Point::default()
  }
  let origin = if json
    is { "origin": [Number(originx, ..), Number(originy, ..)], .. } {
    @struct.Point::new(originx.to_int(), originy.to_int())
  } else {
    @struct.Point::default()
  }
  { i, w, h, offset, origin }
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
