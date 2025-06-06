///|
struct Module {
  network : @net.Network
  stat_listeners : Map[MapleStatId, Array[(Int, Int) -> IterResult]]
  i64stat_listeners : Map[MapleStatId, Array[(Int64, Int64) -> IterResult]]
  total_listeners : Map[@maple_stat.EquipStatId, Array[(Int, Int) -> Bool]]
  mut player_char_stats : CharStats?
}

///|
pub fn Module::load(network : @net.Network) -> Module {
  Module::new(network)
}

///|
fn Module::new(network : @net.Network) -> Module {
  {
    network,
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
  job : @job.Job
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
pub fn make_stat_handlers(
  self : Module
) -> Map[@maple_stat.Id, @game_mod.StatHandler] {
  [
    @maple_stat.Id::LEVEL,
    @maple_stat.Id::STR,
    @maple_stat.Id::DEX,
    @maple_stat.Id::INT,
    @maple_stat.Id::LUK,
    @maple_stat.Id::HP,
    @maple_stat.Id::MAXHP,
    @maple_stat.Id::MP,
    @maple_stat.Id::MAXMP,
    @maple_stat.Id::AP,
    @maple_stat.Id::SP,
    @maple_stat.Id::EXP,
    @maple_stat.Id::FAME,
  ]
  .iter()
  .map(fn(stat_id) {
    (
      stat_id,
      fn(value) {
        guard self.player_char_stats is Some(char_stats) else { return false }
        match stat_id {
          @maple_stat.Id::LEVEL => {
            char_stats.set_stat(@maple_stat.Id::LEVEL, value)
            false
          }
          @maple_stat.Id::EXP => {
            char_stats.set_exp(value.to_int64())
            false
          }
          _ => {
            char_stats.set_stat(stat_id, value)
            true
          }
        }
      },
    )
  })
  |> Map::from_iter
}
