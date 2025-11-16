///|
using @physics {type Movement}

///|
using @char_stats {type CharStats}

///|
pub(open) trait SkillBook {
  get_level(Self, Int) -> Int
  set_skill(Self, Int, Int, Int, Int) -> Unit
}

///|
pub(all) struct Player {
  entity : @entity.Entity
  character : @character.CharBase
  stats : CharStats
  mut underwater : Bool
  mut last_move : Movement
  mut ladder : @map.Ladder?
  // inventory : &Inventory
  buffs : Map[@buff.StatId, @buff.Buff]
  active_buffs : ActiveBuffs
  randomizer : @utils.Randomizer
  // load_skill_book : async (@job.Job) -> &SkillBook raise
  // mut skill_book : &SkillBook
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
pub async fn Player::load(
  entity : @entity.Entity,
  entry : @character.CharEntry,
  // inventory : &Inventory,
  look : @char_look.CharLook,
  damage_number_set : @ui.NumberSet,
  // load_skill_book : async (@job.Job) -> &SkillBook raise,
  new_char_stats : (@job.Job) -> CharStats,
) -> Player {
  let job = @job.Job::load(
    id=entry.stats.stats.get(@maple_stat.Id::JOB).unwrap_or(0),
  )
  // let skill_book = load_skill_book(job)
  Player::new(
    entity,
    entry.id,
    entry.stats.name,
    // inventory,
    // skill_book,
    look,
    damage_number_set,
    // load_skill_book,
    new_char_stats(job),
  )
}

///|
/// Construct a player object from the given character entry.
pub fn Player::new(
  entity : @entity.Entity,
  id : Int,
  name : String,
  // inventory : &Inventory,
  // skill_book : &SkillBook,
  look : @char_look.CharLook,
  damage_number_set : @ui.NumberSet,
  // load_skill_book : async (@job.Job) -> &SkillBook raise,
  stats : CharStats,
) -> Player {
  let character = @character.Character::new(
    entity,
    id,
    look,
    name,
    damage_number_set,
    // get_skilllevel=fn(skill_id) { skill_book.get_level(skill_id) },
    get_skilllevel=fn(_) { 0 }, // TODO: implement
    stats,
  )
  let p : Player = {
    entity,
    character,
    stats,
    underwater: false,
    last_move: Movement::default(),
    ladder: None,
    // inventory,
    buffs: Map::new(),
    active_buffs: ActiveBuffs::new(),
    randomizer: @utils.Randomizer::new(),
    // skill_book,
    // load_skill_book,
  }
  p.set_state(CharState::STAND)
  p.set_facing_right(true)
  stats.watch_stat_changes(@maple_stat.Id::HP, fn(_old, hp) {
    if hp <= 0 {
      p.set_state(@character.CharState::DIED)
      let died = true
      let target_id = 0
      // network.send_message(
      //   { died, target_id, target_p: "sp", use_wheel: false },
      //   log_level=@log.Level::INFO,
      // )
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
pub fn Player::is_invincible(self : Player) -> Bool {
  if self.character.state == CharState::DIED {
    return true
  }
  if self.has_buff(@buff.StatId::DARKSIGHT) {
    return true
  }
  self.character.is_invincible()
}

///|
pub fn Player::has_buff(self : Player, stat : @buff.StatId) -> Bool {
  match self.buffs.get(stat) {
    Some(buff) => buff.value > 0
    None => false
  }
}

///|
pub fn Player::update(
  self : Player,
  physics : @physics.Physics,
  map_info : @map.MapInfo,
) -> Unit {
  match get_player_state(self.character.state) {
    Some(_) => {
      let player = self
      match self.character.state {
        STAND =>
          if not(player.character.get_phobj().enablejd) {
            player.character
            .get_phobj()
            .set_flag(@physics.PhysicsObjectFlag::CHECK_BELOW)
          }
        WALK => {
          if not(player.is_attacking()) && haswalkinput(player) {
            let hforce = if player.character.is_facing_right() {
              player.get_walkforce()
            } else {
              -player.get_walkforce()
            }
            player.character
            .get_phobj()
            .set_hforce(player.character.get_phobj().hforce + hforce)
          }
          if not(player.character.get_phobj().enablejd) {
            player.character
            .get_phobj()
            .set_flag(@physics.PhysicsObjectFlag::CHECK_BELOW)
          }
        }
        FALL => {
          let hspeed = player.character.get_phobj().moving_object.hspeed
          if player.is_key_down(@keyboard.BasicActionId::LEFT) && hspeed > 0.0 {
            player.character.get_phobj().moving_object.set_hspeed(
              hspeed - 0.025,
            )
            if player.character.get_phobj().moving_object.hspeed < 0.0 {
              player.character.get_phobj().moving_object.set_hspeed(0.0)
            }
          } else if player.is_key_down(@keyboard.BasicActionId::RIGHT) &&
            hspeed < 0.0 {
            player.character.get_phobj().moving_object.set_hspeed(
              hspeed + 0.025,
            )
            if player.character.get_phobj().moving_object.hspeed > 0.0 {
              player.character.get_phobj().moving_object.set_hspeed(0.0)
            }
          }
        }
        PRONE =>
          if not(player.character.get_phobj().enablejd) {
            player.character
            .get_phobj()
            .set_flag(@physics.PhysicsObjectFlag::CHECK_BELOW)
          }
        SWIM => {
          if player.is_attacking() {
            return
          }
          if player.is_key_down(@keyboard.BasicActionId::LEFT) {
            player.character.get_phobj().set_hforce(-player.get_flyforce())
          } else if player.is_key_down(@keyboard.BasicActionId::RIGHT) {
            player.character.get_phobj().set_hforce(player.get_flyforce())
          }
          if player.is_key_down(@keyboard.BasicActionId::UP) {
            player.character.get_phobj().set_vforce(-player.get_flyforce())
          } else if player.is_key_down(@keyboard.BasicActionId::DOWN) {
            player.character.get_phobj().set_vforce(player.get_flyforce())
          }
        }
        LADDER | ROPE =>
          if player.is_key_down(@keyboard.BasicActionId::UP) {
            player.character.get_phobj().set_vspeed(-player.get_climbforce())
          } else if player.is_key_down(@keyboard.BasicActionId::DOWN) {
            player.character.get_phobj().set_vspeed(player.get_climbforce())
          } else {
            player.character.get_phobj().set_vspeed(0.0)
          }
        _ => ()
      }
      physics.move_object(self.character.get_phobj())

      // Check for ladder interaction
      if @inputs.is_pressed(@inputs.Code::ArrowUp) {
        self.check_ladders(map_info, true)
      } else if @inputs.is_pressed(@inputs.Code::ArrowDown) {
        self.check_ladders(map_info, false)
      }
      let aniend = self.character.update(
        self.character.get_stancespeed(
          @character.get_integer_attackspeed(
            self.character.get_look(),
            self.stats,
          ),
        ),
      )
      if aniend && self.character.attacking {
        self.character.attacking = false
        let state : CharState = if player.character.get_phobj().onground {
          if player.is_key_down(@keyboard.BasicActionId::LEFT) {
            player.set_facing_right(false)
            CharState::WALK
          } else if player.is_key_down(@keyboard.BasicActionId::RIGHT) {
            player.set_facing_right(true)
            CharState::WALK
          } else if player.is_key_down(@keyboard.BasicActionId::DOWN) {
            CharState::PRONE
          } else {
            CharState::STAND
          }
        } else {
          let ladder = player.get_ladder()
          match ladder {
            Some(l) =>
              if l.is_ladder() {
                CharState::LADDER
              } else {
                CharState::ROPE
              }
            None => CharState::FALL
          }
        }
        player.character.get_phobj().clear_flags()
        player.character.set_state(state)
      } else {
        match self.character.state {
          STAND =>
            if not(player.character.get_phobj().onground) {
              player.set_state(CharState::FALL)
            }
          WALK =>
            if player.character.get_phobj().onground {
              if not(haswalkinput(player)) ||
                player.character.get_phobj().moving_object.hspeed == 0.0 {
                player.set_state(CharState::STAND)
              }
            } else {
              player.set_state(CharState::FALL)
            }
          FALL =>
            if player.character.get_phobj().onground {
              if player.is_key_down(@keyboard.BasicActionId::LEFT) {
                player.set_facing_right(false)
                player.set_state(CharState::WALK)
              } else if player.is_key_down(@keyboard.BasicActionId::RIGHT) {
                player.set_facing_right(true)
                player.set_state(CharState::WALK)
              } else if player.is_key_down(@keyboard.BasicActionId::DOWN) {
                player.set_state(CharState::PRONE)
              } else {
                player.set_state(CharState::STAND)
              }
            } else if player.is_underwater() {
              player.set_state(CharState::SWIM)
            }
          SWIM =>
            if player.character.get_phobj().onground && player.is_underwater() {
              let state = if player.is_key_down(@keyboard.BasicActionId::LEFT) {
                player.set_facing_right(false)
                CharState::WALK
              } else if player.is_key_down(@keyboard.BasicActionId::RIGHT) {
                player.set_facing_right(true)
                CharState::WALK
              } else if player.is_key_down(@keyboard.BasicActionId::DOWN) {
                CharState::PRONE
              } else {
                CharState::STAND
              }
              player.set_state(state)
            }
          LADDER | ROPE => {
            let y = player.character.get_phobj().get_y()
            let downwards = player.is_key_down(@keyboard.BasicActionId::DOWN)
            match player.get_ladder() {
              Some(ladder) =>
                if ladder.felloff(y, downwards) {
                  cancel_ladder(player)
                }
              None => ()
            }
          }
          _ => ()
        }
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
    // new_move_player_packet(newmove).dispatch()
    self.last_move = newmove
  }
}

///|
/// Respawn the player at the given position
pub fn Player::respawn(
  self : Player,
  pos : @struct.Point[Int],
  underwater : Bool,
) -> Unit {
  self.set_position(pos.x, pos.y)
  self.underwater = underwater
}

///|
pub fn Player::set_position(self : Player, x : Int, y : Int) -> Unit {
  self.character.set_position(@struct.Point::new(x, y))
}

///|
pub fn Player::draw(
  self : Player,
  layer : Int,
  viewx : Double,
  viewy : Double,
  alpha : Double,
) -> Unit {
  if layer == self.character.get_layer() {
    self.character.draw(viewx, viewy, alpha)
  }
}

///|
/// Sends a Keyaction to the player's state, to apply forces, change the state and other behaviour.
pub fn Player::send_action(
  self : Player,
  action : @keyboard.BasicActionId,
  down : Bool,
) -> Unit {
  let player = self
  let ka = action
  match self.character.state {
    STAND => {
      if player.is_attacking() {
        return
      }
      if down {
        match ka {
          @keyboard.BasicActionId::LEFT => {
            player.set_facing_right(false)
            player.set_state(CharState::WALK)
          }
          @keyboard.BasicActionId::RIGHT => {
            player.set_facing_right(true)
            player.set_state(CharState::WALK)
          }
          @keyboard.BasicActionId::JUMP => {
            play_jumpsound()
            player.character.get_phobj().set_vforce(-player.get_jumpforce())
          }
          @keyboard.BasicActionId::DOWN => player.set_state(CharState::PRONE)
          _ => ()
        }
      }
    }
    WALK => {
      if player.is_attacking() {
        return
      }
      if down {
        match ka {
          @keyboard.BasicActionId::LEFT => player.set_facing_right(false)
          @keyboard.BasicActionId::RIGHT => player.set_facing_right(true)
          @keyboard.BasicActionId::JUMP => {
            play_jumpsound()
            player.character.get_phobj().set_vforce(-player.get_jumpforce())
          }
          @keyboard.BasicActionId::DOWN => player.set_state(CharState::PRONE)
          _ => ()
        }
      }
    }
    FALL =>
      if down {
        match ka {
          @keyboard.BasicActionId::LEFT => player.set_facing_right(false)
          @keyboard.BasicActionId::RIGHT => player.set_facing_right(true)
          _ => ()
        }
      }
    PRONE =>
      if down {
        match ka {
          @keyboard.BasicActionId::JUMP =>
            if player.character.get_phobj().enablejd &&
              player.is_key_down(@keyboard.BasicActionId::DOWN) {
              play_jumpsound()
              player.character.get_phobj().moving_object.set_y(
                player.character.get_phobj().groundbelow,
              )
              player.set_state(CharState::FALL)
            }
          _ => ()
        }
      } else {
        match ka {
          @keyboard.BasicActionId::DOWN => player.set_state(CharState::STAND)
          _ => ()
        }
      }
    SIT =>
      if down {
        match ka {
          @keyboard.BasicActionId::LEFT => {
            player.set_facing_right(false)
            player.set_state(CharState::WALK)
          }
          @keyboard.BasicActionId::RIGHT => {
            player.set_facing_right(true)
            player.set_state(CharState::WALK)
          }
          @keyboard.BasicActionId::JUMP => {
            play_jumpsound()
            player.set_state(CharState::STAND)
          }
          @keyboard.BasicActionId::UP => player.set_state(CharState::STAND)
          _ => ()
        }
      }
    SWIM =>
      if down {
        match ka {
          @keyboard.BasicActionId::LEFT => player.set_facing_right(false)
          @keyboard.BasicActionId::RIGHT => player.set_facing_right(true)
          _ => ()
        }
      }
    LADDER | ROPE =>
      if down {
        match ka {
          @keyboard.BasicActionId::JUMP =>
            if player.is_key_down(@keyboard.BasicActionId::LEFT) {
              play_jumpsound()
              player.set_facing_right(false)
              player.character.get_phobj().moving_object.set_hspeed(
                -player.get_walkforce() * 8.0,
              )
              player.character.get_phobj().moving_object.set_vspeed(
                -player.get_jumpforce() / 1.5,
              )
              cancel_ladder(player)
            } else if player.is_key_down(@keyboard.BasicActionId::RIGHT) {
              play_jumpsound()
              player.set_facing_right(true)
              player.character.get_phobj().moving_object.set_hspeed(
                player.get_walkforce() * 8.0,
              )
              player.character.get_phobj().moving_object.set_vspeed(
                -player.get_jumpforce() / 1.5,
              )
              cancel_ladder(player)
            }
          _ => ()
        }
      }
    _ => ()
  }
}

///|
fn get_player_state(state : CharState) -> Unit? {
  match state {
    CharState::STAND => Some(())
    CharState::WALK => Some(())
    CharState::FALL => Some(())
    CharState::PRONE => Some(())
    CharState::LADDER | CharState::ROPE => Some(())
    CharState::SIT => Some(())
    CharState::SWIM => Some(())
    _ => None
  }
}

///|
pub fn Player::is_key_down(
  self : Player,
  key : @keyboard.BasicActionId,
) -> Bool {
  match key {
    @keyboard.BasicActionId::UP => @inputs.is_pressed(@inputs.Code::ArrowUp)
    @keyboard.BasicActionId::DOWN => @inputs.is_pressed(@inputs.Code::ArrowDown)
    @keyboard.BasicActionId::LEFT => @inputs.is_pressed(@inputs.Code::ArrowLeft)
    @keyboard.BasicActionId::RIGHT =>
      @inputs.is_pressed(@inputs.Code::ArrowRight)
    _ => false
  }
}

///|
pub fn Player::set_facing_right(self : Player, facing_right : Bool) -> Unit {
  if not(self.character.attacking) {
    self.character.set_facing_right(facing_right)
  }
}

///|
pub fn Player::is_attacking(self : Player) -> Bool {
  self.character.attacking
}

// Set state ignore if attacking.

///|
pub fn Player::set_state(self : Player, st : CharState) -> Unit {
  if not(self.character.attacking) {
    self.character.set_state(st)
    match st {
      STAND | WALK | FALL =>
        self.character.get_phobj().set_t(@physics.PhysicsObjectType::NORMAL)
      SWIM =>
        self.character
        .get_phobj()
        .set_t(
          if self.is_underwater() {
            @physics.PhysicsObjectType::SWIMMING
          } else {
            @physics.PhysicsObjectType::FLYING
          },
        )
      LADDER | ROPE =>
        self.character.get_phobj().set_t(@physics.PhysicsObjectType::FIXATED)
      _ => ()
    }
  }
}

///|
pub fn Player::is_underwater(self : Player) -> Bool {
  self.underwater
}

///|
pub fn Player::get_flyforce(self : Player) -> Double {
  0.25
}

///|
/// Returns the current jumping force, calculated from the total ES_JUMP stat.
pub fn Player::get_jumpforce(self : Player) -> Double {
  1.0 +
  3.5 * self.stats.get_total(@maple_stat.EquipStatId::JUMP).to_double() / 100.0
}

///|
pub fn Player::get_climbforce(self : Player) -> Double {
  self.stats.get_total(@maple_stat.EquipStatId::SPEED).to_double() / 100.0
}

///|
/// Returns the current walking force, calculated from the total ES_SPEED stat.
pub fn Player::get_walkforce(self : Player) -> Double {
  0.05 +
  0.11 *
  self.stats.get_total(@maple_stat.EquipStatId::SPEED).to_double() /
  100.0
}

///|
pub fn Player::get_stats(self : Player) -> CharStats {
  self.stats
}

///|
/// Recalculates the total stats from base stats, inventories and skills.
pub fn Player::recalc_stats(self : Player, equip_changed : Bool) -> Unit {
  let weapontype = self.character.get_weapontype()
  self.stats.init_totalstats()
  if equip_changed {
    // self.inventory.recalc_stats(weapontype)
  }
  for stat in @maple_stat.all_equip_stats {
    // let inventory_total = self.inventory.get_stat(stat)
    // self.stats.add_value(stat, inventory_total)
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
pub fn Player::get_ladder(self : Player) -> @map.Ladder? {
  self.ladder
}

///|
pub fn Player::set_ladder(self : Player, ladder : @map.Ladder?) -> Unit {
  self.ladder = ladder
  match ladder {
    Some(ladder) => {
      self.character.get_phobj().set_x(ladder.get_x().to_double())
      self.character.get_phobj().set_hspeed(0.0)
      self.character.get_phobj().set_vspeed(0.0)
      self.character.get_phobj().set_fhlayer(7)
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
pub fn Player::damage(
  self : Player,
  attack : @combat.MobAttack,
) -> @combat.MobAttackResult {
  let damage = self.stats.calculate_damage(attack.watk)
  self.character.show_damage(damage)
  let fromleft = attack.origin.x > self.character.get_phobj().get_x()
  let missed = damage <= 0
  let immovable = not(self.get_ladder().is_empty()) ||
    self.character.state == CharState::DIED
  let knockback = not(missed) && not(immovable)
  if knockback && self.randomizer.above(self.stats.get_stance()) {
    self.character.get_phobj().moving_object.set_hspeed(
      if fromleft {
        -1.5
      } else {
        1.5
      },
    )
    self.character
    .get_phobj()
    .set_vforce(self.character.get_phobj().vforce - 3.5)
  }
  let direction = if fromleft { 0 } else { 1 }
  @combat.MobAttackResult::new(attack, damage, direction)
}

///|
pub fn Player::get_skills(self : Player) -> &SkillBook {
  ...
  // self.skill_book
}

///|
pub fn Player::can_attack(self : Player) -> Bool {
  not(self.character.attacking) &&
  not(self.character.is_climbing()) &&
  not(self.character.is_sitting()) &&
  self.character.look.get_equips().has_weapon()
}

///|
pub fn Player::rush(self : Player, targetx : Double) -> Unit {
  if self.character.get_phobj().onground {
    let delay = self.character.get_attackdelay(1)
    self.character.get_phobj().moving_object.movexuntil(targetx, delay)
    self.character
    .get_phobj()
    .set_flag(@physics.PhysicsObjectFlag::TURN_AT_EDGES)
  }
}

///|
pub fn Player::check_ladders(
  self : Player,
  map_info : @map.MapInfo,
  up : Bool,
) -> Unit {
  if self.character.is_climbing() || self.character.attacking {
    return
  }
  let ladder = map_info.find_ladder(self.character.get_position(), up)
  self.set_ladder(ladder)
}

///|
pub fn Player::change_skill(
  self : Player,
  skill_id : Int,
  skill_level : Int,
  masterlevel : Int,
  expiration : Int,
) -> Unit {
  // let old_level = self.skill_book.get_level(skill_id)
  // self.skill_book.set_skill(skill_id, skill_level, masterlevel, expiration)
  // if old_level != skill_level {
  //   self.recalc_stats(false)
  // }
}

///|
pub fn Player::show_iron_body(self : Player) -> Unit {
  self.character.show_iron_body()
}

///|
pub fn Player::attack_by_action(self : Player, action : String) -> Unit {
  self.character.attack_by_action(action)
}

///|
pub fn Player::attack_by_stance(
  self : Player,
  stance : @types.StanceId,
) -> Unit {
  self.character.attack_by_stance(stance)
}

///|
pub fn Player::change_job(
  self : Player,
  job_id : Int,
  io_service : @io_task.IOService,
) -> Unit {
  // self.character.show_effect_id(@character.CharEffectId::JOB_CHANGE)
  // self.changing_job = io_service
  //   .submit(fn() {
  //     let job = @job.Job::load(id=job_id)
  //     let skill_book = (self.load_skill_book)(job)
  //     (job, skill_book)
  //   })
  //   .map(fn(it) {
  //     it.unwrap() // TODO: handle error
  //   })
  //   |> Some
}
