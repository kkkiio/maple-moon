///|
/// Resolve attack type and whether attack should be degenerate.
pub fn check_attack_type(
  character : @character.Character,
  inventory : &@legacy_types.Inventory,
  skill : Bool,
) -> (Bool, @combat_proto.AttackType) {
  if character.state == @character.CharState::PRONE {
    (true, @combat_proto.AttackType::CLOSE)
  } else {
    match character.get_weapontype() {
      @weapon.Type::BOW
      | @weapon.Type::CROSSBOW
      | @weapon.Type::CLAW
      | @weapon.Type::GUN => {
        let degenerate = not(inventory.has_projectile())
        (
          degenerate,
          if degenerate {
            @combat_proto.AttackType::CLOSE
          } else {
            @combat_proto.AttackType::RANGED
          },
        )
      }
      @weapon.Type::WAND | @weapon.Type::STAFF => {
        let degenerate = not(skill)
        (
          degenerate,
          if degenerate {
            @combat_proto.AttackType::CLOSE
          } else {
            @combat_proto.AttackType::MAGIC
          },
        )
      }
      _ => (false, @combat_proto.AttackType::CLOSE)
    }
  }
}

///|
/// Validate regular attack ammo requirement by weapon type.
pub fn can_use_regular_attack(
  weapon : @weapon.Type,
  bullets : Int,
) -> @combat_system.ForbidReason {
  match weapon {
    @weapon.BOW | @weapon.CROSSBOW | @weapon.CLAW | @weapon.GUN =>
      if bullets > 0 {
        @combat_system.ForbidReason::FBR_NONE
      } else {
        @combat_system.ForbidReason::FBR_BULLETCOST
      }
    _ => @combat_system.ForbidReason::FBR_NONE
  }
}
