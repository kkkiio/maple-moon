///|
/// A compiled Selene clip for one NPC stance/tag.
pub(all) struct SeleneClip {
  /// Shared atlas image handle.
  image : @asset.ImageHandle
  /// Shared texture atlas layout handle.
  layout : @sprite.TextureAtlasLayoutHandle
  /// Shared animation graph handle.
  graph : @selene_animation.AnimationGraphHandle
  /// Node index for this tag's clip in `graph`.
  node : @selene_animation.AnimationNodeIndex
  /// Sprite anchor derived from `anchor_<tag>` slice pivot.
  anchor : @sprite.Anchor
  /// Total clip duration in milliseconds.
  duration_ms : Int
  /// Frame dimensions used by gameplay picking bounds.
  dimensions : @struct.Point[Int]
  /// Per-frame durations in milliseconds for this tag range.
  frame_durations_ms : Array[Int]
  /// Per-frame alpha multipliers resolved from optional layer/cel metadata.
  frame_alphas : Array[Double]
}

///|
/// Loaded and compiled animation set keyed by Aseprite frame tags.
pub(all) struct LoadedAnimations {
  clips : Map[String, SeleneClip]
  tags : Array[String]
}

///|
/// Return one compiled clip by tag name.
pub fn LoadedAnimations::clip(
  self : LoadedAnimations,
  tag : String,
) -> SeleneClip raise {
  match self.clips.get(tag) {
    Some(clip) => clip
    None => fail("missing animation tag: \{tag}")
  }
}

///|
/// List all available tag names in deterministic export order.
pub fn LoadedAnimations::list_tags(self : LoadedAnimations) -> Array[String] {
  self.tags.copy()
}

///|
/// Loader entrypoint for `mx.json.animations_path` -> Selene clips.
pub(all) struct AnimationLoader {} derive(Default)

///|
/// Create an animation loader from an existing resource async loader.
pub fn AnimationLoader::AnimationLoader() -> AnimationLoader {
  Default::default()
}

///|
/// Load and compile one Aseprite animation resource from `animations_path`.
///
/// `animations_path` can be:
/// - relative to resource root (for example `Npc/Npc/0002007.img/animation.json`)
/// - a resolved asset path (`assets/...`)
pub fn AnimationLoader::load(
  _self : AnimationLoader,
  animations_path : String,
) -> LoadedAnimations {
  let json_url = animations_path
  match animation_cache.get(json_url) {
    Some(cached) => cached
    None => {
      let src = require_json(json_url)
      let compiled = compile_loaded_animations(src, json_url) catch {
        err => abort("failed to load animation: \{json_url}, error=\{err}")
      }
      animation_cache.set(json_url, compiled)
      compiled
    }
  }
}

///|
let animation_cache : Map[String, LoadedAnimations] = Map([])

///|
priv struct FrameItem {
  rect : @math.Rect
  sprite_source_position : @struct.Point[Int]
  duration_ms : Int
  duration_s : Double
  alpha : Double
}

///|
priv struct AnchorInfo {
  bounds_position : @struct.Point[Int]
  dimensions : @struct.Point[Int]
  pivot : @math.Vec2
}

///|
priv struct TagRange {
  name : String
  from : Int
  to : Int
  direction : String
}

///|
fn compile_loaded_animations(
  src : Json,
  json_url : String,
) -> LoadedAnimations raise {
  guard src is { "frames": Array(frames_json), "meta": Object(meta_obj), .. } else {
    fail(
      "invalid aseprite animation json: missing frames/meta/image/frameTags/slices",
    )
  }
  let image_ref = match meta_obj.get("image") {
    Some(String(image_ref)) => image_ref
    _ =>
      fail(
        "invalid aseprite animation json: missing frames/meta/image/frameTags/slices",
      )
  }
  let tags_json = match meta_obj.get("frameTags") {
    Some(Array(tags_json)) => tags_json
    _ =>
      fail(
        "invalid aseprite animation json: missing frames/meta/image/frameTags/slices",
      )
  }
  let slices_json = match meta_obj.get("slices") {
    Some(Array(slices_json)) => slices_json
    _ =>
      fail(
        "invalid aseprite animation json: missing frames/meta/image/frameTags/slices",
      )
  }
  guard !frames_json.is_empty() else {
    fail("invalid aseprite animation json: empty frames")
  }
  guard !tags_json.is_empty() else {
    fail("invalid aseprite animation json: empty frameTags")
  }

  let frame_alpha_by_index = parse_frame_alpha_by_index(
    meta_obj.get("layers"),
    frames_json.length(),
  )
  let atlas_size = parse_meta_size(meta_obj)
  let frames = parse_frames(frames_json, frame_alpha_by_index)
  let ranges = parse_tag_ranges(tags_json, frames.length())
  let anchor_by_tag = parse_anchor_info_by_tag(slices_json)

  let atlas_layout = @sprite.register_texture_atlas_layout(
    @sprite.TextureAtlasLayout(
      @math.Vec2(atlas_size.x.to_double(), atlas_size.y.to_double()),
      frames.map(fn(frame) { frame.rect }),
    ),
  )

  let image = load_meta_image(json_url, image_ref)

  let clip_handles : Array[@selene_animation.AnimationClipHandle] = []
  let tag_names : Array[String] = []
  let durations_ms : Array[Int] = []
  let tag_frame_durations : Array[Array[Int]] = []
  let tag_frame_alphas : Array[Array[Double]] = []
  for range in ranges {
    if range.direction != "forward" {
      fail(
        "unsupported frameTags.direction=\{range.direction}, only forward is supported",
      )
    }
    let keys : Array[@selene_animation.ScalarKeyframe] = []
    let mut t = 0.0
    let frame_durations_ms : Array[Int] = []
    let frame_alphas : Array[Double] = []
    for idx = range.from; idx <= range.to; idx = idx + 1 {
      let frame = frames[idx]
      keys.push({
        time: t,
        value: idx.to_double(),
        in_tangent: None,
        out_tangent: None,
      })
      t += frame.duration_s
      frame_durations_ms.push(frame.duration_ms)
      frame_alphas.push(frame.alpha)
    }
    let clip = @selene_animation.AnimationClip("npc/aseprite/\{range.name}")
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
        build_sprite_anchor_keys(frames, range, anchor_by_tag),
        interpolation=@selene_animation.ChannelInterpolation::Step,
      ),
    )
    clip.duration = if t <= 0.0 { 0.001 } else { t }
    clip_handles.push(@selene_animation.register_animation_clip_asset(clip))
    tag_names.push(range.name)
    durations_ms.push((clip.duration * 1000.0).to_int())
    tag_frame_durations.push(frame_durations_ms)
    tag_frame_alphas.push(frame_alphas)
  }

  let (graph, nodes) = @selene_animation.AnimationGraph::from_clips(
    clip_handles,
  )
  let graph_handle = @selene_animation.register_animation_graph_asset(graph)

  let clips : Map[String, SeleneClip] = Map([], capacity=tag_names.length())
  for idx = 0; idx < tag_names.length(); idx = idx + 1 {
    let tag = tag_names[idx]
    let anchor_info = match anchor_by_tag.get(tag) {
      Some(info) => info
      None => fail("missing slice anchor_\{tag} in aseprite meta.slices")
    }
    let tag_size = anchor_info.dimensions
    clips.set(tag, {
      image,
      layout: atlas_layout,
      graph: graph_handle,
      node: nodes[idx],
      anchor: frame_anchor(frames[ranges[idx].from], anchor_info),
      duration_ms: durations_ms[idx],
      dimensions: tag_size,
      frame_durations_ms: tag_frame_durations[idx],
      frame_alphas: tag_frame_alphas[idx],
    })
  }
  { clips, tags: tag_names }
}

///|
fn parse_meta_size(meta_obj : Map[String, Json]) -> @struct.Point[Int] raise {
  match meta_obj.get("size") {
    Some({ "w": Number(w, ..), "h": Number(h, ..), .. }) => {
      let wi = w.to_int()
      let hi = h.to_int()
      guard wi > 0 && hi > 0 else {
        fail("invalid aseprite meta.size: \{wi}x\{hi}")
      }
      Point(wi, hi)
    }
    _ => fail("invalid aseprite animation json: missing meta.size")
  }
}

///|
fn parse_frames(
  frames_json : Array[Json],
  frame_alpha_by_index : Array[Double],
) -> Array[FrameItem] raise {
  let frames : Array[FrameItem] = []
  for idx, frame in frames_json {
    guard frame
      is {
        "frame": {
          "x": Number(x, ..),
          "y": Number(y, ..),
          "w": Number(w, ..),
          "h": Number(h, ..),
          ..
        },
        "duration": Number(duration_ms, ..),
        ..
      } else {
      fail("invalid aseprite frame json: \{to_repr(frame)}")
    }
    let wi = w.to_int()
    let hi = h.to_int()
    guard wi > 0 && hi > 0 else {
      fail("invalid aseprite frame size: \{wi}x\{hi}")
    }
    let duration = duration_ms.to_int()
    let duration_s = if duration <= 0 {
      0.1
    } else {
      duration.to_double() / 1000.0
    }
    frames.push({
      rect: { position: @math.Vec2(x, y), size: @math.Vec2(w, h) },
      sprite_source_position: parse_frame_sprite_source_position(frame),
      duration_ms: duration,
      duration_s,
      alpha: frame_alpha_by_index[idx],
    })
  }
  frames
}

///|
fn parse_frame_sprite_source_position(frame : Json) -> @struct.Point[Int] {
  match frame {
    { "spriteSourceSize": { "x": Number(x, ..), "y": Number(y, ..), .. }, .. } =>
      Point(x.to_int(), y.to_int())
    _ => Point(0, 0)
  }
}

///|
fn parse_frame_alpha_by_index(
  layers_json : Json?,
  frame_len : Int,
) -> Array[Double] {
  let frame_alpha : Array[Double] = []
  for _ in 0..<frame_len {
    frame_alpha.push(1.0)
  }
  guard layers_json is Some(Array(layers)) else { return frame_alpha }
  for layer in layers {
    guard layer is Object(layer_obj) else { continue }
    let layer_alpha = parse_optional_opacity(layer_obj.get("opacity"))
    match layer_obj.get("cels") {
      Some(Array(cels)) => {
        let has_any_cel = Ref(false)
        for cel in cels {
          guard cel is Object(cel_obj) else { continue }
          let frame_index = match cel_obj.get("frame") {
            Some(Number(frame_index, ..)) => frame_index.to_int()
            _ => continue
          }
          if frame_index < 0 || frame_index >= frame_len {
            continue
          }
          let cel_alpha = parse_optional_opacity(cel_obj.get("opacity"))
          frame_alpha[frame_index] = frame_alpha[frame_index] *
            layer_alpha *
            cel_alpha
          has_any_cel.val = true
        }
        if !has_any_cel.val {
          for i = 0; i < frame_len; i = i + 1 {
            frame_alpha[i] = frame_alpha[i] * layer_alpha
          }
        }
      }
      _ =>
        for i = 0; i < frame_len; i = i + 1 {
          frame_alpha[i] = frame_alpha[i] * layer_alpha
        }
    }
  }
  frame_alpha
}

///|
fn parse_optional_opacity(value : Json?) -> Double {
  let raw = match value {
    Some(Number(opacity, ..)) => opacity.to_int()
    _ => 255
  }
  if raw <= 0 {
    0.0
  } else if raw >= 255 {
    1.0
  } else {
    raw.to_double() / 255.0
  }
}

///|
fn parse_tag_ranges(
  tags_json : Array[Json],
  frame_len : Int,
) -> Array[TagRange] raise {
  let ranges : Array[TagRange] = []
  for tag in tags_json {
    guard tag
      is {
        "name": String(name),
        "from": Number(from, ..),
        "to": Number(to, ..),
        "direction": String(direction),
        ..
      } else {
      fail("invalid aseprite frameTags item: \{to_repr(tag)}")
    }
    let from_i = from.to_int()
    let to_i = to.to_int()
    guard from_i >= 0 && to_i >= from_i && to_i < frame_len else {
      fail(
        "invalid frameTags range for \{name}: from=\{from_i}, to=\{to_i}, frame_len=\{frame_len}",
      )
    }
    ranges.push({ name, from: from_i, to: to_i, direction })
  }
  ranges
}

///|
fn parse_anchor_info_by_tag(
  slices_json : Array[Json],
) -> Map[String, AnchorInfo] {
  let anchors = Map([])
  for slice in slices_json {
    guard slice is { "name": String(name), "keys": Array(keys), .. } else {
      continue
    }
    guard name.has_prefix("anchor_") else { continue }
    guard !keys.is_empty() else { continue }
    let first = keys[0]
    guard first
      is {
        "bounds": {
          "x": Number(x, ..),
          "y": Number(y, ..),
          "w": Number(w, ..),
          "h": Number(h, ..),
          ..
        },
        "pivot": { "x": Number(px, ..), "y": Number(py, ..), .. },
        ..
      } else {
      continue
    }
    let wi = w.to_int()
    let hi = h.to_int()
    guard wi > 0 && hi > 0 else { continue }
    let tag = name
      .strip_prefix("anchor_")
      .map(fn(v) { v.to_owned() })
      .unwrap_or(name)
    anchors[tag] = {
      bounds_position: Point(x.to_int(), y.to_int()),
      dimensions: Point(wi, hi),
      pivot: @math.Vec2(px, py),
    }
  }
  anchors
}

///|
fn build_sprite_anchor_keys(
  frames : Array[FrameItem],
  range : TagRange,
  anchor_by_tag : Map[String, AnchorInfo],
) -> Array[@selene_animation.Vec3Keyframe] raise {
  let info = match anchor_by_tag.get(range.name) {
    Some(info) => info
    None => fail("missing slice anchor_\{range.name} in aseprite meta.slices")
  }
  let keys : Array[@selene_animation.Vec3Keyframe] = []
  let mut t = 0.0
  for idx = range.from; idx <= range.to; idx = idx + 1 {
    let frame = frames[idx]
    let @sprite.Anchor(anchor) = frame_anchor(frame, info)
    keys.push({
      time: t,
      value: @math.Vec3(anchor.0, anchor.1, 0.0),
      in_tangent: None,
      out_tangent: None,
    })
    t += frame.duration_s
  }
  keys
}

///|
fn frame_anchor(frame : FrameItem, info : AnchorInfo) -> @sprite.Anchor raise {
  let rect_w = frame.rect.size.0.to_int()
  let rect_h = frame.rect.size.1.to_int()
  guard rect_w > 0 && rect_h > 0 else {
    fail("invalid frame rect size for anchor conversion")
  }
  let source_x = frame.sprite_source_position.x - info.bounds_position.x
  let source_y = frame.sprite_source_position.y - info.bounds_position.y
  let pivot_x = info.pivot.0 - source_x.to_double()
  let pivot_y = info.pivot.1 - source_y.to_double()
  anchor_from_pivot(@math.Vec2(pivot_x, pivot_y), Point(rect_w, rect_h))
}

///|
let sprite_anchor_field_ref : Ref[@selene_animation.AnimatedFieldHandle?] = Ref(
  None,
)

///|
fn sprite_anchor_field() -> @selene_animation.AnimatedFieldHandle {
  match sprite_anchor_field_ref.val {
    Some(handle) => handle
    None => {
      let handle = @selene_animation.register_animated_field({
        name: "Sprite.anchor",
        kind: @selene_animation.AnimationValueKind::Vec3,
        sample: fn(entity) {
          let @sprite.Anchor(anchor) = @sprite.sprites()
            .get(entity)
            .map_or(@sprite.Anchor(@math.Vec2::zero()), fn(sprite) {
              sprite.anchor
            })
          @selene_animation.AnimatedValue::Vec3(
            @math.Vec3(anchor.0, anchor.1, 0.0),
          )
        },
        apply: fn(entity, value) {
          guard value is @selene_animation.AnimatedValue::Vec3(anchor)
          guard @sprite.sprites().get(entity) is Some(sprite) else { return }
          let x = if sprite.flip_x { -anchor.x } else { anchor.x }
          @sprite.sprites().set(entity, {
            ..sprite,
            anchor: @sprite.Anchor(@math.Vec2(x, anchor.y)),
          })
        },
      })
      sprite_anchor_field_ref.val = Some(handle)
      handle
    }
  }
}

///|
fn anchor_from_pivot(
  pivot : @math.Vec2,
  size : @struct.Point[Int],
) -> @sprite.Anchor raise {
  guard size.x > 0 && size.y > 0 else {
    fail("invalid frame size for pivot conversion: \{size.x}x\{size.y}")
  }
  let normalized_x = pivot.0 / size.x.to_double()
  let normalized_y = pivot.1 / size.y.to_double()
  @sprite.Anchor(@math.Vec2(normalized_x - 0.5, 0.5 - normalized_y))
}

///|
test "anchor_from_pivot supports aseprite pixel pivot" {
  let @sprite.Anchor(v) = anchor_from_pivot(
    @math.Vec2(30.0, 79.0),
    Point(57, 79),
  )
  inspect(v.0, content="0.02631578947368418")
  inspect(v.1, content="-0.5")
}

///|
test "anchor_from_pivot preserves legacy normalized-equivalent center" {
  let @sprite.Anchor(v) = anchor_from_pivot(
    @math.Vec2(29.0, 50.0),
    Point(58, 100),
  )
  inspect(v.0, content="0")
  inspect(v.1, content="0")
}

///|
test "parse frame alpha by index applies layer and cel opacity" {
  let factors = parse_frame_alpha_by_index(
    Some(
      Json::array([
        Json::object({
          "name": Json::string("main"),
          "opacity": Json::number(200.0),
          "cels": Json::array([
            Json::object({
              "frame": Json::number(0.0),
              "opacity": Json::number(128.0),
            }),
          ]),
        }),
      ]),
    ),
    2,
  )
  inspect(factors.length(), content="2")
  assert_true((factors[0] - 0.3936947327950788).abs() < 0.000000000001)
  inspect(factors[1], content="1")
}

///|
fn load_meta_image(json_url : String, image_ref : String) -> @asset.ImageHandle {
  let normalized_ref = image_ref.replace(old="\\", new="/")
  if is_resolved_asset_path(normalized_ref) {
    require_image(image_ref)
  } else {
    require_image(resolve_ref(json_url, image_ref))
  }
}
