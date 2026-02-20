///|
pub(all) struct MobBuff {
  time : Int
  anim : @resource.NxAnimation
}

///|
/// The skill implementation of special move
pub(all) struct MobSkill {
  // TODO: implement Effect
  // use_effect : MobSkillUseEffect
  // hit_effect : MobSkillHitEffect
  skill_id : Int
  level : Int
  buff : MobBuff
}

///|
pub async fn MobSkill::load(id : Int, level : Int) -> MobSkill {
  let src = get_skill_loader()
    .load_res_async(["MobSkill.img", id.to_string()])
    .value()
  MobSkill::new(id, level, src)
}

///|
pub fn MobSkill::new(
  id : Int,
  level : Int,
  src : Json,
) -> MobSkill raise {
  // let use_effect = MobSingleUseEffect::new(get_path(src, ["level", level.to_string()]))
  let level_json = get_path(src, ["level", level.to_string()])
  let mob_json = get_path(level_json, ["mob"])
  let is_buff = match mob_json {
    Object(obj) => obj.length() > 0
    _ => false
  }
  let buff = if is_buff {
    {
      time: json_int(get_path(level_json, ["time"])),
      anim: @json.from_json(mob_json),
    }
  } else {
    { time: 0, anim: @json.from_json(Json::null()) }
  }
  {
    // use_effect,
    // hit_effect: MobSkillHitEffect::default(),
    skill_id: id,
    level,
    buff,
  }
}

///|
pub fn MobSkill::apply_useeffects(_self : MobSkill, _mob : Mob) -> Unit {
  // self.use_effect.apply(mob)
}

///|
pub fn MobSkill::apply_hit_effects(_self : MobSkill, _mob : Mob) -> Unit {
  // self.hit_effect.apply(mob)
}

///|
pub fn MobSkill::is_attack(_self : MobSkill) -> Bool {
  false
}

///|
pub fn MobSkill::is_skill(_self : MobSkill) -> Bool {
  true
}

///|
pub fn MobSkill::is_buff(self : MobSkill) -> Bool {
  self.buff.time > 5
}

///|
pub fn MobSkill::get_id(self : MobSkill) -> Int {
  self.skill_id
}

///|
pub fn MobSkill::get_level(self : MobSkill) -> Int {
  self.level
}

///|
pub fn MobSkill::get_buff(self : MobSkill) -> MobBuff {
  self.buff
}

///|
struct Effect {
  animation : @resource.NxAnimation
  z : Int
}

///|
pub fn Effect::new(src : Json) -> Effect raise {
  { animation: @json.from_json(src), z: json_int(get_path(src, ["z"])) }
}

///|
pub fn Effect::apply(
  self : Effect,
  func_show_effect : (@resource.NxAnimation, Int, Int, Bool) -> Unit,
) -> Unit {
  func_show_effect(self.animation, 1, self.z, false)
  // mob.show_effect(animation_, 0, z_, true);
}

///|
trait MobSkillUseEffect {
  apply(Self, Mob) -> Unit
}

///|
fn get_path(json : Json, keys : Array[String]) -> Json {
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
fn json_int(json : Json) -> Int {
  match json {
    Number(v, ..) => v.to_int()
    _ => 0
  }
}

// An effect which displays an animation over the mob's position

///|
pub(all) struct MobSingleUseEffect {
  effect : Effect
}

///|
pub fn MobSingleUseEffect::new(
  src : Json,
) -> MobSingleUseEffect raise {
  { effect: Effect::new(src) }
}

///|
pub impl MobSkillUseEffect for MobSingleUseEffect with apply(
  self : MobSingleUseEffect,
  mob : Mob,
) -> Unit {
  self.effect.apply(fn(a : @resource.NxAnimation, b : Int, c : Int, d : Bool) {
    mob.show_effect(a, b, c, d)
  })
}

///|
pub(all) struct MobMultiUseEffect {
  effects : Array[Effect]
}

///|
pub fn MobMultiUseEffect::new(
  src : Json,
  area_warning : Bool,
) -> MobMultiUseEffect raise {
  let effects = Array::new()
  if area_warning {
    let area_warning_json = get_path(src, ["areaWarning"])
    if area_warning_json != Json::null() {
      effects.push(Effect::new(area_warning_json))
    }
  }
  let effect0 = get_path(src, ["effect"])
  if effect0 != Json::null() {
    effects.push(Effect::new(effect0))
  }
  for no in 0..<999 {
    let sub = get_path(src, ["effect" + no.to_string()])
    if sub == Json::null() {
      break
    }
    effects.push(Effect::new(sub))
  }
  { effects, }
}

///|
pub impl MobSkillUseEffect for MobMultiUseEffect with apply(
  self : MobMultiUseEffect,
  mob : Mob,
) -> Unit {
  fn func(a : @resource.NxAnimation, b : Int, c : Int, d : Bool) {
    // TODO: show effect
    // ...
    mob.show_effect(a, b, c, d)
  }

  for effect in self.effects {
    effect.apply(func)
  }
}

///|
using @resource {get_skill_loader}
