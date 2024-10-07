trait SkillUseEffect {
  apply(Self, @character.Character) -> Unit
}

struct SkillUseEffectEffect {
  animation : @graphics.Animation
  z : Int
}

fn SkillUseEffectEffect::new(src : @resource.NxNode) -> SkillUseEffectEffect! {
  {
    animation: src |> @graphics.Animation::from_resource_ex!(),
    z: src["z"].get_int!(),
  }
}

fn apply(self : SkillUseEffectEffect, c : @character.Character) -> Unit {
  c.show_attack_effect(self.animation, self.z)
}

// No animation
struct NoUseEffect {} derive(Default)

fn NoUseEffect::new() -> NoUseEffect {
  NoUseEffect::default()
}

fn apply(self : NoUseEffect, c : @character.Character) -> Unit {

}

/// An effect which displays an animation over the character's position
struct SingleUseEffect {
  effect : SkillUseEffectEffect
}

fn SingleUseEffect::new(src : @resource.NxNode) -> SingleUseEffect! {
  { effect: SkillUseEffectEffect::new!(src["effect"]) }
}

fn apply(self : SingleUseEffect, c : @character.Character) -> Unit {
  self.effect.apply(c)
}

/// An effect which displays an animation over the character's position
/// The effect changes based on whether the character uses a two-handed weapon
struct TwoHandedUseEffect {
  effects : @utils.BoolPair[SkillUseEffectEffect]
}

fn TwoHandedUseEffect::new(src : @resource.NxNode) -> TwoHandedUseEffect! {
  {
    effects: @utils.BoolPair::new(
      SkillUseEffectEffect::new!(src["effect"]["0"]),
      SkillUseEffectEffect::new!(src["effect"]["1"]),
    ),
  }
}

fn apply(self : TwoHandedUseEffect, c : @character.Character) -> Unit {
  let twohanded = c.is_twohanded()
  self.effects[twohanded].apply(c)
}

/// An effect which displays multiple animations over the character's position
struct MultiUseEffect {
  effects : Array[SkillUseEffectEffect]
}

fn MultiUseEffect::new(src : @resource.NxNode) -> MultiUseEffect! {
  let effects = []
  let mut no = -1
  let mut sub = src["effect"]
  while sub.is_null().not() {
    effects.push(SkillUseEffectEffect::new!(sub))
    no += 1
    sub = src["effect" + no.to_string()]
  }
  { effects, }
}

fn apply(self : MultiUseEffect, c : @character.Character) -> Unit {
  for effect in self.effects {
    effect.apply(c)
  }
}

/// The animation changes with the character level
struct ByLevelUseEffect {
  effects : Array[(Int, SkillUseEffectEffect)]
}

fn ByLevelUseEffect::new(src : @resource.NxNode) -> ByLevelUseEffect! {
  let effects = []
  for sub in src["CharLevel"] {
    let level = @strconv.parse_int!(sub.name())
    let effect = SkillUseEffectEffect::new!(sub["effect"])
    effects.push((level, effect))
  }
  effects.sort_by_key(fn(it) { it.0 })
  { effects, }
}

fn apply(self : ByLevelUseEffect, c : @character.Character) -> Unit {
  if self.effects.is_empty() {
    return
  }
  let level = c.get_level()
  let mut iter = 0
  while iter < self.effects.length() && level > self.effects[iter].0 {
    iter += 1
  }
  if iter > 0 {
    iter -= 1
  }
  self.effects[iter].1.apply(c)
}

/// Use effect for Iron Body
struct IronBodyUseEffect {} derive(Default)

fn IronBodyUseEffect::new() -> IronBodyUseEffect {
  IronBodyUseEffect::default()
}

fn apply(self : IronBodyUseEffect, c : @character.Character) -> Unit {
  c.show_iron_body()
}
