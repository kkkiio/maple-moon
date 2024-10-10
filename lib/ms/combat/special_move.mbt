pub enum ForbidReason {
  FBR_NONE
  FBR_WEAPONTYPE
  FBR_HPCOST
  FBR_MPCOST
  FBR_BULLETCOST
  FBR_COOLDOWN
  FBR_OTHER
} derive(Eq)

pub trait SpecialMove {
  get_id(Self) -> Int
  is_attack(Self) -> Bool
  is_skill(Self) -> Bool
  apply_useeffects(Self, @character.Character) -> Unit
  apply_actions(Self, @character.Character, AttackType) -> Unit!
  apply_stats(Self, @character.Character, Attack) -> Unit
  get_bullet(Self, @character.Character, Int) -> @graphics.Animation
  can_use(Self, Int, @weapon.Type, @job.Job, Int, Int, Int) -> ForbidReason
}
