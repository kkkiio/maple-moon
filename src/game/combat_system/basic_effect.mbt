///|
fn read_basic_mx_animation_ref(src : Json) -> String {
  match src {
    { "mx_animation": String(path), .. } => path
    _ => abort("missing mx_animation in Effect/BasicEff.img/Teleport")
  }
}

///|
fn read_basic_effect_z(src : Json) -> Int {
  match src {
    { "z": Number(z, ..), .. } => z.to_int()
    { "z": String(raw), .. } =>
      @string.parse_int(raw) catch {
        _ => abort("invalid z in Effect/BasicEff.img/Teleport")
      }
    _ => 0
  }
}

///|
pub fn load_teleport_use_effect() -> (@character.Character) -> Unit {
  let teleport_node = @resource.require_json(
    "assets/Effect/BasicEff.img/Teleport.json",
  )
  let ref_path = read_basic_mx_animation_ref(teleport_node)
  let resolved = @resource.resolve_ref(
    "assets/Effect/BasicEff.img/Teleport.json", ref_path,
  )
  let animation_loader = AnimationLoader()
  let loaded = animation_loader.load(resolved)
  let clip = loaded.clip("main") catch {
    _ => abort("missing animation tag 'main': \{resolved}")
  }
  let effect : @graphics.EffectAnimation = {
    animation: @ms_animation.from_selene_clip(clip, loop_=false),
    duration_ms: clip.duration_ms,
  }
  let z = read_basic_effect_z(teleport_node)
  fn(character : @character.Character) -> Unit {
    character.show_attack_effect(effect, z)
  }
}

///|
using @resource {type AnimationLoader}

///|
using @utils {type BoolPair}
