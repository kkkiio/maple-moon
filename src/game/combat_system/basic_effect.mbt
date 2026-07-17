///|
fn read_basic_mx_animation_ref(src : Json) -> String raise {
  match src {
    { "mx_animation": String(path), .. } => path
    _ => fail("missing mx_animation in Effect/BasicEff.img/Teleport")
  }
}

///|
fn read_basic_effect_z(src : Json) -> Int raise {
  match src {
    { "z": Number(z, ..), .. } => z.to_int()
    { "z": String(raw), .. } =>
      @string.parse_int(raw) catch {
        _ => fail("invalid z in Effect/BasicEff.img/Teleport")
      }
    _ => 0
  }
}

///|
/// Load the shared teleport cast effect.
///
/// # Example
/// ```moonbit nocheck
/// let effect = try! load_teleport_use_effect()
/// ignore(effect)
/// ```
///
/// # Errors
/// Raises when the effect document, its animation reference, or its `main` tag
/// is invalid or missing.
pub fn load_teleport_use_effect() -> ((@character.Character) -> Unit) raise {
  let teleport_node = @res.load_json("res://Effect/BasicEff.img/Teleport.json")
  let ref_path = read_basic_mx_animation_ref(teleport_node)
  let resolved = @res.resolve_ref(
    "res://Effect/BasicEff.img/Teleport.json", ref_path,
  )
  let animation_loader = AnimationLoader()
  let loaded = animation_loader.load(resolved)
  let clip = loaded.clip("main") catch {
    error => fail("missing animation tag 'main': \{resolved}, error=\{error}")
  }
  let effect = @graphics.EffectAnimation(clip)
  let z = read_basic_effect_z(teleport_node)
  fn(character : @character.Character) -> Unit {
    character.show_attack_effect(effect, z)
  }
}

///|
using @res {type AnimationLoader}

///|
using @utils {type BoolPair}
