typealias Point[T] = @struct.Point[T]

typealias NxNode = @resource.NxNode

struct BodyAction {
  stance : StanceId
  frame : Int
  delay : Int
  move : Point[Int]
  attack_frame : Bool
}

pub fn BodyAction::new(src : NxNode) -> BodyAction {
  let stance = StanceId::by_string(src["action"].get_string())
  let frame = src["frame"].get_int?().unwrap()
  let move = src["move"].as_point?().unwrap()
  let mut sgndelay = src["delay"].get_int?().unwrap()
  if sgndelay == 0 {
    sgndelay = 100
  }
  let (delay, attack_frame) = if sgndelay > 0 {
    (sgndelay, true)
  } else {
    (-sgndelay, false)
  }
  { stance, frame, delay, move, attack_frame }
}

pub fn BodyAction::default() -> BodyAction {
  {
    stance: StanceId::default(),
    frame: 0,
    delay: 0,
    move: Point::default(),
    attack_frame: false,
  }
}

pub fn is_attack_frame(self : BodyAction) -> Bool {
  self.attack_frame
}

pub fn get_frame(self : BodyAction) -> Int {
  self.frame
}

pub fn get_delay(self : BodyAction) -> Int {
  self.delay
}

pub fn get_move(self : BodyAction) -> Point[Int] {
  self.move
}

pub fn get_stance(self : BodyAction) -> StanceId {
  self.stance
}

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

pub fn BodyDrawInfo::new() -> BodyDrawInfo {
  let body_positions = FixedArray::makei(
    StanceId::count(),
    fn(_i) { Map::new() },
  )
  let arm_positions = FixedArray::makei(
    StanceId::count(),
    fn(_i) { Map::new() },
  )
  let hand_positions = FixedArray::makei(
    StanceId::count(),
    fn(_i) { Map::new() },
  )
  let head_positions = FixedArray::makei(
    StanceId::count(),
    fn(_i) { Map::new() },
  )
  let hair_positions = FixedArray::makei(
    StanceId::count(),
    fn(_i) { Map::new() },
  )
  let face_positions = FixedArray::makei(
    StanceId::count(),
    fn(_i) { Map::new() },
  )
  let stance_delays = FixedArray::makei(
    StanceId::count(),
    fn(_i) { Map::new() },
  )
  let body_actions = Map::new()
  let attack_delays = Map::new()
  let character_loader = @resource.character_loader()
  let bodynode = character_loader.load_res(["00002000.img"])
  let headnode = character_loader.load_res(["00012000.img"])
  bodynode.each(
    fn(stancenode) {
      let ststr = stancenode.name()
      let mut attackdelay : Int = 0
      let mut frame : Int = 0
      while stancenode[frame.to_string()].is_null().not() {
        let framenode = stancenode[frame.to_string()]
        let isaction = framenode["action"].get_string() != ""
        if isaction {
          let action = BodyAction::new(framenode)
          (match body_actions[ststr] {
            Some(v) => v
            None => {
              let v = Map::new()
              body_actions.set(ststr, v)
              v
            }
          }).set(frame, action)
          if action.is_attack_frame() {
            (match attack_delays[ststr] {
              Some(v) => v
              None => {
                let v = Array::new()
                attack_delays.set(ststr, v)
                v
              }
            }).push(attackdelay)
          }
          attackdelay += action.get_delay()
        } else {
          let stance = StanceId::by_string(ststr)
          let mut delay = framenode["delay"].get_int?().unwrap()
          if delay <= 0 {
            delay = 100
          }
          stance_delays[stance.int_value()].set(frame, delay)
          let bodyshiftmap : Map[BodyLayer, Map[String, Point[Int]]] = Map::new()
          framenode.each(
            fn(partnode) {
              let part = partnode.name()
              if part != "delay" && part != "face" {
                let zstr = partnode["z"].get_string()
                let z = Body::layer_by_name(zstr)
                partnode["map"].each(
                  fn(mapnode) {
                    let mapnodename = mapnode.name()
                    set_defaultm(bodyshiftmap, z).set(
                      mapnodename,
                      mapnode.as_point?().unwrap(),
                    )
                  },
                )
              }
            },
          )
          headnode[ststr][frame.to_string()]["head"]["map"].each(
            fn(mapnode) {
              let mapnodename = mapnode.name()
              set_defaultm(bodyshiftmap, BodyLayer::HEAD).set(
                mapnodename,
                mapnode.as_point?().unwrap(),
              )
            },
          )
          body_positions[stance.int_value()].set(
            frame,
            bodyshiftmap[BodyLayer::BODY]
            .bind(fn(it) { it["navel"] })
            .or(Point::default()),
          )
          arm_positions[stance.int_value()].set(
            frame,
            if bodyshiftmap.contains(BodyLayer::ARM) {
              bodyshiftmap[BodyLayer::ARM]
              .bind(fn(it) { it["hand"] })
              .or(Point::default()) -
              bodyshiftmap[BodyLayer::ARM]
              .bind(fn(it) { it["navel"] })
              .or(Point::default()) +
              bodyshiftmap[BodyLayer::BODY]
              .bind(fn(it) { it["navel"] })
              .or(Point::default())
            } else {
              bodyshiftmap[BodyLayer::ARM_OVER_HAIR]
              .bind(fn(it) { it["hand"] })
              .or(Point::default()) -
              bodyshiftmap[BodyLayer::ARM_OVER_HAIR]
              .bind(fn(it) { it["navel"] })
              .or(Point::default()) +
              bodyshiftmap[BodyLayer::BODY]
              .bind(fn(it) { it["navel"] })
              .or(Point::default())
            },
          )
          hand_positions[stance.int_value()].set(
            frame,
            bodyshiftmap[BodyLayer::HAND_BELOW_WEAPON]
            .bind(fn(it) { it["handMove"] })
            .or(Point::default()),
          )
          head_positions[stance.int_value()].set(
            frame,
            bodyshiftmap[BodyLayer::BODY]
            .bind(fn(it) { it["neck"] })
            .or(Point::default()) -
            bodyshiftmap[BodyLayer::HEAD]
            .bind(fn(it) { it["neck"] })
            .or(Point::default()),
          )
          face_positions[stance.int_value()].set(
            frame,
            bodyshiftmap[BodyLayer::BODY]
            .bind(fn(it) { it["neck"] })
            .or(Point::default()) -
            bodyshiftmap[BodyLayer::HEAD]
            .bind(fn(it) { it["neck"] })
            .or(Point::default()) +
            bodyshiftmap[BodyLayer::HEAD]
            .bind(fn(it) { it["brow"] })
            .or(Point::default()),
          )
          hair_positions[stance.int_value()].set(
            frame,
            bodyshiftmap[BodyLayer::HEAD]
            .bind(fn(it) { it["brow"] })
            .or(Point::default()) -
            bodyshiftmap[BodyLayer::HEAD]
            .bind(fn(it) { it["neck"] })
            .or(Point::default()) +
            bodyshiftmap[BodyLayer::BODY]
            .bind(fn(it) { it["neck"] })
            .or(Point::default()),
          )
        }
        frame += 1
      }
    },
  )
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

fn set_defaulta[K : Hash + Eq, V](m : Map[K, Array[V]], k : K) -> Array[V] {
  match m[k] {
    Some(v) => v
    None => {
      let v = Array::new()
      m.set(k, v)
      v
    }
  }
}

fn set_defaultm[K : Hash + Eq, K1, V](
  m : Map[K, Map[K1, V]],
  k : K
) -> Map[K1, V] {
  match m[k] {
    Some(v) => v
    None => {
      let v = Map::new()
      m.set(k, v)
      v
    }
  }
}

pub fn get_body_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int
) -> Point[Int] {
  self.body_positions[stance.int_value()].get(frame).or(Point::default())
}

pub fn get_arm_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int
) -> Point[Int] {
  self.arm_positions[stance.int_value()].get(frame).or(Point::default())
}

pub fn get_hand_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int
) -> Point[Int] {
  self.hand_positions[stance.int_value()].get(frame).or(Point::default())
}

pub fn get_head_position(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int
) -> Point[Int] {
  self.head_positions[stance.int_value()].get(frame).or(Point::default())
}

pub fn get_hair_pos(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int
) -> Point[Int] {
  self.hair_positions[stance.int_value()].get(frame).or(Point::default())
}

pub fn get_face_pos(
  self : BodyDrawInfo,
  stance : StanceId,
  frame : Int
) -> Point[Int] {
  self.face_positions[stance.int_value()].get(frame).or(Point::default())
}

pub fn next_frame(self : BodyDrawInfo, stance : StanceId, frame : Int) -> Int {
  if self.stance_delays[stance.int_value()].contains(frame + 1) {
    frame + 1
  } else {
    0
  }
}

pub fn get_delay(self : BodyDrawInfo, stance : StanceId, frame : Int) -> Int {
  self.stance_delays[stance.int_value()].get(frame).or(100)
}

pub fn get_attack_delay(self : BodyDrawInfo, action : String, no : Int) -> Int {
  self.attack_delays[action].bind(fn(it) { it.get(no) }).or(0)
}

pub fn next_action_frame(
  self : BodyDrawInfo,
  action : String,
  frame : Int
) -> Int {
  match self.body_actions[action].bind(fn(it) { it[frame + 1] }) {
    Some(_) => frame + 1
    None => 0
  }
}

pub fn get_action(
  self : BodyDrawInfo,
  action : String,
  frame : Int
) -> BodyAction? {
  self.body_actions[action].bind(fn(it) { it.get(frame) })
}
