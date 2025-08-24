///|
fn new_skill_use_effect_effect(
  src : @resource.NxNode
) -> ((@character.Character) -> Unit) raise Error {
  let animation = src |> @graphics.Animation::from_resource_ex()
  let z = src["z"].get_int()
  fn(c : @character.Character) -> Unit { c.show_attack_effect(animation, z) }
}

///| An effect which displays an animation over the character's position
fn new_single_use_effect(
  src : @resource.NxNode
) -> ((@character.Character) -> Unit) raise Error {
  let effect = new_skill_use_effect_effect(src["effect"])
  fn(c : @character.Character) -> Unit { effect(c) }
}

///| An effect which displays an animation over the character's position
/// The effect changes based on whether the character uses a two-handed weapon
fn new_twohanded_use_effect(
  src : @resource.NxNode
) -> ((@character.Character) -> Unit) raise Error {
  let effects = @utils.BoolPair::new(
    new_skill_use_effect_effect(src["effect"]["0"]),
    new_skill_use_effect_effect(src["effect"]["1"]),
  )
  fn(c : @character.Character) -> Unit {
    let twohanded = c.is_twohanded()
    effects[twohanded](c)
  }
}

///| An effect which displays multiple animations over the character's position
fn new_multi_use_effect(
  src : @resource.NxNode
) -> ((@character.Character) -> Unit) raise Error {
  let effects = []
  let mut no = -1
  let mut sub = src["effect"]
  while not(sub.is_null()) {
    effects.push(new_skill_use_effect_effect(sub))
    no += 1
    sub = src["effect" + no.to_string()]
  }
  fn(c) {
    for effect in effects {
      effect(c)
    }
  }
}

///| The animation changes with the character level
fn new_by_level_use_effect(
  src : @resource.NxNode
) -> ((@character.Character) -> Unit) raise Error {
  let effects = []
  for sub in src["CharLevel"] {
    let level = @strconv.parse_int(sub.name())
    let effect = new_skill_use_effect_effect(sub["effect"])
    effects.push((level, effect))
  }
  effects.sort_by_key(fn(it) { it.0 })
  fn(c) {
    if effects.is_empty() {
      return
    }
    let level = c.get_stats().get_stat(@maple_stat.Id::LEVEL)
    let mut iter = 0
    while iter < effects.length() && level > effects[iter].0 {
      iter += 1
    }
    if iter > 0 {
      iter -= 1
    }
    (effects[iter].1)(c)
  }
}

///| Use effect for Iron Body
fn new_iron_body_use_effect() -> (@character.Character) -> Unit {
  fn(c) { c.show_iron_body() }
}
