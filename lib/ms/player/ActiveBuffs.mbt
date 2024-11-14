///| Define the ActiveBuff interface
trait ActiveBuff {
  apply_to(Self, CharStats, Int) -> Unit
}

///| Template for SimpleStatBuff
struct SimpleStatBuff {
  stat : @stat.Id
}

fn SimpleStatBuff::new(stat : @stat.Id) -> SimpleStatBuff {
  { stat, }
}

fn apply_to(self : SimpleStatBuff, stats : CharStats, value : Int) -> Unit {
  // stats.add_buff(self.stat, value)
}

// Template for PercentageStatBuff
struct PercentageStatBuff {
  stat : @stat.Id
}

fn PercentageStatBuff::new(stat : @stat.Id) -> PercentageStatBuff {
  { stat, }
}

fn apply_to(self : PercentageStatBuff, stats : CharStats, value : Int) -> Unit {
  // stats.add_percent(self.stat, Double::from_int(value) / 100.0)
}

// MapleWarriorBuff
type MapleWarriorBuff Unit derive(Default)

fn apply_to(self : MapleWarriorBuff, stats : CharStats, value : Int) -> Unit {
  // stats.add_percent(@stat.Id::STR, Double::from_int(value) / 100.0)
  // stats.add_percent(@stat.Id::DEX, Double::from_int(value) / 100.0)
  // stats.add_percent(@stat.Id::INT, Double::from_int(value) / 100.0)
  // stats.add_percent(@stat.Id::LUK, Double::from_int(value) / 100.0)
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
  buffs : @immut/sorted_map.T[@buff.StatId, ActiveBuff]
}

fn ActiveBuffs::new() -> ActiveBuffs {
  {
    buffs: @immut/sorted_map.from_array(
      [
        (@buff.StatId::MAPLE_WARRIOR, MapleWarriorBuff::default()),
        (@buff.StatId::STANCE, StanceBuff::default()),
        (@buff.StatId::BOOSTER, BoosterBuff::default()),
        (@buff.StatId::WATK, SimpleStatBuff::new(@stat.Id::WATK)),
        (@buff.StatId::WDEF, SimpleStatBuff::new(@stat.Id::WDEF)),
        (@buff.StatId::MATK, SimpleStatBuff::new(@stat.Id::MAGIC)),
        (@buff.StatId::MDEF, SimpleStatBuff::new(@stat.Id::MDEF)),
        (@buff.StatId::SPEED, SimpleStatBuff::new(@stat.Id::SPEED)),
        (@buff.StatId::JUMP, SimpleStatBuff::new(@stat.Id::JUMP)),
        (@buff.StatId::HYPERBODYHP, PercentageStatBuff::new(@stat.Id::HP)),
        (@buff.StatId::HYPERBODYMP, PercentageStatBuff::new(@stat.Id::MP)),
      ],
    ),
  }
}

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
