struct Text {
  font : FontId
  alignment : TextAlignment
  color : ColorName
  mut image : @graphics.Image?
  mut text : String
  max_width : Int
  formatted : Bool
  line_adj : Int
}

pub fn Text::new(
  font : FontId,
  alignment : TextAlignment,
  color : ColorName,
  ~text : String = "",
  ~max_width : Int = 0,
  ~formatted : Bool = true,
  ~line_adj : Int = 0
) -> Text {
  { font, alignment, color, image: None, text, max_width, formatted, line_adj }
}

pub fn Text::default() -> Text {
  Text::new(FontId::A11M, TextAlignment::LEFT, ColorName::BLACK)
}

pub enum TextAlignment {
  LEFT
  CENTER
  RIGHT
}

pub fn draw(
  self : Text,
  point : Point[Int],
  ~text_y_clip : Range[Int]? = None
) -> Unit {
  let image = self.get_or_calc_image()
  GraphicsGL::get().draw_text(image, self.text, point, ~text_y_clip)
}

pub fn change_text(self : Text, text : String) -> Unit {
  if self.text == text {
    return
  }
  self.text = text
  self.image = None
}

pub fn dimensions(self : Text) -> Point[Int] {
  let image = self.get_or_calc_image()
  { x: image.width(), y: image.height() }
}

pub fn width(self : Text) -> Int {
  let image = self.get_or_calc_image()
  image.width()
}

pub fn height(self : Text) -> Int {
  let image = self.get_or_calc_image()
  image.height()
}

fn get_or_calc_image(self : Text) -> @graphics.Image {
  match self.image {
    Some(image) => image
    None => {
      let image = GraphicsGL::get().create_text_image(
        self.text,
        self.font,
        self.max_width,
      )
      self.image = Some(image)
      image
    }
  }
}
