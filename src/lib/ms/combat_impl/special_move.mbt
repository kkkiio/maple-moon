///|
pub(all) enum ForbidReason {
  FBR_NONE
  FBR_WEAPONTYPE
  FBR_HPCOST
  FBR_MPCOST
  FBR_BULLETCOST
  FBR_COOLDOWN
  FBR_OTHER
} derive(Eq)

///|
pub(all) struct SpecialMove {
  id : Int
  attack : Bool
  skill : Bool
  apply_useeffects : (@character.Character) -> Unit
  apply_actions : (@character.Character, @combat.AttackType) -> Unit
  // TODO: find a better place for inventory arguments
  make_attack : (
    @character.Character,
    &@player.Inventory,
    @combat.AttackType,
    Bool,
  ) -> @combat.Attack
  get_bullet : (@character.Character, Int) -> @graphics.Animation
  can_use : (Int, @weapon.Type, @job.Job, Int, Int, Int) -> ForbidReason
  apply_hit_effects : (@combat.AttackUser, @monster.Mob) -> Unit
} derive(Show)

///|
pub fn SpecialMove::get_id(self : SpecialMove) -> Int {
  self.id
}

///|
pub fn SpecialMove::is_attack(self : SpecialMove) -> Bool {
  self.attack
}

///|
pub fn SpecialMove::is_skill(self : SpecialMove) -> Bool {
  self.skill
}

///|
pub fn SpecialMove::apply_useeffects(
  self : SpecialMove,
  char : @character.Character,
) -> Unit {
  (self.apply_useeffects)(char)
}

///|
pub fn SpecialMove::apply_actions(
  self : SpecialMove,
  char : @character.Character,
  attack_type : @combat.AttackType,
) -> Unit {
  (self.apply_actions)(char, attack_type)
}

///|
pub fn SpecialMove::make_attack(
  self : SpecialMove,
  char : @character.Character,
  inventory : &@player.Inventory,
  attack_type : @combat.AttackType,
  degenerate : Bool,
) -> @combat.Attack {
  (self.make_attack)(char, inventory, attack_type, degenerate)
}

///|
pub fn SpecialMove::get_bullet(
  self : SpecialMove,
  char : @character.Character,
  value : Int,
) -> @graphics.Animation {
  (self.get_bullet)(char, value)
}

///|
pub fn SpecialMove::can_use(
  self : SpecialMove,
  value : Int,
  weapon_type : @weapon.Type,
  job : @job.Job,
  hp : Int,
  mp : Int,
  bullet : Int,
) -> ForbidReason {
  (self.can_use)(value, weapon_type, job, hp, mp, bullet)
}

///|
pub fn SpecialMove::apply_hit_effects(
  self : SpecialMove,
  attack_user : @combat.AttackUser,
  mob : @monster.Mob,
) -> Unit {
  (self.apply_hit_effects)(attack_user, mob)
}
