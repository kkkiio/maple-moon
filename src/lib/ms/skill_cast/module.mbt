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
    (@combat_system.new_regular_attack(), Some(weapon))
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
