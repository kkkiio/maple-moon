/// Reanim CLI tool: process game animations
/// - Unify origin for each animation
/// - Generate spritesheets
/// - Transform __i references to __i + __off format

///|
pub(all) struct FrameData {
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
  // Which spritesheet this frame comes from
  spritesheet_path : String
}

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

///|
/// Check if json is a frame resource (has __i, __h, __w)
fn is_frame_resource(json : Json) -> Bool {
  json is { "__i": String(_), "__h": Number(_), "__w": Number(_), .. }
}

///|
/// Check if object is an animation node.
/// Requirements:
/// - Has consecutive numeric keys starting from 0 (at least 2 frames)
/// - Each numeric key's value is a frame resource (has __i, __h, __w)
fn is_animation_node(json : Json) -> Bool {
  guard json is Object(obj) else { return false }
  let mut i = 0
  while true {
    match obj.get(i.to_string()) {
      Some(value) =>
        if is_frame_resource(value) {
          i = i + 1
        } else {
          return false
        }
      None => break
    }
  }
  i >= 1
}

// ============== Core Processing ==============

///|
/// Collect frame data from an animation node.
/// All frames in an animation must come from the same spritesheet.
pub fn collect_frames(
  animation_json : Json,
  atlases : Map[String, @resource.SpritesheetMetadata],
) -> Array[FrameData] raise {
  let frames : Array[FrameData] = []
  guard animation_json is Object(obj) else { return frames }
  let mut expected_spritesheet : String? = None
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

    // Parse __i to get spritesheet path and sprite ID
    // Format: "spritesheets/Mob/1210100.img#837"
    guard img_ref.contains("#") else { continue }
    let parts = img_ref.split("#").to_array()
    guard parts.length() == 2 else { continue }
    let spritesheet_path = parts[0].to_string()
    let sprite_id = parts[1].to_string()
    let frame_key = sprite_id + ".png"

    // Validate all frames come from the same spritesheet
    match expected_spritesheet {
      None => expected_spritesheet = Some(spritesheet_path)
      Some(expected) =>
        if expected != spritesheet_path {
          fail(
            "Frame \{frame_index} comes from \{spritesheet_path}, expected \{expected}",
          )
        }
    }

    // Look up position in atlas for this spritesheet
    guard atlases.get(spritesheet_path) is Some(atlas) else {
      fail("Spritesheet \{spritesheet_path} not found in atlases")
    }
    guard atlas.frames.get(frame_key) is Some(frame_meta) else {
      fail("Frame \{frame_key} not found in spritesheet \{spritesheet_path}")
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
      src_x: frame_meta.frame.x,
      src_y: frame_meta.frame.y,
      spritesheet_path,
    })
  }

  // Sort by frame index
  frames.sort_by_key(fn(f) { f.frame_index })
  frames
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
/// Extract frames from spritesheet.
/// All frames must come from the same spritesheet.
async fn extract_frames(
  frames : Array[FrameData],
  spritesheet_buffers : Map[String, @js.Value],
) -> Array[ExtractedFrame] {
  if frames.is_empty() {
    return []
  }
  // All frames are from the same spritesheet (validated in collect_frames)
  let spritesheet_path = frames[0].spritesheet_path
  guard spritesheet_buffers.get(spritesheet_path) is Some(buffer) else {
    fail("Spritesheet buffer not found for \{spritesheet_path}")
  }
  let sharp_img = sharp_from_buffer(buffer)
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
/// Process game animations in resource:
/// 
/// - Recursively traverse JSON to find all animation nodes
/// - Unify origin for each animation
/// - Generate spritesheets
/// - Transform __i references to __i + __off format
/// 
/// When `load_spritesheet` or `save_image` is None, image operations are skipped
/// and only JSON transformation is performed (useful for testing).
pub async fn process_resource(
  src : Json,
  atlases : Map[String, @resource.SpritesheetMetadata],
  base_name : String,
  output_rel_path : String,
  load_spritesheet? : (String) -> @js.Value,
  save_image? : (String, @js.Value) -> Unit,
) -> Json {
  // Load spritesheet buffers if load_spritesheet is provided
  let spritesheet_buffers : Map[String, @js.Value] = {}
  match load_spritesheet {
    Some(loader) => {
      let spritesheet_paths = @resource.collect_spritesheet_paths(src)
      for spritesheet_ref in spritesheet_paths {
        spritesheet_buffers[spritesheet_ref] = loader(spritesheet_ref)
      }
    }
    None => ()
  }

  // Recursively process JSON tree
  process_node(
    src,
    [],
    atlases,
    spritesheet_buffers,
    base_name,
    output_rel_path,
    load_spritesheet,
    save_image,
  )
}

///|
/// Recursive helper to process a JSON node
async fn process_node(
  json : Json,
  path : Array[String],
  atlases : Map[String, @resource.SpritesheetMetadata],
  spritesheet_buffers : Map[String, @js.Value],
  base_name : String,
  output_rel_path : String,
  load_spritesheet : ((String) -> @js.Value)?,
  save_image : ((String, @js.Value) -> Unit)?,
) -> Json {
  if is_animation_node(json) {
    // This is an animation node, process it
    let action_name = path.join("_")
    let frames = collect_frames(json, atlases)
    if frames.is_empty() {
      return json
    }
    let unified = calculate_unified_size(frames)

    // Process images if callbacks are provided
    match (load_spritesheet, save_image) {
      (Some(_), Some(saver)) => {
        let extracted = extract_frames(frames, spritesheet_buffers)
        let resized = resize_frames(extracted, unified)
        let new_spritesheet = generate_spritesheet(resized, unified)
        let output_filename = "\{base_name}_\{action_name}.png"
        saver(output_filename, new_spritesheet)
      }
      _ => ()
    }

    // Update JSON
    update_animation_json(
      json, action_name, unified, base_name, output_rel_path,
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
          new_obj[key] = process_node(
            value, child_path, atlases, spritesheet_buffers, base_name, output_rel_path,
            load_spritesheet, save_image,
          )
        }
        Json::object(new_obj)
      }
      _ => json // Keep primitives and arrays as-is
    }
  }
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

  // Extract base name from input path (e.g., "1210100.img" from ".../1210100.img.json")
  let input_filename = args.input
    .split("/")
    .to_array()
    .last()
    .unwrap()
    .to_string()
  let base_name = input_filename
    .strip_suffix(".json")
    .map_or(input_filename, _.to_string())

  // Collect all spritesheet paths using resource package
  let spritesheet_paths = @resource.collect_spritesheet_paths(input_json)
  if spritesheet_paths.is_empty() {
    fail("No spritesheet references found in input JSON")
  }
  println("Found \{spritesheet_paths.length()} spritesheet(s)")

  // Load all spritesheet atlases
  let atlases : Map[String, @resource.SpritesheetMetadata] = {}
  for spritesheet_ref in spritesheet_paths {
    // Extract relative path from spritesheet ref
    // e.g. "spritesheets/Skill/210.img/skill/2100000/effect" -> "210.img/skill/2100000/effect"
    //      "spritesheets/Mob/1210100.img" -> "1210100.img"
    let spritesheet_path_parts = spritesheet_ref.split("/").to_array()
    // Skip "spritesheets" and type (e.g. "Skill" or "Mob")
    let rel_parts : Array[String] = []
    for i = 2; i < spritesheet_path_parts.length(); i = i + 1 {
      rel_parts.push(spritesheet_path_parts[i].to_string())
    }
    let rel_path = rel_parts.join("/")
    let atlas_path = "\{args.spritesheet_dir}/\{rel_path}.json"
    println("Loading atlas: \{atlas_path}")
    let atlas_content = @fs.read_file_to_string(atlas_path)
    let atlas_json = @json.parse(atlas_content)
    let metadata : @resource.SpritesheetMetadata = @json.from_json(atlas_json) catch {
      e => fail("Failed to parse atlas \{atlas_path}: \{e}")
    }
    atlases[spritesheet_ref] = metadata
    println("Loaded \{metadata.frames.length()} frames from atlas")
  }

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

  // Process resource using process_resource
  let result_json = process_resource(
    input_json,
    atlases,
    base_name,
    output_rel_path,
    load_spritesheet=fn(spritesheet_ref : String) {
      let spritesheet_path_parts = spritesheet_ref.split("/").to_array()
      // Skip "spritesheets" and type (e.g. "Skill" or "Mob")
      let rel_parts : Array[String] = []
      for i = 2; i < spritesheet_path_parts.length(); i = i + 1 {
        rel_parts.push(spritesheet_path_parts[i].to_string())
      }
      let rel_path = rel_parts.join("/")
      let png_path = "\{args.spritesheet_dir}/\{rel_path}.png"
      println("Loading spritesheet: \{png_path}")
      read_file_buffer_ffi(png_path)
    },
    save_image=fn(filename : String, buffer : @js.Value) {
      let output_path = "\{args.output}/\{filename}"
      write_file_buffer_ffi(output_path, buffer)
      println("  Saved: \{output_path}")
    },
  )

  // Save output JSON
  let output_json_path = "\{args.output}/\{base_name}.json"
  let output_content = result_json.stringify(indent=2)
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
