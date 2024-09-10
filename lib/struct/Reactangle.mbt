// app/src/main/cpp/src/Template/Rectangle.h

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
