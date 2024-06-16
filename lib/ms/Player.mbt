struct Player {
  char_base : CharBase
}

pub fn Player::default() -> Player {
  { char_base: CharBase::new(0, CharLook::default(), "") }
}

pub fn get_position(self : Player) -> Point[Int] {
  self.char_base.get_position()
}

pub fn is_invincible(self : Player) -> Bool {
  true
}

pub fn update(self : Player, physics : Physics) -> Unit {

}

// Respawn the player at the given position
pub fn respawn(self : Player, pos : Point[Int], underwater : Bool) -> Unit {
  self.set_position(pos.x, pos.y)
}

pub fn set_position(self : Player, x : Int, y : Int) -> Unit {
  self.char_base.set_position({ x, y })
}

pub fn draw(
  self : Player,
  layer : Int,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  if layer == self.char_base.get_layer() {
    self.char_base.draw(viewx, viewy, alpha)
  }
}
