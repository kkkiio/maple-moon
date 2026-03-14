///|
using @resource {nx_animation_to_selene_animation}

///|
#deprecated("use nx_animation_to_selene_animation instead")
pub fn nx_animation_to_selene_sprite(
  src : @resource.NxAnimation,
  z? : Int = 0,
  loop_? : Bool = true,
) -> @sprite.Sprite {
  nx_animation_to_selene_animation(src, loop_~)
  |> @sprite.Sprite::from_animation(z)
}
