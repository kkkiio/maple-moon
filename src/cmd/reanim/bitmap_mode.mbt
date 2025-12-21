/// Bitmap mode: Process animations with __b bitmap references
/// Loads images from bitmaps directory, generates spritesheets

///|
/// Check if json is a frame with __b reference
pub fn is_bitmap_frame(json : Json) -> Bool {
  json is { "__b": Number(_), "__h": Number(_), "__w": Number(_), .. }
}

///|
/// Check if object is an animation node with __b frames.
/// Requirements:
/// - Has consecutive numeric keys starting from 0 (at least 1 frame)
/// - Each numeric key's value is a bitmap frame (has __b, __h, __w)
pub fn is_bitmap_animation_node(json : Json) -> Bool {
  guard json is Object(obj) else { return false }
  let mut i = 0
  while true {
    match obj.get(i.to_string()) {
      Some(value) =>
        if is_bitmap_frame(value) {
          i = i + 1
        } else {
          return false
        }
      None => break
    }
  }
  i >= 1
}

///|
/// Collect frame data from an animation node with __b references.
pub fn collect_frames_from_bitmaps(animation_json : Json) -> Array[FrameData] {
  let frames : Array[FrameData] = []
  guard animation_json is Object(obj) else { return frames }
  for key, frame_json in obj {
    // Skip non-numeric keys
    guard key.iter().all(fn(c) { c >= '0' && c <= '9' }) else { continue }
    let frame_index = @strconv.parse_int(key) catch { _ => continue }

    // Parse frame data
    guard frame_json
      is {
        "__b": Number(bitmap_id, ..),
        "__w": Number(w, ..),
        "__h": Number(h, ..),
        ..
      } else {
      continue
    }

    // Get origin (default [0, 0])
    let (origin_x, origin_y) = match frame_json {
      { "origin": Array([Number(x, ..), Number(y, ..)]), .. } =>
        (x.to_int(), y.to_int())
      _ => (0, 0)
    }

    // Get delay (default 100)
    let delay = match frame_json {
      { "delay": Number(d, ..), .. } => d.to_int()
      _ => 100
    }
    frames.push({
      id: bitmap_id.to_int(),
      width: w.to_int(),
      height: h.to_int(),
      origin_x,
      origin_y,
      delay,
      frame_index,
      // For bitmap mode, src_x/y are 0 since we load the whole image
      src_x: 0,
      src_y: 0,
      spritesheet_path: "", // Will be set later
      is_bitmap: true,
    })
  }

  // Sort by frame index
  frames.sort_by_key(fn(f) { f.frame_index })
  frames
}

///|
/// Load bitmap images for frames
async fn load_bitmap_images(
  frames : Array[FrameData],
  load_bitmap : (Int) -> @js.Value,
) -> Array[ExtractedFrame] {
  let extracted : Array[ExtractedFrame] = []
  for frame in frames {
    let buffer = load_bitmap(frame.id)
    extracted.push({ data: frame, buffer })
  }
  extracted
}

///|
/// Update animation JSON with new __i and __off for bitmap mode
fn update_bitmap_animation_json(
  animation_json : Json,
  action_name : String,
  unified : UnifiedSize,
  output_rel_path : String,
) -> Json {
  guard animation_json is Object(obj) else { return animation_json }
  let new_obj : Map[String, Json] = {}
  let mut frame_idx = 0
  for key, frame_json in obj {
    // Check if numeric key (frame)
    if key.iter().all(fn(c) { c >= '0' && c <= '9' }) {
      guard frame_json is Object(frame_obj) else {
        new_obj[key] = frame_json
        continue
      }

      // Create new frame object with __i and __off instead of __b
      let new_frame : Map[String, Json] = {}
      for k, v in frame_obj {
        if k == "__b" {
          // Skip __b, we'll add __i instead
          continue
        } else if k == "origin" {
          // Update origin to unified anchor
          new_frame["origin"] = Json::array([
            Json::number(unified.anchor_x.to_double()),
            Json::number(unified.anchor_y.to_double()),
          ])
        } else {
          new_frame[k] = v
        }
      }
      // Add __i for spritesheet path
      new_frame["__i"] = Json::string("\{output_rel_path}/\{action_name}.png")
      // Add __off for position in spritesheet
      new_frame["__off"] = Json::array([
        Json::number((frame_idx * unified.width).to_double()),
        Json::number(0.0),
      ])
      // Update __w and __h to unified size
      new_frame["__w"] = Json::number(unified.width.to_double())
      new_frame["__h"] = Json::number(unified.height.to_double())
      new_obj[key] = Json::object(new_frame)
      frame_idx += 1
    } else {
      new_obj[key] = frame_json
    }
  }
  Json::object(new_obj)
}

///|
/// Process a single bitmap animation node
async fn process_bitmap_animation(
  json : Json,
  action_name : String,
  output_rel_path : String,
  load_bitmap : ((Int) -> @js.Value)?,
  save_image : ((String, @js.Value) -> Unit)?,
) -> Json {
  let frames = collect_frames_from_bitmaps(json)
  if frames.is_empty() {
    return json
  }
  let unified = calculate_unified_size(frames)

  // Process images if callbacks are provided
  match (load_bitmap, save_image) {
    (Some(loader), Some(saver)) => {
      let extracted = load_bitmap_images(frames, loader)
      let resized = resize_frames(extracted, unified)
      let new_spritesheet = generate_spritesheet(resized, unified)
      let output_filename = "\{action_name}.png"
      saver(output_filename, new_spritesheet)
    }
    _ => ()
  }

  // Update JSON
  update_bitmap_animation_json(json, action_name, unified, output_rel_path)
}

///|
/// Process bitmap resource tree recursively
pub async fn process_bitmap_resource(
  src : Json,
  output_rel_path : String,
  root_name : String,
  load_bitmap? : (Int) -> @js.Value,
  save_image? : (String, @js.Value) -> Unit,
) -> Json {
  process_bitmap_node(
    src,
    [],
    output_rel_path,
    root_name,
    load_bitmap,
    save_image,
  )
}

///|
/// Recursive helper to process a bitmap JSON node
async fn process_bitmap_node(
  json : Json,
  path : Array[String],
  output_rel_path : String,
  root_name : String,
  load_bitmap : ((Int) -> @js.Value)?,
  save_image : ((String, @js.Value) -> Unit)?,
) -> Json {
  if is_bitmap_animation_node(json) {
    // This is an animation node, process it
    let action_name = if path.is_empty() { root_name } else { path.join("_") }
    process_bitmap_animation(
      json, action_name, output_rel_path, load_bitmap, save_image,
    )
  } else {
    // Not an animation node
    match json {
      Object(obj) => {
        // Recurse into child objects
        let new_obj : Map[String, Json] = {}
        for key, value in obj {
          let child_path = path.copy()
          child_path.push(key)
          new_obj[key] = process_bitmap_node(
            value, child_path, output_rel_path, root_name, load_bitmap, save_image,
          )
        }
        Json::object(new_obj)
      }
      _ => json // Keep primitives and arrays as-is
    }
  }
}
