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
  state_args? : DrawArgument = DrawArgument::default(),
) -> Sprite {
  Sprite::new(Animation::from_resource(src), state_args)
}

///|
pub fn Sprite::draw(
  self : Sprite,
  parentpos : Point[Int],
  alpha : Double,
) -> Unit {
  let absargs = self.state_args.add_pos(parentpos)
  self.animation.draw(absargs, alpha)
}

///|
pub fn Sprite::update(
  self : Sprite,
  timestep? : Int = @config.STEP_TIME_MS,
) -> Bool {
  self.animation.update(timestep~)
}

///|
pub fn Sprite::reset(self : Sprite) -> Unit {
  self.animation.reset()
}

///|
pub fn Sprite::width(self : Sprite) -> Int {
  self.get_dimensions().x
}

///|
pub fn Sprite::height(self : Sprite) -> Int {
  self.get_dimensions().y
}

///|
pub fn Sprite::get_origin(self : Sprite) -> Point[Int] {
  self.animation.get_origin()
}

///|
pub fn Sprite::get_dimensions(self : Sprite) -> Point[Int] {
  self.animation.get_dimensions()
}

///|
pub impl ToJson for Sprite with to_json(self) -> Json {
  ignore(self)
  {} // TODO
}
