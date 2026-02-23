///|
trait SkillAffectedEffect {
  apply(Self, @character.Character) -> Unit
}

///|
struct SkillAffectedEffectEffect {
  animation : @resource.NxAnimation
  z : Int
}

///|
fn SkillAffectedEffectEffect::new(
  src : Json,
) -> SkillAffectedEffectEffect raise {
  let z = match src {
    { "z": Number(z, ..), .. } => z.to_int()
    _ => 0
  }
  { animation: @json.from_json(src), z }
}

///|
fn SkillAffectedEffectEffect::apply(
  self : SkillAffectedEffectEffect,
  c : @character.Character,
) -> Unit {
  c.show_attack_effect(self.animation, self.z)
}

///|
/// no animation
struct NoAffectedEffect {} derive(Default)

///|
fn NoAffectedEffect::new() -> NoAffectedEffect {
  NoAffectedEffect::default()
}

///|
fn NoAffectedEffect::apply(
  self : NoAffectedEffect,
  c : @character.Character,
) -> Unit {

}

///|
/// An effect which displays an animation over the character's position
struct SingleAffectedEffect {
  effect : SkillAffectedEffectEffect
}

///|
fn SingleAffectedEffect::new(src : Json) -> SingleAffectedEffect raise {
  let effect = if src is { "affected": affected, .. } {
    SkillAffectedEffectEffect::new(affected)
  } else {
    SkillAffectedEffectEffect::new(Json::null())
  }
  { effect, }
}

///|
fn SingleAffectedEffect::apply(
  self : SingleAffectedEffect,
  c : @character.Character,
) -> Unit {
  self.effect.apply(c)
}
