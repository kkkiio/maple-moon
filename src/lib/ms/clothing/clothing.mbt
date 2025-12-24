///|
pub(all) enum Layer {
  CAPE = 1
  SHIELD_BELOW_BODY = 2
  WEAPON_BELOW_BODY = 3
  CAP_BELOW_BODY = 4
  WRIST_OVER_BODY = 6
  GLOVE_OVER_BODY = 7
  SHOES = 8
  MAIL = 10
  PANTS_DEFAULT = 11
  PANTS = 12
  TOP_DEFAULT = 13
  TOP = 14
  SHIELD_OVER_HAIR = 17
  EARRINGS = 18
  FACE_ACC = 22
  EYE_ACC = 23
  SHIELD = 24
  CAP = 26
  CAP_OVER_HAIR = 29
  WEAPON_BELOW_ARM = 33
  MAILARM = 34
  WEAPON = 36
  WRIST = 40
  GLOVE = 41
  WEAPON_OVER_GLOVE = 42
  WEAPON_OVER_HAND = 46
  WEAPON_OVER_BODY = 47
  HAND_OVER_WEAPON = 49
  WRIST_OVER_HAIR = 50
  GLOVE_OVER_HAIR = 51
  // Unused layers (no z-value in play_animations)
  PENDANT
  BELT
  MEDAL
  RING
  BACK_SHIELD
  BACK_WEAPON
} derive(Eq, Hash, Show)

///|
pub fn Layer::int_value(self : Layer) -> Int = "%identity"

///|
pub impl ToJson for Layer with to_json(self) {
  self.to_string().to_json()
}

///|
struct Clothing {
  stances : Map[
    @types.StanceId,
    Map[String, (Array[@resource.NxFrame], Array[Layer])],
  ]
  item_id : Int
  eq_slot : @slot.Id
  walk : @types.StanceId
  stand : @types.StanceId
  vslot : String
  two_handed : Bool
  // transparent : Bool
} derive(Show)

///|
pub fn Clothing::from_resource(
  item_data : @item.ItemData,
  drawinfo : @types.BodyDrawInfo,
) -> Clothing raise {
  let equipdata = @data.EquipData::parse_item_data(item_data)
  let eq_slot = equipdata.get_eqslot()
  let two_handed = if eq_slot == @slot.Id::WEAPON {
    @weapon.WeaponData::from_item_data(item_data).is_twohanded()
  } else {
    false
  }
  let non_weapon_types = 15
  let weapon_offset = non_weapon_types + 15
  let weapon_types = 20
  let item_id = item_data.item_id
  let index = item_id / 10000 - 100
  let chlayer = if index < non_weapon_types {
    layers[index]
  } else if index >= weapon_offset && index < weapon_offset + weapon_types {
    Layer::WEAPON
  } else {
    Layer::CAPE
  }
  let info = item_data.get_info()
  let vslot = if info is { "vslot": String(vslot), .. } { vslot } else { "" }
  let stand = match info {
    { "stand": Json::Number(1, ..), .. } => @types.StanceId::STAND1
    { "stand": Json::Number(2, ..), .. } => @types.StanceId::STAND2
    _ =>
      if two_handed {
        @types.StanceId::STAND2
      } else {
        @types.StanceId::STAND1
      }
  }
  let walk = match info {
    { "walk": Json::Number(1, ..), .. } => @types.StanceId::WALK1
    { "walk": Json::Number(2, ..), .. } => @types.StanceId::WALK2
    _ =>
      if two_handed {
        @types.StanceId::WALK2
      } else {
        @types.StanceId::WALK1
      }
  }
  let src = item_data.src
  let stances : Map[
    @types.StanceId,
    Map[String, (Array[@resource.NxFrame], Array[Layer])],
  ] = {}
  for stancename, stance in @types.stance_name_id_map {
    guard src is Object(obj) else { continue }
    guard obj.get(stancename) is Some(stancenode) else { continue }
    let part_frames_map : Map[String, (Array[@resource.NxFrame], Array[Layer])] = Map::new()
    for frame = 0; ; frame = frame + 1 {
      guard stancenode is Object(stance_obj) else { break }
      guard stance_obj.get(frame.to_string()) is Some(framenode) else { break }
      guard framenode is Object(frame_obj) else { break }
      for part, partnode in frame_obj {
        // Check if partnode has texture data (__i field)
        guard partnode is Object(part_obj) else { continue }
        guard part_obj.contains("__i") else { continue }
        let mut z = chlayer
        let zs = match part_obj.get("z") {
          Some(String(s)) => s
          _ => ""
        }
        if part == "mailArm" {
          z = Layer::MAILARM
        } else {
          match sub_layer_names.get(zs) {
            Some(sublayer) => z = sublayer
            None => ()
          }
        }
        // Parse map data for parent position
        let (parent, parentpos) = match part_obj.get("map") {
          Some(Object(map_obj)) => {
            let mut result = ("", @struct.Point::default())
            for key, value in map_obj {
              match value {
                Array([Number(x, ..), Number(y, ..)]) => {
                  result = (key, @struct.Point::new(x.to_int(), y.to_int()))
                  break
                }
                _ => ()
              }
            }
            result
          }
          _ => ("", @struct.Point::default())
        }
        let shift = match eq_slot {
          @slot.Id::FACE => -parentpos
          @slot.Id::SHOES
          | @slot.Id::GLOVES
          | @slot.Id::TOP
          | @slot.Id::TOP_DEFAULT
          | @slot.Id::BOTTOM
          | @slot.Id::BOTTOM_DEFAULT
          | @slot.Id::CAPE =>
            drawinfo.get_body_position(stance, frame) - parentpos
          @slot.Id::HAT | @slot.Id::EARACC | @slot.Id::EYE_ACC =>
            drawinfo.get_face_pos(stance, frame) - parentpos
          @slot.Id::SHIELD | @slot.Id::WEAPON =>
            (if parent == "handMove" {
              drawinfo.get_hand_position(stance, frame)
            } else if parent == "hand" {
              drawinfo.get_arm_position(stance, frame)
            } else if parent == "navel" {
              drawinfo.get_body_position(stance, frame)
            } else {
              @struct.Point::default()
            }) -
            parentpos
          _ => @struct.Point::default()
        }
        let tex : @resource.NxTexture = @json.from_json(partnode)
        let tex = { ..tex, origin: tex.origin - shift }
        let nx_frame = @resource.NxFrame::{
          texture: tex,
          delay: None, // Will be set later if available
          head: None,
          bounds: None,
        }
        let (frames, layers) = part_frames_map.get_or_init(part, fn() {
          ([], [])
        })
        // Handle frame discontinuity: fill gaps with previous frame
        while frames.length() < frame {
          if frames.length() > 0 {
            frames.push(frames[frames.length() - 1])
            layers.push(layers[layers.length() - 1])
          } else {
            // First frame is missing, push current as placeholder
            frames.push(nx_frame)
            layers.push(z)
          }
        }
        frames.push(nx_frame)
        layers.push(z)
      }
    }
    stances.set(stance, part_frames_map)
  }
  // let transparent = item_id == 1002186
  { stances, item_id, eq_slot, vslot, two_handed, walk, stand }
}

///|
pub fn Clothing::get_animation(
  self : Clothing,
  stance : @types.StanceId,
  part : String,
) -> (Array[@resource.NxFrame], Array[Layer])? {
  self.stances.get(stance).bind(fn(m) { m.get(part) })
}

///|
pub fn Clothing::get_parts_for_stance(
  self : Clothing,
  stance : @types.StanceId,
) -> Map[String, (Array[@resource.NxFrame], Array[Layer])]? {
  self.stances.get(stance)
}

///|
pub fn Clothing::get_id(self : Clothing) -> Int {
  self.item_id
}

///|
pub fn Clothing::get_vslot(self : Clothing) -> String {
  self.vslot
}

///|
pub fn Clothing::is_twohanded(self : Clothing) -> Bool {
  self.two_handed
}

///|
pub fn Clothing::get_eqslot(self : Clothing) -> @slot.Id {
  self.eq_slot
}

///|
let sub_layer_names : Map[String, Layer] = {
  "weaponOverHand": Layer::WEAPON_OVER_HAND,
  "weaponOverGlove": Layer::WEAPON_OVER_GLOVE,
  "weaponOverBody": Layer::WEAPON_OVER_BODY,
  "weaponBelowArm": Layer::WEAPON_BELOW_ARM,
  "weaponBelowBody": Layer::WEAPON_BELOW_BODY,
  "backWeaponOverShield": Layer::BACK_WEAPON,
  "shieldOverHair": Layer::SHIELD_OVER_HAIR,
  "shieldBelowBody": Layer::SHIELD_BELOW_BODY,
  "backShield": Layer::BACK_SHIELD,
  "gloveWrist": Layer::WRIST,
  "gloveOverHair": Layer::GLOVE_OVER_HAIR,
  "gloveOverBody": Layer::GLOVE_OVER_BODY,
  "gloveWristOverHair": Layer::WRIST_OVER_HAIR,
  "gloveWristOverBody": Layer::WRIST_OVER_BODY,
  "capOverHair": Layer::CAP_OVER_HAIR,
  "capBelowBody": Layer::CAP_BELOW_BODY,
}

///|
pub fn Clothing::get_stand(self : Clothing) -> @types.StanceId {
  self.stand
}

///|
pub fn Clothing::get_walk(self : Clothing) -> @types.StanceId {
  self.walk
}

///|
let layers : Array[Layer] = [
  Layer::CAP,
  Layer::FACE_ACC,
  Layer::EYE_ACC,
  Layer::EARRINGS,
  Layer::TOP,
  Layer::MAIL,
  Layer::PANTS,
  Layer::SHOES,
  Layer::GLOVE,
  Layer::SHIELD,
  Layer::CAPE,
  Layer::RING,
  Layer::PENDANT,
  Layer::BELT,
  Layer::MEDAL,
]
