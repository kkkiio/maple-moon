///|
struct NxHitEffect {
  animation : @resource.NxAnimation
  pos : Int
  z : Int
}

///|
pub impl @json.FromJson for NxHitEffect with from_json(json, path) {
  let animation = @json.from_json(json, path~)
  let pos = match json {
    { "pos": Number(pos, ..), .. } => pos.to_int()
    _ => 0
  }
  let z = match json {
    { "z": Number(z, ..), .. } => z.to_int()
    _ => 0
  }
  { animation, pos, z }
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
  let levels = Map::new()
  for level, value in obj {
    let entry : NxHitEntry = @json.from_json(value, path=path.add_key(level))
    let parsed_level = @strconv.parse_int(level) catch {
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
  let levels = Map::new()
  for level, value in obj {
    let entry : NxHitEntry = @json.from_json(value, path=path.add_key(level))
    let parsed_level = @strconv.parse_int(level) catch {
      _ =>
        raise @json.JsonDecodeError((path.add_key(level), "expect numeric key"))
    }
    levels.set(parsed_level, entry)
  }
  NxSkillLevelHit(levels)
}

///|
fn new_hit_effect(res : NxHitEffect) -> (@monster.Mob, Bool) -> Unit {
  let animation = res.animation
  let pos = res.pos
  let z = res.z
  fn(target : @monster.Mob, flip : Bool) -> Unit {
    target.show_effect(animation, pos, z, flip)
  }
}

///|
/// A single animation
fn new_single_hit_effect(
  res : NxHitEffect,
) -> (@combat_proto.AttackUser, @monster.Mob) -> Unit {
  let f = new_hit_effect(res)
  fn(user : @combat_proto.AttackUser, target : @monster.Mob) -> Unit {
    f(target, user.flip)
  }
}

///|
/// The animation changes depending on the weapon used
fn new_twohanded_hit_effect(
  hit0 : NxHitEffect,
  hit1 : NxHitEffect,
) -> (@combat_proto.AttackUser, @monster.Mob) -> Unit {
  let effects = @utils.BoolPair::new(new_hit_effect(hit0), new_hit_effect(hit1))
  fn(user : @combat_proto.AttackUser, target : @monster.Mob) -> Unit {
    effects[user.second_weapon](target, user.flip)
  }
}

///|
/// The animation changes with the character level
fn new_by_level_hit_effect(
  src : Json,
) -> ((@combat_proto.AttackUser, @monster.Mob) -> Unit) raise Error {
  let effects = []
  let by_level : NxCharLevelHit = @json.from_json(
    hit_effect_get_path(src, ["CharLevel"]),
  )
  for level, entry in by_level.0 {
    match entry.hit.get(0) {
      Some(hit0) => effects.push((level, new_hit_effect(hit0)))
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
fn new_by_level_twohanded_hit_effect(
  src : Json,
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
              new_hit_effect(pair.main),
              new_hit_effect(pair.second),
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
fn new_by_skill_level_hit_effect(
  src : Json,
) -> ((@combat_proto.AttackUser, @monster.Mob) -> Unit) raise Error {
  let effects = Map::new()
  let by_level : NxSkillLevelHit = @json.from_json(
    hit_effect_get_path(src, ["level"]),
  )
  for level, entry in by_level.0 {
    match entry.hit.get(0) {
      Some(hit0) => effects.set(level, new_hit_effect(hit0))
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
