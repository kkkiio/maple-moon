pub struct Point[T] {
  x : T
  y : T
} derive(Eq, Show)

pub fn Point::new[T](x : T, y : T) -> Point[T] {
  { x, y }
}

pub fn Point::default[T : Default]() -> Point[T] {
  { x: T::default(), y: T::default() }
}

pub fn op_add(self : Point[Int], p2 : Point[Int]) -> Point[Int] {
  { x: self.x + p2.x, y: self.y + p2.y }
}

pub fn op_sub(self : Point[Int], p2 : Point[Int]) -> Point[Int] {
  { x: self.x - p2.x, y: self.y - p2.y }
}

pub fn op_neg(self : Point[Int]) -> Point[Int] {
  { x: -self.x, y: -self.y }
}

/// Shift the x-coordinate by the specified amount
pub fn shift_x(self : Point[Int], v : Int) -> Point[Int] {
  { x: self.x + v, y: self.y }
}

/// Shift the y-coordinate by the specified amount
pub fn shift_y(self : Point[Int], v : Int) -> Point[Int] {
  { x: self.x, y: self.y + v }
}
