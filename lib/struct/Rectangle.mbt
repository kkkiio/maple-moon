struct Rectangle[T] {
  lt : Point[T]
  rb : Point[T]
} derive(Eq, Default)

pub fn to_string[T : Show](self : Rectangle[T]) -> String {
  let lt = self.lt
  let rb = self.rb
  "Rect[\{lt},\{rb}]"
}

pub fn Rectangle::new[T](lt : Point[T], rb : Point[T]) -> Rectangle[T] {
  { lt, rb }
}

pub fn Rectangle::from4[T](
  left : T,
  right : T,
  top : T,
  bottom : T
) -> Rectangle[T] {
  { lt: { x: left, y: top }, rb: { x: right, y: bottom } }
}

pub fn left[T](self : Rectangle[T]) -> T {
  self.lt.x
}

pub fn top[T](self : Rectangle[T]) -> T {
  self.lt.y
}

pub fn right[T](self : Rectangle[T]) -> T {
  self.rb.x
}

pub fn bottom[T](self : Rectangle[T]) -> T {
  self.rb.y
}

pub fn straight[T : Eq](self : Rectangle[T]) -> Bool {
  self.lt == self.rb
}

pub fn contains[T : Eq + Compare](self : Rectangle[T], v : Point[T]) -> Bool {
  self.straight().not() &&
  v.x >= self.left() &&
  v.x <= self.right() &&
  v.y >= self.top() &&
  v.y <= self.bottom()
}

pub fn shift(self : Rectangle[Int], v : Point[Int]) -> Rectangle[Int] {
  { lt: self.lt + v, rb: self.rb + v }
}

pub fn overlaps(self : Rectangle[Int], ar : Rectangle[Int]) -> Bool {
  self.get_horizontal().overlaps(Range::new(ar.left(), ar.right())) &&
  self.get_vertical().overlaps(Range::new(ar.top(), ar.bottom()))
}

pub fn get_horizontal(self : Rectangle[Int]) -> Range[Int] {
  Range::new(self.left(), self.right())
}

pub fn get_vertical(self : Rectangle[Int]) -> Range[Int] {
  Range::new(self.top(), self.bottom())
}

pub fn is_empty[T : Eq](self : Rectangle[T]) -> Bool {
  self.lt.straight() && self.rb.straight() && self.straight()
}
