// app/src/main/cpp/src/Template/Interpolated.h

struct Nominal[T] {
  mut now : T
  mut before : T
  mut threshold : Double
}

fn Nominal::default[T : Default]() -> Nominal[T] {
  { now: T::default(), before: T::default(), threshold: 0.0 }
}

pub fn get[T](self : Nominal[T], alpha : Double) -> T {
  if alpha >= self.threshold {
    self.now
  } else {
    self.before
  }
}

pub fn last[T](self : Nominal[T]) -> T {
  self.before
}

pub fn set[T](self : Nominal[T], value : T) -> Unit {
  self.before = self.now
  self.now = value
}

pub fn normalize[T](self : Nominal[T]) -> Unit {
  self.before = self.now
}

pub fn normalized[T : Eq](self : Nominal[T]) -> Bool {
  self.before == self.now
}

pub fn next[T](self : Nominal[T], value : T, thrs : Double) -> Unit {
  self.before = self.now
  self.now = value
  self.threshold = thrs
}

struct Linear {
  mut now : Double
  mut before : Double
} derive(Default, Show)

pub fn get(self : Linear, alpha : Double) -> Double {
  lerp(self.before, self.now, alpha)
}

pub fn set(self : Linear, value : Double) -> Unit {
  self.before = self.now
  self.now = value
}

pub fn last(self : Linear) -> Double {
  self.before
}

fn add(self : Linear, value : Double) -> Unit {
  self.before = self.now
  self.now += value
}

pub fn normalize(self : Linear) -> Unit {
  self.before = self.now
}

pub fn normalized(self : Linear) -> Bool {
  self.before == self.now
}

fn plus(self : Linear, value : Double) -> Double {
  self.now + value
}
