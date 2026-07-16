///|
using @struct {type Point}

///|
using @char_stance {type StanceId}

///|
pub(all) struct NxStanceBodyAction {
  stance : StanceId
  frame : Int
  delay : Int
  mov : Point[Int]
  attack_frame : Bool
}

///|
pub impl @json.FromJson for NxStanceBodyAction with fn from_json(value, path) {
  match value {
    { "action": Json::String(ststr), "frame": Json::Number(frame, ..), .. } => {
      let sgndelay = match value {
        { "delay": Json::Number(n, ..), .. } => n.to_int()
        { "delay": Json::String(s), .. } =>
          @string.parse_int(s) catch {
            e => raise @json.JsonDecodeError((path, e.to_string()))
          }
        _ => 100
      }
      let (delay, attack_frame) = if sgndelay > 0 {
        (sgndelay, true)
      } else {
        (-sgndelay, false)
      }
      let mov = match value {
        { "move": [Json::Number(x, ..), Json::Number(y, ..)], .. } =>
          Point(x.to_int(), y.to_int())
        _ => Default::default()
      }
      {
        stance: StanceId::from_name(ststr).unwrap(),
        frame: frame.to_int(),
        delay,
        mov,
        attack_frame,
      }
    }
    _ =>
      raise @json.JsonDecodeError(
        (path, "BodyAction::from_json: expected object"),
      )
  }
}

///|
pub fn NxStanceBodyAction::default() -> NxStanceBodyAction {
  {
    stance: Default::default(),
    frame: 0,
    delay: 0,
    mov: Default::default(),
    attack_frame: false,
  }
}

///|
pub fn NxStanceBodyAction::is_attack_frame(self : NxStanceBodyAction) -> Bool {
  self.attack_frame
}

///|
pub fn NxStanceBodyAction::get_frame(self : NxStanceBodyAction) -> Int {
  self.frame
}

///|
pub fn NxStanceBodyAction::get_delay(self : NxStanceBodyAction) -> Int {
  self.delay
}

///|
pub fn NxStanceBodyAction::get_move(self : NxStanceBodyAction) -> Point[Int] {
  self.mov
}

///|
pub fn NxStanceBodyAction::get_stance(self : NxStanceBodyAction) -> StanceId {
  self.stance
}

///|
struct BodyDrawInfo {
  body_positions : FixedArray[Map[Int, Point[Int]]]
  arm_positions : FixedArray[Map[Int, Point[Int]]]
  hand_positions : FixedArray[Map[Int, Point[Int]]]
  head_positions : FixedArray[Map[Int, Point[Int]]]
  hair_positions : FixedArray[Map[Int, Point[Int]]]
  face_positions : FixedArray[Map[Int, Point[Int]]]
  stance_delays : FixedArray[Map[Int, Int]]
  body_actions : Map[StanceId, Map[Int, NxStanceBodyAction]]
  attack_delays : Map[StanceId, Array[Int]]
}

///|
pub fn BodyDrawInfo::BodyDrawInfo(
  bodynode : Map[StanceId, Array[NxStanceBody]],
  headnode : Map[StanceId, Array[NxMultiPartFrame]],
) -> BodyDrawInfo {
  let body_positions = FixedArray::makei(StanceId::count(), fn(_i) { Map([]) })
  let arm_positions = FixedArray::makei(StanceId::count(), fn(_i) { Map([]) })
  let hand_positions = FixedArray::makei(StanceId::count(), fn(_i) { Map([]) })
  let head_positions = FixedArray::makei(StanceId::count(), fn(_i) { Map([]) })
  let hair_positions = FixedArray::makei(StanceId::count(), fn(_i) { Map([]) })
  let face_positions = FixedArray::makei(StanceId::count(), fn(_i) { Map([]) })
  let stance_delays = FixedArray::makei(StanceId::count(), fn(_i) { Map([]) })
  let body_actions = Map([])
  let attack_delays = Map([])
  for stance, stancenode in bodynode {
    let mut attackdelay : Int = 0
    for frame, frame_json in stancenode {
      match frame_json {
        NxStanceBody::Action(action) => {
          (match body_actions.get(stance) {
            Some(v) => v
            None => {
              let v = Map([])
              body_actions.set(stance, v)
              v
            }
          }).set(frame, action)
          if action.is_attack_frame() {
            (match attack_delays.get(stance) {
              Some(v) => v
              None => {
                let v = Array::new()
                attack_delays.set(stance, v)
                v
              }
            }).push(attackdelay)
          }
          attackdelay += action.get_delay()
        }
        NxStanceBody::MultiPartFrame(layer_textures) => {
          let delay = layer_textures.delay.unwrap_or(100)
          stance_delays[stance.int_value()].set(frame, delay)
          let parts = []
          for _, partnode in layer_textures.part_texture_map {
            parts.push(partnode)
          }
          let head_shift_map = headnode
            .get(stance)
            .bind(fn(it) { it.get(frame) })
            .bind(fn(it) { it.part_texture_map.get("head") })
            .map(fn(it) { it.map.0 })
            .unwrap_or(Map([]))
          let bodyshiftmap : Map[BodyLayer, Map[String, Point[Int]]] = Map([])
          for _, part in parts {
            guard part.z is Some(z) else { continue }
            bodyshiftmap.set(z, part.map.0)
          }
          bodyshiftmap[BodyLayer::HEAD] = head_shift_map
          fn get_shift(layer, key) {
            bodyshiftmap
            .get(layer)
            .bind(fn(it) { it.get(key) })
            .unwrap_or(Default::default())
          }

          body_positions[stance.int_value()].set(
            frame,
            get_shift(BodyLayer::BODY, "navel"),
          )
          arm_positions[stance.int_value()].set(
            frame,
            if bodyshiftmap.contains(BodyLayer::ARM) {
              get_shift(BodyLayer::ARM, "hand") -
              get_shift(BodyLayer::ARM, "navel") +
              get_shift(BodyLayer::BODY, "navel")
            } else {
              get_shift(BodyLayer::ARM_OVER_HAIR, "hand") -
              get_shift(BodyLayer::ARM_OVER_HAIR, "navel") +
              get_shift(BodyLayer::BODY, "navel")
            },
          )
          hand_positions[stance.int_value()].set(
            frame,
            get_shift(BodyLayer::HAND_BELOW_WEAPON, "handMove"),
          )
          head_positions[stance.int_value()].set(
            frame,
            get_shift(BodyLayer::BODY, "neck") -
            get_shift(BodyLayer::HEAD, "neck"),
          )
          face_positions[stance.int_value()].set(
            frame,
            get_shift(BodyLayer::BODY, "neck") -
            get_shift(BodyLayer::HEAD, "neck") +
            get_shift(BodyLayer::HEAD, "brow"),
          )
          hair_positions[stance.int_value()].set(
            frame,
            get_shift(BodyLayer::HEAD, "brow") -
            get_shift(BodyLayer::HEAD, "neck") +
            get_shift(BodyLayer::BODY, "neck"),
          )
        }
      }
    }
  }
  {
    body_positions,
    arm_positions,
    hand_positions,
    head_positions,
    face_positions,
    hair_positions,
    stance_delays,
    body_actions,
    attack_delays,
  }
}

///|
/// For testing
pub fn BodyDrawInfo::default() -> BodyDrawInfo {
  {
    body_positions: [],
    arm_positions: [],
    hand_positions: [],
    head_positions: [],
    hair_positions: [],
    face_positions: [],
    stance_delays: [],
    body_actions: Map([]),
    attack_delays: Map([]),
  }
}

///|
pub(all) struct ShiftMap(Map[String, @struct.Point[Int]]) derive(FromJson)

///|
pub fn BodyDrawInfo::get_body_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Point[Int] {
  self.body_positions[stance.int_value()]
  .get(frame)
  .unwrap_or(Default::default())
}

///|
pub fn BodyDrawInfo::get_arm_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Point[Int] {
  self.arm_positions[stance.int_value()]
  .get(frame)
  .unwrap_or(Default::default())
}

///|
pub fn BodyDrawInfo::get_hand_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Point[Int] {
  self.hand_positions[stance.int_value()]
  .get(frame)
  .unwrap_or(Default::default())
}

///|
pub fn BodyDrawInfo::get_head_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Point[Int] {
  self.head_positions[stance.int_value()]
  .get(frame)
  .unwrap_or(Default::default())
}

///|
pub fn BodyDrawInfo::get_hair_pos(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Point[Int] {
  self.hair_positions[stance.int_value()]
  .get(frame)
  .unwrap_or(Default::default())
}

///|
pub fn BodyDrawInfo::get_face_pos(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Point[Int] {
  self.face_positions[stance.int_value()]
  .get(frame)
  .unwrap_or(Default::default())
}

///|
pub fn BodyDrawInfo::next_frame(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Int {
  if self.stance_delays[stance.int_value()].contains(frame + 1) {
    frame + 1
  } else {
    0
  }
}

///|
pub fn BodyDrawInfo::get_delay(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Int {
  self.stance_delays[stance.int_value()].get(frame).unwrap_or(100)
}

///|
pub fn BodyDrawInfo::get_attack_delay(
  self : BodyDrawInfo,
  action : String,
  no : Int,
) -> Int {
  guard StanceId::from_name(action) is Some(stance) else { return 0 }
  self.attack_delays.get(stance).bind(fn(it) { it.get(no) }).unwrap_or(0)
}

///|
pub fn BodyDrawInfo::next_action_frame(
  self : BodyDrawInfo,
  action : String,
  frame : Int,
) -> Int {
  guard StanceId::from_name(action) is Some(stance) else { return 0 }
  guard self.body_actions.get(stance) is Some(frames) else { return 0 }
  match frames.get(frame + 1) {
    Some(_) => frame + 1
    None => 0
  }
}

///|
pub fn BodyDrawInfo::get_action(
  self : BodyDrawInfo,
  action : String,
  frame : Int,
) -> NxStanceBodyAction? {
  guard StanceId::from_name(action) is Some(stance) else { return None }
  self.body_actions.get(stance).bind(fn(it) { it.get(frame) })
}

///|
pub enum NxStanceBody {
  Action(NxStanceBodyAction)
  MultiPartFrame(NxMultiPartFrame)
}

///|
pub impl @json.FromJson for NxStanceBody with fn from_json(json, path) {
  match json {
    { "action": Json::String(_), .. } => Action(@json.from_json(json, path~))
    _ => MultiPartFrame(@json.from_json(json, path~))
  }
}

///|
/// 动作每个帧可能包含多个部位的动画
pub(all) struct NxMultiPartFrame {
  /// part name => texture. 注意: 整个动画里, 有些部位不是一直显示的.
  part_texture_map : Map[String, NxBodyLayerTexture]
  delay : Int?
}

///|
pub impl @json.FromJson for NxMultiPartFrame with fn from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let mut delay = None
  let layer_textures = Map([])
  for k, v in obj {
    if k == "delay" {
      guard v is Number(delay_value, ..) else {
        raise @json.JsonDecodeError((path.add_key(k), "expect number"))
      }
      delay = Some(delay_value.to_int())
      continue
    }
    guard v is Object(_) else { continue }
    let layer_texture = @json.from_json(v, path=path.add_key(k))
    layer_textures.set(k, layer_texture)
  }
  { part_texture_map: layer_textures, delay }
}

///|
pub(all) struct NxBodyLayerTexture {
  z : BodyLayer?
  texture : @res.NxAnimation
  map : ShiftMap
}

///|
pub impl @json.FromJson for NxBodyLayerTexture with fn from_json(json, path) {
  let z = match json {
    { "z": Json::String(z), .. } => BodyLayer::from_name(z)
    _ => None
  }
  let texture = @json.from_json(json, path~)
  let map = match json {
    { "map": map_json, .. } => @json.from_json(map_json, path~)
    _ => Map([])
  }
  { z, texture, map }
}
