struct TimedQueue[T] {
  queue : @priority_queue.T[Timed[T]]
  mut time : Int64
}

pub fn TimedQueue::new[T]() -> TimedQueue[T] {
  { queue: @priority_queue.new(), time: 0 }
}

pub fn push[T](self : TimedQueue[T], delay : Int64, t : T) -> Unit {
  self.queue.push((delay, t))
}

pub fn update[T](
  self : TimedQueue[T],
  action : (T) -> Unit,
  ~timestep : Int64 = @constants.timestep.to_int64()
) -> Unit {
  self.time += timestep
  loop self.queue.peek() {
    Some(top) => {
      if top._.0 > self.time {
        break
      }
      action(top._.1)
      self.queue.pop() |> ignore
      continue self.queue.peek()
    }
    None => break
  }
}

type Timed[T] (Int64, T)

pub fn compare[T](self : Timed[T], other : Timed[T]) -> Int {
  self._.0.compare(other._.0).op_neg() // less first
}

pub fn op_equal[T](self : Timed[T], other : Timed[T]) -> Bool {
  self._.0.op_equal(other._.0)
}
