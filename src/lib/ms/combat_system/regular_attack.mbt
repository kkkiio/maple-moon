///|
pub(all) struct RegularAttack {
  action : RegularAction
}

///|
pub fn RegularAttack::apply_actions(
  self : RegularAttack,
  user : @character.Character,
  t : @combat_proto.AttackType,
) -> Unit {
  self.action.apply(user, t)
}

///|
pub fn make_regular_attack(
  character : @character.Character,
  bullet_id : Int,
  attacktype : @combat_proto.AttackType,
  degenerate : Bool,
) -> @combat_proto.Attack {
  let t = attacktype
  let mut mindamage = character.stats.get_mindamage().to_double()
  let mut maxdamage = character.stats.get_maxdamage().to_double()
  if degenerate {
    mindamage /= 10
    maxdamage /= 10
  }
  let critical = character.stats.get_critical()
  let ignoredef = character.stats.get_ignoredef()
  let accuracy = character.stats.get_total(@maple_stat.EquipStatId::ACC)
  let playerlevel = character.stats.get_stat(@maple_stat.Id::LEVEL)
  let origin = character.get_position()
  let toleft = character.facing_right |> not()
  let speed = @character.get_integer_attackspeed(
    character.get_look(),
    character.stats,
  )
  {
    damagetype: @combat_proto.AttackDamageType::DMG_WEAPON(
      min=mindamage,
      max=maxdamage,
    ),
    t,
    critical,
    ignoredef,
    accuracy,
    playerlevel,
    range: match t {
      @combat_proto.AttackType::CLOSE => {
        guard @char_look.get_after_image(character.entity) is Some(after_image) else {
          @log.fatal("No afterimage when making regular attack")
        }
        let after_image_range = after_image.get_range()
        if after_image_range.is_empty() {
          @log.fatal("afterimage range is empty for close regular attack")
        }
        after_image_range
      }
      _ => character.stats.get_range()
    },
    bullet: bullet_id,
    origin,
    toleft,
    speed,
    skill: 0,
    mobcount: 1,
    hitcount: 1,
    stance: character.get_look().get_stance().int_value(),
    hrange: 1.0,
  }
}

///|
pub fn get_regular_attack_bullet(bulletid : Int) -> @resource.NxAnimation {
  let data = @bullet.get_bullet_data(bulletid)
  data.bullet
}

///|
struct RegularAction {} derive(Default)

///|
pub impl SkillAction for RegularAction with apply(
  self : RegularAction,
  target : @character.Character,
  atype : @combat_proto.AttackType,
) -> Unit {
  let weapontype = target.get_weapontype()
  let degenerate = match weapontype {
    @weapon.BOW | @weapon.CROSSBOW | @weapon.CLAW | @weapon.GUN =>
      atype != @combat_proto.AttackType::RANGED
    _ => false
  }
  target.regular_attack(degenerate)
}

///|
pub fn can_use_regular_attack(
  weapon : @weapon.Type,
  bullets : Int,
) -> ForbidReason {
  match weapon {
    @weapon.BOW | @weapon.CROSSBOW | @weapon.CLAW | @weapon.GUN =>
      if bullets > 0 {
        FBR_NONE
      } else {
        FBR_BULLETCOST
      }
    _ => FBR_NONE
  }
}

///|
pub fn new_regular_attack() -> SpecialMove {
  let ra = RegularAttack::{ action: RegularAction::default() }
  {
    id: 0,
    attack: true,
    skill: false,
    apply_useeffects: fn(_) {  },
    apply_actions: fn(char, attack_type) { ra.apply_actions(char, attack_type) },
    make_attack: fn(char, i, attack_type, degenerate) {
      make_regular_attack(char, i.get_bulletid(), attack_type, degenerate)
    },
    get_bullet: fn(_char, value) { get_regular_attack_bullet(value) },
    can_use: fn(_, weapon_type, _, _, _, bullet) {
      can_use_regular_attack(weapon_type, bullet)
    },
    apply_hit_effects: fn(_, _) {  },
    get_afterimage: fn() { Map::new() },
  }
}
