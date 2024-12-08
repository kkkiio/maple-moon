pub(all) type TimePoint Int64 derive(Eq, Compare, Default)

pub fn TimePoint::from_micro(i : Double) -> TimePoint {
  i.to_int64()
}

pub(all) type Duration Int derive(Eq, Compare, Show)

pub fn Duration::from_micro(i : Int) -> Duration {
  i
}

pub fn to_micro_seconds(self : Duration) -> Int {
  self._
}

pub fn to_milliseconds(self : Duration) -> Int {
  self._ / 1000
}

pub fn to_seconds(self : Duration) -> Int {
  self._ / 1000000
}

pub fn since(self : TimePoint, other : TimePoint) -> Duration {
  (self._ - other._).to_int()
}

struct Timer {
  get_now : () -> TimePoint
  mut current_time : TimePoint
}

pub fn Timer::new(get_now : () -> TimePoint) -> Timer {
  { get_now, current_time: 0L }
}

pub fn reset(self : Timer) -> Unit {
  self.current_time = (self.get_now)()
}

pub fn stop(self : Timer, now : TimePoint) -> Duration {
  let duration = self.since(now)
  self.current_time = now
  duration
}

pub fn since(self : Timer, now : TimePoint) -> Duration {
  if now <= self.current_time {
    return 0
  }
  now.since(self.current_time)
}

pub fn now(self : Timer) -> TimePoint {
  self.current_time
}
