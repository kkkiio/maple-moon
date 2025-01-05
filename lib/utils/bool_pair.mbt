///|
type BoolPair[T] (T, T)

///|
pub fn BoolPair::new[T](false_value : T, true_value : T) -> BoolPair[T] {
  (false_value, true_value)
}

///|
pub fn op_get[T](self : BoolPair[T], b : Bool) -> T {
  if b {
    self._.1
  } else {
    self._.0
  }
}

///|
pub impl[T : Default] Default for BoolPair[T] with default() {
  BoolPair::new(T::default(), T::default())
}
