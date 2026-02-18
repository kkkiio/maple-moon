///|
struct TimedQueue[T] {
  queue : @priority_queue.PriorityQueue[Timed[T]]
  mut time : Int64
}

///|
pub fn[T] TimedQueue::new() -> TimedQueue[T] {
  { queue: @priority_queue.PriorityQueue::new(), time: 0 }
}

///|
pub fn[T] TimedQueue::push(self : TimedQueue[T], delay : Int64, t : T) -> Unit {
  self.queue.push(Timed(delay, t))
}

///|
pub fn[T] TimedQueue::process(
  self : TimedQueue[T],
  timestep~ : Int64,
) -> Iter[T] {
  self.time += timestep
  Iter::new(fn() {
    match self.queue.peek() {
      Some(top) => {
        if top.0 > self.time {
          return None
        }
        self.queue.pop() |> ignore
        return Some(top.1)
      }
      None => return None
    }
  })
}

///|
struct Timed[T](Int64, T)

///|
pub impl[T] Compare for Timed[T] with compare(self, other) -> Int {
  self.0.compare(other.0).neg() // less first
}

///|
pub impl[T] Eq for Timed[T] with equal(self, other) -> Bool {
  self.0.equal(other.0)
}
