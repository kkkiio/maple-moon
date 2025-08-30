///|
pub(all) enum CursorState {
  IDLE = 0
  CAN_CLICK = 1
  GAME = 2
  HOUSE = 3
  CAN_CLICK2 = 4
  CAN_GRAB = 5
  GIFT = 6
  VSCROLL = 7
  HSCROLL = 8
  VSCROLL_IDLE = 9
  HSCROLL_IDLE = 10
  GRABBING = 11
  CLICKING = 12
  RCLICK = 13
  LEAF = 18
  CHAT_BAR_VDRAG = 67
  CHAT_BAR_HDRAG = 68
  CHAT_BAR_BLTRDRAG = 69
  CHAT_BAR_MOVE = 72
  CHAT_BAR_BRTLDRAG = 73
} derive(Eq, Compare, Hash)

///|
// pub fn int_value(self : CursorState) -> Int {
//   match self {
//     IDLE => 0
//     CAN_CLICK => 1
//     GAME => 2
//     HOUSE => 3
//     CAN_CLICK2 => 4
//     CAN_GRAB => 5
//     GIFT => 6
//     VSCROLL => 7
//     HSCROLL => 8
//     VSCROLL_IDLE => 9
//     HSCROLL_IDLE => 10
//     GRABBING => 11
//     CLICKING => 12
//     RCLICK => 13
//     LEAF => 18
//     CHAT_BAR_VDRAG => 67
//     CHAT_BAR_HDRAG => 68
//     CHAT_BAR_BLTRDRAG => 69
//     CHAT_BAR_MOVE => 72
//     CHAT_BAR_BRTLDRAG => 73
//   }
// }

///|
pub(all) struct Cursor {
  mut state : CursorState
  mut hide_counter : Int
  sprites : Map[CursorState, @sprite.Sprite]
  entity : @system.Entity
}

///|
pub let hide_time : Int = 15_000

///|
pub fn Cursor::new() -> Cursor {
  let sprites = {}
  sprites.set(
    CursorState::IDLE,
    @sprite.Sprite::from_animation(
      @sprite.Animation::single_frame(
        "assets/ui/cursor/idle.png",
        @math.Vec2D(24.0, 28.0),
      ),
      @ui.UI_ZINDEX,
    ),
  )
  sprites.set(
    CursorState::CAN_CLICK,
    @sprite.Sprite::from_animation(
      @sprite.Animation::new(
        @sprite.frames_from_atlas(
          "assets/ui/cursor/can_click.png",
          2,
          width=30,
          height=30,
        ),
        loop_=true,
      ),
      @ui.UI_ZINDEX,
    ),
  )
  let entity = @system.Entity::new()
  @sprite.sprites.set(entity, sprites.get(CursorState::IDLE).unwrap())
  @ui.uis.set(entity, @ui.Ui::new())
  { state: CursorState::IDLE, hide_counter: 0, sprites, entity }
}

///|
pub fn Cursor::update(self : Cursor) -> Unit {
  match self.state {
    CursorState::CAN_CLICK
    | CursorState::CAN_CLICK2
    | CursorState::CAN_GRAB
    | CursorState::CLICKING
    | CursorState::GRABBING => self.hide_counter = 0
    _ => self.hide_counter += 1
  }
  // let hide_after = hide_time / @config.step_time_ms
  // if self.hide_counter == hide_after {
  @sprite.sprites.remove(self.entity)
  // }
}

///|
pub fn Cursor::set_state(self : Cursor, state : CursorState) -> Unit {
  guard self.state != state else { return }
  self.state = state
  @sprite.sprites.set(self.entity, self.get_sprite())
  self.hide_counter = 0
}

///|
pub fn Cursor::set_position(self : Cursor, position : Point[Int]) -> Unit {
  @position.positions.set(
    self.entity,
    @math.Vec2D(position.x.to_double(), position.y.to_double()),
  )
  self.hide_counter = 0
}

///|
pub fn Cursor::get_state(self : Cursor) -> CursorState {
  self.state
}

///|
fn Cursor::get_sprite(self : Cursor) -> @sprite.Sprite {
  self.sprites.get(self.state).unwrap()
}
