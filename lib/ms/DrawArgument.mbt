// app/src/main/cpp/src/Graphics/DrawArgument.h
// #pragma once

// #include "../Template/Rectangle.h"
// #include "Color.h"

// namespace ms {
// class DrawArgument {
// public:
//     constexpr DrawArgument() : DrawArgument(0, 0) {}

//     constexpr DrawArgument(int16_t x, int16_t y) :
//         DrawArgument(Point<int16_t>(x, y)) {}

//     constexpr DrawArgument(Point<int16_t> position) :
//         DrawArgument(position, 1.0f) {}

//     constexpr DrawArgument(Point<int16_t> position,
//                            float xscale,
//                            float yscale) :
//         DrawArgument(position, position, xscale, yscale, 1.0f) {}

//     constexpr DrawArgument(Point<int16_t> position, Point<int16_t> stretch) :
//         DrawArgument(position, position, stretch, 1.0f, 1.0f, 1.0f, 0.0f) {}

//     constexpr DrawArgument(Point<int16_t> position, bool flip) :
//         DrawArgument(position, flip, 1.0f) {}

//     constexpr DrawArgument(float angle,
//                            Point<int16_t> position,
//                            float opacity) :
//         DrawArgument(angle, position, false, opacity) {}

//     constexpr DrawArgument(Point<int16_t> position, float opacity) :
//         DrawArgument(position, false, opacity) {}

//     constexpr DrawArgument(Point<int16_t> position, Color color) :
//         DrawArgument(position,
//                      position,
//                      Point<int16_t>(0, 0),
//                      1.0f,
//                      1.0f,
//                      color,
//                      0.0f) {}

//     constexpr DrawArgument(Point<int16_t> position,
//                            bool flip,
//                            Point<int16_t> center) :
//         DrawArgument(position, center, flip ? -1.0f : 1.0f, 1.0f, 1.0f) {}

//     constexpr DrawArgument(Point<int16_t> position,
//                            Point<int16_t> center,
//                            float xscale,
//                            float yscale,
//                            float opacity) :
//         DrawArgument(position,
//                      center,
//                      Point<int16_t>(0, 0),
//                      xscale,
//                      yscale,
//                      opacity,
//                      0.0f) {}

//     constexpr DrawArgument(bool flip) :
//         DrawArgument(flip ? -1.0f : 1.0f, 1.0f, 1.0f) {}

//     constexpr DrawArgument(float xscale, float yscale, float opacity) :
//         DrawArgument(Point<int16_t>(0, 0), xscale, yscale, opacity) {}

//     constexpr DrawArgument(Point<int16_t> position,
//                            float xscale,
//                            float yscale,
//                            float opacity) :
//         DrawArgument(position, position, xscale, yscale, opacity) {}

//     constexpr DrawArgument(Point<int16_t> position, bool flip, float opacity) :
//         DrawArgument(position, position, flip ? -1.0f : 1.0f, 1.0f, opacity) {}

//     constexpr DrawArgument(float angle,
//                            Point<int16_t> position,
//                            bool flip,
//                            float opacity) :
//         DrawArgument(position,
//                      position,
//                      Point<int16_t>(0, 0),
//                      flip ? -1.0f : 1.0f,
//                      1.0f,
//                      opacity,
//                      angle) {}

//     constexpr DrawArgument(Point<int16_t> position,
//                            Point<int16_t> center,
//                            Point<int16_t> stretch,
//                            float xscale,
//                            float yscale,
//                            float opacity,
//                            float angle) :
//         pos_(position),
//         center_(center),
//         stretch_(stretch),
//         xscale_(xscale),
//         yscale_(yscale),
//         angle_(angle),
//         color_(1.0f, 1.0f, 1.0f, opacity) {}

//     constexpr DrawArgument(Point<int16_t> position,
//                            Point<int16_t> center,
//                            Point<int16_t> stretch,
//                            float xscale,
//                            float yscale,
//                            Color color,
//                            float angle) :
//         pos_(position),
//         center_(center),
//         stretch_(stretch),
//         xscale_(xscale),
//         yscale_(yscale),
//         angle_(angle),
//         color_(color) {}

//     constexpr Point<int16_t> get_pos() const { return pos_; }

//     constexpr int16_t get_radius() const { return radius_; }

//     constexpr Point<int16_t> get_stretch() const { return stretch_; }

//     constexpr float get_xscale() const { return xscale_; }

//     constexpr float get_yscale() const { return yscale_; }

//     constexpr const Color &get_color() const { return color_; }

//     constexpr float get_angle() const { return angle_; }

//     constexpr DrawArgument operator+(Point<int16_t> argpos) const {
//         return { pos_ + argpos, center_ + argpos, stretch_, xscale_,
//                  yscale_,       color_,           angle_ };
//     }

//     constexpr DrawArgument operator+(float argopc) const {
//         return { pos_,    center_, stretch_,
//                  xscale_, yscale_, color_.a() * argopc,
//                  angle_ };
//     }

//     constexpr DrawArgument operator+(const DrawArgument &o) const {
//         return { pos_ + o.pos_,         center_ + o.center_,
//                  stretch_ + o.stretch_, xscale_ * o.xscale_,
//                  yscale_ * o.yscale_,   color_ * o.color_,
//                  angle_ + o.angle_ };
//     }

//     constexpr DrawArgument operator-(const DrawArgument &o) const {
//         return { pos_ - o.pos_,         center_ - o.center_,
//                  stretch_ - o.stretch_, xscale_ / o.xscale_,
//                  yscale_ / o.yscale_,   color_ / o.color_,
//                  angle_ - o.angle_ };
//     }

//     Rectangle<int16_t> get_rectangle(Point<int16_t> origin,
//                                      Point<int16_t> dimensions) const {
//         int16_t w = stretch_.x();

//         if (w == 0) {
//             w = dimensions.x();
//         }

//         int16_t h = stretch_.y();

//         if (h == 0) {
//             h = dimensions.y();
//         }

//         Point<int16_t> rlt = pos_ - center_ - origin;
//         int16_t rl = rlt.x();
//         int16_t rr = rlt.x() + w;
//         int16_t rt = rlt.y();
//         int16_t rb = rlt.y() + h;
//         int16_t cx = center_.x();
//         int16_t cy = center_.y();

//         return { static_cast<int16_t>(cx + static_cast<int16_t>(xscale_ * rl)),
//                  static_cast<int16_t>(cx + static_cast<int16_t>(xscale_ * rr)),
//                  static_cast<int16_t>(cy + static_cast<int16_t>(yscale_ * rt)),
//                  static_cast<int16_t>(cy + static_cast<int16_t>(yscale_ * rb)) };
//     }

// private:
//     Point<int16_t> pos_;
//     Point<int16_t> center_;
//     Point<int16_t> stretch_;
//     float xscale_;
//     float yscale_;
//     float angle_;
//     int16_t radius_;
//     Color color_;
// };
// }  // namespace ms

struct DrawArgument {
  pos : Point[Int]
  center : Point[Int]
  stretch : Point[Int]
  xscale : Double
  yscale : Double
  angle : Double
  radius : Int
  color : Color
}

pub fn DrawArgument::new0() -> DrawArgument {
  DrawArgument::new1(0, 0)
}

pub fn DrawArgument::new1(x : Int, y : Int) -> DrawArgument {
  DrawArgument::new2({ x, y })
}

pub fn DrawArgument::new2(position : Point[Int]) -> DrawArgument {
  DrawArgument::new7(position, 1.0)
}

pub fn DrawArgument::new3(
  position : Point[Int],
  xscale : Double,
  yscale : Double
) -> DrawArgument {
  DrawArgument::new10(position, position, xscale, yscale, 1.0)
}

pub fn DrawArgument::new4(
  position : Point[Int],
  stretch : Point[Int]
) -> DrawArgument {
  DrawArgument::new16(position, position, stretch, 1.0, 1.0, 1.0, 0.0)
}

pub fn DrawArgument::new5(position : Point[Int], flip : Bool) -> DrawArgument {
  DrawArgument::new14(position, flip, 1.0)
}

pub fn DrawArgument::new6(
  angle : Double,
  position : Point[Int],
  opacity : Double
) -> DrawArgument {
  DrawArgument::new15(angle, position, false, opacity)
}

pub fn DrawArgument::new7(
  position : Point[Int],
  opacity : Double
) -> DrawArgument {
  DrawArgument::new14(position, false, opacity)
}

pub fn DrawArgument::new8(position : Point[Int], color : Color) -> DrawArgument {
  DrawArgument::new17(position, position, { x: 0, y: 0 }, 1.0, 1.0, color, 0.0)
}

pub fn DrawArgument::new9(
  position : Point[Int],
  flip : Bool,
  center : Point[Int]
) -> DrawArgument {
  DrawArgument::new10(position, center, if flip { -1.0 } else { 1.0 }, 1.0, 1.0)
}

pub fn DrawArgument::new10(
  position : Point[Int],
  center : Point[Int],
  xscale : Double,
  yscale : Double,
  opacity : Double
) -> DrawArgument {
  DrawArgument::new16(
    position,
    center,
    { x: 0, y: 0 },
    xscale,
    yscale,
    opacity,
    0.0,
  )
}

pub fn DrawArgument::new11(flip : Bool) -> DrawArgument {
  DrawArgument::new12(if flip { -1.0 } else { 1.0 }, 1.0, 1.0)
}

pub fn DrawArgument::new12(
  xscale : Double,
  yscale : Double,
  opacity : Double
) -> DrawArgument {
  DrawArgument::new13({ x: 0, y: 0 }, xscale, yscale, opacity)
}

pub fn DrawArgument::new13(
  position : Point[Int],
  xscale : Double,
  yscale : Double,
  opacity : Double
) -> DrawArgument {
  DrawArgument::new10(position, position, xscale, yscale, opacity)
}

pub fn DrawArgument::new14(
  position : Point[Int],
  flip : Bool,
  opacity : Double
) -> DrawArgument {
  DrawArgument::new10(
    position,
    position,
    if flip {
      -1.0
    } else {
      1.0
    },
    1.0,
    opacity,
  )
}

pub fn DrawArgument::new15(
  angle : Double,
  position : Point[Int],
  flip : Bool,
  opacity : Double
) -> DrawArgument {
  DrawArgument::new16(
    position,
    position,
    { x: 0, y: 0 },
    if flip {
      -1.0
    } else {
      1.0
    },
    1.0,
    opacity,
    angle,
  )
}

pub fn DrawArgument::new16(
  position : Point[Int],
  center : Point[Int],
  stretch : Point[Int],
  xscale : Double,
  yscale : Double,
  opacity : Double,
  angle : Double
) -> DrawArgument {
  DrawArgument::new17(
    position,
    center,
    stretch,
    xscale,
    yscale,
    new_rgba(1.0, 1.0, 1.0, opacity),
    angle,
  )
}

pub fn DrawArgument::new17(
  position : Point[Int],
  center : Point[Int],
  stretch : Point[Int],
  xscale : Double,
  yscale : Double,
  color : Color,
  angle : Double
) -> DrawArgument {
  { pos: position, center, stretch, xscale, yscale, angle, color, radius: 0 } // Assuming default value
}

pub fn add_pos(self : DrawArgument, argpos : Point[Int]) -> DrawArgument {
  DrawArgument::new17(
    self.pos + argpos,
    self.center + argpos,
    self.stretch,
    self.xscale,
    self.yscale,
    self.color,
    self.angle,
  )
}

pub fn add_opacity(self : DrawArgument, argopc : Double) -> DrawArgument {
  DrawArgument::new16(
    self.pos,
    self.center,
    self.stretch,
    self.xscale,
    self.yscale,
    self.color.a() * argopc,
    self.angle,
  )
}

pub fn op_add(self : DrawArgument, o : DrawArgument) -> DrawArgument {
  DrawArgument::new17(
    self.pos + o.pos,
    self.center + o.center,
    self.stretch + o.stretch,
    self.xscale * o.xscale,
    self.yscale * o.yscale,
    self.color * o.color,
    self.angle + o.angle,
  )
}

pub fn op_sub(self : DrawArgument, o : DrawArgument) -> DrawArgument {
  DrawArgument::new17(
    self.pos - o.pos,
    self.center - o.center,
    self.stretch - o.stretch,
    self.xscale / o.xscale,
    self.yscale / o.yscale,
    self.color / o.color,
    self.angle - o.angle,
  )
}

pub fn get_rectangle(
  self : DrawArgument,
  origin : Point[Int],
  dimensions : Point[Int]
) -> Rectangle[Int] {
  let mut w = self.stretch.x
  if w == 0 {
    w = dimensions.x
  }
  let mut h = self.stretch.y
  if h == 0 {
    h = dimensions.y
  }
  let rlt = self.pos - self.center - origin
  let rl = rlt.x
  let rr = rlt.x + w
  let rt = rlt.y
  let rb = rlt.y + h
  let cx = self.center.x
  let cy = self.center.y
  Rectangle::from4(
    cx + (self.xscale * rl.to_double()).to_int(),
    cx + (self.xscale * rr.to_double()).to_int(),
    cy + (self.yscale * rt.to_double()).to_int(),
    cy + (self.yscale * rb.to_double()).to_int(),
  )
}
