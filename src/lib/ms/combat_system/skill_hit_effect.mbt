///|
struct NxHitEffect {
  mx_animation : String
  pos : Int
  z : Int
}

///|
pub impl @json.FromJson for NxHitEffect with from_json(json, path) {
  let parse_int_like = fn(field : String) -> Int raise @json.JsonDecodeError {
    match json {
      Object(obj) =>
        match obj.get(field) {
          Some(Number(v, ..)) => v.to_int()
          Some(String(raw)) =>
            @string.parse_int(raw) catch {
              _ =>
                raise @json.JsonDecodeError(
                  (path.add_key(field), "invalid int-like value"),
                )
            }
          Some(_) =>
            raise @json.JsonDecodeError(
              (path.add_key(field), "invalid int-like value"),
            )
          None => 0
        }
      _ => raise @json.JsonDecodeError((path, "expect object"))
    }
  }
  let mx_animation = match json {
    { "mx_animation": String(path_), .. } => path_
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("mx_animation"), "missing mx_animation"),
      )
  }
  let pos = parse_int_like("pos")
  let z = parse_int_like("z")
  { mx_animation, pos, z }
}

///|
priv struct LoadedHitEffect {
  effect : @graphics.EffectAnimation
  pos : Int
  z : Int
}

///|
async fn load_hit_effect(
  src : NxHitEffect,
  tag : String,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> LoadedHitEffect {
  let resolved = @resource.resolve_ref(base_path, src.mx_animation)
  let animation_loader = @resource.AnimationLoader::new(skill_loader)
  let loaded = animation_loader.load(resolved)
  let clip = loaded.clip(tag) catch {
    _ => abort("missing animation tag '\{tag}': \{resolved}")
  }
  {
    effect: {
      animation: @ms_animation.from_selene_clip(clip, loop_=false),
      duration_ms: clip.duration_ms,
    },
    pos: src.pos,
    z: src.z,
  }
}

///|
struct NxHitEntry {
  hit : Array[NxHitEffect]
}

///|
pub impl @json.FromJson for NxHitEntry with from_json(json, path) {
  let hit = match json {
    { "hit": hit, .. } =>
      @resource.parse_map_based_array(hit, path=path.add_key("hit"))
    _ => []
  }
  { hit, }
}

///|
priv struct NxTwoHandedHit {
  main : NxHitEffect
  second : NxHitEffect
}

///|
fn NxTwoHandedHit::from_hit_array(hits : Array[NxHitEffect]) -> NxTwoHandedHit? {
  match (hits.get(0), hits.get(1)) {
    (Some(main), Some(second)) => Some({ main, second })
    _ => None
  }
}

///|
struct NxCharLevelHit(Map[Int, NxHitEntry])

///|
pub impl @json.FromJson for NxCharLevelHit with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let levels = Map([])
  for level, value in obj {
    let entry : NxHitEntry = @json.from_json(value, path=path.add_key(level))
    let parsed_level = @string.parse_int(level) catch {
      _ =>
        raise @json.JsonDecodeError((path.add_key(level), "expect numeric key"))
    }
    levels.set(parsed_level, entry)
  }
  NxCharLevelHit(levels)
}

///|
struct NxSkillLevelHit(Map[Int, NxHitEntry])

///|
pub impl @json.FromJson for NxSkillLevelHit with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let levels = Map([])
  for level, value in obj {
    let entry : NxHitEntry = @json.from_json(value, path=path.add_key(level))
    let parsed_level = @string.parse_int(level) catch {
      _ =>
        raise @json.JsonDecodeError((path.add_key(level), "expect numeric key"))
    }
    levels.set(parsed_level, entry)
  }
  NxSkillLevelHit(levels)
}

///|
async fn new_hit_effect(
  res : NxHitEffect,
  tag : String,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> (@monster.Mob, Bool) -> Unit {
  let loaded = load_hit_effect(res, tag, skill_loader, base_path)
  fn(target : @monster.Mob, flip : Bool) -> Unit {
    target.show_effect(loaded.effect, loaded.pos, loaded.z, flip)
  }
}

///|
/// A single animation
pub async fn new_single_hit_effect(
  res : NxHitEffect,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> (@combat_proto.AttackUser, @monster.Mob) -> Unit {
  let f = new_hit_effect(
    res,
    skill_animation_tag(["hit", "0"]),
    skill_loader,
    base_path,
  )
  fn(user : @combat_proto.AttackUser, target : @monster.Mob) -> Unit {
    f(target, user.flip)
  }
}

///|
/// The animation changes depending on the weapon used
pub async fn new_twohanded_hit_effect(
  hit0 : NxHitEffect,
  hit1 : NxHitEffect,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> (@combat_proto.AttackUser, @monster.Mob) -> Unit {
  let effects = @utils.BoolPair::new(
    new_hit_effect(
      hit0,
      skill_animation_tag(["hit", "0"]),
      skill_loader,
      base_path,
    ),
    new_hit_effect(
      hit1,
      skill_animation_tag(["hit", "1"]),
      skill_loader,
      base_path,
    ),
  )
  fn(user : @combat_proto.AttackUser, target : @monster.Mob) -> Unit {
    effects[user.second_weapon](target, user.flip)
  }
}

///|
/// The animation changes with the character level
pub async fn new_by_level_hit_effect(
  src : Json,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> ((@combat_proto.AttackUser, @monster.Mob) -> Unit) raise Error {
  let effects = []
  let by_level : NxCharLevelHit = @json.from_json(
    hit_effect_get_path(src, ["CharLevel"]),
  )
  for level, entry in by_level.0 {
    match entry.hit.get(0) {
      Some(hit0) =>
        effects.push(
          (
            level,
            new_hit_effect(
              hit0,
              skill_animation_tag(["CharLevel", level.to_string(), "hit", "0"]),
              skill_loader,
              base_path,
            ),
          ),
        )
      None => ()
    }
  }
  effects.sort_by_key(fn(it) { it.0 })
  fn(user : @combat_proto.AttackUser, target : @monster.Mob) -> Unit {
    if effects.is_empty() {
      return
    }
    let mut iter = 0
    while iter < effects.length() && user.level > effects[iter].0 {
      iter += 1
    }
    if iter > 0 {
      iter -= 1
    }
    (effects[iter].1)(target, user.flip)
  }
}

///|
/// The animation changes with the character level and weapon used
pub async fn new_by_level_twohanded_hit_effect(
  src : Json,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> ((@combat_proto.AttackUser, @monster.Mob) -> Unit) raise Error {
  let effects = []
  let by_level : NxCharLevelHit = @json.from_json(
    hit_effect_get_path(src, ["CharLevel"]),
  )
  for level, entry in by_level.0 {
    match NxTwoHandedHit::from_hit_array(entry.hit) {
      Some(pair) =>
        effects.push(
          (
            level,
            @utils.BoolPair::new(
              new_hit_effect(
                pair.main,
                skill_animation_tag(["CharLevel", level.to_string(), "hit", "0"]),
                skill_loader,
                base_path,
              ),
              new_hit_effect(
                pair.second,
                skill_animation_tag(["CharLevel", level.to_string(), "hit", "1"]),
                skill_loader,
                base_path,
              ),
            ),
          ),
        )
      None => ()
    }
  }
  effects.sort_by_key(fn(it) { it.0 })
  fn(user : @combat_proto.AttackUser, target : @monster.Mob) -> Unit {
    if effects.is_empty() {
      return
    }
    let mut iter = 0
    while iter < effects.length() && user.level > effects[iter].0 {
      iter += 1
    }
    if iter > 0 {
      iter -= 1
    }
    effects[iter].1[user.second_weapon](target, user.flip)
  }
}

///|
/// The animation changes with the skill level
pub async fn new_by_skill_level_hit_effect(
  src : Json,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> ((@combat_proto.AttackUser, @monster.Mob) -> Unit) raise Error {
  let effects = Map([])
  let by_level : NxSkillLevelHit = @json.from_json(
    hit_effect_get_path(src, ["level"]),
  )
  for level, entry in by_level.0 {
    match entry.hit.get(0) {
      Some(hit0) =>
        effects.set(
          level,
          new_hit_effect(
            hit0,
            skill_animation_tag(["level", level.to_string(), "hit", "0"]),
            skill_loader,
            base_path,
          ),
        )
      None => ()
    }
  }
  fn(user : @combat_proto.AttackUser, target : @monster.Mob) -> Unit {
    match effects.get(user.skill_level) {
      Some(effect) => effect(target, user.flip)
      None => ()
    }
  }
}

///|
fn hit_effect_get_path(json : Json, keys : Array[String]) -> Json {
  let mut current = json
  for key in keys {
    current = match current {
      Object(obj) => obj.get(key).unwrap_or(Json::null())
      _ => Json::null()
    }
  }
  current
}
