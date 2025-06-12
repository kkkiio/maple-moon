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
  id : JobId
  level : Level
  sub_job_data_map : Map[Int, JobData]
}

///|
pub fn Job::load(
  string_loader : @resource.SyncLoader,
  io_service : @io_task.IOService,
  id~ : Int = 0
) -> @utils.Future[Job] {
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
  @utils.Future::all_of(
    subids
    .iter()
    .map(fn(subid) {
      io_service
      .submit(fn() { JobData::load(subid, string_loader) })
      .map(fn(data) { (subid, data.unwrap()) }) // TODO: handle error
    })
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
  let job_id = JobId::from_int(id).unwrap() // TODO: handle error
  let name = get_name_by_id(job_id)
  { name, id: job_id, level, sub_job_data_map }
}

///|
pub fn get_id(self : Job) -> JobId {
  self.id
}

///|
pub fn get_name(self : Job) -> String {
  self.name
}

///|
pub(all) enum JobId {
  BEGINNER = 0
  WARRIOR = 100
  FIGHTER = 110
  CRUSADER = 111
  HERO = 112
  PAGE = 120
  WHITEKNIGHT = 121
  PALADIN = 122
  SPEARMAN = 130
  DRAGONKNIGHT = 131
  DARKKNIGHT = 132
  MAGICIAN = 200
  FP_WIZARD = 210
  FP_MAGE = 211
  FP_ARCHMAGE = 212
  IL_WIZARD = 220
  IL_MAGE = 221
  IL_ARCHMAGE = 222
  CLERIC = 230
  PRIEST = 231
  BISHOP = 232
  BOWMAN = 300
  HUNTER = 310
  RANGER = 311
  BOWMASTER = 312
  CROSSBOWMAN = 320
  SNIPER = 321
  MARKSMAN = 322
  THIEF = 400
  ASSASSIN = 410
  HERMIT = 411
  NIGHTLORD = 412
  BANDIT = 420
  CHIEFBANDIT = 421
  SHADOWER = 422
  PIRATE = 500
  BRAWLER = 510
  MARAUDER = 511
  BUCCANEER = 512
  GUNSLINGER = 520
  OUTLAW = 521
  CORSAIR = 522
  MAPLELEAF_BRIGADIER = 800
  GM = 900
  SUPERGM = 910
  NOBLESSE = 1000
  DAWNWARRIOR1 = 1100
  DAWNWARRIOR2 = 1110
  DAWNWARRIOR3 = 1111
  DAWNWARRIOR4 = 1112
  BLAZEWIZARD1 = 1200
  BLAZEWIZARD2 = 1210
  BLAZEWIZARD3 = 1211
  BLAZEWIZARD4 = 1212
  WINDARCHER1 = 1300
  WINDARCHER2 = 1310
  WINDARCHER3 = 1311
  WINDARCHER4 = 1312
  NIGHTWALKER1 = 1400
  NIGHTWALKER2 = 1410
  NIGHTWALKER3 = 1411
  NIGHTWALKER4 = 1412
  THUNDERBREAKER1 = 1500
  THUNDERBREAKER2 = 1510
  THUNDERBREAKER3 = 1511
  THUNDERBREAKER4 = 1512
  LEGEND = 2000
  EVAN = 2001
  ARAN1 = 2100
  ARAN2 = 2110
  ARAN3 = 2111
  ARAN4 = 2112
  EVAN1 = 2200
  EVAN2 = 2210
  EVAN3 = 2211
  EVAN4 = 2212
  EVAN5 = 2213
  EVAN6 = 2214
  EVAN7 = 2215
  EVAN8 = 2216
  EVAN9 = 2217
  EVAN10 = 2218
} derive(Eq)

///|
pub fn JobId::int_value(self : JobId) -> Int = "%identity"

///|
pub fn JobId::from_int(i : Int) -> JobId? {
  let jobid = match i {
    0 => JobId::BEGINNER
    100 => WARRIOR
    110 => FIGHTER
    111 => CRUSADER
    112 => HERO
    120 => PAGE
    121 => WHITEKNIGHT
    122 => PALADIN
    130 => SPEARMAN
    131 => DRAGONKNIGHT
    132 => DARKKNIGHT
    200 => MAGICIAN
    210 => FP_WIZARD
    211 => FP_MAGE
    212 => FP_ARCHMAGE
    220 => IL_WIZARD
    221 => IL_MAGE
    222 => IL_ARCHMAGE
    230 => CLERIC
    231 => PRIEST
    232 => BISHOP
    300 => BOWMAN
    310 => HUNTER
    311 => RANGER
    312 => BOWMASTER
    320 => CROSSBOWMAN
    321 => SNIPER
    322 => MARKSMAN
    400 => THIEF
    410 => ASSASSIN
    411 => HERMIT
    412 => NIGHTLORD
    420 => BANDIT
    421 => CHIEFBANDIT
    422 => SHADOWER
    500 => PIRATE
    510 => BRAWLER
    511 => MARAUDER
    512 => BUCCANEER
    520 => GUNSLINGER
    521 => OUTLAW
    522 => CORSAIR
    800 => MAPLELEAF_BRIGADIER
    900 => GM
    910 => SUPERGM
    1000 => NOBLESSE
    1100 => DAWNWARRIOR1
    1110 => DAWNWARRIOR2
    1111 => DAWNWARRIOR3
    1112 => DAWNWARRIOR4
    1200 => BLAZEWIZARD1
    1210 => BLAZEWIZARD2
    1211 => BLAZEWIZARD3
    1212 => BLAZEWIZARD4
    1300 => WINDARCHER1
    1310 => WINDARCHER2
    1311 => WINDARCHER3
    1312 => WINDARCHER4
    1400 => NIGHTWALKER1
    1410 => NIGHTWALKER2
    1411 => NIGHTWALKER3
    1412 => NIGHTWALKER4
    1500 => THUNDERBREAKER1
    1510 => THUNDERBREAKER2
    1511 => THUNDERBREAKER3
    1512 => THUNDERBREAKER4
    2000 => LEGEND
    2001 => EVAN
    2100 => ARAN1
    2110 => ARAN2
    2111 => ARAN3
    2112 => ARAN4
    2200 => EVAN1
    2210 => EVAN2
    2211 => EVAN3
    2212 => EVAN4
    2213 => EVAN5
    2214 => EVAN6
    2215 => EVAN7
    2216 => EVAN8
    2217 => EVAN9
    2218 => EVAN10
    _ => return None
  }
  Some(jobid)
}

///|
pub impl Show for JobId with output(self, logger) {
  let name = match self {
    BEGINNER => "Beginner"
    WARRIOR => "Swordsman"
    FIGHTER => "Fighter"
    CRUSADER => "Crusader"
    HERO => "Hero"
    PAGE => "Page"
    WHITEKNIGHT => "White Knight"
    PALADIN => "Paladin"
    SPEARMAN => "Spearman"
    DRAGONKNIGHT => "Dragon Knight"
    DARKKNIGHT => "Dark Knight"
    MAGICIAN => "Magician"
    FP_WIZARD => "Wizard (F/P)"
    FP_MAGE => "Mage (F/P)"
    FP_ARCHMAGE => "Archmage (F/P)"
    IL_WIZARD => "Wizard (I/L)"
    IL_MAGE => "Mage (I/L)"
    IL_ARCHMAGE => "Archmage (I/L)"
    CLERIC => "Cleric"
    PRIEST => "Priest"
    BISHOP => "Bishop"
    BOWMAN => "Archer"
    HUNTER => "Hunter"
    RANGER => "Ranger"
    BOWMASTER => "Bowmaster"
    CROSSBOWMAN => "Crossbowman"
    SNIPER => "Sniper"
    MARKSMAN => "Marksman"
    THIEF => "Rogue"
    ASSASSIN => "Assassin"
    HERMIT => "Hermit"
    NIGHTLORD => "Nightlord"
    BANDIT => "Bandit"
    CHIEFBANDIT => "Chief Bandit"
    SHADOWER => "Shadower"
    PIRATE => "Pirate"
    BRAWLER => "Brawler"
    MARAUDER => "Marauder"
    BUCCANEER => "Buccaneer"
    GUNSLINGER => "Gunslinger"
    OUTLAW => "Outlaw"
    CORSAIR => "Corsair"
    NOBLESSE => "Noblesse"
    LEGEND => "Legend"
    EVAN => "Evan"
    ARAN1 => "Aran1"
    ARAN2 => "Aran2"
    ARAN3 => "Aran3"
    ARAN4 => "Aran4"
    EVAN1 => "Evan1"
    EVAN2 => "Evan2"
    EVAN3 => "Evan3"
    EVAN4 => "Evan4"
    EVAN5 => "Evan5"
    EVAN6 => "Evan6"
    EVAN7 => "Evan7"
    EVAN8 => "Evan8"
    EVAN9 => "Evan9"
    EVAN10 => "Evan10"
    GM => "GM"
    SUPERGM => "SuperGM"
    MAPLELEAF_BRIGADIER => "Maple Leaf Brigadier"
    DAWNWARRIOR1 => "Dawn Warrior1"
    DAWNWARRIOR2 => "Dawn Warrior2"
    DAWNWARRIOR3 => "Dawn Warrior3"
    DAWNWARRIOR4 => "Dawn Warrior4"
    BLAZEWIZARD1 => "Blaze Wizard1"
    BLAZEWIZARD2 => "Blaze Wizard2"
    BLAZEWIZARD3 => "Blaze Wizard3"
    BLAZEWIZARD4 => "Blaze Wizard4"
    WINDARCHER1 => "Wind Archer1"
    WINDARCHER2 => "Wind Archer2"
    WINDARCHER3 => "Wind Archer3"
    WINDARCHER4 => "Wind Archer4"
    NIGHTWALKER1 => "Night Walker1"
    NIGHTWALKER2 => "Night Walker2"
    NIGHTWALKER3 => "Night Walker3"
    NIGHTWALKER4 => "Night Walker4"
    THUNDERBREAKER1 => "Thunder Breaker1"
    THUNDERBREAKER2 => "Thunder Breaker2"
    THUNDERBREAKER3 => "Thunder Breaker3"
    THUNDERBREAKER4 => "Thunder Breaker4"
  }
  logger.write_string(name)
}

///|
pub impl @json.FromJson for JobId with from_json(json, path) {
  let id : Int = @json.from_json!(json, path~)
  if JobId::from_int(id) is Some(jobid) {
    jobid
  } else {
    raise @json.JsonDecodeError((path, "Invalid job id"))
  }
}

///|
pub fn get_name_by_id(jid : JobId) -> String {
  jid.to_string()
}

///| Return true if the job is a branch of the required job
pub fn Job::is_a(self : Job, base_job_id : Int) -> Bool {
  let self_id = self.id.int_value()
  let basebranch = base_job_id / 10
  (self_id / 10 == basebranch && self_id >= base_job_id) ||
  (basebranch % 10 == 0 && self_id / 100 == base_job_id / 100)
}

///|
pub fn get_level(self : Job) -> Level {
  self.level
}

///|
pub fn get_primary(
  self : Job,
  weapontype : @weapon.Type
) -> @maple_stat.EquipStatId {
  match self.id.int_value() / 100 {
    2 => return @maple_stat.EquipStatId::INT
    3 => return @maple_stat.EquipStatId::DEX
    4 => return @maple_stat.EquipStatId::LUK
    5 =>
      return if weapontype == @weapon.Type::GUN {
        @maple_stat.EquipStatId::DEX
      } else {
        @maple_stat.EquipStatId::STR
      }
    _ => return @maple_stat.EquipStatId::STR
  }
}

///|
pub fn get_secondary(
  self : Job,
  weapontype : @weapon.Type
) -> @maple_stat.EquipStatId {
  match self.id.int_value() / 100 {
    2 => return @maple_stat.EquipStatId::LUK
    3 => return @maple_stat.EquipStatId::STR
    4 => return @maple_stat.EquipStatId::DEX
    5 =>
      return if weapontype == @weapon.Type::GUN {
        @maple_stat.EquipStatId::STR
      } else {
        @maple_stat.EquipStatId::DEX
      }
    _ => return @maple_stat.EquipStatId::DEX
  }
}

///|
pub fn get_subjob(self : Job, level : Level) -> Int {
  get_subjob_id(self.id.int_value(), self.level, level)
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
  self.is_a(required)
}

///|
pub fn get_data_by_id(self : Job, subid : Int) -> JobData {
  self.sub_job_data_map.get(subid).unwrap() // TODO: handle error
}
