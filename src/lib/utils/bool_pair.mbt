///|
type BoolPair[T] (T, T)

///|
pub fn[T] BoolPair::new(false_value : T, true_value : T) -> BoolPair[T] {
  (false_value, true_value)
}

///|
pub fn[T] op_get(self : BoolPair[T], b : Bool) -> T {
  if b {
    self.inner().1
  } else {
    self.inner().0
  }
}

///|
pub impl[T : Default] Default for BoolPair[T] with default() {
  BoolPair::new(T::default(), T::default())
}
