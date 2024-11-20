pub(all) enum BodyLayer {
  BODY_NONE
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
} derive(Eq, Compare)

pub fn int_value(self : BodyLayer) -> Int {
  match self {
    BodyLayer::BODY_NONE => 0
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

pub fn hash_combine(self : BodyLayer, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

pub let body_layer_int_map : @immut/sorted_map.T[BodyLayer, Int] = @immut/sorted_map.from_array(
  [
    (BodyLayer::BODY_NONE, 0),
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

pub(all) struct Body {
  stances : @immut/sorted_map.T[
    StanceId,
    @immut/sorted_map.T[BodyLayer, Map[Int, @graphics.Texture]],
  ]
  name : String
}

fn Body::load(skin : Int, drawinfo : BodyDrawInfo) -> @utils.Future[Body] {
  let strid : String = @string_format.extend_id(skin, 2)
  let bodynode = body_loader.load_res(["000020" + strid + ".img"])
  let headnode = body_loader.load_res(["000120" + strid + ".img"])
  bodynode
  .combine(headnode)
  .map(fn(it) { Body::new(skin, drawinfo, it.0, it.1) })
}

fn Body::new(
  skin : Int,
  drawinfo : BodyDrawInfo,
  bodynode : @resource.NxNode,
  headnode : @resource.NxNode
) -> Body {
  let stances = stance_id_names
    .iter()
    .map(
      fn(it) {
        let (stance_name, stance) = it
        let body_texture_map = body_layer_int_map.map(
          fn(_v) -> Map[Int, @graphics.Texture] { Map::new() },
        )
        let stancenode = bodynode[stance_name]
        if stancenode.is_null().not() {
          let mut frame : Int = 0
          while true {
            let framenode = stancenode[frame.to_string()]
            if framenode.is_null() {
              break
            }
            for part, partnode in framenode {
              if part != "delay" && part != "face" {
                let z : String = partnode["z"].get_string()
                let layer : BodyLayer = Body::layer_by_name(z)
                if layer != BodyLayer::BODY_NONE {
                  let shift = match layer {
                    BodyLayer::HAND_BELOW_WEAPON =>
                      drawinfo.get_hand_position(stance, frame) -
                      partnode["map"]["handMove"].as_point?().unwrap()
                    _ => {
                      let mut shift = drawinfo.get_body_position(stance, frame)
                      if stance == StanceId::DEAD {
                        shift -= Point::new(5, 4)
                      }
                      shift -= partnode["map"]["navel"].as_point?().unwrap()
                      shift
                    }
                  }
                  let texture = @graphics.Texture::from_resource(partnode)
                  texture.shift(shift)
                  body_texture_map[layer].unwrap().set(frame, texture)
                }
              }
            }
            let headsfnode = headnode[stance_name][frame.to_string()]["head"]
            if headsfnode.is_null().not() {
              let shift : Point[Int] = drawinfo.get_head_position(stance, frame)
              let texture = @graphics.Texture::from_resource(headsfnode)
              texture.shift(shift)
              body_texture_map[BodyLayer::HEAD].unwrap().set(frame, texture)
            }
            frame += 1
          }
        }
        (stance, body_texture_map)
      },
    )
    .collect()
    |> @immut/sorted_map.from_array
  let index = skin
  let name = if index < skintypes.length() { skintypes[index] } else { "" }
  { stances, name }
}

let skintypes = [
  "Light", "Tan", "Dark", "Pale", "Blue", "Green", "", "", "", "Grey", "Pink", "Red",
]

pub fn Body::draw(
  self : Body,
  stance : StanceId,
  layer : BodyLayer,
  frame : Int,
  args : @graphics.DrawArgument
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
        println("Unknown BodyLayer name: [" + name + "]")
      }
      BodyLayer::BODY_NONE
    }
    Some(v) => v
  }
}

pub let layers_by_name_ : @immut/sorted_map.T[String, BodyLayer] = @immut/sorted_map.from_array(
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

let body_loader : @resource.AsyncLoader = @resource.AsyncLoader::new("body")
