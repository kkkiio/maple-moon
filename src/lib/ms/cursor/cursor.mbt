///|
using @ui {type CursorState}

///|
const CURSOR_ZINDEX : Int = @graphics.CURSOR_ZINDEX

///|
const CAN_CLICK_FRAME_WIDTH : Double = 30.0

///|
const CAN_CLICK_FRAME_HEIGHT : Double = 30.0

///|
const CAN_CLICK_FRAME_COUNT : Int = 2

///|
const CAN_CLICK_FRAME_SECONDS : Double = 0.15

///|
pub(all) struct Cursor {
  mut state : CursorState
  mut inactive_seconds : Double
  mut state_seconds : Double
  mut last_mouse_pos : @math.Vec2
  entity : @entity.Entity
}

///|
pub const HIDE_SECONDS : Int = 12

///|
pub fn Cursor::new() -> Cursor {
  let entity = @entity.Entity()
  {
    state: CursorState::IDLE,
    inactive_seconds: 0.0,
    state_seconds: 0.0,
    last_mouse_pos: @math.Vec2(-9999999.0, -9999999.0),
    entity,
  }
}

///|
pub fn Cursor::set_state(self : Cursor, state : CursorState) -> Unit {
  guard self.state != state else { return }
  self.state = state
  self.inactive_seconds = 0.0
  self.state_seconds = 0.0
}

///|
fn ui_hovered_clickable() -> Bool {
  match @selene_ui.hovered_entity() {
    Some(entity) =>
      match @selene_ui.buttons().get(entity) {
        Some(button) => button.enabled
        None => false
      }
    None => false
  }
}

///|
fn world_pickable_hovered() -> Bool {
  for entity, _ in @physics2d.pickables() {
    if @collision.is_hover(entity) {
      return true
    }
  }
  false
}

///|
fn resolve_cursor_state() -> CursorState {
  if @inputs.is_mouse_pressed(@inputs.MouseButton::Left) {
    CursorState::CLICKING
  } else if ui_hovered_clickable() || world_pickable_hovered() {
    CursorState::CAN_CLICK
  } else {
    CursorState::IDLE
  }
}

///|
fn hide_cursor_entity(entity : @entity.Entity) -> Unit {
  @selene_ui.nodes().remove(entity)
  @selene_ui.z_indexes().remove(entity)
  @selene_ui.ui_images().remove(entity)
}

///|
fn cursor_texture_path(state : CursorState) -> String {
  match state {
    CursorState::CAN_CLICK => "assets/ui/cursor/cursor_can_click.png"
    CursorState::CLICKING => "assets/ui/cursor/cursor_clicking.png"
    _ => "assets/ui/cursor/cursor_idle.png"
  }
}

///|
fn cursor_size(state : CursorState) -> @math.Vec2 {
  match state {
    CursorState::CAN_CLICK =>
      @math.Vec2(CAN_CLICK_FRAME_WIDTH, CAN_CLICK_FRAME_HEIGHT)
    _ => @math.Vec2(24.0, 28.0)
  }
}

///|
fn cursor_offset(state : CursorState) -> @math.Vec2 {
  match state {
    CursorState::CAN_CLICK => @math.Vec2(-4.0, -6.0)
    CursorState::IDLE => @math.Vec2(0.0, -3.0)
    _ => @math.Vec2::zero()
  }
}

///|
fn cursor_frame_index(cursor : Cursor) -> Int {
  if cursor.state != CursorState::CAN_CLICK {
    return 0
  }
  let frame = (cursor.state_seconds / CAN_CLICK_FRAME_SECONDS).to_int()
  frame % CAN_CLICK_FRAME_COUNT
}

///|
fn sync_cursor_ui(cursor : Cursor, mouse_pos : @math.Vec2) -> Unit {
  let size = cursor_size(cursor.state)
  let position = mouse_pos + cursor_offset(cursor.state)
  @selene_ui.nodes().set(
    cursor.entity,
    @selene_ui.Node::absolute(position, size~),
  )
  @selene_ui.z_indexes().set(cursor.entity, @selene_ui.ZIndex(CURSOR_ZINDEX))
  let frame = cursor_frame_index(cursor)
  let frame_pos_x = if cursor.state == CursorState::CAN_CLICK {
    frame.to_double() * CAN_CLICK_FRAME_WIDTH
  } else {
    0.0
  }
  @selene_ui.ui_images().set(
    cursor.entity,
    @selene_ui.UiImage::from_image(
      size,
      @resource.load_image(cursor_texture_path(cursor.state)),
      source=Some({ position: @math.Vec2(frame_pos_x, 0.0), size }),
    ),
  )
}

///|
let cursor : Cursor = Cursor::new()

///|
pub fn cursor_system(_world : @ecs.World) -> Unit {
  let delta = @time.delta()
  if !cursor.entity.is_alive() {
    cursor.entity.respawn()
    cursor.state_seconds = 0.0
    cursor.inactive_seconds = 0.0
    cursor.last_mouse_pos = @math.Vec2(-9999999.0, -9999999.0)
  }
  let mouse_pos = @inputs.mouse.pos
  if mouse_pos != cursor.last_mouse_pos {
    cursor.last_mouse_pos = mouse_pos
    cursor.inactive_seconds = 0.0
  }
  cursor.set_state(resolve_cursor_state())
  cursor.state_seconds += @cmp.maximum(0.0, delta)
  match cursor.state {
    CursorState::CAN_CLICK
    | CursorState::CAN_CLICK2
    | CursorState::CAN_GRAB
    | CursorState::CLICKING
    | CursorState::GRABBING => cursor.inactive_seconds = 0.0
    _ => cursor.inactive_seconds += delta
  }
  if cursor.inactive_seconds >= HIDE_SECONDS.to_double() {
    hide_cursor_entity(cursor.entity)
  } else {
    sync_cursor_ui(cursor, mouse_pos)
  }
}
