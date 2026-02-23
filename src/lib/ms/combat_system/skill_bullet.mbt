///|
priv struct Ball {
  animation : @graphics.Animation
}

///|
fn Ball::new(src : Json) -> Ball raise {
  ...
}

///|
priv struct SkillRegularBullet {
  bullet_module : @bullet.Module
}

///|
fn SkillRegularBullet::new(
  bullet_module : @bullet.Module,
) -> SkillRegularBullet {
  { bullet_module, }
}

///|
fn SkillRegularBullet::get(
  self : SkillRegularBullet,
  _ : @character.Character,
  bulletid : Int,
) -> @graphics.Animation {
  let data = self.bullet_module.get_bullet_data(bulletid).unwrap()
  data.bullet
}

///|
priv struct SingleBullet {
  ball : Ball
}

///|
fn SingleBullet::new(src : Json) -> SingleBullet raise {
  let ball = match src {
    { "ball": ball, .. } => Ball::new(ball)
    _ => Ball::new(Json::null())
  }
  { ball, }
}

///|
fn SingleBullet::get(
  self : SingleBullet,
  _ : @character.Character,
  _ : Int,
) -> @graphics.Animation {
  self.ball.animation
}

///|
priv struct BySkillLevelBullet {
  bullets : Map[Int, Ball]
  skill_id : Int
}

///|
fn BySkillLevelBullet::new(src : Json, id : Int) -> BySkillLevelBullet raise {
  let bullets = Map::new()
  if src is { "level": Object(levels), .. } {
    for level, sub in levels {
      if sub is { "ball": ball, .. } {
        bullets.set(@strconv.parse_int(level), Ball::new(ball))
      }
    }
  }
  { bullets, skill_id: id }
}

///|
fn BySkillLevelBullet::get(
  self : BySkillLevelBullet,
  user : @character.Character,
  _ : Int,
) -> @graphics.Animation {
  let level = (user.get_skilllevel)(self.skill_id)
  match self.bullets.get(level) {
    Some(ball) => ball.animation
    None => @graphics.Animation::default()
  }
}
