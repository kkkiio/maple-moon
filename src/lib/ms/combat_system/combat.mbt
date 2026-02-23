///|
using @combat_proto {type AttackResult}

///|
/// Global registry of all available moves (skills and regular attack).
/// Populated during game start via `register_move`.
pub let move_map : Map[Int, SpecialMove] = Map::new()

///|
/// Register a move (skill) into the global move_map.
/// Should be called during game initialization.
pub fn register_move(sp_move : SpecialMove) -> Unit {
  move_map.set(sp_move.get_id(), sp_move)
}

///|
struct Combat {
  mobs : @monster.MapMobs
  regular_attack : SpecialMove
  // TODO: Add reactors
  bullet_effects : @utils.TimedQueue[BulletEffect]
  damage_effects : @utils.TimedQueue[DamageEffect]
  bullets : Array[BulletEffect]
  // damage_numbers : Array[@ui.Number]
  cooldowns : Map[Int, Int]
  bullet_module : @bullet.Module
}

///|
pub fn Combat::new(
  mobs : @monster.MapMobs,
  bullet_module : @bullet.Module,
) -> Combat {
  {
    mobs,
    regular_attack: new_regular_attack(bullet_module),
    bullet_effects: @utils.TimedQueue::new(),
    damage_effects: @utils.TimedQueue::new(),
    bullets: Array::new(),
    // damage_numbers: Array::new(),
    cooldowns: {},
    bullet_module,
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
  // for dmg_eff in self.damage_numbers {
  //   dmg_eff.draw(viewx, viewy, alpha)
  // }
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
  // self.damage_numbers.retain(fn(dn) { not(dn.update()) })
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
  } else if move_map.get(move_id) is Some(act) {
    if act.is_attack() {
      guard character.get_look().get_equips().get_weapon() is Some(weapon) else {
        return
      }
      (act, Some(weapon))
    } else {
      (act, None)
    }
  } else {
    @log.warn("skill not registered", data={ "move_id": move_id })
    return
  }
  if act.is_attack() && not(cc.can_attack()) {
    return
  }
  let reason = self.can_use(cc, act)
  if reason == ForbidReason::FBR_NONE {
    let after_images = match attack_weapon {
      Some(weapon) => {
        let name = weapon.get_afterimage()
        let level = weapon.get_equipdata().get_reqstat(@maple_stat.Id::LEVEL)
        let after_images = @char_look.AfterImage::get_collection(name, level)
        if act.is_skill() {
          let skill_resources = act.get_afterimage()
          for k, v in skill_resources {
            // Override weapon afterimages with skill-specific ones
            after_images.set(k, v)
          }
        }
        after_images
      }
      None => Map::new()
    }
    self.apply_move(cc, act, after_images)
  } else {
    // TODO: show forbid reason
    // let weapontype = self.player.get_stats().get_weapontype()
    // ForbidSkillMessage::new(reason, weapontype).drop()
  }
}

///|
/// Get a registered skill move by ID.
/// Returns None if the skill is not registered.
pub fn get_skill_move(move_id : Int) -> SpecialMove? {
  move_map.get(move_id)
}

///|
fn Combat::apply_move(
  self : Combat,
  cc : &CombatCharacter,
  act : SpecialMove,
  after_images : Map[String, @char_look.NxAfterImage],
) -> Unit {
  let character = cc.get_character()
  let inventory = cc.get_inventory()
  if act.is_attack() {
    let (degenerate, attacktype) = check_attack_type(
      character,
      inventory,
      act.is_skill(),
    )
    let result = self.execute_attack_pipeline(
      character,
      act,
      inventory,
      attack_type=attacktype,
      degenerate~,
      fixed_targets=None,
      user_input=true,
      after_images=Some(after_images),
      strict_afterimage=true,
    )
    match result {
      Some(result) => self.apply_result_movement(cc, act, result)
      None => ()
    }
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
/// Unified attack execution pipeline used by both normal attacks and passive extra attacks.
///
/// Pipeline stages:
/// 1. play use-effects (`apply_useeffects`) and action animation (`apply_actions`);
/// 2. resolve and spawn afterimage for current stance;
/// 3. build `Attack` via `SpecialMove::make_attack`;
/// 4. resolve targets (either fixed targets or nearest mobs by range);
/// 5. apply damage/effects/network and emit `HitEvent` via `apply_attack_to_mobs`.
fn Combat::execute_attack_pipeline(
  self : Combat,
  character : @character.Character,
  act : SpecialMove,
  inventory : &@legacy_types.Inventory,
  attack_type~ : @combat_proto.AttackType,
  degenerate~ : Bool,
  fixed_targets~ : Array[Int]?,
  user_input~ : Bool,
  after_images~ : Map[String, @char_look.NxAfterImage]?,
  strict_afterimage~ : Bool,
) -> AttackResult? {
  act.apply_useeffects(character)
  act.apply_actions(character, attack_type)
  guard self.apply_attack_afterimage(
    character, act, after_images, strict_afterimage,
  ) else {
    return None
  }
  let attack = act.make_attack(character, inventory, attack_type, degenerate)
  let mob_targets = match fixed_targets {
    Some(targets) => targets
    None => {
      let range = make_attack_range(attack)
      let origin = attack.origin
      find_closest_mob(self.mobs, range, origin, attack.mobcount)
    }
  }
  let result : AttackResult = {
    ..AttackResult::new(attack),
    attacker: character.get_oid(),
  }
  self.apply_attack_to_mobs(
    character, act, attack, mob_targets, result, user_input,
  )
  Some(result)
}

///|
fn Combat::apply_attack_afterimage(
  self : Combat,
  character : @character.Character,
  act : SpecialMove,
  after_images : Map[String, @char_look.NxAfterImage]?,
  strict_afterimage : Bool,
) -> Bool {
  let after_images = match after_images {
    Some(after_images) => after_images
    None => {
      guard character.get_look().get_equips().get_weapon() is Some(weapon) else {
        return false
      }
      let after_image_name = weapon.get_afterimage()
      let level = weapon.get_equipdata().get_reqstat(@maple_stat.Id::LEVEL)
      let after_images = @char_look.AfterImage::get_collection(
        after_image_name, level,
      )
      let skill_resources = act.get_afterimage()
      for k, v in skill_resources {
        after_images.set(k, v)
      }
      after_images
    }
  }
  let stance_name = character.get_look().get_stance().name()
  guard after_images.get(stance_name) is Some(after_image) else {
    @log.error("No afterimage for stance", data={
      "stance": stance_name,
      "available": after_images.keys().collect(),
    })
    if strict_afterimage {
      panic()
    }
    return false
  }
  let look = character.get_look()
  let get_frame_fn = fn() { look.get_frame() }
  @char_look.add_after_image(
    character.get_entity(),
    get_frame_fn,
    after_image,
    character.is_facing_right(),
  )
  true
}

///|
/// Apply attack to mobs
pub fn Combat::apply_attack_to_mobs(
  self : Combat,
  character : @character.Character,
  act : SpecialMove,
  attack : @combat_proto.Attack,
  mob_targets : Array[Int],
  result : AttackResult,
  user_input : Bool,
) -> Unit {
  self.mobs.send_attack(result, attack, mob_targets)
  self.extract_effects(character, act, result)
  // Create and queue hit event for passive skills
  let source : HitSource = if user_input {
    UserInput
  } else {
    Passive(act.get_id())
  }
  let hit_event : HitEvent = {
    attacker_oid: character.get_oid(),
    move_id: act.get_id(),
    source,
    target_oids: result.damage_lines.keys().to_array(),
    result,
  }
  push_event(hit_event)
  for target_oid, damage_lines in result.damage_lines {
    let mut total_damage = 0
    for line in damage_lines {
      total_damage += line.0
    }
    @game_server.send(@maple_protocol.MobDamageMessage::{
      oid: target_oid,
      damage: total_damage,
    })
  }
}

///|
/// Trigger an extra attack (used by passive skills like Final Attack).
/// Reuses the same attack execution pipeline as normal attacks.
pub fn Combat::trigger_extra_attack(
  self : Combat,
  character : @character.Character,
  skill_id : Int,
  targets : Array[Int],
) -> Unit {
  guard move_map.get(skill_id) is Some(act) else {
    @log.warn("Passive skill not registered", data={ "skill_id": skill_id })
    return
  }
  guard character.get_look().get_equips().get_weapon() is Some(_weapon) else {
    return
  }
  let inventory : &@legacy_types.Inventory = @legacy_types.MockInventory::{  }
  ignore(
    self.execute_attack_pipeline(
      character,
      act,
      inventory,
      attack_type=@combat_proto.AttackType::MAGIC,
      degenerate=false,
      fixed_targets=Some(targets),
      user_input=false,
      after_images=None,
      strict_afterimage=false,
    ),
  )
}

///|
fn Combat::apply_result_movement(
  self : Combat,
  cc : &CombatCharacter,
  act : SpecialMove,
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
  mobs : @monster.MapMobs,
  range : @struct.Rectangle[Int],
  origin : @struct.Point[Int],
  objcount : Int,
) -> Array[Int] {
  if objcount <= 0 {
    panic()
  }
  let arr = Array::new()
  mobs.for_each_mob(fn(_oid, mob) {
    match mob.get_live_range() {
      Some(mob_range) =>
        if mob_range.overlaps(range) {
          let oid = mob.get_oid()
          let distance = mob.get_position().distance(origin)
          arr.push((distance, oid))
        }
      None => ()
    }
  })
  arr.sort_by_key(fn(pair) { pair.0 })
  arr.iter().take(objcount).map(fn(pair) { pair.1 }).collect()
}

///|
priv struct DamageEffect {
  user : @combat_proto.AttackUser
  number_params : (@ui.NumberType, Int, Int) // type, damage, y_pos
  damage : Int
  toleft : Bool
  target_oid : Int
  sp_move : SpecialMove
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
/// Load a skill and create a SpecialMove from it.
/// This is used during game initialization to pre-load skills.
pub async fn load_skill_move(
  move_id : Int,
  bullet_module : @bullet.Module,
) -> SpecialMove {
  let it = Skill::load(move_id, bullet_module)
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
    get_afterimage: fn() { it.get_afterimage() },
  }
}

///|
fn Combat::extract_effects(
  self : Combat,
  user : @character.Character,
  act : SpecialMove,
  result : AttackResult,
) -> Unit {
  let attack_user : @combat_proto.AttackUser = {
    skill_level: (user.get_skilllevel)(act.get_id()),
    level: user.get_stats().get_stat(@maple_stat.Id::LEVEL),
    second_weapon: user.is_two_handed(),
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
            number_params: number,
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
          number_params: (@ui.NumberType::HIT_NORMAL, 0, user.get_position().y),
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
            number_params: number,
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
) -> Array[(@ui.NumberType, Int, Int)] {
  let numbers = Array::new()
  let mut head = self.mobs.get_mob_head_position(oid).y
  for it in damage_lines {
    let (amount, is_critical) = it
    let t = if is_critical {
      @ui.NumberType::HIT_CRITICAL
    } else {
      @ui.NumberType::HIT_NORMAL
    }
    numbers.push((t, amount, head))
    head -= @ui.Number::row_height(is_critical)
  }
  return numbers
}

///|
fn Combat::apply_damage_effect(self : Combat, effect : DamageEffect) -> Unit {
  let head_position = self.mobs.get_mob_head_position(effect.target_oid)
  let (t, amount, start_y) = effect.number_params
  @ui.show_number(t, amount, start_y, x=head_position.x)
  guard self.mobs.get_mob(effect.target_oid) is Some(mob) else { return }
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
  act : SpecialMove,
) -> ForbidReason {
  let character = cc.get_character()
  let skill_book = cc.get_skill_book()
  let stats = cc.get_stats()
  let inventory = cc.get_inventory()
  if act.is_skill() && character.state == @character.CharState::PRONE {
    return ForbidReason::FBR_OTHER
  }
  if act.is_attack() &&
    (
      character.state == @character.CharState::LADDER ||
      character.state == @character.CharState::ROPE
    ) {
    return ForbidReason::FBR_OTHER
  }
  if self.has_cooldown(act.get_id()) {
    return ForbidReason::FBR_COOLDOWN
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
      Err(e) =>
        @log.error("task failed", data={ "err": Show::to_string(e) }, loc~)
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
let combat_ref : Ref[Combat?] = Ref::new(None)

///|
pub fn set_combat(combat : Combat?) -> Unit {
  combat_ref.val = combat
}

///|
/// Get the current combat instance. Returns None if not initialized.
pub fn get_combat() -> Combat? {
  combat_ref.val
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
  guard @game_state.game_state.phase is GameActive(..) else { return }
  guard @monster.get_map_mobs() is Some(mobs) else { return }
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
