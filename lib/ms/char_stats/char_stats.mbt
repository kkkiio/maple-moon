///|
struct CharStats {
  name : String
  weapon_type_getter : () -> @weapon.Type
  mut job : @job.Job
  mut map_id : Int
  portal : Int
  base_stats : Map[@maple_stat.Id, Int]
  base_i64stats : Map[@maple_stat.Id, Int64]
  total_stats : @utils.Counter[@equip_stat.Id, Int]
  buff_deltas : @utils.Counter[@equip_stat.Id, Int]
  percentages : Map[@equip_stat.Id, Double]
  mut attack_speed : Int
  mut projectile_range : Int
  mut critical : Double
  mut max_damage : Int
  mut min_damage : Int
  mut mastery : Double
  mut damage_percent : Double
  mut ignore_def : Double
  mut stance : Double
  mut reduce_damage : Double
  female : Bool
  stat_listeners : Map[StatId, Array[(Int, Int) -> IterResult]]
  i64stat_listeners : Map[@maple_stat.Id, Array[(Int64, Int64) -> IterResult]]
}

///|
pub(all) struct StatsEntry {
  name : String
  female : Bool
  stats : Map[@maple_stat.Id, Int]
  i64stats : Map[@maple_stat.Id, Int64]
  mapid : Int
  portal : Int
} derive(Show)

///|
pub fn CharStats::new(
  s : StatsEntry,
  weapon_type_getter : () -> @weapon.Type,
  job : @job.Job
) -> CharStats {
  let cs : CharStats = {
    name: s.name,
    weapon_type_getter,
    job,
    map_id: s.mapid,
    portal: s.portal,
    base_stats: s.stats,
    base_i64stats: s.i64stats,
    total_stats: @utils.Counter::new(),
    buff_deltas: @utils.Counter::new(),
    percentages: Map::new(),
    attack_speed: 0,
    projectile_range: 400,
    critical: 0.05,
    max_damage: 0,
    min_damage: 0,
    mastery: 0.0,
    damage_percent: 0.0,
    ignore_def: 0.0,
    stance: 0.0,
    reduce_damage: 0.0,
    female: s.female,
    stat_listeners: {},
    i64stat_listeners: {},
  }
  cs.init_totalstats()
  cs
}

///|
pub fn init_totalstats(self : CharStats) -> Unit {
  self.total_stats._.clear()
  self.buff_deltas._.clear()
  self.percentages.clear()
  self.total_stats._.set(
    @equip_stat.Id::HP,
    self.get_stat(@maple_stat.Id::MAXHP),
  )
  self.total_stats._.set(
    @equip_stat.Id::MP,
    self.get_stat(@maple_stat.Id::MAXMP),
  )
  self.total_stats._.set(
    @equip_stat.Id::STR,
    self.get_stat(@maple_stat.Id::STR),
  )
  self.total_stats._.set(
    @equip_stat.Id::DEX,
    self.get_stat(@maple_stat.Id::DEX),
  )
  self.total_stats._.set(
    @equip_stat.Id::INT,
    self.get_stat(@maple_stat.Id::INT),
  )
  self.total_stats._.set(
    @equip_stat.Id::LUK,
    self.get_stat(@maple_stat.Id::LUK),
  )
  self.total_stats._.set(@equip_stat.Id::SPEED, 100)
  self.total_stats._.set(@equip_stat.Id::JUMP, 100)
  self.max_damage = 0
  self.min_damage = 0
  // honor_ = 0;
  self.attack_speed = 0
  self.projectile_range = 400
  self.mastery = 0.0
  self.critical = 0.05
  // min_crit_ = 0.5f;
  // max_crit_ = 0.75f;
  self.damage_percent = 0.0
  // boss_dmg_ = 0.0f;
  self.ignore_def = 0.0
  self.stance = 0.0
  // resist_status_ = 0.0f;
  self.reduce_damage = 0.0
}

///|
pub fn get_total(self : CharStats, stat : @equip_stat.Id) -> Int {
  self.total_stats[stat]
}

///|
pub fn get_stat(self : CharStats, stat : @maple_stat.Id) -> Int {
  self.base_stats[stat].or(0)
}

///|
pub fn get_i64stat(self : CharStats, stat : @maple_stat.Id) -> Int64 {
  self.base_i64stats[stat].or(0)
}

///|
pub fn set_stat(self : CharStats, stat : @maple_stat.Id, value : Int) -> Unit {
  let old_value = self.get_stat(stat)
  self.base_stats.set(stat, value)
  match self.stat_listeners.get(stat) {
    Some(listeners) =>
      listeners.retain(fn(listener) {
        match listener(old_value, value) {
          IterResult::IterEnd => false
          IterResult::IterContinue => true
        }
      })
    None => ()
  }
}

///|
pub fn set_i64stat(
  self : CharStats,
  stat : @maple_stat.Id,
  value : Int64
) -> Unit {
  let old_value = self.get_i64stat(stat)
  self.base_i64stats.set(stat, value)
}

///|
pub fn get_stance(self : CharStats) -> Double {
  self.stance
}

///|
pub fn get_portal(self : CharStats) -> Int {
  self.portal
}

///|
pub fn get_map_id(self : CharStats) -> Int {
  self.map_id
}

///|
pub fn set_map_id(self : CharStats, id : Int) -> Unit {
  self.map_id = id
}

///|
pub fn add_value(self : CharStats, stat : @equip_stat.Id, value : Int) -> Unit {
  let current = self.get_total(stat)
  self.set_total(stat, current + value)
}

///|
pub fn set_total(self : CharStats, stat : @equip_stat.Id, value : Int) -> Unit {
  self.total_stats[stat] = match eqstat_caps.get(stat) {
    Some(cap_value) => if value > cap_value { cap_value } else { value }
    None => value
  }
}

///|
pub fn close_totalstats(self : CharStats) -> Unit {
  self.total_stats[@equip_stat.Id::ACC] += self.calculate_accuracy()
  for stat, p in self.percentages {
    let total = self.get_total(stat)
    let total = total + (total.to_double() * p).to_int()
    self.set_total(stat, total)
  }
  let primary = self.get_primary_stat()
  let secondary = self.get_secondary_stat()
  let attack = self.get_total(@equip_stat.Id::WATK)
  let multiplier = self.damage_percent + attack.to_double() / 100
  self.max_damage = ((primary + secondary).to_double() * multiplier).to_int()
  self.min_damage = ((
    primary.to_double() * 0.9 * self.mastery + secondary.to_double()
  ) *
  multiplier).to_int()
}

///|
fn get_primary_stat(self : CharStats) -> Int {
  let primary = self.job.get_primary(self.get_weapon_type())
  return (self.get_multiplier() * self.get_total(primary).to_double()).to_int()
}

///|
fn get_secondary_stat(self : CharStats) -> Int {
  let secondary = self.job.get_secondary(self.get_weapon_type())
  return self.get_total(secondary)
}

///|
fn calculate_accuracy(self : CharStats) -> Int {
  let totaldex = self.get_total(@equip_stat.Id::DEX)
  let totalluk = self.get_total(@equip_stat.Id::LUK)
  return (totaldex.to_double() * 0.8 + totalluk.to_double() * 0.5).to_int()
}

///|
fn get_multiplier(self : CharStats) -> Double {
  match self.get_weapon_type() {
    @weapon.Type::SWORD_1H => 4.0
    @weapon.Type::AXE_1H => 4.0
    @weapon.Type::MACE_1H => 4.0
    @weapon.Type::WAND => 4.0
    @weapon.Type::STAFF => 4.0
    @weapon.Type::DAGGER => 3.6
    @weapon.Type::CROSSBOW => 3.6
    @weapon.Type::CLAW => 3.6
    @weapon.Type::GUN => 3.6
    @weapon.Type::SWORD_2H => 4.6
    @weapon.Type::AXE_2H => 4.6
    @weapon.Type::MACE_2H => 4.6
    @weapon.Type::KNUCKLE => 4.8
    @weapon.Type::SPEAR => 5.0
    @weapon.Type::POLEARM => 5.0
    @weapon.Type::BOW => 3.4
    _ => 0.0
  }
}

///| Externalising this for easier configurability.
let eqstat_caps : Map[@equip_stat.Id, Int] = Map::from_array([
  (@equip_stat.Id::STR, 999),
  (@equip_stat.Id::DEX, 999),
  (@equip_stat.Id::INT, 999),
  (@equip_stat.Id::LUK, 999),
  (@equip_stat.Id::HP, 30000),
  (@equip_stat.Id::MP, 30000),
  (@equip_stat.Id::WATK, 999),
  (@equip_stat.Id::MAGIC, 2000),
  (@equip_stat.Id::WDEF, 999),
  (@equip_stat.Id::MDEF, 999),
  (@equip_stat.Id::ACC, 999),
  (@equip_stat.Id::AVOID, 999),
  (@equip_stat.Id::HANDS, 999),
  (@equip_stat.Id::SPEED, 140),
  (@equip_stat.Id::JUMP, 123),
])

///|
pub fn calculate_damage(self : CharStats, mobatk : Int) -> Int {
  // TODO: Random stuff, need to find the actual formula somewhere.
  let weapon_def = self.get_total(@equip_stat.Id::WDEF)
  if weapon_def == 0 {
    return mobatk
  }
  let reduceatk = mobatk / 2 + mobatk / weapon_def
  reduceatk - (reduceatk.to_double() * self.reduce_damage).to_int()
}

///|
pub fn get_maxdamage(self : CharStats) -> Int {
  self.max_damage
}

///|
pub fn get_mindamage(self : CharStats) -> Int {
  self.min_damage
}

///|
pub fn get_critical(self : CharStats) -> Double {
  self.critical
}

///|
pub fn get_ignoredef(self : CharStats) -> Double {
  self.ignore_def
}

///|
pub fn get_range(self : CharStats) -> @struct.Rectangle[Int] {
  @struct.Rectangle::from4(-self.projectile_range, -5, -50, 50)
}

///|
pub fn get_attackspeed(self : CharStats) -> Int {
  self.attack_speed
}

///|
pub fn get_job(self : CharStats) -> @job.Job {
  self.job
}

///|
pub fn get_weapon_type(self : CharStats) -> @weapon.Type {
  (self.weapon_type_getter)()
}

///|
pub fn get_exp(self : CharStats) -> Int64 {
  self.get_i64stat(@maple_stat.Id::EXP)
}

///|
pub fn set_exp(self : CharStats, exp : Int64) -> Unit {
  self.set_i64stat(@maple_stat.Id::EXP, exp)
}

///|
pub fn get_female(self : CharStats) -> Bool {
  self.female
}

///|
pub fn get_buffdelta(self : CharStats, stat : @equip_stat.Id) -> Int {
  self.buff_deltas[stat]
}

///|
pub fn get_name(self : CharStats) -> String {
  self.name
}

///|
pub fn is_damage_buffed(self : CharStats) -> Bool {
  self.get_buffdelta(@equip_stat.Id::WATK) > 0 ||
  self.get_buffdelta(@equip_stat.Id::MAGIC) > 0
}

///|
pub fn change_job(self : CharStats, job : @job.Job) -> Unit {
  self.job = job
}

///|
pub fn get_matk(self : CharStats) -> Int {
  self.total_stats[@equip_stat.MAGIC]
}

///| Watch for stat changes
/// 
/// The `listener` will be called when the stat changes.
pub fn watch_stat_changes(
  self : CharStats,
  stat_id : StatId,
  trigger_now~ : Bool = false,
  listener : (Int, Int) -> IterResult
) -> Unit {
  if trigger_now {
    let v = self.get_stat(stat_id)
    match listener(v, v) {
      IterResult::IterEnd => return
      IterResult::IterContinue => ()
    }
  }
  self.stat_listeners.get_or_init(stat_id, fn() { Array::new() }).push(listener)
}

///|
pub fn listen_i64stat_changes(
  self : CharStats,
  stat_id : @maple_stat.Id,
  listener : (Int64, Int64) -> IterResult
) -> Unit {
  self.i64stat_listeners
  .get_or_init(stat_id, fn() { Array::new() })
  .push(listener)
}
