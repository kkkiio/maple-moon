///|
/// Return a random boolean value.
pub fn next_bool(state : @random.Rand) -> Bool {
  next_int(state, 2) == 1
}

///|
/// Return whether a random value in `[0.0, 1.0)` is lower than `percent`.
pub fn below(state : @random.Rand, percent : Double) -> Bool {
  next_real(state, 1.0) < percent
}

///|
/// Return whether a random value in `[0.0, 1.0)` is greater than `percent`.
pub fn above(state : @random.Rand, percent : Double) -> Bool {
  next_real(state, 1.0) > percent
}

///|
/// Return a random floating-point number in `[from, to)`.
pub fn next_real(
  state : @random.Rand,
  from? : Double = 0.0,
  to : Double,
) -> Double {
  if from >= to {
    return from
  }
  state.double() * (to - from) + from
}

///|
/// Return a random integer in `[from, to)`.
pub fn next_int(state : @random.Rand, from? : Int = 0, to : Int) -> Int {
  if from >= to {
    return from
  }
  state.int(limit=to - from) + from
}

///|
/// Select one item uniformly from `items`.
pub fn[T] choose(state : @random.Rand, items : Array[T]) -> T {
  items[next_int(state, items.length())]
}
