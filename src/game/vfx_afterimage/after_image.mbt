///|
using @res {type AnimationLoader}

///|
using @struct {type Rectangle}

///|
/// 残影. 角色移动或攻击时，在身后留下的半透明或特效化的影子效果，用来表现速度感或技能的威力。
pub struct AfterImage {
  animation : @ms_animation.Animation
  range : @struct.Rectangle[Int]
  first_frame : Int
  facing_right : Bool
  mut displayed : Bool
  mut entity : @entity.Entity?
}

///|
pub(all) struct NxAfterImage {
  animation : @ms_animation.Animation
  range : @struct.Rectangle[Int]
  first_frame : Int
}

///|

///|
pub impl @json.FromJson for NxAfterImage with fn from_json(json, path) -> NxAfterImage raise @json.JsonDecodeError {
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
    Rectangle(left_top, right_bottom)
  }

  // Find the first numeric key and parse animation from it
  let mut first_frame = 0
  let mut animation_json = Json::null()
  for key, value in obj {
    try @string.parse_int(key) catch {
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
  let animation : @res.NxAnimation = @json.from_json(
    animation_json,
    path=path.add_key(first_frame.to_string()),
  )
  { animation: @ms_animation.from_nx_animation(animation), range, first_frame }
}

///|
/// Cache stores: Name -> Level -> Stance -> Resource
let nx_after_image_resources : Map[String, Map[Int, Map[String, NxAfterImage]]] = Map([],
)

///|
struct NxAfterImages {
  level_map : Map[Int, Map[String, NxAfterImage]]
}

///|
pub impl @json.FromJson for NxAfterImages with fn from_json(json, path) -> NxAfterImages raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let level_map = Map([])
  for level_key, level_val in obj {
    guard level_val is Object(level_val) else { continue }
    let level = @string.parse_int(level_key) catch { _ => continue }
    let stance_map = Map([])
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
  nx_after_image_resources.set(name, after_images.level_map)
}

///|
/// Load one exported afterimage bundle by weapon/skill afterimage name.
///
/// The exported bundle is `res://Character/Afterimage/<name>.img/mx.json`.
/// `first_frame` is the paper-doll stance frame that starts playback; the
/// referenced Aseprite tag always plays from its own first frame.
///
/// # Example
/// ```moonbit nocheck
/// let afterimages = try! load_after_images("bow")
/// ignore(afterimages)
/// ```
///
/// # Errors
/// Raises when the bundle structure, a relative animation reference, or a
/// referenced animation tag is invalid.
pub fn load_after_images(name : String) -> NxAfterImages raise {
  let mx_path = "res://Character/Afterimage/\{name}.img/mx.json"
  let src = @res.load_json(mx_path)
  guard src
    is {
      "animations_path": String(animations_path),
      "levels": Object(levels_obj),
      ..
    } else {
    fail("invalid afterimage mx resource: \{mx_path}")
  }
  let loaded = AnimationLoader().load(
    @res.resolve_ref(mx_path, animations_path),
  )
  let level_map : Map[Int, Map[String, NxAfterImage]] = Map([])
  for level_key, level_val in levels_obj {
    guard level_val is Object(stance_obj) else {
      fail("invalid afterimage level entry: \{mx_path}/levels/\{level_key}")
    }
    let level = @string.parse_int(level_key) catch {
      _ => fail("invalid afterimage level key: \{mx_path}/levels/\{level_key}")
    }
    let stance_map : Map[String, NxAfterImage] = Map([])
    for stance_key, stance_val in stance_obj {
      guard stance_val is Object(entry_obj) else {
        fail(
          "invalid afterimage stance entry: \{mx_path}/levels/\{level_key}/\{stance_key}",
        )
      }
      let tag = match entry_obj.get("tag") {
        Some(String(tag)) => tag
        _ =>
          fail(
            "missing afterimage tag: \{mx_path}/levels/\{level_key}/\{stance_key}",
          )
      }
      let first_frame = match entry_obj.get("first_frame") {
        Some(Number(first_frame, ..)) => first_frame.to_int()
        _ =>
          fail(
            "missing afterimage first_frame: \{mx_path}/levels/\{level_key}/\{stance_key}",
          )
      }
      let range = match entry_obj.get("range") {
        Some(range_json) =>
          @json.from_json(range_json) catch {
            _ =>
              fail(
                "invalid afterimage range: \{mx_path}/levels/\{level_key}/\{stance_key}",
              )
          }
        None => @struct.Rectangle::from4(0, 0, 0, 0)
      }
      let clip = loaded.clip(tag) catch {
        error =>
          fail(
            "missing afterimage animation tag '\{tag}' in \{mx_path}: \{error}",
          )
      }
      stance_map[stance_key] = {
        animation: @ms_animation.from_selene_clip(clip, loop_=false),
        range,
        first_frame,
      }
    }
    level_map[level] = stance_map
  }
  { level_map, }
}

///|
/// Retrieves a map of stances to AfterImage instances for a given weapon name and level.
pub fn AfterImage::get_collection(
  name : String,
  level : Int,
) -> Map[String, NxAfterImage] {
  let res_map = Map([])
  guard nx_after_image_resources.get(name) is Some(levels) else {
    return res_map
  }

  // The cache keys are "0", "1", etc. which correspond to level / 10
  let level_key = level / 10
  guard levels.get(level_key) is Some(stances) else { return res_map }
  for stance, resource in stances {
    res_map.set(stance, resource)
  }
  res_map
}

///|
fn AfterImage::AfterImage(
  resource : NxAfterImage,
  facing_right : Bool,
) -> AfterImage {
  let range = resource.range
  let animation = resource.animation
  let first_frame = resource.first_frame
  let displayed = false
  { animation, range, first_frame, facing_right, displayed, entity: None }
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
    @sprite.sprites().remove(e)
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
  if !self.displayed && stframe >= self.first_frame {
    self.displayed = true
    if self.entity is Some(e) {
      let transform = if self.facing_right {
        @selene_math.Transform::from_scale(-1.0, 1.0)
      } else {
        @selene_math.Transform()
      }
      // Attach sprite and play
      // Use CHAR_LOOK_ZINDEX to align with character rendering layer
      let sprite = @ms_animation.sprite_from_animation(
        self.animation,
        @graphics.CHAR_LOOK_ZINDEX,
        transform~,
      )
      @sprite.sprites().set(e, sprite)
      @ms_animation.play_animation(e, self.animation, loop_=false, transform~)
    }
  }
}

// ============================================================================
// AfterImage System - ECS-style management
// ============================================================================

///|
priv struct AfterImageEntry {
  after_image : AfterImage
  look : @cp.CharLook
}

///|
/// Per-world active after-images keyed by host entity.
let after_images_by_world : Map[UInt, Map[@entity.Entity, AfterImageEntry]] = Map([],
)

///|
fn after_images() -> Map[@entity.Entity, AfterImageEntry] {
  let world_id = @ecs.require_current_world().id()
  after_images_by_world.get_or_init(world_id, fn() { Map([]) })
}

///|
/// Add an AfterImage to an entity, disposing any existing one.
/// 
/// Parameters:
/// - `entity`: The character's root entity (used for keying and as parent for AfterImage sprite)
/// - `look`: The character look used as frame source
/// - `after_image`: The AfterImage to add
pub fn add_after_image(
  entity : @entity.Entity,
  look : @cp.CharLook,
  resource : NxAfterImage,
  facing_right : Bool,
) -> Unit {
  let after_images = after_images()
  // Dispose old if exists
  if after_images.get(entity) is Some(old) {
    old.after_image.dispose()
  }
  let after_image = AfterImage(resource, facing_right)
  after_image.attach(entity)
  after_images.set(entity, { after_image, look })
}

///|
/// Get the current AfterImage for an entity.
pub fn get_after_image(entity : @entity.Entity) -> AfterImage? {
  let after_images = after_images()
  after_images.get(entity).map(fn(entry) { entry.after_image })
}

///|
/// Clear/remove the AfterImage for an entity.
pub fn clear_after_image(entity : @entity.Entity) -> Unit {
  let after_images = after_images()
  if after_images.get(entity) is Some(old) {
    old.after_image.dispose()
  }
  after_images.remove(entity)
}

///|
/// Update all AfterImages based on character look frame.
/// Should be called from the main game loop.
pub fn update_after_image_system(_world : @ecs.World) -> Unit {
  let delta = @time.delta()
  let after_images = after_images()
  let to_remove : Array[@entity.Entity] = []
  for entity, entry in after_images {
    if !entity.is_alive() {
      entry.after_image.dispose()
      to_remove.push(entity)
      continue
    }
    let frame = entry.look.get_frame()
    entry.after_image.update(frame, (delta * 1000.0).to_int())
  }
  // Clean up dead entities
  for entity in to_remove {
    after_images.remove(entity)
  }
}
