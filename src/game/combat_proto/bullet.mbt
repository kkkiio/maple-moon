///|
struct Bullet {
  move_obj : @physics.MovingObject
}

///|
/// A projectile sprite clip together with its reusable playback graph.
pub struct BulletAnimation {
  clip : @res.SpriteClip
  graph : @animation.AnimationGraphHandle
  node : @animation.AnimationNodeIndex
}

///|
/// Register a single-clip playback graph for a projectile.
///
/// # Example
/// ```moonbit nocheck
/// let animation = BulletAnimation(clip)
/// ignore(animation)
/// ```
pub fn BulletAnimation::BulletAnimation(
  clip : @res.SpriteClip,
) -> BulletAnimation {
  let (graph, node) = @graphics.sprite_clip_graph(clip)
  { clip, graph, node }
}

///|
pub fn Bullet::Bullet(
  entity : @entity.Entity,
  animation : BulletAnimation,
  origin : @struct.Point[Int],
  toleft : Bool,
) -> Bullet {
  @sprite.sprites().set(entity, animation.clip.sprite(flip_x=!toleft))
  @animation.animation_target_ids().set(
    entity,
    @animation.AnimationTargetId("self"),
  )
  @animation.animated_bys().set(entity, @animation.AnimatedBy(entity))
  @animation.animation_graph_handles().set(entity, animation.graph)
  let player = @animation.AnimationPlayer()
  @animation.animation_players().set(entity, player)
  ignore(
    player.start(animation.node, repeat=@animation.RepeatAnimation::Forever),
  )

  let move_obj = MovingObject(on_pos_change=fn(pos) {
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

///|
using @physics {type MovingObject}
