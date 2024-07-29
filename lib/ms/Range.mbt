pub struct Range[T] {
  a : T
  b : T
} derive(Eq, Show)

pub fn Range::new[T](first : T, second : T) -> Range[T] {
  { a: first, b: second }
}

pub fn Range::default[T : Default]() -> Range[T] {
  { a: T::default(), b: T::default() }
}

pub fn first[T](self : Range[T]) -> T {
  self.a
}

pub fn second[T](self : Range[T]) -> T {
  self.b
}

pub fn greater[T : Compare](self : Range[T]) -> T {
  if self.a > self.b {
    self.a
  } else {
    self.b
  }
}

pub fn smaller[T : Compare](self : Range[T]) -> T {
  if self.a < self.b {
    self.a
  } else {
    self.b
  }
}

pub fn delta(self : Range[Int]) -> Int {
  self.b - self.a
}

pub fn length(self : Range[Int]) -> Int {
  let greater = self.greater()
  let smaller = self.smaller()
  greater - smaller
}

pub fn center(self : Range[Int]) -> Int {
  (self.a + self.b) / 2
}

pub fn empty[T : Eq](self : Range[T]) -> Bool {
  self.a == self.b
}

pub fn contains[T : Compare](self : Range[T], v : T) -> Bool {
  v >= self.a && v <= self.b
}

pub fn contains_range[T : Compare](self : Range[T], v : Range[T]) -> Bool {
  v.a >= self.a && v.b <= self.b
}

pub fn overlaps[T : Compare](self : Range[T], v : Range[T]) -> Bool {
  Range::contains(self, v.a) || Range::contains(self, v.b) || Range::contains_range(
    v, self,
  )
}

pub fn eq[T : Eq](self : Range[T], v : Range[T]) -> Bool {
  self.a == v.a && self.b == v.b
}

pub fn neq[T : Eq](self : Range[T], v : Range[T]) -> Bool {
  self.eq(v).not()
}

pub fn op_add(self : Range[Int], v : Range[Int]) -> Range[Int] {
  { a: self.a + v.a, b: self.b + v.b }
}

pub fn op_sub(self : Range[Int], v : Range[Int]) -> Range[Int] {
  { a: self.a - v.a, b: self.b - v.b }
}

pub fn op_neg(self : Range[Int]) -> Range[Int] {
  { a: -self.a, b: -self.b }
}

pub fn Range::symmetric(mid : Int, tail : Int) -> Range[Int] {
  { a: mid - tail, b: mid + tail }
}
