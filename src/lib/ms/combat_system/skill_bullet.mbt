///|
priv struct Ball {
  animation : @resource.NxAnimation
}

///|
fn Ball::new(src : Json) -> Ball raise {
  let animation : @resource.NxAnimation = @json.from_json(src)
  { animation, }
}

///|
priv struct SkillRegularBullet {}

///|
fn SkillRegularBullet::new() -> SkillRegularBullet {
  SkillRegularBullet::{  }
}

///|
fn SkillRegularBullet::get(
  _self : SkillRegularBullet,
  _ : @character.Character,
  bulletid : Int,
) -> @resource.NxAnimation {
  let data = @bullet.get_bullet_data(bulletid)
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
) -> @resource.NxAnimation {
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
        bullets.set(@string.parse_int(level), Ball::new(ball))
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
) -> @resource.NxAnimation {
  let level = (user.get_skilllevel)(self.skill_id)
  match self.bullets.get(level) {
    Some(ball) => ball.animation
    None => {
      let empty_ball = Ball::new(Json::null()) catch {
        _ => @log.fatal("invalid empty skill bullet animation")
      }
      empty_ball.animation
    }
  }
}
