struct Text {
  font : @graphics.FontId
  alignment : @graphics.TextAlignment
  color : @struct.ColorName
  mut image : @resource.Image?
  mut text : String
  max_width : Int
  formatted : Bool
  line_adj : Int
}

pub fn Text::new(
  font : @graphics.FontId,
  alignment : @graphics.TextAlignment,
  color : @struct.ColorName,
  max_width : Int,
  ~text : String = "",
  ~formatted : Bool = true,
  ~line_adj : Int = 0
) -> Text {
  { font, alignment, color, image: None, text, max_width, formatted, line_adj }
}

pub fn draw(
  self : Text,
  point : Point[Int],
  ~text_y_clip : Range[Int]? = None
) -> Unit {
  let image = self.get_or_calc_image()
  @graphics.GraphicsGL::get().draw_text(image, self.text, point, ~text_y_clip)
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

fn get_or_calc_image(self : Text) -> @resource.Image {
  match self.image {
    Some(image) => image
    None => {
      let image = @graphics.GraphicsGL::get().create_text_image(
        self.text,
        self.font,
        self.max_width,
        self.alignment,
      )
      self.image = Some(image)
      image
    }
  }
}
