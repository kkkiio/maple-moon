///|
struct Rectangle[T] {
  lt : Point[T]
  rb : Point[T]
} derive(Eq, Default, Show, ToJson)

///|
pub fn[T] Rectangle::new(lt : Point[T], rb : Point[T]) -> Rectangle[T] {
  { lt, rb }
}

///|
pub fn[T] Rectangle::from4(
  left : T,
  right : T,
  top : T,
  bottom : T
) -> Rectangle[T] {
  { lt: { x: left, y: top }, rb: { x: right, y: bottom } }
}

///|
pub fn[T] left(self : Rectangle[T]) -> T {
  self.lt.x
}

///|
pub fn[T] top(self : Rectangle[T]) -> T {
  self.lt.y
}

///|
pub fn[T] right(self : Rectangle[T]) -> T {
  self.rb.x
}

///|
pub fn[T] bottom(self : Rectangle[T]) -> T {
  self.rb.y
}

///|
pub fn[T : Eq] Rectangle::straight(self : Rectangle[T]) -> Bool {
  self.lt == self.rb
}

///|
pub fn[T : Eq + Compare] Rectangle::contains(
  self : Rectangle[T],
  v : Point[T]
) -> Bool {
  not(self.straight()) &&
  v.x >= self.left() &&
  v.x <= self.right() &&
  v.y >= self.top() &&
  v.y <= self.bottom()
}

///|
pub fn[T : Add] Rectangle::shift(
  self : Rectangle[T],
  v : Point[T]
) -> Rectangle[T] {
  { lt: self.lt + v, rb: self.rb + v }
}

///|
pub fn Rectangle::overlaps(self : Rectangle[Int], ar : Rectangle[Int]) -> Bool {
  self.get_horizontal().overlaps(Range::new(ar.left(), ar.right())) &&
  self.get_vertical().overlaps(Range::new(ar.top(), ar.bottom()))
}

///|
pub fn get_horizontal(self : Rectangle[Int]) -> Range[Int] {
  Range::new(self.left(), self.right())
}

///|
pub fn get_vertical(self : Rectangle[Int]) -> Range[Int] {
  Range::new(self.top(), self.bottom())
}

///|
pub fn[T : Eq] is_empty(self : Rectangle[T]) -> Bool {
  self.lt.straight() && self.rb.straight() && self.straight()
}

///|
pub fn flip_x(self : Rectangle[Int]) -> Rectangle[Int] {
  {
    lt: { x: -self.right(), y: self.top() },
    rb: { x: -self.left(), y: self.bottom() },
  }
}

///|
pub impl @json.FromJson for Rectangle[Int] with from_json(value, path) {
  match value {
    { "lt"? : lt_value, "rb"? : rb_value, .. } => {
      let lt = match lt_value {
        None => { x: 0, y: 0 }
        Some(v) => Point::from_json(v, path.add_key("lt"))
      }
      let rb = match rb_value {
        None => { x: 0, y: 0 }
        Some(v) => Point::from_json(v, path.add_key("rb"))
      }
      { lt, rb }
    }
    _ =>
      raise @json.JsonDecodeError(
        (path, "Rectangle::from_json: expected object with 'lt' and 'rb' keys"),
      )
  }
}
