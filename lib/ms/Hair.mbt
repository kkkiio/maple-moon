pub enum HairLayer {
  NONE
  DEFAULT
  BELOW_BODY
  OVER_HEAD
  SHADE
  BACK
  BELOW_CAP
} derive(Debug, Eq, Compare)

pub fn int_value(self : HairLayer) -> Int {
  match self {
    HairLayer::NONE => 0
    HairLayer::DEFAULT => 1
    HairLayer::BELOW_BODY => 2
    HairLayer::OVER_HEAD => 3
    HairLayer::SHADE => 4
    HairLayer::BACK => 5
    HairLayer::BELOW_CAP => 6
  }
}

pub fn hash(self : HairLayer) -> Int {
  self.int_value()
}

struct Hair {
  stances : Map[StanceId, Map[HairLayer, Map[Int, Texture]]]
  name : String
  color : String
}

pub let layers_by_name : @immut/sorted_map.Map[String, HairLayer] = @immut/sorted_map.from_array(
  [
    ("hair", HairLayer::DEFAULT),
    ("hairBelowBody", HairLayer::BELOW_BODY),
    ("hairOverHead", HairLayer::OVER_HEAD),
    ("hairShade", HairLayer::SHADE),
    ("backHair", HairLayer::BACK),
    ("backHairBelowCap", HairLayer::BELOW_CAP),
  ],
)

pub fn Hair::new(hairid : Int, drawinfo : BodyDrawInfo) -> Hair {
  let character_loader = character_loader()
  let stances : Map[StanceId, Map[HairLayer, Map[Int, Texture]]] = Map::new()
  let hairnode = character_loader.load_res("Hair/000\(hairid).img")
  stance_id_names.iter(
    fn(stancename, stance) {
      let stancenode = hairnode[stancename]
      if stancenode.is_null() {
        return
      }
      let mut frame = 0
      while true {
        let framenode = stancenode[frame.to_string()]
        if framenode.is_null() {
          break
        }
        framenode.get_object().iter(
          fn(layername, layernode) {
            let layer = match layers_by_name[layername] {
              Some(v) => v
              None => {
                println("Unknown Hair::Layer name: [" + layername + "]")
                return
              }
            }
            let brow = Point::from_resource(layernode["map"]["brow"])
            let shift = drawinfo.get_hair_pos(stance, frame) - brow
            let tex = Texture::from_resource(layernode)
            (stances |> set_defaultm(stance) |> set_defaultm(layer)).set(
              frame, tex,
            )
            tex.shift(shift)
          },
        )
        frame += 1
      }
    },
  )
  let string_loader = string_loader()
  let name = string_loader.load_res("Eqp.img/Eqp/Hair/\(hairid)/name").get_string()
  let haircolors = [
    "Black", "Red", "Orange", "Blonde", "Green", "Blue", "Violet", "Brown",
  ]
  let index = hairid % 10
  let color = if index < haircolors.length() { haircolors[index] } else { "" }
  { stances, name, color }
}

pub fn draw(
  self : Hair,
  stance : StanceId,
  layer : HairLayer,
  frame : Int,
  args : DrawArgument
) -> Unit {
  let frameit = self.stances[stance].bind(fn(it) { it[layer] }).bind(
    fn(it) { it.get(frame) },
  )
  match frameit {
    None => ()
    Some(frameit) => frameit.draw(args)
  }
}

pub fn get_name(self : Hair) -> String {
  self.name
}

pub fn getcolor(self : Hair) -> String {
  self.color
}
