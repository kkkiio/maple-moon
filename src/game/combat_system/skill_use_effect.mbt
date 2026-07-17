///|
priv struct SkillUseEffect {
  effect : @graphics.EffectAnimation
  z : Int
}

///|
fn read_mx_animation_ref(src : Json) -> String raise {
  match src {
    { "mx_animation": String(path), .. } => path
    _ => fail("missing mx_animation in skill use effect node")
  }
}

///|
fn read_effect_z(src : Json) -> Int raise {
  match src {
    { "z": Number(z, ..), .. } => z.to_int()
    { "z": String(raw), .. } =>
      @string.parse_int(raw) catch {
        _ => fail("invalid z in skill use effect node")
      }
    _ => 0
  }
}

///|
fn load_skill_use_effect(
  src : Json,
  tag : String,
  base_path : String,
) -> SkillUseEffect raise {
  let ref_path = read_mx_animation_ref(src) catch {
    error => fail("missing mx_animation in skill use effect node: \{error}")
  }
  let resolved = @res.resolve_ref(base_path, ref_path)
  let animation_loader = AnimationLoader()
  let loaded = animation_loader.load(resolved)
  let clip = loaded.clip(tag) catch {
    error =>
      fail(
        "missing skill use effect animation tag '\{tag}': \{resolved}, error=\{error}",
      )
  }
  { effect: @graphics.EffectAnimation(clip), z: read_effect_z(src) }
}

///|
fn apply_skill_use_effect(
  loaded : SkillUseEffect,
) -> (@character.Character) -> Unit {
  fn(c : @character.Character) -> Unit {
    c.show_attack_effect(loaded.effect, loaded.z)
  }
}

///|
/// An effect which displays an animation over the character's position
///
/// # Example
/// ```moonbit nocheck
/// let effect = try! new_single_use_effect(src, "res://Skill/110.img.json")
/// ignore(effect)
/// ```
///
/// # Errors
/// Raises when the referenced animation or expected tag cannot be loaded.
pub fn new_single_use_effect(
  src : Json,
  base_path : String,
) -> ((@character.Character) -> Unit) raise {
  let effect = load_skill_use_effect(
    use_effect_get_path(src, ["effect"]),
    skill_animation_tag(["effect"]),
    base_path,
  )
  apply_skill_use_effect(effect)
}

///|
/// An effect which displays an animation over the character's position
/// The effect changes based on whether the character uses a two-handed weapon
///
/// # Example
/// ```moonbit nocheck
/// let effect = try! new_twohanded_use_effect(
///   src,
///   "res://Skill/110.img.json",
/// )
/// ignore(effect)
/// ```
///
/// # Errors
/// Raises when either referenced animation or expected tag cannot be loaded.
pub fn new_twohanded_use_effect(
  src : Json,
  base_path : String,
) -> ((@character.Character) -> Unit) raise {
  let effects = BoolPair(
    apply_skill_use_effect(
      load_skill_use_effect(
        use_effect_get_path(src, ["effect", "0"]),
        skill_animation_tag(["effect", "0"]),
        base_path,
      ),
    ),
    apply_skill_use_effect(
      load_skill_use_effect(
        use_effect_get_path(src, ["effect", "1"]),
        skill_animation_tag(["effect", "1"]),
        base_path,
      ),
    ),
  )
  fn(c : @character.Character) -> Unit {
    let twohanded = c.is_two_handed()
    effects[twohanded](c)
  }
}

///|
/// An effect which displays multiple animations over the character's position
///
/// # Example
/// ```moonbit nocheck
/// let effect = try! new_multi_use_effect(src, "res://Skill/110.img.json")
/// ignore(effect)
/// ```
///
/// # Errors
/// Raises when any referenced animation or expected tag cannot be loaded.
pub fn new_multi_use_effect(
  src : Json,
  base_path : String,
) -> ((@character.Character) -> Unit) raise {
  let effects = []
  let mut no = -1
  let mut sub = use_effect_get_path(src, ["effect"])
  while sub != Json::null() {
    let tag = if no < 0 {
      skill_animation_tag(["effect"])
    } else {
      skill_animation_tag(["effect\{no}"])
    }
    effects.push(
      apply_skill_use_effect(load_skill_use_effect(sub, tag, base_path)),
    )
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
///
/// # Example
/// ```moonbit nocheck
/// let effect = try! new_by_level_use_effect(
///   src,
///   "res://Skill/110.img.json",
/// )
/// ignore(effect)
/// ```
///
/// # Errors
/// Raises when a level key, animation reference, or expected tag is invalid.
pub fn new_by_level_use_effect(
  src : Json,
  base_path : String,
) -> ((@character.Character) -> Unit) raise {
  let effects = []
  if src is { "CharLevel": Object(level_map), .. } {
    for level, sub in level_map {
      let effect = apply_skill_use_effect(
        load_skill_use_effect(
          use_effect_get_path(sub, ["effect"]),
          skill_animation_tag(["CharLevel", level, "effect"]),
          base_path,
        ),
      )
      let parsed_level = @string.parse_int(level) catch {
        _ => fail("invalid skill use effect level: \{level}")
      }
      effects.push((parsed_level, effect))
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
pub fn new_iron_body_use_effect() -> (@character.Character) -> Unit {
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
