/// A list of animations. Animations will be removed after all frames were displayed.
struct EffectLayer {
  effects : @sorted_map.T[Int, Array[Effect]]
}

pub fn EffectLayer::default() -> EffectLayer {
  { effects: @sorted_map.new() }
}

pub fn EffectLayer::drawbelow(
  self : EffectLayer,
  position : Point[Int],
  alpha : Double
) -> Unit {
  // draw (-inf,-1]
  for k, v in self.effects {
    if k > -1 {
      break
    }
    for effect in v {
      effect.draw(position, alpha)
    }
  }
}

pub fn EffectLayer::drawabove(
  self : EffectLayer,
  position : Point[Int],
  alpha : Double
) -> Unit {
  // draw (-1,+inf)
  for k, v in self.effects {
    if k < -1 { // TODO: optimize 
      continue
    }
    for effect in v {
      effect.draw(position, alpha)
    }
  }
}

pub fn EffectLayer::update(self : EffectLayer) -> Unit {
  for _, effectlist in self.effects {
    effectlist.retain(fn(effect : Effect) -> Bool { effect.update().not() })
  }
}

struct Effect {
  sprite : Sprite
  speed : Double
}

pub fn Effect::update(self : Effect) -> Bool {
  self.sprite.update_with_timestep(
    (@constants.timestep.to_double() * self.speed).to_int(),
  )
}

pub fn Effect::draw(
  self : Effect,
  position : Point[Int],
  alpha : Double
) -> Unit {
  self.sprite.draw(position, alpha)
}
