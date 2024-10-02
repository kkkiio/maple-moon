pub enum GaugeType {
  GAME
  CASHSHOP
}

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

pub fn draw(self : Gauge, args : @graphics.DrawArgument) -> Unit {
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
        let pos_adj = Point::new(45, 1)
        self.bar_front.draw(args.add_pos(-pos_adj))
        self.bar_mid.draw(
          args +
          @graphics.DrawArgument::new4(Point::new(0, 0), Point::new(length, 0)),
        )
        self.bar_end.draw(
          args.add_pos(
            -pos_adj + Point::new(length + self.bar_front.width(), 0),
          ),
        )
      }
    }
  }
}

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
