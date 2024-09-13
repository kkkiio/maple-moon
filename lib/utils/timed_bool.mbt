struct TimedBool {
  mut last : Int
  mut delay : Int
  mut value : Bool
}

pub fn TimedBool::default() -> TimedBool {
  { value: false, delay: 0, last: 0 }
}

pub fn get(self : TimedBool) -> Bool {
  self.value
}

pub fn set_for(self : TimedBool, millis : Int) -> Unit {
  self.last = millis
  self.delay = millis
  self.value = true
}

pub fn update(self : TimedBool, ~timestep : Int = @constants.timestep) -> Unit {
  if self.value {
    if timestep >= self.delay {
      self.value = false
      self.delay = 0
    } else {
      self.delay -= timestep
    }
  }
}

pub fn set(self : TimedBool, value : Bool) -> Unit {
  self.value = value
  self.delay = 0
  self.last = 0
}

pub fn alpha(self : TimedBool) -> Double {
  1.0 - self.delay.to_double() / self.last.to_double()
}
