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
pub async fn SkillData::load(
  string_loader : @resource.SyncLoader,
  id : Int
) -> SkillData raise {
  let strid = @string_format.extend_id(id, 7)
  let jobid = strid.substring(end=3)
  let src = skill_loader().load_res_async([jobid + ".img", "skill", strid])
  let skill_res : SkillNxResource = @json.from_json(src.value())
  let strsrc : SkillTextResource = string_loader
    .load_res(["Skill.img", strid])
    .value()
    |> @json.from_json()
  SkillData::new(id, src, skill_res.unwrap(), strsrc)
}

///|
struct SkillNxResource {
  icon : @graphics.TextureResource
  icon_disabled : @graphics.TextureResource
  icon_mouseover : @graphics.TextureResource
  elem_attr : String
  req_skills : Nullable[IntMap[Int]]
  invisible : Bool
  level_stats : LevelStats
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
  let icon : @graphics.TextureResource = @json.from_json(
    obj.get("icon").or(Json::null()),
    path=path.add_key("icon"),
  )
  let icon_disabled : @graphics.TextureResource = @json.from_json(
    obj.get("iconDisabled").or(Json::null()),
    path=path.add_key("iconDisabled"),
  )
  let icon_mouseover : @graphics.TextureResource = @json.from_json(
    obj.get("iconMouseOver").or(Json::null()),
    path=path.add_key("iconMouseOver"),
  )
  let elem_attr : String = match obj.get("elemAttr") {
    Some(String(s)) => s
    Some(Number(n)) => n.to_string()
    Some(Null) | None => ""
    _ =>
      raise @json.JsonDecodeError((path.add_key("elemAttr"), "expect string"))
  }
  let req_skills : Nullable[IntMap[Int]] = @json.from_json(
    obj.get("req").or(Json::null()),
    path=path.add_key("req"),
  )
  let invisible : Bool = match obj.get("invisible") {
    Some(Number(n)) => n == 1
    Some(Null) | None => false
    _ =>
      raise @json.JsonDecodeError((path.add_key("invisible"), "expect number"))
  }
  let level_stats : LevelStats = @json.from_json(
    obj.get("level").or(Json::null()),
    path=path.add_key("level"),
  )
  let req_weapon : WeaponType = @json.from_json(
    obj.get("weapon").or(Json::null()),
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
pub fn SkillNxResource::unwrap(self : SkillNxResource) -> SkillResource {
  {
    icon: self.icon,
    icon_disabled: self.icon_disabled,
    icon_mouseover: self.icon_mouseover,
    elem_attr: self.elem_attr,
    req_skills: self.req_skills._.map_or({}, fn(it) { it._ }),
    invisible: self.invisible,
    level_stats: self.level_stats._,
    req_weapon: self.req_weapon._,
  }
}

///|
struct SkillResource {
  icon : @graphics.TextureResource
  icon_disabled : @graphics.TextureResource
  icon_mouseover : @graphics.TextureResource
  elem_attr : String
  req_skills : Map[Int, Int]
  invisible : Bool
  level_stats : Map[Int, Stats]
  req_weapon : @weapon.Type
} derive(ToJson)

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
pub fn SkillData::new(
  id : Int,
  skill_src : @resource.NxNode,
  skill_res : SkillResource,
  text_src : SkillTextResource
) -> SkillData {
  let strid = @string_format.extend_id(id, 7)
  let jobid = strid.substring(end=3)

  // Load icons
  let icons = FixedArray::from_array([
    skill_res.icon |> @graphics.Texture::load("", skill_src.get_image_loader()),
    skill_res.icon_disabled
    |> @graphics.Texture::load("", skill_src.get_image_loader()),
    skill_res.icon_mouseover
    |> @graphics.Texture::load("", skill_src.get_image_loader()),
  ])
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
  let master_level = stats.size()
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
priv type LevelStats Map[Int, Stats]

///|
impl @json.FromJson for LevelStats with from_json(json, path) -> LevelStats raise @json.JsonDecodeError {
  let stats = {}
  for key, value in json.as_object().or({}) {
    let level = try key |> @strconv.parse_int() catch {
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
          chance,
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
type WeaponType @weapon.Type

///|
pub impl @json.FromJson for WeaponType with from_json(json, path) -> WeaponType raise @json.JsonDecodeError {
  match json {
    Null => @weapon.Type::NONE
    Number(v) =>
      @weapon.Type::by_value(100 + v.to_int()) catch {
        _ => raise @json.JsonDecodeError((path, "invalid weapon type"))
      }
    _ => raise @json.JsonDecodeError((path, "expect number"))
  }
}

///|
typealias @resource.IntMap

///|
typealias @resource.Nullable
