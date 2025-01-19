///|
pub(all) struct Point[T] {
  x : T
  y : T
} derive(Eq, Show)

///|
pub fn Point::new[T](x : T, y : T) -> Point[T] {
  { x, y }
}

///|
pub fn Point::default[T : Default]() -> Point[T] {
  { x: T::default(), y: T::default() }
}

///|
pub fn op_add[T : Scalar](self : Point[T], p2 : Point[T]) -> Point[T] {
  { x: self.x + p2.x, y: self.y + p2.y }
}

///|
pub fn op_sub[T : Scalar](self : Point[T], p2 : Point[T]) -> Point[T] {
  { x: self.x - p2.x, y: self.y - p2.y }
}

///|
pub fn op_neg[T : Scalar](self : Point[T]) -> Point[T] {
  { x: -self.x, y: -self.y }
}

///| Shift the x-coordinate by the specified amount
pub fn shift_x[T : Scalar](self : Point[T], v : T) -> Point[T] {
  { x: self.x + v, y: self.y }
}

///| Shift the y-coordinate by the specified amount
pub fn shift_y[T : Scalar](self : Point[T], v : T) -> Point[T] {
  { x: self.x, y: self.y + v }
}

///|
pub fn distance(self : Point[Int], v : Point[Int]) -> Int {
  (self.x - v.x).abs() + (self.y - v.y).abs()
}

///| Check whether the coordinates are equal
pub fn straight[T : Eq](self : Point[T]) -> Bool {
  self.x == self.y
}

///|
pub(open) trait Scalar {
  op_add(Self, Self) -> Self
  op_sub(Self, Self) -> Self
  op_neg(Self) -> Self
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
