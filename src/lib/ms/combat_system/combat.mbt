///|
using @combat_proto {type AttackResult}

///|
struct Combat {
  mobs : @monster.MapMobs
  regular_attack : SpecialMove
  // TODO: Add reactors
  damage_effects : @utils.TimedQueue[DamageEffect]
  // damage_numbers : Array[@ui.Number]
  cooldowns : Map[Int, Int]
}

///|
/// Create a combat runtime bound to the provided map mob collection.
pub fn Combat::new(mobs : @monster.MapMobs) -> Combat {
  {
    mobs,
    regular_attack: new_regular_attack(),
    damage_effects: @utils.TimedQueue::new(),
    // damage_numbers: Array::new(),
    cooldowns: {},
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
  _self : Combat,
  _viewx : Double,
  _viewy : Double,
  _alpha : Double,
) -> Unit {
  ()
}

///|
pub fn Combat::update(self : Combat) -> Unit {
  for
    dmg_eff in self.damage_effects.process(
      timestep=@logic_fps.STEP_TIME_MS.to_int64(),
    ) {
    self.apply_damage_effect(dmg_eff)
  }
  // self.damage_numbers.retain(fn(dn) { not(dn.update()) })
}

///|
pub fn Combat::apply_move(
  self : Combat,
  cc : &CombatCharacter,
  act : SpecialMove,
  after_images : Map[String, @char_look.NxAfterImage],
) -> Unit {
  let character = cc.get_character()
  let inventory = cc.get_inventory()
  if act.is_attack() {
    let (degenerate, attacktype) = resolve_attack_type(
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
    None => self.resolve_attack_targets(character, act, attack)
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
  _ : Combat,
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
  let target_oids = result.damage_lines.keys().to_array()
  if attack.t == @combat_proto.AttackType::RANGED && target_oids.is_empty() {
    @log.warn("ranged attack has no resolved targets", data={
      "attacker_oid": character.get_oid(),
      "move_id": act.get_id(),
      "bullet": result.bullet,
      "requested_target_oids": mob_targets,
    })
  }
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
    target_oids,
    result,
  }
  push_event(hit_event)
  if result.bullet == 0 {
    for target_oid, damage_lines in result.damage_lines {
      let mut total_damage = 0
      for line in damage_lines {
        total_damage += line.0
      }
      @game_server.send(@server_proto.MobDamageMessage::{
        oid: target_oid,
        damage: total_damage,
      })
    }
  }
}

///|
/// Trigger an extra attack (used by passive skills like Final Attack).
/// Reuses the same attack execution pipeline as normal attacks.
pub fn Combat::trigger_extra_attack(
  self : Combat,
  character : @character.Character,
  act : SpecialMove,
  targets : Array[Int],
) -> Unit {
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
pub(all) enum RangeSemantics {
  LegacySingleRange
  ProjectileThenAoe
} derive(Eq)

///|
fn get_range_semantics(move_id : Int) -> RangeSemantics {
  match @skill.SkillId::from_int(move_id) {
    Some(@skill.SkillId::ARROW_BOMB_BOW) => RangeSemantics::ProjectileThenAoe
    _ => RangeSemantics::LegacySingleRange
  }
}

///|
fn Combat::resolve_attack_targets(
  self : Combat,
  character : @character.Character,
  act : SpecialMove,
  attack : @combat_proto.Attack,
) -> Array[Int] {
  match get_range_semantics(act.get_id()) {
    RangeSemantics::LegacySingleRange => {
      let range = make_attack_range(attack)
      find_closest_mob(self.mobs, range, attack.origin, attack.mobcount)
    }
    RangeSemantics::ProjectileThenAoe => {
      // Stage 1: primary target is resolved by regular ranged cast range.
      let cast_range = make_world_range(
        attack.origin,
        attack.toleft,
        character.stats.get_range(),
        1.0,
      )
      let primary = find_closest_mob(self.mobs, cast_range, attack.origin, 1)
      guard primary.length() > 0 else { return [] }
      let primary_oid = primary[0]
      let center = self.mobs.get_mob_position(primary_oid)

      // Stage 2: splash uses skill lt/rb around the primary target.
      let aoe_range = attack.range.shift(center)
      let splash = find_closest_mob(
        self.mobs,
        aoe_range,
        center,
        attack.mobcount,
      )
      let targets = [primary_oid]
      for oid in splash {
        if not(targets.contains(oid)) {
          targets.push(oid)
        }
      }
      targets.iter().take(attack.mobcount).collect()
    }
  }
}

///|
priv struct DamageEffect {
  user : @combat_proto.AttackUser
  number_params : (@ui.NumberType, Int, Int) // type, damage, y_pos
  damage : Int
  toleft : Bool
  target_oid : Int
  sp_move : SpecialMove
  send_damage_to_server : Bool
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
    if get_range_semantics(act.get_id()) == RangeSemantics::ProjectileThenAoe {
      self.extract_projectile_then_aoe_effects(user, act, result, attack_user)
      return
    }
    for oid, vec in result.damage_lines {
      if self.mobs.get_mob(oid) is Some(_) {
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
            send_damage_to_server: true,
          }
          @bullet.spawn_bullet(
            user.get_attackdelay(i).to_int64(),
            act.get_bullet(user, result.bullet),
            user.get_position(),
            result.toleft,
            head,
            fn() { self.apply_damage_effect(effect) },
            fn(prev_target) {
              if self.mobs.get_mob(oid) is Some(_) {
                self.mobs.get_mob_head_position(oid)
              } else {
                prev_target
              }
            },
          )
          i += 1
        }
      }
    }
    if result.damage_lines.is_empty() { // TODO: what does this mean?
      let target = miss_bullet_target_position(user, act, result)
      for i in 0..<result.hitcount {
        let effect : DamageEffect = {
          user: attack_user,
          number_params: (@ui.NumberType::HIT_NORMAL, 0, user.get_position().y),
          damage: 0,
          toleft: false,
          target_oid: 0,
          sp_move: self.regular_attack, // TODO: what should this be?
          send_damage_to_server: false,
        }
        @bullet.spawn_bullet(
          user.get_attackdelay(i).to_int64(),
          act.get_bullet(user, result.bullet),
          user.get_position(),
          result.toleft,
          target,
          fn() { self.apply_damage_effect(effect) },
          fn(prev_target) { prev_target },
        )
      }
    }
  } else {
    for oid, vec in result.damage_lines {
      if self.mobs.get_mob(oid) is Some(_) {
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
            send_damage_to_server: false,
          })
          i += 1
        }
      }
    }
  }
}

///|
fn Combat::extract_projectile_then_aoe_effects(
  self : Combat,
  user : @character.Character,
  act : SpecialMove,
  result : AttackResult,
  attack_user : @combat_proto.AttackUser,
) -> Unit {
  if result.damage_lines.is_empty() {
    let target = miss_bullet_target_position(user, act, result)
    @bullet.spawn_bullet(
      user.get_attackdelay(0).to_int64(),
      act.get_bullet(user, result.bullet),
      user.get_position(),
      result.toleft,
      target,
      fn() {  },
      fn(prev_target) { prev_target },
    )
    return
  }

  let mut primary_oid = result.first_oid
  if self.mobs.get_mob(primary_oid) is None {
    for oid, _ in result.damage_lines {
      if self.mobs.get_mob(oid) is Some(_) {
        primary_oid = oid
        break
      }
    }
  }
  guard self.mobs.get_mob(primary_oid) is Some(_) else { return }

  @bullet.spawn_bullet(
    user.get_attackdelay(0).to_int64(),
    act.get_bullet(user, result.bullet),
    user.get_position(),
    result.toleft,
    self.mobs.get_mob_head_position(primary_oid),
    fn() { self.apply_projectile_then_aoe_hit(attack_user, act, result) },
    fn(prev_target) {
      if self.mobs.get_mob(primary_oid) is Some(_) {
        self.mobs.get_mob_head_position(primary_oid)
      } else {
        prev_target
      }
    },
  )
}

///|
fn Combat::apply_projectile_then_aoe_hit(
  self : Combat,
  attack_user : @combat_proto.AttackUser,
  act : SpecialMove,
  result : AttackResult,
) -> Unit {
  for oid, vec in result.damage_lines {
    if self.mobs.get_mob(oid) is Some(_) {
      let numbers = self.place_numbers(oid, vec)
      let mut i = 0
      for number in numbers {
        self.apply_damage_effect({
          user: attack_user,
          number_params: number,
          damage: vec[i].0,
          toleft: result.toleft,
          target_oid: oid,
          sp_move: act,
          send_damage_to_server: true,
        })
        i += 1
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
fn miss_bullet_target_position(
  user : @character.Character,
  act : SpecialMove,
  result : AttackResult,
) -> @struct.Point[Int] {
  if get_range_semantics(act.get_id()) == RangeSemantics::ProjectileThenAoe {
    let origin = user.get_position()
    let toleft = result.toleft
    let cast_range = make_world_range(
      origin,
      toleft,
      user.stats.get_range(),
      1.0,
    )
    let x = if toleft { cast_range.left() } else { cast_range.right() }
    return @struct.Point::new(x, origin.y - 26)
  }
  let xshift = if result.toleft { -400 } else { 400 }
  user.get_position() + @struct.Point::new(xshift, -26)
}

///|
fn Combat::apply_damage_effect(self : Combat, effect : DamageEffect) -> Unit {
  guard self.mobs.get_mob(effect.target_oid) is Some(mob) else { return }
  if effect.send_damage_to_server {
    @game_server.send(@server_proto.MobDamageMessage::{
      oid: effect.target_oid,
      damage: effect.damage,
    })
  }
  let head_position = self.mobs.get_mob_head_position(effect.target_oid)
  let (t, amount, start_y) = effect.number_params
  @ui.show_number(t, amount, start_y, x=head_position.x)
  mob.apply_damage(effect.damage, effect.toleft)
  let act = effect.sp_move
  act.apply_hit_effects(effect.user, mob)
}

///|
/// Internal helper for attack type resolution.
fn resolve_attack_type(
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
  make_world_range(attack.origin, attack.toleft, attack.range, attack.hrange)
}

///|
fn make_world_range(
  origin : @struct.Point[Int],
  toleft : Bool,
  range : Rectangle[Int],
  hrange : Double,
) -> Rectangle[Int] {
  let left = (range.left().to_double() * hrange).to_int()
  let rel_range = Rectangle::from4(
    left,
    range.right(),
    range.top(),
    range.bottom(),
  )
  (if toleft { rel_range } else { rel_range.flip_x() }).shift(origin)
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
