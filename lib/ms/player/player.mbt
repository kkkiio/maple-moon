typealias Movement = @physics.Movement

typealias CharStats = @char_stats.CharStats

pub struct Player {
  char_base : @character.CharBase
  stats : CharStats
  keys_down : Map[@action.Id, Bool]
  mut underwater : Bool
  mut last_move : Movement
  mut ladder : @map.Ladder?
  inventory : Inventory
  buffs : Map[@buff.StatId, @buff.Buff]
  active_buffs : ActiveBuffs
  randomizer : @utils.Randomizer
  skill_book : @character.SkillBook
}

pub trait Inventory {
  recalc_stats(Self, @weapon.Type) -> Unit
  get_stat(Self, @stat.Id) -> Int
  has_projectile(Self) -> Bool
  get_bulletid(Self) -> Int
  get_bulletcount(Self) -> Int
}

/// Construct a player object from the given character entry.
pub fn Player::from_entry(
  entry : @character.CharEntry,
  inventory : Inventory,
  damage_number_set : @combat_ui.DamageNumberSet,
  sp_stat_id : @char_stats.StatId
) -> Player! {
  let p = {
    char_base: @character.CharBase::new(
      entry.id,
      @character.CharLook::new!(entry.look),
      entry.stats.name,
      damage_number_set,
    ),
    stats: CharStats::from_entry(entry.stats, sp_stat_id),
    keys_down: Map::new(),
    underwater: false,
    last_move: Movement::default(),
    ladder: None,
    inventory,
    buffs: Map::new(),
    active_buffs: ActiveBuffs::new(),
    randomizer: @utils.Randomizer::default(),
    skill_book: @character.SkillBook::new(),
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

pub fn update(
  self : Player,
  physics : @physics.Physics,
  map_info : @map.MapInfo
) -> Int {
  match get_player_state(self.char_base.state) {
    Some(pst) => {
      pst.update(self)
      physics.move_object(self.get_phobj())

      // Check for ladder interaction
      if self.keys_down[@action.Id::UP].or(false) {
        self.check_ladders(map_info, true)
      } else if self.keys_down[@action.Id::DOWN].or(false) {
        self.check_ladders(map_info, false)
      }
      let aniend = self.char_base.update(
        self.char_base.get_stancespeed(self.get_integer_attackspeed()),
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
pub fn send_action(self : Player, action : @action.Id, down : Bool) -> Unit {
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

pub fn is_key_down(self : Player, key : @action.Id) -> Bool {
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

pub fn is_facing_right(self : Player) -> Bool {
  self.char_base.is_facing_right()
}

/// Returns the current walking force, calculated from the total ES_SPEED stat.
pub fn get_walkforce(self : Player) -> Double {
  0.05 + 0.11 * self.stats.get_total(@stat.Id::SPEED).to_double() / 100.0
}

let nullstate : PlayerNullState = PlayerNullState::default()

pub fn get_stats(self : Player) -> CharStats {
  self.stats
}

/// Recalculates the total stats from base stats, inventories and skills.
pub fn recalc_stats(self : Player, equip_changed : Bool) -> Unit {
  let weapontype = self.char_base.get_weapontype()
  self.stats.set_weapontype(weapontype)
  self.stats.init_totalstats()
  if equip_changed {
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

pub fn change_look(self : Player, stat : @maple_stat.Id, id : Int) -> Unit {
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
  self.char_base.show_damage(damage)
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

pub fn get_integer_attackspeed(self : Player) -> Int {
  let weapon_id = self.char_base.look.get_equips().get_weapon()
  if weapon_id <= 0 {
    return 0
  }
  let weapon = @weapon.WeaponData::get?(weapon_id).unwrap() // TODO: Handle error
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

pub fn set_afterimage(self : Player, skill_id : Int) -> Unit {
  self.char_base.set_afterimage(skill_id)
}

pub fn get_oid(self : Player) -> Int {
  self.char_base.get_oid()
}

pub fn get_skilllevel(self : Player, skill_id : Int) -> Int {
  self.skill_book.get_level(skill_id)
}

pub fn is_twohanded(self : Player) -> Bool {
  self.char_base.is_twohanded()
}

pub fn get_attackdelay(self : Player, no : Int) -> Int {
  self.char_base.get_attackdelay(no, self.get_integer_attackspeed())
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

pub fn get_weapontype(self : Player) -> @weapon.Type {
  self.char_base.get_weapontype()
}

pub fn regular_attack(self : Player, degenerate : Bool) -> Unit! {
  self.char_base.regular_attack!(degenerate)
}

pub fn change_level(self : Player, level : Int) -> Unit {
  let oldlevel = self.stats.get_level()
  if level > oldlevel {
    self.char_base.show_effect_id(@character.CharEffectId::LEVEL_UP)
  }
  self.stats.set_level(level)
}

pub fn check_ladders(self : Player, map_info : @map.MapInfo, up : Bool) -> Unit {
  if self.is_climbing() || self.is_attacking() {
    return
  }
  let ladder = map_info.find_ladder(self.get_position(), up)
  self.set_ladder(ladder)
}

pub fn change_skill(
  self : Player,
  skill_id : Int,
  skill_level : Int,
  masterlevel : Int,
  expiration : Int
) -> Unit {
  let old_level = self.skill_book.get_level(skill_id)
  self.skill_book.set_skill(skill_id, skill_level, masterlevel, expiration)
  if old_level != skill_level {
    self.recalc_stats(false)
  }
}

pub fn show_attack_effect(
  self : Player,
  toshow : @graphics.Animation,
  z : Int
) -> Unit {
  self.char_base.show_attack_effect(toshow, z, self.get_integer_attackspeed())
}

pub fn show_iron_body(self : Player) -> Unit {
  self.char_base.show_iron_body()
}

pub fn attack_by_action(self : Player, action : String) -> Unit {
  self.char_base.attack_by_action(action)
}

pub fn attack_by_stance(self : Player, stance : @char_look.StanceId) -> Unit {
  self.char_base.attack_by_stance(stance)
}

pub fn change_job(self : Player, jobid : Int) -> Unit {
  self.char_base.show_effect_id(@character.CharEffectId::JOB_CHANGE)
  self.stats.change_job(jobid)
}
