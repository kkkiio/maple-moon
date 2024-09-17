typealias Movement = @physics.Movement

typealias CharBase = @character.CharBase

typealias CharStats = @character.CharStats

typealias CharLook = @character.CharLook

pub struct Player {
  char_base : CharBase
  stats : CharStats
  keys_down : Map[@KeyAction.Id, Bool]
  mut underwater : Bool
  mut last_move : Movement
  mut ladder : @map.Ladder?
  inventory : @inventory.Inventory
  buffs : Map[@buff.StatId, @buff.Buff]
  active_buffs : ActiveBuffs
  randomizer : @utils.Randomizer
  skill_book : @character.SkillBook
  cooldowns : Map[Int, Int]
}

pub typealias CharEntry = @login.CharEntry

/// Construct a player object from the given character entry.
pub fn Player::from_entry(
  entry : CharEntry,
  wid : Int,
  channel_id : Int
) -> Player! {
  let p = {
    char_base: CharBase::new(
      PlayerSub::default(),
      entry.id,
      CharLook::new!(entry.look),
      entry.stats.name,
    ),
    stats: CharStats::from_entry(entry.stats),
    keys_down: Map::new(),
    underwater: false,
    last_move: Movement::default(),
    ladder: None,
    inventory: @inventory.Inventory::new(),
    buffs: Map::new(),
    active_buffs: ActiveBuffs::new(),
    randomizer: @utils.Randomizer::default(),
    skill_book: @character.SkillBook::new(),
    cooldowns: Map::new(),
  }
  p.set_state(CharState::STAND)
  p.set_direction(true)
  p
}

pub fn get_position(self : Player) -> @struct.Point[Int] {
  self.char_base.get_position()
}

pub fn is_invincible(self : Player) -> Bool {
  if self.char_base.state == CharState::DIED {
    return true
  }
  if self.has_buff(@buff.StatId::DARKSIGHT) {
    return true
  }
  self.char_base.is_invincible()
}

pub fn has_buff(self : Player, stat : @buff.StatId) -> Bool {
  match self.buffs.get(stat) {
    Some(buff) => buff.value > 0
    None => false
  }
}

pub fn update(self : Player, physics : @physics.Physics) -> Int {
  match get_player_state(self.char_base.state) {
    Some(pst) => {
      pst.update(self)
      physics.move_object(self.get_phobj())
      let aniend = self.char_base.update(
        physics,
        self.char_base.get_stancespeed(),
      )
      if aniend && self.char_base.attacking {
        self.char_base.attacking = false
        nullstate.update_state(self)
      } else {
        pst.update_state(self)
      }
    }
    None => ()
  }
  let stancebyte = self.char_base.state.int_value() +
    (if self.char_base.facing_right { 0 } else { 1 })
  let newmove = Movement::from_physics_object(self.get_phobj(), stancebyte)
  let needupdate = self.last_move.hasmoved(newmove)
  if needupdate {
    new_move_player_packet(newmove).dispatch()
    self.last_move = newmove
  }
  self.char_base.get_layer()
}

// Respawn the player at the given position
pub fn respawn(
  self : Player,
  pos : @struct.Point[Int],
  underwater : Bool
) -> Unit {
  self.set_position(pos.x, pos.y)
  self.underwater = underwater
}

pub fn set_position(self : Player, x : Int, y : Int) -> Unit {
  self.char_base.set_position(@struct.Point::new(x, y))
}

pub fn draw(
  self : Player,
  layer : Int,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  if layer == self.char_base.get_layer() {
    self.char_base.draw(viewx, viewy, alpha)
  }
}

// Sends a Keyaction to the player's state, to apply forces, change the
// state and other behaviour.
pub fn send_action(self : Player, action : @KeyAction.Id, down : Bool) -> Unit {
  match get_player_state(self.char_base.state) {
    Some(pst) => pst.send_action(self, action, down)
    None => ()
  }
  self.keys_down[action] = down
}

struct PlayerStates {
  standing : PlayerStandState
  walking : PlayerWalkState
  falling : PlayerFallState
  lying : PlayerProneState
  climbing : PlayerClimbState
  sitting : PlayerSitState
  flying : PlayerFlyState
} derive(Default)

let g_player_states : PlayerStates = PlayerStates::default()

fn get_player_state(state : CharState) -> PlayerState? {
  match state {
    CharState::STAND => Some(g_player_states.standing)
    CharState::WALK => Some(g_player_states.walking)
    CharState::FALL => Some(g_player_states.falling)
    CharState::PRONE => Some(g_player_states.lying)
    CharState::LADDER | CharState::ROPE => Some(g_player_states.climbing)
    CharState::SIT => Some(g_player_states.sitting)
    CharState::SWIM => Some(g_player_states.flying)
    _ => None
  }
}

pub fn get_phobj(self : Player) -> @physics.PhysicsObject {
  self.char_base.get_phobj()
}

pub fn is_key_down(self : Player, key : @KeyAction.Id) -> Bool {
  self.keys_down[key].or(false)
}

pub fn set_direction(self : Player, flipped : Bool) -> Unit {
  if self.char_base.attacking.not() {
    self.char_base.set_direction(flipped)
  }
}

pub fn is_attacking(self : Player) -> Bool {
  self.char_base.attacking
}

// Set state ignore if attacking.
pub fn set_state(self : Player, st : CharState) -> Unit {
  if self.char_base.attacking.not() {
    self.char_base.set_state(st)
    match get_player_state(st) {
      Some(pst) => pst.initialize(self)
      None => ()
    }
  }
}

pub fn is_underwater(self : Player) -> Bool {
  self.underwater
}

pub fn get_flyforce(self : Player) -> Double {
  0.25
}

/// Returns the current jumping force, calculated from the total ES_JUMP stat.
pub fn get_jumpforce(self : Player) -> Double {
  1.0 + 3.5 * self.stats.get_total(@stat.Id::JUMP).to_double() / 100.0
}

pub fn is_climbing(self : Player) -> Bool {
  self.char_base.is_climbing()
}

pub fn get_climbforce(self : Player) -> Double {
  self.stats.get_total(@stat.Id::SPEED).to_double() / 100.0
}

pub fn getflip(self : Player) -> Bool {
  self.char_base.getflip()
}

/// Returns the current walking force, calculated from the total ES_SPEED stat.
pub fn get_walkforce(self : Player) -> Double {
  0.05 + 0.11 * self.stats.get_total(@stat.Id::SPEED).to_double() / 100.0
}

let nullstate : PlayerNullState = PlayerNullState::default()

struct PlayerSub {} derive(Default)

fn get_integer_attackspeed(self : PlayerSub) -> Int {
  0
  // let weapon_id = self.look.get_equips().get_weapon();

  // if weapon_id <= 0 {
  //   return 0;
  // }

  // let weapon = WeaponData::get(weapon_id);

  // let base_speed = self.stats.get_attackspeed();
  // let weapon_speed = weapon.get_speed();

  // base_speed + weapon_speed
}

pub fn get_stats(self : Player) -> CharStats {
  self.stats
}

/// Recalculates the total stats from base stats, inventories and skills.
pub fn recalc_stats(self : Player, equipchanged : Bool) -> Unit! {
  let weapontype = self.char_base.get_weapontype!()
  self.stats.set_weapontype(weapontype)
  self.stats.init_totalstats()
  if equipchanged {
    self.inventory.recalc_stats(weapontype)
  }
  for stat in @stat.all_stats {
    let inventory_total = self.inventory.get_stat(stat)
    self.stats.add_value(stat, inventory_total)
  }
  // TODO: Implement passive skills
  for buff in self.buffs.values() {
    self.active_buffs.apply_buff(self.stats, buff.stat, buff.value)
  }
  self.stats.close_totalstats()
  // TODO: Update stats info ui
}

fn new_move_player_packet(movement : Movement) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.OutPacketOpcode::MOVE_PLAYER)
  packet.skip(9)
  packet.write_byte((1).to_byte())
  write_movement(packet, movement)
  packet
}

fn write_movement(out : @net.OutPacket, movement : @physics.Movement) -> Unit {
  out.write_byte(movement.command.to_byte())
  out.write_short(movement.xpos)
  out.write_short(movement.ypos)
  out.write_short(movement.lastx)
  out.write_short(movement.lasty)
  out.write_short(movement.fh)
  out.write_byte(movement.newstate.to_byte())
  out.write_short(movement.duration)
}

pub fn change_look(self : Player, stat : @MapleStat.Id, id : Int) -> Unit {
  self.char_base.change_look(stat, id)
}

pub fn get_name(self : Player) -> String {
  self.char_base.get_name()
}

pub fn get_ladder(self : Player) -> @map.Ladder? {
  self.ladder
}

pub fn set_ladder(self : Player, ladder : @map.Ladder?) -> Unit {
  self.ladder = ladder
  match ladder {
    Some(ladder) => {
      self.get_phobj().set_x(ladder.get_x().to_double())
      self.get_phobj().moving_object.hspeed = 0.0
      self.get_phobj().moving_object.vspeed = 0.0
      self.get_phobj().fhlayer = 7
      self.set_state(
        if ladder.is_ladder() {
          CharState::LADDER
        } else {
          CharState::ROPE
        },
      )
    }
    None => ()
  }
}

pub fn damage(
  self : Player,
  attack : @combat.MobAttack
) -> @combat.MobAttackResult {
  let damage = self.stats.calculate_damage(attack.watk)
  // TODO: Show damage
  // self.char_base.show_damage(damage)
  let fromleft = attack.origin.x > self.get_phobj().get_x()
  let missed = damage <= 0
  let immovable = self.get_ladder().is_empty().not() ||
    self.char_base.state == CharState::DIED
  let knockback = missed.not() && immovable.not()
  if knockback && self.randomizer.above(self.stats.get_stance()) {
    self.get_phobj().moving_object.hspeed = if fromleft { -1.5 } else { 1.5 }
    self.get_phobj().vforce -= 3.5
  }
  let direction = if fromleft { 0 } else { 1 }
  @combat.MobAttackResult::new(attack, damage, direction)
}

pub fn get_skills(self : Player) -> @character.SkillBook {
  self.skill_book
}

pub fn prepare_attack(self : Player, skill : Bool) -> @combat.Attack! {
  let (degenerate, attacktype) = if self.char_base.state == CharState::PRONE {
    (true, @combat.AttackType::CLOSE)
  } else {
    let weapontype = self.char_base.get_weapontype!()
    match weapontype {
      @Weapon.Type::BOW
      | @Weapon.Type::CROSSBOW | @Weapon.Type::CLAW | @Weapon.Type::GUN => {
        let degenerate = self.inventory.has_projectile().not()
        (
          degenerate,
          if degenerate {
            @combat.AttackType::CLOSE
          } else {
            @combat.AttackType::RANGED
          },
        )
      }
      @Weapon.Type::WAND | @Weapon.Type::STAFF => {
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
  let mut mindamage = self.stats.get_mindamage().to_double()
  let mut maxdamage = self.stats.get_maxdamage().to_double()
  if degenerate {
    mindamage /= 10
    maxdamage /= 10
  }
  let critical = self.stats.get_critical()
  let ignoredef = self.stats.get_ignoredef()
  let accuracy = self.stats.get_total(@stat.Id::ACC)
  let playerlevel = self.stats.get_stat(@MapleStat.Id::LEVEL)
  let range = self.stats.get_range()
  let bullet = self.inventory.get_bulletid()
  let origin = self.get_position()
  let toleft = self.char_base.facing_right.not()
  let speed = self.get_integer_attackspeed!()
  let d = @combat.Attack::default()
  {
    ..d,
    t,
    mindamage,
    maxdamage,
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

fn get_integer_attackspeed(self : Player) -> Int! {
  let weapon_id = self.char_base.look.get_equips().get_weapon()
  if weapon_id <= 0 {
    return 0
  }
  let weapon = @Weapon.WeaponData::get!(weapon_id)
  let base_speed = self.stats.get_attackspeed()
  let weapon_speed = weapon.get_speed()
  base_speed + weapon_speed
}

pub fn can_attack(self : Player) -> Bool {
  self.char_base.attacking.not() &&
  self.char_base.is_climbing().not() &&
  self.char_base.is_sitting().not() &&
  self.char_base.look.get_equips().has_weapon()
}

pub fn can_use(
  self : Player,
  move : @combat.SpecialMove
) -> @combat.ForbidReason! {
  if move.is_skill() && self.char_base.state == CharState::PRONE {
    return @combat.ForbidReason::FBR_OTHER
  }
  if move.is_attack() &&
    (
      self.char_base.state == CharState::LADDER ||
      self.char_base.state == CharState::ROPE
    ) {
    return @combat.ForbidReason::FBR_OTHER
  }
  if self.has_cooldown(move.get_id()) {
    return @combat.ForbidReason::FBR_COOLDOWN
  }
  let level = self.skill_book.get_level(move.get_id())
  let weapontype = self.char_base.get_weapontype!()
  let job = self.stats.get_job()
  let hp = self.stats.get_stat(@MapleStat.Id::HP)
  let mp = self.stats.get_stat(@MapleStat.Id::MP)
  let bullets = self.inventory.get_bulletcount()
  move.can_use(level, weapontype, job, hp, mp, bullets)
}

fn has_cooldown(self : Player, skill_id : Int) -> Bool {
  self.cooldowns[skill_id].or(0) > 0
}

pub fn set_afterimage(self : Player, skill_id : Int) -> Unit {
  self.char_base.set_afterimage(skill_id)
}

pub fn get_oid(self : Player) -> Int {
  self.char_base.get_oid()
}

pub fn get_level(self : Player) -> Int {
  self.stats.get_stat(@MapleStat.Id::LEVEL)
}

pub fn get_skilllevel(self : Player, skill_id : Int) -> Int {
  self.skill_book.get_level(skill_id)
}

pub fn is_twohanded(self : Player) -> Bool {
  self.char_base.is_twohanded()
}

pub fn get_attackdelay(self : Player, no : Int) -> Int {
  self.char_base.get_attackdelay(no)
}

pub fn rush(self : Player, targetx : Double) -> Unit {
  if self.get_phobj().onground {
    let delay = self.get_attackdelay(1)
    self.get_phobj().moving_object.movexuntil(targetx, delay)
    self.get_phobj().set_flag(@physics.PhysicsObjectFlag::TURN_AT_EDGES)
  }
}

pub fn get_look(self : Player) -> @character.CharLook {
  self.char_base.look
}

pub fn get_afterimage(self : Player) -> @char_look.Afterimage {
  self.char_base.after_image
}

pub fn get_weapontype(self : Player) -> @Weapon.Type! {
  self.char_base.get_weapontype!()
}

pub fn regular_attack(self : Player, degenerate : Bool) -> Unit! {
  self.char_base.regular_attack!(degenerate)
}
