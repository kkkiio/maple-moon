///|
priv struct NxSpriteFrame {
  texture : NxTexture
  duration_ms : Int
}

///|
/// Compile one decoded NX flipbook into a registered Selene sprite clip.
///
/// Every frame must reference the same spritesheet image. The compiler
/// preserves each frame's exact spritesheet rectangle and animates its anchor
/// so different frame sizes keep the MapleStory origin at one world position.
///
/// # Example
/// ```moonbit nocheck
/// let source : NxAnimation = try! @json.from_json({
///   "0": {
///     "__i": "res://UI/demo.png",
///     "__w": 16,
///     "__h": 16,
///     "origin": [8, 16],
///   },
/// })
/// let clip = try! compile_nx_animation(source, name="ui/demo")
/// ignore(clip)
/// ```
///
/// # Errors
/// Raises when the animation is empty, contains invalid frame dimensions, or
/// references more than one spritesheet image.
pub fn compile_nx_animation(
  source : NxAnimation,
  name? : String = "nx/animation",
) -> SpriteClip raise {
  guard !source.frames.is_empty() else {
    fail("cannot compile empty NX animation: \{name}")
  }
  let frames : Array[NxSpriteFrame] = source.frames.map(fn(frame) {
    let duration = frame.delay.unwrap_or(100)
    {
      texture: frame.texture,
      duration_ms: if duration <= 0 {
        100
      } else {
        duration
      },
    }
  })
  if source.zigzag && frames.length() > 2 {
    for index = frames.length() - 2; index >= 1; index = index - 1 {
      frames.push(frames[index])
    }
  }
  let first = frames[0].texture
  guard first.w > 0 && first.h > 0 else {
    fail("invalid NX animation frame size: \{first.w}x\{first.h}, name=\{name}")
  }
  let mut left = 0
  let mut top = 0
  let mut right = 0
  let mut bottom = 0
  let mut atlas_width = 0
  let mut atlas_height = 0
  for frame in frames {
    let texture = frame.texture
    guard texture.i == first.i else {
      fail("NX animation frames must share one image: \{name}")
    }
    guard texture.w > 0 && texture.h > 0 else {
      fail(
        "invalid NX animation frame size: \{texture.w}x\{texture.h}, name=\{name}",
      )
    }
    guard texture.offset.x >= 0 && texture.offset.y >= 0 else {
      fail(
        "NX animation frame offset must be non-negative: x=\{texture.offset.x}, y=\{texture.offset.y}, name=\{name}",
      )
    }
    left = left.max(texture.origin.x)
    top = top.max(texture.origin.y)
    right = right.max(texture.w - texture.origin.x)
    bottom = bottom.max(texture.h - texture.origin.y)
    atlas_width = atlas_width.max(texture.offset.x + texture.w)
    atlas_height = atlas_height.max(texture.offset.y + texture.h)
  }
  let cell_width = left + right
  let cell_height = top + bottom
  guard cell_width > 0 && cell_height > 0 else {
    fail(
      "invalid NX animation canvas: \{cell_width}x\{cell_height}, name=\{name}",
    )
  }
  let rects : Array[@math.Rect] = []
  let keys : Array[@selene_animation.ScalarKeyframe] = []
  let anchor_keys : Array[@selene_animation.Vec3Keyframe] = []
  let durations : Array[Int] = []
  let mut elapsed = 0.0
  for index, frame in frames {
    let texture = frame.texture
    rects.push({
      position: @math.Vec2(
        texture.offset.x.to_double(),
        texture.offset.y.to_double(),
      ),
      size: @math.Vec2(texture.w.to_double(), texture.h.to_double()),
    })
    keys.push({
      time: elapsed,
      value: index.to_double(),
      in_tangent: None,
      out_tangent: None,
    })
    let @sprite.Anchor(anchor) = anchor_from_origin(
      @math.Vec2(texture.origin.x.to_double(), texture.origin.y.to_double()),
      @math.Vec2(texture.w.to_double(), texture.h.to_double()),
    )
    anchor_keys.push({
      time: elapsed,
      value: @math.Vec3(anchor.0, anchor.1, 0.0),
      in_tangent: None,
      out_tangent: None,
    })
    elapsed += frame.duration_ms.to_double() / 1000.0
    durations.push(frame.duration_ms)
  }
  let layout = @sprite.register_texture_atlas_layout(
    @sprite.TextureAtlasLayout(
      @math.Vec2(atlas_width.to_double(), atlas_height.to_double()),
      rects,
    ),
  )
  let clip = @selene_animation.AnimationClip(name)
  clip.add_curve_to_target(
    @selene_animation.AnimationTargetId("self"),
    @selene_animation.VariableCurve::scalar(
      @selene_animation.texture_atlas_index_field(),
      keys,
      interpolation=@selene_animation.ChannelInterpolation::Step,
    ),
  )
  clip.add_curve_to_target(
    @selene_animation.AnimationTargetId("self"),
    @selene_animation.VariableCurve::vec3(
      sprite_anchor_field(),
      anchor_keys,
      interpolation=@selene_animation.ChannelInterpolation::Step,
    ),
  )
  clip.duration = elapsed.max(0.001)
  {
    image: require_image(first.i),
    layout,
    clip: @selene_animation.register_animation_clip_asset(clip),
    first_frame_index: 0,
    anchor: anchor_from_origin(
      @math.Vec2(first.origin.x.to_double(), first.origin.y.to_double()),
      @math.Vec2(first.w.to_double(), first.h.to_double()),
    ),
    duration_ms: (clip.duration * 1000.0).to_int(),
    dimensions: @struct.Point(cell_width, cell_height),
    frame_durations_ms: durations,
    frame_alphas: frames.map(fn(_) { 1.0 }),
  }
}

///|
/// Build a Selene sprite from the first frame of one compiled sprite clip.
///
/// Playback is intentionally separate: callers install an animation graph and
/// player only for visuals that should advance beyond the first frame.
///
/// # Example
/// ```moonbit nocheck
/// let loaded = try! AnimationLoader().load(
///   "res://Mob/0100100.img/animation.json",
/// )
/// let sprite = try! loaded.clip("stand").sprite()
/// ignore(sprite)
/// ```
pub fn SpriteClip::sprite(
  self : SpriteClip,
  flip_x? : Bool = false,
  alpha? : Double = 1.0,
) -> @sprite.Sprite {
  let anchor = if flip_x { mirror_anchor_x(self.anchor) } else { self.anchor }
  @sprite.Sprite(
    image=Some(self.image),
    texture_atlas=Some(
      @sprite.TextureAtlas(self.layout, index=self.first_frame_index),
    ),
    anchor~,
    flip_x~,
    color=white_with_alpha(alpha),
  )
}

///|
/// Load the image referenced by an NX texture and construct its static sprite.
///
/// `size` changes the destination size while preserving the NX source rectangle
/// and origin. Repeating sprites require an untrimmed source at offset `(0, 0)`.
///
/// # Example
/// ```moonbit nocheck
/// let texture : NxTexture = try! @json.from_json({
///   "__i": "res://UI/demo.png",
///   "__w": 16,
///   "__h": 12,
///   "origin": [8, 12],
/// })
/// let sprite = texture.require_sprite()
/// ignore(sprite)
/// ```
///
/// # Panics
/// Panics when a repeating texture uses a non-zero spritesheet offset, or when
/// the required image cannot be loaded.
pub fn NxTexture::require_sprite(
  self : NxTexture,
  size? : @math.Vec2,
  repeat? : @math.RepeatMode = NoRepeat,
  flip_x? : Bool = false,
  alpha? : Double = 1.0,
) -> @sprite.Sprite {
  guard repeat is NoRepeat || self.offset is { x: 0, y: 0 } else {
    abort("tiled NX texture in a spritesheet is not supported: \{self.i}")
  }
  let source_size = @math.Vec2(self.w.to_double(), self.h.to_double())
  let destination_size = size.unwrap_or(source_size)
  @sprite.Sprite(
    image=Some(require_image(self.i)),
    rect=Some({
      position: @math.Vec2(self.offset.x.to_double(), self.offset.y.to_double()),
      size: source_size,
    }),
    custom_size=Some(destination_size),
    anchor=anchor_from_origin(
      @math.Vec2(self.origin.x.to_double(), self.origin.y.to_double()),
      source_size,
      flip_x~,
    ),
    flip_x~,
    image_mode=if repeat is NoRepeat {
      @sprite.SpriteImageMode::Auto
    } else {
      @sprite.SpriteImageMode::Tiled(repeat)
    },
    color=white_with_alpha(alpha),
  )
}

///|
fn anchor_from_origin(
  origin : @math.Vec2,
  size : @math.Vec2,
  flip_x? : Bool = false,
) -> @sprite.Anchor {
  let width = size.0.max(1.0)
  let height = size.1.max(1.0)
  let x = origin.0 / width - 0.5
  @sprite.Anchor(
    @math.Vec2(if flip_x { -x } else { x }, 0.5 - origin.1 / height),
  )
}

///|
fn mirror_anchor_x(anchor : @sprite.Anchor) -> @sprite.Anchor {
  let @sprite.Anchor(value) = anchor
  @sprite.Anchor(@math.Vec2(-value.0, value.1))
}

///|
fn white_with_alpha(alpha : Double) -> @render.Color {
  let color = @sprite.color_from_css("white")
  { ..color, a: alpha.clamp(min=0.0, max=1.0) }
}
