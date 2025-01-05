///|
struct Module {
  change_job : (Int) -> Unit
}

///|
pub fn Module::new(change_job : (Int) -> Unit) -> Module {
  { change_job, }
}

///|
pub fn make_stat_handlers(
  self : Module
) -> Map[@maple_stat.Id, @game_mod.StatHandler] {
  [
    (
      @maple_stat.Id::JOB,
      fn(job_id) {
        (self.change_job)(job_id)
        false
      },
    ),
  ]
  |> Map::from_array
}
