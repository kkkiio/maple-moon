///|
pub(all) struct RegularAttack {
  action : RegularAction
} derive(Default)

///|
pub fn RegularAttack::apply_actions(
  self : RegularAttack,
  user : @character.Character,
  t : @combat.AttackType
) -> Unit {
  self.action.apply(user, t)
}

///|
pub fn make_regular_attack(
  character : @character.CharBase,
  bullet_id : Int,
  attacktype : @combat.AttackType,
  degenerate : Bool
) -> @combat.Attack {
  let t = attacktype
  let mut mindamage = character.stats.get_mindamage().to_double()
  let mut maxdamage = character.stats.get_maxdamage().to_double()
  if degenerate {
    mindamage /= 10
    maxdamage /= 10
  }
  let critical = character.stats.get_critical()
  let ignoredef = character.stats.get_ignoredef()
  let accuracy = character.stats.get_total(@stat.Id::ACC)
  let playerlevel = character.stats.get_stat(@maple_stat.Id::LEVEL)
  let origin = character.get_position()
  let toleft = character.facing_right |> not()
  let speed = (character.get_integer_attackspeed)()
  {
    damagetype: @combat.AttackDamageType::DMG_WEAPON(mindamage, maxdamage),
    t,
    critical,
    ignoredef,
    accuracy,
    playerlevel,
    range: match t {
      @combat.AttackType::CLOSE => character.get_afterimage().get_range()
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
pub fn RegularAttack::get_bullet(
  self : RegularAttack,
  _user : @character.Character,
  bulletid : Int
) -> @utils.Future[@graphics.Animation] {
  @bullet.BulletData::get_async(bulletid).map(fn(data) {
    data.unwrap() // TODO: Handle error
    .bullet
  })
}

///|
struct RegularAction {} derive(Default)

///|
pub fn RegularAction::apply(
  self : RegularAction,
  target : @character.Character,
  atype : @combat.AttackType
) -> Unit {
  let weapontype = target.get_weapontype()
  let degenerate = match weapontype {
    @weapon.BOW | @weapon.CROSSBOW | @weapon.CLAW | @weapon.GUN =>
      atype != @combat.AttackType::RANGED
    _ => false
  }
  target.regular_attack(degenerate)
}

///|
pub fn can_use_regular_attack(
  weapon : @weapon.Type,
  bullets : Int
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
  let ra = RegularAttack::default()
  {
    id: 0,
    attack: true,
    skill: false,
    apply_useeffects: fn(_) {  },
    apply_actions: fn(char, attack_type) { ra.apply_actions(char, attack_type) },
    make_attack: fn(char, i, attack_type, degenerate) {
      make_regular_attack(char, i.get_bulletid(), attack_type, degenerate)
    },
    get_bullet: fn(char, value) { ra.get_bullet(char, value) },
    can_use: fn(_, weapon_type, _, _, _, bullet) {
      can_use_regular_attack(weapon_type, bullet)
    },
    apply_hit_effects: fn(_, _) {  },
  }
}
