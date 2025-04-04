///|
struct Rectangle[T] {
  lt : Point[T]
  rb : Point[T]
} derive(Eq, Default, Show, ToJson)

///|
pub fn Rectangle::new[T](lt : Point[T], rb : Point[T]) -> Rectangle[T] {
  { lt, rb }
}

///|
pub fn Rectangle::from4[T](
  left : T,
  right : T,
  top : T,
  bottom : T
) -> Rectangle[T] {
  { lt: { x: left, y: top }, rb: { x: right, y: bottom } }
}

///|
pub fn left[T](self : Rectangle[T]) -> T {
  self.lt.x
}

///|
pub fn top[T](self : Rectangle[T]) -> T {
  self.lt.y
}

///|
pub fn right[T](self : Rectangle[T]) -> T {
  self.rb.x
}

///|
pub fn bottom[T](self : Rectangle[T]) -> T {
  self.rb.y
}

///|
pub fn Rectangle::straight[T : Eq](self : Rectangle[T]) -> Bool {
  self.lt == self.rb
}

///|
pub fn Rectangle::contains[T : Eq + Compare](
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
pub fn Rectangle::shift[T : Add](
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
pub fn is_empty[T : Eq](self : Rectangle[T]) -> Bool {
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
        Some(v) => Point::from_json!(v, path.add_key("lt"))
      }
      let rb = match rb_value {
        None => { x: 0, y: 0 }
        Some(v) => Point::from_json!(v, path.add_key("rb"))
      }
      { lt, rb }
    }
    _ =>
      raise @json.JsonDecodeError(
        (path, "Rectangle::from_json: expected object with 'lt' and 'rb' keys"),
      )
  }
}
