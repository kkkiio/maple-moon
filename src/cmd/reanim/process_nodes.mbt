/// Process nodes - iterative JSON tree processing for animations
/// Avoids stack overflow when processing large nested structures

///|
/// Stack item for iterative JSON processing
struct ProcessStackItem {
  json : Json
  path : Array[String]
}

///|
/// Iterative helper to process a JSON tree (avoids stack overflow)
/// 
/// Use iterative approach with explicit work queue to avoid stack overflow
/// Strategy: 
/// 1. First pass: collect all leaf nodes (Animation, MultiPartAnimation, Frame) with their paths
/// 2. Process each leaf node
/// 3. Rebuild the tree structure from processed results
async fn process_node(
  json : Json,
  path : Array[String],
  atlases : Map[String, @resource.SpritesheetMetadata],
  spritesheet_buffers : Map[String, @js.Value],
  base_name : String,
  output_rel_path : String,
  bitmaps_dir : String,
  load_spritesheet : ((String) -> @js.Value)?,
  load_bitmap : ((String) -> @js.Value)?,
  save_image : ((String, @js.Value) -> Unit)?,
) -> Json {

  // Map from path string to processed result
  let processed_results : Map[String, Json] = {}

  // Work queue for BFS traversal
  let work_queue : Array[ProcessStackItem] = []
  work_queue.push({ json, path })

  // First pass: find and process all leaf nodes
  while not(work_queue.is_empty()) {
    let item = work_queue.pop().unwrap()
    let current_json = item.json
    let current_path = item.path
    let path_key = current_path.join("/")
    let node_type = identify_node_type(current_json)
    match node_type {
      Animation => {
        // Simple Animation - process directly
        let action_name = current_path.join("_")
        let frames = collect_frames(current_json, atlases, None)
        let result = if frames.is_empty() {
          current_json
        } else {
          process_animation_frames(
            current_json,
            frames,
            action_name,
            base_name,
            output_rel_path,
            None,
            spritesheet_buffers,
            bitmaps_dir,
            load_spritesheet,
            load_bitmap,
            save_image,
          )
        }
        processed_results[path_key] = result
      }
      MultiPartAnimation => {
        // Multi-Part Animation - process all layers
        let layers = get_animation_layers(current_json)
        let action_name = current_path.join("_")
        let mut result_json = current_json
        for layer in layers {
          let frames = collect_frames(current_json, atlases, Some(layer))
          if frames.is_empty() {
            continue
          }
          let layer_action_name = "\{action_name}_\{layer}"
          process_animation_frames_images_only(
            frames, layer_action_name, base_name, spritesheet_buffers, bitmaps_dir,
            load_spritesheet, load_bitmap, save_image,
          )
          let unified = calculate_unified_size(frames)
          result_json = update_animation_json(
            result_json,
            "\{action_name}_\{layer}",
            unified,
            base_name,
            output_rel_path,
            Some(layer),
          )
        }
        processed_results[path_key] = result_json
      }
      Frame => {
        // Single frame - process directly
        let frame_data = parse_frame_data(current_json, atlases)
        let result = match frame_data {
          Some(frame) => {
            let frames = [frame]
            let suffix = current_path.join("_")
            process_animation_frames_images_only(
              frames, suffix, base_name, spritesheet_buffers, bitmaps_dir, load_spritesheet,
              load_bitmap, save_image,
            )
            let unified = calculate_unified_size(frames)
            update_frame_json(
              current_json, suffix, unified, base_name, output_rel_path,
            )
          }
          None => current_json
        }
        processed_results[path_key] = result
      }
      Unknown =>
        // Container node - add children to work queue
        match current_json {
          Object(obj) =>
            for key, value in obj {
              let child_path = current_path.copy()
              child_path.push(key)
              work_queue.push({ json: value, path: child_path })
            }
          _ =>
            // Non-object leaf - just store as-is
            processed_results[path_key] = current_json
        }
    }
  }

  // Second pass: rebuild the tree from processed results
  rebuild_json_tree(json, path, processed_results)
}

///|
/// Rebuild JSON tree from processed results (iterative)
fn rebuild_json_tree(
  original : Json,
  path : Array[String],
  processed_results : Map[String, Json],
) -> Json {
  let path_key = path.join("/")

  // Check if this exact path was processed
  match processed_results.get(path_key) {
    Some(result) => result
    None =>
      // This is a container node, rebuild from children
      match original {
        Object(obj) => {
          let new_obj : Map[String, Json] = {}
          for key, value in obj {
            let child_path = path.copy()
            child_path.push(key)
            new_obj[key] = rebuild_json_tree(
              value, child_path, processed_results,
            )
          }
          Json::object(new_obj)
        }
        _ => original
      }
  }
}

///|
/// Helper to process images and return updated JSON for a simple animation
async fn process_animation_frames(
  json : Json,
  frames : Array[FrameData],
  action_name : String,
  base_name : String,
  output_rel_path : String,
  layer : String?,
  spritesheet_buffers : Map[String, @js.Value],
  bitmaps_dir : String,
  load_spritesheet : ((String) -> @js.Value)?,
  load_bitmap : ((String) -> @js.Value)?,
  save_image : ((String, @js.Value) -> Unit)?,
) -> Json {
  process_animation_frames_images_only(
    frames, action_name, base_name, spritesheet_buffers, bitmaps_dir, load_spritesheet,
    load_bitmap, save_image,
  )
  let unified = calculate_unified_size(frames)
  update_animation_json(
    json, action_name, unified, base_name, output_rel_path, layer,
  )
}

///|
/// Helper to generate images only (for multi-part reuse)
async fn process_animation_frames_images_only(
  frames : Array[FrameData],
  action_suffix : String,
  base_name : String,
  spritesheet_buffers : Map[String, @js.Value],
  bitmaps_dir : String,
  load_spritesheet : ((String) -> @js.Value)?,
  load_bitmap : ((String) -> @js.Value)?,
  save_image : ((String, @js.Value) -> Unit)?,
) -> Unit {
  let unified = calculate_unified_size(frames)
  match (load_spritesheet, load_bitmap, save_image) {
    (Some(_), Some(lb), Some(saver)) => {
      let extracted = extract_frames(
        frames, spritesheet_buffers, bitmaps_dir, lb,
      )
      let resized = resize_frames(extracted, unified)
      let new_spritesheet = generate_spritesheet(resized, unified)
      let output_filename = "\{base_name}_\{action_suffix}.png"
      saver(output_filename, new_spritesheet)
    }
    _ => ()
  }
}

///|
/// Helper to update a single frame JSON
fn update_frame_json(
  json : Json,
  action_suffix : String,
  unified : UnifiedSize,
  base_name : String,
  output_rel_path : String,
) -> Json {
  guard json is Object(obj) else { return json }
  let new_frame_data : Map[String, Json] = {}
  for k, v in obj {
    if k == "__i" {
      new_frame_data["__i"] = Json::string(
        "\{output_rel_path}/\{base_name}_\{action_suffix}.png",
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
  // We should also update __w and __h to match unified size
  new_frame_data["__w"] = Json::number(unified.width.to_double())
  new_frame_data["__h"] = Json::number(unified.height.to_double())
  Json::object(new_frame_data)
}
