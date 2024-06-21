pub struct CharStats {
  base_stats : Map[@MapleStat.Id, Int]
  total_stats : Map[@EquipStat.Id, Int]
}

pub fn CharStats::from_entry(s : StatsEntry) -> CharStats {
  let cs = { base_stats: s.stats, total_stats: Map::new() }
  cs.init_totalstats()
  cs
}

pub fn CharStats::default() -> CharStats {
  { base_stats: Map::new(), total_stats: Map::new() }
}

pub fn init_totalstats(self : CharStats) -> Unit {
  self.total_stats.clear()
  // buff_deltas_.clear();
  // percentages_.clear();

  self.total_stats.set(@EquipStat.Id::HP, self.get_stat(@MapleStat.Id::MAXHP))
  self.total_stats.set(@EquipStat.Id::MP, self.get_stat(@MapleStat.Id::MAXMP))
  self.total_stats.set(@EquipStat.Id::STR, self.get_stat(@MapleStat.Id::STR))
  self.total_stats.set(@EquipStat.Id::DEX, self.get_stat(@MapleStat.Id::DEX))
  self.total_stats.set(@EquipStat.Id::INT, self.get_stat(@MapleStat.Id::INT))
  self.total_stats.set(@EquipStat.Id::LUK, self.get_stat(@MapleStat.Id::LUK))
  self.total_stats.set(@EquipStat.Id::SPEED, 100)
  self.total_stats.set(@EquipStat.Id::JUMP, 100)

  // max_damage_ = 0;
  // min_damage_ = 0;
  // honor_ = 0;
  // attack_speed_ = 0;
  // projectile_range_ = 400;
  // mastery_ = 0.0f;
  // critical_ = 0.05f;
  // min_crit_ = 0.5f;
  // max_crit_ = 0.75f;
  // damage_percent_ = 0.0f;
  // boss_dmg_ = 0.0f;
  // ignore_def_ = 0.0f;
  // stance_ = 0.0f;
  // resist_status_ = 0.0f;
  // reduce_damage_ = 0.0f;

}

pub fn get_total(self : CharStats, stat : @EquipStat.Id) -> Int {
  self.total_stats[stat].or(0)
}

pub fn get_stat(self : CharStats, stat : @MapleStat.Id) -> Int {
  self.base_stats[stat].or(0)
}
