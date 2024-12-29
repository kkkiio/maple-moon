///|
pub(all) enum ButtonState {
  NORMAL
  DISABLED
  MOUSEOVER
  PRESSED
} derive(Eq, Hash)

///|
pub(open) trait UIButton {
  draw(Self, Point[Int]) -> Unit
  update(Self) -> Unit
  bounds(Self) -> @struct.Rectangle[Int]
  width(Self) -> Int
  origin(Self) -> Point[Int]
  // send_cursor(Self, Bool, Point[Int]) -> CursorState
  get_button_base(Self) -> ButtonModel
  // set_position(Self, Point[Int]) -> Unit
  // toggle_pressed(Self) -> Unit
  // is_pressed(Self) -> Bool
}

///|
pub(all) struct Button {
  object : UIButton
  on_click : (() -> ButtonState?)?
}

///|
pub fn Button::new(object : UIButton, on_click? : () -> ButtonState?) -> Button {
  { object, on_click }
}

///|
pub impl Drawable for Button with draw(self, pos) -> Unit {
  self.object.draw(pos)
}

///|
pub impl RenderUnit for Button with update(self) -> Unit {
  self.object.update()
}

///|
pub impl RenderUnit for Button with get_interactive_area(self) -> InteractiveArea? {
  self.on_click.map(fn(on_click) {
    {
      bounds: self.object.bounds(),
      state: self.object.get_button_base().state,
      on_click: fn() {
        match on_click() {
          Some(s) => self.object.get_button_base().set_state(s)
          None => ()
        }
      },
    }
  })
}

///|
pub impl ToJson for Button with to_json(self) -> Json {
  {} // TODO
}

///|
struct ButtonModel {
  state : Ref[ButtonState]
  mut position : Point[Int]
  mut active : Bool
  mut pressed : Bool
}

///|
pub fn ButtonModel::default() -> ButtonModel {
  {
    state: Ref::new(ButtonState::NORMAL),
    position: @struct.Point::default(),
    active: true,
    pressed: false,
  }
}

///|
pub fn set_position(self : ButtonModel, pos : Point[Int]) -> Unit {
  self.position = pos
}

///|
pub fn set_state(self : ButtonModel, s : ButtonState) -> Unit {
  self.state.val = s
}

///|
pub fn set_active(self : ButtonModel, a : Bool) -> Unit {
  self.active = a
}

///|
pub fn toggle_pressed(self : ButtonModel) -> Unit {
  self.pressed = self.pressed.not()
}

///|
pub fn is_active(self : ButtonModel) -> Bool {
  self.active && self.get_state() != ButtonState::DISABLED
}

///|
pub fn get_state(self : ButtonModel) -> ButtonState {
  self.state.val
}

///|
pub fn is_pressed(self : ButtonModel) -> Bool {
  self.pressed
}
