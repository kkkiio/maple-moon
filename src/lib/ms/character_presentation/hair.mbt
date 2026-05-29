///|
pub(all) enum HairLayer {
  // HAIR_LAYER_NONE = 0
  // HAIR_LAYER_DEFAULT = 1
  // BELOW_BODY = 2
  // OVER_HEAD = 3
  // SHADE = 4
  // BACK = 5
  // BELOW_CAP = 6
  HAIR_LAYER_DEFAULT = 16
  BELOW_BODY = 0
  OVER_HEAD = 25
  SHADE = 20
  BACK = 5
  BELOW_CAP = 6
} derive(Eq, Compare, Debug, Hash)

///|
// pub impl ToJson for HairLayer with to_json(self) {
//   self.to_string().to_json()
// }

///|
pub fn HairLayer::z(self : HairLayer) -> Int = "%identity"

///|
struct Hair {
  stances : Map[StanceId, Map[HairLayer, @resource.NxAnimation]]
  name : String
  color : String
}

///|
pub impl ToJson for Hair with fn to_json(self) -> Json {
  { "name": self.name.to_json(), "color": self.color.to_json() }
}

///|
pub let layers_by_name : @immut/sorted_map.SortedMap[String, HairLayer] = @immut/sorted_map.from_array([
    ("hair", HairLayer::HAIR_LAYER_DEFAULT),
    ("hairBelowBody", HairLayer::BELOW_BODY),
    ("hairOverHead", HairLayer::OVER_HEAD),
    ("hairShade", HairLayer::SHADE),
    ("backHair", HairLayer::BACK),
    ("backHairBelowCap", HairLayer::BELOW_CAP),
  ],
)

///|
pub fn Hair::load(hairid : Int, drawinfo : @types.BodyDrawInfo) -> Hair {
  let strid = "000" + hairid.to_string()
  let hairnode = @resource.require_json("assets/Character/Hair/" + strid + ".img.json")
  let hairnode : NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    hairnode,
  ) catch {
    err => abort("failed to decode hair: \{hairid}, error=\{err}")
  }
  Hair::parse(hairid, hairnode, drawinfo)
}

///|
pub fn Hair::parse(
  hairid : Int,
  hairnode : NxStanceLooks[@types.NxMultiPartFrame],
  drawinfo : @types.BodyDrawInfo,
) -> Hair {
  let stances : Map[StanceId, Map[HairLayer, @resource.NxAnimation]] = Map([])
  for stance, stancenode in hairnode.0 {
    let layers : Map[HairLayer, Array[@resource.NxFrame]] = Map([])
    for frame, framenode in stancenode {
      for layername, layernode in framenode.part_texture_map {
        let layer = match layers_by_name.get(layername) {
          Some(v) => v
          None => {
            @log.warn("Unknown Hair::Layer name", data={
              "layer_name": layername,
            })
            continue
          }
        }
        let brow = layernode.map.0
          .get("brow")
          .unwrap_or(@struct.Point::default())
        let shift = drawinfo.get_hair_pos(stance, frame) - brow
        let texture : @resource.NxTexture = layernode.texture.frames[0].texture
        let texture = { ..texture, origin: texture.origin - shift }
        let frames = layers.get_or_init(layer, fn() { [] })
        while frames.length() < frame { // 整个动画里, 有些部位不是一直显示的
          frames.push(@resource.NxFrame::{
            texture,
            delay: None,
            head: None,
            bounds: None,
          }) // TODO: 填充为空白帧
        }
        frames.push(@resource.NxFrame::{
          texture,
          delay: None,
          head: None,
          bounds: None,
        })
      }
    }
    stances.set(
      stance,
      layers.map(fn(_, frames) { { frames, blend: false, zigzag: false } }),
    )
  }
  let name = hair_names.get(hairid.to_string()).unwrap_or("")
  let haircolors = [
    "Black", "Red", "Orange", "Blonde", "Green", "Blue", "Violet", "Brown",
  ]
  let index = hairid % 10
  let color = if index < haircolors.length() { haircolors[index] } else { "" }
  { stances, name, color }
}

///|
pub fn Hair::get_name(self : Hair) -> String {
  self.name
}

///|
pub fn Hair::getcolor(self : Hair) -> String {
  self.color
}
