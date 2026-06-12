///|
struct BoolPair[T](T, T)

///|
pub fn[T] BoolPair::new(false_value : T, true_value : T) -> BoolPair[T] {
  BoolPair(false_value, true_value)
}

///|
pub fn[T] BoolPair::op_get(self : BoolPair[T], b : Bool) -> T {
  if b {
    self.1
  } else {
    self.0
  }
}

///|
pub impl[T : Default] Default for BoolPair[T] with fn default() {
  BoolPair::new(T::default(), T::default())
}
