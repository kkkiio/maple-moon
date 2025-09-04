///|
typealias @struct.Point

///|
struct NxStanceBodyAction {
  stance : StanceId
  frame : Int
  delay : Int
  mov : Point[Int]
  attack_frame : Bool
}

///|
pub impl @json.FromJson for NxStanceBodyAction with from_json(value, path) {
  match value {
    { "action": Json::String(ststr), "frame": Json::Number(frame, ..), .. } => {
      let sgndelay = match value {
        { "delay": Json::Number(n, ..), .. } => n.to_int()
        { "delay": Json::String(s), .. } =>
          @strconv.parse_int(s) catch {
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
          Point::new(x.to_int(), y.to_int())
        _ => Point::default()
      }
      {
        stance: StanceId::by_string(ststr),
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
    stance: StanceId::default(),
    frame: 0,
    delay: 0,
    mov: @struct.Point::default(),
    attack_frame: false,
  }
}

///|
pub fn is_attack_frame(self : NxStanceBodyAction) -> Bool {
  self.attack_frame
}

///|
pub fn get_frame(self : NxStanceBodyAction) -> Int {
  self.frame
}

///|
pub fn get_delay(self : NxStanceBodyAction) -> Int {
  self.delay
}

///|
pub fn get_move(self : NxStanceBodyAction) -> Point[Int] {
  self.mov
}

///|
pub fn get_stance(self : NxStanceBodyAction) -> StanceId {
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
pub fn BodyDrawInfo::new(
  bodynode : Map[StanceId, Array[NxStanceBody]],
  headnode : Map[StanceId, Array[NxLayerTextures]],
) -> BodyDrawInfo {
  let body_positions = FixedArray::makei(StanceId::count(), fn(_i) {
    Map::new()
  })
  let arm_positions = FixedArray::makei(StanceId::count(), fn(_i) { Map::new() })
  let hand_positions = FixedArray::makei(StanceId::count(), fn(_i) {
    Map::new()
  })
  let head_positions = FixedArray::makei(StanceId::count(), fn(_i) {
    Map::new()
  })
  let hair_positions = FixedArray::makei(StanceId::count(), fn(_i) {
    Map::new()
  })
  let face_positions = FixedArray::makei(StanceId::count(), fn(_i) {
    Map::new()
  })
  let stance_delays = FixedArray::makei(StanceId::count(), fn(_i) { Map::new() })
  let body_actions = Map::new()
  let attack_delays = Map::new()
  for stance, stancenode in bodynode {
    let mut attackdelay : Int = 0
    for frame, frame_json in stancenode {
      match frame_json {
        NxStanceBody::Action(action) => {
          (match body_actions.get(stance) {
            Some(v) => v
            None => {
              let v = Map::new()
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
        NxStanceBody::LayerTextures(layer_textures) => {
          let delay = layer_textures.delay.unwrap_or(100)
          stance_delays[stance.int_value()].set(frame, delay)
          let parts = []
          for _, partnode in layer_textures.textures {
            parts.push(partnode)
          }
          let head_shift_map = headnode
            .get(stance)
            .bind(fn(it) { it.get(frame) })
            .bind(fn(it) { it.textures.get("head") })
            .map(fn(it) { it.map.inner() })
            .unwrap_or({})
          let bodyshiftmap : Map[BodyLayer, Map[String, Point[Int]]] = Map::new()
          for _, part in parts {
            bodyshiftmap.set(part.z, part.map.inner())
          }
          bodyshiftmap[BodyLayer::HEAD] = head_shift_map
          fn get_shift(layer, key) {
            bodyshiftmap
            .get(layer)
            .bind(fn(it) { it.get(key) })
            .unwrap_or(Point::default())
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
    body_actions: Map::new(),
    attack_delays: Map::new(),
  }
}

///|
pub(all) struct ShiftMap(Map[String, @struct.Point[Int]]) derive(FromJson)

///|
pub fn get_body_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Point[Int] {
  self.body_positions[stance.int_value()].get(frame).unwrap_or(Point::default())
}

///|
pub fn get_arm_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Point[Int] {
  self.arm_positions[stance.int_value()].get(frame).unwrap_or(Point::default())
}

///|
pub fn get_hand_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Point[Int] {
  self.hand_positions[stance.int_value()].get(frame).unwrap_or(Point::default())
}

///|
pub fn get_head_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Point[Int] {
  self.head_positions[stance.int_value()].get(frame).unwrap_or(Point::default())
}

///|
pub fn get_hair_pos(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Point[Int] {
  self.hair_positions[stance.int_value()].get(frame).unwrap_or(Point::default())
}

///|
pub fn get_face_pos(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int,
) -> Point[Int] {
  self.face_positions[stance.int_value()].get(frame).unwrap_or(Point::default())
}

///|
pub fn next_frame(self : BodyDrawInfo, stance : StanceId, frame : Int) -> Int {
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
pub fn get_attack_delay(self : BodyDrawInfo, action : String, no : Int) -> Int {
  guard StanceId::from_name(action) is Some(stance) else { return 0 }
  self.attack_delays.get(stance).bind(fn(it) { it.get(no) }).unwrap_or(0)
}

///|
pub fn next_action_frame(
  self : BodyDrawInfo,
  action : String,
  frame : Int,
) -> Int {
  guard StanceId::from_name(action) is Some(stance) else { return 0 }
  match self.body_actions.get(stance).bind(fn(it) { it.get(frame + 1) }) {
    Some(_) => frame + 1
    None => 0
  }
}

///|
pub fn get_action(
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
  LayerTextures(NxLayerTextures)
}

///|
pub impl @json.FromJson for NxStanceBody with from_json(json, path) {
  match json {
    { "action": Json::String(_), .. } => Action(@json.from_json(json, path~))
    _ => LayerTextures(@json.from_json(json, path~))
  }
}

///|
pub(all) struct NxLayerTextures {
  textures : Map[String, NxBodyLayerTexture]
  delay : Int?
}

///|
pub impl @json.FromJson for NxLayerTextures with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let mut delay = None
  let layer_textures = Map::new()
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
  { textures: layer_textures, delay }
}

///|
pub(all) struct NxBodyLayerTexture {
  z : BodyLayer
  texture : @resource.NxAnimation
  map : ShiftMap
}

///|
pub impl @json.FromJson for NxBodyLayerTexture with from_json(json, path) {
  let z = match json {
    { "z": Json::String(z), .. } =>
      layers_by_name_.get(z).unwrap_or(BodyLayer::BODY_NONE)
    _ => BodyLayer::BODY_NONE
  }
  let texture = @json.from_json(json, path~)
  let map = match json {
    { "map": map_json, .. } => @json.from_json(map_json, path~)
    _ => {}
  }
  { z, texture, map }
}
