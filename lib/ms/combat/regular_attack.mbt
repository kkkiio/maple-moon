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
  t : AttackType
) -> Unit! {
  self.action.apply!(user, t)
}

pub fn apply_stats(
  self : RegularAttack,
  user : @character.Character,
  attack : Attack
) -> Unit {
  attack.damagetype = AttackDamageType::DMG_WEAPON
  attack.skill = 0
  attack.mobcount = 1
  attack.hitcount = 1
  attack.stance = user.get_look().get_stance().int_value()
  if attack.t == AttackType::CLOSE {
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

pub fn RegularAction::apply(
  self : RegularAction,
  target : @character.Character,
  atype : AttackType
) -> Unit! {
  let weapontype = target.get_weapontype()
  let degenerate = match weapontype {
    @weapon.BOW | @weapon.CROSSBOW | @weapon.CLAW | @weapon.GUN =>
      atype != AttackType::RANGED
    _ => false
  }
  target.regular_attack!(degenerate)
}

pub fn RegularAttack::can_use(
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
