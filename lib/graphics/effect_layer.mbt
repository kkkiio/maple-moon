///| A list of animations. Animations will be removed after all frames were displayed.
struct EffectLayer {
  effects : @sorted_map.T[Int, Array[Effect]]
}

///|
pub fn EffectLayer::default() -> EffectLayer {
  { effects: @sorted_map.new() }
}

///|
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

///|
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

///|
pub fn EffectLayer::update(self : EffectLayer) -> Unit {
  for _, effectlist in self.effects {
    effectlist.retain(fn(effect : Effect) -> Bool { not(effect.update()) })
  }
}

///|
pub fn EffectLayer::add(
  self : EffectLayer,
  animation : Animation,
  args~ : DrawArgument = DrawArgument::default(),
  z~ : Int = 0,
  speed~ : Double = 1.0
) -> Unit {
  match self.effects[z] {
    Some(effects) =>
      effects.push({ sprite: Sprite::new(animation, args), speed })
    None => self.effects[z] = [{ sprite: Sprite::new(animation, args), speed }]
  }
}

///|
struct Effect {
  sprite : Sprite
  speed : Double
}

///|
pub fn Effect::update(self : Effect) -> Bool {
  self.sprite.update(
    timestep=(@constants.step_time_ms.to_double() * self.speed).to_int(),
  )
}

///|
pub fn Effect::draw(
  self : Effect,
  position : Point[Int],
  alpha : Double
) -> Unit {
  self.sprite.draw(position, alpha)
}
