///|
pub(all) enum HairLayer {
  HAIR_LAYER_NONE = 0
  HAIR_LAYER_DEFAULT = 1
  BELOW_BODY = 2
  OVER_HEAD = 3
  SHADE = 4
  BACK = 5
  BELOW_CAP = 6
} derive(Eq, Compare, Show, Hash)

///|
pub impl ToJson for HairLayer with to_json(self) {
  self.to_string().to_json()
}

///|
pub fn int_value(self : HairLayer) -> Int = "%identity"

///|
struct Hair {
  stances : Map[@types.StanceId, Map[HairLayer, @sprite.Sprite]]
  name : String
  color : String
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
pub async fn Hair::load(
  hairid : Int,
  drawinfo : @types.BodyDrawInfo,
) -> Hair raise {
  // let hairnode = get_hair_loader().load_res_async(["000\{hairid}.img"])
  // Hair::new(hairid, hairnode, drawinfo)
  ...
}

///|
pub fn Hair::new(
  hairid : Int,
  hairnode : NxStanceLooks[@types.NxLayerTextures],
  drawinfo : @types.BodyDrawInfo,
) -> Hair {
  let stances : Map[@types.StanceId, Map[HairLayer, @sprite.Sprite]] = Map::new()
  for stance, stancenode in hairnode.inner() {
    let layers : Map[
      HairLayer,
      (Array[@sprite.AnimationFrame], @selene_math.Vec2D),
    ] = Map::new()
    for frame, framenode in stancenode {
      for layername, layernode in framenode.textures {
        let layer = match layers_by_name.get(layername) {
          Some(v) => v
          None => {
            @log.warn({ "layer_name": layername }, "Unknown Hair::Layer name")
            continue
          }
        }
        let brow = layernode.map
          .inner()
          .get("brow")
          .unwrap_or(@struct.Point::default())
        let shift = drawinfo.get_hair_pos(stance, frame) - brow
        let tex : @resource.NxTexture = layernode.texture.frames[0].texture
        let tex = { ..tex, origin: tex.origin - shift }
        let ani = layers.get_or_init(layer, fn() {
          (
            Array::make(stancenode.length(), @sprite.AnimationFrame::{
              sprite_path: "",
              size: @selene_math.Vec2D(0, 0),
              offset: @selene_math.Vec2D(0, 0),
            }),
            @selene_math.Vec2D(
              tex.origin.x.to_double(),
              tex.origin.y.to_double(),
            ),
          )
        })
        ani.0[frame] = {
          sprite_path: tex.i,
          size: @selene_math.Vec2D(tex.w.to_double(), tex.h.to_double()),
          offset: @selene_math.Vec2D(
            tex.offset.x.to_double(),
            tex.offset.y.to_double(),
          ),
        }
      }
    }
    stances.set(
      stance,
      layers.map(fn(_, frames) {
        @sprite.Sprite::from_animation(
          @sprite.Animation::new(frames.0, loop_=true),
          0,
          offset=-frames.1,
        )
      }),
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
pub fn draw(
  self : Hair,
  stance : @types.StanceId,
  layer : HairLayer,
  frame : Int,
  args : @graphics.DrawArgument,
) -> Unit {
  // let frameit = self.stances
  //   .get(stance)
  //   .bind(fn(it) { it.get(layer) })
  //   .bind(fn(it) { it.get(frame) })
  // match frameit {
  //   None => ()
  //   Some(frameit) => frameit.draw(args)
  // }
}

///|
pub fn get_name(self : Hair) -> String {
  self.name
}

///|
pub fn getcolor(self : Hair) -> String {
  self.color
}
