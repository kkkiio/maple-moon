// Define the ActiveBuff interface
trait ActiveBuff {
  apply_to(Self, CharStats, Int) -> Unit
}

// Template for SimpleStatBuff
struct SimpleStatBuff {
  stat : @EquipStat.Id
}

fn SimpleStatBuff::new(stat : @EquipStat.Id) -> SimpleStatBuff {
  { stat, }
}

fn apply_to(self : SimpleStatBuff, stats : CharStats, value : Int) -> Unit {
  // stats.add_buff(self.stat, value)
}

// Template for PercentageStatBuff
struct PercentageStatBuff {
  stat : @EquipStat.Id
}

fn PercentageStatBuff::new(stat : @EquipStat.Id) -> PercentageStatBuff {
  { stat, }
}

fn apply_to(self : PercentageStatBuff, stats : CharStats, value : Int) -> Unit {
  // stats.add_percent(self.stat, Double::from_int(value) / 100.0)
}

// MapleWarriorBuff
type MapleWarriorBuff Unit derive(Default)

fn apply_to(self : MapleWarriorBuff, stats : CharStats, value : Int) -> Unit {
  // stats.add_percent(@EquipStat.Id::STR, Double::from_int(value) / 100.0)
  // stats.add_percent(@EquipStat.Id::DEX, Double::from_int(value) / 100.0)
  // stats.add_percent(@EquipStat.Id::INT, Double::from_int(value) / 100.0)
  // stats.add_percent(@EquipStat.Id::LUK, Double::from_int(value) / 100.0)
}

// StanceBuff
type StanceBuff Unit derive(Default)

fn apply_to(self : StanceBuff, stats : CharStats, value : Int) -> Unit {
  // stats.set_stance(Double::from_int(value) / 100.0)
}

// BoosterBuff
type BoosterBuff Unit derive(Default)

fn apply_to(self : BoosterBuff, stats : CharStats, value : Int) -> Unit {
  // stats.set_attackspeed(value)
}

// ActiveBuffs
struct ActiveBuffs {
  buffs : EnumMap[@Buffstat.Id, ActiveBuff]
}

fn ActiveBuffs::new() -> ActiveBuffs {
  let buffs : EnumMap[@Buffstat.Id, ActiveBuff] = EnumMap::make(
    @Buffstat.values,
  )
  buffs[@Buffstat.Id::MAPLE_WARRIOR] = MapleWarriorBuff::default()
  buffs[@Buffstat.Id::STANCE] = StanceBuff::default()
  buffs[@Buffstat.Id::BOOSTER] = BoosterBuff::default()
  buffs[@Buffstat.Id::WATK] = SimpleStatBuff::new(@EquipStat.Id::WATK)
  buffs[@Buffstat.Id::WDEF] = SimpleStatBuff::new(@EquipStat.Id::WDEF)
  buffs[@Buffstat.Id::MATK] = SimpleStatBuff::new(@EquipStat.Id::MAGIC)
  buffs[@Buffstat.Id::MDEF] = SimpleStatBuff::new(@EquipStat.Id::MDEF)
  buffs[@Buffstat.Id::SPEED] = SimpleStatBuff::new(@EquipStat.Id::SPEED)
  buffs[@Buffstat.Id::JUMP] = SimpleStatBuff::new(@EquipStat.Id::JUMP)
  buffs[@Buffstat.Id::HYPERBODYHP] = PercentageStatBuff::new(@EquipStat.Id::HP)
  buffs[@Buffstat.Id::HYPERBODYMP] = PercentageStatBuff::new(@EquipStat.Id::MP)
  { buffs, }
}

fn apply_buff(
  self : ActiveBuffs,
  stats : CharStats,
  stat : @Buffstat.Id,
  value : Int
) -> Unit {
  match self.buffs[stat] {
    Some(buff) => buff.apply_to(stats, value)
  }
}
