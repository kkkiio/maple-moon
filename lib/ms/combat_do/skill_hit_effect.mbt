trait SkillHitEffect {
  apply(Self, @combat.AttackUser, @monster.Mob) -> Unit
}

struct Effect {
  animation : @graphics.Animation
  pos : Int
  z : Int
}

fn Effect::new(src : @resource.NxNode) -> Effect! {
  {
    animation: src |> @graphics.Animation::from_resource_ex!(),
    pos: src["pos"].get_int!(),
    z: src["z"].get_int!(),
  }
}

fn apply(self : Effect, target : @monster.Mob, flip : Bool) -> Unit {
  target.show_effect(self.animation, self.pos, self.z, flip)
}

// No animation
struct NoHitEffect {} derive(Default)

fn NoHitEffect::new() -> NoHitEffect {
  NoHitEffect::default()
}

fn apply(
  self : NoHitEffect,
  user : @combat.AttackUser,
  target : @monster.Mob
) -> Unit {
  // Do nothing
}

// A single animation
struct SingleHitEffect {
  effect : Effect
}

fn SingleHitEffect::new(src : @resource.NxNode) -> SingleHitEffect! {
  { effect: Effect::new!(src["hit"]["0"]) }
}

fn apply(
  self : SingleHitEffect,
  user : @combat.AttackUser,
  target : @monster.Mob
) -> Unit {
  self.effect.apply(target, user.flip)
}

// The animation changes depending on the weapon used
struct TwoHandedHitEffect {
  effects : @utils.BoolPair[Effect]
}

fn TwoHandedHitEffect::new(src : @resource.NxNode) -> TwoHandedHitEffect! {
  {
    effects: @utils.BoolPair::new(
      Effect::new!(src["hit"]["0"]),
      Effect::new!(src["hit"]["1"]),
    ),
  }
}

fn apply(
  self : TwoHandedHitEffect,
  user : @combat.AttackUser,
  target : @monster.Mob
) -> Unit {
  self.effects[user.second_weapon].apply(target, user.flip)
}

// The animation changes with the character level
struct ByLevelHitEffect {
  effects : Array[(Int, Effect)]
}

fn ByLevelHitEffect::new(src : @resource.NxNode) -> ByLevelHitEffect! {
  let effects = []
  for sub in src["CharLevel"] {
    let level = @strconv.parse_int!(sub.name())
    let effect = Effect::new!(sub["hit"]["0"])
    effects.push((level, effect))
  }
  effects.sort_by_key(fn(it) { it.0 })
  { effects, }
}

fn apply(
  self : ByLevelHitEffect,
  user : @combat.AttackUser,
  target : @monster.Mob
) -> Unit {
  if self.effects.is_empty() {
    return
  }
  let mut iter = 0
  while iter < self.effects.length() && user.level > self.effects[iter].0 {
    iter += 1
  }
  if iter > 0 {
    iter -= 1
  }
  self.effects[iter].1.apply(target, user.flip)
}

// The animation changes with the character level and weapon used
struct ByLevelTwoHandedHitEffect {
  effects : Array[(Int, @utils.BoolPair[Effect])]
}

fn ByLevelTwoHandedHitEffect::new(
  src : @resource.NxNode
) -> ByLevelTwoHandedHitEffect! {
  let effects = []
  for sub in src["CharLevel"] {
    let level = @strconv.parse_int!(sub.name())
    let effect_pair = @utils.BoolPair::new(
      Effect::new!(sub["hit"]["0"]),
      Effect::new!(sub["hit"]["1"]),
    )
    effects.push((level, effect_pair))
  }
  effects.sort_by_key(fn(it) { it.0 })
  { effects, }
}

fn apply(
  self : ByLevelTwoHandedHitEffect,
  user : @combat.AttackUser,
  target : @monster.Mob
) -> Unit {
  if self.effects.is_empty() {
    return
  }
  let mut iter = 0
  while iter < self.effects.length() && user.level > self.effects[iter].0 {
    iter += 1
  }
  if iter > 0 {
    iter -= 1
  }
  self.effects[iter].1[user.second_weapon].apply(target, user.flip)
}

// The animation changes with the skill level
struct BySkillLevelHitEffect {
  effects : Map[Int, Effect]
}

fn BySkillLevelHitEffect::new(src : @resource.NxNode) -> BySkillLevelHitEffect! {
  let effects = Map::new()
  for sub in src["level"] {
    let level = @strconv.parse_int!(sub.name())
    let effect = Effect::new!(sub["hit"]["0"])
    effects.set(level, effect)
  }
  { effects, }
}

fn apply(
  self : BySkillLevelHitEffect,
  user : @combat.AttackUser,
  target : @monster.Mob
) -> Unit {
  match self.effects.get(user.skill_level) {
    Some(effect) => effect.apply(target, user.flip)
    None => ()
  }
}
