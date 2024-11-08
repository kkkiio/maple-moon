pub struct SkillData {
  id : Int
  stats : Map[Int, Stats]
  element : String
  req_weapon : @weapon.Type
  master_level : Int
  flags : Int
  passive : Bool
  invisible : Bool
  name : String
  desc : String
  levels : Map[Int, String]
  req_skills : @immut/hashmap.T[Int, Int]
  icons : FixedArray[@graphics.Texture] // NORMAL, DISABLED, MOUSEOVER
}

/// The stats of one level
pub struct Stats {
  damage : Double
  matk : Int
  fixdamage : Int
  mastery : Int
  attackcount : Int
  mobcount : Int
  bulletcount : Int
  bulletcost : Int
  hpcost : Int
  mpcost : Int
  chance : Double
  critical : Double
  ignoredef : Double
  hrange : Double
  range : @struct.Rectangle[Int]
}

let cache : Map[Int, SkillData] = {}

pub fn SkillData::get(id : Int) -> SkillData! {
  match cache.get(id) {
    Some(skill) => skill
    None => {
      let skill = SkillData::load!(id)
      cache.set(id, skill)
      skill
    }
  }
}

pub fn SkillData::load(id : Int) -> SkillData! {
  /// Locate sources
  let strid = @string_format.extend_id(id, 7)
  let jobid = strid.substring(end=3)
  let src = skill_loader().load_res([jobid + ".img", "skill", strid])
  let strsrc = @resource.string_loader().load_res(["Skill.img", strid])

  // Load icons
  let icons = FixedArray::from_array(
    [
      src["icon"] |> @graphics.Texture::from_resource,
      src["iconDisabled"] |> @graphics.Texture::from_resource,
      src["iconMouseOver"] |> @graphics.Texture::from_resource,
    ],
  )

  // Load strings
  let name = strsrc["name"].get_string()
  let desc = strsrc["desc"].get_string()
  let levels = (1)
    .until(@int.max_value)
    .map_while(
      fn(level) {
        let sub = strsrc["h" + Show::to_string(level)]
        if sub.is_null() {
          None
        } else {
          Some((level, sub.get_string()))
        }
      },
    )
    |> Map::from_iter

  /// Load stats
  let levelsrc = src["level"]
  let stats = {}
  for sub in levelsrc {
    let level = sub.name() |> @strconv.parse_int!()
    if sub.is_null() {
      // TODO: don't add invalid stats
      stats.set(
        level,
        {
          damage: 0,
          matk: 0,
          fixdamage: 0,
          mastery: 0,
          attackcount: 0,
          mobcount: 0,
          bulletcount: 0,
          bulletcost: 0,
          hpcost: 0,
          mpcost: 0,
          chance: 0,
          critical: 0,
          ignoredef: 0,
          hrange: 0,
          range: @struct.Rectangle::new(
            @struct.Point::new(0, 0),
            @struct.Point::new(0, 0),
          ),
        },
      )
      continue
    }
    let damage = sub["damage"].get_float!() / 100
    let matk = sub["mad"].get_int!()
    let fixdamage = sub["fixdamage"].get_int!()
    let mastery = sub["mastery"].get_int!()
    let attackcount = sub["attackCount"].get_int?().or(1)
    let mobcount = sub.get_int_field!("mobCount", default=1)
    let bulletcount = sub["bulletCount"].get_int?().or(1)
    let bulletcost = sub["bulletConsume"].get_int!()
    let hpcost = sub["hpCon"].get_int!()
    let mpcost = sub["mpCon"].get_int!()
    let chance = sub.get_float_field!("prop", default=100) / 100
    let critical = 0.0
    let ignoredef = 0.0
    let hrange = sub.get_float_field!("range", default=100) / 100
    if mobcount == 0 || hrange == 0 {
      @log.error(
        { "id": id, "level": level, "hrange": hrange },
        "invalid range",
      )
      panic()
    }
    let range = sub.as_rectangle!()
    stats.set(
      level,
      {
        damage,
        matk,
        fixdamage,
        mastery,
        attackcount,
        mobcount,
        bulletcount,
        bulletcost,
        hpcost,
        mpcost,
        chance,
        critical,
        ignoredef,
        hrange,
        range,
      },
    )
  }
  let element = src["elemAttr"].get_string()
  let req_weapon = if jobid == "900" || jobid == "910" {
    @weapon.Type::NONE
  } else {
    let weapon = src["weapon"]
    if weapon.is_null() {
      @weapon.Type::NONE
    } else {
      @weapon.Type::by_value!(100 + weapon.get_int!())
    }
  }
  let master_level = stats.size()
  let passive = id % 10000 / 1000 == 0
  let flags = flags_of(id)
  let invisible = src["invisible"].get_bool!()

  /// Load required skills
  let reqsrc = src["req"]
  let req_skills = {}
  for sub in reqsrc {
    let skillid = sub.name() |> @strconv.parse_int?() |> @result.or(-1)
    let reqlv = sub.get_int!()
    req_skills.set(skillid, reqlv)
  }
  {
    id,
    stats,
    element,
    req_weapon,
    master_level,
    flags,
    passive,
    invisible,
    name,
    desc,
    levels,
    req_skills: @immut/hashmap.from_iter(req_skills.iter()),
    icons,
  }
}

// Skill flags, unfortunately these just have to be hard-coded
let flag_none : Int = 0x0000

let flag_attack : Int = 0x0001

let flag_ranged : Int = 0x0002

fn flags_of(id : Int) -> Int {
  guard let Ok(id) = SkillId::from_int?(id) else { _ => flag_none }
  skill_flags[id].or(flag_none)
}

let skill_flags : @immut/hashmap.T[SkillId, Int] = @immut/hashmap.from_array(
  [
    // Beginner
    (SkillId::THREE_SNAILS, flag_attack),
    // Warrior
    (SkillId::POWER_STRIKE, flag_attack),
    (SkillId::SLASH_BLAST, flag_attack),
    // Fighter
    // Page
    // Crusader
    (SkillId::SWORD_PANIC, flag_attack),
    (SkillId::AXE_PANIC, flag_attack),
    (SkillId::SWORD_COMA, flag_attack),
    (SkillId::AXE_COMA, flag_attack),
    // Hero
    (SkillId::RUSH_HERO, flag_attack),
    (SkillId::BRANDISH, flag_attack),
    // Page
    // White Knight
    (SkillId::CHARGE, flag_attack),
    // Paladin
    (SkillId::RUSH_PALADIN, flag_attack),
    (SkillId::BLAST, flag_attack),
    (SkillId::HEAVENS_HAMMER, flag_attack),
    // Spearman
    // Dragon Knight
    (SkillId::DRAGON_BUSTER, flag_attack),
    (SkillId::DRAGON_FURY, flag_attack),
    (SkillId::PA_BUSTER, flag_attack),
    (SkillId::PA_FURY, flag_attack),
    (SkillId::SACRIFICE, flag_attack),
    (SkillId::DRAGONS_ROAR, flag_attack),
    // Dark Knight
    (SkillId::RUSH_DK, flag_attack),
    // Mage
    (SkillId::ENERGY_BOLT, flag_attack | flag_ranged),
    (SkillId::MAGIC_CLAW, flag_attack | flag_ranged),
    // F/P Mage
    (SkillId::SLOW_FP, flag_attack),
    (SkillId::FIRE_ARROW, flag_attack | flag_ranged),
    (SkillId::POISON_BREATH, flag_attack | flag_ranged),
    // F/P ArchMage
    (SkillId::EXPLOSION, flag_attack),
    (SkillId::POISON_BREATH, flag_attack),
    (SkillId::SEAL_FP, flag_attack),
    (SkillId::ELEMENT_COMPOSITION_FP, flag_attack | flag_ranged),
    //
    (SkillId::FIRE_DEMON, flag_attack),
    (SkillId::PARALYZE, flag_attack | flag_ranged),
    (SkillId::METEOR_SHOWER, flag_attack),
  ],
)

pub fn is_attack(self : SkillData) -> Bool {
  self.passive.not() && (self.flags & flag_attack) != 0
}

pub fn get_stats(self : SkillData, level : Int) -> Stats? {
  self.stats.get(level)
}
