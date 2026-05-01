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
fn read_effect_z(src : Json) -> Int {
  match src {
    { "z": Number(z, ..), .. } => z.to_int()
    { "z": String(raw), .. } =>
      @string.parse_int(raw) catch {
        _ => abort("invalid z in skill use effect node")
      }
    _ => 0
  }
}

///|
async fn load_skill_use_effect(
  src : Json,
  tag : String,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> SkillUseEffect {
  let ref_path = read_mx_animation_ref(src)
  let resolved = @resource.resolve_ref(base_path, ref_path)
  let animation_loader = @resource.AnimationLoader::new(skill_loader)
  let loaded = animation_loader.load(resolved)
  let clip = loaded.clip(tag)
  {
    effect: {
      animation: @ms_animation.from_selene_clip(clip, loop_=false),
      duration_ms: clip.duration_ms,
    },
    z: read_effect_z(src),
  }
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
pub async fn new_single_use_effect(
  src : Json,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> ((@character.Character) -> Unit) raise Error {
  let effect = load_skill_use_effect(
    use_effect_get_path(src, ["effect"]),
    skill_animation_tag(["effect"]),
    skill_loader,
    base_path,
  )
  apply_skill_use_effect(effect)
}

///|
/// An effect which displays an animation over the character's position
/// The effect changes based on whether the character uses a two-handed weapon
pub async fn new_twohanded_use_effect(
  src : Json,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> ((@character.Character) -> Unit) raise Error {
  let effects = @utils.BoolPair::new(
    apply_skill_use_effect(
      load_skill_use_effect(
        use_effect_get_path(src, ["effect", "0"]),
        skill_animation_tag(["effect", "0"]),
        skill_loader,
        base_path,
      ),
    ),
    apply_skill_use_effect(
      load_skill_use_effect(
        use_effect_get_path(src, ["effect", "1"]),
        skill_animation_tag(["effect", "1"]),
        skill_loader,
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
pub async fn new_multi_use_effect(
  src : Json,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> ((@character.Character) -> Unit) raise Error {
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
      apply_skill_use_effect(
        load_skill_use_effect(sub, tag, skill_loader, base_path),
      ),
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
pub async fn new_by_level_use_effect(
  src : Json,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> ((@character.Character) -> Unit) raise Error {
  let effects = []
  if src is { "CharLevel": Object(level_map), .. } {
    for level, sub in level_map {
      let effect = apply_skill_use_effect(
        load_skill_use_effect(
          use_effect_get_path(sub, ["effect"]),
          skill_animation_tag(["CharLevel", level, "effect"]),
          skill_loader,
          base_path,
        ),
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
