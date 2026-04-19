///|
pub(all) struct Point[T] {
  x : T
  y : T
} derive(Eq, Debug, Default)

///|
pub fn[T] Point::new(x : T, y : T) -> Point[T] {
  { x, y }
}

///|
pub impl[T : Add] Add for Point[T] with add(self : Point[T], p2 : Point[T]) -> Point[
  T,
] {
  { x: self.x + p2.x, y: self.y + p2.y }
}

///|
pub impl[T : Sub] Sub for Point[T] with sub(self : Point[T], p2 : Point[T]) -> Point[
  T,
] {
  { x: self.x - p2.x, y: self.y - p2.y }
}

///|
pub impl[T : Neg] Neg for Point[T] with neg(self : Point[T]) -> Point[T] {
  { x: -self.x, y: -self.y }
}

///|
/// Shift the x-coordinate by the specified amount
pub fn[T : Add] Point::shift_x(self : Point[T], v : T) -> Point[T] {
  { x: self.x + v, y: self.y }
}

///|
/// Shift the y-coordinate by the specified amount
pub fn[T : Add] Point::shift_y(self : Point[T], v : T) -> Point[T] {
  { x: self.x, y: self.y + v }
}

///|
pub fn Point::distance(self : Point[Int], v : Point[Int]) -> Int {
  (self.x - v.x).abs() + (self.y - v.y).abs()
}

///|
/// Check whether the coordinates are equal
pub fn[T : Eq] Point::straight(self : Point[T]) -> Bool {
  self.x == self.y
}

///|
pub impl @json.FromJson for Point[Int] with from_json(value, path) {
  match value {
    [Json::Number(x, ..), Json::Number(y, ..)] =>
      Point::new(x.to_int(), y.to_int())
    Null => Point::default()
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
pub fn Point::to_vec2d(self : Point[Int]) -> @selene_math.Vec2D {
  @selene_math.Vec2D(self.x.to_double(), self.y.to_double())
}
