struct Skill {
  action : SkillAction
  bullet : (@character.Character, Int) -> @utils.Future[@graphics.Animation]
  use_effect : SkillUseEffect
  hit_effect : SkillHitEffect
  affected_effects : SkillAffectedEffect
  skill_id : Int
  over_regular : Bool
  projectile : Bool
}

pub fn Skill::new(skill_id : Int) -> Skill! {
  let data = @skill.SkillData::get!(skill_id)
  let strid = if skill_id < 10000000 {
    @string_format.extend_id(skill_id, 7)
  } else {
    skill_id.to_string()
  }
  let src = @skill.skill_loader().load_res(
    [strid.substring(end=3) + ".img", "skill", strid],
  )
  let mut projectile = true
  let mut over_regular = false
  let has_affected_effect = src["affected"].get_children_count() > 0
  let by_level_effect = src["CharLevel"]["10"]["effect"].get_children_count() >
    0
  let multi_effect = src["effect0"].get_children_count() > 0
  let affected_effects = if has_affected_effect {
    let effect : SkillAffectedEffect = SingleAffectedEffect::new!(src)
    effect
  } else {
    NoAffectedEffect::new()
  }
  let use_effect = if by_level_effect {
    let effect : SkillUseEffect = ByLevelUseEffect::new!(src)
    effect
  } else if multi_effect {
    let effect : SkillUseEffect = MultiUseEffect::new!(src)
    effect
  } else {
    let is_animation = src["effect"]["0"].get_bitmap().is_empty().not()
    let has_effect1 = src["effect"]["1"].get_bitmap().is_empty().not()
    if is_animation {
      let effect : SkillUseEffect = SingleUseEffect::new!(src)
      effect
    } else if has_effect1 {
      let effect : SkillUseEffect = TwoHandedUseEffect::new!(src)
      effect
    } else {
      match @skill.SkillId::from_int?(skill_id) {
        Ok(@skill.SkillId::IRON_BODY) | Ok(@skill.SkillId::MAGIC_ARMOR) => {
          let effect : SkillUseEffect = IronBodyUseEffect::new()
          effect
        }
        _ => {
          let effect : SkillUseEffect = NoUseEffect::new()
          effect
        }
      }
    }
  }
  let by_level_hit = src["CharLevel"]["10"]["hit"].get_children_count() > 0
  let by_skill_level_hit = src["level"]["1"]["hit"].get_children_count() > 0
  let has_hit0 = src["hit"]["0"].get_children_count() > 0
  let has_hit1 = src["hit"]["1"].get_children_count() > 0
  let hit_effect = if by_level_hit {
    if has_hit0 && has_hit1 {
      let effect : SkillHitEffect = ByLevelTwoHandedHitEffect::new!(src)
      effect
    } else {
      let effect : SkillHitEffect = ByLevelHitEffect::new!(src)
      effect
    }
  } else if by_skill_level_hit {
    let effect : SkillHitEffect = BySkillLevelHitEffect::new!(src)
    effect
  } else if has_hit0 && has_hit1 {
    let effect : SkillHitEffect = TwoHandedHitEffect::new!(src)
    effect
  } else if has_hit0 {
    let effect : SkillHitEffect = SingleHitEffect::new!(src)
    effect
  } else {
    NoHitEffect::new()
  }
  let has_action0 = src["action"]["0"].as_string?().is_ok()
  let has_action1 = src["action"]["1"].as_string?().is_ok()
  let action = if has_action0 && has_action1 {
    let action : SkillAction = TwoHandedAction::new(src)
    action
  } else if has_action0 {
    let action : SkillAction = SingleAction::new(src)
    action
  } else if data.is_attack() {
    let by_level = src["level"]["1"]["action"].as_string?().is_ok()
    if by_level {
      let action : SkillAction = ByLevelAction::new!(src, skill_id)
      action
    } else {
      over_regular = true
      let action : SkillAction = RegularAction::default()
      action
    }
  } else {
    let action : SkillAction = NoAction::new()
    action
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
    let bullet = SkillRegularBullet::default()
    fn(user : @character.Character, bulletid : Int) {
      bullet.get(user, bulletid)
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
    affected_effects,
  }
}

pub fn Skill::get_id(self : Skill) -> Int {
  self.skill_id
}

pub fn Skill::is_attack(self : Skill) -> Bool {
  @skill.SkillData::get?(self.skill_id).unwrap().is_attack()
}

pub fn Skill::is_skill(self : Skill) -> Bool {
  true
}

pub fn Skill::apply_useeffects(
  self : Skill,
  user : @character.Character
) -> Unit {
  self.use_effect.apply(user)
}

pub fn apply_actions(
  self : Skill,
  user : @character.Character,
  attack_type : @combat.AttackType
) -> Unit {
  self.action.apply(user, attack_type)
}

pub fn apply_stats(
  self : Skill,
  user : @character.Character,
  attack : @combat.Attack
) -> Unit {
  attack.skill = self.skill_id
  let level = user.get_skilllevel(self.skill_id)
  let stats = @skill.SkillData::get?(self.skill_id)
    .unwrap()
    .get_stats(level)
    .unwrap() // TODO: Handle error
  if stats.fixdamage != 0 {
    attack.damagetype = @combat.AttackDamageType::DMG_FIXED(stats.fixdamage)
  } else if stats.matk != 0 {
    attack.damagetype = @combat.AttackDamageType::DMG_MAGIC(
      user.get_stats().get_matk() + stats.matk,
    )
  } else {
    attack.damagetype = @combat.AttackDamageType::DMG_WEAPON(
      stats.damage,
      stats.damage,
    )
  }
  attack.critical += stats.critical
  attack.ignoredef += stats.ignoredef
  attack.mobcount = stats.mobcount
  attack.hrange = stats.hrange
  match attack.t {
    @combat.AttackType::RANGED => attack.hitcount = stats.bulletcount
    _ => attack.hitcount = stats.attackcount
  }
  if stats.range.is_empty().not() {
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
    attack.stance = user.get_look().get_stance().int_value()
    if attack.t == @combat.AttackType::CLOSE && self.projectile.not() {
      attack.range = user.get_afterimage().get_range()
    }
  }
}

pub fn can_use(
  self : Skill,
  level : Int,
  weapon : @weapon.Type,
  job : @job.Job,
  hp : Int,
  _mp : Int,
  bullets : Int
) -> ForbidReason {
  let data = @skill.SkillData::get?(self.skill_id).unwrap() // TODO: Handle error
  if level <= 0 || level > data.master_level {
    return FBR_OTHER
  }
  if job.can_use(self.skill_id) == false {
    return FBR_OTHER
  }
  let stats = data.get_stats(level).unwrap()
  if hp <= stats.hpcost {
    return FBR_HPCOST
  }
  // TODO: support cost plugins
  // if mp < stats.mpcost {
  //   return FBR_MPCOST
  // }
  let reqweapon = data.req_weapon
  if weapon != reqweapon && reqweapon != @weapon.Type::NONE {
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

pub fn get_bullet(
  self : Skill,
  user : @character.Character,
  bulletid : Int
) -> @utils.Future[@graphics.Animation] {
  (self.bullet)(user, bulletid)
}

pub fn apply_hit_effects(
  self : Skill,
  user : @combat.AttackUser,
  target : @monster.Mob
) -> Unit {
  self.hit_effect.apply(user, target)
}
