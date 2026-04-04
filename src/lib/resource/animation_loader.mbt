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
pub(all) struct AnimationLoader {
  loader : AsyncLoader
}

///|
/// Create an animation loader from an existing resource async loader.
pub fn AnimationLoader::new(loader : AsyncLoader) -> AnimationLoader {
  { loader, }
}

///|
/// Load and compile one Aseprite animation resource from `animations_path`.
///
/// `animations_path` can be:
/// - relative to resource root (for example `Npc/Npc/0002007.img/animation.json`)
/// - absolute (`/assets/...`)
pub async fn AnimationLoader::load(
  self : AnimationLoader,
  animations_path : String,
) -> LoadedAnimations {
  let json_url = self.loader.resolve_json_path(animations_path)
  match animation_cache.get(json_url) {
    Some(cached) => cached
    None => {
      let src = self.loader.load_data(animations_path)
      let compiled = compile_loaded_animations(self.loader, src, json_url)
      animation_cache.set(json_url, compiled)
      compiled
    }
  }
}

///|
let animation_cache : Map[String, LoadedAnimations] = Map::new()

///|
priv struct FrameItem {
  rect : @math.Rect
  duration_s : Double
  size : @struct.Point[Int]
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
  loader : AsyncLoader,
  src : Json,
  json_url : String,
) -> LoadedAnimations raise {
  guard src
    is {
      "frames": Array(frames_json),
      "meta": {
        "image": String(image_ref),
        "frameTags": Array(tags_json),
        "slices": Array(slices_json),
        ..
      },
      ..
    } else {
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

  let frames = parse_frames(frames_json)
  let ranges = parse_tag_ranges(tags_json, frames.length())
  let anchor_by_tag = parse_anchor_by_tag(slices_json)

  let first = frames[0]
  let atlas_layout = @sprite.register_texture_atlas_layout(
    @sprite.TextureAtlasLayout::new(
      @math.Vec2D(first.size.x.to_double(), first.size.y.to_double()),
      frames.map(fn(frame) { frame.rect }),
    ),
  )

  let image = load_meta_image(loader, json_url, image_ref)

  let clip_handles : Array[@selene_animation.AnimationClipHandle] = []
  let tag_names : Array[String] = []
  let durations_ms : Array[Int] = []
  for range in ranges {
    if range.direction != "forward" {
      fail(
        "unsupported frameTags.direction=\{range.direction}, only forward is supported",
      )
    }
    let keys : Array[@selene_animation.ScalarKeyframe] = []
    let mut t = 0.0
    for idx = range.from; idx <= range.to; idx = idx + 1 {
      let frame = frames[idx]
      keys.push({
        time: t,
        value: idx.to_double(),
        in_tangent: None,
        out_tangent: None,
      })
      t += frame.duration_s
    }
    let clip = @selene_animation.AnimationClip::new(
      "npc/aseprite/\{range.name}",
    )
    clip.add_curve_to_target(
      @selene_animation.AnimationTargetId::new("self"),
      @selene_animation.VariableCurve::scalar(
        @selene_animation.texture_atlas_index_field(),
        keys,
        interpolation=@selene_animation.ChannelInterpolation::Step,
      ),
    )
    clip.duration = if t <= 0.0 { 0.001 } else { t }
    clip_handles.push(@selene_animation.register_animation_clip_asset(clip))
    tag_names.push(range.name)
    durations_ms.push((clip.duration * 1000.0).to_int())
  }

  let (graph, nodes) = @selene_animation.AnimationGraph::from_clips(
    clip_handles,
  )
  let graph_handle = @selene_animation.register_animation_graph_asset(graph)

  let clips : Map[String, SeleneClip] = Map::new(capacity=tag_names.length())
  for idx = 0; idx < tag_names.length(); idx = idx + 1 {
    let tag = tag_names[idx]
    let pivot = match anchor_by_tag.get(tag) {
      Some(pivot) => pivot
      None => fail("missing slice anchor_\{tag} in aseprite meta.slices")
    }
    clips.set(tag, {
      image,
      layout: atlas_layout,
      graph: graph_handle,
      node: nodes[idx],
      anchor: anchor_from_pivot(pivot, first.size),
      duration_ms: durations_ms[idx],
      dimensions: first.size,
    })
  }
  { clips, tags: tag_names }
}

///|
fn parse_frames(frames_json : Array[Json]) -> Array[FrameItem] raise {
  let frames : Array[FrameItem] = []
  for frame in frames_json {
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
      fail("invalid aseprite frame json: \{frame}")
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
      rect: { position: @math.Vec2D(x, y), size: @math.Vec2D(w, h) },
      duration_s,
      size: @struct.Point::new(wi, hi),
    })
  }
  frames
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
      fail("invalid aseprite frameTags item: \{tag}")
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
fn parse_anchor_by_tag(slices_json : Array[Json]) -> Map[String, @math.Vec2D] {
  let anchors = Map::new()
  for slice in slices_json {
    guard slice is { "name": String(name), "keys": Array(keys), .. } else {
      continue
    }
    guard name.has_prefix("anchor_") else { continue }
    guard !keys.is_empty() else { continue }
    let first = keys[0]
    guard first
      is { "pivot": { "x": Number(px, ..), "y": Number(py, ..), .. }, .. } else {
      continue
    }
    let tag = name
      .strip_prefix("anchor_")
      .map(fn(v) { v.to_string() })
      .unwrap_or(name)
    anchors[tag] = @math.Vec2D(px, py)
  }
  anchors
}

///|
fn anchor_from_pivot(
  pivot : @math.Vec2D,
  size : @struct.Point[Int],
) -> @sprite.Anchor raise {
  guard size.x > 0 && size.y > 0 else {
    fail("invalid frame size for pivot conversion: \{size.x}x\{size.y}")
  }
  let normalized_x = pivot.0 / size.x.to_double()
  let normalized_y = pivot.1 / size.y.to_double()
  @sprite.Anchor(@math.Vec2D(normalized_x - 0.5, 0.5 - normalized_y))
}

///|
test "anchor_from_pivot supports aseprite pixel pivot" {
  let @sprite.Anchor(v) = anchor_from_pivot(
    @math.Vec2D(30.0, 79.0),
    @struct.Point::new(57, 79),
  )
  inspect(v.0, content="0.02631578947368418")
  inspect(v.1, content="-0.5")
}

///|
test "anchor_from_pivot preserves legacy normalized-equivalent center" {
  let @sprite.Anchor(v) = anchor_from_pivot(
    @math.Vec2D(29.0, 50.0),
    @struct.Point::new(58, 100),
  )
  inspect(v.0, content="0")
  inspect(v.1, content="0")
}

///|
fn load_meta_image(
  loader : AsyncLoader,
  json_url : String,
  image_ref : String,
) -> @asset.ImageHandle {
  if image_ref.has_prefix("/") {
    loader.load_image(image_ref)
  } else if image_ref.contains("/") {
    loader.load_image(image_ref)
  } else {
    loader.load_image(join_dir(parent_dir(json_url), image_ref))
  }
}

///|
fn parent_dir(path : String) -> String {
  js_parent_dir(path)
}

///|
extern "js" fn js_parent_dir(path : String) -> String =
  #| (path) => {
  #|   const idx = path.lastIndexOf("/")
  #|   if (idx < 0) return ""
  #|   return path.slice(0, idx)
  #| }
