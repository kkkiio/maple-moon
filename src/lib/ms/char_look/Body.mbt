///|
pub(all) struct Body {
  stances : Map[@types.StanceId, Map[@types.BodyLayer, @sprite.Sprite]]
  name : String
}

///|
// async fn Body::load(skin : Int, drawinfo : @types.BodyDrawInfo) -> Body raise {
//   let strid : String = @string_format.stoi_left_pad0(skin, 2)
//   let loader = get_body_loader()
//   let bodynode = loader.load_res_async(["000020" + strid + ".img"])
//   let headnode = loader.load_res_async(["000120" + strid + ".img"])
//   Body::new(skin, drawinfo, bodynode, headnode)
// }

///|
pub fn Body::new(
  skin : Int,
  drawinfo : @types.BodyDrawInfo,
  bodynode : Map[@types.StanceId, Array[@types.NxStanceBody]],
  headnode : Map[@types.StanceId, Array[@types.NxLayerTextures]],
) -> Body {
  let stances = {}
  for stance, stance_body in bodynode {
    let stance_head = headnode.get(stance).unwrap_or([])
    stances.set(
      stance,
      new_body_stance(stance, stance_body, stance_head, drawinfo),
    )
  }
  let index = skin
  let name = if index < skintypes.length() { skintypes[index] } else { "" }
  { stances, name }
}

///|
fn new_body_stance(
  stance : @types.StanceId,
  stance_nx_resource : Array[@types.NxStanceBody],
  head_nx_resource : Array[@types.NxLayerTextures],
  drawinfo : @types.BodyDrawInfo,
) -> Map[@types.BodyLayer, @sprite.Sprite] {
  let layer_frames_map : Map[@types.BodyLayer, AnimationData] = Map::new()
  for frame, framenode in stance_nx_resource {
    guard framenode is @types.NxStanceBody::LayerTextures(layer_textures) else {
      continue
    }
    for _, partnode in layer_textures.textures {
      let layer = partnode.z
      let shift = match layer {
        @types.BodyLayer::HAND_BELOW_WEAPON =>
          drawinfo.get_hand_position(stance, frame) -
          partnode.map
          .inner()
          .get_or_default("handMove", @struct.Point::default())
        _ => {
          let mut shift = drawinfo.get_body_position(stance, frame)
          if stance == @types.StanceId::DEAD {
            shift -= @struct.Point::new(5, 4)
          }
          shift -= partnode.map
            .inner()
            .get_or_default("navel", @struct.Point::default())
          shift
        }
      }
      let texture = partnode.texture.frames[0].texture
      let texture = { ..texture, origin: texture.origin - shift }
      let layer_frames = layer_frames_map.get_or_init(layer, fn() {
        {
          frames: Array::make(stance_nx_resource.length(), @sprite.AnimationFrame::{
            sprite_path: "",
            size: @selene_math.Vec2D(0, 0),
            offset: @selene_math.Vec2D(0, 0),
          }),
          left_top: -@selene_math.Vec2D(
            texture.origin.x.to_double(),
            texture.origin.y.to_double(),
          ),
          delay_ms: layer_textures.delay.unwrap_or(100),
        }
      })
      layer_frames.frames[frame] = {
        sprite_path: texture.i,
        size: @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
        offset: @selene_math.Vec2D(
          texture.offset.x.to_double(),
          texture.offset.y.to_double(),
        ),
      }
    }
    if head_nx_resource.get(frame)
      is Some({ textures: { "head": head_texture, .. }, delay }) {
      let texture = head_texture.texture.frames[0].texture
      let shift = drawinfo.get_head_position(stance, frame)
      let texture = { ..texture, origin: texture.origin - shift }
      let layer_frames = layer_frames_map.get_or_init(@types.BodyLayer::HEAD, fn() {
        {
          frames: Array::make(stance_nx_resource.length(), @sprite.AnimationFrame::{
            sprite_path: "",
            size: @selene_math.Vec2D(0, 0),
            offset: @selene_math.Vec2D(0, 0),
          }),
          left_top: -@selene_math.Vec2D(
            texture.origin.x.to_double(),
            texture.origin.y.to_double(),
          ),
          delay_ms: delay.unwrap_or(100),
        }
      })
      layer_frames.frames[frame] = {
        sprite_path: texture.i,
        size: @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
        offset: @selene_math.Vec2D(
          texture.offset.x.to_double(),
          texture.offset.y.to_double(),
        ),
      }
    }
  }
  layer_frames_map.map(fn(_, frames) {
    @sprite.Sprite::from_animation(
      @sprite.Animation::new(
        frames.frames,
        loop_=true,
        rate=1000.0 / frames.delay_ms.to_double() / @graphics.fps.to_double(),
      ), // fps * rate == 1000 / delay_ms
      0,
      offset=frames.left_top,
    )
  })
}

///|
let skintypes = [
  "Light", "Tan", "Dark", "Pale", "Blue", "Green", "", "", "", "Grey", "Pink", "Red",
]

///|
pub fn Body::draw(
  _self : Body,
  _stance : @types.StanceId,
  _layer : @types.BodyLayer,
  _frame : Int,
  _args : @graphics.DrawArgument,
) -> Unit {
  // let frameit = self.stances
  //   .get(stance)
  //   .bind(fn(it) { it.get(layer) })
  //   .bind(fn(it) { it.get(frame) })
  // match frameit {
  //   Some(v) => v.draw(args)
  //   None => ()
  // }
}

///|
pub fn Body::get_name(self : Body) -> String {
  self.name
}

///|
pub impl ToJson for Body with to_json(self) -> Json {
  { "name": self.name.to_json() }
}

///|
typealias @graphics.AnimationData
