///|
/// Load a skill and convert it into `SpecialMove` for cast/attack pipeline.
pub async fn load_skill_move(move_id : Int) -> @combat_system.SpecialMove {
  let it = @combat_system.Skill::load(move_id)
  {
    id: it.get_id(),
    attack: it.is_attack(),
    skill: true,
    apply_useeffects: fn(c) { it.apply_useeffects(c) },
    apply_use_sfx: fn(c) { it.apply_use_sfx(c) },
    apply_actions: fn(attack_type, c) { it.apply_actions(attack_type, c) },
    make_attack: fn(c, i, t, _) { it.make_attack(c, i.get_bulletid(), t) },
    get_bullet: fn(c, bulletid) { it.get_bullet(c, bulletid) },
    can_use: fn(level, weapontype, job, hp, mp, bullet) {
      it.can_use(level, weapontype, job, hp, mp, bullet)
    },
    apply_hit_effects: fn(attack_user, mob) {
      it.apply_hit_effects(attack_user, mob)
    },
    apply_hit_sfx: fn(attack_user, mob) { it.apply_hit_sfx(attack_user, mob) },
    get_afterimage: fn() { it.get_afterimage() },
  }
}
