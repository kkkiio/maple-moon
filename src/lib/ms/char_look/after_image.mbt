///|
/// 残影. 角色移动或攻击时，在身后留下的半透明或特效化的影子效果，用来表现速度感或技能的威力。
struct AfterImage {
  animation : @sprite.Animation
  range : @struct.Rectangle[Int]
  first_frame : Int
  mut displayed : Bool
  mut entity : @entity.Entity?
}

///|
#alias(AfterImageResource, deprecated)
struct NxAfterImage {
  animation : @resource.NxAnimation
  range : @struct.Rectangle[Int]
  first_frame : Int
}

///|
pub impl @json.FromJson for NxAfterImage with from_json(json, path) -> NxAfterImage raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }

  // Parse range from "lt" and "rb" fields
  let range = {
    let left_top = @json.from_json(
      obj.get("lt").unwrap_or(Json::null()),
      path=path.add_key("lt"),
    )
    let right_bottom = @json.from_json(
      obj.get("rb").unwrap_or(Json::null()),
      path=path.add_key("rb"),
    )
    @struct.Rectangle::new(left_top, right_bottom)
  }

  // Find the first numeric key and parse animation from it
  let mut first_frame = 0
  let mut animation_json = Json::null()
  for key, value in obj {
    try @strconv.parse_int(key) catch {
      _ => continue
    } noraise {
      frame_num => {
        first_frame = frame_num
        animation_json = value
        break
      }
    }
  }
  if animation_json is Json::Null {
    raise @json.JsonDecodeError((path, "no frame data found"))
  }
  let animation : @resource.NxAnimation = @json.from_json(
    animation_json,
    path=path.add_key(first_frame.to_string()),
  )
  { animation, range, first_frame }
}

///|
/// Cache stores: Name -> Level -> Stance -> Resource
let after_image_cache : Map[String, Map[Int, Map[String, NxAfterImage]]] = Map::new()

///|
struct NxAfterImages {
  level_map : Map[Int, Map[String, NxAfterImage]]
}

///|
pub impl @json.FromJson for NxAfterImages with from_json(json, path) -> NxAfterImages raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let level_map = Map::new()
  for level_key, level_val in obj {
    guard level_val is Object(level_val) else { continue }
    let level = @strconv.parse_int(level_key) catch { _ => continue }
    let stance_map = Map::new()
    for stance_key, stance_val in level_val {
      let stance = stance_key
      let resource : NxAfterImage = @json.from_json(stance_val)
      stance_map.set(stance, resource)
    }
    level_map.set(level, stance_map)
  }
  { level_map, }
}

///|
pub fn set_after_images(name : String, after_images : NxAfterImages) -> Unit {
  after_image_cache.set(name, after_images.level_map)
}

///|
/// Retrieves a map of stances to AfterImage instances for a given weapon name and level.
pub fn AfterImage::get_collection(
  name : String,
  level : Int,
) -> Map[String, AfterImage] {
  let res_map = Map::new()
  guard after_image_cache.get(name) is Some(levels) else { return res_map }

  // The cache keys are "0", "1", etc. which correspond to level / 10
  let level_key = level / 10
  guard levels.get(level_key) is Some(stances) else { return res_map }
  for stance, resource in stances {
    res_map.set(stance, AfterImage::new(resource))
  }
  res_map
}

///|
pub fn AfterImage::new(resource : NxAfterImage) -> AfterImage {
  let range = resource.range
  if range.is_empty() {
    @log.error({}, "afterimage range is empty")
    panic()
  }
  let animation = resource.animation
  let first_frame = resource.first_frame
  let displayed = false

  // Create selene Sprite
  let selene_anim = nx_animation_to_selene_animation(animation)
  { animation: selene_anim, range, first_frame, displayed, entity: None }
}

///|
pub fn AfterImage::attach(self : AfterImage, parent : @entity.Entity) -> Unit {
  if self.entity is None {
    self.entity = Some(parent.spawn_child())
  }
}

///|
pub fn AfterImage::dispose(self : AfterImage) -> Unit {
  if self.entity is Some(e) {
    e.destroy()
    self.entity = None
  }
}

///|
pub fn AfterImage::get_first_frame(self : AfterImage) -> Int {
  self.first_frame
}

///|
pub fn AfterImage::get_range(self : AfterImage) -> @struct.Rectangle[Int] {
  self.range
}

///|
pub fn AfterImage::update(
  self : AfterImage,
  stframe : Int,
  _timestep : Int,
) -> Unit {
  if not(self.displayed) && stframe >= self.first_frame {
    self.displayed = true
    if self.entity is Some(e) {
      // Attach sprite and play
      // Use CHAR_LOOK_ZINDEX to align with character rendering layer
      let sprite = @sprite.Sprite::from_animation(
        self.animation,
        @graphics.CHAR_LOOK_ZINDEX,
      )
      @sprite.sprites.set(e, sprite)
      @sprite.play_animation(e, self.animation, loop_=false)
    }
  }
}
