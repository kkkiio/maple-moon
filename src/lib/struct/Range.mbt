///|
pub(all) struct Range[T] {
  a : T
  b : T
} derive(Eq, Show, Default)

///|
pub fn Range::new[T](first : T, second : T) -> Range[T] {
  { a: first, b: second }
}

///|
pub fn first[T](self : Range[T]) -> T {
  self.a
}

///|
pub fn second[T](self : Range[T]) -> T {
  self.b
}

///|
pub fn greater[T : Compare](self : Range[T]) -> T {
  if self.a > self.b {
    self.a
  } else {
    self.b
  }
}

///|
pub fn smaller[T : Compare](self : Range[T]) -> T {
  if self.a < self.b {
    self.a
  } else {
    self.b
  }
}

///|
pub fn delta(self : Range[Int]) -> Int {
  self.b - self.a
}

///|
pub fn length(self : Range[Int]) -> Int {
  let greater = self.greater()
  let smaller = self.smaller()
  greater - smaller
}

///|
pub fn center(self : Range[Int]) -> Int {
  (self.a + self.b) / 2
}

///|
pub fn empty[T : Eq](self : Range[T]) -> Bool {
  self.a == self.b
}

///|
pub fn contains[T : Compare](self : Range[T], v : T) -> Bool {
  v >= self.a && v <= self.b
}

///|
pub fn contains_range[T : Compare](self : Range[T], v : Range[T]) -> Bool {
  v.a >= self.a && v.b <= self.b
}

///|
pub fn overlaps[T : Compare](self : Range[T], v : Range[T]) -> Bool {
  Range::contains(self, v.a) ||
  Range::contains(self, v.b) ||
  Range::contains_range(v, self)
}

///|
pub impl[T : Add] Add for Range[T] with op_add(self : Range[T], v : Range[T]) -> Range[
  T,
] {
  { a: self.a + v.a, b: self.b + v.b }
}

///|
pub impl[T : Sub] Sub for Range[T] with op_sub(self : Range[T], v : Range[T]) -> Range[
  T,
] {
  { a: self.a - v.a, b: self.b - v.b }
}

///|
pub impl[T : Neg] Neg for Range[T] with op_neg(self : Range[T]) -> Range[T] {
  { a: -self.a, b: -self.b }
}

///|
pub fn Range::symmetric(mid : Int, tail : Int) -> Range[Int] {
  { a: mid - tail, b: mid + tail }
}
