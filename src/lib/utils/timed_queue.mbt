///|
struct TimedQueue[T] {
  queue : @priority_queue.T[Timed[T]]
  mut time : Int64
}

///|
pub fn TimedQueue::new[T]() -> TimedQueue[T] {
  { queue: @priority_queue.new(), time: 0 }
}

///|
pub fn push[T](self : TimedQueue[T], delay : Int64, t : T) -> Unit {
  self.queue.push((delay, t))
}

///|
pub fn process[T](self : TimedQueue[T], timestep~ : Int64) -> Iter[T] {
  self.time += timestep
  Iter::new(fn(yield_) {
    loop self.queue.peek() {
      Some(top) => {
        if top._.0 > self.time {
          break
        }
        if yield_(top._.1) == IterEnd {
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
type Timed[T] (Int64, T)

///|
pub impl[T] Compare for Timed[T] with compare(self, other) -> Int {
  self._.0.compare(other._.0).op_neg() // less first
}

///|
pub impl[T] Eq for Timed[T] with op_equal(self, other) -> Bool {
  self._.0.op_equal(other._.0)
}
