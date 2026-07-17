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
pub(all) struct CombatAction {
  id : Int
  attack : Bool
  skill : Bool
  apply_useeffects : (@character.Character) -> Unit
  apply_use_sfx : (@character.Character) -> Unit
  apply_actions : (@character.Character, @combat_proto.AttackType) -> Unit
  // TODO: find a better place for inventory arguments
  make_attack : (
    @character.Character,
    &@legacy_types.Inventory,
    @combat_proto.AttackType,
    Bool,
  ) -> @combat_proto.Attack
  get_bullet : (@character.Character, Int) -> @combat_proto.BulletAnimation
  can_use : (Int, @weapon.Type, @job.Job, Int, Int, Int) -> ForbidReason
  apply_hit_effects : (@combat_proto.AttackUser, @monster.Mob) -> Unit
  apply_hit_sfx : (@combat_proto.AttackUser, @monster.Mob) -> Unit
  get_afterimage : () -> Map[String, @char_look.NxAfterImage]
} derive(Debug)

///|
pub fn CombatAction::get_id(self : CombatAction) -> Int {
  self.id
}

///|
pub fn CombatAction::is_attack(self : CombatAction) -> Bool {
  self.attack
}

///|
pub fn CombatAction::is_skill(self : CombatAction) -> Bool {
  self.skill
}

///|
pub fn CombatAction::apply_useeffects(
  self : CombatAction,
  char : @character.Character,
) -> Unit {
  (self.apply_useeffects)(char)
}

///|
pub fn CombatAction::apply_actions(
  self : CombatAction,
  char : @character.Character,
  attack_type : @combat_proto.AttackType,
) -> Unit {
  (self.apply_actions)(char, attack_type)
}

///|
pub fn CombatAction::apply_use_sfx(
  self : CombatAction,
  char : @character.Character,
) -> Unit {
  (self.apply_use_sfx)(char)
}

///|
pub fn CombatAction::make_attack(
  self : CombatAction,
  char : @character.Character,
  inventory : &@legacy_types.Inventory,
  attack_type : @combat_proto.AttackType,
  degenerate : Bool,
) -> @combat_proto.Attack {
  (self.make_attack)(char, inventory, attack_type, degenerate)
}

///|
pub fn CombatAction::get_bullet(
  self : CombatAction,
  char : @character.Character,
  value : Int,
) -> @combat_proto.BulletAnimation {
  (self.get_bullet)(char, value)
}

///|
pub fn CombatAction::can_use(
  self : CombatAction,
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
pub fn CombatAction::apply_hit_effects(
  self : CombatAction,
  attack_user : @combat_proto.AttackUser,
  mob : @monster.Mob,
) -> Unit {
  (self.apply_hit_effects)(attack_user, mob)
}

///|
pub fn CombatAction::apply_hit_sfx(
  self : CombatAction,
  attack_user : @combat_proto.AttackUser,
  mob : @monster.Mob,
) -> Unit {
  (self.apply_hit_sfx)(attack_user, mob)
}

///|
pub fn CombatAction::get_afterimage(
  self : CombatAction,
) -> Map[String, @char_look.NxAfterImage] {
  (self.get_afterimage)()
}
