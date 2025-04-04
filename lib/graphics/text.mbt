///|
struct Text {
  font : FontId
  alignment : TextAlignment
  max_width : Int?
  nametag : Bool
  mut text : String
  mut color : @struct.ColorName
  mut image : Image?
}

///|
pub fn Text::new(
  font : FontId,
  alignment : TextAlignment,
  color : @struct.ColorName,
  text~ : String = "",
  nametag~ : Bool = false,
  max_width? : Int
) -> Text {
  { font, alignment, color, image: None, text, max_width, nametag }
}

///|
pub fn Text::draw(
  self : Text,
  point : Point[Int],
  text_y_clip~ : Range[Int]? = None
) -> Unit {
  let image = self.get_or_init_image()
  let point = match self.alignment {
    TextAlignment::LEFT => point
    TextAlignment::CENTER => {
      let width = image.width()
      let x = point.x - width / 2
      { ..point, x, }
    }
    TextAlignment::RIGHT => {
      let width = image.width()
      let x = point.x - width
      { ..point, x, }
    }
  }
  GraphicsGL::get().draw_text(
    image,
    self.text,
    point,
    self.nametag,
    text_y_clip~,
  )
}

///|
pub fn Text::dimensions(self : Text) -> Point[Int] {
  let image = self.get_or_init_image()
  { x: image.width(), y: image.height() }
}

///|
pub fn Text::width(self : Text) -> Int {
  let image = self.get_or_init_image()
  image.width()
}

///|
pub fn Text::height(self : Text) -> Int {
  let image = self.get_or_init_image()
  image.height()
}

///|
pub fn Text::get_text(self : Text) -> String {
  self.text
}

///|
pub fn Text::get_or_init_image(self : Text) -> Image {
  match self.image {
    Some(image) => image
    None => {
      let image = GraphicsGL::get().create_text_image({
        text: self.text,
        font_id: self.font,
        max_width: self.max_width,
        text_alignment: self.alignment,
        color: self.color |> Color::from_name |> @struct.IntColor::from_color,
      })
      self.image = Some(image)
      image
    }
  }
}

///|
pub fn Text::change_text(self : Text, text : String) -> Unit {
  if self.text == text {
    return
  }
  self.text = text
  self.image = None
}

///|
pub fn Text::change_color(self : Text, color : @struct.ColorName) -> Unit {
  if self.color == color {
    return
  }
  self.color = color
  self.image = None
}

///|
pub fn Text::with_text(self : Text, text : String) -> Text {
  if self.text == text {
    return self
  }
  { ..self, text, image: None }
}

///|
pub impl ToJson for Text with to_json(self) -> Json {
  {
    "nametag": self.nametag.to_json(),
    "text": self.text.to_json(),
    "color": self.color.to_json(),
  }
}
