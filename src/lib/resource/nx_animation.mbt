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
      (path, "\{i} still uses '#'-framed __i, reanim output expected"),
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
pub fn nx_animation_to_selene_animation(
  src : NxAnimation,
  loop_? : Bool = false,
) -> @sprite.Animation {
  // Extract all delays
  let delays = src.frames.map(fn(frame) {
    match frame.delay {
      Some(d) => if d <= 0 { 100 } else { d }
      None => 100
    }
  })

  // Handle zigzag: extend delays and maintain mapping to original indices
  let (effective_delays, index_map) = if src.zigzag && delays.length() > 2 {
    let extended = delays.copy()
    let mapping = Array::make(delays.length(), 0)
    for i = 0; i < delays.length(); i = i + 1 {
      mapping[i] = i
    }

    // Append reversed inner frames: N-2 down to 1
    let len = delays.length()
    for i = len - 2; i >= 1; i = i - 1 {
      extended.push(delays[i])
      mapping.push(i)
    }
    (extended, mapping)
  } else {
    let mapping = Array::make(delays.length(), 0)
    for i = 0; i < delays.length(); i = i + 1 {
      mapping[i] = i
    }
    (delays, mapping)
  }

  // Create frames explicitly with duration
  let frames = index_map.mapi(fn(i, original_index) {
    let frame = src.frames[original_index]
    let delay_ms = effective_delays[i]
    @sprite.AnimationFrame::{
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
      duration: delay_ms.to_double() / 1000.0,
    }
  })

  // Note: transform is set at Sprite level.
  @sprite.Animation::new(frames, loop_~)
}

///|
/// 将 Nx 资源中的单帧贴图转换为 Selene 的 `@sprite.Picture`, 自动套用 `origin`
/// 信息以确保实体位置与 Nx 定义的参考点一致。
///
/// Parameters:
/// * `texture` : 解析后的 Nx 贴图数据, 包含尺寸、原点与图片路径。
/// * `size` : 可选的绘制尺寸, 不传时默认使用贴图自身宽高。
/// * `repeat` : 纹理平铺模式, 默认为 `NoRepeat`。
/// * `flip_x` : 是否围绕 `origin` 做水平镜像, 默认为 `false`。
///
/// Return:
/// A `@sprite.Picture` with the correct translation matrix to align rendering
/// position with Nx `origin`.
///
/// Edge cases:
/// * If the Nx data is missing `origin`, it will fall back to (0, 0) and not
///   perform additional translation.
/// * If `size` is different from the texture dimensions and `repeat` is
///   `Repeat`, the texture will still be tiled, only affecting the starting
///   offset.
pub fn nx_texture_to_selene_picture(
  texture : NxTexture,
  size? : @selene_math.Vec2D,
  repeat? : @selene_math.RepeatMode = NoRepeat,
  flip_x? : Bool = false,
) -> @sprite.Picture {
  guard repeat is NoRepeat || texture.offset is { x: 0, y: 0 } else {
    abort("tiled texture in spritesheet is not supported")
  }
  let resolved_size = size.unwrap_or(
    @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
  )
  let base = @selene_math.Transform::from_translation(
    -texture.origin.x.to_double(),
    -texture.origin.y.to_double(),
  )
  let transform = if flip_x {
    @selene_math.Transform::from_scale(-1.0, 1.0) * base
  } else {
    base
  }
  @sprite.Picture::new(resolved_size, texture.i, transform~, repeat~)
}
