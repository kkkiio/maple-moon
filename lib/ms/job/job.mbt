///|
pub(all) enum Level {
  BEGINNER
  FIRST
  SECOND
  THIRD
  FOURTH
}

///|
pub fn int_value(self : Level) -> Int {
  match self {
    BEGINNER => 0
    FIRST => 1
    SECOND => 2
    THIRD => 3
    FOURTH => 4
  }
}

///|
pub impl Eq for Level with op_equal(self : Level, other : Level) -> Bool {
  self.int_value() == other.int_value()
}

///|
pub impl Compare for Level with compare(self : Level, other : Level) -> Int {
  self.int_value().compare(other.int_value())
}

///|
pub impl Hash for Level with hash_combine(self : Level, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

///|
let all_levels : Array[Level] = [BEGINNER, FIRST, SECOND, THIRD, FOURTH]

///|
pub fn get_levels(upto~ : Level = FOURTH) -> Iter[Level] {
  all_levels.iter().take_while(fn(level) { level <= upto })
}

///|
pub fn get_next_level(level : Level) -> Level {
  match level {
    BEGINNER => FIRST
    FIRST => SECOND
    SECOND => THIRD
    _ => FOURTH
  }
}

///|
struct Job {
  name : String
  id : Int
  level : Level
  sub_job_data_map : Map[Int, JobData]
}

///|
pub fn Job::load(id~ : Int = 0) -> @utils.Future[Job] {
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
  let subids = get_levels(upto=level).map(fn(sub_level) {
    get_subjob_id(id, level, sub_level)
  })
  // Load all subjob data in parallel
  @utils.Future::all_of(
    subids
    .iter()
    .map(fn(subid) { JobData::load(subid).map(fn(data) { (subid, data) }) })
    |> Array::from_iter,
  ).map(fn(data_list) {
    let sub_job_data_map = Map::new()
    for _, it in data_list {
      let (subid, data) = it
      sub_job_data_map[subid] = data
    }
    Job::new(id, level, sub_job_data_map)
  })
}

///|
pub fn Job::new(
  id : Int,
  level : Level,
  sub_job_data_map : Map[Int, JobData]
) -> Job {
  let name = get_name_by_id(id)
  { name, id, level, sub_job_data_map }
}

///|
pub fn get_id(self : Job) -> Int {
  self.id
}

///|
pub fn get_name(self : Job) -> String {
  self.name
}

///|
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

///|
pub fn get_level(self : Job) -> Level {
  self.level
}

///|
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

///|
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

///|
pub fn get_subjob(self : Job, level : Level) -> Int {
  get_subjob_id(self.id, self.level, level)
}

///|
pub fn get_subjob_id(
  job_id : Int,
  now_level : Level,
  target_level : Level
) -> Int {
  if target_level <= now_level {
    match target_level {
      Level::BEGINNER => 0
      Level::FIRST => job_id / 100 * 100
      Level::SECOND => job_id / 10 * 10
      Level::THIRD =>
        if now_level == Level::FOURTH {
          job_id - 1
        } else {
          job_id
        }
      Level::FOURTH => job_id
    }
  } else {
    0
  }
}

///|
pub fn get_all_subjobs(self : Job) -> Iter[JobData] {
  self.sub_job_data_map.values()
}

///|
pub fn can_use(self : Job, skill_id : Int) -> Bool {
  let required = skill_id / 10000
  self.is_sub_job(required)
}

///|
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

///|
pub fn get_data_by_id(self : Job, subid : Int) -> JobData {
  self.sub_job_data_map.get(subid).unwrap() // TODO: handle error
}
