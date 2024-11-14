pub enum Potential {
  POT_NONE
  POT_HIDDEN
  POT_RARE
  POT_EPIC
  POT_UNIQUE
  POT_LEGENDARY
}

pub fn int_value(pot : Potential) -> Int {
  match pot {
    POT_NONE => 0
    POT_HIDDEN => 1
    POT_RARE => 2
    POT_EPIC => 3
    POT_UNIQUE => 4
    POT_LEGENDARY => 5
  }
}

pub struct Equip {
  stats : Map[@stat.Id, Int]
  item_id : Int
  expiration : Int64
  owner : String
  flags : Int
  slots : Int
  level : Int
  item_level : Int
  vicious : Int
  potential_rank : Potential
  // quality : @quality.Id
}

pub fn check_quality(
  data : EquipData,
  scrolled : Bool,
  stats : Map[@stat.Id, Int]
) -> @quality.Id {
  let mut delta = 0
  for es, stat in stats {
    let defstat = data.get_defstat(es)
    let defstat = data.get_defstat(es)
    delta += stat - defstat
  }
  if delta < -5 {
    return if scrolled { @quality.Id::ORANGE } else { @quality.Id::GREY }
  }
  if delta < 7 {
    return if scrolled { @quality.Id::ORANGE } else { @quality.Id::WHITE }
  }
  if delta < 14 {
    return @quality.Id::BLUE
  }
  if delta < 21 {
    return @quality.Id::VIOLET
  }
  return @quality.Id::GOLD
}
