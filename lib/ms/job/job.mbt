pub enum Level {
  BEGINNER
  FIRST
  SECOND
  THIRD
  FOURTH
} derive(Eq)

pub fn int_value(self : Level) -> Int {
  match self {
    BEGINNER => 0
    FIRST => 1
    SECOND => 2
    THIRD => 3
    FOURTH => 4
  }
}

pub fn compare(self : Level, other : Level) -> Int {
  self.int_value().compare(other.int_value())
}

pub fn get_next_level(level : Level) -> Level {
  match level {
    BEGINNER => FIRST
    FIRST => SECOND
    SECOND => THIRD
    _ => FOURTH
  }
}

struct Job {
  name : String
  id : Int
  level : Level
}

pub fn Job::new(~id : Int = 0) -> Job {
  let name = get_name_by_id(id)
  let level = if id == 0 {
    Level::BEGINNER
  } else if id % 100 == 0 {
    Level::FIRST
  } else if id % 10 == 0 {
    Level::SECOND
  } else if id % 10 == 1 {
    Level::THIRD
  } else {
    Level::FOURTH
  }
  { name, id, level }
}

pub fn get_id(self : Job) -> Int {
  self.id
}

pub fn get_name(self : Job) -> String {
  self.name
}

fn get_name_by_id(jid : Int) -> String {
  match jid {
    0 => "Beginner"
    100 => "Swordsman"
    110 => "Fighter"
    111 => "Crusader"
    112 => "Hero"
    120 => "Page"
    121 => "White Knight"
    122 => "Paladin"
    130 => "Spearman"
    131 => "Dragon Knight"
    132 => "Dark Knight"
    200 => "Magician"
    210 => "Wizard (F/P)"
    211 => "Mage (F/P)"
    212 => "Archmage (F/P)"
    220 => "Wizard (I/L)"
    221 => "Mage (I/L)"
    222 => "Archmage (I/L)"
    230 => "Cleric"
    231 => "Priest"
    232 => "Bishop"
    300 => "Archer"
    310 => "Hunter"
    311 => "Ranger"
    312 => "Bowmaster"
    320 => "Crossbowman"
    321 => "Sniper"
    322 => "Marksman"
    400 => "Rogue"
    410 => "Assassin"
    411 => "Hermit"
    412 => "Nightlord"
    420 => "Bandit"
    421 => "Chief Bandit"
    422 => "Shadower"
    500 => "Pirate"
    510 => "Brawler"
    511 => "Marauder"
    512 => "Buccaneer"
    520 => "Gunslinger"
    521 => "Outlaw"
    522 => "Corsair"
    1000 => "Noblesse"
    2000 => ""
    2100 => ""
    2110 => ""
    2111 => ""
    2112 => "Aran"
    900 => "GM"
    910 => "SuperGM"
    _ => ""
  }
}

pub fn get_level(self : Job) -> Level {
  self.level
}

pub fn get_primary(self : Job, weapontype : @weapon.Type) -> @stat.Id {
  match self.id / 100 {
    2 => return @stat.Id::INT
    3 => return @stat.Id::DEX
    4 => return @stat.Id::LUK
    5 =>
      return if weapontype == @weapon.Type::GUN {
        @stat.Id::DEX
      } else {
        @stat.Id::STR
      }
    _ => return @stat.Id::STR
  }
}

pub fn get_secondary(self : Job, weapontype : @weapon.Type) -> @stat.Id {
  match self.id / 100 {
    2 => return @stat.Id::LUK
    3 => return @stat.Id::STR
    4 => return @stat.Id::DEX
    5 =>
      return if weapontype == @weapon.Type::GUN {
        @stat.Id::STR
      } else {
        @stat.Id::DEX
      }
    _ => return @stat.Id::DEX
  }
}

pub fn get_subjob(self : Job, level : Level) -> Int {
  if level <= self.level {
    match level {
      Level::BEGINNER => 0
      Level::FIRST => self.id / 100 * 100
      Level::SECOND => self.id / 10 * 10
      Level::THIRD => if level == Level::FOURTH { self.id - 1 } else { self.id }
      Level::FOURTH => self.id
    }
  } else {
    0
  }
}

pub fn can_use(self : Job, skill_id : Int) -> Bool {
  let required = skill_id / 10000
  self.is_sub_job(required)
}

pub fn is_sub_job(self : Job, subid : Int) -> Bool {
  for
    lv in [
      Level::BEGINNER,
      Level::FIRST,
      Level::SECOND,
      Level::THIRD,
      Level::FOURTH,
    ] {
    if subid == self.get_subjob(lv) {
      return true
    }
  }
  false
}
