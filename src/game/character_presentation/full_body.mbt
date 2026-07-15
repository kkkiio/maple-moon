///|
using @types {type NxStanceBody, type NxMultiPartFrame}

///|
using @resource {type NxFrame}

///|
pub(all) struct FullBody {
  stances : Map[
    StanceId,
    Map[String, (Array[NxFrame], Array[@types.BodyLayer])],
  ]
  name : String
}

///|
// fn Body::load(skin : Int, drawinfo : @types.BodyDrawInfo) -> Body raise {
//   let strid : String = @utils.stoi_left_pad0(skin, 2)
//   let loader = @resource.get_async_loader("body")
//   let bodynode = loader.load_res_async(["000020" + strid + ".img"])
//   let headnode = loader.load_res_async(["000120" + strid + ".img"])
//   Body::new(skin, drawinfo, bodynode, headnode)
// }

///|
pub fn FullBody::FullBody(
  skin : Int,
  drawinfo : @types.BodyDrawInfo,
  bodynode : Map[StanceId, Array[NxStanceBody]],
  headnode : Map[StanceId, Array[NxMultiPartFrame]],
) -> FullBody {
  let stances = Map([])
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
/// 解析一个动作的全身动画
/// - stance: 动作 ID
/// - stance_nx_resource: 动作的身体动画资源 (Body)
/// - head_nx_resource: 动作的头部动画资源 (Head)
/// - drawinfo: 绘制信息 (BodyDrawInfo)
/// 
/// Returns a map of part names to their animation frames and z-layers.
fn parse_body_animations_by_stance(
  stance : StanceId,
  stance_nx_resource : Array[NxStanceBody],
  head_nx_resource : Array[NxMultiPartFrame],
  drawinfo : @types.BodyDrawInfo,
) -> Map[String, (Array[NxFrame], Array[@types.BodyLayer])] {
  let part_frames_map = Map([])
  let body_frame_delays = []
  for frame, framenode in stance_nx_resource {
    guard framenode is NxStanceBody::MultiPartFrame(layer_textures) else {
      continue
    }
    body_frame_delays.push(layer_textures.delay)
    for partname, partnode in layer_textures.part_texture_map {
      guard partname != "head" else {
        @log.error("unexpected head part", data={
          "stance": stance,
          "frame": frame,
        })
        abort("unexpected head part: stance=\{stance}, frame=\{frame}")
      }
      guard partnode.z is Some(layer) else {
        @log.error("Unknown BodyLayer", data={
          "partname": partname,
          "stance": stance,
          "frame": frame,
        })
        abort(
          "Unknown BodyLayer: partname=\{partname}, stance=\{stance}, frame=\{frame}",
        )
      }
      let shift = match layer {
        @types.BodyLayer::HAND_BELOW_WEAPON =>
          drawinfo.get_hand_position(stance, frame) -
          partnode.map.0.get_or_default("handMove", Default::default())
        _ =>
          drawinfo.get_body_position(stance, frame) -
          (if stance is StanceId::DEAD {
            Point(5, 4)
          } else {
            Default::default()
          }) -
          partnode.map.0.get_or_default("navel", Default::default())
      }
      let texture = partnode.texture.frames[0].texture
      let texture = { ..texture, origin: texture.origin - shift }
      let (frames, layers) = part_frames_map.get_or_init(partname, fn() {
        ([], [])
      })
      while frames.length() < frame { // 整个动画里, 有些部位不是一直显示的
        frames.push(@resource.NxFrame::{
          texture: { ..texture, w: 0, h: 0 },
          delay: None,
          head: None,
          bounds: None,
        })
        layers.push(layer)
      }
      frames.push(@resource.NxFrame::{
        texture,
        delay: None,
        head: None,
        bounds: None,
      })
      layers.push(layer)
    }
  }
  // reset delays and pad tails
  let total_frames = stance_nx_resource.length()
  for _, layer_frams in part_frames_map {
    let (frames, layers) = layer_frams
    // Pad tail if necessary
    if frames.length() > 0 && frames.length() < total_frames {
      let last_texture = frames[frames.length() - 1].texture
      while frames.length() < total_frames {
        frames.push(@resource.NxFrame::{
          texture: { ..last_texture, w: 0, h: 0 },
          delay: None,
          head: None,
          bounds: None,
        })
        layers.push(layers[layers.length() - 1])
      }
    }
    layer_frams.0.mapi_in_place(fn(i, frame) {
      { ..frame, delay: body_frame_delays[i] }
    })
  }
  // add head part
  if head_nx_resource.length() > 0 {
    let head_frames = []
    let head_layers = []
    part_frames_map.set("head", (head_frames, head_layers))
    for frame, _ in stance_nx_resource {
      if head_nx_resource[frame]
        is { part_texture_map: { "head": head_texture, .. }, .. } {
        let texture = head_texture.texture.frames[0].texture
        let shift = drawinfo.get_head_position(stance, frame)
        let texture = { ..texture, origin: texture.origin - shift }
        head_frames.push(@resource.NxFrame::{
          texture,
          delay: body_frame_delays[frame],
          head: None,
          bounds: None,
        })
        head_layers.push(@types.BodyLayer::HEAD)
      } else {
        abort("head not found: stance=\{stance}, frame=\{frame}")
      }
    }
  }
  part_frames_map
}

///|
let skintypes : ReadOnlyArray[String] = [
  "Light", "Tan", "Dark", "Pale", "Blue", "Green", "", "", "", "Grey", "Pink", "Red",
]

///|
pub fn FullBody::get_name(self : FullBody) -> String {
  self.name
}

///|
pub impl ToJson for FullBody with fn to_json(self) -> Json {
  { "name": self.name.to_json() }
}
