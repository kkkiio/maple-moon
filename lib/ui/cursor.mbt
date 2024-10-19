pub enum CursorState {
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

pub fn int_value(self : CursorState) -> Int {
  match self {
    IDLE => 0
    CAN_CLICK => 1
    GAME => 2
    HOUSE => 3
    CAN_CLICK2 => 4
    CAN_GRAB => 5
    GIFT => 6
    VSCROLL => 7
    HSCROLL => 8
    VSCROLL_IDLE => 9
    HSCROLL_IDLE => 10
    GRABBING => 11
    CLICKING => 12
    RCLICK => 13
    LEAF => 18
    CHAT_BAR_VDRAG => 67
    CHAT_BAR_HDRAG => 68
    CHAT_BAR_BLTRDRAG => 69
    CHAT_BAR_MOVE => 72
    CHAT_BAR_BRTLDRAG => 73
  }
}

pub fn hash(self : CursorState) -> Int {
  self.int_value()
}

pub fn hash_combine(self : CursorState, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

pub fn CursorState::by_id(id : Int) -> CursorState? {
  match id {
    0 => Some(IDLE)
    1 => Some(CAN_CLICK)
    2 => Some(GAME)
    3 => Some(HOUSE)
    4 => Some(CAN_CLICK2)
    5 => Some(CAN_GRAB)
    6 => Some(GIFT)
    7 => Some(VSCROLL)
    8 => Some(HSCROLL)
    9 => Some(VSCROLL_IDLE)
    10 => Some(HSCROLL_IDLE)
    11 => Some(GRABBING)
    12 => Some(CLICKING)
    13 => Some(RCLICK)
    18 => Some(LEAF)
    67 => Some(CHAT_BAR_VDRAG)
    68 => Some(CHAT_BAR_HDRAG)
    69 => Some(CHAT_BAR_BLTRDRAG)
    72 => Some(CHAT_BAR_MOVE)
    73 => Some(CHAT_BAR_BRTLDRAG)
    _ => None
  }
}

pub struct Cursor {
  mut state : CursorState
  mut position : Point[Int]
  mut hide_counter : Int
  animations : Map[CursorState, @graphics.Animation]
}

pub let hide_time : Int = 15_000

pub fn Cursor::new() -> Cursor {
  {
    state: CursorState::IDLE,
    position: { x: 0, y: 0 },
    hide_counter: 0,
    animations: {},
  }
}

pub fn draw(self : Cursor, alpha : Double) -> Unit {
  let hide_after = hide_time / @constants.step_time_ms
  if self.hide_counter < hide_after {
    self
    .get_or_init_animation()
    .draw(@graphics.DrawArgument::from_point(self.position), alpha)
  }
}

pub fn update(self : Cursor) -> Unit {
  self.get_or_init_animation().update() |> ignore
  match self.state {
    CursorState::CAN_CLICK
    | CursorState::CAN_CLICK2
    | CursorState::CAN_GRAB | CursorState::CLICKING | CursorState::GRABBING =>
      self.hide_counter = 0
    _ => self.hide_counter += 1
  }
}

pub fn set_state(self : Cursor, state : CursorState) -> Unit {
  if self.state != state {
    self.state = state
    self.get_or_init_animation().reset()
    self.hide_counter = 0
  }
}

pub fn set_position(self : Cursor, position : Point[Int]) -> Unit {
  self.position = position
  self.hide_counter = 0
}

pub fn get_state(self : Cursor) -> CursorState {
  self.state
}

pub fn get_position(self : Cursor) -> Point[Int] {
  self.position
}

fn get_or_init_animation(self : Cursor) -> @graphics.Animation {
  let state = self.state
  match self.animations.get(state) {
    Some(animation) => animation
    None => {
      let animation = @graphics.Animation::from_resource(
        @resource.ui_loader().load_res(
          ["Basic.img", "Cursor", "\{state.int_value()}"],
        ),
      )
      self.animations.set(state, animation)
      animation
    }
  }
}
