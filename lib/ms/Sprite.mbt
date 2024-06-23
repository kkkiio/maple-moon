pub struct Sprite {
  mut animation : Animation
  mut state_args : DrawArgument
} derive(Default)

pub fn new_sprite(animation : Animation, state_args : DrawArgument) -> Sprite {
  { animation, state_args }
}

pub fn new_sprite_from_node(
  src : NxNode,
  state_args : DrawArgument
) -> Sprite {
  { animation: Animation::from_resource(src), state_args }
}

pub fn new_sprite_from_node_only(src : NxNode) -> Sprite {
  new_sprite_from_node(src, DrawArgument::default())
}

pub fn draw(self : Sprite, parentpos : Point[Int], alpha : Double) -> Unit {
  let absargs = self.state_args.add_pos(parentpos)
  self.animation.draw(absargs, alpha)
}

pub fn update_with_timestep(self : Sprite, timestep : Int) -> Bool {
  self.animation.update(~timestep)
}

pub fn update(self : Sprite) -> Bool {
  self.animation.update()
}

pub fn reset(self : Sprite) -> Unit {
  self.animation.reset()
}

pub fn width(self : Sprite) -> Int {
  self.get_dimensions().x
}

pub fn height(self : Sprite) -> Int {
  self.get_dimensions().y
}

pub fn get_origin(self : Sprite) -> Point[Int] {
  self.animation.get_origin()
}

pub fn get_dimensions(self : Sprite) -> Point[Int] {
  self.animation.get_dimensions()
}
