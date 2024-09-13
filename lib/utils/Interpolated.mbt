struct Nominal[T] {
  mut now : T
  mut before : T
  mut threshold : Double
}

pub fn Nominal::default[T : Default]() -> Nominal[T] {
  { now: T::default(), before: T::default(), threshold: 0.0 }
}

pub fn get[T](self : Nominal[T], ~alpha? : Double) -> T {
  match alpha {
    None => self.now
    Some(alpha) => if alpha >= self.threshold { self.now } else { self.before }
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

pub fn Linear::new(now : Double) -> Linear {
  { now, before: 0 }
}

pub fn get(self : Linear, ~alpha? : Double) -> Double {
  match alpha {
    None => self.now
    Some(alpha) => lerp(self.before, self.now, alpha)
  }
}

pub fn set(self : Linear, value : Double) -> Unit {
  self.before = self.now
  self.now = value
}

pub fn last(self : Linear) -> Double {
  self.before
}

pub fn add(self : Linear, value : Double) -> Unit {
  self.before = self.now
  self.now += value
}

pub fn normalize(self : Linear) -> Unit {
  self.before = self.now
}

pub fn normalized(self : Linear) -> Bool {
  self.before == self.now
}

pub fn plus(self : Linear, value : Double) -> Double {
  self.now + value
}

///https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p0811r3.html
pub fn lerp(a : Double, b : Double, t : Double) -> Double {
  // Exact, monotonic, bounded, determinate, and (for a=b=0) consistent:
  if (a <= 0.0 && b >= 0.0) || (a >= 0.0 && b <= 0.0) {
    return t * b + (1.0 - t) * a
  }
  // exact
  if t == 1.0 {
    return b
  }

  // Exact at t=0, monotonic except near t=1,
  // bounded, determinate, and consistent:
  let x = a + t * (b - a)
  // monotonic near t=1
  return if t > 1.0 == (b > a) {
    @math.maximum(b, x)
  } else {
    @math.minimum(b, x)
  }
}
