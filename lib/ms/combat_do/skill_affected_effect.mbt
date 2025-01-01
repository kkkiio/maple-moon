///|
trait SkillAffectedEffect {
  apply(Self, @character.Character) -> Unit
}

///|
struct SkillAffectedEffectEffect {
  animation : @graphics.Animation
  z : Int
}

///|
fn SkillAffectedEffectEffect::new(
  src : @resource.NxNode
) -> SkillAffectedEffectEffect! {
  {
    animation: src |> @graphics.Animation::from_resource_ex!(),
    z: src["z"].get_int!(),
  }
}

///|
fn apply(self : SkillAffectedEffectEffect, c : @character.Character) -> Unit {
  c.show_attack_effect(self.animation, self.z)
}

///| no animation
struct NoAffectedEffect {} derive(Default)

///|
fn NoAffectedEffect::new() -> NoAffectedEffect {
  NoAffectedEffect::default()
}

///|
fn apply(self : NoAffectedEffect, c : @character.Character) -> Unit {

}

///| An effect which displays an animation over the character's position
struct SingleAffectedEffect {
  effect : SkillAffectedEffectEffect
}

///|
fn SingleAffectedEffect::new(src : @resource.NxNode) -> SingleAffectedEffect! {
  { effect: SkillAffectedEffectEffect::new!(src["affected"]) }
}

///|
fn apply(self : SingleAffectedEffect, c : @character.Character) -> Unit {
  self.effect.apply(c)
}
