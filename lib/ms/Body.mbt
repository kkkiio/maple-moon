pub enum BodyLayer {
  NONE
  BODY
  ARM
  ARM_BELOW_HEAD
  ARM_BELOW_HEAD_OVER_MAIL
  ARM_OVER_HAIR
  ARM_OVER_HAIR_BELOW_WEAPON
  HAND_BELOW_WEAPON
  HAND_OVER_HAIR
  HAND_OVER_WEAPON
  HEAD
} derive(Eq, Compare, Debug)

pub fn int_value(self : BodyLayer) -> Int {
  match self {
    BodyLayer::NONE => 0
    BodyLayer::BODY => 1
    BodyLayer::ARM => 2
    BodyLayer::ARM_BELOW_HEAD => 3
    BodyLayer::ARM_BELOW_HEAD_OVER_MAIL => 4
    BodyLayer::ARM_OVER_HAIR => 5
    BodyLayer::ARM_OVER_HAIR_BELOW_WEAPON => 6
    BodyLayer::HAND_BELOW_WEAPON => 7
    BodyLayer::HAND_OVER_HAIR => 8
    BodyLayer::HAND_OVER_WEAPON => 9
    BodyLayer::HEAD => 10
  }
}

pub fn hash(self : BodyLayer) -> Int {
  self.int_value()
}

pub let body_layer_int_map : @immut/sorted_map.Map[BodyLayer, Int] = @immut/sorted_map.from_array(
  [
    (BodyLayer::NONE, 0),
    (BodyLayer::BODY, 1),
    (BodyLayer::ARM, 2),
    (BodyLayer::ARM_BELOW_HEAD, 3),
    (BodyLayer::ARM_BELOW_HEAD_OVER_MAIL, 4),
    (BodyLayer::ARM_OVER_HAIR, 5),
    (BodyLayer::ARM_OVER_HAIR_BELOW_WEAPON, 6),
    (BodyLayer::HAND_BELOW_WEAPON, 7),
    (BodyLayer::HAND_OVER_HAIR, 8),
    (BodyLayer::HAND_OVER_WEAPON, 9),
    (BodyLayer::HEAD, 10),
  ],
)

pub struct Body {
  stances : @immut/sorted_map.Map[
    @Stance.Id,
    @immut/sorted_map.Map[BodyLayer, Map[Int, Texture]],
  ]
  name : String
}

pub fn Body::new(skin : Int, drawinfo : BodyDrawInfo) -> Body {
  let strid : String = @string_format.extend_id(skin, 2)
  let character_loader = character_loader()
  let bodynode : NxNode = character_loader.load_res("000020" + strid + ".img")
  let headnode : NxNode = character_loader.load_res("000120" + strid + ".img")
  let stances = @Stance.names.as_iter().map(
      fn(it) {
        let (stance_name, stance) = it
        let body_texture_map = body_layer_int_map.map(
          fn(_v) -> Map[Int, Texture] { Map::new() },
        )
        let stancenode = bodynode[stance_name]
        if stancenode.is_null().not() {
          let mut frame : Int = 0
          while true {
            let framenode : NxNode = stancenode[frame.to_string()]
            if framenode.is_null() {
              break
            }
            framenode.get_object().iter(
              fn(name, partnode) {
                let part : String = name
                if part != "delay" && part != "face" {
                  let z : String = partnode["z"].get_string()
                  let layer : BodyLayer = Body::layer_by_name(z)
                  if layer != BodyLayer::NONE {
                    let shift = match layer {
                      BodyLayer::HAND_BELOW_WEAPON =>
                        drawinfo.get_hand_position(stance, frame) - (partnode["map"]["handMove"]
                        |> Point::from_resource)
                      _ => {
                        let mut shift = drawinfo.get_body_position(
                          stance, frame,
                        )
                        if stance == @Stance.Id::DEAD {
                          shift -= Point::new(5, 4)
                        }
                        shift -= partnode["map"]["navel"]
                          |> Point::from_resource
                        shift
                      }
                    }
                    let texture = Texture::from_resource(partnode)
                    texture.shift(shift)
                    body_texture_map[layer].unwrap().set(frame, texture)
                  }
                }
              },
            )
            let headsfnode : NxNode = headnode[stance_name][frame.to_string()]["head"]
            if headsfnode.is_null().not() {
              let shift : Point[Int] = drawinfo.get_head_position(stance, frame)
              let texture = Texture::from_resource(headsfnode)
              texture.shift(shift)
              body_texture_map[BodyLayer::HEAD].unwrap().set(frame, texture)
            }
            frame += 1
          }
        }
        (stance, body_texture_map)
      },
    ).collect()
    |> @immut/sorted_map.from_array
  let skintypes = [
    "Light", "Tan", "Dark", "Pale", "Blue", "Green", "", "", "", "Grey", "Pink",
    "Red",
  ]
  let index = skin
  let name = if index < skintypes.length() { skintypes[index] } else { "" }
  { stances, name }
}

pub fn Body::draw(
  self : Body,
  stance : @Stance.Id,
  layer : BodyLayer,
  frame : Int,
  args : DrawArgument
) -> Unit {
  let frameit = self.stances[stance].unwrap()[layer].unwrap()[frame]
  match frameit {
    Some(v) => v.draw(args)
    None => ()
  }
}

pub fn Body::get_name(self : Body) -> String {
  self.name
}

pub fn Body::layer_by_name(name : String) -> BodyLayer {
  let layer_iter = layers_by_name_[name]
  match layer_iter {
    None => {
      if name != "" {
        print("Unknown BodyLayer name: [" + name + "]")
      }
      BodyLayer::NONE
    }
    Some(v) => v
  }
}

pub let layers_by_name_ : @immut/sorted_map.Map[String, BodyLayer] = @immut/sorted_map.from_array(
  [
    ("body", BodyLayer::BODY),
    ("backBody", BodyLayer::BODY),
    ("arm", BodyLayer::ARM),
    ("armBelowHead", BodyLayer::ARM_BELOW_HEAD),
    ("armBelowHeadOverMailChest", BodyLayer::ARM_BELOW_HEAD_OVER_MAIL),
    ("armOverHair", BodyLayer::ARM_OVER_HAIR),
    ("armOverHairBelowWeapon", BodyLayer::ARM_OVER_HAIR_BELOW_WEAPON),
    ("handBelowWeapon", BodyLayer::HAND_BELOW_WEAPON),
    ("handOverHair", BodyLayer::HAND_OVER_HAIR),
    ("handOverWeapon", BodyLayer::HAND_OVER_WEAPON),
    ("head", BodyLayer::HEAD),
  ],
)
