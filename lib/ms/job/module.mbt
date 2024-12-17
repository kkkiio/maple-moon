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
) -> Map[@maple_stat.Id, (@maple_stat.Id, @net.InPacket) -> Bool!] {
  [
    (
      @maple_stat.Id::JOB,
      fn(_id, recv) {
        (self.change_job)(recv.read_ushort!())
        false
      },
    ),
  ]
  |> Map::from_array
}
