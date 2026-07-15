///|
struct BoolPair[T] {
  false_value : T
  true_value : T
}

///|
pub fn[T] BoolPair::BoolPair(false_value : T, true_value : T) -> BoolPair[T] {
  { false_value, true_value }
}

///|
pub fn[T] BoolPair::op_get(self : BoolPair[T], b : Bool) -> T {
  if b {
    self.true_value
  } else {
    self.false_value
  }
}

///|
pub impl[T : Default] Default for BoolPair[T] with fn default() {
  BoolPair(T::default(), T::default())
}
