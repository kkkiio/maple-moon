///| Define the ActiveBuff interface
trait ActiveBuff {
  apply_to(Self, CharStats, Int) -> Unit
}

///| Template for SimpleStatBuff
struct SimpleStatBuff {
  stat : @maple_stat.EquipStatId
}

///|
fn SimpleStatBuff::new(stat : @maple_stat.EquipStatId) -> SimpleStatBuff {
  { stat, }
}

///|
pub impl ActiveBuff for SimpleStatBuff with apply_to(
  self : SimpleStatBuff,
  stats : CharStats,
  value : Int
) -> Unit {
  // stats.add_buff(self.stat, value)
}

// Template for PercentageStatBuff
///|
struct PercentageStatBuff {
  stat : @maple_stat.EquipStatId
}

///|
fn PercentageStatBuff::new(
  stat : @maple_stat.EquipStatId
) -> PercentageStatBuff {
  { stat, }
}

///|
pub impl ActiveBuff for PercentageStatBuff with apply_to(
  self : PercentageStatBuff,
  stats : CharStats,
  value : Int
) -> Unit {
  // stats.add_percent(self.stat, Double::from_int(value) / 100.0)
}

// MapleWarriorBuff
///|
type MapleWarriorBuff Unit derive(Default)

///|
pub impl ActiveBuff for MapleWarriorBuff with apply_to(
  self : MapleWarriorBuff,
  stats : CharStats,
  value : Int
) -> Unit {
  // stats.add_percent(@stat.Id::STR, Double::from_int(value) / 100.0)
  // stats.add_percent(@stat.Id::DEX, Double::from_int(value) / 100.0)
  // stats.add_percent(@stat.Id::INT, Double::from_int(value) / 100.0)
  // stats.add_percent(@stat.Id::LUK, Double::from_int(value) / 100.0)
}

// StanceBuff
///|
type StanceBuff Unit derive(Default)

///|
pub impl ActiveBuff for StanceBuff with apply_to(
  self : StanceBuff,
  stats : CharStats,
  value : Int
) -> Unit {
  // stats.set_stance(Double::from_int(value) / 100.0)
}

// BoosterBuff
///|
type BoosterBuff Unit derive(Default)

///|
pub impl ActiveBuff for BoosterBuff with apply_to(
  self : BoosterBuff,
  stats : CharStats,
  value : Int
) -> Unit {
  // stats.set_attackspeed(value)
}

// ActiveBuffs
///|
struct ActiveBuffs {
  buffs : @immut/sorted_map.T[@buff.StatId, &ActiveBuff]
}

///|
fn ActiveBuffs::new() -> ActiveBuffs {
  {
    buffs: @immut/sorted_map.from_array([
      (@buff.StatId::MAPLE_WARRIOR, MapleWarriorBuff::default()),
      (@buff.StatId::STANCE, StanceBuff::default()),
      (@buff.StatId::BOOSTER, BoosterBuff::default()),
      (@buff.StatId::WATK, SimpleStatBuff::new(@maple_stat.EquipStatId::WATK)),
      (@buff.StatId::WDEF, SimpleStatBuff::new(@maple_stat.EquipStatId::WDEF)),
      (@buff.StatId::MATK, SimpleStatBuff::new(@maple_stat.EquipStatId::MAGIC)),
      (@buff.StatId::MDEF, SimpleStatBuff::new(@maple_stat.EquipStatId::MDEF)),
      (@buff.StatId::SPEED, SimpleStatBuff::new(@maple_stat.EquipStatId::SPEED)),
      (@buff.StatId::JUMP, SimpleStatBuff::new(@maple_stat.EquipStatId::JUMP)),
      (
        @buff.StatId::HYPERBODYHP,
        PercentageStatBuff::new(@maple_stat.EquipStatId::HP),
      ),
      (
        @buff.StatId::HYPERBODYMP,
        PercentageStatBuff::new(@maple_stat.EquipStatId::MP),
      ),
    ]),
  }
}

///|
fn apply_buff(
  self : ActiveBuffs,
  stats : CharStats,
  stat : @buff.StatId,
  value : Int
) -> Unit {
  match self.buffs[stat] {
    Some(buff) => buff.apply_to(stats, value)
    None => ()
  }
}
