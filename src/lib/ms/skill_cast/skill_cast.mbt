///|
using @combat_system {
  type SpecialMove,
  type RegularAttack,
  type RegularAction,
  make_regular_attack,
  get_regular_attack_bullet,
}

///|
/// Global registry of available moves.
pub let move_map : Map[Int, @combat_system.SpecialMove] = Map::new()

///|
/// Register a move into the global cast registry.
pub fn register_move(sp_move : @combat_system.SpecialMove) -> Unit {
  move_map.set(sp_move.get_id(), sp_move)
}

///|
/// Get a registered skill move by id.
pub fn get_skill_move(move_id : Int) -> @combat_system.SpecialMove? {
  move_map.get(move_id)
}

///|
/// Entry point for skill casting.
pub fn use_move(cc : &@combat_system.CombatCharacter, move_id : Int) -> Unit {
  guard @combat_system.get_combat() is Some(combat) else { return }
  let character = cc.get_character()
  let (act, attack_weapon) = if move_id == @combat_proto.REGULAR_ATTACK {
    guard character.get_look().get_equips().get_weapon() is Some(weapon) else {
      return
    }
    (new_regular_attack(weapon.get_type()), Some(weapon))
  } else if move_map.get(move_id) is Some(act) {
    if act.is_attack() {
      guard character.get_look().get_equips().get_weapon() is Some(weapon) else {
        return
      }
      (act, Some(weapon))
    } else {
      (act, None)
    }
  } else {
    @log.warn("skill not registered", data={ "move_id": move_id })
    return
  }

  guard not(act.is_attack() && not(cc.can_attack())) else { return }

  let reason = combat.can_use(cc, act)
  guard reason == @combat_system.ForbidReason::FBR_NONE else {
    // TODO: show forbid reason in UI
    return
  }

  let after_images = match attack_weapon {
    Some(weapon) => {
      let name = weapon.get_afterimage()
      let level = weapon.get_equipdata().get_reqstat(@maple_stat.Id::LEVEL)
      let after_images = @char_look.AfterImage::get_collection(name, level)
      if act.is_skill() {
        let skill_resources = act.get_afterimage()
        for k, v in skill_resources {
          // Override weapon afterimages with skill-specific ones.
          after_images.set(k, v)
        }
      }
      after_images
    }
    None => Map::new()
  }
  combat.apply_move(cc, act, after_images)
}

///|
pub fn new_regular_attack(weapon_type : @weapon.Type) -> SpecialMove {
  let ra = RegularAttack::{ action: RegularAction::default() }
  {
    id: 0,
    attack: true,
    skill: false,
    apply_useeffects: fn(_) {  },
    apply_use_sfx: fn(_) {  },
    apply_actions: fn(char, attack_type) { ra.apply_actions(char, attack_type) },
    make_attack: fn(char, i, attack_type, degenerate) {
      make_regular_attack(
        char,
        i.get_bulletid(),
        attack_type,
        degenerate,
        max_target_count=match weapon_type {
          @weapon.SWORD_1H
          | @weapon.SWORD_2H
          | @weapon.AXE_1H
          | @weapon.AXE_2H
          | @weapon.MACE_1H
          | @weapon.MACE_2H
          | @weapon.POLEARM
          | @weapon.SPEAR => 3
          _ => 1
        },
      )
    },
    get_bullet: fn(_char, value) { get_regular_attack_bullet(value) },
    can_use: fn(_, weapon_type, _, _, _, bullet) {
      can_use_regular_attack(weapon_type, bullet)
    },
    apply_hit_effects: fn(_, _) {  },
    apply_hit_sfx: fn(_, _) {  },
    get_afterimage: fn() { Map::new() },
  }
}
