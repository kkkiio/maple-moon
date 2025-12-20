///|
using @combat_proto {type AttackResult}

///|
struct Combat {
  damage_number_set : @ui.NumberSet
  mobs : @monster.MapMobs
  regular_attack : @combat_impl.SpecialMove
  // TODO: Add reactors
  bullet_effects : @utils.TimedQueue[BulletEffect]
  damage_effects : @utils.TimedQueue[DamageEffect]
  bullets : Array[BulletEffect]
  damage_numbers : Array[@ui.Number]
  cooldowns : Map[Int, Int]
  bullet_module : @bullet.Module
  skill_cache : Map[Int, @utils.Future[@combat_impl.SpecialMove]]
  after_image_cache : Map[
    CacheKey,
    @utils.Future[Map[String, @char_look.AfterImage]],
  ]
  attack_events_listeners : Array[(AttackEvent) -> Bool]
}

///|
pub fn Combat::new(
  damage_number_set : @ui.NumberSet,
  mobs : @monster.MapMobs,
  bullet_module : @bullet.Module,
) -> Combat {
  let server_listener = fn(_event : AttackEvent) -> Bool {
    // TODO: send to server
    // network.send_message(AttackMessage(event.result))
    true // keep the listener
  }
  {
    damage_number_set,
    mobs,
    skill_cache: Map::new(),
    regular_attack: @combat_impl.new_regular_attack(bullet_module),
    bullet_effects: @utils.TimedQueue::new(),
    damage_effects: @utils.TimedQueue::new(),
    bullets: Array::new(),
    damage_numbers: Array::new(),
    cooldowns: {},
    bullet_module,
    after_image_cache: Map::new(),
    attack_events_listeners: [server_listener],
  }
}

///|
pub fn Combat::set_cooldowns(self : Combat, cooldowns : Map[Int, Int]) -> Unit {
  self.cooldowns.clear()
  for skill_id, cooldown in cooldowns {
    self.cooldowns.set(skill_id, cooldown)
  }
}

///|
pub fn Combat::draw(
  self : Combat,
  viewx : Double,
  viewy : Double,
  alpha : Double,
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
      timestep=@logic_fps.STEP_TIME_MS.to_int64(),
    ) {
    self.apply_bullet_effect(bullet_effect)
  }
  for
    dmg_eff in self.damage_effects.process(
      timestep=@logic_fps.STEP_TIME_MS.to_int64(),
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
/// Use a skill or regular attack
pub fn use_move(cc : &CombatCharacter, move_id : Int) -> Unit {
  guard combat_ref.val is Some(combat) else { return }
  combat.use_move(cc, move_id)
}

///|
/// Use a skill or regular attack
fn Combat::use_move(
  self : Combat,
  cc : &CombatCharacter,
  move_id : Int,
) -> Unit {
  let character = cc.get_character()
  let (act, attack_weapon) = if move_id == 0 {
    guard character.get_look().get_equips().get_weapon() is Some(weapon) else {
      return
    }
    (self.regular_attack, Some(weapon))
  } else if self.skill_cache.get(move_id) is Some(act_fut) {
    guard act_fut.poll() is Some(act) else {
      @log.warn({ "move_id": move_id }, "loading skill") // TODO: load skill early
      return
    }
    if act.is_attack() {
      guard character.get_look().get_equips().get_weapon() is Some(weapon) else {
        return
      }
      (act, Some(weapon))
    } else {
      (act, None)
    }
  } else {
    @log.warn({ "move_id": move_id }, "loading skill") // TODO: load skill early
    self.skill_cache[move_id] = @io_service.submit_background_task(fn() {
      self.load_sp_move(move_id)
    }).map(@log.unwrap_err(_))
    return
  }
  if act.is_attack() && not(cc.can_attack()) {
    return
  }
  let reason = self.can_use(cc, act)
  if reason == @combat_impl.ForbidReason::FBR_NONE {
    let after_images = match attack_weapon {
      Some(weapon) => {
        let key = CacheKey(
          move_id,
          weapon.get_afterimage(),
          weapon.get_equipdata().get_reqstat(@maple_stat.Id::LEVEL),
        )
        if self.after_image_cache.get(key) is Some(fut) {
          if fut.poll() is Some(after_images) {
            after_images
          } else {
            @log.warn({ "move_id": move_id }, "loading afterimage") // TODO: load afterimage early
            return
          }
        } else {
          @log.warn({ "move_id": move_id }, "loading afterimage") // TODO: load afterimage early
          self.after_image_cache[key] = @io_service.submit_background_task(fn() {
            load_after_images_by_skill_weapon(key)
          }).map(@log.unwrap_err(_))
          return
        }
      }
      None => {}
    }
    self.apply_move(cc, act, after_images)
  } else {
    // TODO: show forbid reason
    // let weapontype = self.player.get_stats().get_weapontype()
    // ForbidSkillMessage::new(reason, weapontype).drop()
  }
}

///|
pub fn Combat::listen_attack_events(
  self : Combat,
  listener : (AttackEvent) -> Bool,
) -> Unit {
  self.attack_events_listeners.push(listener)
}

///|
pub struct AttackEvent {
  result : @combat_proto.AttackResult
  /// 是否是玩家输入的攻击, 而不是技能追加的攻击
  user_input : Bool
} derive(Show)

///|
pub fn Combat::get_skill_move(
  self : Combat,
  move_id : Int,
) -> @utils.Future[@combat_impl.SpecialMove] {
  if self.skill_cache.get(move_id) is Some(fut) {
    return fut
  }
  @log.warn({ "move_id": move_id }, "loading skill") // TODO: load skill early
  let fut = @io_service.submit_background_task(fn() {
    self.load_sp_move(move_id)
  }).map(@log.unwrap_err(_))
  self.skill_cache[move_id] = fut
  fut
}

///|
fn Combat::apply_move(
  self : Combat,
  cc : &CombatCharacter,
  act : @combat_impl.SpecialMove,
  after_images : Map[String, @char_look.AfterImage],
) -> Unit {
  let character = cc.get_character()
  let inventory = cc.get_inventory()
  if act.is_attack() {
    let (degenerate, attacktype) = check_attack_type(
      character,
      inventory,
      act.is_skill(),
    )
    act.apply_useeffects(character)
    act.apply_actions(character, attacktype) // WARN: this will change the stance
    let stance_name = character.get_look().get_stance().name()
    character.set_afterimage(after_images.get(stance_name).unwrap())
    let attack = act.make_attack(character, inventory, attacktype, degenerate)
    let range = make_attack_range(attack)
    let mobcount = attack.mobcount
    let result = { ..AttackResult::new(attack), attacker: character.get_oid() }
    let mob_objs = self.mobs.get_mobs()
    // TODO: check reactor objects
    let origin = attack.origin
    let mob_targets = find_closest_mob(mob_objs, range, origin, mobcount)
    self.apply_result_movement(cc, act, result)
    self.apply_attack_to_mobs(character, act, attack, mob_targets, result, true)
  } else {
    act.apply_useeffects(character)
    act.apply_actions(character, @combat_proto.AttackType::MAGIC)
    let moveid = act.get_id()
    let skill_book = cc.get_skill_book()
    let level = skill_book.get_level(moveid)
    // self.network.send_message({ move_id: moveid, level })
    // TODO: send to server
    ignore(level)
  }
}

///|
/// Apply attack to mobs
pub fn Combat::apply_attack_to_mobs(
  self : Combat,
  character : @character.Character,
  act : @combat_impl.SpecialMove,
  attack : @combat_proto.Attack,
  mob_targets : Array[Int],
  result : AttackResult,
  user_input : Bool,
) -> Unit {
  self.mobs.send_attack(result, attack, mob_targets)
  self.extract_effects(character, act, result)
  self.attack_events_listeners.retain(fn(listener) {
    listener({ result, user_input })
  })
}

///|
fn Combat::apply_result_movement(
  self : Combat,
  cc : &CombatCharacter,
  act : @combat_impl.SpecialMove,
  result : AttackResult,
) -> Unit {
  if act.get_id() == @skill.SkillId::RUSH_HERO.int_value() ||
    act.get_id() == @skill.SkillId::RUSH_PALADIN.int_value() ||
    act.get_id() == @skill.SkillId::RUSH_DK.int_value() {
    self.apply_rush(cc, result)
  }
}

///|
fn Combat::apply_rush(
  self : Combat,
  cc : &CombatCharacter,
  result : AttackResult,
) -> Unit {
  if result.mob_count == 0 {
    return
  }
  let mob_position = self.mobs.get_mob_position(result.last_oid)
  let targetx = mob_position.x
  cc.rush(targetx.to_double())
}

///|
fn find_closest_mob(
  objs : @map_object.MapObjects[@monster.Mob],
  range : @struct.Rectangle[Int],
  origin : @struct.Point[Int],
  objcount : Int,
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
  sp_move : @combat_impl.SpecialMove
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

///|
/// Notifies the server of an attack. 
struct AttackMessage(AttackResult) derive(Show)

///|
pub impl @net.OutMessage for AttackMessage with pack(self) {
  let attack = self.0
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
async fn Combat::load_sp_move(
  self : Combat,
  move_id : Int,
) -> @combat_impl.SpecialMove {
  let it = @combat_impl.Skill::load(move_id, self.bullet_module)
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
}

///|
fn Combat::extract_effects(
  self : Combat,
  user : @character.Character,
  act : @combat_impl.SpecialMove,
  result : AttackResult,
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
            sp_move: act,
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
          sp_move: self.regular_attack, // TODO: what should this be?
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
            sp_move: act,
          })
          i += 1
        }
      }
    }
  }
}

///|
fn Combat::place_numbers(
  self : Combat,
  oid : Int,
  damage_lines : Array[(Int, Bool)],
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
fn Combat::apply_damage_effect(self : Combat, effect : DamageEffect) -> Unit {
  let head_position = self.mobs.get_mob_head_position(effect.target_oid)
  let number = effect.number
  self.damage_numbers.push(number)
  number.set_x(head_position.x)
  guard self.mobs.get_mobs().get(effect.target_oid) is Some(mob) else { return }
  mob.apply_damage(effect.damage, effect.toleft)
  let act = effect.sp_move
  act.apply_hit_effects(effect.user, mob)
}

///|
fn Combat::apply_bullet_effect(self : Combat, effect : BulletEffect) -> Unit {
  if effect.bullet.set_target(effect.target) {
    self.apply_damage_effect(effect.damageeffect)
  } else {
    self.bullets.push(effect)
  }
}

///|
/// Find out the type of attack and whether it should be degenerate
/// 
/// Returns (degenerate, attack_type) where degenerate is true if the skill or ammunition is missing
pub fn check_attack_type(
  character : @character.Character,
  inventory : &@legacy_types.Inventory,
  skill : Bool,
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
pub fn Combat::can_use(
  self : Combat,
  cc : &CombatCharacter,
  act : @combat_impl.SpecialMove,
) -> @combat_impl.ForbidReason {
  let character = cc.get_character()
  let skill_book = cc.get_skill_book()
  let stats = cc.get_stats()
  let inventory = cc.get_inventory()
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
fn Combat::has_cooldown(self : Combat, skill_id : Int) -> Bool {
  self.cooldowns.get(skill_id).unwrap_or(0) > 0
}

///|
#callsite(autofill(loc))
pub fn[E : Show] log_background_err(
  f : @utils.Future[Result[Unit, E]],
  loc~ : SourceLoc,
) -> @utils.Future[Unit] {
  f.map(fn(res) {
    match res {
      Ok(_) => ()
      Err(e) => @log.error({ "err": Show::to_string(e) }, "task failed", loc~)
    }
  })
}

///|
using @struct {type Rectangle}

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
pub fn parse_cooldowns(recv : @net.InPacket) -> Map[Int, Int] raise {
  let size = recv.read_short()
  let cooldowns = Map::new()
  for i in 0..<size {
    let skill_id = recv.read_int()
    let cooltime = recv.read_short()
    cooldowns[skill_id] = cooltime
  }
  cooldowns
}

///|
priv struct CacheKey(Int, String, Int) derive(Show, Eq, Hash)

///|
async fn load_after_images_by_skill_weapon(
  key : CacheKey,
) -> Map[String, @char_look.AfterImage] {
  let skill_id = key.0
  let wepon_after_image_name = key.1
  let weapon_level = key.2
  let after_images = Map::new()
  if skill_id > 0 {
    let strid = @utils.stoi_left_pad0(skill_id, 7)
    let skill_srcs = @resource.get_skill_loader().load_res_async([
      "\{strid[:3]}.img",
      "skill",
      strid,
      "afterimage",
      wepon_after_image_name,
    ])
    for src in skill_srcs {
      let stance_name = src.name()
      let resource : @char_look.AfterNxImageResource = @json.from_json(
        src.value(),
      )
      let after_image = @char_look.AfterImage::new(resource.simplify())
      after_images[stance_name] = after_image
    }
  }
  let path = [wepon_after_image_name + ".img", (weapon_level / 10).to_string()]
  let srcs = @char_look.get_afterimage_loader().load_res_async(path)
  for src in srcs {
    let stance_name = src.name()
    if after_images.get(stance_name) is Some(_) { // prefer skill afterimage
      continue
    }
    let resource : @char_look.AfterNxImageResource = @json.from_json(
      src.value(),
    )
    let after_image = @char_look.AfterImage::new(resource.simplify())
    after_images[stance_name] = after_image
  }
  after_images
}

///|
let combat_ref : Ref[Combat?] = Ref::new(None)

///|
pub fn set_combat(combat : Combat?) -> Unit {
  combat_ref.val = combat
}

///|
let player_ref : Ref[&DamagableCharacter?] = Ref::new(None)

///|
pub fn set_player(player : &DamagableCharacter?) -> Unit {
  player_ref.val = player
}

///|
pub fn combat_system(_delta : Double) -> Unit {
  guard combat_ref.val is Some(combat) else { return }
  guard @game_state.game_state.phase is GameActive(mobs~, ..) else { return }
  if player_ref.val is Some(player) && not(player.is_invincible()) {
    let moving_object : @physics.MovingObject = player.get_phobj().moving_object
    match mobs.find_colliding(moving_object) {
      Some(oid_id) =>
        match mobs.create_attack(oid_id) {
          Some(attack) => {
            let result = player.damage(attack)
            // TODO: handle result
            // self.network.send_message(
            //   new_take_damage_packet_from_mob(result, TakeDamageFrom::TOUCH),
            // )
            ignore(result)
          }
          None => ()
        }
      None => ()
    }
  }
  for i in 0..<@logic_fps.get_logic_times() {
    combat.update()
  }
}
