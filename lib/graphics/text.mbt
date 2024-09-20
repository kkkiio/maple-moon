struct Text {
  font : FontId
  alignment : TextAlignment
  color : @struct.ColorName
  text : String
  max_width : Int?
  mut image : @resource.Image?
}

pub fn Text::new(
  text : String,
  font : FontId,
  alignment : TextAlignment,
  color : @struct.ColorName,
  ~max_width? : Int
) -> Text {
  { font, alignment, color, image: None, text, max_width }
}

pub fn draw(
  self : Text,
  point : Point[Int],
  ~text_y_clip : Range[Int]? = None
) -> Unit {
  let image = self.get_or_init_image()
  let point = match self.alignment {
    TextAlignment::CENTER => {
      let width = image.width()
      let x = point.x - width / 2
      { ..point, x, }
    }
    _ => point
  }
  GraphicsGL::get().draw_text(image, self.text, point, ~text_y_clip)
}

pub fn dimensions(self : Text) -> Point[Int] {
  let image = self.get_or_init_image()
  { x: image.width(), y: image.height() }
}

pub fn width(self : Text) -> Int {
  let image = self.get_or_init_image()
  image.width()
}

pub fn height(self : Text) -> Int {
  let image = self.get_or_init_image()
  image.height()
}

fn get_or_init_image(self : Text) -> @resource.Image {
  match self.image {
    Some(image) => image
    None => {
      let image = GraphicsGL::get().create_text_image(
        {
          text: self.text,
          font_id: self.font,
          max_width: self.max_width,
          text_alignment: self.alignment,
          color: self.color |> Color::from_name |> @struct.IntColor::from_color,
        },
      )
      self.image = Some(image)
      image
    }
  }
}

pub fn change_text(self : Text, text : String) -> Text {
  if self.text == text {
    return self
  }
  { ..self, text, image: None }
}

pub fn change_color(self : Text, color : @struct.ColorName) -> Text {
  if self.color == color {
    return self
  }
  { ..self, color, image: None }
}
