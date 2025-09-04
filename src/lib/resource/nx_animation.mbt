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
} derive (
  FromJson(
    fields(
      i(rename="__i"),
      w(rename="__w"),
      h(rename="__h"),
      offset(rename="__off"),
    ),
  ),
)

///|
pub(all) struct NxFrame {
  texture : NxTexture
}

///|
pub impl @json.FromJson for NxFrame with from_json(json, path) -> NxFrame raise @json.JsonDecodeError {
  let texture = @json.from_json(json, path~)
  { texture, }
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
