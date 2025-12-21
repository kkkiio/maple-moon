/// Merge frames - extract, resize, and generate spritesheets from animation frames

///|
struct ExtractedFrame {
  data : FrameData
  buffer : @js.Value
}

///|
pub(all) struct UnifiedSize {
  width : Int
  height : Int
  anchor_x : Int
  anchor_y : Int
}

///|
using @cmp {maximum}

///|
/// Calculate unified size based on origin alignment
pub fn calculate_unified_size(frames : Array[FrameData]) -> UnifiedSize {
  let mut max_left = 0
  let mut max_right = 0
  let mut max_top = 0
  let mut max_bottom = 0
  for frame in frames {
    max_left = maximum(max_left, frame.origin_x)
    max_top = maximum(max_top, frame.origin_y)
    max_right = maximum(max_right, frame.width - frame.origin_x)
    max_bottom = maximum(max_bottom, frame.height - frame.origin_y)
  }
  {
    width: max_left + max_right,
    height: max_top + max_bottom,
    anchor_x: max_left,
    anchor_y: max_top,
  }
}

///|
/// Extract frames from sources.
async fn extract_frames(
  frames : Array[FrameData],
  spritesheet_buffers : Map[String, @js.Value],
  bitmaps_dir : String,
  load_bitmap : (String) -> @js.Value,
) -> Array[ExtractedFrame] {
  if frames.is_empty() {
    return []
  }

  // For spritesheet mode, we can optimize by loading the sharp instance once if all are from same sheet
  // But since we might mix or have bitmaps, let's just handle per frame or group by sheet if needed.
  // Current logic assumes single sheet per animation for spritesheet mode, but bitmaps are individual.

  let extracted : Array[ExtractedFrame] = []

  // Optimization: Pre-load the spritesheet sharp instance if applicable
  let mut current_sheet_path = ""
  let mut current_sharp_img : @js.Value? = None
  if not(frames[0].is_bitmap) {
    current_sheet_path = frames[0].spritesheet_path
    if spritesheet_buffers.get(current_sheet_path) is Some(buffer) {
      current_sharp_img = Some(sharp_from_buffer(buffer))
    } else {
      fail("Spritesheet buffer not found for \{current_sheet_path}")
    }
  }
  for frame in frames {
    if frame.is_bitmap {
      let bitmap_path = "\{bitmaps_dir}/\{frame.id}.png"
      let buffer = load_bitmap(bitmap_path)
      let sharp_img = sharp_from_buffer(buffer)
      let extracted_buffer = extract_ffi(
        sharp_img,
        0,
        0,
        frame.width,
        frame.height,
      ).wait()
      extracted.push({ data: frame, buffer: extracted_buffer })
    } else {
      // Spritesheet frame
      let buffer = extract_ffi(
        current_sharp_img.unwrap(),
        frame.src_x,
        frame.src_y,
        frame.width,
        frame.height,
      ).wait()
      extracted.push({ data: frame, buffer })
    }
  }
  extracted
}

///|
/// Resize frames to unified size
async fn resize_frames(
  frames : Array[ExtractedFrame],
  unified : UnifiedSize,
) -> Array[@js.Value] {
  let resized : Array[@js.Value] = []
  for frame in frames {
    let left = unified.anchor_x - frame.data.origin_x
    let top = unified.anchor_y - frame.data.origin_y
    let base = sharp_create_ffi(unified.width, unified.height)
    let composite_input = @js.Object::new()
    composite_input["input"] = frame.buffer
    composite_input["left"] = left
    composite_input["top"] = top
    let inputs_array : Array[@js.Value] = [composite_input.to_value()]
    let buffer = composite_ffi(base, @js.Value::cast_from(inputs_array)).wait()
    resized.push(buffer)
  }
  resized
}

///|
/// Generate spritesheet from frames (horizontal layout)
async fn generate_spritesheet(
  frames : Array[@js.Value],
  unified : UnifiedSize,
) -> @js.Value {
  let total_width = unified.width * frames.length()
  let base = sharp_create_ffi(total_width, unified.height)
  let inputs : Array[@js.Value] = []
  for i, buffer in frames {
    let input = @js.Object::new()
    input["input"] = buffer
    input["left"] = i * unified.width
    input["top"] = 0
    inputs.push(input.to_value())
  }
  composite_ffi(base, @js.Value::cast_from(inputs)).wait()
}

///|
/// Update animation JSON with new __i and __off
fn update_animation_json(
  animation_json : Json,
  action_name : String,
  unified : UnifiedSize,
  base_name : String,
  output_rel_path : String,
  layer : String?,
) -> Json {
  guard animation_json is Object(obj) else { return animation_json }
  let new_obj : Map[String, Json] = {}
  let mut frame_idx = 0
  for key, frame_json in obj {
    // Check if numeric key (frame)
    if key.iter().all(fn(c) { c >= '0' && c <= '9' }) {

      // Determine the object containing __i etc.
      let target_json_opt = match layer {
        Some(l) =>
          match frame_json {
            Object(o) => o.get(l)
            _ => None
          }
        None => Some(frame_json)
      }
      match target_json_opt {
        Some(Object(target_obj)) => {
          // Found frame data, update it
          let new_frame_data : Map[String, Json] = {}
          for k, v in target_obj {
            if k == "__i" {
              new_frame_data["__i"] = Json::string(
                "\{output_rel_path}/\{base_name}_\{action_name}.png",
              )
            } else if k == "origin" {
              new_frame_data["origin"] = Json::array([
                Json::number(unified.anchor_x.to_double()),
                Json::number(unified.anchor_y.to_double()),
              ])
            } else {
              new_frame_data[k] = v
            }
          }
          // Add extra fields
          new_frame_data["__off"] = Json::array([
            Json::number((frame_idx * unified.width).to_double()),
            Json::number(0.0),
          ])
          new_frame_data["__w"] = Json::number(unified.width.to_double())
          new_frame_data["__h"] = Json::number(unified.height.to_double())

          // Reconstruct final frame JSON
          let final_json = match layer {
            Some(l) =>
              match frame_json {
                Object(o) => {
                  let wrapper : Map[String, Json] = {}
                  for k, v in o {
                    if k == l {
                      wrapper[k] = Json::object(new_frame_data)
                    } else {
                      wrapper[k] = v
                    }
                  }
                  Json::object(wrapper)
                }
                _ => frame_json // Should not happen given guard above
              }
            None => Json::object(new_frame_data)
          }
          new_obj[key] = final_json
          frame_idx += 1
        }
        _ =>
          // Not a valid frame structure or missing layer, keep as is
          new_obj[key] = frame_json
      }
    } else {
      new_obj[key] = frame_json
    }
  }
  Json::object(new_obj)
}
