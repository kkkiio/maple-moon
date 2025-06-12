///|
priv struct Ball {
  animation : @graphics.Animation
}

///|
fn Ball::new(src : @resource.NxNode) -> Ball! {
  { animation: src |> @graphics.Animation::from_resource_ex!() }
}

///|
priv struct SkillRegularBullet {
  string_loader : @resource.SyncLoader
}

///|
fn SkillRegularBullet::new(
  string_loader : @resource.SyncLoader
) -> SkillRegularBullet {
  { string_loader, }
}

///|
async fn SkillRegularBullet::get(
  self : SkillRegularBullet,
  _ : @character.Character,
  bulletid : Int
) -> @graphics.Animation! {
  let data = @bullet.BulletData::get_async(bulletid, self.string_loader)
  data.bullet
}

///|
priv struct SingleBullet {
  ball : Ball
}

///|
fn SingleBullet::new(src : @resource.NxNode) -> SingleBullet! {
  { ball: Ball::new!(src["ball"]) }
}

///|
fn SingleBullet::get(
  self : SingleBullet,
  _ : @character.Character,
  _ : Int
) -> @graphics.Animation {
  self.ball.animation
}

///|
priv struct BySkillLevelBullet {
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
fn BySkillLevelBullet::get(
  self : BySkillLevelBullet,
  user : @character.Character,
  _ : Int
) -> @graphics.Animation {
  let level = (user.get_skilllevel)(self.skill_id)
  match self.bullets.get(level) {
    Some(ball) => ball.animation
    None => @graphics.Animation::default()
  }
}
