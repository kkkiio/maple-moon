///|
struct Combat {
  damage_number_set : @ui.NumberSet
  mobs : @monster.MapMobs
  skill_cache : Map[Int, @utils.Future[Result[@combat_impl.SpecialMove, Error]]]
  regular_attack : @combat_impl.SpecialMove
  // TODO: Add reactors
  bullet_effects : @utils.TimedQueue[BulletEffect]
  damage_effects : @utils.TimedQueue[DamageEffect]
  bullets : Array[BulletEffect]
  damage_numbers : Array[@ui.Number]
  cooldowns : Map[Int, Int]
  add_task_fn : (@utils.Future[Unit]) -> Unit
  network : @net.Network
  string_loader : @resource.SyncLoader
}

///|
pub fn Combat::new(
  damage_number_set : @ui.NumberSet,
  mobs : @monster.MapMobs,
  packet_processor : @net.Network,
  cooldowns : Map[Int, Int],
  add_task_fn : (@utils.Future[Unit]) -> Unit,
  string_loader : @resource.SyncLoader
) -> Combat {
  {
    damage_number_set,
    mobs,
    skill_cache: Map::new(),
    regular_attack: @combat_impl.new_regular_attack(string_loader),
    bullet_effects: @utils.TimedQueue::new(),
    damage_effects: @utils.TimedQueue::new(),
    bullets: Array::new(),
    damage_numbers: Array::new(),
    cooldowns,
    add_task_fn,
    network: packet_processor,
    string_loader,
  }
}

///|
pub fn Combat::draw(
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
pub fn Combat::update(self : Combat) -> Unit {
  for
    bullet_effect in self.bullet_effects.process(
      timestep=@config.step_time_ms.to_int64(),
    ) {
    self.apply_bullet_effect(bullet_effect)
  }
  for
    dmg_eff in self.damage_effects.process(
      timestep=@config.step_time_ms.to_int64(),
    ) {
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
      return not(apply)
    }
    not(mb.bullet.update(mb.target))
  })
  self.damage_numbers.retain(fn(dn) { not(dn.update()) })
}

///|
pub fn use_move(self : Combat, player : @player.Player, move_id : Int) -> Unit {
  if not(player.can_attack()) {
    return
  }
  let act_f = self.get_move(move_id)
  let task = act_f.map_exn(fn(act) {
      let act = act.unwrap_or_error!()
      let reason = self.can_use(
        player.character,
        player.skill_book,
        player.stats,
        player.inventory,
        act,
      )
      if reason == @combat_impl.ForbidReason::FBR_NONE {
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
fn Combat::apply_move(
  self : Combat,
  player : @player.Player,
  act : @combat_impl.SpecialMove
) -> Unit {
  if act.is_attack() {
    let (degenerate, attacktype) = check_attack_type(
      player.character,
      player.inventory,
      act.is_skill(),
    )
    act.apply_useeffects(player.character)
    act.apply_actions(player.character, attacktype)
    player.character.set_afterimage(act.get_id())
    let attack = act.make_attack(
      player.character,
      player.inventory,
      attacktype,
      degenerate,
    )
    let range = make_attack_range(attack)
    // This approach should also make it easier to implement PvP
    let mobcount = attack.mobcount
    let result = {
      ..AttackResult::new(attack),
      attacker: player.character.get_oid(),
    }
    let mob_objs = self.mobs.get_mobs()
    // let reactor_objs = self.reactors.get_reactors()
    let origin = attack.origin
    let mob_targets = find_closest_mob(mob_objs, range, origin, mobcount)
    // let reactor_targets = self.find_closest_reactor(
    //   reactor_objs, range, origin, mobcount, false,
    // )
    self.mobs.send_attack(result, attack, mob_targets, mobcount, self.network)
    self.extract_effects(player.character, act, result)
    self.apply_result_movement(player, act, result)
    self.network.send_message(AttackMessage(result))
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
    act.apply_useeffects(player.character)
    act.apply_actions(player.character, @combat_proto.AttackType::MAGIC)
    let moveid = act.get_id()
    let level = player.get_skills().get_level(moveid)
    self.network.send_message({ move_id: moveid, level })
  }
}

///|
fn apply_result_movement(
  self : Combat,
  player : @player.Player,
  act : @combat_impl.SpecialMove,
  result : AttackResult
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
  result : AttackResult
) -> Unit {
  if result.mob_count == 0 {
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
    match mob.get_live_range() {
      Some(mob_range) =>
        if mob_range.overlaps(range) {
          let oid = mob.get_oid()
          let distance = mob.get_position().distance(origin)
          arr.push((distance, oid))
        }
      None => ()
    }
  }
  arr.sort_by_key(fn(pair) { pair.0 })
  arr.iter().take(objcount).map(fn(pair) { pair.1 }).collect()
}

///|
priv struct DamageEffect {
  user : @combat_proto.AttackUser
  number : @ui.Number
  damage : Int
  toleft : Bool
  target_oid : Int
  move_id : Int
}

///|
priv struct BulletEffect {
  damageeffect : DamageEffect
  bullet : @combat_proto.Bullet
  mut target : @struct.Point[Int]
}

///|
priv struct UseSkillMessage {
  move_id : Int
  level : Int
} derive(Show)

///|
impl @net.OutMessage for UseSkillMessage with pack(self) {
  let packet = @net.OutPacket::new(@net.ClientOpcode::USE_SKILL)
  packet.write_time()
  packet.write_int(self.move_id)
  packet.write_byte(self.level.to_byte())

  // If monster magnet : some more bytes

  if self.move_id % 10000000 == 1004 {
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
type AttackMessage AttackResult derive(Show)

///|
pub impl @net.OutMessage for AttackMessage with pack(self) {
  let attack = self._
  let opcode = match attack.t {
    @combat_proto.AttackType::CLOSE => @net.ClientOpcode::CLOSE_ATTACK
    @combat_proto.AttackType::RANGED => @net.ClientOpcode::RANGED_ATTACK
    _ => @net.ClientOpcode::MAGIC_ATTACK
  }
  let packet = @net.OutPacket::new(opcode)
  packet.skip(1)
  packet.write_byte(((attack.mob_count << 4) | attack.hitcount).to_byte())
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
  if attack.t == @combat_proto.AttackType::RANGED {
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
pub fn get_move(
  self : Combat,
  move_id : Int
) -> @utils.Future[Result[@combat_impl.SpecialMove, Error]] {
  if move_id == 0 {
    return self.regular_attack |> Ok |> @utils.Future::from_value
  }
  self.skill_cache.get_or_init(move_id, fn() {
    @combat_impl.Skill::load(self.string_loader, move_id).map(fn(f) {
      f.map(fn(it) {
        {
          id: it.get_id(),
          attack: it.is_attack(),
          skill: true,
          apply_useeffects: fn(c) { it.apply_useeffects(c) },
          apply_actions: fn(attack_type, c) { it.apply_actions(attack_type, c) },
          make_attack: fn(c, i, t, _) { it.make_attack(c, i.get_bulletid(), t) },
          get_bullet: fn(c, bulletid) { it.get_bullet(c, bulletid) },
          can_use: fn(level, weapontype, job, hp, mp, bullet) {
            it.can_use(level, weapontype, job, hp, mp, bullet)
          },
          apply_hit_effects: fn(attack_user, mob) {
            it.apply_hit_effects(attack_user, mob)
          },
        }
      })
    })
  })
}

///|
fn extract_effects(
  self : Combat,
  user : @character.Character,
  act : @combat_impl.SpecialMove,
  result : AttackResult
) -> Unit {
  let attack_user : @combat_proto.AttackUser = {
    skill_level: (user.get_skilllevel)(act.get_id()),
    level: user.get_stats().get_stat(@maple_stat.Id::LEVEL),
    second_weapon: user.is_twohanded(),
    flip: not(result.toleft),
  }
  if result.bullet != 0 {
    let bullet = @combat_proto.Bullet::new(
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
      let target = user.get_position() + @struct.Point::new(xshift, -26)
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
  guard self.mobs.get_mobs().get(effect.target_oid) is Some(mob) else { return }
  mob.apply_damage(effect.damage, effect.toleft, self.network)
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

///| Find out the type of attack and whether it should be degenerate
/// 
/// Returns (degenerate, attack_type) where degenerate is true if the skill or ammunition is missing
pub fn check_attack_type(
  character : @character.CharBase,
  inventory : &@player.Inventory,
  skill : Bool
) -> (Bool, @combat_proto.AttackType) {
  if character.state == @character.CharState::PRONE {
    (true, @combat_proto.AttackType::CLOSE)
  } else {
    match character.get_weapontype() {
      @weapon.Type::BOW
      | @weapon.Type::CROSSBOW
      | @weapon.Type::CLAW
      | @weapon.Type::GUN => {
        let degenerate = not(inventory.has_projectile())
        (
          degenerate,
          if degenerate {
            @combat_proto.AttackType::CLOSE
          } else {
            @combat_proto.AttackType::RANGED
          },
        )
      }
      @weapon.Type::WAND | @weapon.Type::STAFF => {
        let degenerate = not(skill)
        (
          degenerate,
          if degenerate {
            @combat_proto.AttackType::CLOSE
          } else {
            @combat_proto.AttackType::MAGIC
          },
        )
      }
      _ => (false, @combat_proto.AttackType::CLOSE)
    }
  }
}

///|
pub fn can_use(
  self : Combat,
  character : @character.CharBase,
  skill_book : &@player.SkillBook,
  stats : @char_stats.CharStats,
  inventory : &@player.Inventory,
  act : @combat_impl.SpecialMove
) -> @combat_impl.ForbidReason {
  if act.is_skill() && character.state == @character.CharState::PRONE {
    return @combat_impl.ForbidReason::FBR_OTHER
  }
  if act.is_attack() &&
    (
      character.state == @character.CharState::LADDER ||
      character.state == @character.CharState::ROPE
    ) {
    return @combat_impl.ForbidReason::FBR_OTHER
  }
  if self.has_cooldown(act.get_id()) {
    return @combat_impl.ForbidReason::FBR_COOLDOWN
  }
  let level = skill_book.get_level(act.get_id())
  let weapontype = character.get_weapontype()
  let job = stats.get_job()
  let hp = stats.get_stat(@maple_stat.Id::HP)
  let mp = stats.get_stat(@maple_stat.Id::MP)
  let bullets = inventory.get_bulletcount()
  act.can_use(level, weapontype, job, hp, mp, bullets)
}

///|
fn has_cooldown(self : Combat, skill_id : Int) -> Bool {
  self.cooldowns.get(skill_id).or(0) > 0
}

///|
pub fn[E : Show] log_background_err(
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

///|
typealias Rectangle[T] = @struct.Rectangle[T]

///|
pub fn make_attack_range(attack : @combat_proto.Attack) -> Rectangle[Int] {
  let origin = attack.origin
  let left = (attack.range.left().to_double() * attack.hrange).to_int()
  let rel_range = Rectangle::from4(
    left,
    attack.range.right(),
    attack.range.top(),
    attack.range.bottom(),
  )
  (if attack.toleft { rel_range } else { rel_range.flip_x() }).shift(origin)
}

///|
typealias AttackResult = @combat_proto.AttackResult

///|
pub fn parse_cooldowns(recv : @net.InPacket) -> Map[Int, Int]! {
  let size = recv.read_short!()
  let cooldowns = Map::new()
  for i in 0..<size {
    let skill_id = recv.read_int!()
    let cooltime = recv.read_short!()
    cooldowns[skill_id] = cooltime
  }
  cooldowns
}
