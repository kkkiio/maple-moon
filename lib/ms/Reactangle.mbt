// app/src/main/cpp/src/Template/Rectangle.h

struct Rectangle[T] {
  left_top : Point[T]
  right_bottom : Point[T]
} derive(Eq, Default, Debug)

pub fn to_string[T : Show](self : Rectangle[T]) -> String {
  let lt = self.left_top
  let rb = self.right_bottom
  "Rect[\(lt),\(rb)]"
}

pub fn Rectangle::new[T](lt : Point[T], rb : Point[T]) -> Rectangle[T] {
  { left_top: lt, right_bottom: rb }
}

pub fn Rectangle::from4[T](
  left : T,
  right : T,
  top : T,
  bottom : T
) -> Rectangle[T] {
  { left_top: { x: left, y: top }, right_bottom: { x: right, y: bottom } }
}

pub fn left[T](self : Rectangle[T]) -> T {
  self.left_top.x
}

pub fn top[T](self : Rectangle[T]) -> T {
  self.left_top.y
}

pub fn right[T](self : Rectangle[T]) -> T {
  self.right_bottom.x
}

pub fn bottom[T](self : Rectangle[T]) -> T {
  self.right_bottom.y
}

pub trait FromResource {
  from_resource(NxNode) -> Self
}

pub fn Rectangle::from_resource(src : NxNode) -> Rectangle[Int] {
  {
    left_top: Point::from_resource(src["lt"]),
    right_bottom: Point::from_resource(src["rb"]),
  }
}

fn straight[T : Eq](self : Rectangle[T]) -> Bool {
  self.left_top == self.right_bottom
}

fn contains[T : Eq + Compare](self : Rectangle[T], v : Point[T]) -> Bool {
  self.straight().not() && v.x >= self.left() && v.x <= self.right() && v.y >= self.top() &&
  v.y <= self.bottom()
}
