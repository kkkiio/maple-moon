///|
struct TimedQueue[T] {
  queue : @priority_queue.T[Timed[T]]
  mut time : Int64
}

///|
pub fn[T] TimedQueue::new() -> TimedQueue[T] {
  { queue: @priority_queue.new(), time: 0 }
}

///|
pub fn[T] push(self : TimedQueue[T], delay : Int64, t : T) -> Unit {
  self.queue.push(Timed(delay, t))
}

///|
pub fn[T] process(self : TimedQueue[T], timestep~ : Int64) -> Iter[T] {
  self.time += timestep
  Iter::new(fn(yield_) {
    loop self.queue.peek() {
      Some(top) => {
        if top.0 > self.time {
          break
        }
        if yield_(top.1) == IterEnd {
          return IterEnd
        }
        self.queue.pop() |> ignore
        continue self.queue.peek()
      }
      None => break
    }
    IterContinue
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
