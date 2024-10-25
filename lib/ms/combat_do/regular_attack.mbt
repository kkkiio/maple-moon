pub struct RegularAttack {
  action : RegularAction
  bullet : RegularBullet
} derive(Default)

pub fn apply_useeffects(
  self : RegularAttack,
  _user : @character.Character
) -> Unit {

}

pub fn apply_actions(
  self : RegularAttack,
  user : @character.Character,
  t : @combat.AttackType
) -> Unit {
  self.action.apply(user, t)
}

pub fn apply_stats(
  self : RegularAttack,
  user : @character.Character,
  attack : @combat.Attack
) -> Unit {
  attack.damagetype = @combat.AttackDamageType::DMG_WEAPON(1.0, 1.0) // TODO: fix
  attack.skill = 0
  attack.mobcount = 1
  attack.hitcount = 1
  attack.stance = user.get_look().get_stance().int_value()
  if attack.t == @combat.AttackType::CLOSE {
    attack.range = user.get_afterimage().get_range()
  }
}

pub fn RegularAttack::is_attack(self : RegularAttack) -> Bool {
  true
}

pub fn RegularAttack::is_skill(self : RegularAttack) -> Bool {
  return false
}

pub fn RegularAttack::get_id(self : RegularAttack) -> Int {
  0
}

pub fn RegularAttack::get_bullet(
  self : RegularAttack,
  _user : @character.Character,
  bulletid : Int
) -> @graphics.Animation {
  self.bullet.get(bulletid)
}

struct RegularAction {} derive(Default)

pub fn apply(
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
  target.regular_attack?(degenerate).unwrap() // TODO: Handle error
}

pub fn can_use(
  self : RegularAttack,
  _level : Int,
  weapon : @weapon.Type,
  _job : @job.Job,
  _hp : Int,
  _mp : Int,
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

struct RegularBullet {} derive(Default)

pub fn get(self : RegularBullet, bulletid : Int) -> @graphics.Animation {
  @bullet.BulletData::get?(bulletid).unwrap().bullet // TODO: Handle error
}

pub fn apply_hit_effects(
  self : RegularAttack,
  _user : @combat.AttackUser,
  _target : @monster.Mob
) -> Unit {

}
