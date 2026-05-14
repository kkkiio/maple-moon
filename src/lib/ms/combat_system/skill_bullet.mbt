///|
priv struct Ball {
  animation : @ms_animation.Animation
}

///|
async fn load_ball_animation(
  src : Json,
  tag : String,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> @ms_animation.Animation {
  let ref_path = match src {
    { "mx_animation": String(path), .. } => path
    _ => fail("missing mx_animation in skill ball")
  }
  let resolved = @resource.resolve_ref(base_path, ref_path)
  let animation_loader = @resource.AnimationLoader::new(skill_loader)
  let loaded = animation_loader.load(resolved)
  let clip = loaded.clip(tag)
  @ms_animation.from_selene_clip(clip, loop_=true)
}

///|
async fn Ball::new(
  src : Json,
  tag : String,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> Ball {
  let animation = load_ball_animation(src, tag, skill_loader, base_path)
  Ball::{ animation, }
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
) -> @ms_animation.Animation {
  let data = @bullet.get_bullet_data(bulletid)
  data.bullet
}

///|
priv struct SingleBullet {
  ball : Ball
}

///|
async fn SingleBullet::new(
  src : Json,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> SingleBullet {
  let ball = match src {
    { "ball": ball, .. } =>
      Ball::new(ball, skill_animation_tag(["ball"]), skill_loader, base_path)
    _ => fail("missing skill ball")
  }
  { ball, }
}

///|
fn SingleBullet::get(
  self : SingleBullet,
  _ : @character.Character,
  _ : Int,
) -> @ms_animation.Animation {
  self.ball.animation
}

///|
priv struct BySkillLevelBullet {
  bullets : Map[Int, Ball]
  skill_id : Int
}

///|
async fn BySkillLevelBullet::new(
  src : Json,
  id : Int,
  skill_loader : @resource.AsyncLoader,
  base_path : String,
) -> BySkillLevelBullet {
  let bullets = Map([])
  if src is { "level": Object(levels), .. } {
    for level, sub in levels {
      if sub is { "ball": ball, .. } {
        bullets.set(
          @string.parse_int(level),
          Ball::new(
            ball,
            skill_animation_tag(["level", level, "ball"]),
            skill_loader,
            base_path,
          ),
        )
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
) -> @ms_animation.Animation {
  let level = (user.get_skilllevel)(self.skill_id)
  match self.bullets.get(level) {
    Some(ball) => ball.animation
    None => @log.fatal("invalid missing skill bullet animation")
  }
}
