pub enum State {
  IDLE
  CAN_CLICK
  GAME
  HOUSE
  CAN_CLICK2
  CAN_GRAB
  GIFT
  VSCROLL
  HSCROLL
  VSCROLL_IDLE
  HSCROLL_IDLE
  GRABBING
  CLICKING
  RCLICK
  LEAF
  CHAT_BAR_VDRAG
  CHAT_BAR_HDRAG
  CHAT_BAR_BLTRDRAG
  CHAT_BAR_MOVE
  CHAT_BAR_BRTLDRAG
} derive(Eq, Compare)
// enum State {
//     IDLE,
//     CAN_CLICK,
//     GAME,
//     HOUSE,
//     CAN_CLICK2,
//     CAN_GRAB,
//     GIFT,
//     VSCROLL,
//     HSCROLL,
//     VSCROLL_IDLE,
//     HSCROLL_IDLE,
//     GRABBING,
//     CLICKING,
//     RCLICK,
//     LEAF = 18,
//     CHAT_BAR_VDRAG = 67,
//     CHAT_BAR_HDRAG,
//     CHAT_BAR_BLTRDRAG,
//     CHAT_BAR_MOVE = 72,
//     CHAT_BAR_BRTLDRAG,
//     LENGTH
// };

pub let all_cursor_states : @map.Map[State, Int] = @map.from_array(
  [
    (IDLE, 0),
    (CAN_CLICK, 1),
    (GAME, 2),
    (HOUSE, 3),
    (CAN_CLICK2, 4),
    (CAN_GRAB, 5),
    (GIFT, 6),
    (VSCROLL, 7),
    (HSCROLL, 8),
    (VSCROLL_IDLE, 9),
    (HSCROLL_IDLE, 10),
    (GRABBING, 11),
    (CLICKING, 12),
    (RCLICK, 13),
    (LEAF, 18),
    (CHAT_BAR_VDRAG, 67),
    (CHAT_BAR_HDRAG, 68),
    (CHAT_BAR_BLTRDRAG, 69),
    (CHAT_BAR_MOVE, 72),
    (CHAT_BAR_BRTLDRAG, 73),
  ],
)

pub fn by_id(id : Int) -> State {
  all_cursor_states.as_iter().find_first(fn(it) -> Bool { id == it.1 }).map(
    fn(it) -> State { it.0 },
  ).unwrap()
}

pub fn int_value(self : State) -> Int {
  all_cursor_states[self].unwrap()
}

fn hash(self : State) -> Int {
  self.int_value()
}

pub struct Cursor {
  mut state : State
  mut position : Point[Int]
  mut hide_counter : Int
  animations : @immut/hashmap.Map[State, Animation]
}

pub let hide_time : Int = 15_000

pub fn Cursor::new(animations : @immut/hashmap.Map[State, Animation]) -> Cursor {
  { state: State::IDLE, position: { x: 0, y: 0 }, hide_counter: 0, animations }
}

pub fn draw(self : Cursor, g : Gl_g, alpha : Double) -> Unit {
  let hide_after = hide_time / @Constants.timestep
  if self.hide_counter < hide_after {
    self.animations[self.state].unwrap().draw(
      g,
      DrawArgument::new2(self.position),
      alpha,
    )
  }
}

pub fn update(self : Cursor) -> Unit {
  self.animations[self.state].unwrap().update() |> ignore
  match self.state {
    State::CAN_CLICK
    | State::CAN_CLICK2 | State::CAN_GRAB | State::CLICKING | State::GRABBING =>
      self.hide_counter = 0
    _ => self.hide_counter += 1
  }
}

pub fn set_state(self : Cursor, state : State) -> Unit {
  if self.state != state {
    self.state = state
    self.animations[self.state].unwrap().reset()
    self.hide_counter = 0
  }
}

pub fn set_position(self : Cursor, position : Point[Int]) -> Unit {
  self.position = position
  self.hide_counter = 0
}

pub fn get_state(self : Cursor) -> State {
  self.state
}

pub fn get_position(self : Cursor) -> Point[Int] {
  self.position
}
