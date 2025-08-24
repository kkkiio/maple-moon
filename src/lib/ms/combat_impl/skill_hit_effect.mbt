///|
struct HitEffectNxResource {
  animation : @graphics.AnimationResource
  pos : Int
  z : Int
}

///|
pub impl @json.FromJson for HitEffectNxResource with from_json(json, path) {
  let animation = @json.from_json(json, path~)
  let pos = match json {
    { "pos": Number(pos), .. } => pos.to_int()
    _ => 0
  }
  let z = match json {
    { "z": Number(z), .. } => z.to_int()
    _ => 0
  }
  { animation, pos, z }
}

///|
fn new_hit_effect(res : HitEffectNxResource) -> (@monster.Mob, Bool) -> Unit {
  let animation = @graphics.Animation::new(
    res.animation,
    "",
    @resource.ImageLoader::get_path_image_loader(),
  )
  let pos = res.pos
  let z = res.z
  fn(target : @monster.Mob, flip : Bool) -> Unit {
    target.show_effect(animation, pos, z, flip)
  }
}

///| A single animation
fn new_single_hit_effect(
  res : HitEffectNxResource
) -> (@combat.AttackUser, @monster.Mob) -> Unit {
  let f = new_hit_effect(res)
  fn(user : @combat.AttackUser, target : @monster.Mob) -> Unit {
    f(target, user.flip)
  }
}

///| The animation changes depending on the weapon used
fn new_twohanded_hit_effect(
  hit0 : HitEffectNxResource,
  hit1 : HitEffectNxResource
) -> (@combat.AttackUser, @monster.Mob) -> Unit {
  let effects = @utils.BoolPair::new(new_hit_effect(hit0), new_hit_effect(hit1))
  fn(user : @combat.AttackUser, target : @monster.Mob) -> Unit {
    effects[user.second_weapon](target, user.flip)
  }
}

///| The animation changes with the character level
fn new_by_level_hit_effect(
  src : @resource.NxNode
) -> ((@combat.AttackUser, @monster.Mob) -> Unit) raise Error {
  let effects = []
  for sub in src["CharLevel"] {
    let level = @strconv.parse_int(sub.name())
    let hit0 = @json.from_json(sub["hit"]["0"].value())
    let effect = new_hit_effect(hit0)
    effects.push((level, effect))
  }
  effects.sort_by_key(fn(it) { it.0 })
  fn(user : @combat.AttackUser, target : @monster.Mob) -> Unit {
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

///| The animation changes with the character level and weapon used
fn new_by_level_twohanded_hit_effect(
  src : @resource.NxNode
) -> ((@combat.AttackUser, @monster.Mob) -> Unit) raise Error {
  let effects = []
  for sub in src["CharLevel"] {
    let level = @strconv.parse_int(sub.name())
    let hit0 = @json.from_json(sub["hit"]["0"].value())
    let hit1 = @json.from_json(sub["hit"]["1"].value())
    let effect_pair = @utils.BoolPair::new(
      new_hit_effect(hit0),
      new_hit_effect(hit1),
    )
    effects.push((level, effect_pair))
  }
  effects.sort_by_key(fn(it) { it.0 })
  fn(user : @combat.AttackUser, target : @monster.Mob) -> Unit {
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

///| The animation changes with the skill level
fn new_by_skill_level_hit_effect(
  src : @resource.NxNode
) -> ((@combat.AttackUser, @monster.Mob) -> Unit) raise Error {
  let effects = Map::new()
  for sub in src["level"] {
    let level = @strconv.parse_int(sub.name())
    let hit0 = @json.from_json(sub["hit"]["0"].value())
    let effect = new_hit_effect(hit0)
    effects.set(level, effect)
  }
  fn(user : @combat.AttackUser, target : @monster.Mob) -> Unit {
    match effects.get(user.skill_level) {
      Some(effect) => effect(target, user.flip)
      None => ()
    }
  }
}
