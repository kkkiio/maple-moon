struct CharStats {
  job : @job.Job
  mut map_id : Int
  portal : Int
  base_stats : Map[@MapleStat.Id, Int]
  total_stats : @utils.Counter[@stat.Id]
  percentages : Map[@stat.Id, Double]
  mut weapon_type : @Weapon.Type
  mut max_damage : Int
  mut min_damage : Int
  mut mastery : Double
  mut damage_percent : Double
  mut stance : Double
  mut reduce_damage : Double
}

pub fn CharStats::from_entry(s : @login.StatsEntry) -> CharStats {
  let job = s.stats[@MapleStat.Id::JOB].or(0) |> @job.Job::from_id
  let cs = {
    job,
    map_id: s.mapid,
    portal: s.portal,
    base_stats: s.stats,
    total_stats: @utils.Counter::new(),
    percentages: Map::new(),
    weapon_type: @Weapon.Type::NONE,
    max_damage: 0,
    min_damage: 0,
    mastery: 0.0,
    damage_percent: 0.0,
    stance: 0.0,
    reduce_damage: 0.0,
  }
  cs.init_totalstats()
  cs
}

pub fn init_totalstats(self : CharStats) -> Unit {
  self.total_stats._.clear()
  // buff_deltas_.clear();
  self.percentages.clear()
  self.total_stats._.set(@stat.Id::HP, self.get_stat(@MapleStat.Id::MAXHP))
  self.total_stats._.set(@stat.Id::MP, self.get_stat(@MapleStat.Id::MAXMP))
  self.total_stats._.set(@stat.Id::STR, self.get_stat(@MapleStat.Id::STR))
  self.total_stats._.set(@stat.Id::DEX, self.get_stat(@MapleStat.Id::DEX))
  self.total_stats._.set(@stat.Id::INT, self.get_stat(@MapleStat.Id::INT))
  self.total_stats._.set(@stat.Id::LUK, self.get_stat(@MapleStat.Id::LUK))
  self.total_stats._.set(@stat.Id::SPEED, 100)
  self.total_stats._.set(@stat.Id::JUMP, 100)
  self.max_damage = 0
  self.min_damage = 0
  // honor_ = 0;
  // attack_speed_ = 0;
  // projectile_range_ = 400;
  self.mastery = 0.0
  // critical_ = 0.05f;
  // min_crit_ = 0.5f;
  // max_crit_ = 0.75f;
  self.damage_percent = 0.0
  // boss_dmg_ = 0.0f;
  // ignore_def_ = 0.0f;
  self.stance = 0.0
  // resist_status_ = 0.0f;
  self.reduce_damage = 0.0
}

pub fn get_total(self : CharStats, stat : @stat.Id) -> Int {
  self.total_stats[stat]
}

pub fn get_stat(self : CharStats, stat : @MapleStat.Id) -> Int {
  self.base_stats[stat].or(0)
}

pub fn set_stat(self : CharStats, stat : @MapleStat.Id, value : Int) -> Unit {
  self.base_stats.set(stat, value)
}

pub fn get_stance(self : CharStats) -> Double {
  self.stance
}

fn set_mapid(self : CharStats, id : Int) -> Unit {
  self.map_id = id
}

fn set_weapontype(self : CharStats, w : @Weapon.Type) -> Unit {
  self.weapon_type = w
}

pub fn add_value(self : CharStats, stat : @stat.Id, value : Int) -> Unit {
  let current = self.get_total(stat)
  self.set_total(stat, current + value)
}

pub fn set_total(self : CharStats, stat : @stat.Id, value : Int) -> Unit {
  self.total_stats[stat] = match eqstat_caps.get(stat) {
    Some(cap_value) => if value > cap_value { cap_value } else { value }
    None => value
  }
}

pub fn close_totalstats(self : CharStats) -> Unit {
  self.total_stats[@stat.Id::ACC] += self.calculate_accuracy()
  for stat, p in self.percentages {
    let total = self.get_total(stat)
    let total = total + (total.to_double() * p).to_int()
    self.set_total(stat, total)
  }
  let primary = self.get_primary_stat()
  let secondary = self.get_secondary_stat()
  let attack = self.get_total(@stat.Id::WATK)
  let multiplier = self.damage_percent + attack.to_double() / 100
  self.max_damage = ((primary + secondary).to_double() * multiplier).to_int()
  self.min_damage = ((
    primary.to_double() * 0.9 * self.mastery + secondary.to_double()
  ) *
  multiplier).to_int()
}

fn get_primary_stat(self : CharStats) -> Int {
  let primary = self.job.get_primary(self.weapon_type)
  return (self.get_multiplier() * self.get_total(primary).to_double()).to_int()
}

fn get_secondary_stat(self : CharStats) -> Int {
  let secondary = self.job.get_secondary(self.weapon_type)
  return self.get_total(secondary)
}

fn calculate_accuracy(self : CharStats) -> Int {
  let totaldex = self.get_total(@stat.Id::DEX)
  let totalluk = self.get_total(@stat.Id::LUK)
  return (totaldex.to_double() * 0.8 + totalluk.to_double() * 0.5).to_int()
}

fn get_multiplier(self : CharStats) -> Double {
  match self.weapon_type {
    @Weapon.Type::SWORD_1H => 4.0
    @Weapon.Type::AXE_1H => 4.0
    @Weapon.Type::MACE_1H => 4.0
    @Weapon.Type::WAND => 4.0
    @Weapon.Type::STAFF => 4.0
    @Weapon.Type::DAGGER => 3.6
    @Weapon.Type::CROSSBOW => 3.6
    @Weapon.Type::CLAW => 3.6
    @Weapon.Type::GUN => 3.6
    @Weapon.Type::SWORD_2H => 4.6
    @Weapon.Type::AXE_2H => 4.6
    @Weapon.Type::MACE_2H => 4.6
    @Weapon.Type::KNUCKLE => 4.8
    @Weapon.Type::SPEAR => 5.0
    @Weapon.Type::POLEARM => 5.0
    @Weapon.Type::BOW => 3.4
    _ => 0.0
  }
}

/// Externalising this for easier configurability.
let eqstat_caps : Map[@stat.Id, Int] = Map::from_array(
  [
    (@stat.Id::STR, 999),
    (@stat.Id::DEX, 999),
    (@stat.Id::INT, 999),
    (@stat.Id::LUK, 999),
    (@stat.Id::HP, 30000),
    (@stat.Id::MP, 30000),
    (@stat.Id::WATK, 999),
    (@stat.Id::MAGIC, 2000),
    (@stat.Id::WDEF, 999),
    (@stat.Id::MDEF, 999),
    (@stat.Id::ACC, 999),
    (@stat.Id::AVOID, 999),
    (@stat.Id::HANDS, 999),
    (@stat.Id::SPEED, 140),
    (@stat.Id::JUMP, 123),
  ],
)

pub fn calculate_damage(self : CharStats, mobatk : Int) -> Int {
  // TODO: Random stuff, need to find the actual formula somewhere.
  let weapon_def = self.get_total(@stat.Id::WDEF)
  if weapon_def == 0 {
    return mobatk
  }
  let reduceatk = mobatk / 2 + mobatk / weapon_def
  reduceatk - (reduceatk.to_double() * self.reduce_damage).to_int()
}
