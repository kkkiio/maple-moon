///|
fn new_skill_use_effect_effect(
  src : Json,
) -> ((@character.Character) -> Unit) raise Error {
  let animation : @resource.NxAnimation = @json.from_json(src)
  let z = match src {
    { "z": Number(z, ..), .. } => z.to_int()
    _ => 0
  }
  fn(c : @character.Character) -> Unit { c.show_attack_effect(animation, z) }
}

///|
/// An effect which displays an animation over the character's position
fn new_single_use_effect(
  src : Json,
) -> ((@character.Character) -> Unit) raise Error {
  let effect = new_skill_use_effect_effect(use_effect_get_path(src, ["effect"]))
  fn(c : @character.Character) -> Unit { effect(c) }
}

///|
/// An effect which displays an animation over the character's position
/// The effect changes based on whether the character uses a two-handed weapon
fn new_twohanded_use_effect(
  src : Json,
) -> ((@character.Character) -> Unit) raise Error {
  let effects = @utils.BoolPair::new(
    new_skill_use_effect_effect(use_effect_get_path(src, ["effect", "0"])),
    new_skill_use_effect_effect(use_effect_get_path(src, ["effect", "1"])),
  )
  fn(c : @character.Character) -> Unit {
    let twohanded = c.is_two_handed()
    effects[twohanded](c)
  }
}

///|
/// An effect which displays multiple animations over the character's position
fn new_multi_use_effect(
  src : Json,
) -> ((@character.Character) -> Unit) raise Error {
  let effects = []
  let mut no = -1
  let mut sub = use_effect_get_path(src, ["effect"])
  while sub != Json::null() {
    effects.push(new_skill_use_effect_effect(sub))
    no += 1
    sub = use_effect_get_path(src, ["effect" + no.to_string()])
  }
  fn(c) {
    for effect in effects {
      effect(c)
    }
  }
}

///|
/// The animation changes with the character level
fn new_by_level_use_effect(
  src : Json,
) -> ((@character.Character) -> Unit) raise Error {
  let effects = []
  if src is { "CharLevel": Object(level_map), .. } {
    for level, sub in level_map {
      let effect = new_skill_use_effect_effect(
        use_effect_get_path(sub, ["effect"]),
      )
      effects.push((@string.parse_int(level), effect))
    }
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

///|
/// Use effect for Iron Body
fn new_iron_body_use_effect() -> (@character.Character) -> Unit {
  fn(c) { c.show_iron_body() }
}

///|
fn use_effect_get_path(json : Json, keys : Array[String]) -> Json {
  let mut current = json
  for key in keys {
    current = match current {
      Object(obj) => obj.get(key).unwrap_or(Json::null())
      _ => Json::null()
    }
  }
  current
}
