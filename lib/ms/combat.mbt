///|
struct Combat {
  damage_number_set : @ui.NumberSet
  mobs : @monster.MapMobs
  skill_cache : Map[Int, @utils.Future[Result[@combat_do.SpecialMove, Error]]]
  regular_attack : @combat_do.RegularAttack
  // TODO: Add reactors
  bullet_effects : @utils.TimedQueue[BulletEffect]
  damage_effects : @utils.TimedQueue[DamageEffect]
  bullets : Array[BulletEffect]
  damage_numbers : Array[@ui.Number]
  cooldowns : Map[Int, Int]
  add_task_fn : (@utils.Future[Unit]) -> Unit
}

///|
pub fn Combat::new(
  damage_number_set : @ui.NumberSet,
  mobs : @monster.MapMobs,
  add_task_fn : (@utils.Future[Unit]) -> Unit
) -> Combat {
  {
    damage_number_set,
    mobs,
    skill_cache: Map::new(),
    regular_attack: @combat_do.RegularAttack::default(),
    bullet_effects: @utils.TimedQueue::new(),
    damage_effects: @utils.TimedQueue::new(),
    bullets: Array::new(),
    damage_numbers: Array::new(),
    cooldowns: Map::new(),
    add_task_fn,
  }
}

///|
pub fn draw(
  self : Combat,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  for bullet_eff in self.bullets {
    bullet_eff.bullet.draw(viewx, viewy, alpha)
  }
  for dmg_eff in self.damage_numbers {
    dmg_eff.draw(viewx, viewy, alpha)
  }
}

///|
pub fn update(self : Combat) -> Unit {
  for bullet_effect in self.bullet_effects.process() {
    self.apply_bullet_effect(bullet_effect)
  }
  for dmg_eff in self.damage_effects.process() {
    self.apply_damage_effect(dmg_eff)
  }
  self.bullets.retain(fn(mb) {
    let target_oid = mb.damageeffect.target_oid
    if self.mobs.contains(target_oid) {
      mb.target = self.mobs.get_mob_head_position(target_oid)
      let apply = mb.bullet.update(mb.target)
      if apply {
        self.apply_damage_effect(mb.damageeffect)
      }
      return apply.not()
    }
    mb.bullet.update(mb.target).not()
  })
  self.damage_numbers.retain(fn(dn) { dn.update().not() })
}

///|
pub fn use_move(self : Combat, player : @player.Player, move_id : Int) -> Unit {
  if player.can_attack().not() {
    return
  }
  let act_f = self.get_move(move_id)
  let task = act_f.map_exn(fn(act) {
      let act = act.unwrap_or_error!()
      let reason = self.can_use(player, act)
      if reason == @combat_do.ForbidReason::FBR_NONE {
        self.apply_move(player, act)
      } else {
        // TODO: show forbid reason
        // let weapontype = self.player.get_stats().get_weapontype()
        // ForbidSkillMessage::new(reason, weapontype).drop()
      }
    })
    |> log_background_err
  (self.add_task_fn)(task)
}

///|
fn apply_move(
  self : Combat,
  player : @player.Player,
  act : @combat_do.SpecialMove
) -> Unit {
  if act.is_attack() {
    let attack = prepare_attack(player, act.is_skill())
    act.apply_useeffects(player)
    act.apply_actions(player, attack.t)
    player.set_afterimage(act.get_id())
    act.apply_stats(player, attack)
    let origin = attack.origin
    let hrange = (attack.range.left().to_double() * attack.hrange).to_int()
    let rel_range = @struct.Rectangle::from4(
      hrange,
      attack.range.right(),
      attack.range.top(),
      attack.range.bottom(),
    )
    let range = (if attack.toleft { rel_range } else { rel_range.flip_x() }).shift(
      origin,
    )
    // This approach should also make it easier to implement PvP
    let mobcount = attack.mobcount
    let result = {
      ..@combat.AttackResult::new(attack),
      attacker: player.get_oid(),
    }
    let mob_objs = self.mobs.get_mobs()
    // let reactor_objs = self.reactors.get_reactors()
    let mob_targets = find_closest_mob(mob_objs, range, origin, mobcount)
    // let reactor_targets = self.find_closest_reactor(
    //   reactor_objs, range, origin, mobcount, false,
    // )
    self.mobs.send_attack(result, attack, mob_targets, mobcount)
    self.extract_effects(player, act, result)
    self.apply_result_movement(player, act, result)
    new_attack_packet(result).dispatch()
    // if reactor_targets.is_empty().not() {
    //   match reactor_objs.get(reactor_targets[0]) {
    //     Some(reactor) =>
    //       new_damage_reactor_packet(
    //         reactor.get_oid(),
    //         player.get_position(),
    //         0,
    //         0,
    //       ).dispatch()
    //     None => ()
    //   }
    // }
  } else {
    act.apply_useeffects(player)
    act.apply_actions(player, @combat.AttackType::MAGIC)
    let moveid = act.get_id()
    let level = player.get_skills().get_level(moveid)
    new_use_skill_packet(moveid, level).dispatch()
  }
}

///|
fn apply_result_movement(
  self : Combat,
  player : @player.Player,
  act : @combat_do.SpecialMove,
  result : @combat.AttackResult
) -> Unit {
  if act.get_id() == @skill.SkillId::RUSH_HERO.int_value() ||
    act.get_id() == @skill.SkillId::RUSH_PALADIN.int_value() ||
    act.get_id() == @skill.SkillId::RUSH_DK.int_value() {
    self.apply_rush(player, result)
  }
}

///|
fn apply_rush(
  self : Combat,
  player : @player.Player,
  result : @combat.AttackResult
) -> Unit {
  if result.mobcount == 0 {
    return
  }
  let mob_position = self.mobs.get_mob_position(result.last_oid)
  let targetx = mob_position.x
  player.rush(targetx.to_double())
}

///|
fn find_closest_mob(
  objs : @map_object.MapObjects[@monster.Mob],
  range : @struct.Rectangle[Int],
  origin : @struct.Point[Int],
  objcount : Int
) -> Array[Int] {
  if objcount <= 0 {
    panic()
  }
  let arr = Array::new()
  for _, mob in objs {
    if mob.is_alive() && mob.is_in_range(range) {
      let oid = mob.get_oid()
      let distance = mob.get_position().distance(origin)
      arr.push((distance, oid))
    }
  }
  arr.sort_by_key(fn(pair) { pair.0 })
  arr.iter().take(objcount).map(fn(pair) { pair.1 }).collect()
}

///|
struct DamageEffect {
  user : @combat.AttackUser
  number : @ui.Number
  damage : Int
  toleft : Bool
  target_oid : Int
  move_id : Int
}

///|
struct BulletEffect {
  damageeffect : DamageEffect
  bullet : @combat.Bullet
  mut target : @struct.Point[Int]
}

///|
fn new_use_skill_packet(moveid : Int, level : Int) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.OutPacketOpcode::USE_SKILL)
  packet.write_time()
  packet.write_int(moveid)
  packet.write_byte(level.to_byte())

  // If monster magnet : some more bytes

  if moveid % 10000000 == 1004 {
    packet.skip(2) // TODO: No idea what this could be
  }
  // TODO: A point (4 bytes) could be added at the end
  packet
}

// fn new_damage_reactor_packet(
//   oid : Int,
//   position : @struct.Point[Int],
//   stance : Int,
//   skillid : Int
// ) -> @net.OutPacket {
//   let packet = @net.OutPacket::new(@net.OutPacketOpcode::DAMAGE_REACTOR)
//   packet.write_int(oid)
//   packet.write_point(position)
//   packet.write_short(stance)
//   packet.skip(4)
//   packet.write_int(skillid)
//   packet
// }

///| Notifies the server of an attack. 
/// 
/// The opcode is determined by the attack type. 
/// Attack::CLOSE = CLOSE_ATTACK(44) 
/// Attack::RANGED = RANGED_ATTACK(45)
/// Attack::MAGIC = MAGIC_ATTACK(46)
fn new_attack_packet(attack : @combat.AttackResult) -> @net.OutPacket {
  let packet = @net.OutPacket::new(opcodefor(attack.t))
  packet.skip(1)
  packet.write_byte(((attack.mobcount << 4) | attack.hitcount).to_byte())
  packet.write_int(attack.skill)
  if attack.charge > 0 {
    packet.write_int(attack.charge)
  }
  packet.skip(8)
  packet.write_byte(attack.display.to_byte())
  packet.write_byte(attack.toleft.to_int().to_byte())
  packet.write_byte(attack.stance.to_byte())
  packet.skip(1)
  packet.write_byte(attack.speed.to_byte())
  if attack.t == @combat.AttackType::RANGED {
    packet.skip(1)
    packet.write_byte(attack.toleft.to_int().to_byte())
    packet.skip(7)
    // TODO: skip(4); If hurricane, piercing arrow or rapidfire
  } else {
    packet.skip(4)
  }
  for damage_to_mob, arr in attack.damage_lines {
    packet.write_int(damage_to_mob)
    packet.skip(14)
    for single_damage in arr {
      packet.write_int(single_damage.0)
      // TODO: Add critical here
    }
    if attack.skill != 5221004 {
      packet.skip(4)
    }
  }
  packet
}

///|
fn opcodefor(t : @combat.AttackType) -> @net.OutPacketOpcode {
  match t {
    @combat.AttackType::CLOSE => @net.OutPacketOpcode::CLOSE_ATTACK
    @combat.AttackType::RANGED => @net.OutPacketOpcode::RANGED_ATTACK
    _ => @net.OutPacketOpcode::MAGIC_ATTACK
  }
}

///|
pub fn get_move(
  self : Combat,
  move_id : Int
) -> @utils.Future[Result[@combat_do.SpecialMove, Error]] {
  if move_id == 0 {
    return self.regular_attack |> Ok |> @utils.Future::from_value
  }
  self.skill_cache.get_or_init(move_id, fn() {
    @combat_do.Skill::load(move_id).map(fn(f) { f.map(fn(it) { it }) })
  })
}

///|
fn extract_effects(
  self : Combat,
  user : @character.Character,
  act : @combat_do.SpecialMove,
  result : @combat.AttackResult
) -> Unit {
  let attack_user : @combat.AttackUser = {
    skill_level: user.get_skilllevel(act.get_id()),
    level: user.get_stats().get_stat(@maple_stat.Id::LEVEL),
    second_weapon: user.is_twohanded(),
    flip: result.toleft.not(),
  }
  if result.bullet != 0 {
    let bullet = @combat.Bullet::new(
      act.get_bullet(user, result.bullet),
      user.get_position(),
      result.toleft,
    )
    for oid, vec in result.damage_lines {
      if self.mobs.contains(oid) {
        let numbers = self.place_numbers(oid, vec)
        let head = self.mobs.get_mob_head_position(oid)
        let mut i = 0
        for number in numbers {
          let effect : DamageEffect = {
            user: attack_user,
            number,
            damage: vec[i].0,
            toleft: result.toleft,
            target_oid: oid,
            move_id: act.get_id(),
          }
          self.bullet_effects.push(user.get_attackdelay(i).to_int64(), {
            damageeffect: effect,
            bullet,
            target: head,
          })
          i += 1
        }
      }
    }
    if result.damage_lines.is_empty() { // TODO: what does this mean?
      let xshift = if result.toleft { -400 } else { 400 }
      let target = user.get_position() + Point::new(xshift, -26)
      for i in 0..<result.hitcount {
        let effect : DamageEffect = {
          user: attack_user,
          number: self.damage_number_set.new_number(
            @ui.NumberType::HIT_NORMAL,
            0,
            user.get_position().y,
          ),
          damage: 0,
          toleft: false,
          target_oid: 0,
          move_id: 0,
        }
        self.bullet_effects.push(user.get_attackdelay(i).to_int64(), {
          damageeffect: effect,
          bullet,
          target,
        })
      }
    }
  } else {
    for oid, vec in result.damage_lines {
      if self.mobs.contains(oid) {
        let numbers = self.place_numbers(oid, vec)
        let mut i = 0
        for number in numbers {
          self.damage_effects.push(user.get_attackdelay(i).to_int64(), {
            user: attack_user,
            number,
            damage: vec[i].0,
            toleft: result.toleft,
            target_oid: oid,
            move_id: act.get_id(),
          })
          i += 1
        }
      }
    }
  }
}

///|
fn place_numbers(
  self : Combat,
  oid : Int,
  damage_lines : Array[(Int, Bool)]
) -> Array[@ui.Number] {
  let numbers = Array::new()
  let mut head = self.mobs.get_mob_head_position(oid).y
  for it in damage_lines {
    let (amount, is_critical) = it
    let t = if is_critical {
      @ui.NumberType::HIT_CRITICAL
    } else {
      @ui.NumberType::HIT_NORMAL
    }
    numbers.push(self.damage_number_set.new_number(t, amount, head))
    head -= @ui.Number::row_height(is_critical)
  }
  return numbers
}

///|
fn apply_damage_effect(self : Combat, effect : DamageEffect) -> Unit {
  let head_position = self.mobs.get_mob_head_position(effect.target_oid)
  let number = effect.number
  self.damage_numbers.push(number)
  number.set_x(head_position.x)
  let act_f = self.get_move(effect.move_id)
  guard let Some(mob) = self.mobs.get_mobs().get(effect.target_oid) else {
    None => return
  }
  mob.apply_damage(effect.damage, effect.toleft)
  (self.add_task_fn)(
    act_f.map(fn(res) {
      match res {
        Ok(act) => act.apply_hit_effects(effect.user, mob)
        Err(e) => @log.error({ "error": e }, "apply_damage_effect failed")
      }
    }),
  )
}

///|
fn apply_bullet_effect(self : Combat, effect : BulletEffect) -> Unit {
  if effect.bullet.set_target(effect.target) {
    self.apply_damage_effect(effect.damageeffect)
  } else {
    self.bullets.push(effect)
  }
}

///|
pub fn prepare_attack(player : @player.Player, skill : Bool) -> @combat.Attack {
  let (degenerate, attacktype) = if player.char_base.state ==
    @character.CharState::PRONE {
    (true, @combat.AttackType::CLOSE)
  } else {
    match player.get_weapontype() {
      @weapon.Type::BOW
      | @weapon.Type::CROSSBOW
      | @weapon.Type::CLAW
      | @weapon.Type::GUN => {
        let degenerate = player.inventory.has_projectile().not()
        (
          degenerate,
          if degenerate {
            @combat.AttackType::CLOSE
          } else {
            @combat.AttackType::RANGED
          },
        )
      }
      @weapon.Type::WAND | @weapon.Type::STAFF => {
        let degenerate = skill.not()
        (
          degenerate,
          if degenerate {
            @combat.AttackType::CLOSE
          } else {
            @combat.AttackType::MAGIC
          },
        )
      }
      _ => (false, @combat.AttackType::CLOSE)
    }
  }
  let t = attacktype
  let mut mindamage = player.stats.get_mindamage().to_double()
  let mut maxdamage = player.stats.get_maxdamage().to_double()
  if degenerate {
    mindamage /= 10
    maxdamage /= 10
  }
  let critical = player.stats.get_critical()
  let ignoredef = player.stats.get_ignoredef()
  let accuracy = player.stats.get_total(@stat.Id::ACC)
  let playerlevel = player.stats.get_stat(@maple_stat.Id::LEVEL)
  let range = player.stats.get_range()
  let bullet = player.inventory.get_bulletid()
  let origin = player.get_position()
  let toleft = player.char_base.facing_right.not()
  let speed = player.get_integer_attackspeed()
  let d = @combat.Attack::default()
  {
    ..d,
    damagetype: @combat.AttackDamageType::DMG_WEAPON(mindamage, maxdamage),
    t,
    critical,
    ignoredef,
    accuracy,
    playerlevel,
    range,
    bullet,
    origin,
    toleft,
    speed,
  }
}

///|
pub fn can_use(
  self : Combat,
  player : @player.Player,
  act : @combat_do.SpecialMove
) -> @combat_do.ForbidReason {
  if act.is_skill() && player.char_base.state == @character.CharState::PRONE {
    return @combat_do.ForbidReason::FBR_OTHER
  }
  if act.is_attack() &&
    (
      player.char_base.state == @character.CharState::LADDER ||
      player.char_base.state == @character.CharState::ROPE
    ) {
    return @combat_do.ForbidReason::FBR_OTHER
  }
  if self.has_cooldown(act.get_id()) {
    return @combat_do.ForbidReason::FBR_COOLDOWN
  }
  let level = player.skill_book.get_level(act.get_id())
  let weapontype = player.char_base.get_weapontype()
  let job = player.stats.get_job()
  let hp = player.stats.get_stat(@maple_stat.Id::HP)
  let mp = player.stats.get_stat(@maple_stat.Id::MP)
  let bullets = player.inventory.get_bulletcount()
  act.can_use(level, weapontype, job, hp, mp, bullets)
}

///|
fn has_cooldown(self : Combat, skill_id : Int) -> Bool {
  self.cooldowns[skill_id].or(0) > 0
}

///|
pub fn log_background_err[E : Show](
  f : @utils.Future[Result[Unit, E]],
  loc~ : SourceLoc = _
) -> @utils.Future[Unit] {
  f.map(fn(res) {
    match res {
      Ok(_) => ()
      Err(e) => @log.error({ "err": Show::to_string(e) }, "task failed", loc~)
    }
  })
}
