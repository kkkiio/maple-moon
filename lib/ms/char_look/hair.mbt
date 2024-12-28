///|
pub(all) enum HairLayer {
  HAIR_LAYER_NONE
  HAIR_LAYER_DEFAULT
  BELOW_BODY
  OVER_HEAD
  SHADE
  BACK
  BELOW_CAP
} derive(Eq, Compare, Show)

///|
pub impl ToJson for HairLayer with to_json(self) { self.to_string().to_json() }

///|
pub fn int_value(self : HairLayer) -> Int {
  match self {
    HairLayer::HAIR_LAYER_NONE => 0
    HairLayer::HAIR_LAYER_DEFAULT => 1
    HairLayer::BELOW_BODY => 2
    HairLayer::OVER_HEAD => 3
    HairLayer::SHADE => 4
    HairLayer::BACK => 5
    HairLayer::BELOW_CAP => 6
  }
}

///|
pub fn hash(self : HairLayer) -> Int {
  self.int_value()
}

///|
pub fn hash_combine(self : HairLayer, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

///|
struct Hair {
  stances : Map[@types.StanceId, Map[HairLayer, Map[Int, @graphics.Texture]]]
  name : String
  color : String
}

///| For testing
pub fn Hair::default() -> Hair {
  { stances: Map::new(), name: "", color: "" }
}

///|
pub impl ToJson for Hair with to_json(self) -> Json {
  { "name": self.name.to_json(), "color": self.color.to_json() }
}

///|
pub let layers_by_name : @immut/sorted_map.T[String, HairLayer] = @immut/sorted_map.from_array([
    ("hair", HairLayer::HAIR_LAYER_DEFAULT),
    ("hairBelowBody", HairLayer::BELOW_BODY),
    ("hairOverHead", HairLayer::OVER_HEAD),
    ("hairShade", HairLayer::SHADE),
    ("backHair", HairLayer::BACK),
    ("backHairBelowCap", HairLayer::BELOW_CAP),
  ],
)

///|
fn get_hair_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("hair")
}

///|
pub fn Hair::load(
  hairid : Int,
  drawinfo : @types.BodyDrawInfo
) -> @utils.Future[Hair] {
  get_hair_loader()
  .load_res(["000\{hairid}.img"])
  .map(fn(hairnode) { Hair::new(hairid, hairnode, drawinfo) })
}

///|
fn Hair::new(
  hairid : Int,
  hairnode : @resource.NxNode,
  drawinfo : @types.BodyDrawInfo
) -> Hair {
  let stances : Map[
    @types.StanceId,
    Map[HairLayer, Map[Int, @graphics.Texture]],
  ] = Map::new()
  for stancename, stance in @types.stance_name_id_map {
    let stancenode = hairnode[stancename]
    if stancenode.is_null() {
      continue
    }
    let mut frame = 0
    while true {
      let framenode = stancenode[frame.to_string()]
      if framenode.is_null() {
        break
      }
      for layernode in framenode {
        let layername = layernode.name()
        let layer = match layers_by_name[layername] {
          Some(v) => v
          None => {
            @log.warn({ "layer_name": layername }, "Unknown Hair::Layer name")
            continue
          }
        }
        let brow = layernode["map"]["brow"].as_point?().unwrap()
        let shift = drawinfo.get_hair_pos(stance, frame) - brow
        let tex = @graphics.Texture::from_resource(layernode)
        stances
        .get_or_init(stance, fn() { Map::new() })
        .get_or_init(layer, fn() { Map::new() })
        .set(frame, tex)
        tex.shift(shift)
      }
      frame += 1
    }
  }
  let string_loader = @resource.string_loader()
  let name = string_loader
    .load_res(["Eqp.img", "Eqp", "Hair", "\{hairid}", "name"])
    .get_string()
  let haircolors = [
    "Black", "Red", "Orange", "Blonde", "Green", "Blue", "Violet", "Brown",
  ]
  let index = hairid % 10
  let color = if index < haircolors.length() { haircolors[index] } else { "" }
  { stances, name, color }
}

///|
pub fn draw(
  self : Hair,
  stance : @types.StanceId,
  layer : HairLayer,
  frame : Int,
  args : @graphics.DrawArgument
) -> Unit {
  let frameit = self.stances[stance]
    .bind(fn(it) { it[layer] })
    .bind(fn(it) { it.get(frame) })
  match frameit {
    None => ()
    Some(frameit) => frameit.draw(args)
  }
}

///|
pub fn get_name(self : Hair) -> String {
  self.name
}

///|
pub fn getcolor(self : Hair) -> String {
  self.color
}
