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
  self.0
}

fn since(self : TimePoint, other : TimePoint) -> Duration {
  (self.0 - other.0).to_int()
}

// Small class for measuring elapsed time between game loops.
// Time measures are in microseconds.
struct Timer {
  mut point : TimePoint
}

fn Timer::new() -> Timer {
  { point: 0L }
}

let timer : Timer = Timer::new()

fn Timer::get() -> Timer {
  timer
}

fn start(self : Timer) -> Unit {
  self.point = now_micro() |> TimePoint::from_micro
}

fn stop(self : Timer, now : TimePoint) -> Duration {
  if now <= self.point {
    return 0
  }
  let duration = now.since(self.point)
  self.point = now
  duration
}

fn now(self : Timer) -> TimePoint {
  now_micro() |> TimePoint::from_micro
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
