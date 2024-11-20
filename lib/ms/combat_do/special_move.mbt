pub(all) enum ForbidReason {
  FBR_NONE
  FBR_WEAPONTYPE
  FBR_HPCOST
  FBR_MPCOST
  FBR_BULLETCOST
  FBR_COOLDOWN
  FBR_OTHER
} derive(Eq)

pub(open) trait SpecialMove {
  get_id(Self) -> Int
  is_attack(Self) -> Bool
  is_skill(Self) -> Bool
  apply_useeffects(Self, @character.Character) -> Unit
  apply_actions(Self, @character.Character, @combat.AttackType) -> Unit
  apply_stats(Self, @character.Character, @combat.Attack) -> Unit
  get_bullet(Self, @character.Character, Int) ->
       @utils.Future[@graphics.Animation]
  can_use(Self, Int, @weapon.Type, @job.Job, Int, Int, Int) -> ForbidReason
  apply_hit_effects(Self, @combat.AttackUser, @monster.Mob) -> Unit
}
