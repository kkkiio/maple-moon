///|
typealias @physics.Movement

///|
typealias @char_stats.CharStats

///|
pub(open) trait SkillBook {
  get_level(Self, Int) -> Int
  set_skill(Self, Int, Int, Int, Int) -> Unit
}

///|
pub(all) struct Player {
  string_loader : @resource.SyncLoader
  character : @character.CharBase
  stats : CharStats
  keys_down : Map[@keyboard.BasicActionId, Bool]
  mut underwater : Bool
  mut last_move : Movement
  mut ladder : @map.Ladder?
  inventory : &Inventory
  buffs : Map[@buff.StatId, @buff.Buff]
  active_buffs : ActiveBuffs
  randomizer : @utils.Randomizer
  load_skill_book : (@job.Job) -> @utils.Future[&SkillBook]
  mut skill_book : &SkillBook
  mut changing_job : @utils.Future[(@job.Job, &SkillBook)]?
}

///|
pub(open) trait Inventory {
  recalc_stats(Self, @weapon.Type) -> Unit
  get_stat(Self, @maple_stat.EquipStatId) -> Int
  has_projectile(Self) -> Bool
  get_bulletid(Self) -> Int
  get_bulletcount(Self) -> Int
}

///|
pub fn Player::load(
  entry : @character.CharEntry,
  inventory : &Inventory,
  look : @char_look.CharLook,
  damage_number_set : @ui.NumberSet,
  load_skill_book : (@job.Job) -> @utils.Future[&SkillBook],
  new_char_stats : (@job.Job) -> CharStats,
  network : @net.Network,
  string_loader : @resource.SyncLoader,
  io_service : @io_task.IOService
) -> @utils.Future[Player] {
  @job.Job::load(
    string_loader,
    io_service,
    id=entry.stats.stats.get(@maple_stat.Id::JOB).or(0),
  )
  .bind(fn(job) {
    load_skill_book(job).map(fn(skill_book) { (job, skill_book) })
  })
  .map(fn(it) {
    let (job, skill_book) = it
    Player::new(
      entry,
      inventory,
      skill_book,
      look,
      damage_number_set,
      network,
      load_skill_book,
      new_char_stats(job),
      string_loader,
    )
  })
}

///| Construct a player object from the given character entry.
pub fn Player::new(
  entry : @character.CharEntry,
  inventory : &Inventory,
  skill_book : &SkillBook,
  look : @char_look.CharLook,
  damage_number_set : @ui.NumberSet,
  network : @net.Network,
  load_skill_book : (@job.Job) -> @utils.Future[&SkillBook],
  stats : CharStats,
  string_loader : @resource.SyncLoader
) -> Player {
  let character = @character.Character::new(
    entry.id,
    look,
    entry.stats.name,
    damage_number_set,
    get_skilllevel=fn(skill_id) { skill_book.get_level(skill_id) },
    stats,
    get_integer_attackspeed=fn() { get_integer_attackspeed(look, stats) },
  )
  let p = {
    string_loader,
    character,
    stats,
    keys_down: Map::new(),
    underwater: false,
    last_move: Movement::default(),
    ladder: None,
    inventory,
    buffs: Map::new(),
    active_buffs: ActiveBuffs::new(),
    randomizer: @utils.Randomizer::new(),
    skill_book,
    changing_job: None,
    load_skill_book,
  }
  p.set_state(CharState::STAND)
  p.set_direction(true)
  stats.watch_stat_changes(@maple_stat.Id::HP, fn(_old, hp) {
    if hp <= 0 {
      p.set_state(@character.CharState::DIED)
      let died = true
      let target_id = 0
      network.send_message(
        { died, target_id, target_p: "sp", use_wheel: false },
        log_level=@log.Level::INFO,
      )
    }
    IterContinue
  })
  stats.watch_stat_changes(@maple_stat.Id::HP, fn(old_hp, new_hp) {
    if new_hp > old_hp {
      p.character.show_heal_number(new_hp - old_hp)
    }
    IterContinue
  })
  p
}

///|
pub fn is_invincible(self : Player) -> Bool {
  if self.character.state == CharState::DIED {
    return true
  }
  if self.has_buff(@buff.StatId::DARKSIGHT) {
    return true
  }
  self.character.is_invincible()
}

///|
pub fn has_buff(self : Player, stat : @buff.StatId) -> Bool {
  match self.buffs.get(stat) {
    Some(buff) => buff.value > 0
    None => false
  }
}

///|
pub fn update(
  self : Player,
  physics : @physics.Physics,
  map_info : @map.MapInfo
) -> Int {
  match self.changing_job.bind(fn(it) { it.poll() }) {
    Some(it) => {
      let (job, skill_book) = it
      self.stats.change_job(job)
      self.skill_book = skill_book
      self.changing_job = None
    }
    None => ()
  }
  match get_player_state(self.character.state) {
    Some(pst) => {
      pst.update(self)
      physics.move_object(self.character.get_phobj())

      // Check for ladder interaction
      if self.keys_down.get(@keyboard.BasicActionId::UP).or(false) {
        self.check_ladders(map_info, true)
      } else if self.keys_down.get(@keyboard.BasicActionId::DOWN).or(false) {
        self.check_ladders(map_info, false)
      }
      let aniend = self.character.update(
        self.character.get_stancespeed(
          (self.character.get_integer_attackspeed)(),
        ),
      )
      if aniend && self.character.attacking {
        self.character.attacking = false
        nullstate.update_state(self)
      } else {
        pst.update_state(self)
      }
    }
    None => ()
  }
  let stancebyte = self.character.state.stance_value(
    facing_right=self.character.facing_right,
  )
  let newmove = Movement::from_physics_object(
    self.character.get_phobj(),
    stancebyte,
  )
  let needupdate = self.last_move.hasmoved(newmove)
  if needupdate {
    new_move_player_packet(newmove).dispatch()
    self.last_move = newmove
  }
  self.character.get_layer()
}

// Respawn the player at the given position
///|
pub fn respawn(
  self : Player,
  pos : @struct.Point[Int],
  underwater : Bool
) -> Unit {
  self.set_position(pos.x, pos.y)
  self.underwater = underwater
}

///|
pub fn set_position(self : Player, x : Int, y : Int) -> Unit {
  self.character.set_position(@struct.Point::new(x, y))
}

///|
pub fn draw(
  self : Player,
  layer : Int,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  if layer == self.character.get_layer() {
    self.character.draw(viewx, viewy, alpha)
  }
}

// Sends a Keyaction to the player's state, to apply forces, change the
// state and other behaviour.
///|
pub fn send_action(
  self : Player,
  action : @keyboard.BasicActionId,
  down : Bool
) -> Unit {
  match get_player_state(self.character.state) {
    Some(pst) => pst.send_action(self, action, down)
    None => ()
  }
  self.keys_down[action] = down
}

///|
struct PlayerStates {
  standing : PlayerStandState
  walking : PlayerWalkState
  falling : PlayerFallState
  lying : PlayerProneState
  climbing : PlayerClimbState
  sitting : PlayerSitState
  flying : PlayerFlyState
} derive(Default)

///|
let g_player_states : PlayerStates = PlayerStates::default()

///|
fn get_player_state(state : CharState) -> &PlayerState? {
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

///|
pub fn is_key_down(self : Player, key : @keyboard.BasicActionId) -> Bool {
  self.keys_down.get(key).or(false)
}

///|
pub fn set_direction(self : Player, flipped : Bool) -> Unit {
  if not(self.character.attacking) {
    self.character.set_direction(flipped)
  }
}

///|
pub fn is_attacking(self : Player) -> Bool {
  self.character.attacking
}

// Set state ignore if attacking.
///|
pub fn set_state(self : Player, st : CharState) -> Unit {
  if not(self.character.attacking) {
    self.character.set_state(st)
    match get_player_state(st) {
      Some(pst) => pst.initialize(self)
      None => ()
    }
  }
}

///|
pub fn is_underwater(self : Player) -> Bool {
  self.underwater
}

///|
pub fn get_flyforce(self : Player) -> Double {
  0.25
}

///| Returns the current jumping force, calculated from the total ES_JUMP stat.
pub fn get_jumpforce(self : Player) -> Double {
  1.0 +
  3.5 * self.stats.get_total(@maple_stat.EquipStatId::JUMP).to_double() / 100.0
}

///|
pub fn get_climbforce(self : Player) -> Double {
  self.stats.get_total(@maple_stat.EquipStatId::SPEED).to_double() / 100.0
}

///| Returns the current walking force, calculated from the total ES_SPEED stat.
pub fn get_walkforce(self : Player) -> Double {
  0.05 +
  0.11 *
  self.stats.get_total(@maple_stat.EquipStatId::SPEED).to_double() /
  100.0
}

///|
let nullstate : PlayerNullState = PlayerNullState::default()

///|
pub fn get_stats(self : Player) -> CharStats {
  self.stats
}

///| Recalculates the total stats from base stats, inventories and skills.
pub fn recalc_stats(self : Player, equip_changed : Bool) -> Unit {
  let weapontype = self.character.get_weapontype()
  self.stats.init_totalstats()
  if equip_changed {
    self.inventory.recalc_stats(weapontype)
  }
  for stat in @maple_stat.all_equip_stats {
    let inventory_total = self.inventory.get_stat(stat)
    self.stats.add_value(stat, inventory_total)
  }
  // TODO: Implement passive skills
  for buff in self.buffs.values() {
    self.active_buffs.apply_buff(self.stats, buff.stat, buff.value)
  }
  self.stats.close_totalstats()
}

///|
fn new_move_player_packet(movement : Movement) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.ClientOpcode::MOVE_PLAYER)
  packet.skip(9)
  packet.write_byte((1).to_byte())
  write_movement(packet, movement)
  packet
}

///|
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

///|
pub fn get_ladder(self : Player) -> @map.Ladder? {
  self.ladder
}

///|
pub fn set_ladder(self : Player, ladder : @map.Ladder?) -> Unit {
  self.ladder = ladder
  match ladder {
    Some(ladder) => {
      self.character.get_phobj().set_x(ladder.get_x().to_double())
      self.character.get_phobj().moving_object.hspeed = 0.0
      self.character.get_phobj().moving_object.vspeed = 0.0
      self.character.get_phobj().fhlayer = 7
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

///|
pub fn damage(
  self : Player,
  attack : @combat.MobAttack
) -> @combat.MobAttackResult {
  let damage = self.stats.calculate_damage(attack.watk)
  self.character.show_damage(damage)
  let fromleft = attack.origin.x > self.character.get_phobj().get_x()
  let missed = damage <= 0
  let immovable = not(self.get_ladder().is_empty()) ||
    self.character.state == CharState::DIED
  let knockback = not(missed) && not(immovable)
  if knockback && self.randomizer.above(self.stats.get_stance()) {
    self.character.get_phobj().moving_object.hspeed = if fromleft {
      -1.5
    } else {
      1.5
    }
    self.character.get_phobj().vforce -= 3.5
  }
  let direction = if fromleft { 0 } else { 1 }
  @combat.MobAttackResult::new(attack, damage, direction)
}

///|
pub fn get_skills(self : Player) -> &SkillBook {
  self.skill_book
}

///|
pub fn get_integer_attackspeed(
  look : @char_look.CharLook,
  stats : CharStats
) -> Int {
  guard look.get_equips().get_weapon() is Some(weapon) else { return 0 }
  let base_speed = stats.get_attackspeed()
  let weapon_speed = weapon.get_speed()
  base_speed + weapon_speed
}

///|
pub fn can_attack(self : Player) -> Bool {
  not(self.character.attacking) &&
  not(self.character.is_climbing()) &&
  not(self.character.is_sitting()) &&
  self.character.look.get_equips().has_weapon()
}

///|
pub fn rush(self : Player, targetx : Double) -> Unit {
  if self.character.get_phobj().onground {
    let delay = self.character.get_attackdelay(1)
    self.character.get_phobj().moving_object.movexuntil(targetx, delay)
    self.character
    .get_phobj()
    .set_flag(@physics.PhysicsObjectFlag::TURN_AT_EDGES)
  }
}

///|
pub fn check_ladders(self : Player, map_info : @map.MapInfo, up : Bool) -> Unit {
  if self.character.is_climbing() || self.character.attacking {
    return
  }
  let ladder = map_info.find_ladder(self.character.get_position(), up)
  self.set_ladder(ladder)
}

///|
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

///|
pub fn show_iron_body(self : Player) -> Unit {
  self.character.show_iron_body()
}

///|
pub fn attack_by_action(self : Player, action : String) -> Unit {
  self.character.attack_by_action(action)
}

///|
pub fn attack_by_stance(self : Player, stance : @types.StanceId) -> Unit {
  self.character.attack_by_stance(stance)
}

///|
pub fn change_job(
  self : Player,
  job_id : Int,
  io_service : @io_task.IOService
) -> Unit {
  self.character.show_effect_id(@character.CharEffectId::JOB_CHANGE)
  self.changing_job = @job.Job::load(self.string_loader, io_service, id=job_id).bind(fn(
        job
      ) {
        (self.load_skill_book)(job).map(fn(skill_book) { (job, skill_book) })
      },
    )
    |> Some
}

///|
pub(all) struct ChangeMapMessage {
  died : Bool
  target_id : Int
  target_p : String
  use_wheel : Bool
} derive(Show)

///|
pub impl @net.OutMessage for ChangeMapMessage with pack(self) -> @net.OutPacket {
  let p = @net.OutPacket::new(@net.ClientOpcode::CHANGE_MAP)
  p
  ..write_byte(self.died.to_int().to_byte())
  ..write_int(self.target_id)
  ..write_string(self.target_p)
  ..skip(1)
  ..write_short(if self.use_wheel { 1 } else { 0 })
  p
}
