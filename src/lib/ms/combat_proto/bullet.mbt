///|
struct Bullet {
  move_obj : @physics.MovingObject
}

///|
pub fn Bullet::new(
  entity : @entity.Entity,
  animation : @resource.NxAnimation,
  origin : @struct.Point[Int],
  toleft : Bool,
) -> Bullet {
  let sprite_animation = @ms_animation.from_nx_animation(animation, loop_=true)
  let transform = if toleft {
    @selene_math.Transform::new()
  } else {
    @selene_math.Transform::from_scale(-1.0, 1.0)
  }
  let sprite = @ms_animation.sprite_from_animation(
    sprite_animation,
    @graphics.CHAR_LOOK_ZINDEX + 100,
    transform~,
  )
  @sprite.sprites().set(entity, sprite)
  @ms_animation.play_animation(entity, sprite_animation, loop_=true, transform~)

  let move_obj = @physics.MovingObject::new(on_pos_change=fn(pos) {
    @transform2d.set_xy(entity, pos)
  })
  move_obj.set_x(origin.x.to_double() + (if toleft { -30.0 } else { 30.0 }))
  move_obj.set_y(origin.y.to_double() - 26.0)
  { move_obj, }
}

///|
pub fn Bullet::update(self : Bullet, target : @struct.Point[Int]) -> Bool {
  self.move_obj.do_move()
  let xdelta = target.x - self.move_obj.get_x()
  if self.move_obj.hspeed > 0.0 {
    xdelta < 10
  } else {
    xdelta > 10
  }
}

///|
pub fn Bullet::set_target(self : Bullet, target : @struct.Point[Int]) -> Bool {
  let xdelta = target.x - self.move_obj.get_x()
  let ydelta = target.y - self.move_obj.get_y()
  if xdelta.abs() < 10 {
    return true
  }
  self.move_obj.set_hspeed(xdelta.to_double() / 32.0)
  if xdelta > 0 {
    if self.move_obj.hspeed < 3.0 {
      self.move_obj.set_hspeed(3.0)
    } else if self.move_obj.hspeed > 6.0 {
      self.move_obj.set_hspeed(6.0)
    }
  } else if xdelta < 0 {
    if self.move_obj.hspeed > -3.0 {
      self.move_obj.set_hspeed(-3.0)
    } else if self.move_obj.hspeed < -6.0 {
      self.move_obj.set_hspeed(-6.0)
    }
  }
  self.move_obj.set_vspeed(
    self.move_obj.hspeed * ydelta.to_double() / xdelta.to_double(),
  )
  return false
}
