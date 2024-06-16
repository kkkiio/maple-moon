struct BodyAction {
  stance : @Stance.Id
  frame : Int
  delay : Int
  move : Point[Int]
  attack_frame : Bool
}

pub fn BodyAction::new(src : NxNode) -> BodyAction {
  let stance = @Stance.by_string(src["action"].get_string())
  let frame = src["frame"].get_int()
  let move = Point::from_resource(src["move"])
  let mut sgndelay = src["delay"].get_int()
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
    stance: @Stance.Id::default(),
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

pub fn get_stance(self : BodyAction) -> @Stance.Id {
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
  {
    body_positions: FixedArray::default(),
    arm_positions: FixedArray::default(),
    hand_positions: FixedArray::default(),
    head_positions: FixedArray::default(),
    hair_positions: FixedArray::default(),
    face_positions: FixedArray::default(),
    stance_delays: FixedArray::default(),
    body_actions: Map::new(),
    attack_delays: Map::new(),
  }
}

pub fn initialize(self : BodyDrawInfo) -> Unit {
  let character_loader = character_loader()
  let bodynode = character_loader.load_res("00002000.img")
  let headnode = character_loader.load_res("00012000.img")
  bodynode.get_array().iter(
    fn(stancenode) {
      let ststr = stancenode.get_string()
      let mut attackdelay : Int = 0
      let mut frame : Int = 0
      while stancenode[frame.to_string()].desc != @json.JsonValue::Null {
        let framenode = stancenode[frame.to_string()]
        let isaction = framenode["action"].get_string() != ""
        if isaction {
          let action = BodyAction::new(framenode)
          self.body_actions[ststr].unwrap().set(frame, action)
          if action.is_attack_frame() {
            self.attack_delays[ststr].unwrap().push(attackdelay)
          }
          attackdelay += action.get_delay()
        } else {
          let stance = @Stance.by_string(ststr)
          let mut delay = framenode["delay"].get_int()
          if delay <= 0 {
            delay = 100
          }
          self.stance_delays[stance.int_value()].set(frame, delay)
          let bodyshiftmap : Map[BodyLayer, Map[String, Point[Int]]] = Map::new()
          framenode.get_array().iter(
            fn(partnode) {
              let part = partnode.get_string()
              if part != "delay" && part != "face" {
                let zstr = partnode["z"].get_string()
                let z = Body::layer_by_name(zstr)
                partnode["map"].get_array().iter(
                  fn(mapnode) {
                    bodyshiftmap[z].unwrap().set(
                      mapnode.get_string(),
                      Point::from_resource(mapnode),
                    )
                  },
                )
              }
            },
          )
          headnode[ststr][frame.to_string()]["head"]["map"].get_array().iter(
            fn(mapnode) {
              bodyshiftmap[BodyLayer::HEAD].unwrap().set(
                mapnode.get_string(),
                Point::from_resource(mapnode),
              )
            },
          )
          self.body_positions[stance.int_value()].set(
            frame,
            bodyshiftmap[BodyLayer::BODY].unwrap()["navel"].unwrap(),
          )
          self.arm_positions[stance.int_value()].set(
            frame,
            if bodyshiftmap.contains(BodyLayer::ARM) {
              bodyshiftmap[BodyLayer::ARM].unwrap()["hand"].unwrap() - bodyshiftmap[BodyLayer::ARM].unwrap()["navel"].unwrap() +
              bodyshiftmap[BodyLayer::BODY].unwrap()["navel"].unwrap()
            } else {
              bodyshiftmap[BodyLayer::ARM_OVER_HAIR].unwrap()["hand"].unwrap() -
              bodyshiftmap[BodyLayer::ARM_OVER_HAIR].unwrap()["navel"].unwrap() +
              bodyshiftmap[BodyLayer::BODY].unwrap()["navel"].unwrap()
            },
          )
          self.hand_positions[stance.int_value()].set(
            frame,
            bodyshiftmap[BodyLayer::HAND_BELOW_WEAPON].unwrap()["handMove"].unwrap(),
          )
          self.head_positions[stance.int_value()].set(
            frame,
            bodyshiftmap[BodyLayer::BODY].unwrap()["neck"].unwrap() - bodyshiftmap[BodyLayer::HEAD].unwrap()["neck"].unwrap(),
          )
          self.face_positions[stance.int_value()].set(
            frame,
            bodyshiftmap[BodyLayer::BODY].unwrap()["neck"].unwrap() - bodyshiftmap[BodyLayer::HEAD].unwrap()["neck"].unwrap() +
            bodyshiftmap[BodyLayer::HEAD].unwrap()["brow"].unwrap(),
          )
          self.hair_positions[stance.int_value()].set(
            frame,
            bodyshiftmap[BodyLayer::HEAD].unwrap()["brow"].unwrap() - bodyshiftmap[BodyLayer::HEAD].unwrap()["neck"].unwrap() +
            bodyshiftmap[BodyLayer::BODY].unwrap()["neck"].unwrap(),
          )
        }
        frame += 1
      }
    },
  )
}

pub fn get_body_position(
  self : BodyDrawInfo,
  stance : @Stance.Id,
  frame : Int
) -> Point[Int] {
  self.body_positions[stance.int_value()].get(frame).or(Point::default())
}

pub fn get_arm_position(
  self : BodyDrawInfo,
  stance : @Stance.Id,
  frame : Int
) -> Point[Int] {
  self.arm_positions[stance.int_value()].get(frame).or(Point::default())
}

pub fn get_hand_position(
  self : BodyDrawInfo,
  stance : @Stance.Id,
  frame : Int
) -> Point[Int] {
  self.hand_positions[stance.int_value()].get(frame).or(Point::default())
}

pub fn get_head_position(
  self : BodyDrawInfo,
  stance : @Stance.Id,
  frame : Int
) -> Point[Int] {
  self.head_positions[stance.int_value()].get(frame).or(Point::default())
}

pub fn get_hair_pos(
  self : BodyDrawInfo,
  stance : @Stance.Id,
  frame : Int
) -> Point[Int] {
  self.hair_positions[stance.int_value()].get(frame).or(Point::default())
}

pub fn get_face_pos(
  self : BodyDrawInfo,
  stance : @Stance.Id,
  frame : Int
) -> Point[Int] {
  self.face_positions[stance.int_value()].get(frame).or(Point::default())
}

pub fn next_frame(self : BodyDrawInfo, stance : @Stance.Id, frame : Int) -> Int {
  if self.stance_delays[stance.int_value()].contains(frame + 1) {
    frame + 1
  } else {
    0
  }
}

pub fn get_delay(self : BodyDrawInfo, stance : @Stance.Id, frame : Int) -> Int {
  self.stance_delays[stance.int_value()].get(frame).or(100)
}

pub fn get_attack_delay(self : BodyDrawInfo, action : String, no : Int) -> Int {
  self.attack_delays[action].unwrap().get(no).or(0)
}

pub fn next_action_frame(
  self : BodyDrawInfo,
  action : String,
  frame : Int
) -> Int {
  if self.body_actions[action].unwrap().contains(frame + 1) {
    frame + 1
  } else {
    0
  }
}

pub fn get_action(
  self : BodyDrawInfo,
  action : String,
  frame : Int
) -> BodyAction? {
  self.body_actions[action].unwrap().get(frame)
}
