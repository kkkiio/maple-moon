///|
/// Pure data structure for skill configuration.
/// Use load_skill() to load, get_cached_skill() for synchronous access.
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
  req_skills : @hashmap.HashMap[Int, Int]
  icons : (@resource.NxTexture, @resource.NxTexture, @resource.NxTexture) // NORMAL, DISABLED, MOUSEOVER
  /// Internal: raw JSON source for legacy effect construction.
  /// Will be removed when effect system is refactored.
  src : Json
}

///|
/// The stats of one level
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
  /// 概率, * 100
  prop : Int
  critical : Double
  ignoredef : Double
  hrange : Double
  range : @struct.Rectangle[Int]
} derive(ToJson, Debug)

///|
/// Load skill data asynchronously with caching.
/// Raises error if resource not found - caller must ensure preloading.
pub async fn SkillData::load(id : Int) -> SkillData {
  load_skill(id)
}

///|
/// Get cached skill data synchronously.
/// Returns None if not loaded yet. Use for runtime skill access.
pub fn SkillData::get_cached(id : Int) -> SkillData? {
  get_cached_skill(id)
}

///|
struct SkillNxResource {
  icon : @resource.NxTexture
  icon_disabled : @resource.NxTexture
  icon_mouseover : @resource.NxTexture
  elem_attr : String
  req_skills : Nullable[IntMap[Int]]
  invisible : Bool
  level_stats : NxLevelStats
  req_weapon : WeaponType
}
// @json.FromJson(
//   fields(
//     icon_disabled(rename="iconDisabled"),
//     icon_mouseover(rename="iconMouseOver"),
//     elem_attr(rename="elemAttr"),
//     req_skills(rename="req"),
//     level_stats(rename="level"),
//     req_weapon(rename="weapon"),
//   ),
// ),

///|
pub impl @json.FromJson for SkillNxResource with from_json(json, path) -> SkillNxResource raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let icon : @resource.NxTexture = @json.from_json(
    obj.get("icon").unwrap_or(Json::null()),
    path=path.add_key("icon"),
  )
  let icon_disabled : @resource.NxTexture = @json.from_json(
    obj.get("iconDisabled").unwrap_or(Json::null()),
    path=path.add_key("iconDisabled"),
  )
  let icon_mouseover : @resource.NxTexture = @json.from_json(
    obj.get("iconMouseOver").unwrap_or(Json::null()),
    path=path.add_key("iconMouseOver"),
  )
  let elem_attr : String = match obj.get("elemAttr") {
    Some(String(s)) => s
    Some(Number(n, ..)) => n.to_string()
    Some(Null) | None => ""
    _ =>
      raise @json.JsonDecodeError((path.add_key("elemAttr"), "expect string"))
  }
  let req_skills : Nullable[IntMap[Int]] = @json.from_json(
    obj.get("req").unwrap_or(Json::null()),
    path=path.add_key("req"),
  )
  let invisible : Bool = obj is { "invisible": v, .. } &&
    (v is Number(1, ..) || v is String("1") || v is True)
  let level_stats : NxLevelStats = @json.from_json(
    obj.get("level").unwrap_or(Json::null()),
    path=path.add_key("level"),
  )
  let req_weapon : WeaponType = @json.from_json(
    obj.get("weapon").unwrap_or(Json::null()),
    path=path.add_key("weapon"),
  )
  {
    icon,
    icon_disabled,
    icon_mouseover,
    elem_attr,
    req_skills,
    invisible,
    level_stats,
    req_weapon,
  }
}

///|
pub fn SkillNxResource::simplify(self : SkillNxResource) -> SkillResource {
  {
    icon: self.icon,
    icon_disabled: self.icon_disabled,
    icon_mouseover: self.icon_mouseover,
    elem_attr: self.elem_attr,
    req_skills: self.req_skills.0.map_or({}, fn(it) { it.0 }),
    invisible: self.invisible,
    level_stats: self.level_stats.0,
    req_weapon: self.req_weapon.0,
  }
}

///|
struct SkillResource {
  icon : @resource.NxTexture
  icon_disabled : @resource.NxTexture
  icon_mouseover : @resource.NxTexture
  elem_attr : String
  req_skills : Map[Int, Int]
  invisible : Bool
  level_stats : Map[Int, Stats]
  req_weapon : @weapon.Type
}

///|
struct SkillTextResource {
  name : String
  desc : String
  levels : Map[Int, String]
}

///|
pub impl @json.FromJson for SkillTextResource with from_json(json, path) -> SkillTextResource raise @json.JsonDecodeError {
  let (name, desc) = match json {
    { "name": String(name), "desc": String(desc), .. } => (name, desc)
    _ => raise @json.JsonDecodeError((path, "expect object with name and desc"))
  }
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let levels = {}
  for level = 1; ; level = level + 1 {
    match obj.get("h" + Show::to_string(level)) {
      Some(String(sub)) => levels.set(level, sub)
      None => break
      _ => raise @json.JsonDecodeError((path, "expect string"))
    }
  }
  { name, desc, levels }
}

///|
/// Create SkillData from resources (internal use, use load_skill for public API).
/// Note: src is used for legacy effect construction and will be removed.
pub fn SkillData::new(
  id : Int,
  skill_src : Json,
  skill_res : SkillResource,
  text_src : SkillTextResource,
) -> SkillData {
  let strid = @utils.stoi_left_pad0(id, 7)
  let jobid = strid.view(end_offset=3)

  // Keep raw icon resources; UI decides when/how to materialize render assets.
  let icons = (
    skill_res.icon,
    skill_res.icon_disabled,
    skill_res.icon_mouseover,
  )
  let name = text_src.name
  let desc = text_src.desc
  let levels = text_src.levels
  /// Load stats
  let stats = skill_res.level_stats
  let element = skill_res.elem_attr
  let req_weapon_type = skill_res.req_weapon
  let req_weapon = if jobid == "900" || jobid == "910" {
    @weapon.Type::NONE
  } else {
    req_weapon_type
  }
  let master_level = stats.length()
  let passive = id % 10000 / 1000 == 0
  let invisible = skill_res.invisible
  let (is_attack, is_ranged) = flags_of(id)

  /// Load required skills
  let req_skills = skill_res.req_skills
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
    req_skills: @hashmap.from_iter(req_skills.iter()),
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
  guard SkillId::from_int(id) is Some(id) else { flag_none }
  skill_flags.get(id).unwrap_or(flag_none)
}

///|
/// Skill flags, unfortunately these just have to be hard-coded
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
  // Hunter
  (SkillId::ARROW_BOMB_BOW, flag_range_attack),
  //
  (SkillId::FIRE_DEMON, flag_attack),
  (SkillId::PARALYZE, flag_range_attack),
  (SkillId::METEOR_SHOWER, flag_attack),
])

///|
pub fn SkillData::is_attack(self : SkillData) -> Bool {
  !self.passive && self.is_attack
}

///|
pub fn SkillData::get_stats(self : SkillData, level : Int) -> Stats? {
  self.stats.get(level)
}

///|
priv struct NxLevelStats(Map[Int, Stats])

///|
impl @json.FromJson for NxLevelStats with from_json(json, path) -> NxLevelStats raise @json.JsonDecodeError {
  let stats = {}
  guard json is Object(levels) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  for key, value in levels {
    let level = @string.parse_int(key) catch {
      _ => raise @json.JsonDecodeError((path, "invalid level"))
    }
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
          prop: 0,
          critical: 0,
          ignoredef: 0,
          hrange: 0,
          range: @struct.Rectangle::new(
            @struct.Point::new(0, 0),
            @struct.Point::new(0, 0),
          ),
        }
      Object(sub) => {
        let damage_base = if sub is { "damage": Number(d, ..), .. } {
          d
        } else if sub is { "x": Number(x, ..), .. } {
          x
        } else {
          0
        }
        let damage = damage_base / 100.0
        let matk = if sub is { "mad": Number(m, ..), .. } {
          m.to_int()
        } else {
          0
        }
        let fixdamage = if sub is { "fixdamage": Number(f, ..), .. } {
          f.to_int()
        } else {
          0
        }
        let mastery = if sub is { "mastery": Number(m, ..), .. } {
          m.to_int()
        } else {
          0
        }
        let attackcount = if sub is { "attackCount": Number(a, ..), .. } {
          a.to_int()
        } else {
          1
        }
        let mobcount = if sub is { "mobCount": Number(m, ..), .. } {
          m.to_int()
        } else {
          1
        }
        let bulletcount = if sub is { "bulletCount": Number(b, ..), .. } {
          b.to_int()
        } else {
          1
        }
        let bulletcost = if sub is { "bulletConsume": Number(b, ..), .. } {
          b.to_int()
        } else {
          0
        }
        let hpcost = if sub is { "hpCon": Number(h, ..), .. } {
          h.to_int()
        } else {
          0
        }
        let mpcost = if sub is { "mpCon": Number(m, ..), .. } {
          m.to_int()
        } else {
          0
        }
        let prop = if sub is { "prop": Number(p, ..), .. } {
          p.to_int()
        } else {
          100
        }
        let critical = 0.0
        let ignoredef = 0.0
        let hrange = if sub is { "range": Number(r, ..), .. } {
          r / 100
        } else {
          1
        }
        if mobcount == 0 || hrange == 0 {
          raise @json.JsonDecodeError((path, "invalid range"))
        }
        let range = @json.from_json(value)
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
          prop,
          critical,
          ignoredef,
          hrange,
          range,
        }
      }
      _ => raise @json.JsonDecodeError((path, "expect object"))
    }
    stats.set(level, stat)
  }
  stats
}

///|
struct WeaponType(@weapon.Type)

///|
pub impl @json.FromJson for WeaponType with from_json(json, path) -> WeaponType raise @json.JsonDecodeError {
  match json {
    Null => @weapon.Type::NONE
    Number(v, ..) =>
      @weapon.Type::from_value(100 + v.to_int()).unwrap_or_error(
        @json.JsonDecodeError((path, "invalid weapon type")),
      )
    String(s) if (try? @string.parse_int(s)) is Ok(v) =>
      @weapon.Type::from_value(100 + v).unwrap_or_error(
        @json.JsonDecodeError((path, "invalid weapon type")),
      )
    _ => raise @json.JsonDecodeError((path, "expect number"))
  }
}

///|
using @resource {type IntMap, type Nullable}
