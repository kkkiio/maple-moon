///|
struct Module {
  stat_listeners : Map[MapleStatId, Array[(Int, Int) -> Bool]]
  i64stat_listeners : Map[MapleStatId, Array[(Int64, Int64) -> Bool]]
  total_listeners : Map[@maple_stat.EquipStatId, Array[(Int, Int) -> Bool]]
  mut player_char_stats : CharStats?
}

///|
pub fn Module::load() -> Module {
  Module::new()
}

///|
fn Module::new() -> Module {
  {
    stat_listeners: Map::new(),
    i64stat_listeners: Map::new(),
    total_listeners: Map::new(),
    player_char_stats: None,
  }
}

///|
pub fn Module::new_char_stats(
  self : Module,
  s : StatsEntry,
  weapon_type_getter : () -> @weapon.Type,
  job : @job.Job,
) -> CharStats {
  let stats = CharStats::new(
    s,
    weapon_type_getter,
    job,
    self.stat_listeners,
    self.i64stat_listeners,
    self.total_listeners,
  )
  self.player_char_stats = Some(stats)
  stats
}

///|
