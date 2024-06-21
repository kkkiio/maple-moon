pub struct Point[T] {
  mut x : T
  mut y : T
} derive(Eq, Debug)

pub fn to_string(self : Point[Int]) -> String {
  let x = self.x
  let y = self.y
  "(\(x),\(y))"
}

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
pub fn shift_x(self : Point[Int], v : Int) -> Unit {
  self.x += v
}

/// Shift the y-coordinate by the specified amount
pub fn shift_y(self : Point[Int], v : Int) -> Unit {
  self.y += v
}

pub fn Point::from_resource(src : NxNode) -> Point[Int] {
  match src.desc.as_array() {
    Some(arr) =>
      {
        x: arr[0].as_number().unwrap().to_int(),
        y: arr[1].as_number().unwrap().to_int(),
      }
    None => Point::default()
  }
}
