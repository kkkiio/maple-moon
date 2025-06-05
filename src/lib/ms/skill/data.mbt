///|
pub(all) struct SkillData {
  id : Int
  stats : Map[Int, Stats]
  element : String
  req_weapon : @weapon.Type
  master_level : Int
  is_attack : Bool
  is_ranged : Bool
  passive : Bool
  invisible : Bool
  name : String
  desc : String
  levels : Map[Int, String]
  req_skills : @immut/hashmap.T[Int, Int]
  icons : FixedArray[@graphics.Texture] // NORMAL, DISABLED, MOUSEOVER
  src : @resource.NxNode
}

///| The stats of one level
pub(all) struct Stats {
  damage_mul : Double
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
} derive(ToJson)

///|
pub fn SkillData::load(
  string_loader : @resource.SyncLoader,
  id : Int
) -> @utils.Future[Result[SkillData, Error]] {
  let strid = @string_format.extend_id(id, 7)
  let jobid = strid.substring(end=3)
  skill_loader()
  .load_res([jobid + ".img", "skill", strid])
  .map_exn(fn(src) {
    let strsrc = string_loader.load_res(["Skill.img", strid])
    SkillData::new!(id, src, strsrc)
  })
}

///|
pub fn SkillData::new(
  id : Int,
  skill_src : @resource.NxNode,
  strsrc : @resource.NxNode
) -> SkillData! {
  let strid = @string_format.extend_id(id, 7)
  let jobid = strid.substring(end=3)

  // Load icons
  let icons = FixedArray::from_array([
    skill_src["icon"] |> @graphics.Texture::from_resource,
    skill_src["iconDisabled"] |> @graphics.Texture::from_resource,
    skill_src["iconMouseOver"] |> @graphics.Texture::from_resource,
  ])

  // Load strings
  let name = strsrc["name"].get_string()
  let desc = strsrc["desc"].get_string()
  let levels = (1)
    .until(@int.max_value)
    .map_while(fn(level) {
      let sub = strsrc["h" + Show::to_string(level)]
      if sub.is_null() {
        None
      } else {
        Some((level, sub.get_string()))
      }
    })
    |> Map::from_iter

  /// Load stats
  let levelsrc = skill_src["level"]
  let stats = parse_stats!(levelsrc.value())
  let element = skill_src["elemAttr"].get_string()
  let req_weapon = parse_req_weapon!(jobid, skill_src["weapon"].value())
  let master_level = stats.size()
  let passive = id % 10000 / 1000 == 0
  let invisible = skill_src["invisible"].get_bool!()
  let (is_attack, is_ranged) = flags_of(id)

  /// Load required skills
  let reqsrc = skill_src["req"]
  let req_skills = {}
  for sub in reqsrc {
    let skillid = sub.name() |> @strconv.parse_int?() |> _.or(-1)
    let reqlv = sub.get_int!()
    req_skills.set(skillid, reqlv)
  }
  {
    id,
    stats,
    element,
    req_weapon,
    master_level,
    is_attack,
    is_ranged,
    passive,
    invisible,
    name,
    desc,
    levels,
    req_skills: @immut/hashmap.from_iter(req_skills.iter()),
    icons,
    src: skill_src,
  }
}

///|
let flag_none : (Bool, Bool) = (false, false)

///|
let flag_attack : (Bool, Bool) = (true, false)

///|
let flag_range_attack : (Bool, Bool) = (true, true)

///|
fn flags_of(id : Int) -> (Bool, Bool) {
  guard SkillId::from_int?(id) is Ok(id) else { flag_none }
  skill_flags.get(id).or(flag_none)
}

///| Skill flags, unfortunately these just have to be hard-coded
let skill_flags : Map[SkillId, (Bool, Bool)] = Map::from_array([
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
  (SkillId::ENERGY_BOLT, flag_range_attack),
  (SkillId::MAGIC_CLAW, flag_range_attack),
  // F/P Mage
  (SkillId::SLOW_FP, flag_attack),
  (SkillId::FIRE_ARROW, flag_range_attack),
  (SkillId::POISON_BREATH, flag_range_attack),
  // F/P ArchMage
  (SkillId::EXPLOSION, flag_attack),
  (SkillId::POISON_BREATH, flag_attack),
  (SkillId::SEAL_FP, flag_attack),
  (SkillId::ELEMENT_COMPOSITION_FP, flag_range_attack),
  //
  (SkillId::FIRE_DEMON, flag_attack),
  (SkillId::PARALYZE, flag_range_attack),
  (SkillId::METEOR_SHOWER, flag_attack),
])

///|
pub fn is_attack(self : SkillData) -> Bool {
  not(self.passive) && self.is_attack
}

///|
pub fn get_stats(self : SkillData, level : Int) -> Stats? {
  self.stats.get(level)
}

///|
pub fn skill_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("skill")
}

///|
pub fn parse_stats(src : @json.JsonValue) -> Map[Int, Stats]! {
  let stats = {}
  for key, value in src.as_object().or({}) {
    let level = key |> @strconv.parse_int!()
    let stat = match value {
      Null =>
        // TODO: don't add invalid stats
        {
          damage_mul: 0,
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
        }
      Object(sub) => {
        let damage = if sub is { "damage": Number(d), .. } {
          d / 100.0
        } else {
          0
        }
        let matk = if sub is { "mad": Number(m), .. } { m.to_int() } else { 0 }
        let fixdamage = if sub is { "fixdamage": Number(f), .. } {
          f.to_int()
        } else {
          0
        }
        let mastery = if sub is { "mastery": Number(m), .. } {
          m.to_int()
        } else {
          0
        }
        let attackcount = if sub is { "attackCount": Number(a), .. } {
          a.to_int()
        } else {
          1
        }
        let mobcount = if sub is { "mobCount": Number(m), .. } {
          m.to_int()
        } else {
          1
        }
        let bulletcount = if sub is { "bulletCount": Number(b), .. } {
          b.to_int()
        } else {
          1
        }
        let bulletcost = if sub is { "bulletConsume": Number(b), .. } {
          b.to_int()
        } else {
          0
        }
        let hpcost = if sub is { "hpCon": Number(h), .. } {
          h.to_int()
        } else {
          0
        }
        let mpcost = if sub is { "mpCon": Number(m), .. } {
          m.to_int()
        } else {
          0
        }
        let chance = if sub is { "prop": Number(p), .. } {
          p / 100.0
        } else {
          1.0
        }
        let critical = 0.0
        let ignoredef = 0.0
        let hrange = if sub is { "range": Number(r), .. } { r / 100 } else { 1 }
        if mobcount == 0 || hrange == 0 {
          fail!(
            "invalid range level=\{level}, mobcount=\{mobcount}, hrange=\{hrange}",
          )
        }
        let range = @json.from_json!(value)
        {
          damage_mul: damage,
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
        }
      }
      _ => fail!("invalid stats")
    }
    stats.set(level, stat)
  }
  stats
}

///|
pub fn parse_req_weapon(
  jobid : String,
  weapon_value : @json.JsonValue
) -> @weapon.Type! {
  if jobid == "900" || jobid == "910" {
    @weapon.Type::NONE
  } else {
    match weapon_value {
      Null => @weapon.Type::NONE
      Number(v) => @weapon.Type::by_value!(100 + v.to_int())
      _ => fail!("invalid weapon value")
    }
  }
}
