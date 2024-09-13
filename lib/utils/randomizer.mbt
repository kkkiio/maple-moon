struct Randomizer {
  state : @random.Rand
}

pub fn Randomizer::default() -> Randomizer {
  { state: @random.new() }
}

pub fn next_bool(self : Randomizer) -> Bool {
  self.next_int(2) == 1
}

pub fn below(self : Randomizer, percent : Double) -> Bool {
  self.next_real(1.0) < percent
}

pub fn above(self : Randomizer, percent : Double) -> Bool {
  self.next_real(1.0) > percent
}

pub fn next_real(
  self : Randomizer,
  ~from : Double = 0.0,
  to : Double
) -> Double {
  if from >= to {
    return from
  }
  self.state.double() * (to - from) + from
}

pub fn next_int(self : Randomizer, ~from : Int = 0, to : Int) -> Int {
  if from >= to {
    return from
  }
  self.state.int(limit=to - from) + from
}

pub fn choose[T](self : Randomizer, items : FixedArray[T]) -> T {
  items[self.next_int(items.length())]
}
