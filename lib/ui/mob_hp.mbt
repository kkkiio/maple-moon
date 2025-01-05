struct MobHpBar {
  width : Int
  height : Int
}

pub fn MobHpBar::default() -> MobHpBar {
  { width: 50, height: 10 }
}

pub fn draw(
  self : MobHpBar,
  position : @struct.Point[Int],
  hppercent : Int
) -> Unit {
  let width = self.width
  let height = self.height
  let fillw = ((width - 6).to_double() * hppercent.to_double() / 100.0).to_int()
  let x = position.x - width / 2
  let y = position.y - height * 3
  draw_rectangle(x, y, width, height, @struct.ColorName::BLACK, 1.0)
  draw_rectangle(x + 1, y + 1, width - 2, 1, @struct.ColorName::WHITE, 1.0)
  draw_rectangle(
    x + 1,
    y + height - 2,
    width - 2,
    1,
    @struct.ColorName::WHITE,
    1.0,
  )
  draw_rectangle(x + 1, y + 2, 1, height - 4, @struct.ColorName::WHITE, 1.0)
  draw_rectangle(
    x + width - 2,
    y + 2,
    1,
    height - 4,
    @struct.ColorName::WHITE,
    1.0,
  )
  draw_rectangle(x + 3, y + 3, fillw, 3, @struct.ColorName::LIGHTGREEN, 1.0)
  draw_rectangle(x + 3, y + 6, fillw, 1, @struct.ColorName::JAPANESELAUREL, 1.0)
}

pub fn draw_rectangle(
  x : Int,
  y : Int,
  w : Int,
  h : Int,
  cid : @struct.ColorName,
  opacity : Double
) -> Unit {
  if w == 0 || h == 0 || opacity <= 0.0 {
    return
  }
  let color = @struct.Color::from_name(cid)
  @graphics.GraphicsGL::get().draw_rectangle(
    x,
    y,
    w,
    h,
    color.r(),
    color.g(),
    color.b(),
    opacity,
  )
}
