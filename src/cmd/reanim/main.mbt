/// Reanim CLI tool: process game animations
/// - Unify origin for each animation
/// - Generate spritesheets
/// - Transform __i references to __i + __off format

///|
struct CliArgs {
  input : String
  output : String
  spritesheet_dir : String // For __i mode
  bitmaps_dir : String // For __b mode (default: <input-dir>/bitmaps)
  match_pattern : String? // Optional path pattern filter
}

///|
enum Mode {
  Spritesheet // __i references
  Bitmap // __b references
}

///|
fn parse_args() -> CliArgs? {
  let args = @sys.get_cli_args()
  // Skip the first argument (script path)
  let argv = if args.length() > 0 {
    let arr : Array[String] = []
    for i = 1; i < args.length(); i = i + 1 {
      arr.push(args[i].to_string())
    }
    arr
  } else {
    []
  }

  // Refs for ArgParser
  let match_pattern : Ref[String] = Ref::new("")
  let bitmaps_dir : Ref[String] = Ref::new("")
  let spritesheet_dir : Ref[String] = Ref::new("")

  // Positional arguments
  let positional : Array[String] = []

  // Spec: (long_opt, short_opt, spec, description)
  let spec : Array[(String, String, @ArgParser.Spec, String)] = [
    (
      "--match",
      "-m",
      @ArgParser.Set_string(match_pattern),
      "Filter by path pattern (e.g., BasicEff.img/Teleport)",
    ),
    (
      "--bitmaps-dir",
      "-b",
      @ArgParser.Set_string(bitmaps_dir),
      "Override bitmaps dir (default: <input-dir>/bitmaps)",
    ),
    (
      "--spritesheet-dir",
      "-s",
      @ArgParser.Set_string(spritesheet_dir),
      "Spritesheet dir (for __i mode)",
    ),
  ]
  let usage =
    #| Reanim CLI tool - Process game animations
    #| 
    #| Usage: reanim <input.json> <output-dir> [options]
    #| 
    #| Examples:
    #|   reanim .local/r2/Mob/1210100.img.json assets/mob -s .local/r2/spritesheets/Mob
    #|   reanim .local/nx/Effect.nx/nx.json assets/Effect -m BasicEff.img/Teleport
    #|

  // Parse arguments
  @ArgParser.parse(spec, fn(arg) { positional.push(arg) }, usage, argv) catch {
    @ArgParser.ErrorMsg(msg) => {
      println(msg)
      return None
    }
    e => {
      println("Error: \{e}")
      return None
    }
  }

  // Validate positional arguments
  if positional.length() < 2 {
    println("Error: Missing required arguments <input.json> <output-dir>")
    println("")
    println(usage)
    return None
  }
  let input = positional[0]
  let output = positional[1]

  // Derive input directory
  let input_dir = {
    let parts = input.split("/").to_array()
    if parts.length() > 1 {
      let dir_parts : Array[String] = []
      for j = 0; j < parts.length() - 1; j = j + 1 {
        dir_parts.push(parts[j].to_string())
      }
      dir_parts.join("/")
    } else {
      "."
    }
  }

  // Set defaults
  let final_bitmaps_dir = if bitmaps_dir.val.is_empty() {
    input_dir + "/bitmaps"
  } else {
    bitmaps_dir.val
  }
  let final_spritesheet_dir = if spritesheet_dir.val.is_empty() {
    input_dir + "/spritesheets"
  } else {
    spritesheet_dir.val
  }
  let final_match : String? = if match_pattern.val.is_empty() {
    None
  } else {
    Some(match_pattern.val)
  }
  Some({
    input,
    output,
    spritesheet_dir: final_spritesheet_dir,
    bitmaps_dir: final_bitmaps_dir,
    match_pattern: final_match,
  })
}

///|
/// Parse frame data from a JSON node.
///
/// Frame resources come in two mutually exclusive formats:
/// - `__i` (spritesheet mode): References sprites via paths like "spritesheets/Mob/xxx.img#123"
/// - `__b` (bitmap mode): References bitmaps via numeric IDs like `"__b": 1902`
///
/// A JSON resource file will use either `__i` or `__b` format, never both.
fn parse_frame_data(
  json : Json,
  atlases : Map[String, @resource.SpritesheetMetadata],
) -> FrameData? {
  // Check common fields
  guard json is { "__w": Number(w, ..), "__h": Number(h, ..), .. } else {
    return None
  }

  // Get origin (default [0, 0])
  let (origin_x, origin_y) = match json {
    { "origin": Array([Number(x, ..), Number(y, ..)]), .. } =>
      (x.to_int(), y.to_int())
    _ => (0, 0)
  }

  // Get delay (default 100)
  let delay = match json {
    { "delay": Number(d, ..), .. } => d.to_int()
    _ => 100
  }

  // Check for __i (Spritesheet)
  if json is { "__i": String(img_ref), .. } {
    // Parse __i to get spritesheet path and sprite ID
    // Format: "spritesheets/Mob/1210100.img#837"
    guard img_ref.contains("#") else { return None }
    let parts = img_ref.split("#").to_array()
    guard parts.length() == 2 else { return None }
    let spritesheet_path = parts[0].to_string()
    let sprite_id = parts[1].to_string()

    // Find in atlases
    guard atlases.get(spritesheet_path) is Some(metadata) else { return None }

    // Find frame in metadata
    let frame_name = if sprite_id.has_suffix(".png") {
      sprite_id
    } else {
      "\{sprite_id}.png"
    }
    guard metadata.frames.get(frame_name) is Some(frame_meta) else {
      return None
    }
    return Some({
      id: @strconv.parse_int(sprite_id) catch {
        _ => 0
      },
      width: w.to_int(),
      height: h.to_int(),
      origin_x,
      origin_y,
      delay,
      frame_index: 0,
      src_x: frame_meta.frame.x,
      src_y: frame_meta.frame.y,
      spritesheet_path,
      is_bitmap: false,
    })
  }

  // Check for __b (Bitmap)
  if json is { "__b": Number(b_id, ..), .. } {
    return Some({
      id: b_id.to_int(),
      width: w.to_int(),
      height: h.to_int(),
      origin_x,
      origin_y,
      delay,
      frame_index: 0,
      src_x: 0, // Ignored for bitmap
      src_y: 0, // Ignored for bitmap
      spritesheet_path: "", // Ignored/empty for bitmap
      is_bitmap: true,
    })
  }
  None
}

///|
/// Collect frame data from an animation node.
/// All frames in an animation must come from the same spritesheet (if using spritesheets).
pub fn collect_frames(
  animation_json : Json,
  atlases : Map[String, @resource.SpritesheetMetadata],
  layer : String?,
) -> Array[FrameData] raise {
  let frames : Array[FrameData] = []
  guard animation_json is Object(obj) else { return frames }
  let mut expected_spritesheet : String? = None
  for key, frame_json in obj {
    // Skip non-numeric keys
    guard key.iter().all(fn(c) { c >= '0' && c <= '9' }) else { continue }
    let frame_index = @strconv.parse_int(key) catch { _ => continue }

    // Extract frame data based on layer
    let frame_data_json = match layer {
      Some(l) =>
        match frame_json {
          Object(o) => o.get(l).unwrap_or(Json::null())
          _ => Json::null()
        }
      None => frame_json
    }

    // Check if valid frame resource first
    guard is_frame_resource(frame_data_json) else { continue }

    // Parse frame data
    match parse_frame_data(frame_data_json, atlases) {
      Some(fd) => {
        fd.frame_index = frame_index
        // Validate spritesheet consistency
        if not(fd.is_bitmap) {
          match expected_spritesheet {
            None => expected_spritesheet = Some(fd.spritesheet_path)
            Some(expected) =>
              if expected != fd.spritesheet_path {
                fail(
                  "Frame \{frame_index} comes from \{fd.spritesheet_path}, expected \{expected}",
                )
              }
          }
        }
        frames.push(fd)
      }
      None => continue
    }
  }

  // Sort by frame index
  frames.sort_by_key(fn(f) { f.frame_index })
  frames
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
  bitmaps_dir? : String = "",
  load_spritesheet? : (String) -> @js.Value,
  load_bitmap? : (String) -> @js.Value,
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
    bitmaps_dir,
    load_spritesheet,
    load_bitmap,
    save_image,
  )
}

///|
/// Main processing function
pub async fn process_spritesheet(args : CliArgs) -> Unit {
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
    .map_or(input_filename, fn(s) { s.to_string() })

  // Find all spritesheet paths (for info only)
  let spritesheet_paths = @resource.collect_spritesheet_paths(input_json)
  println("Found \{spritesheet_paths.length()} spritesheet references")

  // Load all atlases (still needed for metadata lookup during processing)
  let atlases : Map[String, @resource.SpritesheetMetadata] = {}
  for spritesheet_ref in spritesheet_paths {
    // Extract relative path from spritesheet ref
    let spritesheet_path_parts = spritesheet_ref.split("/").to_array()
    // Skip "spritesheets" and type (e.g. "Skill" or "Mob")
    let rel_parts : Array[String] = []
    let start_idx = if spritesheet_path_parts.length() >= 5 &&
      spritesheet_path_parts[1] == "Character" &&
      spritesheet_path_parts[3] == "spritesheets" {
      4
    } else {
      2
    }
    for i = start_idx; i < spritesheet_path_parts.length(); i = i + 1 {
      rel_parts.push(spritesheet_path_parts[i].to_string())
    }
    let rel_path = rel_parts.join("/")
    let atlas_path = "\{args.spritesheet_dir}/\{rel_path}.json"

    // Warn instead of fail if missing, or maybe valid for bitmaps
    if @fs.path_exists(atlas_path) {
      println("Loading atlas: \{atlas_path}")
      let atlas_content = @fs.read_file_to_string(atlas_path)
      let atlas_json = @json.parse(atlas_content)
      let metadata : @resource.SpritesheetMetadata = @json.from_json(atlas_json) catch {
        e => {
          println("Warning: Failed to parse atlas \{atlas_path}: \{e}")
          continue
        }
      }
      atlases[spritesheet_ref] = metadata
      println("Loaded \{metadata.frames.length()} frames from atlas")
    } else {
      println("Warning: Atlas not found at \{atlas_path}")
    }
  }

  // Ensure output directory exists
  @fs.create_dir(args.output) catch {
    e => println("Warning: could not create output dir: \{e}")
  }

  // Calculate output_rel_path (relative to assets directory)
  let output_rel_path = {
    let parts = args.output.split("/").to_array()
    let mut found_assets = false
    let result : Array[String] = []
    for part in parts {
      if found_assets {
        result.push(part.to_string())
      }
      if part == "assets" {
        found_assets = true
      }
    }
    if result.is_empty() {
      args.output
    } else {
      result.join("/")
    }
  }

  // Process resource
  let processed_json = process_resource(
    input_json,
    atlases,
    base_name,
    output_rel_path,
    bitmaps_dir=args.bitmaps_dir,
    load_spritesheet=fn(spritesheet_ref : String) {
      let spritesheet_path_parts = spritesheet_ref.split("/").to_array()
      // Skip "spritesheets" and type (e.g. "Skill" or "Mob")
      let rel_parts : Array[String] = []
      // Handle Weapon path: /Character/Weapon/spritesheets/...
      let start_idx = if spritesheet_path_parts.length() >= 5 &&
        spritesheet_path_parts[1] == "Character" &&
        spritesheet_path_parts[3] == "spritesheets" {
        4
      } else {
        2
      }
      for i = start_idx; i < spritesheet_path_parts.length(); i = i + 1 {
        rel_parts.push(spritesheet_path_parts[i].to_string())
      }
      let rel_path = rel_parts.join("/")
      let png_path = "\{args.spritesheet_dir}/\{rel_path}.png"
      println("Loading spritesheet: \{png_path}")
      read_file_buffer_ffi(png_path)
    },
    load_bitmap=fn(bitmap_path : String) {
      println("Loading bitmap: \{bitmap_path}")
      read_file_buffer_ffi(bitmap_path)
    },
    save_image=fn(filename : String, buffer : @js.Value) {
      let output_path = "\{args.output}/\{filename}"
      write_file_buffer_ffi(output_path, buffer)
      println("  Saved: \{output_path}")
    },
  )

  // Save output JSON
  let output_json_path = "\{args.output}/\{base_name}.json"
  let output_content = processed_json.stringify(indent=2)
  @fs.write_string_to_file(output_json_path, output_content)
  println("Saved: \{output_json_path}")
  println("Done!")
}

///|
/// Process bitmap mode with --match pattern support
async fn process_bitmap(args : CliArgs) -> Unit {
  println("Input: \{args.input}")
  println("Bitmaps dir: \{args.bitmaps_dir}")
  println("Output: \{args.output}")
  if args.match_pattern is Some(p) {
    println("Match pattern: \{p}")
  }

  // Read input JSON
  let input_content = @fs.read_file_to_string(args.input)
  let input_json = @json.parse(input_content)

  // Apply match filter if provided
  let entries_to_process : Array[(String, Json)] = match args.match_pattern {
    Some(pattern) => {
      let matched = match_entries(input_json, pattern)
      println("Found \{matched.length()} matched entries")
      matched
    }
    None =>
      // No filter, process entire JSON
      [("", input_json)]
  }

  // Ensure output directory exists
  @fs.create_dir(args.output) catch {
    e => println("Warning: could not create output dir: \{e}")
  }

  // Calculate output_rel_path (relative to assets directory)
  let output_rel_path = {
    let parts = args.output.split("/").to_array()
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
      parts.last().unwrap().to_string()
    } else {
      result.join("/")
    }
  }

  // Process each matched entry
  for entry in entries_to_process {
    let (path, json) = entry
    let action_name = if path.is_empty() {
      // Use input filename as base name
      let input_parts = args.input.split("/").to_array()
      let filename = input_parts.last().unwrap().to_string()
      filename.strip_suffix(".json").map_or(filename, _.to_string())
    } else {
      path.split("/").to_array().last().unwrap().to_string()
    }

    // Create subdirectory based on path
    let output_subdir = if path.is_empty() {
      args.output.to_string()
    } else {
      let path_parts = path.split("/").to_array()
      let dir_parts : Array[String] = [args.output.to_string()]
      for i = 0; i < path_parts.length() - 1; i = i + 1 {
        dir_parts.push(path_parts[i].to_string())
      }
      dir_parts.join("/")
    }
    @fs.create_dir(output_subdir) catch {
      e => println("Warning: could not create subdir: \{e}")
    }

    // Calculate relative path for the output
    let full_output_rel_path = if path.is_empty() {
      output_rel_path
    } else {
      let path_parts = path.split("/").to_array()
      let parts : Array[String] = [output_rel_path.to_string()]
      for i = 0; i < path_parts.length() - 1; i = i + 1 {
        parts.push(path_parts[i].to_string())
      }
      parts.join("/")
    }
    println("Processing: \{action_name}")
    let result_json = process_bitmap_resource(
      json,
      full_output_rel_path,
      action_name,
      load_bitmap=fn(bitmap_id : Int) {
        let png_path = "\{args.bitmaps_dir}/\{bitmap_id}.png"
        read_file_buffer_ffi(png_path)
      },
      save_image=fn(filename : String, buffer : @js.Value) {
        let output_path = "\{output_subdir}/\{filename}"
        write_file_buffer_ffi(output_path, buffer)
        println("  Saved: \{output_path}")
      },
    )

    // Save output JSON
    let output_json_path = "\{output_subdir}/\{action_name}.json"
    let output_content = result_json.stringify(indent=2)
    @fs.write_string_to_file(output_json_path, output_content)
    println("  Saved: \{output_json_path}")
  }
  println("Done!")
}

///|
/// Detect mode by scanning JSON for __b or __i keys
fn detect_mode(json : Json) -> Mode {
  match json {
    Object(obj) => {
      for _, value in obj {
        // Check if this is a frame with __b or __i
        if value is { "__b": Number(_), .. } {
          return Bitmap
        }
        if value is { "__i": String(_), .. } {
          return Spritesheet
        }
        // Recurse into child objects
        let child_mode = detect_mode(value)
        match child_mode {
          Bitmap => return Bitmap
          Spritesheet => return Spritesheet
        }
      }
      Spritesheet // Default
    }
    _ => Spritesheet
  }
}

///|
async fn main {
  guard parse_args() is Some(args) else { return }
  // Read input JSON to detect mode
  let input_content = @fs.read_file_to_string(args.input) catch {
    e => {
      println("Error reading input: \{e}")
      @sys.exit(1)
      return
    }
  }
  let input_json = @json.parse(input_content) catch {
    e => {
      println("Error parsing JSON: \{e}")
      @sys.exit(1)
      return
    }
  }
  let mode = detect_mode(input_json)
  match mode {
    Bitmap => {
      println("Detected bitmap mode (__b references)")
      process_bitmap(args) catch {
        e => {
          println("Error: \{e}")
          @sys.exit(1)
        }
      }
    }
    Spritesheet => {
      println("Detected spritesheet mode (__i references)")
      process_spritesheet(args) catch {
        e => {
          println("Error: \{e}")
          @sys.exit(1)
        }
      }
    }
  }
}
