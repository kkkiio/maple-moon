///|
/// 单个 cursor 帧数据。
pub(all) struct CursorFrame {
  /// 在 packed atlas 中的位置和尺寸。
  rect : @math.Rect
  /// 帧持续时间，单位为秒。
  duration : Double
  /// 光标热点相对于 trimmed frame 左上角的像素偏移。
  anchor : @math.Vec2
}

///|
/// 单个 cursor 状态的帧序列。
pub(all) struct CursorAnimation {
  frames : Array[CursorFrame]
  /// 总时长（秒），预计算用于帧循环。
  total_duration : Double
}

///|
/// 所有 cursor 状态的动画数据。
pub(all) struct CursorAnimationData {
  atlas_image : @asset.ImageHandle
  animations : @hashmap.HashMap[String, CursorAnimation]
}

///|
/// 根据已用时间和 tag 名获取当前应显示的帧。
///
/// 帧循环：elapsed % total_duration 后按 duration 累积查找。
pub fn CursorAnimationData::current_frame(
  self : CursorAnimationData,
  tag : String,
  elapsed : Double,
) -> CursorFrame? {
  let anim = match self.animations.get(tag) {
    Some(a) => a
    None => return None
  }
  let t = elapsed % anim.total_duration
  let mut accumulated = 0.0
  for frame in anim.frames {
    accumulated += frame.duration
    if t < accumulated {
      return Some(frame)
    }
  }
  anim.frames.last()
}

///|
/// 从 aseprite atlas JSON 加载 cursor 动画数据。
///
/// JSON 格式为 Aseprite packed spritesheet。
/// 使用 `meta.slices` 中的 `anchor_<tag>` pivot 作为 cursor hotspot。
///
/// # Example
/// ```moonbit nocheck
/// let data = try! CursorAnimationData::load(
///   "assets/UI/Basic.img/Cursor/cursor_animation.json",
/// )
/// ```
pub fn CursorAnimationData::load(
  json_path : String,
) -> CursorAnimationData raise {
  let json = @resource.require_json(json_path)
  guard json
    is {
      "frames": Array(frames_json),
      "meta": {
        "frameTags": Array(tags_json),
        "slices": Array(slices_json),
        ..
      },
      ..
    } else {
    fail("invalid cursor animation json structure: " + json_path)
  }

  // 解析所有帧的 duration、atlas rect 和 trim offset
  let frame_durations : Array[Int] = []
  let frame_rects : Array[@math.Rect] = []
  let frame_source_offsets : Array[(Int, Int)] = []
  for frame in frames_json {
    guard frame
      is {
        "duration": Number(d, ..),
        "frame": {
          "x": Number(x, ..),
          "y": Number(y, ..),
          "w": Number(w, ..),
          "h": Number(h, ..),
          ..
        },
        "spriteSourceSize": {
          "x": Number(src_x, ..),
          "y": Number(src_y, ..),
          ..
        },
        ..
      } else {
      fail("invalid frame in cursor animation json: " + json_path)
    }
    frame_durations.push(d.to_int())
    frame_rects.push({ position: @math.Vec2(x, y), size: @math.Vec2(w, h) })
    frame_source_offsets.push((src_x.to_int(), src_y.to_int()))
  }

  // 解析 frameTags
  let tag_ranges : @hashmap.HashMap[String, (Int, Int)] = @hashmap.HashMap(
    [],
    capacity=20,
  )
  for tag in tags_json {
    guard tag
      is {
        "name": String(name),
        "from": Number(from, ..),
        "to": Number(to, ..),
        ..
      } else {
      fail("invalid frameTag in cursor animation json: " + json_path)
    }
    tag_ranges.set(name, (from.to_int(), to.to_int()))
  }

  // 解析 slices：提取 anchor_<tag> 的 pivot
  let tag_pivots : @hashmap.HashMap[String, (Int, Int)] = @hashmap.HashMap(
    [],
    capacity=20,
  )
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
    let tag = name.strip_prefix("anchor_").map_or(name, fn(v) { v.to_owned() })
    tag_pivots.set(tag, (px.to_int(), py.to_int()))
  }

  // 构建每个 tag 的 CursorAnimation
  let animations : @hashmap.HashMap[String, CursorAnimation] = @hashmap.HashMap(
    [],
    capacity=20,
  )
  let tag_range_pairs = tag_ranges.to_array()
  for pair in tag_range_pairs {
    let (tag, (from, to)) = pair
    let tag_frames : Array[CursorFrame] = []
    let mut total_duration = 0.0
    let pivot = match tag_pivots.get(tag) {
      Some((px, py)) => (px, py)
      None => (0, 0)
    }
    let pivot_x = pivot.0
    let pivot_y = pivot.1
    for idx = from; idx <= to; idx = idx + 1 {
      guard idx >= 0 && idx < frame_durations.length() else {
        fail("cursor animation tag frame index out of range: " + tag)
      }
      let duration_s = frame_durations[idx].to_double() / 1000.0
      let source_offset = frame_source_offsets[idx]
      let frame = {
        rect: frame_rects[idx],
        duration: duration_s,
        anchor: @math.Vec2(
          (pivot_x - source_offset.0).to_double(),
          (pivot_y - source_offset.1).to_double(),
        ),
      }
      tag_frames.push(frame)
      total_duration += duration_s
    }
    guard !tag_frames.is_empty() else {
      fail("cursor animation tag has no frames: " + tag)
    }
    guard total_duration > 0.0 else {
      fail("cursor animation tag has zero duration: " + tag)
    }
    animations.set(tag, { frames: tag_frames, total_duration })
  }

  let atlas_path = json_path.replace(old=".json", new=".png")
  let atlas_image = @resource.require_image(atlas_path)

  { atlas_image, animations }
}
