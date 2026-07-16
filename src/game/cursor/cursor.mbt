///|
using @ui {type CursorState}

///|
const CURSOR_ZINDEX : Int = @graphics.CURSOR_ZINDEX

///|
pub(all) struct Cursor {
  mut state : CursorState
  mut inactive_seconds : Double
  mut state_seconds : Double
  mut last_mouse_pos : @math.Vec2
  entity : @entity.Entity
  animation_data : CursorAnimationData
}

///|
pub const HIDE_SECONDS : Int = 12

///|
/// 创建 cursor 实例。
///
/// # Example
/// ```moonbit nocheck
/// let data = try! CursorAnimationData::load(
///   "res://UI/Basic.img/Cursor/cursor_animation.json",
/// )
///
/// let cursor = Cursor(data)
/// ```
pub fn Cursor::Cursor(data : CursorAnimationData) -> Cursor {
  let entity = @entity.Entity()
  {
    state: CursorState::IDLE,
    inactive_seconds: 0.0,
    state_seconds: 0.0,
    last_mouse_pos: @math.Vec2(-9999999.0, -9999999.0),
    entity,
    animation_data: data,
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
fn cursor_state_tag(state : CursorState) -> String {
  match state {
    CursorState::IDLE => "idle"
    CursorState::CAN_CLICK => "can_click"
    CursorState::GAME => "game"
    CursorState::HOUSE => "house"
    CursorState::CAN_CLICK2 => "can_click2"
    CursorState::CAN_GRAB => "can_grab"
    CursorState::GIFT => "gift"
    CursorState::VSCROLL => "vscroll"
    CursorState::HSCROLL => "hscroll"
    CursorState::VSCROLL_IDLE => "vscroll_idle"
    CursorState::HSCROLL_IDLE => "hscroll_idle"
    CursorState::GRABBING => "grabbing"
    CursorState::CLICKING => "clicking"
    CursorState::RCLICK => "rclick"
    CursorState::LEAF => "leaf"
    CursorState::CHAT_BAR_VDRAG => "chat_bar_vdrag"
    CursorState::CHAT_BAR_HDRAG => "chat_bar_hdrag"
    CursorState::CHAT_BAR_BLTRDRAG => "chat_bar_bltrdrag"
    CursorState::CHAT_BAR_MOVE => "chat_bar_move"
    CursorState::CHAT_BAR_BRTLDRAG => "chat_bar_brtldrag"
  }
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
fn sync_cursor_ui(cursor : Cursor, mouse_pos : @math.Vec2) -> Unit raise {
  let tag = cursor_state_tag(cursor.state)
  let data = cursor.animation_data
  let frame = match data.current_frame(tag, cursor.state_seconds) {
    Some(f) => f
    None => fail("cursor animation tag not found: " + tag)
  }

  let size = frame.rect.size
  let position = mouse_pos + @math.Vec2(-frame.anchor.0, -frame.anchor.1)
  @selene_ui.nodes().set(
    cursor.entity,
    @selene_ui.Node::absolute(position, size~),
  )
  @selene_ui.z_indexes().set(cursor.entity, @selene_ui.ZIndex(CURSOR_ZINDEX))
  @selene_ui.ui_images().set(
    cursor.entity,
    @selene_ui.UiImage::from_image(
      size,
      data.atlas_image,
      source=Some({ position: frame.rect.position, size }),
    ),
  )
}

///|
let cursor : Ref[Cursor?] = Ref(None)

///|
/// 初始化 cursor，在 app resource preload 完成后调用。
///
/// # Example
/// ```moonbit nocheck
/// let data = try! CursorAnimationData::load("res://UI/Basic.img/Cursor/cursor_animation.json")
/// init_cursor(Cursor(data))
/// ```
pub fn init_cursor(c : Cursor) -> Unit {
  cursor.val = Some(c)
}

///|
pub fn cursor_system(_world : @ecs.World) -> Unit {
  let c = match cursor.val {
    Some(c) => c
    None => return
  }
  let delta = @time.delta()
  if !c.entity.is_alive() {
    c.entity.respawn()
    c.state_seconds = 0.0
    c.inactive_seconds = 0.0
    c.last_mouse_pos = @math.Vec2(-9999999.0, -9999999.0)
  }
  let mouse_pos = @inputs.mouse.pos
  if mouse_pos != c.last_mouse_pos {
    c.last_mouse_pos = mouse_pos
    c.inactive_seconds = 0.0
  }
  c.set_state(resolve_cursor_state())
  c.state_seconds += @cmp.maximum(0.0, delta)
  match c.state {
    CursorState::CAN_CLICK
    | CursorState::CAN_CLICK2
    | CursorState::CAN_GRAB
    | CursorState::CLICKING
    | CursorState::GRABBING => c.inactive_seconds = 0.0
    _ => c.inactive_seconds += delta
  }
  if c.inactive_seconds >= HIDE_SECONDS.to_double() {
    hide_cursor_entity(c.entity)
  } else {
    sync_cursor_ui(c, mouse_pos) catch {
      err =>
        abort(
          "cursor_system failed: state=\{cursor_state_tag(c.state)}, error=\{err}",
        )
    }
  }
}
