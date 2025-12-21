///|
pub(all) struct FrameData {
  id : Int
  width : Int
  height : Int
  origin_x : Int
  origin_y : Int
  delay : Int
  mut frame_index : Int

  // Position in source spritesheet
  src_x : Int
  src_y : Int
  // Which spritesheet this frame comes from
  spritesheet_path : String
  // Bitmap specific
  is_bitmap : Bool
}

///|
pub enum NodeType {
  Frame
  Animation // Simple Animation
  MultiPartAnimation
  Unknown
}

///|
/// Check if json is a frame resource (has __i or __b with dimensions)
pub fn is_frame_resource(json : Json) -> Bool {
  match json {
    // Check for __i (spritesheet)
    { "__i": String(_), "__h": Number(_), "__w": Number(_), .. } => true
    // Check for __b (bitmap)
    { "__b": Number(_), "__h": Number(_), "__w": Number(_), .. } => true
    _ => false
  }
}

///|
/// Identify the type of the JSON node
pub fn identify_node_type(json : Json) -> NodeType {
  if is_frame_resource(json) {
    return Frame
  }
  match json {
    Object(obj) => {
      // Check for sequential numeric keys starting from "0"
      let has_frames = match obj.get("0") {
        Some(_) => true // At least 1 frame for an animation
        None => false
      }
      if has_frames {
        let frame0 = obj.get("0").unwrap()
        if is_frame_resource(frame0) {
          return Animation
        } else {
          // If frame "0" is not a direct resource, check if it contains sub-parts that are resources
          match frame0 {
            Object(frame_obj) => {
              for _, v in frame_obj {
                if is_frame_resource(v) {
                  return MultiPartAnimation
                }
              }
              Unknown
            }
            _ => Unknown
          }
        }
      } else {
        Unknown
      }
    }
    _ => Unknown
  }
}

///|
/// Get all layer names in a multi-part animation node
/// Examines ALL frames to find all properties that are valid frame resources
/// This ensures layers that only appear in certain frames (like armOverHair) are detected
pub fn get_animation_layers(json : Json) -> Array[String] {
  match json {
    Object(obj) => {
      let layer_set : Map[String, Unit] = {}
      // Scan all frames to collect unique layer names
      for key, value in obj {
        // Only look at numeric frame keys
        ignore(@strconv.parse_int(key)) catch {
          _ => continue
        }
        guard value is Object(frame_obj) else { continue }
        for k, v in frame_obj {
          if is_frame_resource(v) && not(layer_set.contains(k)) {
            layer_set[k] = ()
          }
        }
      }
      layer_set.keys().collect()
    }
    _ => []
  }
}
