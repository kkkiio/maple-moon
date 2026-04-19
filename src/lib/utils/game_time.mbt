///|
pub(all) struct TimePoint(Int64) derive(Eq, Compare, Default)

///|
pub fn TimePoint::from_micro(i : Double) -> TimePoint {
  i.to_int64()
}

///|
pub fn TimePoint::add_duration(
  self : TimePoint,
  duration : Duration,
) -> TimePoint {
  self.0 + duration.0.to_int64()
}

///|
pub(all) struct Duration(Int) derive(Eq, Compare, Debug)

///|
pub fn Duration::from_micro(i : Int) -> Duration {
  i
}

///|
pub fn Duration::from_milliseconds(i : Int) -> Duration {
  i * 1000
}

///|
pub fn Duration::to_micro_seconds(self : Duration) -> Int {
  self.0
}

///|
pub fn Duration::to_milliseconds(self : Duration) -> Int {
  self.0 / 1000
}

///|
pub fn Duration::to_seconds(self : Duration) -> Int {
  self.0 / 1000000
}

///|
pub fn TimePoint::since(self : TimePoint, other : TimePoint) -> Duration {
  (self.0 - other.0).to_int()
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
pub fn Timer::reset(self : Timer) -> Unit {
  self.current_time = (self.get_now)()
}

///|
pub fn Timer::stop(self : Timer, now : TimePoint) -> Duration {
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
pub fn Timer::now(self : Timer) -> TimePoint {
  self.current_time
}
