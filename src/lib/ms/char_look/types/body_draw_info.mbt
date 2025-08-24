///|
typealias @struct.Point

///|
struct BodyAction {
  stance : StanceId
  frame : Int
  delay : Int
  mov : Point[Int]
  attack_frame : Bool
}

///|
pub impl @json.FromJson for BodyAction with from_json(value, path) {
  match value {
    { "action": Json::String(ststr), "frame": Json::Number(frame), .. } => {
      let sgndelay = match value {
        { "delay": Json::Number(n), .. } => n.to_int()
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
        { "move": [Json::Number(x), Json::Number(y)], .. } =>
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
pub fn BodyAction::default() -> BodyAction {
  {
    stance: StanceId::default(),
    frame: 0,
    delay: 0,
    mov: @struct.Point::default(),
    attack_frame: false,
  }
}

///|
pub fn is_attack_frame(self : BodyAction) -> Bool {
  self.attack_frame
}

///|
pub fn get_frame(self : BodyAction) -> Int {
  self.frame
}

///|
pub fn get_delay(self : BodyAction) -> Int {
  self.delay
}

///|
pub fn get_move(self : BodyAction) -> Point[Int] {
  self.mov
}

///|
pub fn get_stance(self : BodyAction) -> StanceId {
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
  body_actions : Map[String, Map[Int, BodyAction]]
  attack_delays : Map[String, Array[Int]]
}

///|
pub fn BodyDrawInfo::new(
  bodynode : Json,
  headnode : Json
) -> BodyDrawInfo raise {
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
  for ststr, stancenode in bodynode.as_object().or({}) {
    let mut attackdelay : Int = 0
    guard stancenode is Json::Object(stancenode) else { continue }
    for
      it in @utils.ints().map_while(fn(i) {
        stancenode.get(i.to_string()).map(fn(it) { (i, it) })
      }) {
      let (frame, frame_json) = it
      match frame_json {
        { "action": Json::String(_), .. } => {
          let action : BodyAction = @json.from_json(frame_json)
          (match body_actions.get(ststr) {
            Some(v) => v
            None => {
              let v = Map::new()
              body_actions.set(ststr, v)
              v
            }
          }).set(frame, action)
          if action.is_attack_frame() {
            (match attack_delays.get(ststr) {
              Some(v) => v
              None => {
                let v = Array::new()
                attack_delays.set(ststr, v)
                v
              }
            }).push(attackdelay)
          }
          attackdelay += action.get_delay()
        }
        Json::Object(frame_json) => {
          let stance = StanceId::by_string(ststr)
          let delay = match frame_json {
            { "delay": Json::Number(delay_value), .. } => delay_value.to_int()
            _ => 100
          }
          stance_delays[stance.int_value()].set(frame, delay)
          let parts = []
          for _, partnode in frame_json {
            match partnode {
              { "z": Json::String(zstr), "map": map_json, .. } => {
                let z = BodyLayer::layer_by_name(zstr)
                let map = @json.from_json(map_json)
                parts.push({ z, map })
              }
              _ => ()
            }
          }
          let head_json = headnode
            .as_object()
            .bind(fn(it) { it.get(ststr) })
            .bind(fn(it) { it.as_object() })
            .bind(fn(it) { it.get(frame.to_string()) })
            .or(Json::null())
          let head_shift_map = match head_json {
            { "head": { "map": map_json, .. }, .. } => @json.from_json(map_json)
            _ => ShiftMap(Map::new())
          }
          let bodyshiftmap : Map[BodyLayer, Map[String, Point[Int]]] = Map::new()
          for _, part in parts {
            bodyshiftmap.set(part.z, part.map.inner())
          }
          bodyshiftmap[BodyLayer::HEAD] = head_shift_map.inner()
          fn get_shift(layer, key) {
            bodyshiftmap
            .get(layer)
            .bind(fn(it) { it.get(key) })
            .or(Point::default())
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
        _ => panic()
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

///| For testing
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
priv struct StanceFramePartConfig {
  map : ShiftMap
  z : BodyLayer
}

///|
priv type ShiftMap Map[String, @struct.Point[Int]] derive(FromJson, ToJson)

///|
pub fn get_body_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int
) -> Point[Int] {
  self.body_positions[stance.int_value()].get(frame).or(Point::default())
}

///|
pub fn get_arm_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int
) -> Point[Int] {
  self.arm_positions[stance.int_value()].get(frame).or(Point::default())
}

///|
pub fn get_hand_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int
) -> Point[Int] {
  self.hand_positions[stance.int_value()].get(frame).or(Point::default())
}

///|
pub fn get_head_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int
) -> Point[Int] {
  self.head_positions[stance.int_value()].get(frame).or(Point::default())
}

///|
pub fn get_hair_pos(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int
) -> Point[Int] {
  self.hair_positions[stance.int_value()].get(frame).or(Point::default())
}

///|
pub fn get_face_pos(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int
) -> Point[Int] {
  self.face_positions[stance.int_value()].get(frame).or(Point::default())
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
  frame : Int
) -> Int {
  self.stance_delays[stance.int_value()].get(frame).or(100)
}

///|
pub fn get_attack_delay(self : BodyDrawInfo, action : String, no : Int) -> Int {
  self.attack_delays.get(action).bind(fn(it) { it.get(no) }).or(0)
}

///|
pub fn next_action_frame(
  self : BodyDrawInfo,
  action : String,
  frame : Int
) -> Int {
  match self.body_actions.get(action).bind(fn(it) { it.get(frame + 1) }) {
    Some(_) => frame + 1
    None => 0
  }
}

///|
pub fn get_action(
  self : BodyDrawInfo,
  action : String,
  frame : Int
) -> BodyAction? {
  self.body_actions.get(action).bind(fn(it) { it.get(frame) })
}
