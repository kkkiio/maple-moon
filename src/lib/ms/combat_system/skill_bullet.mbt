///|
priv struct Ball {
  animation : @ms_animation.Animation
}

///|
fn load_ball_animation(
  src : Json,
  tag : String,
  base_path : String,
) -> @ms_animation.Animation {
  let ref_path = match src {
    { "mx_animation": String(path), .. } => path
    _ => abort("missing mx_animation in skill ball")
  }
  let resolved = @resource.resolve_ref(base_path, ref_path)
  let animation_loader = @resource.AnimationLoader::new()
  let loaded = animation_loader.load(resolved)
  let clip = loaded.clip(tag) catch {
    _ => abort("missing skill ball animation tag '\{tag}': \{resolved}")
  }
  @ms_animation.from_selene_clip(clip, loop_=true)
}

///|
fn Ball::new(src : Json, tag : String, base_path : String) -> Ball {
  let animation = load_ball_animation(src, tag, base_path)
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
fn SingleBullet::new(src : Json, base_path : String) -> SingleBullet {
  let ball = match src {
    { "ball": ball, .. } =>
      Ball::new(ball, skill_animation_tag(["ball"]), base_path)
    _ => abort("missing skill ball")
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
fn BySkillLevelBullet::new(
  src : Json,
  id : Int,
  base_path : String,
) -> BySkillLevelBullet {
  let bullets = Map([])
  if src is { "level": Object(levels), .. } {
    for level, sub in levels {
      if sub is { "ball": ball, .. } {
        let parsed_level = @string.parse_int(level) catch {
          _ => abort("invalid skill ball level: \{level}")
        }
        bullets.set(
          parsed_level,
          Ball::new(
            ball,
            skill_animation_tag(["level", level, "ball"]),
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
