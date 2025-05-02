///|
pub(all) struct Point[T] {
  x : T
  y : T
} derive(Eq, Show, Default)

///|
pub fn Point::new[T](x : T, y : T) -> Point[T] {
  { x, y }
}

///|
pub impl[T : Add] Add for Point[T] with op_add(self : Point[T], p2 : Point[T]) -> Point[
  T,
] {
  { x: self.x + p2.x, y: self.y + p2.y }
}

///|
pub impl[T : Sub] Sub for Point[T] with op_sub(self : Point[T], p2 : Point[T]) -> Point[
  T,
] {
  { x: self.x - p2.x, y: self.y - p2.y }
}

///|
pub impl[T : Neg] Neg for Point[T] with op_neg(self : Point[T]) -> Point[T] {
  { x: -self.x, y: -self.y }
}

///| Shift the x-coordinate by the specified amount
pub fn shift_x[T : Add](self : Point[T], v : T) -> Point[T] {
  { x: self.x + v, y: self.y }
}

///| Shift the y-coordinate by the specified amount
pub fn shift_y[T : Add](self : Point[T], v : T) -> Point[T] {
  { x: self.x, y: self.y + v }
}

///|
pub fn distance(self : Point[Int], v : Point[Int]) -> Int {
  (self.x - v.x).abs() + (self.y - v.y).abs()
}

///| Check whether the coordinates are equal
pub fn Point::straight[T : Eq](self : Point[T]) -> Bool {
  self.x == self.y
}

///|
pub impl @json.FromJson for Point[Int] with from_json(value, path) {
  match value {
    [Json::Number(x), Json::Number(y)] => Point::new(x.to_int(), y.to_int())
    _ =>
      raise @json.JsonDecodeError(
        (path, "Point::from_json: expected array of 2 numbers"),
      )
  }
}

///|
pub impl[T : ToJson] ToJson for Point[T] with to_json(self) -> Json {
  [self.x.to_json(), self.y.to_json()]
}

///|
pub fn div_float(self : Point[Float], f : Float) -> Point[Float] {
  { x: self.x / f, y: self.y / f }
}

///|
pub fn to_float(self : Point[Int]) -> Point[Float] {
  { x: self.x.to_float(), y: self.y.to_float() }
}

///|
pub fn to_int(self : Point[Float]) -> Point[Int] {
  { x: self.x.to_int(), y: self.y.to_int() }
}
