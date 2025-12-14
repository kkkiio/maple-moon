/// Reanim CLI tool: process game animations
/// - Unify origin for each animation
/// - Generate spritesheets
/// - Transform __i references to __i + __off format

// ============== Sharp FFI ==============

///|
extern "js" fn require_sharp() -> @js.Value = "() => require('sharp')"

///|
let sharp : @js.Value = require_sharp()

///|
/// Read file as Buffer
extern "js" fn read_file_buffer_ffi(path : String) -> @js.Value = "(path) => require('fs').readFileSync(path)"

///|
/// Write Buffer to file
extern "js" fn write_file_buffer_ffi(path : String, buffer : @js.Value) -> Unit = "(path, buffer) => require('fs').writeFileSync(path, buffer)"

///|
/// Create sharp instance from buffer
fn sharp_from_buffer(buffer : @js.Value) -> @js.Value {
  sharp.apply([buffer])
}

///|
/// Create empty canvas
extern "js" fn sharp_create_ffi(w : Int, h : Int) -> @js.Value =
  #| (w, h) => require('sharp')({ create: { width: w, height: h, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })

///|
/// Extract region from image (async)
extern "js" fn extract_ffi(
  image : @js.Value,
  left : Int,
  top : Int,
  width : Int,
  height : Int,
) -> @js.Promise =
  #| (img, l, t, w, h) => img.clone().extract({ left: l, top: t, width: w, height: h }).png().toBuffer()

///|
/// Composite images onto base (async)
extern "js" fn composite_ffi(
  base : @js.Value,
  inputs : @js.Value,
) -> @js.Promise =
  #| (base, inputs) => base.composite(inputs).png().toBuffer()

// ============== Data Structures ==============

///|
struct FrameData {
  id : Int
  width : Int
  height : Int
  origin_x : Int
  origin_y : Int
  delay : Int
  frame_index : Int
  // Position in source spritesheet
  src_x : Int
  src_y : Int
}

///|
struct ExtractedFrame {
  data : FrameData
  buffer : @js.Value
}

///|
struct UnifiedSize {
  width : Int
  height : Int
  anchor_x : Int
  anchor_y : Int
}

// ============== CLI Argument Parsing ==============

///|
struct CliArgs {
  input : String
  spritesheet_dir : String
  output : String
}

///|
fn parse_args() -> CliArgs? {
  let args = @sys.get_cli_args()
  // args[0] is the script path
  if args.length() < 4 {
    println("Usage: reanim <input.json> <spritesheet-dir> <output-dir>")
    println(
      "Example: reanim .local/r2/Mob/1210100.img.json .local/r2/spritesheets/Mob assets/mob",
    )
    return None
  }
  Some({ input: args[1], spritesheet_dir: args[2], output: args[3] })
}

// ============== JSON Helpers ==============

///|
fn get_string(json : Json, key : String) -> String? {
  match json {
    Object(obj) =>
      match obj.get(key) {
        Some(String(s)) => Some(s)
        _ => None
      }
    _ => None
  }
}

///|
fn is_animation_node(json : Json) -> Bool {
  // Check if object has "0" key (animation frames are numbered)
  match json {
    Object(obj) => obj.get("0") != None
    _ => false
  }
}

// ============== Core Processing ==============

///|
/// Parse spritesheet atlas JSON to get frame positions
fn parse_atlas(atlas_json : Json) -> Map[String, (Int, Int, Int, Int)]? {
  // Returns map of frame_id -> (x, y, w, h)
  guard atlas_json is { "frames": Object(frames), .. } else { return None }
  let result : Map[String, (Int, Int, Int, Int)] = {}
  for name, frame_data in frames {
    guard frame_data
      is {
        "frame": {
          "x": Number(x, ..),
          "y": Number(y, ..),
          "w": Number(w, ..),
          "h": Number(h, ..),
          ..
        },
        ..
      } else {
      continue
    }
    // Remove .png suffix if present
    let id = if name.has_suffix(".png") {
      name.substring(end=name.length() - 4)
    } else {
      name
    }
    result[id] = (x.to_int(), y.to_int(), w.to_int(), h.to_int())
  }
  Some(result)
}

///|
/// Collect frame data from an animation node
fn collect_frames(
  animation_json : Json,
  atlas : Map[String, (Int, Int, Int, Int)],
) -> Array[FrameData] {
  let frames : Array[FrameData] = []
  guard animation_json is Object(obj) else { return frames }
  for key, frame_json in obj {
    // Skip non-numeric keys
    guard key.iter().all(fn(c) { c >= '0' && c <= '9' }) else { continue }
    let frame_index = @strconv.parse_int(key) catch { _ => continue }

    // Parse frame data
    guard frame_json
      is {
        "__i": String(img_ref),
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

    // Parse __i to get sprite ID
    // Format: "spritesheets/Mob/1210100.img#837"
    guard img_ref.contains("#") else { continue }
    let parts = img_ref.split("#").to_array()
    guard parts.length() == 2 else { continue }
    let sprite_id = parts[1].to_string()

    // Look up position in atlas
    guard atlas.get(sprite_id) is Some((src_x, src_y, _, _)) else {
      println("Warning: sprite \{sprite_id} not found in atlas")
      continue
    }
    frames.push({
      id: @strconv.parse_int(sprite_id) catch {
        _ => 0
      },
      width: w.to_int(),
      height: h.to_int(),
      origin_x,
      origin_y,
      delay,
      frame_index,
      src_x,
      src_y,
    })
  }

  // Sort by frame index
  frames.sort_by_key(fn(f) { f.frame_index })
  frames
}

///|
/// Calculate unified size based on origin alignment
fn calculate_unified_size(frames : Array[FrameData]) -> UnifiedSize {
  let mut max_left = 0
  let mut max_right = 0
  let mut max_top = 0
  let mut max_bottom = 0
  for frame in frames {
    max_left = @math.maximum(max_left, frame.origin_x)
    max_top = @math.maximum(max_top, frame.origin_y)
    max_right = @math.maximum(max_right, frame.width - frame.origin_x)
    max_bottom = @math.maximum(max_bottom, frame.height - frame.origin_y)
  }
  {
    width: max_left + max_right,
    height: max_top + max_bottom,
    anchor_x: max_left,
    anchor_y: max_top,
  }
}

///|
/// Extract frames from spritesheet
async fn extract_frames(
  frames : Array[FrameData],
  spritesheet_buffer : @js.Value,
) -> Array[ExtractedFrame] {
  let sharp_img = sharp_from_buffer(spritesheet_buffer)
  let extracted : Array[ExtractedFrame] = []
  for frame in frames {
    let buffer = extract_ffi(
      sharp_img,
      frame.src_x,
      frame.src_y,
      frame.width,
      frame.height,
    ).wait()
    extracted.push({ data: frame, buffer })
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

      // Create new frame object with updated __i and __off
      let new_frame : Map[String, Json] = {}
      for k, v in frame_obj {
        if k == "__i" {
          // Replace with new spritesheet reference (relative to assets)
          new_frame["__i"] = Json::string(
            "\{output_rel_path}/\{base_name}_\{action_name}.png",
          )
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
      // Add __off for position in new spritesheet
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
/// Process a single animation
async fn process_animation(
  action_name : String,
  animation_json : Json,
  spritesheet_buffer : @js.Value,
  atlas : Map[String, (Int, Int, Int, Int)],
  output_dir : String,
  base_name : String,
  output_rel_path : String,
) -> Json {
  println("Processing animation: \{action_name}")

  // Collect frame data
  let frames = collect_frames(animation_json, atlas)
  if frames.is_empty() {
    println("  No frames found, skipping")
    return animation_json
  }
  println("  Found \{frames.length()} frames")

  // Calculate unified size
  let unified = calculate_unified_size(frames)
  println(
    "  Unified size: \{unified.width}x\{unified.height}, anchor: (\{unified.anchor_x}, \{unified.anchor_y})",
  )

  // Extract frames from spritesheet
  let extracted = extract_frames(frames, spritesheet_buffer)
  println("  Extracted \{extracted.length()} frames")

  // Resize to unified size
  let resized = resize_frames(extracted, unified)
  println("  Resized frames")

  // Generate new spritesheet
  let new_spritesheet = generate_spritesheet(resized, unified)
  println("  Generated spritesheet")

  // Save spritesheet
  let output_path = "\{output_dir}/\{base_name}_\{action_name}.png"
  write_file_buffer_ffi(output_path, new_spritesheet)
  println("  Saved: \{output_path}")

  // Update JSON
  update_animation_json(
    animation_json, action_name, unified, base_name, output_rel_path,
  )
}

///|
/// Main processing function
async fn process_mob(args : CliArgs) -> Unit {
  println("Input: \{args.input}")
  println("Spritesheet dir: \{args.spritesheet_dir}")
  println("Output: \{args.output}")

  // Read input JSON
  let input_content = @fs.read_file_to_string(args.input)
  let input_json = @json.parse(input_content)
  guard input_json is Object(root_obj) else {
    fail("Input is not a JSON object")
  }

  // Extract base name from input path (e.g., "1210100.img" from ".../1210100.img.json")
  let input_filename = args.input
    .split("/")
    .to_array()
    .last()
    .unwrap()
    .to_string()
  let base_name = if input_filename.has_suffix(".json") {
    input_filename.substring(end=input_filename.length() - 5)
  } else {
    input_filename
  }

  // Find spritesheet atlas JSON
  // The __i references like "spritesheets/Mob/1210100.img#837" tell us which spritesheet to use
  let mut spritesheet_ref = ""
  for _, v in root_obj {
    if is_animation_node(v) {
      guard v is Object(anim_obj) else { continue }
      for _, frame in anim_obj {
        if get_string(frame, "__i") is Some(ref) && ref.contains("#") {
          spritesheet_ref = ref.split("#").to_array()[0].to_string()
          break
        }
      }
      if spritesheet_ref != "" {
        break
      }
    }
  }
  if spritesheet_ref == "" {
    fail("No spritesheet reference found in input JSON")
  }

  // spritesheets/Mob/1210100.img -> .local/r2/spritesheets/Mob/1210100.img
  let spritesheet_path_parts = spritesheet_ref.split("/").to_array()
  let spritesheet_filename = spritesheet_path_parts.last().unwrap().to_string()
  let atlas_path = "\{args.spritesheet_dir}/\{spritesheet_filename}.json"
  let png_path = "\{args.spritesheet_dir}/\{spritesheet_filename}.png"
  println("Loading atlas: \{atlas_path}")
  let atlas_content = @fs.read_file_to_string(atlas_path)
  let atlas_json = @json.parse(atlas_content)
  let atlas = parse_atlas(atlas_json).unwrap()
  println("Loaded \{atlas.size()} frames from atlas")
  println("Loading spritesheet: \{png_path}")
  let spritesheet_buffer = read_file_buffer_ffi(png_path)

  // Ensure output directory exists
  @fs.create_dir(args.output) catch {
    e => println("Warning: could not create output dir: \{e}")
  }

  // Calculate output_rel_path (relative to assets directory)
  // e.g. "assets/mob" -> "mob", "/Users/.../assets/mob" -> "mob"
  let output_rel_path = {
    let parts = args.output.split("/").to_array()
    // Find "assets" in path and take everything after it
    let mut found_assets = false
    let result : Array[String] = []
    for part in parts {
      if found_assets {
        result.push(part.to_string())
      } else if part == "assets" {
        found_assets = true
      }
    }
    if result.is_empty() {
      // Fallback: use last component
      parts.last().unwrap().to_string()
    } else {
      result.join("/")
    }
  }
  println("Output relative path: \{output_rel_path}")

  // Process each animation
  let new_root : Map[String, Json] = {}
  for key, value in root_obj {
    if is_animation_node(value) {
      let new_anim = process_animation(
        key,
        value,
        spritesheet_buffer,
        atlas,
        args.output,
        base_name,
        output_rel_path,
      )
      new_root[key] = new_anim
    } else {
      // Keep non-animation nodes as-is (like "info")
      new_root[key] = value
    }
  }

  // Save output JSON
  let output_json_path = "\{args.output}/\{base_name}.json"
  let output_content = Object(new_root).stringify(indent=2)
  @fs.write_string_to_file(output_json_path, output_content)
  println("Saved: \{output_json_path}")
  println("Done!")
}

///|
fn main {
  guard parse_args() is Some(args) else { return }
  @js.async_run(fn() {
    process_mob(args) catch {
      e => {
        println("Error: \{e}")
        @sys.exit(1)
      }
    }
  })
}
