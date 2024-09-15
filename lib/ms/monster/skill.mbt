pub struct MobBuff {
  time : Int
  anim : @graphics.Animation
}

/// The skill implementation of special move
pub struct MobSkill {
  // TODO: implement Effect
  // use_effect : MobSkillUseEffect
  // hit_effect : MobSkillHitEffect
  skill_id : Int
  level : Int
  buff : MobBuff
}

pub fn MobSkill::new(id : Int, level : Int) -> MobSkill! {
  let src = skill_loader().load_res(["MobSkill.img", id.to_string()])
  // let use_effect = MobSingleUseEffect::new(src["level"][level.to_string()])
  let is_buff = src["level"][level.to_string()]["mob"].get_children_count() > 0
  let buff = if is_buff {
    {
      time: src["level"][level.to_string()]["time"].get_int!(),
      anim: @graphics.Animation::from_resource(
        src["level"][level.to_string()]["mob"],
      ),
    }
  } else {
    { time: 0, anim: @graphics.Animation::default() }
  }
  {
    // use_effect,
    // hit_effect: MobSkillHitEffect::default(),
    skill_id: id,
    level,
    buff,
  }
}

pub fn MobSkill::apply_useeffects(self : MobSkill, mob : Mob) -> Unit {
  // self.use_effect.apply(mob)
}

pub fn MobSkill::apply_hiteffects(self : MobSkill, mob : Mob) -> Unit {
  // self.hit_effect.apply(mob)
}

pub fn MobSkill::is_attack(self : MobSkill) -> Bool {
  false
}

pub fn MobSkill::is_skill(self : MobSkill) -> Bool {
  true
}

pub fn MobSkill::is_buff(self : MobSkill) -> Bool {
  self.buff.time > 5
}

pub fn MobSkill::get_id(self : MobSkill) -> Int {
  self.skill_id
}

pub fn MobSkill::get_level(self : MobSkill) -> Int {
  self.level
}

pub fn MobSkill::get_buff(self : MobSkill) -> MobBuff {
  self.buff
}

fn skill_loader() -> @resource.Loader {
  @resource.Loader::new("Skill.nx")
}

struct Effect {
  animation : @graphics.Animation
  z : Int
}

pub fn Effect::new(src : @resource.NxNode) -> Effect! {
  { animation: @graphics.Animation::from_resource(src), z: src["z"].get_int!() }
}

pub fn Effect::apply(
  self : Effect,
  func_show_effect : (@graphics.Animation, Int, Int, Bool) -> Unit
) -> Unit {
  func_show_effect(self.animation, 1, self.z, false)
  // mob.show_effect(animation_, 0, z_, true);
}

trait MobSkillUseEffect {
  apply(Self, Mob) -> Unit
}

// An effect which displays an animation over the mob's position
pub struct MobSingleUseEffect {
  effect : Effect
}

pub fn MobSingleUseEffect::new(src : @resource.NxNode) -> MobSingleUseEffect! {
  { effect: Effect::new!(src) }
}

pub fn MobSingleUseEffect::apply(self : MobSingleUseEffect, mob : Mob) -> Unit {
  self.effect.apply(
    fn(a : @graphics.Animation, b : Int, c : Int, d : Bool) {
      mob.show_effect(a, b, c, d)
    },
  )
}

pub struct MobMultiUseEffect {
  effects : Array[Effect]
}

pub fn MobMultiUseEffect::new(
  src : @resource.NxNode,
  area_warning : Bool
) -> MobMultiUseEffect! {
  let effects = Array::new()
  if area_warning {
    effects.push(Effect::new!(src["areaWarning"]))
  }
  let mut no = -1
  let mut sub = src["effect"]
  effects.push(Effect::new!(sub))
  while sub.is_null().not() {
    no += 1
    sub = src["effect" + no.to_string()]
    effects.push(Effect::new!(sub))
  }
  { effects, }
}

pub fn MobMultiUseEffect::apply(self : MobMultiUseEffect, mob : Mob) -> Unit {
  fn func(a : @graphics.Animation, b : Int, c : Int, d : Bool) {
    mob.show_effect(a, b, c, d)
  }

  for effect in self.effects {
    effect.apply(func)
  }
}
