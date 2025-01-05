///|
struct Ball {
  animation : @graphics.Animation
}

///|
fn Ball::new(src : @resource.NxNode) -> Ball! {
  { animation: src |> @graphics.Animation::from_resource_ex!() }
}

///|
struct SkillRegularBullet {} derive(Default)

///|
fn SkillRegularBullet::new() -> SkillRegularBullet {
  SkillRegularBullet::default()
}

///|
fn get(
  self : SkillRegularBullet,
  user : @character.Character,
  bulletid : Int
) -> @utils.Future[@graphics.Animation] {
  @bullet.BulletData::get_async(bulletid).map(fn(data) {
    data.unwrap() // TODO: handle error
    .bullet
  })
}

///|
struct SingleBullet {
  ball : Ball
}

///|
fn SingleBullet::new(src : @resource.NxNode) -> SingleBullet! {
  { ball: Ball::new!(src["ball"]) }
}

///|
fn get(
  self : SingleBullet,
  user : @character.Character,
  bulletid : Int
) -> @graphics.Animation {
  self.ball.animation
}

///|
struct BySkillLevelBullet {
  bullets : Map[Int, Ball]
  skill_id : Int
}

///|
fn BySkillLevelBullet::new(
  src : @resource.NxNode,
  id : Int
) -> BySkillLevelBullet! {
  let bullets = Map::new()
  for sub in src["level"] {
    let level = @strconv.parse_int!(sub.name())
    bullets.set(level, Ball::new!(sub["ball"]))
  }
  { bullets, skill_id: id }
}

///|
fn get(
  self : BySkillLevelBullet,
  user : @character.Character,
  bulletid : Int
) -> @graphics.Animation {
  let level = (user.get_skilllevel)(self.skill_id)
  match self.bullets.get(level) {
    Some(ball) => ball.animation
    None => @graphics.Animation::default()
  }
}
