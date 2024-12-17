///|
pub(all) enum Layer {
  CAPE
  SHOES
  PANTS
  TOP
  MAIL
  MAILARM
  EARRINGS
  FACE_ACC
  EYE_ACC
  PENDANT
  BELT
  MEDAL
  RING
  CAP
  CAP_BELOW_BODY
  CAP_OVER_HAIR
  GLOVE
  WRIST
  GLOVE_OVER_HAIR
  WRIST_OVER_HAIR
  GLOVE_OVER_BODY
  WRIST_OVER_BODY
  SHIELD
  BACK_SHIELD
  SHIELD_BELOW_BODY
  SHIELD_OVER_HAIR
  WEAPON
  BACK_WEAPON
  WEAPON_BELOW_ARM
  WEAPON_BELOW_BODY
  WEAPON_OVER_HAND
  WEAPON_OVER_BODY
  WEAPON_OVER_GLOVE
  PANTS_DEFAULT
  TOP_DEFAULT
} derive(Eq, Hash)

///|
struct Clothing {
  stances : Map[@types.StanceId, Map[Layer, Map[Int, Array[@graphics.Texture]]]]
  item_id : Int
  eq_slot : @slot.Id
  walk : @types.StanceId
  stand : @types.StanceId
  vslot : String
  two_handed : Bool
  // transparent : Bool
}

///|
pub fn Clothing::from_resource(
  item_data : @item.ItemData,
  drawinfo : @types.BodyDrawInfo
) -> Clothing! {
  let equipdata = @data.EquipData::from_item_data!(item_data)
  let eq_slot = equipdata.get_eqslot()
  let two_handed = if eq_slot == @slot.Id::WEAPON {
    @weapon.WeaponData::from_item_data!(item_data).is_twohanded()
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
  let vslot = info["vslot"].bind(fn(it) { it.as_string() }).or("")
  let stand = match info {
    { "stand": Json::Number(1) } => @types.StanceId::STAND1
    { "stand": Json::Number(2) } => @types.StanceId::STAND2
    _ =>
      if two_handed {
        @types.StanceId::STAND2
      } else {
        @types.StanceId::STAND1
      }
  }
  let walk = match info {
    { "walk": Json::Number(1) } => @types.StanceId::WALK1
    { "walk": Json::Number(2) } => @types.StanceId::WALK2
    _ =>
      if two_handed {
        @types.StanceId::WALK2
      } else {
        @types.StanceId::WALK1
      }
  }
  let src = item_data.get_src()
  let stances = @types.stance_name_id_map
    .iter()
    .map_option(
      fn(it) {
        let (stancename, stance) = it
        let node = src[stancename]
        if node.is_null() {
          None
        } else {
          Some((stance, node))
        }
      },
    )
    .map(
      fn(it) {
        let (stance, stancenode) = it
        let layeredFrames = Map::new()
        for frame = 0; ; frame = frame + 1 {
          let framenode = stancenode[frame.to_string()]
          if framenode.is_null() {
            break
          }
          for part, partnode in framenode {
            if partnode.is_null() || partnode.get_bitmap().is_empty() {
              continue
            }
            let mut z = chlayer
            let zs = partnode["z"].get_string()
            if part == "mailArm" {
              z = Layer::MAILARM
            } else {
              match sub_layer_names.get(zs) {
                Some(sublayer) => z = sublayer
                None => ()
              }
            }
            let (parent, parentpos) = for mapnode in partnode["map"] {
              match mapnode.as_point?().to_option() {
                Some(point) => break (mapnode.name(), point)
                None => ()
              }
            } else {
              ("", @struct.Point::default())
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
            let tex = @graphics.Texture::from_resource(partnode)..shift(shift)
            layeredFrames
            .get_or_init(z, fn() { Map::new() })
            .get_or_init(frame, fn() { Array::new() })
            .push(tex)
          }
        }
        (stance, layeredFrames)
      },
    )
    |> Map::from_iter
  // let transparent = item_id == 1002186
  { stances, item_id, eq_slot, vslot, two_handed, walk, stand }
}

///|
pub fn Clothing::draw(
  self : Clothing,
  stance : @types.StanceId,
  layer : Layer,
  frame : Int,
  args : @graphics.DrawArgument
) -> Unit {
  match
    self.stances
    .get(stance)
    .bind(fn(m) { m.get(layer) })
    .bind(fn(m) { m.get(frame) }) {
    Some(textures) =>
      for texture in textures {
        texture.draw(args)
      }
    None => ()
  }
}

///|
pub fn get_id(self : Clothing) -> Int {
  self.item_id
}

///|
pub fn get_vslot(self : Clothing) -> String {
  self.vslot
}

///|
pub fn is_twohanded(self : Clothing) -> Bool {
  self.two_handed
}

///|
pub fn get_eqslot(self : Clothing) -> @slot.Id {
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
pub fn get_stand(self : Clothing) -> @types.StanceId {
  self.stand
}

///|
pub fn get_walk(self : Clothing) -> @types.StanceId {
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
