///|
using @struct {type Point, type Rectangle}

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
} derive(Show)

///|
pub impl @json.FromJson for NxTexture with from_json(json, path) -> NxTexture raise @json.JsonDecodeError {
  guard json
    is { "__i": String(i), "__w": Number(w, ..), "__h": Number(h, ..), .. } else {
    raise @json.JsonDecodeError((path, "invalid nx texture=\{json}"))
  }
  if i.contains("#") {
    raise @json.JsonDecodeError(
      (path, "invalid '#'-framed syntax: \{i}, set offset if using spritesheet"),
    )
  }
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
  /// 帧显示时长（毫秒），None 表示使用默认值 100ms 或静态帧
  delay : Int?
  /// 怪物/角色头部位置，用于计算名牌显示位置、伤害数字位置等
  head : Point[Int]?
  /// 碰撞检测边界框 (lt: 左上角, rb: 右下角)，用于判断攻击范围
  bounds : Rectangle[Int]?
} derive(Show)

///|
pub impl @json.FromJson for NxFrame with from_json(json, path) -> NxFrame raise @json.JsonDecodeError {
  let texture = @json.from_json(json, path~)
  let delay = match json {
    { "delay": Number(delay, ..), .. } => Some(delay.to_int())
    _ => None
  }
  let head = match json {
    { "head": head, .. } =>
      Some(@json.from_json(head, path=path.add_key("head"))) catch {
        _ => None
      }
    _ => None
  }
  let bounds = if json is { "lt": _, "rb": _, .. } {
    Some(@json.from_json(json, path~))
  } else {
    None
  }
  { texture, delay, head, bounds }
}

///|
pub(all) struct NxAnimation {
  frames : Array[NxFrame]
  blend : Bool
  zigzag : Bool
} derive(Show)

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
pub(all) struct NxPictureSpec {
  image : @asset.ImageHandle
  rect : @selene_math.Rect
  size : @selene_math.Vec2D
  origin : @selene_math.Vec2D
  repeat : @selene_math.RepeatMode
  flip_x : Bool
}

///|
pub(all) struct NxAnimationStep {
  image : @asset.ImageHandle
  rect : @selene_math.Rect
  size : @selene_math.Vec2D
  origin : @selene_math.Vec2D
  duration : Double
}

///|
pub(all) struct NxAnimationPlayable {
  steps : Array[NxAnimationStep]
  loop_ : Bool
  native_eligible : Bool
}

///|
fn resolve_asset_image_path(path : String) -> String {
  if path.has_prefix("/") {
    path
  } else if path.has_prefix("assets/") {
    "/" + path
  } else {
    "/assets/" + path
  }
}

///|
pub fn nx_texture_to_picture_spec(
  texture : NxTexture,
  size? : @selene_math.Vec2D,
  repeat? : @selene_math.RepeatMode = NoRepeat,
  flip_x? : Bool = false,
) -> NxPictureSpec {
  guard repeat is NoRepeat || texture.offset is { x: 0, y: 0 } else {
    abort("tiled texture in spritesheet is not supported")
  }
  let resolved_size : @selene_math.Vec2D = size.unwrap_or(
    @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
  )
  let rect : @selene_math.Rect = {
    position: @selene_math.Vec2D(
      texture.offset.x.to_double(),
      texture.offset.y.to_double(),
    ),
    size: @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
  }
  {
    image: @asset.load_image(resolve_asset_image_path(texture.i)),
    rect,
    size: resolved_size,
    origin: @selene_math.Vec2D(
      texture.origin.x.to_double(),
      texture.origin.y.to_double(),
    ),
    repeat,
    flip_x,
  }
}

///|
pub fn nx_animation_to_playable(
  src : NxAnimation,
  loop_? : Bool = false,
) -> NxAnimationPlayable {
  let steps : Array[NxAnimationStep] = []
  for frame in src.frames {
    let delay_ms = match frame.delay {
      Some(d) => if d <= 0 { 100 } else { d }
      None => 100
    }
    let texture = frame.texture
    steps.push({
      image: @asset.load_image(resolve_asset_image_path(texture.i)),
      rect: {
        position: @selene_math.Vec2D(
          texture.offset.x.to_double(),
          texture.offset.y.to_double(),
        ),
        size: @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
      },
      size: @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
      origin: @selene_math.Vec2D(
        texture.origin.x.to_double(),
        texture.origin.y.to_double(),
      ),
      duration: delay_ms.to_double() / 1000.0,
    })
  }
  let effective_steps = if src.zigzag && steps.length() > 2 {
    let expanded = steps.copy()
    for i = steps.length() - 2; i >= 1; i = i - 1 {
      expanded.push(steps[i])
    }
    expanded
  } else {
    steps
  }
  {
    steps: effective_steps,
    loop_,
    native_eligible: is_native_eligible(effective_steps),
  }
}

///|
fn is_native_eligible(steps : Array[NxAnimationStep]) -> Bool {
  guard steps.length() > 0 else { return false }
  let first = steps[0]
  for step in steps {
    if step.image != first.image {
      return false
    }
    if step.size != first.size {
      return false
    }
    if step.origin != first.origin {
      return false
    }
  }
  true
}
