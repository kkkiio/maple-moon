///|
struct TimedBool {
  mut last : Int
  mut delay : Int
  mut value : Bool
}

///|
pub fn TimedBool::default() -> TimedBool {
  { value: false, delay: 0, last: 0 }
}

///|
pub fn TimedBool::get(self : TimedBool) -> Bool {
  self.value
}

///|
pub fn TimedBool::set_for(self : TimedBool, millis : Int) -> Unit {
  self.last = millis
  self.delay = millis
  self.value = true
}

///|
pub fn TimedBool::update(self : TimedBool, timestep~ : Int) -> Unit {
  if self.value {
    if timestep >= self.delay {
      self.value = false
      self.delay = 0
    } else {
      self.delay -= timestep
    }
  }
}

///|
pub fn TimedBool::set(self : TimedBool, value : Bool) -> Unit {
  self.value = value
  self.delay = 0
  self.last = 0
}

///|
pub fn TimedBool::alpha(self : TimedBool) -> Double {
  1.0 - self.delay.to_double() / self.last.to_double()
}
