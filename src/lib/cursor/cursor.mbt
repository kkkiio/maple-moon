///|
using @ui {type CursorState}

///|
using @graphics {CURSOR_ZINDEX}

///|
pub(all) struct Cursor {
  mut state : CursorState
  mut inactive_seconds : Double
  sprites : Map[CursorState, @sprite.Sprite]
  entity : @entity.Entity
}

///|
pub const HIDE_SECONDS : Int = 12

///|
pub fn Cursor::new() -> Cursor {
  let sprites = {}
  sprites.set(
    CursorState::IDLE,
    @sprite.Sprite::from_animation(
      @sprite.Animation::single_frame(
        "/assets/ui/cursor/cursor_idle.png",
        @math.Vec2D(24.0, 28.0),
      ),
      CURSOR_ZINDEX,
      offset=-@math.Vec2D(0, 3),
    ),
  )
  sprites.set(
    CursorState::CAN_CLICK,
    @sprite.Sprite::from_animation(
      @sprite.Animation::new(
        @sprite.frames_from_atlas(
          "/assets/ui/cursor/cursor_can_click.png",
          2,
          width=30,
          height=30,
        ),
        loop_=true,
      ),
      CURSOR_ZINDEX,
      offset=-@math.Vec2D(4, 6),
    ),
  )
  sprites.set(
    CursorState::CLICKING,
    @sprite.Sprite::from_animation(
      @sprite.Animation::single_frame(
        "/assets/ui/cursor/cursor_clicking.png",
        @math.Vec2D(24.0, 28.0),
      ),
      CURSOR_ZINDEX,
    ),
  )
  let entity = @entity.Entity::new()
  @sprite.sprites.set(entity, sprites.get(CursorState::IDLE).unwrap())
  @selene_ui.uis.set(entity, @selene_ui.Ui::new())
  { state: CursorState::IDLE, inactive_seconds: 0, sprites, entity }
}

///|
pub fn Cursor::set_state(self : Cursor, state : CursorState) -> Unit {
  guard self.state != state else { return }
  self.state = state
  self.inactive_seconds = 0.0
}

///|
pub fn Cursor::set_position(self : Cursor, position : @math.Vec2D) -> Unit {
  if @position.positions.get(self.entity) is Some(old_position) &&
    old_position.0 == position {
    return
  }
  @position.positions.set(self.entity, position)
  self.inactive_seconds = 0.0
}

///|
fn Cursor::get_sprite(self : Cursor) -> @sprite.Sprite {
  self.sprites.get(self.state).unwrap()
}

///|
let cursor : Cursor = Cursor::new()

///|
pub fn cursor_system(delta : Double) -> Unit {
  // sync pos and state
  cursor.set_position(@inputs.mouse.pos)
  if @inputs.is_mouse_pressed(@inputs.MouseButton::Left) {
    cursor.set_state(CursorState::CLICKING)
  } else {
    cursor.set_state(CursorState::IDLE)
  }
  if cursor.inactive_seconds == 0.0 { // reset
    @sprite.sprites.set(cursor.entity, cursor.get_sprite())
  }
  match cursor.state {
    CursorState::CAN_CLICK
    | CursorState::CAN_CLICK2
    | CursorState::CAN_GRAB
    | CursorState::CLICKING
    | CursorState::GRABBING => cursor.inactive_seconds = 0.0
    _ => cursor.inactive_seconds += delta
  }
  if cursor.inactive_seconds >= HIDE_SECONDS.to_double() {
    @sprite.sprites.remove(cursor.entity)
  }
}
