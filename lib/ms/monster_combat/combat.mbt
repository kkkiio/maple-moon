struct MobCombat {
  // player : Player
  // chars : MapChars
  mobs : @monster.MapMobs
  skills : Map[Int, @combat.Skill]
  // regular_attack : @combat.RegularAttack
  // attack_results : @utils.TimedQueue[@combat.AttackResult]
  // damage_effects : @utils.TimedQueue[DamageEffect]
  // damage_numbers : Array[DamageNumber]
}

pub fn MobCombat::new(mobs : @monster.MapMobs) -> MobCombat {
  { mobs, skills: Map::new() }
}

pub fn use_move(
  self : MobCombat,
  oid : Int,
  move_id : Int,
  skill_id : Int,
  level : Int
) -> Unit! {
  let at = move_id - 24
  let action_id = if at % 2 == 0 { at / 2 } else { (at + 1) / 2 }
  match self.mobs.get_mobs().get(oid) {
    Some(mob) =>
      if 0 < action_id && action_id < 7 {
        let move = mob.get_move_attack!(action_id)
        self.apply_move_attack(move, mob)
      } else if skill_id != 0 {
        let move = mob.get_move_skill!(skill_id, level)
        self.apply_move_skill(move, mob)
      }
    None => ()
  }
}

pub fn apply_move_skill(
  self : MobCombat,
  move : @monster.MobSkill,
  mob : @monster.Mob
) -> Unit {
  mob.update_movement_ex(1, 1, 47, move.get_id(), move.get_level(), 0)
  if move.is_buff() {
    mob.give_buff(move.get_buff())
  }
  mob.use_skill(move)
  move.apply_useeffects(mob)
  // move.apply_hiteffects(mob);
}

pub fn apply_move_attack(
  self : MobCombat,
  move : @monster.MobSpecialAttack,
  mob : @monster.Mob
) -> Unit {
  mob.update_movement_ex(1, 1, 2 * (move.get_id() + 24), 0, 0, 0)
  mob.use_attack(move)
  move.apply_useeffects(mob)
  // move.apply_hiteffects(mob);
}
