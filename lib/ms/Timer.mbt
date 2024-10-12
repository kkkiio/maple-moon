pub type TimePoint Int64 derive(Eq, Compare, Default)

pub fn TimePoint::from_micro(i : Double) -> TimePoint {
  i.to_int64()
}

fn now_micro() -> Double = "time" "now_micro"

pub type Duration Int derive(Eq, Compare, Show)

pub fn Duration::from_micro(i : Int) -> Duration {
  i
}

fn to_micro_seconds(self : Duration) -> Int {
  self._
}

fn to_milliseconds(self : Duration) -> Int {
  self._ / 1000
}

fn since(self : TimePoint, other : TimePoint) -> Duration {
  (self._ - other._).to_int()
}

// Small class for measuring elapsed time between game loops.
// Time measures are in microseconds.
struct Timer {
  mut current_time : TimePoint
}

fn Timer::new() -> Timer {
  { current_time: 0L }
}

fn start(self : Timer) -> Unit {
  self.current_time = now_micro() |> TimePoint::from_micro
}

fn stop(self : Timer, now : TimePoint) -> Duration {
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

struct PerfTimer {
  mut last : TimePoint
}

pub fn PerfTimer::start() -> PerfTimer {
  { last: now_micro() |> TimePoint::from_micro }
}

pub fn tap(self : PerfTimer) -> Duration {
  let now = now_micro() |> TimePoint::from_micro
  let duration = now.since(self.last)
  self.last = now
  duration
}
