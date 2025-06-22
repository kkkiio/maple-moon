///|
pub(all) type TimePoint Int64 derive(Eq, Compare, Default)

///|
pub fn TimePoint::from_micro(i : Double) -> TimePoint {
  i.to_int64()
}

///|
pub fn add_duration(self : TimePoint, duration : Duration) -> TimePoint {
  self.inner() + duration.inner().to_int64()
}

///|
pub(all) type Duration Int derive(Eq, Compare, Show)

///|
pub fn Duration::from_micro(i : Int) -> Duration {
  i
}

///|
pub fn Duration::from_milliseconds(i : Int) -> Duration {
  i * 1000
}

///|
pub fn to_micro_seconds(self : Duration) -> Int {
  self.inner()
}

///|
pub fn to_milliseconds(self : Duration) -> Int {
  self.inner() / 1000
}

///|
pub fn to_seconds(self : Duration) -> Int {
  self.inner() / 1000000
}

///|
pub fn since(self : TimePoint, other : TimePoint) -> Duration {
  (self.inner() - other.inner()).to_int()
}

///|
struct Timer {
  get_now : () -> TimePoint
  mut current_time : TimePoint
}

///|
pub fn Timer::new(get_now : () -> TimePoint) -> Timer {
  { get_now, current_time: 0L }
}

///|
pub fn reset(self : Timer) -> Unit {
  self.current_time = (self.get_now)()
}

///|
pub fn stop(self : Timer, now : TimePoint) -> Duration {
  let duration = self.since(now)
  self.current_time = now
  duration
}

///|
pub fn Timer::since(self : Timer, now : TimePoint) -> Duration {
  if now <= self.current_time {
    return 0
  }
  now.since(self.current_time)
}

///|
pub fn now(self : Timer) -> TimePoint {
  self.current_time
}
