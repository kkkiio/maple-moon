// class TextButton : public Button {
// public:
//     TextButton(Text text, int16_t selection);

//     void draw(Point<int16_t> position) const override;

//     void draw(Point<int16_t> position, Range<int16_t> range) const;

//     void update() override;

//     Rectangle<int16_t> bounds(Point<int16_t> parentpos) const override;

//     int16_t width() const override;

//     int16_t height() const;

//     Point<int16_t> origin() const override;

//     Cursor::State send_cursor(bool, Point<int16_t>) override {
//         return Cursor::State::IDLE;
//     }

//     int16_t get_option_number();
// private:
//     Text text_;
//     int16_t option_number_;
// };
struct TextButton {
  base : ButtonBase
  text : Text
  option_number : Int
}

// TextButton::TextButton(Text text,  int16_t selection) {
//     active_ = true;
//     state_ = Button::State::NORMAL;
//     text_ = std::move(text);
//     option_number_ = selection;
// }
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

pub fn get_button_base(self : TextButton) -> ButtonBase {
  self.base
}

// void TextButton::draw(Point<int16_t> parentpos) const {
//     if (active_) {
//         text_.draw(parentpos);
//     }
// }
pub fn draw(self : TextButton, parentpos : Point[Int]) -> Unit {
  if self.base.active {
    self.text.draw(parentpos)
  }
}

// void TextButton::draw(Point<int16_t> parentpos, Range<int16_t> range) const {
//     if (active_) {
//         text_.draw(parentpos, range);
//     }
// }
pub fn draw_in_range(
  self : TextButton,
  parentpos : Point[Int],
  range : Range[Int]
) -> Unit {
  if self.base.active {
    self.text.draw(parentpos, text_y_clip=range |> @option.some)
  }
}

pub fn update(self : TextButton) -> Unit {

}

pub fn bounds(self : TextButton, parentpos : Point[Int]) -> Rectangle[Int] {
  let lt = parentpos + self.base.position
  let rb = lt + self.text.dimensions()
  Rectangle::new(lt, rb)
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

pub fn in_combobox(self : TextButton, _p : Point[Int]) -> Bool {
  false
}

pub fn send_cursor(
  self : TextButton,
  _b : Bool,
  _p : Point[Int]
) -> CursorState {
  CursorState::IDLE
}
