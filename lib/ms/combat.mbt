struct Combat {
  damage_number_set : @combat_ui.DamageNumberSet
  player : @player.Player
  mobs : @monster.MapMobs
  skills : Map[Int, @combat.Skill]
  regular_attack : @combat.RegularAttack
  // TODO: Add reactors
  damage_effects : @utils.TimedQueue[DamageEffect]
  bullets : Array[BulletEffect]
  damage_numbers : Array[@combat_ui.DamageNumber]
}

pub fn Combat::new(
  damage_number_set : @combat_ui.DamageNumberSet,
  player : @player.Player,
  mobs : @monster.MapMobs
) -> Combat {
  {
    damage_number_set,
    player,
    mobs,
    skills: Map::new(),
    regular_attack: @combat.RegularAttack::default(),
    damage_effects: @utils.TimedQueue::new(),
    bullets: Array::new(),
    damage_numbers: Array::new(),
  }
}

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

pub fn update(self : Combat) -> Unit {
  self.damage_effects.update(fn(dmg_eff) { self.apply_damage_effect(dmg_eff) })
  self.bullets.retain(
    fn(mb) {
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
    },
  )
  self.damage_numbers.retain(fn(dn) { dn.update().not() })
}

pub fn use_move(self : Combat, move_id : Int) -> Unit! {
  if self.player.can_attack().not() {
    return
  }
  let move = self.get_move(move_id)
  let reason = self.player.can_use!(move)
  if reason == @combat.ForbidReason::FBR_NONE {
    self.apply_move!(move)
  } else {
    // TODO: Implement this
    // let weapontype = self.player.get_stats().get_weapontype()
    // ForbidSkillMessage::new(reason, weapontype).drop()
  }
}

fn apply_move(self : Combat, move : @combat.SpecialMove) -> Unit! {
  let player = self.player
  if move.is_attack() {
    let attack = player.prepare_attack!(move.is_skill())
    move.apply_useeffects(player)
    move.apply_actions!(player, attack.t)
    player.set_afterimage(move.get_id())
    move.apply_stats(player, attack)
    let origin = attack.origin
    let mut range = attack.range
    let hrange = (range.left().to_double() * attack.hrange).to_int()
    range = if attack.toleft {
      @struct.Rectangle::from4(
        origin.x + hrange,
        origin.x + range.right(),
        origin.y + range.top(),
        origin.y + range.bottom(),
      )
    } else {
      @struct.Rectangle::from4(
        origin.x - range.right(),
        origin.x - hrange,
        origin.y + range.top(),
        origin.y + range.bottom(),
      )
    }

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
    self.extract_effects(player, move, result)
    self.apply_result_movement(move, result)
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
    move.apply_useeffects(player)
    move.apply_actions!(player, @combat.AttackType::MAGIC)
    let moveid = move.get_id()
    let level = player.get_skills().get_level(moveid)
    new_use_skill_packet(moveid, level).dispatch()
  }
}

fn apply_result_movement(
  self : Combat,
  move : @combat.SpecialMove,
  result : @combat.AttackResult
) -> Unit {
  if move.get_id() == @skill.SkillId::RUSH_HERO.int_value() ||
    move.get_id() == @skill.SkillId::RUSH_PALADIN.int_value() ||
    move.get_id() == @skill.SkillId::RUSH_DK.int_value() {
    self.apply_rush(result)
  }
}

fn apply_rush(self : Combat, result : @combat.AttackResult) -> Unit {
  if result.mobcount == 0 {
    return
  }
  let mob_position = self.mobs.get_mob_position(result.last_oid)
  let targetx = mob_position.x
  self.player.rush(targetx.to_double())
}

fn find_closest_mob(
  objs : @map_object.MapObjects[@monster.Mob],
  range : @struct.Rectangle[Int],
  origin : @struct.Point[Int],
  objcount : Int
) -> Array[Int] {
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

struct DamageEffect {
  user : @combat.AttackUser
  number : @combat_ui.DamageNumber
  damage : Int
  toleft : Bool
  target_oid : Int
  move_id : Int
}

struct BulletEffect {
  damageeffect : DamageEffect
  bullet : @combat.Bullet
  mut target : @struct.Point[Int]
}

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

fn new_damage_reactor_packet(
  oid : Int,
  position : @struct.Point[Int],
  stance : Int,
  skillid : Int
) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.OutPacketOpcode::DAMAGE_REACTOR)
  packet.write_int(oid)
  packet.write_point(position)
  packet.write_short(stance)
  packet.skip(4)
  packet.write_int(skillid)
  packet
}

// Notifies the server of an attack. The opcode is determined by the attack
// type. Attack::CLOSE = CLOSE_ATTACK(44) Attack::RANGED = RANGED_ATTACK(45)
// Attack::MAGIC = MAGIC_ATTACK(46)
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

fn opcodefor(t : @combat.AttackType) -> @net.OutPacketOpcode {
  match t {
    @combat.AttackType::CLOSE => @net.OutPacketOpcode::CLOSE_ATTACK
    @combat.AttackType::RANGED => @net.OutPacketOpcode::RANGED_ATTACK
    _ => @net.OutPacketOpcode::MAGIC_ATTACK
  }
}

pub fn get_move(self : Combat, _move_id : Int) -> @combat.SpecialMove {
  self.regular_attack
  // TODO: support skills
}

fn extract_effects(
  self : Combat,
  user : @character.Character,
  move : @combat.SpecialMove,
  result : @combat.AttackResult
) -> Unit {
  let attack_user : @combat.AttackUser = {
    skill_level: user.get_skilllevel(move.get_id()),
    level: user.get_level(),
    second_weapon: user.is_twohanded(),
    flip: result.toleft.not(),
  }
  if result.bullet != 0 {
    // TODO: Implement bullet effects
  } else {
    for oid, vec in result.damage_lines {
      if self.mobs.contains(oid) {
        let numbers = self.place_numbers(oid, vec)
        let mut i = 0
        for number in numbers {
          self.damage_effects.push(
            user.get_attackdelay(i).to_int64(),
            {
              user: attack_user,
              number,
              damage: vec[i].0,
              toleft: result.toleft,
              target_oid: oid,
              move_id: move.get_id(),
            },
          )
          i += 1
        }
      }
    }
  }
}

fn place_numbers(
  self : Combat,
  oid : Int,
  damage_lines : Array[(Int, Bool)]
) -> Array[@combat_ui.DamageNumber] {
  let numbers = Array::new()
  let mut head = self.mobs.get_mob_head_position(oid).y
  for it in damage_lines {
    let (amount, is_critical) = it
    let t = if is_critical {
      @combat_ui.DamageNumberType::CRITICAL
    } else {
      @combat_ui.DamageNumberType::NORMAL
    }
    numbers.push(self.damage_number_set.new_damage_number(t, amount, head))
    head -= @combat_ui.DamageNumber::row_height(is_critical)
  }
  return numbers
}

fn apply_damage_effect(self : Combat, effect : DamageEffect) -> Unit {
  let head_position = self.mobs.get_mob_head_position(effect.target_oid)
  let number = effect.number
  self.damage_numbers.push(number)
  number.set_x(head_position.x)
  let move = self.get_move(effect.move_id)
  self.mobs.apply_damage(
    effect.target_oid,
    effect.damage,
    effect.toleft,
    effect.user,
    move,
  )
}
