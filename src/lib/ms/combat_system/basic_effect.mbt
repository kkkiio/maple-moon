/// Basic effects are common animations that are reused across different skills or game events.
/// For example, the "Teleport" animation is used by all Mage classes.
/// Instead of duplicating this data in every skill's JSON, we embed it here.

///|
using @graphics {add_effect}

///|
pub struct BasicEffect {
  teleport : @resource.NxAnimation
}

///|
pub fn BasicEffect::load() -> BasicEffect raise {
  let teleport_json : Json = {
    "0": {
      "__h": 172,
      "__w": 62,
      "delay": 80,
      "origin": [34, 122],
      "__i": "/assets/Effect/BasicEff.img/Teleport.png",
      "__off": [0, 0],
    },
    "1": {
      "__h": 172,
      "__w": 62,
      "delay": 80,
      "origin": [34, 122],
      "__i": "/assets/Effect/BasicEff.img/Teleport.png",
      "__off": [62, 0],
    },
    "2": {
      "__h": 172,
      "__w": 62,
      "delay": 80,
      "origin": [34, 122],
      "__i": "/assets/Effect/BasicEff.img/Teleport.png",
      "__off": [124, 0],
    },
    "3": {
      "__h": 172,
      "__w": 62,
      "delay": 80,
      "origin": [34, 122],
      "__i": "/assets/Effect/BasicEff.img/Teleport.png",
      "__off": [186, 0],
    },
  }
  let teleport : @resource.NxAnimation = @json.from_json(teleport_json)
  { teleport, }
}

///|
let basic_effect : Ref[BasicEffect?] = Ref::new(None)

///|
pub fn get_basic_effect() -> BasicEffect {
  match basic_effect.val {
    Some(be) => be
    None => {
      let be = BasicEffect::load() catch { _ => panic() }
      basic_effect.val = Some(be)
      be
    }
  }
}

///|
pub fn show_teleport_effect(character : @character.Character) -> Unit {
  let be = get_basic_effect()
  add_effect(character.entity, be.teleport, z=@graphics.EFFECT_ZINDEX)
}
