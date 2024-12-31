///|
pub(all) enum GaugeType {
  GAME
  CASHSHOP
} derive(Show)

///|
pub impl ToJson for GaugeType with to_json(self) { self.to_string().to_json() }

///|
struct Gauge {
  t : GaugeType
  bar_front : @graphics.Texture
  bar_mid : @graphics.Texture
  bar_end : @graphics.Texture
  maximum : Int
  mut percentage : Double
  mut target : Double
  mut step : Double
}

///|
pub fn Gauge::new(
  t : GaugeType,
  front : @graphics.Texture,
  max : Int,
  percent : Double
) -> Gauge {
  {
    t,
    bar_front: front,
    bar_mid: @graphics.Texture::default(),
    bar_end: @graphics.Texture::default(),
    maximum: max,
    percentage: percent,
    target: percent,
    step: 0.0,
  }
}

///|
pub fn Gauge::new_with_mid(
  t : GaugeType,
  front : @graphics.Texture,
  mid : @graphics.Texture,
  max : Int,
  percent : Double
) -> Gauge {
  {
    t,
    bar_front: front,
    bar_mid: mid,
    bar_end: @graphics.Texture::default(),
    maximum: max,
    percentage: percent,
    target: percent,
    step: 0.0,
  }
}

///|
pub fn Gauge::new_with_mid_end(
  t : GaugeType,
  front : @graphics.Texture,
  mid : @graphics.Texture,
  end : @graphics.Texture,
  max : Int,
  percent : Double
) -> Gauge {
  {
    t,
    bar_front: front,
    bar_mid: mid,
    bar_end: end,
    maximum: max,
    percentage: percent,
    target: percent,
    step: 0.0,
  }
}

///|
pub impl @graphics.Drawable for Gauge with draw(
  self : Gauge,
  args : @graphics.DrawArgument
) -> Unit {
  let position = args.pos
  let length = (self.percentage * self.maximum.to_double()).to_int()
  if length > 0 {
    match self.t {
      GaugeType::GAME => {
        self.bar_front.draw(
          args +
          @graphics.DrawArgument::new4(
            @struct.Point::new(0, 0),
            @struct.Point::new(length, 0),
          ),
        )
        self.bar_mid.draw(args)
        self.bar_end.draw(args.add_pos(Point::new(length + 8, 20)))
      }
      GaugeType::CASHSHOP => {
        let pos_adj = @struct.Point::new(45, 1)
        self.bar_front.draw(args.add_pos(-pos_adj))
        self.bar_mid.draw(
          args +
          @graphics.DrawArgument::new4(
            Point::new(0, 0),
            @struct.Point::new(length, 0),
          ),
        )
        self.bar_end.draw(
          args.add_pos(
            -pos_adj + @struct.Point::new(length + self.bar_front.width(), 0),
          ),
        )
      }
    }
  }
}

///|
pub impl ToJson for Gauge with to_json(self) -> Json {
  {
    "t": self.t.to_json(),
    "maximum": self.maximum.to_json(),
    "percentage": self.percentage.to_json(),
    "target": self.target.to_json(),
    "step": self.step.to_json(),
  }
}

///|
pub impl RenderUnit for Gauge with update(self) -> Unit {
  ignore(self)
  ()
}

///|
pub impl RenderUnit for Gauge with get_interactive_area(self) {
  ignore(self)
  None
}

///|
pub fn update(self : Gauge, t : Double) -> Unit {
  if self.target != t {
    self.target = t
    self.step = (self.target - self.percentage) / 24.0
  }
  if self.percentage != self.target {
    self.percentage += self.step
    if self.step < 0.0 {
      if self.target - self.percentage >= self.step {
        self.percentage = self.target
      }
    } else if self.step > 0.0 {
      if self.target - self.percentage <= self.step {
        self.percentage = self.target
      }
    }
  }
}
