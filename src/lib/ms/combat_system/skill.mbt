///|
struct Skill {
  action : &SkillAction
  bullet : (@character.Character, Int) -> @resource.NxAnimation
  sound : SkillSound
  use_effect : UseEffect
  hit_effect : (@combat_proto.AttackUser, @monster.Mob) -> Unit
  // affected_effects : &SkillAffectedEffect
  skill_id : Int
  over_regular : Bool
  projectile : Bool
  is_attack : Bool
  master_level : Int
  stats : Map[Int, @skill.Stats]
  req_weapon : @weapon.Type
  after_image : Map[String, @char_look.NxAfterImage]
}

///|
pub async fn Skill::load(skill_id : Int) -> Skill {
  let data = @skill.SkillData::load(skill_id)
  Skill::new(
    skill_id,
    data.src,
    data.is_attack,
    data.master_level,
    data.stats,
    data.req_weapon,
    SkillSound::new(skill_id),
    make_use_effect(data.src, skill_id),
    make_hit_effect(data.src),
  )
}

///|
pub fn Skill::new(
  skill_id : Int,
  src : Json,
  is_attack : Bool,
  master_level : Int,
  stats : Map[Int, @skill.Stats],
  req_weapon : @weapon.Type,
  sound : SkillSound,
  use_effect : UseEffect,
  hit_effect : (@combat_proto.AttackUser, @monster.Mob) -> Unit,
) -> Skill raise {
  let mut projectile = true
  let mut over_regular = false
  // let strid = if skill_id < 10000000 {
  //   @string_format.extend_id(skill_id, 7)
  // } else {
  //   skill_id.to_string()
  // }
  // let has_affected_effect = src["affected"].get_children_count() > 0
  // let affected_effects = if has_affected_effect {
  //   SingleAffectedEffect::new!(src) as &SkillAffectedEffect
  // } else {
  //   NoAffectedEffect::new() as &SkillAffectedEffect
  // }
  let has_action0 = json_get_string(skill_get_path(src, ["action", "0"]))
    is Some(_)
  let has_action1 = json_get_string(skill_get_path(src, ["action", "1"]))
    is Some(_)
  let action = if @skill.SkillId::from_int(skill_id) is Some(sk) &&
    (
      sk == @skill.SkillId::TELEPORT_FP ||
      sk == @skill.SkillId::IL_TELEPORT ||
      sk == @skill.SkillId::PRIEST_TELEPORT
    ) {
    FuncSkillAction(fn(c, _) {
      match @map.get_runtime_context() {
        Some((_, physics)) => teleport(c, physics)
        None => () // Do nothing if physics is not available
      }
    })
    as &SkillAction
  } else if has_action0 && has_action1 {
    TwoHandedAction::new(src) as &SkillAction
  } else if has_action0 {
    SingleAction::new(src) as &SkillAction
  } else if is_attack {
    let by_level = json_get_string(
        skill_get_path(src, ["level", "1", "action"]),
      )
      is Some(_)
    if by_level {
      ByLevelAction::new(src, skill_id) as &SkillAction
    } else {
      over_regular = true
      RegularAction::default() as &SkillAction
    }
  } else {
    NoAction::new() as &SkillAction
  }
  let has_ball = json_has_children(skill_get_path(src, ["ball"]))
  let by_level_ball = json_has_children(
    skill_get_path(src, ["level", "1", "ball"]),
  )
  let bullet = if by_level_ball {
    let bullet = BySkillLevelBullet::new(src, skill_id)
    fn(user : @character.Character, bulletid : Int) {
      bullet.get(user, bulletid)
    }
  } else if has_ball {
    let bullet = SingleBullet::new(src)
    fn(user : @character.Character, bulletid : Int) {
      bullet.get(user, bulletid)
    }
  } else {
    projectile = false
    let bullet = SkillRegularBullet::new()
    fn(user : @character.Character, bulletid : Int) {
      bullet.get(user, bulletid)
    }
  }
  let after_image = Map::new()
  if src is { "afterimage": Object(map), .. } {
    for k, v in map {
      if k.has_suffix(".img") {
        continue
      }
      let resource : @char_look.NxAfterImage = @json.from_json(v)
      after_image.set(k, resource)
    }
  }
  {
    skill_id,
    over_regular,
    projectile,
    action,
    bullet,
    sound,
    use_effect,
    hit_effect,
    is_attack,
    master_level,
    stats,
    req_weapon,
    after_image,
  }
}

///|
pub fn Skill::get_id(self : Skill) -> Int {
  self.skill_id
}

///|
pub fn Skill::is_attack(self : Skill) -> Bool {
  self.is_attack
}

///|
pub fn Skill::get_afterimage(
  self : Skill,
) -> Map[String, @char_look.NxAfterImage] {
  self.after_image
}

///|
pub fn Skill::apply_useeffects(
  self : Skill,
  user : @character.Character,
) -> Unit {
  (self.use_effect)(user)
}

///|
pub fn Skill::apply_use_sfx(self : Skill, _user : @character.Character) -> Unit {
  self.sound.play_use()
}

///|
pub fn Skill::apply_actions(
  self : Skill,
  user : @character.Character,
  attack_type : @combat_proto.AttackType,
) -> Unit {
  self.action.apply(user, attack_type)
}

///|
pub fn Skill::make_attack(
  self : Skill,
  chr : @character.Character,
  bullet_id : Int,
  attack_type : @combat_proto.AttackType,
) -> @combat_proto.Attack {
  // let mut mindamage = char_stats.get_mindamage().to_double()
  // let mut maxdamage = char_stats.get_maxdamage().to_double()
  // if degenerate {
  //   mindamage /= 10
  //   maxdamage /= 10
  // }
  let critical = chr.stats.get_critical()
  let ignoredef = chr.stats.get_ignoredef()
  let accuracy = chr.stats.get_total(@maple_stat.EquipStatId::ACC)
  let playerlevel = chr.stats.get_stat(@maple_stat.Id::LEVEL)
  let range = chr.stats.get_range()
  let origin = chr.get_position()
  let toleft = !chr.facing_right
  let speed = @character.get_integer_attackspeed(chr.get_look(), chr.stats)
  let level = (chr.get_skilllevel)(self.skill_id)
  let stats = self.stats.get(level).unwrap()
  let attack : @combat_proto.Attack = {
    hitcount: 0,
    stance: 0,
    damagetype: if stats.fixdamage != 0 {
      @combat_proto.AttackDamageType::DMG_FIXED(stats.fixdamage)
    } else if stats.matk != 0 {
      @combat_proto.AttackDamageType::DMG_MAGIC(
        chr.stats.get_matk() + stats.matk,
      )
    } else {
      @combat_proto.AttackDamageType::DMG_WEAPON(
        min=chr.stats.get_mindamage().to_double() * stats.damage_mul,
        max=chr.stats.get_maxdamage().to_double() * stats.damage_mul,
      )
    },
    t: attack_type,
    critical: critical + stats.critical,
    ignoredef: ignoredef + stats.ignoredef,
    accuracy,
    playerlevel,
    range,
    bullet: bullet_id,
    origin,
    toleft,
    speed,
    skill: self.skill_id,
    max_target_count: stats.mobcount,
    hrange: stats.hrange,
  }
  match attack.t {
    @combat_proto.AttackType::RANGED => attack.hitcount = stats.bulletcount
    _ => attack.hitcount = stats.attackcount
  }
  if !stats.range.is_empty() {
    attack.range = stats.range
  }
  if self.projectile && attack.bullet == 0 {
    match @skill.SkillId::from_int(self.skill_id) {
      Some(@skill.SkillId::THREE_SNAILS) =>
        match level {
          1 => attack.bullet = 4000019
          2 => attack.bullet = 4000000
          3 => attack.bullet = 4000016
          _ => ()
        }
      _ => attack.bullet = self.skill_id
    }
  }
  if self.over_regular {
    attack.stance = chr.get_look().get_stance().int_value()
    if attack.t == @combat_proto.AttackType::CLOSE && !self.projectile {
      // Use afterimage range if available, otherwise keep default range
      if @char_look.get_after_image(chr.entity) is Some(after_image) {
        let after_image_range = after_image.get_range()
        if after_image_range.is_empty() {
          @log.fatal("afterimage range is empty for close skill attack", data={
            "skill_id": self.skill_id,
            "stance": chr.get_look().get_stance().name(),
          })
        }
        attack.range = after_image_range
      }
    }
  }
  attack
}

///|
pub fn Skill::can_use(
  self : Skill,
  level : Int,
  weapon : @weapon.Type,
  job : @job.Job,
  hp : Int,
  mp : Int,
  bullets : Int,
) -> ForbidReason {
  if true {
    return FBR_NONE
  }
  if level <= 0 || level > self.master_level {
    return FBR_OTHER
  }
  if job.can_use(self.skill_id) == false {
    return FBR_OTHER
  }
  let stats = self.stats.get(level).unwrap()
  if hp <= stats.hpcost {
    return FBR_HPCOST
  }
  if mp < stats.mpcost {
    return FBR_MPCOST
  }
  if weapon != self.req_weapon && self.req_weapon != @weapon.Type::NONE {
    return FBR_WEAPONTYPE
  }
  match weapon {
    @weapon.BOW | @weapon.CROSSBOW | @weapon.CLAW | @weapon.GUN =>
      if bullets >= stats.bulletcost {
        FBR_NONE
      } else {
        FBR_BULLETCOST
      }
    _ => FBR_NONE
  }
}

///|
pub fn Skill::get_bullet(
  self : Skill,
  user : @character.Character,
  bulletid : Int,
) -> @resource.NxAnimation {
  (self.bullet)(user, bulletid)
}

///|
pub fn Skill::apply_hit_effects(
  self : Skill,
  user : @combat_proto.AttackUser,
  target : @monster.Mob,
) -> Unit {
  (self.hit_effect)(user, target)
}

///|
pub fn Skill::apply_hit_sfx(
  self : Skill,
  _user : @combat_proto.AttackUser,
  _target : @monster.Mob,
) -> Unit {
  self.sound.play_hit()
}

///|
/// 负责播放“技能使用时”的动画的闭包。
/// 通常用于播放脚下的光圈、头顶的图标等施法特效。
pub struct UseEffect((@character.Character) -> Unit)

///|
pub fn make_use_effect(src : Json, skill_id : Int) -> UseEffect raise Error {
  let by_level_effect = json_has_children(
    skill_get_path(src, ["CharLevel", "10", "effect"]),
  )
  let multi_effect = json_has_children(skill_get_path(src, ["effect0"]))
  if by_level_effect {
    new_by_level_use_effect(src)
  } else if multi_effect {
    new_multi_use_effect(src)
  } else {
    let is_animation = is_texture_node(skill_get_path(src, ["effect", "0"]))
    let has_effect1 = is_texture_node(skill_get_path(src, ["effect", "1"]))
    if is_animation {
      new_single_use_effect(src)
    } else if has_effect1 {
      new_twohanded_use_effect(src)
    } else {
      match @skill.SkillId::from_int(skill_id) {
        Some(@skill.SkillId::IRON_BODY) | Some(@skill.SkillId::MAGIC_ARMOR) =>
          new_iron_body_use_effect()
        Some(@skill.SkillId::TELEPORT_FP)
        | Some(@skill.SkillId::IL_TELEPORT)
        | Some(@skill.SkillId::PRIEST_TELEPORT) => show_teleport_effect
        _ => fn(_) {  }
      }
    }
  }
}

///|
struct NxSkill {
  hit : Array[NxHitEffect]
}

///|
pub impl @json.FromJson for NxSkill with from_json(json, path) {
  let hit = match json {
    { "hit": hit, .. } =>
      @resource.parse_map_based_array(hit, path=path.add_key("hit"))
    _ => []
  }
  { hit, }
}

///|
pub fn make_hit_effect(
  src : Json,
) -> ((@combat_proto.AttackUser, @monster.Mob) -> Unit) raise Error {
  let by_level_hit = json_has_children(
    skill_get_path(src, ["CharLevel", "10", "hit"]),
  )
  let by_skill_level_hit = json_has_children(
    skill_get_path(src, ["level", "1", "hit"]),
  )
  let res : NxSkill = @json.from_json(src)
  let has_hit0 = res.hit.get(0) is Some(_)
  let has_hit1 = res.hit.get(1) is Some(_)
  if by_level_hit {
    if has_hit0 && has_hit1 {
      new_by_level_twohanded_hit_effect(src)
    } else {
      new_by_level_hit_effect(src)
    }
  } else if by_skill_level_hit {
    new_by_skill_level_hit_effect(src)
  } else if has_hit0 && has_hit1 {
    new_twohanded_hit_effect(res.hit[0], res.hit[1])
  } else if has_hit0 {
    new_single_hit_effect(res.hit[0])
  } else {
    fn(_ : @combat_proto.AttackUser, _ : @monster.Mob) -> Unit {  }
  }
}

///|
fn skill_get_path(json : Json, keys : Array[String]) -> Json {
  let mut current = json
  for key in keys {
    current = match current {
      Object(obj) => obj.get(key).unwrap_or(Json::null())
      _ => Json::null()
    }
  }
  current
}

///|
fn json_has_children(json : Json) -> Bool {
  match json {
    Object(obj) => !obj.is_empty()
    _ => false
  }
}

///|
fn json_get_string(json : Json) -> String? {
  match json {
    String(s) => Some(s)
    _ => None
  }
}

///|
fn is_texture_node(json : Json) -> Bool {
  let texture_result : Result[@resource.NxTexture, Error] = try? @json.from_json(
    json,
  )
  texture_result is Ok(_)
}
