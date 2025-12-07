///|
struct MobCombat {
  // player : Player
  // chars : MapChars
  mobs : MapMobs
  // regular_attack : @combat.RegularAttack
  // attack_results : @utils.TimedQueue[@combat.AttackResult]
  // damage_effects : @utils.TimedQueue[DamageEffect]
  // damage_numbers : Array[DamageNumber]
  io_service : @io_task.IOService
}

///|
pub fn MobCombat::new(
  mobs : MapMobs,
  io_service : @io_task.IOService,
) -> MobCombat {
  { mobs, io_service }
}

///|
pub fn MobCombat::use_move(
  self : MobCombat,
  oid : Int,
  move_id : Int,
  skill_id : Int,
  level : Int,
) -> Unit raise {
  let at = move_id - 24
  let action_id = if at % 2 == 0 { at / 2 } else { (at + 1) / 2 }
  match self.mobs.get_mobs().get(oid) {
    Some(mob) =>
      if 0 < action_id && action_id < 7 {
        let mov = mob.get_move_attack(action_id)
        apply_move_attack(mov, mob)
      } else if skill_id != 0 {
        let fut = mob.get_move_skill(skill_id, level, self.io_service)
        self.io_service.execute(fn() {
          let mov = self.io_service.wait(fut).unwrap_or_error()
          apply_move_skill(mov, mob)
        })
      }
    None => ()
  }
}

///|
pub fn apply_move_skill(mov : MobSkill, mob : Mob) -> Unit {
  mob.update_movement_ex(1, 1, 47, mov.get_id(), mov.get_level(), 0)
  if mov.is_buff() {
    mob.give_buff(mov.get_buff())
  }
  mob.use_skill(mov)
  mov.apply_useeffects(mob)
  // move.apply_hit_effects(mob);
}

///|
pub fn apply_move_attack(mov : MobSpecialAttack, mob : Mob) -> Unit {
  mob.update_movement_ex(1, 1, 2 * (mov.get_id() + 24), 0, 0, 0)
  mob.use_attack(mov)
  mov.apply_useeffects(mob)
  // move.apply_hit_effects(mob);
}
