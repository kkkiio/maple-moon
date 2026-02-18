/// Simple pack mode - extract frames and generate spritesheet without resizing

///|
pub(all) struct ExtractedFrame {
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
/// Extract frames from sources.
pub async fn extract_frames(
  frames : Array[FrameData],
  spritesheet_buffers : Map[String, @js.Value],
  bitmaps_dir : String,
  load_bitmap : (String) -> @js.Value,
) -> Array[ExtractedFrame] {
  if frames.is_empty() {
    return []
  }
  let extracted : Array[ExtractedFrame] = []

  // Pre-load the spritesheet sharp instance if applicable
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
      if frame.spritesheet_path != current_sheet_path {
        current_sheet_path = frame.spritesheet_path
        current_sharp_img = match spritesheet_buffers.get(current_sheet_path) {
          Some(buffer) => Some(sharp_from_buffer(buffer))
          None => fail("Spritesheet buffer not found for \{current_sheet_path}")
        }
      }
      // Spritesheet frame
      let buffer = try {
        extract_ffi(
          current_sharp_img.unwrap(),
          frame.src_x,
          frame.src_y,
          frame.width,
          frame.height,
        )
        .wait()
      } catch {
        e =>
          fail(
            "Failed to extract frame id=\{frame.id} sheet=\{frame.spritesheet_path} rect=(\{frame.src_x},\{frame.src_y},\{frame.width},\{frame.height}) err=\{e}",
          )
      }
      extracted.push({ data: frame, buffer })
    }
  }
  extracted
}

///|
/// Simple pack mode: generate spritesheet from extracted frames (horizontal layout)
/// without resizing - keeps original sizes
pub async fn generate_simple_spritesheet(
  frames : Array[ExtractedFrame],
) -> (@js.Value, Array[Int]) {
  // Calculate total width and max height
  let mut total_width = 0
  let mut max_height = 0
  let offsets : Array[Int] = []
  for frame in frames {
    offsets.push(total_width)
    total_width += frame.data.width
    if frame.data.height > max_height {
      max_height = frame.data.height
    }
  }
  let base = sharp_create_ffi(total_width, max_height)
  let inputs : Array[@js.Value] = []
  for i, frame in frames {
    let input = @js.Object::new()
    input["input"] = frame.buffer
    input["left"] = offsets[i]
    input["top"] = 0
    inputs.push(input.to_value())
  }
  (composite_ffi(base, @js.Value::cast_from(inputs)).wait(), offsets)
}
