struct Bullet {
  animation : @graphics.Animation
  move_obj : @physics.MovingObject
  flip : Bool
}

pub fn Bullet::new(
  a : @graphics.Animation,
  origin : @struct.Point[Int],
  toleft : Bool
) -> Bullet {
  let move_obj = @physics.MovingObject::default()
  move_obj.set_x(origin.x.to_double() + (if toleft { -30.0 } else { 30.0 }))
  move_obj.set_y(origin.y.to_double() - 26.0)
  { animation: a, move_obj, flip: toleft }
}

pub fn draw(
  self : Bullet,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  let bulletpos = self.move_obj.get_absolute(viewx, viewy, alpha)
  let args = @graphics.DrawArgument::new14(bulletpos, self.flip)
  self.animation.draw(args, alpha)
}

pub fn Bullet::update(self : Bullet, target : @struct.Point[Int]) -> Bool {
  self.animation.update() |> ignore
  self.move_obj.move()
  let xdelta = target.x - self.move_obj.get_x()
  if self.move_obj.hspeed > 0.0 {
    xdelta < 10
  } else {
    xdelta > 10
  }
}
