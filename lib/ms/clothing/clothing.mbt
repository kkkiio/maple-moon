pub enum Layer {
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

struct Clothing {
  stances : Map[
    @char_look.StanceId,
    Map[Layer, Map[Int, Array[@graphics.Texture]]],
  ]
  item_id : Int
  eq_slot : @slot.Id
  walk : @char_look.StanceId
  stand : @char_look.StanceId
  vslot : String
  two_handed : Bool
  transparent : Bool
}

pub fn Clothing::new(
  item_id : Int,
  drawinfo : @char_look.BodyDrawInfo
) -> Clothing! {
  let equipdata = @equip.EquipData::get!(item_id)
  let mut eq_slot = equipdata.get_eqslot()
  if item_id == top_default_id {
    eq_slot = @slot.Id::TOP_DEFAULT
  } else if item_id == bottom_default_id {
    eq_slot = @slot.Id::BOTTOM_DEFAULT
  }
  let two_handed = if eq_slot == @slot.Id::WEAPON {
    @weapon.WeaponData::get!(item_id).is_twohanded()
  } else {
    false
  }
  let non_weapon_types = 15
  let weapon_offset = non_weapon_types + 15
  let weapon_types = 20
  let layers = [
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
  let index = item_id / 10000 - 100
  let chlayer = if item_id == top_default_id {
    Layer::TOP_DEFAULT
  } else if item_id == bottom_default_id {
    Layer::PANTS_DEFAULT
  } else if index < non_weapon_types {
    layers[index]
  } else if index >= weapon_offset && index < weapon_offset + weapon_types {
    Layer::WEAPON
  } else {
    Layer::CAPE
  }
  let strid = "0" + item_id.to_string()
  let category = equipdata.get_itemdata().get_category()
  let src = @resource.character_loader().load_res([category, strid + ".img"])
  let info = src["info"]
  let vslot = info["vslot"].get_string()
  let standno = info["stand"].get_int!()
  let stand = match standno {
    1 => @char_look.StanceId::STAND1
    2 => @char_look.StanceId::STAND2
    _ =>
      if two_handed {
        @char_look.StanceId::STAND2
      } else {
        @char_look.StanceId::STAND1
      }
  }
  let walkno = info["walk"].get_int!()
  let walk = match walkno {
    1 => @char_look.StanceId::WALK1
    2 => @char_look.StanceId::WALK2
    _ =>
      if two_handed {
        @char_look.StanceId::WALK2
      } else {
        @char_look.StanceId::WALK1
      }
  }
  let stances = @char_look.stance_id_names
    .iter()
    .map(
      fn(it) {
        let (stancename, stance) = it
        (stance, src[stancename])
      },
    )
    .filter(fn(it) { it.1.is_null().not() })
    .map(
      fn(it) {
        let (stance, stancenode) = it
        let layeredFrames = Map::new()
        for frame = 0; ; frame = frame + 1 {
          let framenode = stancenode[frame.to_string()]
          if framenode.is_null() {
            break
          }
          for partnode in framenode {
            let part = partnode.name()
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
            let mapnode = partnode["map"]
            let shift = match eq_slot {
              @slot.Id::FACE => -parentpos
              @slot.Id::SHOES
              | @slot.Id::GLOVES
              | @slot.Id::TOP
              | @slot.Id::TOP_DEFAULT
              | @slot.Id::BOTTOM | @slot.Id::BOTTOM_DEFAULT | @slot.Id::CAPE =>
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

  // static const std::unordered_set<int32_t> transparents = { 1002186 };

  let transparent = item_id == 1002186
  { stances, item_id, eq_slot, vslot, two_handed, transparent, walk, stand }
}

pub fn Clothing::draw(
  self : Clothing,
  stance : @char_look.StanceId,
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

pub fn get_id(self : Clothing) -> Int {
  self.item_id
}

pub fn get_vslot(self : Clothing) -> String {
  self.vslot
}

pub fn is_twohanded(self : Clothing) -> Bool {
  self.two_handed
}

pub fn get_eqslot(self : Clothing) -> @slot.Id {
  self.eq_slot
}

/// Defaults when no clothes are equipped
pub let top_default_id : Int = 1042399

pub let bottom_default_id : Int = 1060026

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
