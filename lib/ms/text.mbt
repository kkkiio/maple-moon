struct Text {
  font : FontId
  alignment : TextAlignment
  color : ColorName
  background : TextBackground
  mut layout : TextLayout?
  mut text : String
  max_width : Int
  formatted : Bool
  line_adj : Int
}

pub fn Text::new(
  font : FontId,
  alignment : TextAlignment,
  color : ColorName,
  ~background : TextBackground = TextBackground::NONE,
  ~text : String = "",
  ~max_width : Int = 0,
  ~formatted : Bool = true,
  ~line_adj : Int = 0
) -> Text {
  {
    font,
    alignment,
    color,
    background,
    layout: None,
    text,
    max_width,
    formatted,
    line_adj,
  }
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
  args : DrawArgument,
  ~vertical : Range[Int] = Range::new(0, 0)
) -> Unit {
  let layout = self.get_or_calc_layout()
  GraphicsGL::get().draw_text(
    args,
    vertical,
    layout,
    self.font,
    self.color,
    self.background,
  )
}

pub fn change_text(self : Text, text : String) -> Unit {
  if self.text == text {
    return
  }
  self.text = text
  self.layout = None
}

pub fn dimensions(self : Text) -> Point[Int] {
  let layout = self.get_or_calc_layout()
  layout.get_dimensions()
}

pub fn width(self : Text) -> Int {
  let layout = self.get_or_calc_layout()
  layout.width()
}

pub fn height(self : Text) -> Int {
  let layout = self.get_or_calc_layout()
  layout.height()
}

fn get_or_calc_layout(self : Text) -> TextLayout {
  match self.layout {
    Some(layout) => layout
    None => {
      let unicodes = self.text.iter().collect()
      let layout = GraphicsGL::get().create_layout(
        unicodes,
        self.font,
        self.alignment,
        self.max_width,
        self.formatted,
        self.line_adj,
      )
      self.layout = Some(layout)
      layout
    }
  }
}
