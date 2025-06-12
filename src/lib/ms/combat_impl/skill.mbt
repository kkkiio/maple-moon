///|
struct Skill {
  action : &SkillAction
  bullet : (@character.Character, Int) -> @utils.Future[@graphics.Animation]
  use_effect : (@character.Character) -> Unit
  hit_effect : (@combat.AttackUser, @monster.Mob) -> Unit
  // affected_effects : &SkillAffectedEffect
  skill_id : Int
  over_regular : Bool
  projectile : Bool
  is_attack : Bool
  master_level : Int
  stats : Map[Int, @skill.Stats]
  req_weapon : @weapon.Type
}

///|
pub async fn Skill::load(
  string_loader : @resource.SyncLoader,
  io_service : @io_task.IOService,
  skill_id : Int
) -> Skill! {
  let data = @skill.SkillData::load(string_loader, skill_id)
  Skill::new!(
    string_loader,
    io_service,
    skill_id,
    data.src,
    data.is_attack,
    data.master_level,
    data.stats,
    data.req_weapon,
    make_use_effect!(data.src, skill_id),
    make_hit_effect!(data.src),
  )
}

///|
pub fn Skill::new(
  string_loader : @resource.SyncLoader,
  io_service : @io_task.IOService,
  skill_id : Int,
  src : @resource.NxNode,
  is_attack : Bool,
  master_level : Int,
  stats : Map[Int, @skill.Stats],
  req_weapon : @weapon.Type,
  use_effect : (@character.Character) -> Unit,
  hit_effect : (@combat.AttackUser, @monster.Mob) -> Unit
) -> Skill! {
  // let strid = if skill_id < 10000000 {
  //   @string_format.extend_id(skill_id, 7)
  // } else {
  //   skill_id.to_string()
  // }
  let mut projectile = true
  let mut over_regular = false
  // let has_affected_effect = src["affected"].get_children_count() > 0
  // let affected_effects = if has_affected_effect {
  //   SingleAffectedEffect::new!(src) as &SkillAffectedEffect
  // } else {
  //   NoAffectedEffect::new() as &SkillAffectedEffect
  // }
  let has_action0 = src["action"]["0"].as_string?().is_ok()
  let has_action1 = src["action"]["1"].as_string?().is_ok()
  let action = if has_action0 && has_action1 {
    TwoHandedAction::new(src) as &SkillAction
  } else if has_action0 {
    SingleAction::new(src) as &SkillAction
  } else if is_attack {
    let by_level = src["level"]["1"]["action"].as_string?().is_ok()
    if by_level {
      ByLevelAction::new!(src, skill_id) as &SkillAction
    } else {
      over_regular = true
      RegularAction::default() as &SkillAction
    }
  } else {
    NoAction::new() as &SkillAction
  }
  let has_ball = src["ball"].get_children_count() > 0
  let by_level_ball = src["level"]["1"]["ball"].get_children_count() > 0
  let bullet = if by_level_ball {
    let bullet = BySkillLevelBullet::new!(src, skill_id)
    fn(user : @character.Character, bulletid : Int) {
      bullet.get(user, bulletid) |> @utils.Future::from_value
    }
  } else if has_ball {
    let bullet = SingleBullet::new!(src)
    fn(user : @character.Character, bulletid : Int) {
      bullet.get(user, bulletid) |> @utils.Future::from_value
    }
  } else {
    projectile = false
    let bullet = SkillRegularBullet::new(string_loader)
    fn(user : @character.Character, bulletid : Int) {
      io_service.submit(fn() { bullet.get(user, bulletid) }).map(_.unwrap())
    }
  }
  {
    skill_id,
    over_regular,
    projectile,
    action,
    bullet,
    use_effect,
    hit_effect,
    is_attack,
    master_level,
    stats,
    req_weapon,
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
pub fn Skill::apply_useeffects(
  self : Skill,
  user : @character.Character
) -> Unit {
  (self.use_effect)(user)
}

///|
pub fn Skill::apply_actions(
  self : Skill,
  user : @character.Character,
  attack_type : @combat.AttackType
) -> Unit {
  self.action.apply(user, attack_type)
}

///|
pub fn Skill::make_attack(
  self : Skill,
  chr : @character.CharBase,
  bullet_id : Int,
  attack_type : @combat.AttackType
) -> @combat.Attack {
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
  let toleft = chr.facing_right |> not()
  let speed = (chr.get_integer_attackspeed)()
  let level = (chr.get_skilllevel)(self.skill_id)
  let stats = self.stats.get(level).unwrap() // TODO: Handle error
  let attack : @combat.Attack = {
    hitcount: 0,
    stance: 0,
    damagetype: if stats.fixdamage != 0 {
      @combat.AttackDamageType::DMG_FIXED(stats.fixdamage)
    } else if stats.matk != 0 {
      @combat.AttackDamageType::DMG_MAGIC(chr.stats.get_matk() + stats.matk)
    } else {
      @combat.AttackDamageType::DMG_WEAPON(
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
    mobcount: stats.mobcount,
    hrange: stats.hrange,
  }
  match attack.t {
    @combat.AttackType::RANGED => attack.hitcount = stats.bulletcount
    _ => attack.hitcount = stats.attackcount
  }
  if not(stats.range.is_empty()) {
    attack.range = stats.range
  }
  if self.projectile && attack.bullet == 0 {
    match @skill.SkillId::from_int?(self.skill_id) {
      Ok(@skill.SkillId::THREE_SNAILS) =>
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
    if attack.t == @combat.AttackType::CLOSE && not(self.projectile) {
      attack.range = chr.get_afterimage().get_range()
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
  bullets : Int
) -> ForbidReason {
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
  bulletid : Int
) -> @utils.Future[@graphics.Animation] {
  (self.bullet)(user, bulletid)
}

///|
pub fn Skill::apply_hit_effects(
  self : Skill,
  user : @combat.AttackUser,
  target : @monster.Mob
) -> Unit {
  (self.hit_effect)(user, target)
}

///|
pub fn make_use_effect(
  src : @resource.NxNode,
  skill_id : Int
) -> ((@character.Character) -> Unit)!Error {
  let by_level_effect = src["CharLevel"]["10"]["effect"].get_children_count() >
    0
  let multi_effect = src["effect0"].get_children_count() > 0
  if by_level_effect {
    new_by_level_use_effect!(src)
  } else if multi_effect {
    new_multi_use_effect!(src)
  } else {
    let is_animation = not(src["effect"]["0"].get_bitmap().is_empty())
    let has_effect1 = not(src["effect"]["1"].get_bitmap().is_empty())
    if is_animation {
      new_single_use_effect!(src)
    } else if has_effect1 {
      new_twohanded_use_effect!(src)
    } else {
      match @skill.SkillId::from_int?(skill_id) {
        Ok(@skill.SkillId::IRON_BODY) | Ok(@skill.SkillId::MAGIC_ARMOR) =>
          new_iron_body_use_effect()
        _ => fn(_) {  }
      }
    }
  }
}

///|
pub fn make_hit_effect(
  src : @resource.NxNode
) -> ((@combat.AttackUser, @monster.Mob) -> Unit)!Error {
  let by_level_hit = src["CharLevel"]["10"]["hit"].get_children_count() > 0
  let by_skill_level_hit = src["level"]["1"]["hit"].get_children_count() > 0
  let has_hit0 = src["hit"]["0"].get_children_count() > 0
  let has_hit1 = src["hit"]["1"].get_children_count() > 0
  if by_level_hit {
    if has_hit0 && has_hit1 {
      new_by_level_twohanded_hit_effect!(src)
    } else {
      new_by_level_hit_effect!(src)
    }
  } else if by_skill_level_hit {
    new_by_skill_level_hit_effect!(src)
  } else if has_hit0 && has_hit1 {
    new_twohanded_hit_effect!(src)
  } else if has_hit0 {
    new_single_hit_effect!(src)
  } else {
    fn(_ : @combat.AttackUser, _ : @monster.Mob) -> Unit {  }
  }
}
