struct Point[T] {
  x : T
  y : T
} derive(Eq)

fn op_add(self : Point[Int], p2 : Point[Int]) -> Point[Int] {
  { x: self.x + p2.x, y: self.y + p2.y }
}

fn op_sub(self : Point[Int], p2 : Point[Int]) -> Point[Int] {
  { x: self.x - p2.x, y: self.y - p2.y }
}
