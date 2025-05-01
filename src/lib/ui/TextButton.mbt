///|
typealias Text = @graphics.Text

///|
struct TextButton {
  base : ButtonModel
  text : Text
  option_number : Int
}

///|
pub fn TextButton::new(text : Text, selection : Int) -> TextButton {
  { base: ButtonModel::new(), text, option_number: selection }
}

///|
pub fn TextButton::get_button_base(self : TextButton) -> ButtonModel {
  self.base
}

///|
pub fn TextButton::draw(self : TextButton, parentpos : Point[Int]) -> Unit {
  if self.base.active {
    self.text.draw(parentpos + self.base.position)
  }
}

///|
pub fn TextButton::draw_in_range(
  self : TextButton,
  parentpos : Point[Int],
  range : @struct.Range[Int]
) -> Unit {
  if self.base.active {
    self.text.draw(parentpos, text_y_clip=range |> @option.some)
  }
}

///|
pub fn TextButton::update(self : TextButton) -> Unit {

}

///|
pub fn TextButton::bounds(self : TextButton) -> @struct.Rectangle[Int] {
  let lt = self.base.position
  let rb = lt + self.text.dimensions()
  @struct.Rectangle::new(lt, rb)
}

///|
pub fn TextButton::height(self : TextButton) -> Int {
  self.text.height()
}

///|
pub fn TextButton::width(self : TextButton) -> Int {
  self.text.width()
}

///|
pub fn TextButton::origin(self : TextButton) -> Point[Int] {
  self.base.position
}

///|
pub fn TextButton::get_option_number(self : TextButton) -> Int {
  self.option_number
}
