///|
typealias @ui.CursorState

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
pub const CURSOR_ZINDEX : Int = @selene_ui.UI_ZINDEX + 100

///|
pub fn Cursor::new() -> Cursor {
  let sprites = {}
  sprites.set(
    CursorState::IDLE,
    @sprite.Sprite::from_animation(
      @sprite.Animation::single_frame(
        "assets/ui/cursor/cursor_idle.png",
        @math.Vec2D(24.0, 28.0),
      ),
      CURSOR_ZINDEX,
    ),
  )
  sprites.set(
    CursorState::CAN_CLICK,
    @sprite.Sprite::from_animation(
      @sprite.Animation::new(
        @sprite.frames_from_atlas(
          "assets/ui/cursor/cursor_can_click.png",
          2,
          width=30,
          height=30,
        ),
        loop_=true,
      ),
      CURSOR_ZINDEX,
    ),
  )
  let entity = @system.Entity::new()
  @sprite.sprites.set(entity, sprites.get(CursorState::IDLE).unwrap())
  @selene_ui.uis.set(entity, @selene_ui.Ui::new())
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
  // @sprite.sprites.remove(self.entity)
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
pub fn Cursor::set_position(self : Cursor, position : @math.Vec2D) -> Unit {
  @position.positions.set(self.entity, position)
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

///|
let cursor : Cursor = Cursor::new()

///|
pub fn cursor_system(_backend : &@system.Backend) -> Unit {
  cursor.update()
  @position.positions.set(cursor.entity, @system.mouse.pos)
}
