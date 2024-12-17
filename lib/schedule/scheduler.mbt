///|
struct Schedules {
  mut current_time : @utils.TimePoint
  scheduled_tasks : Array[ScheduledTask]
}

///|
struct ScheduledTask {
  mut next_time : @utils.TimePoint
  run : () -> Unit
  delay : @utils.Duration
}

///|
pub fn Schedules::new() -> Schedules {
  { current_time: @utils.TimePoint::default(), scheduled_tasks: [] }
}

///|
pub fn schedule_with_fixed_delay(
  self : Schedules,
  task : () -> Unit,
  initial_delay : @utils.Duration,
  delay : @utils.Duration
) -> () -> Unit {
  let scheduled_task = {
    next_time: self.current_time.add_duration(initial_delay),
    run: task,
    delay,
  }
  self.scheduled_tasks.push(scheduled_task)
  fn() {
    match
      self.scheduled_tasks.search_by(fn(t) { physical_equal(t, scheduled_task) }) {
      None => ()
      Some(i) => self.scheduled_tasks.remove(i) |> ignore
    }
  }
}

///|
pub fn update(self : Schedules, timestep : @utils.Duration) -> Unit {
  self.current_time = self.current_time.add_duration(timestep)
  for task in self.scheduled_tasks {
    if self.current_time >= task.next_time {
      (task.run)()
      task.next_time = self.current_time.add_duration(task.delay)
    }
  }
}
