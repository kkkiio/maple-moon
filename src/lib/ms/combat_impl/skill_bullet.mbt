///|
priv struct Ball {
  animation : @graphics.Animation
}

///|
fn Ball::new(src : @resource.NxNode) -> Ball raise {
  { animation: src |> @graphics.Animation::from_resource_ex() }
}

///|
priv struct SkillRegularBullet {
  bullet_module : @bullet.Module
}

///|
fn SkillRegularBullet::new(
  bullet_module : @bullet.Module
) -> SkillRegularBullet {
  { bullet_module, }
}

///|
fn SkillRegularBullet::get(
  self : SkillRegularBullet,
  _ : @character.Character,
  bulletid : Int
) -> @graphics.Animation {
  let data = self.bullet_module.get_bullet_data(bulletid).unwrap()
  data.bullet
}

///|
priv struct SingleBullet {
  ball : Ball
}

///|
fn SingleBullet::new(src : @resource.NxNode) -> SingleBullet raise {
  { ball: Ball::new(src["ball"]) }
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
) -> BySkillLevelBullet raise {
  let bullets = Map::new()
  for sub in src["level"] {
    let level = @strconv.parse_int(sub.name())
    bullets.set(level, Ball::new(sub["ball"]))
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
