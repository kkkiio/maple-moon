///|
pub(all) struct Sprite {
  mut animation : Animation
  mut state_args : DrawArgument
} derive(Default)

///|
pub fn Sprite::new(animation : Animation, state_args : DrawArgument) -> Sprite {
  { animation, state_args }
}

///|
pub fn Sprite::from_resource(
  src : NxNode,
  state_args~ : DrawArgument = DrawArgument::default()
) -> Sprite {
  Sprite::new(Animation::from_resource(src), state_args)
}

///|
pub fn Sprite::draw(
  self : Sprite,
  parentpos : Point[Int],
  alpha : Double
) -> Unit {
  let absargs = self.state_args.add_pos(parentpos)
  self.animation.draw(absargs, alpha)
}

///|
pub fn update(self : Sprite, timestep~ : Int = @config.step_time_ms) -> Bool {
  self.animation.update(timestep~)
}

///|
pub fn reset(self : Sprite) -> Unit {
  self.animation.reset()
}

///|
pub fn width(self : Sprite) -> Int {
  self.get_dimensions().x
}

///|
pub fn height(self : Sprite) -> Int {
  self.get_dimensions().y
}

///|
pub fn get_origin(self : Sprite) -> Point[Int] {
  self.animation.get_origin()
}

///|
pub fn get_dimensions(self : Sprite) -> Point[Int] {
  self.animation.get_dimensions()
}

///|
pub impl ToJson for Sprite with to_json(self) -> Json {
  ignore(self)
  {} // TODO
}
