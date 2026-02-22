/// Process nodes - simplified recursive frame collection
/// Default mode: recursively collect ALL frames, pack into one spritesheet

///|
pub(all) struct CliArgs {
  input : String
  output : String
  spritesheet_dir : String // For __i mode
  bitmaps_dir : String // For __b mode (default: <input-dir>/bitmaps)
  match_pattern : String? // Optional path pattern filter
  resize : Bool // Whether to resize frames to unified size (legacy mode)
  keep_source_sheets : Bool // Keep source spritesheets and only inject __off
}

///|
pub(all) enum Mode {
  Spritesheet // __i references
  Bitmap // __b references
}

///|
/// Frame with its JSON path for later update
pub(all) struct FrameWithPath {
  path : Array[String]
  data : FrameData
}

///|
/// Recursively collect all frame resources from a JSON tree
pub fn collect_all_frames(
  json : Json,
  path : Array[String],
  atlases : Map[String, @resource.SpritesheetMetadata],
  result : Array[FrameWithPath],
) -> Unit {
  if is_frame_resource(json) {
    // This is a frame - parse and collect it
    match parse_frame_data(json, atlases) {
      Some(frame_data) => result.push({ path, data: frame_data })
      None => ()
    }
    return
  }

  // Not a frame, recurse into children
  match json {
    Object(obj) =>
      for key, value in obj {
        let child_path = path.copy()
        child_path.push(key)
        collect_all_frames(value, child_path, atlases, result)
      }
    Array(arr) =>
      for i, value in arr {
        let child_path = path.copy()
        child_path.push(i.to_string())
        collect_all_frames(value, child_path, atlases, result)
      }
    _ => ()
  }
}

///|
/// Update JSON tree with new __i paths and __off values
fn update_json_tree(
  json : Json,
  path : Array[String],
  frame_updates : Map[String, (String, Int, Int, Int, Int)], // path -> (__i, off_x, off_y, w, h)
) -> Json {
  let path_key = path.join("/")

  // Check if this path has a frame update
  match frame_updates.get(path_key) {
    Some((target_i, offset_x, offset_y, w, h)) =>
      // This is a frame that was processed
      match json {
        Object(obj) => {
          let new_obj : Map[String, Json] = {}
          for k, v in obj {
            if k == "__i" {
              new_obj["__i"] = Json::string(target_i)
            } else {
              new_obj[k] = v
            }
          }
          new_obj["__off"] = Json::array([
            Json::number(offset_x.to_double()),
            Json::number(offset_y.to_double()),
          ])
          new_obj["__w"] = Json::number(w.to_double())
          new_obj["__h"] = Json::number(h.to_double())
          Json::object(new_obj)
        }
        _ => json
      }
    None =>
      // Not a processed frame, recurse into children
      match json {
        Object(obj) => {
          let new_obj : Map[String, Json] = {}
          for key, value in obj {
            let child_path = path.copy()
            child_path.push(key)
            new_obj[key] = update_json_tree(value, child_path, frame_updates)
          }
          Json::object(new_obj)
        }
        Array(arr) => {
          let new_arr : Array[Json] = []
          for i, value in arr {
            let child_path = path.copy()
            child_path.push(i.to_string())
            new_arr.push(update_json_tree(value, child_path, frame_updates))
          }
          Json::array(new_arr)
        }
        _ => json
      }
  }
}

///|
/// Main processing function for default mode (simple pack)
pub async fn process_simple_pack(
  json : Json,
  atlases : Map[String, @resource.SpritesheetMetadata],
  spritesheet_buffers : Map[String, @js.Value],
  base_name : String,
  output_rel_path : String,
  bitmaps_dir : String,
  load_bitmap : ((String) -> @js.Value)?,
  save_image : ((String, @js.Value) -> Unit)?,
  keep_source_sheets? : Bool = false,
) -> Json {
  // 1. Recursively collect all frames
  let frames_with_paths : Array[FrameWithPath] = []
  collect_all_frames(json, [], atlases, frames_with_paths)
  if frames_with_paths.is_empty() {
    return json
  }

  // 2. Deduplicate frames based on source
  let unique_frames : Array[FrameData] = []
  let unique_key_to_index : Map[String, Int] = {}
  let path_to_unique_index : Map[String, Int] = {}
  for f in frames_with_paths {
    let key = if f.data.is_bitmap {
      "b:\{f.data.id}"
    } else {
      "s:\{f.data.spritesheet_path}:\{f.data.id}"
    }
    let unique_idx = match unique_key_to_index.get(key) {
      Some(idx) => idx
      None => {
        let idx = unique_frames.length()
        unique_frames.push(f.data)
        unique_key_to_index[key] = idx
        idx
      }
    }
    path_to_unique_index[f.path.join("/")] = unique_idx
  }
  @log.debug("Collected frame references", data={
    "frame_refs": frames_with_paths.length(),
    "unique_frames": unique_frames.length(),
  })

  // 3. Compute offsets (horizontal pack) for JSON update, without loading images
  let offsets : Array[Int] = []
  let mut total_width = 0
  for frame_data in unique_frames {
    offsets.push(total_width)
    total_width += frame_data.width
  }

  // 4. Extract unique frames from source and write unified sheet (optional)
  if not(keep_source_sheets) {
    match load_bitmap {
      Some(lb) => {
        let extracted = extract_frames(
          unique_frames, spritesheet_buffers, bitmaps_dir, lb,
        )

        // 5. Generate spritesheet from unique frames
        let (spritesheet, _offsets) = generate_simple_spritesheet(extracted)

        // 6. Save spritesheet
        match save_image {
          Some(saver) => saver("\{base_name}.png", spritesheet)
          None => ()
        }
      }
      None => ()
    }
  }

  // 7. Build frame_updates map for all original paths
  let frame_updates : Map[String, (String, Int, Int, Int, Int)] = {}
  for path_key, unique_idx in path_to_unique_index {
    let frame_data = unique_frames[unique_idx]
    if keep_source_sheets && not(frame_data.is_bitmap) {
      frame_updates[path_key] = (
        "\{frame_data.spritesheet_path}.png",
        frame_data.src_x,
        frame_data.src_y,
        frame_data.width,
        frame_data.height,
      )
    } else {
      let offset_x = offsets[unique_idx]
      frame_updates[path_key] = (
        "\{output_rel_path}/\{base_name}.png",
        offset_x,
        0,
        frame_data.width,
        frame_data.height,
      )
    }
  }

  // 8. Update JSON tree even if images are not loaded
  update_json_tree(json, [], frame_updates)
}

///|
/// Handle complex resource processing (moved from main.mbt)
pub async fn process_resource(
  src : Json,
  atlases : Map[String, @resource.SpritesheetMetadata],
  base_name : String,
  output_rel_path : String,
  bitmaps_dir? : String = "",
  resize? : Bool = false,
  load_spritesheet? : (String) -> @js.Value,
  load_bitmap? : (String) -> @js.Value,
  save_image? : (String, @js.Value) -> Unit,
  keep_source_sheets? : Bool = false,
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
  if resize {
    // TODO: resize mode - only for simple animations
    src
  } else {
    // Default: simple pack mode - recursively collect all frames
    process_simple_pack(
      src,
      atlases,
      spritesheet_buffers,
      base_name,
      output_rel_path,
      bitmaps_dir,
      load_bitmap,
      save_image,
      keep_source_sheets~,
    )
  }
}

///|
/// Main spritesheet mode entry point (moved from main.mbt)
pub async fn process_spritesheet(args : CliArgs) -> Unit {
  @log.debug("reanim spritesheet input", data={ "path": args.input })
  @log.debug("reanim spritesheet dir", data={ "path": args.spritesheet_dir })
  @log.debug("reanim output dir", data={ "path": args.output })

  // Read input JSON
  let input_content = @fs.read_file_to_string(args.input)
  let input_json = @json.parse(input_content)

  // Extract base name from input path
  let input_filename = args.input
    .split("/")
    .to_array()
    .last()
    .unwrap()
    .to_string()
  let base_name = input_filename
    .strip_suffix(".json")
    .map_or(input_filename, fn(s) { s.to_string() })

  // Find all spritesheet paths
  let spritesheet_paths = @resource.collect_spritesheet_paths(input_json)
  @log.debug("found spritesheet references", data={
    "count": spritesheet_paths.length(),
  })

  // Load all atlases
  let atlases : Map[String, @resource.SpritesheetMetadata] = {}
  for spritesheet_ref in spritesheet_paths {
    let spritesheet_path_parts = spritesheet_ref.split("/").to_array()
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
    if @fs.path_exists(atlas_path) {
      @log.debug("loading atlas", data={ "path": atlas_path })
      let atlas_content = @fs.read_file_to_string(atlas_path)
      let atlas_json = @json.parse(atlas_content)
      let metadata : @resource.SpritesheetMetadata = @json.from_json(atlas_json) catch {
        e => {
          @log.warn("failed to parse atlas", data={
            "path": atlas_path,
            "error": e,
          })
          continue
        }
      }
      atlases[spritesheet_ref] = metadata
      @log.debug("loaded atlas frames", data={
        "path": atlas_path,
        "frame_count": metadata.frames.length(),
      })
    } else {
      @log.warn("atlas not found", data={ "path": atlas_path })
    }
  }

  // Ensure output directory exists
  @fs.create_dir(args.output) catch {
    e => @log.warn("could not create output dir", data={ "error": e })
  }

  // Calculate output_rel_path
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
    resize=args.resize,
    keep_source_sheets=args.keep_source_sheets,
    load_spritesheet=fn(spritesheet_ref : String) {
      let spritesheet_path_parts = spritesheet_ref.split("/").to_array()
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
      let png_path = "\{args.spritesheet_dir}/\{rel_path}.png"
      @log.debug("loading spritesheet", data={ "path": png_path })
      read_file_buffer_ffi(png_path)
    },
    load_bitmap=fn(bitmap_path : String) {
      @log.debug("loading bitmap", data={ "path": bitmap_path })
      read_file_buffer_ffi(bitmap_path)
    },
    save_image=fn(filename : String, buffer : @js.Value) {
      let output_path = "\{args.output}/\{filename}"
      write_file_buffer_ffi(output_path, buffer)
      @log.debug("saved spritesheet", data={ "path": output_path })
    },
  )

  // Save output JSON
  let output_json_path = "\{args.output}/\{base_name}.json"
  let output_content = processed_json.stringify(indent=2)
  @fs.write_string_to_file(output_json_path, output_content)
  @log.debug("saved processed json", data={ "path": output_json_path })
}

///|
/// Main bitmap mode entry point (moved from main.mbt)
pub async fn process_bitmap(args : CliArgs) -> Unit {
  @log.debug("reanim bitmap input", data={ "path": args.input })
  @log.debug("reanim bitmaps dir", data={ "path": args.bitmaps_dir })
  @log.debug("reanim output dir", data={ "path": args.output })
  if args.match_pattern is Some(p) {
    @log.debug("reanim match pattern", data={ "pattern": p })
  }
  let input_content = @fs.read_file_to_string(args.input)
  let input_json = @json.parse(input_content)
  let entries_to_process : Array[(String, Json)] = match args.match_pattern {
    Some(pattern) => {
      let matched = match_entries(input_json, pattern)
      @log.debug("matched entries", data={ "count": matched.length() })
      matched
    }
    None => [("", input_json)]
  }
  @fs.create_dir(args.output) catch {
    e => @log.warn("could not create output dir", data={ "error": e })
  }
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
  for entry in entries_to_process {
    let (path, json) = entry
    let action_name = if path.is_empty() {
      let input_parts = args.input.split("/").to_array()
      let filename = input_parts.last().unwrap().to_string()
      filename.strip_suffix(".json").map_or(filename, fn(v) { v.to_string() })
    } else {
      path.split("/").to_array().last().unwrap().to_string()
    }
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
      e => @log.warn("could not create output subdir", data={ "error": e })
    }
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
    @log.debug("processing bitmap action", data={ "action": action_name })
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
        @log.debug("saved bitmap image", data={ "path": output_path })
      },
    )
    let output_json_path = "\{output_subdir}/\{action_name}.json"
    let output_content = result_json.stringify(indent=2)
    @fs.write_string_to_file(output_json_path, output_content)
    @log.debug("saved bitmap json", data={ "path": output_json_path })
  }
}

///|
/// Detect mode by scanning JSON (moved from main.mbt)
pub fn detect_mode(json : Json) -> Mode {
  match json {
    Object(obj) => {
      for _, value in obj {
        if value is { "__b": Number(_), .. } {
          return Bitmap
        }
        if value is { "__i": String(_), .. } {
          return Spritesheet
        }
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
/// Parse frame data (consolidated version)
pub fn parse_frame_data(
  json : Json,
  atlases : Map[String, @resource.SpritesheetMetadata],
) -> FrameData? {
  // Check common fields
  guard json is { "__w": Number(w, ..), "__h": Number(h, ..), .. } else {
    return None
  }

  // Get origin (default [0, 0])
  let (origin_x, origin_y) = match json {
    { "origin": Array([Number(ox, ..), Number(oy, ..)]), .. } =>
      (ox.to_int(), oy.to_int())
    _ => (0, 0)
  }

  // Get delay (default 100)
  let delay = match json {
    { "delay": Number(d, ..), .. } => d.to_int()
    _ => 100
  }

  // Check for __i (Spritesheet)
  if json is { "__i": String(img_ref), .. } {
    // source format: "path/to/sheet#123"
    if img_ref.contains("#") {
      let parts = img_ref.split("#").to_array()
      guard parts.length() == 2 else { return None }
      let spritesheet_path = parts[0].to_string()
      let sprite_id = parts[1].to_string()
      guard atlases.get(spritesheet_path) is Some(metadata) else { return None }
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

    // processed format: "path/to/sheet.png" + "__off": [x, y]
    guard json is { "__off": [Number(offx, ..), Number(offy, ..)], .. } else {
      return None
    }
    let spritesheet_path = img_ref
      .strip_suffix(".png")
      .map_or(img_ref, fn(v) { v.to_string() })
    return Some({
      id: 0,
      width: w.to_int(),
      height: h.to_int(),
      origin_x,
      origin_y,
      delay,
      frame_index: 0,
      src_x: offx.to_int(),
      src_y: offy.to_int(),
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
      src_x: 0,
      src_y: 0,
      spritesheet_path: "",
      is_bitmap: true,
    })
  }
  None
}
