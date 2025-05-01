///|
fn new_hit_effect(
  src : @resource.NxNode
) -> ((@monster.Mob, Bool) -> Unit)!Error {
  let animation = src |> @graphics.Animation::from_resource_ex!()
  let pos = src["pos"].get_int!()
  let z = src["z"].get_int!()
  fn(target : @monster.Mob, flip : Bool) -> Unit {
    target.show_effect(animation, pos, z, flip)
  }
}

///| A single animation
fn new_single_hit_effect(
  src : @resource.NxNode
) -> ((@combat.AttackUser, @monster.Mob) -> Unit)!Error {
  let f = new_hit_effect!(src)
  fn(user : @combat.AttackUser, target : @monster.Mob) -> Unit {
    f(target, user.flip)
  }
}

///| The animation changes depending on the weapon used
fn new_twohanded_hit_effect(
  src : @resource.NxNode
) -> ((@combat.AttackUser, @monster.Mob) -> Unit)!Error {
  let effects = @utils.BoolPair::new(
    new_hit_effect!(src["hit"]["0"]),
    new_hit_effect!(src["hit"]["1"]),
  )
  fn(user : @combat.AttackUser, target : @monster.Mob) -> Unit {
    effects[user.second_weapon](target, user.flip)
  }
}

///| The animation changes with the character level
fn new_by_level_hit_effect(
  src : @resource.NxNode
) -> ((@combat.AttackUser, @monster.Mob) -> Unit)!Error {
  let effects = []
  for sub in src["CharLevel"] {
    let level = @strconv.parse_int!(sub.name())
    let effect = new_hit_effect!(sub["hit"]["0"])
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
) -> ((@combat.AttackUser, @monster.Mob) -> Unit)!Error {
  let effects = []
  for sub in src["CharLevel"] {
    let level = @strconv.parse_int!(sub.name())
    let effect_pair = @utils.BoolPair::new(
      new_hit_effect!(sub["hit"]["0"]),
      new_hit_effect!(sub["hit"]["1"]),
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
) -> ((@combat.AttackUser, @monster.Mob) -> Unit)!Error {
  let effects = Map::new()
  for sub in src["level"] {
    let level = @strconv.parse_int!(sub.name())
    let effect = new_hit_effect!(sub["hit"]["0"])
    effects.set(level, effect)
  }
  fn(user : @combat.AttackUser, target : @monster.Mob) -> Unit {
    match effects.get(user.skill_level) {
      Some(effect) => effect(target, user.flip)
      None => ()
    }
  }
}
