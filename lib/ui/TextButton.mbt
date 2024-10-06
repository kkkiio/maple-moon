typealias Text = @graphics.Text

struct TextButton {
  base : ButtonModel
  text : Text
  option_number : Int
}

pub fn TextButton::new(text : Text, selection : Int) -> TextButton {
  {
    base: {
      state: ButtonState::NORMAL,
      active: true,
      position: Point::default(),
      pressed: false,
    },
    text,
    option_number: selection,
  }
}

pub fn get_button_base(self : TextButton) -> ButtonModel {
  self.base
}

pub fn draw(self : TextButton, parentpos : Point[Int]) -> Unit {
  if self.base.active {
    self.text.draw(parentpos)
  }
}

pub fn draw_in_range(
  self : TextButton,
  parentpos : Point[Int],
  range : @struct.Range[Int]
) -> Unit {
  if self.base.active {
    self.text.draw(parentpos, text_y_clip=range |> @option.some)
  }
}

pub fn update(self : TextButton) -> Unit {

}

pub fn bounds(
  self : TextButton,
  parentpos : Point[Int]
) -> @struct.Rectangle[Int] {
  let lt = parentpos + self.base.position
  let rb = lt + self.text.dimensions()
  @struct.Rectangle::new(lt, rb)
}

pub fn height(self : TextButton) -> Int {
  self.text.height()
}

pub fn width(self : TextButton) -> Int {
  self.text.width()
}

pub fn origin(self : TextButton) -> Point[Int] {
  self.base.position
}

pub fn get_option_number(self : TextButton) -> Int {
  self.option_number
}

pub fn send_cursor(
  self : TextButton,
  _b : Bool,
  _p : Point[Int]
) -> CursorState {
  CursorState::IDLE
}
