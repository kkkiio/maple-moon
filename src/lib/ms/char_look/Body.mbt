///|
pub(all) struct Body {
  stances : Map[
    @types.StanceId,
    Map[String, (Array[@resource.NxFrame], Array[@types.BodyLayer])],
  ]
  name : String
}

///|
// async fn Body::load(skin : Int, drawinfo : @types.BodyDrawInfo) -> Body raise {
//   let strid : String = @utils.stoi_left_pad0(skin, 2)
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
      parse_body_animations_by_stance(
        stance, stance_body, stance_head, drawinfo,
      ),
    )
  }
  let index = skin
  let name = if index < skintypes.length() { skintypes[index] } else { "" }
  { stances, name }
}

///|
fn parse_body_animations_by_stance(
  stance : @types.StanceId,
  stance_nx_resource : Array[@types.NxStanceBody],
  head_nx_resource : Array[@types.NxLayerTextures],
  drawinfo : @types.BodyDrawInfo,
) -> Map[String, (Array[@resource.NxFrame], Array[@types.BodyLayer])] {
  let part_frames_map = Map::new()
  let body_frame_delays = []
  for frame, framenode in stance_nx_resource { // 一个动作的动画有多帧, 每个帧可能包含多个部位的动画
    guard framenode is @types.NxStanceBody::LayerTextures(layer_textures) else {
      continue
    }
    body_frame_delays.push(layer_textures.delay)
    for partname, partnode in layer_textures.textures {
      guard partname != "head" else {
        @log.error({ "stance": stance, "frame": frame }, "unexpected head part")
        panic()
      }
      guard partnode.z is Some(layer) else {
        @log.error(
          { "partname": partname, "stance": stance, "frame": frame },
          "Unknown BodyLayer",
        )
        panic()
      }
      let shift = match layer {
        @types.BodyLayer::HAND_BELOW_WEAPON =>
          drawinfo.get_hand_position(stance, frame) -
          partnode.map.0.get_or_default("handMove", @struct.Point::default())
        _ =>
          drawinfo.get_body_position(stance, frame) -
          (if stance is @types.StanceId::DEAD {
            @struct.Point::new(5, 4)
          } else {
            @struct.Point::default()
          }) -
          partnode.map.0.get_or_default("navel", @struct.Point::default())
      }
      let texture = partnode.texture.frames[0].texture
      let texture = { ..texture, origin: texture.origin - shift }
      let (frames, layers) = part_frames_map.get_or_init(partname, fn() {
        // {
        //   frames: Array::make(stance_nx_resource.length(), @sprite.AnimationFrame::{
        //     sprite_path: "",
        //     size: @selene_math.Vec2D(0, 0),
        //     offset: @selene_math.Vec2D(0, 0),
        //   }),
        //   left_top: -@selene_math.Vec2D(
        //     texture.origin.x.to_double(),
        //     texture.origin.y.to_double(),
        //   ),
        //   delay_ms: layer_textures.delay.unwrap_or(100),
        // }
        ([], [])
      })
      // guard frames.length() == frame else {
      //   @log.error(
      //     {
      //       "frames": frames.length(),
      //       "frame": frame,
      //       "stance": stance,
      //       "partname": partname,
      //     },
      //     "frames length mismatch",
      //   )
      //   panic()
      // }
      while frames.length() < frame { // 整个动画里, 有些部位不是一直显示的
        frames.push(@resource.NxFrame::{ texture, delay: None }) // TODO: 填充为空白帧
      }
      frames.push(@resource.NxFrame::{ texture, delay: None })
      layers.push(layer)
    }
  }
  // reset delays
  for _, layer_frams in part_frames_map {
    layer_frams.0.mapi_inplace(fn(i, frame) {
      { ..frame, delay: body_frame_delays[i] }
    })
  }
  // add head part
  for frame, _ in stance_nx_resource {
    if head_nx_resource.get(frame)
      is Some({ textures: { "head": head_texture, .. }, delay }) {
      let texture = head_texture.texture.frames[0].texture
      let shift = drawinfo.get_head_position(stance, frame)
      let texture = { ..texture, origin: texture.origin - shift }
      let (frames, layers) = part_frames_map.get_or_init("head", fn() {
        // {
        //   frames: Array::make(stance_nx_resource.length(), @sprite.AnimationFrame::{
        //     sprite_path: "",
        //     size: @selene_math.Vec2D(0, 0),
        //     offset: @selene_math.Vec2D(0, 0),
        //   }),
        //   left_top: -@selene_math.Vec2D(
        //     texture.origin.x.to_double(),
        //     texture.origin.y.to_double(),
        //   ),
        //   delay_ms: delay.unwrap_or(100),
        // }
        ([], [])
      })
      guard frames.length() == frame
      frames.push(@resource.NxFrame::{ texture, delay })
      layers.push(@types.BodyLayer::HEAD)
    }
  }
  part_frames_map
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
