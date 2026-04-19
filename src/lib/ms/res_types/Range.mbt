///|
pub(all) struct Range[T] {
  a : T
  b : T
} derive(Eq, Debug, Default)

///|
pub fn[T] Range::new(first : T, second : T) -> Range[T] {
  { a: first, b: second }
}

///|
pub fn[T] Range::first(self : Range[T]) -> T {
  self.a
}

///|
pub fn[T] Range::second(self : Range[T]) -> T {
  self.b
}

///|
pub fn[T : Compare] Range::greater(self : Range[T]) -> T {
  if self.a > self.b {
    self.a
  } else {
    self.b
  }
}

///|
pub fn[T : Compare] Range::smaller(self : Range[T]) -> T {
  if self.a < self.b {
    self.a
  } else {
    self.b
  }
}

///|
pub fn Range::delta(self : Range[Int]) -> Int {
  self.b - self.a
}

///|
pub fn Range::length(self : Range[Int]) -> Int {
  let greater = self.greater()
  let smaller = self.smaller()
  greater - smaller
}

///|
pub fn Range::center(self : Range[Int]) -> Int {
  (self.a + self.b) / 2
}

///|
pub fn[T : Eq] Range::empty(self : Range[T]) -> Bool {
  self.a == self.b
}

///|
pub fn[T : Compare] Range::contains(self : Range[T], v : T) -> Bool {
  v >= self.a && v <= self.b
}

///|
pub fn[T : Compare] Range::contains_range(
  self : Range[T],
  v : Range[T],
) -> Bool {
  v.a >= self.a && v.b <= self.b
}

///|
pub fn[T : Compare] Range::overlaps(self : Range[T], v : Range[T]) -> Bool {
  let s_min = self.smaller()
  let s_max = self.greater()
  let v_min = v.smaller()
  let v_max = v.greater()
  v_min <= s_max && v_max >= s_min
}

///|
pub impl[T : Add] Add for Range[T] with add(self : Range[T], v : Range[T]) -> Range[
  T,
] {
  { a: self.a + v.a, b: self.b + v.b }
}

///|
pub impl[T : Sub] Sub for Range[T] with sub(self : Range[T], v : Range[T]) -> Range[
  T,
] {
  { a: self.a - v.a, b: self.b - v.b }
}

///|
pub impl[T : Neg] Neg for Range[T] with neg(self : Range[T]) -> Range[T] {
  { a: -self.a, b: -self.b }
}

///|
pub fn Range::symmetric(mid : Int, tail : Int) -> Range[Int] {
  { a: mid - tail, b: mid + tail }
}
