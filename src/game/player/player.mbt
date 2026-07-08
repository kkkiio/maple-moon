///|
using @physics {type Movement}

///|
using @char_stance {type StanceId}

///|
using @char_stats {type CharStats}

///|
using @legacy_types {trait Inventory, trait SkillBook}

///|
/// SkillBook that returns max level for each skill from skill data.
priv struct CachedMaxLevelSkillBook {}

///|
impl SkillBook for CachedMaxLevelSkillBook with fn get_level(_, skill_id) {
  @skill.get_skill_max_level(skill_id)
}

///|
impl SkillBook for CachedMaxLevelSkillBook with fn set_skill(_, _, _, _, _) {

}

///|
using @combat_proto {type MobAttack, type MobAttackResult}

///|
using @combat_system {trait CombatCharacter, trait DamagableCharacter}

///|
pub(all) struct Player {
  entity : @entity.Entity
  character : @character.Character
  stats : CharStats
  mut underwater : Bool
  mut last_move : Movement
  mut ladder : @map.Ladder?
  inventory : &Inventory
  buffs : Map[@buff.StatId, @buff.Buff]
  randomizer : @random.Rand
  // load_skill_book : async (@job.Job) -> &SkillBook raise
  mut skill_book : &SkillBook
}

///|
pub impl CombatCharacter for Player with fn get_character(self) {
  self.character
}

///|
pub impl CombatCharacter for Player with fn get_stats(self) {
  self.get_stats()
}

///|
pub impl CombatCharacter for Player with fn get_inventory(self) {
  self.inventory
}

///|
pub impl CombatCharacter for Player with fn get_skill_book(self) {
  self.skill_book
}

///|
pub impl CombatCharacter for Player with fn can_attack(self) {
  self.can_attack()
}

///|
pub impl CombatCharacter for Player with fn rush(self, targetx) {
  self.rush(targetx)
}

///|
pub impl DamagableCharacter for Player with fn is_invincible(self) {
  self.is_invincible()
}

///|
pub impl DamagableCharacter for Player with fn get_phobj(self) {
  self.character.get_phobj()
}

///|
pub impl DamagableCharacter for Player with fn damage(self, attack) {
  self.damage(attack)
}

///|
pub fn Player::load(
  entity : @entity.Entity,
  entry : @character.CharEntry,
  inventory : &Inventory,
  look : @char_look.CharLook,
  // load_skill_book : async (@job.Job) -> &SkillBook raise,
  new_char_stats : (@job.Job) -> CharStats,
) -> Player {
  let job = @job.Job::load(
    id=entry.stats.stats.0.get(@maple_stat.Id::JOB).unwrap_or(0),
  )
  // let skill_book = load_skill_book(job)
  Player::new(
    entity,
    entry.id,
    entry.stats.name,
    inventory,
    // skill_book,
    look,
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
  inventory : &Inventory,
  // skill_book : &SkillBook,
  look : @char_look.CharLook,
  // load_skill_book : async (@job.Job) -> &SkillBook raise,
  stats : CharStats,
) -> Player {
  let skill_book : &SkillBook = CachedMaxLevelSkillBook::{  }
  let character = @character.Character::new(
    entity,
    id,
    look,
    name,
    get_skilllevel=fn(skill_id) { skill_book.get_level(skill_id) },
    stats,
  )
  let p : Player = {
    entity,
    character,
    stats,
    underwater: false,
    last_move: Movement::default(),
    ladder: None,
    inventory,
    buffs: Map([]),
    randomizer: @random.Rand::new(),
    skill_book,
    // load_skill_book,
  }
  p.set_state(CharState::STAND)
  p.set_facing_right(true)
  sync_player_world_z(p)
  stats.watch_stat_changes(@maple_stat.Id::HP, fn(_old, hp) {
    if hp <= 0 {
      p.set_state(@character.CharState::DIED)
      // network.send_message(
      //   { died, target_id, target_p: "sp", use_wheel: false },
      //   log_level=@log.Level::INFO,
      // )
    }
    true
  })
  stats.watch_stat_changes(@maple_stat.Id::HP, fn(old_hp, new_hp) {
    if new_hp > old_hp {
      p.character.show_heal_number(new_hp - old_hp)
    }
    true
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
/// update player state
fn Player::update(
  self : Player,
  physics : @physics.Physics,
  _ : @map.MapInfo,
) -> Unit {
  match get_player_state(self.character.state) {
    Some(_) => {
      let player = self
      match self.character.state {
        STAND =>
          if !player.character.get_phobj().enablejd {
            player.character
            .get_phobj()
            .set_flag(@physics.PhysicsObjectFlag::CHECK_BELOW)
          }
        WALK => {
          if !player.is_attacking() && haswalkinput(player) {
            let hforce = if player.character.is_facing_right() {
              player.get_walkforce()
            } else {
              -player.get_walkforce()
            }
            player.character
            .get_phobj()
            .set_hforce(player.character.get_phobj().hforce + hforce)
          }
          if !player.character.get_phobj().enablejd {
            player.character
            .get_phobj()
            .set_flag(@physics.PhysicsObjectFlag::CHECK_BELOW)
          }
        }
        FALL => {
          let hspeed = player.character.get_phobj().moving_object.hspeed
          if is_action_down(@keymap.BasicActionId::MOVE_LEFT) && hspeed > 0.0 {
            player.character.get_phobj().moving_object.set_hspeed(
              hspeed - 0.025,
            )
            if player.character.get_phobj().moving_object.hspeed < 0.0 {
              player.character.get_phobj().moving_object.set_hspeed(0.0)
            }
          } else if is_action_down(@keymap.BasicActionId::MOVE_RIGHT) &&
            hspeed < 0.0 {
            player.character.get_phobj().moving_object.set_hspeed(
              hspeed + 0.025,
            )
            if player.character.get_phobj().moving_object.hspeed > 0.0 {
              player.character.get_phobj().moving_object.set_hspeed(0.0)
            }
          }
        }
        PRONE => {
          if !player.character.get_phobj().enablejd {
            player.character
            .get_phobj()
            .set_flag(@physics.PhysicsObjectFlag::CHECK_BELOW)
          }
          if !is_action_down(@keymap.BasicActionId::MOVE_DOWN) {
            player.set_state(CharState::STAND)
          }
        }
        SWIM => {
          if player.is_attacking() {
            return
          }
          if is_action_down(@keymap.BasicActionId::MOVE_LEFT) {
            player.character.get_phobj().set_hforce(-player.get_flyforce())
          } else if is_action_down(@keymap.BasicActionId::MOVE_RIGHT) {
            player.character.get_phobj().set_hforce(player.get_flyforce())
          }
          if is_action_down(@keymap.BasicActionId::MOVE_UP) {
            player.character.get_phobj().set_vforce(-player.get_flyforce())
          } else if is_action_down(@keymap.BasicActionId::MOVE_DOWN) {
            player.character.get_phobj().set_vforce(player.get_flyforce())
          }
        }
        LADDER | ROPE =>
          if is_action_down(@keymap.BasicActionId::MOVE_UP) {
            player.character.get_phobj().set_vspeed(-player.get_climbforce())
          } else if is_action_down(@keymap.BasicActionId::MOVE_DOWN) {
            player.character.get_phobj().set_vspeed(player.get_climbforce())
          } else {
            player.character.get_phobj().set_vspeed(0.0)
          }
        _ => ()
      }
      physics.move_object(self.character.get_phobj())
      if self.character.state == CharState::LADDER ||
        self.character.state == CharState::ROPE {
        hold_at_climb_top_if_needed(self, physics)
      }

      self.character.update(
        self.character.get_stancespeed(
          @character.get_integer_attackspeed(
            self.character.get_look(),
            self.stats,
          ),
        ),
      )
      let aniend = self.character.is_animation_finished()
      if aniend && self.character.attacking {
        self.character.attacking = false
        @char_look.clear_after_image(self.entity)
        let state : CharState = if player.character.get_phobj().on_ground {
          if is_action_down(@keymap.BasicActionId::MOVE_LEFT) {
            player.set_facing_right(false)
            CharState::WALK
          } else if is_action_down(@keymap.BasicActionId::MOVE_RIGHT) {
            player.set_facing_right(true)
            CharState::WALK
          } else if is_action_down(@keymap.BasicActionId::MOVE_DOWN) {
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
        player.set_state(state)
      } else {
        match self.character.state {
          STAND =>
            if !player.character.get_phobj().on_ground {
              player.set_state(CharState::FALL)
            }
          WALK =>
            if player.character.get_phobj().on_ground {
              if !haswalkinput(player) ||
                player.character.get_phobj().moving_object.hspeed == 0.0 {
                player.set_state(CharState::STAND)
              }
            } else {
              player.set_state(CharState::FALL)
            }
          FALL =>
            if player.character.get_phobj().on_ground {
              if is_action_down(@keymap.BasicActionId::MOVE_LEFT) {
                player.set_facing_right(false)
                player.set_state(CharState::WALK)
              } else if is_action_down(@keymap.BasicActionId::MOVE_RIGHT) {
                player.set_facing_right(true)
                player.set_state(CharState::WALK)
              } else if is_action_down(@keymap.BasicActionId::MOVE_DOWN) {
                player.set_state(CharState::PRONE)
              } else {
                player.set_state(CharState::STAND)
              }
            } else if player.is_underwater() {
              player.set_state(CharState::SWIM)
            }
          SWIM =>
            if player.character.get_phobj().on_ground && player.is_underwater() {
              let state = if is_action_down(@keymap.BasicActionId::MOVE_LEFT) {
                player.set_facing_right(false)
                CharState::WALK
              } else if is_action_down(@keymap.BasicActionId::MOVE_RIGHT) {
                player.set_facing_right(true)
                CharState::WALK
              } else if is_action_down(@keymap.BasicActionId::MOVE_DOWN) {
                CharState::PRONE
              } else {
                CharState::STAND
              }
              player.set_state(state)
            }
          LADDER | ROPE => {
            let y = player.character.get_phobj().get_y()
            let downwards = is_action_down(@keymap.BasicActionId::MOVE_DOWN)
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
fn is_action_down(action : @keymap.BasicActionId) -> Bool {
  @keymap.is_pressed(@keymap.Action::BASIC(action))
}

///|
let climb_top_exit_tolerance : Double = 6.0

///|
fn has_climb_exit_ground(
  physics : @physics.Physics,
  ladder : @map.Ladder,
) -> Bool {
  let top = ladder.get_top().to_double()
  let x = ladder.get_x().to_double()
  let fhid = physics.get_fht().get_fhid_below(x, top - climb_top_exit_tolerance)
  if fhid <= 0 {
    return false
  }
  let ground = physics.get_fht().get_ground_below_by_id(fhid, x)
  (ground - top).abs() <= climb_top_exit_tolerance
}

///|
fn hold_at_climb_top_if_needed(
  player : Player,
  physics : @physics.Physics,
) -> Unit {
  if !is_action_down(@keymap.BasicActionId::MOVE_UP) {
    return
  }
  match player.get_ladder() {
    Some(ladder) => {
      if has_climb_exit_ground(physics, ladder) {
        return
      }
      let top = ladder.get_top()
      let phobj = player.character.get_phobj()
      if phobj.get_y() < top {
        phobj.set_y(top.to_double())
        phobj.set_vspeed(0.0)
      }
    }
    None => ()
  }
}

///|
pub fn Player::set_facing_right(self : Player, facing_right : Bool) -> Unit {
  if !self.character.attacking {
    self.character.set_facing_right(facing_right)
  }
}

///|
pub fn Player::is_attacking(self : Player) -> Bool {
  self.character.attacking
}

///|
/// Set state ignore if attacking.
pub fn Player::set_state(self : Player, st : CharState) -> Unit {
  if self.character.attacking {
    return
  }
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

///|
pub fn Player::is_underwater(self : Player) -> Bool {
  self.underwater
}

///|
pub fn Player::get_flyforce(_ : Player) -> Double {
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
/// recalc_stats 的主要目的是基于角色的基础属性（Base Stats）、装备（Equipment）、以及Buff状态，重新计算角色的**最终属性（Total Stats）**。
///
/// 具体流程如下：
/// 1.  **初始化 (`init_totalstats`)**: 清除当前的最终属性，并将基础属性（如 STR, DEX, INT, LUK, HP, MP）作为初始值。
/// 2.  **累加装备属性**: （代码中预留了位置）将所有装备提供的属性加成累加到最终属性上。
/// 3.  **应用 Buff**: 遍历当前激活的 Buff，将其属性加成应用到 ultimately 属性上。
/// 4.  **结算 (`close_totalstats`)**:
///     *   计算衍生属性，如命中率（Accuracy）。
///     *   应用百分比加成（如装备或技能提供的 x% 属性提升）。
///     *   计算攻击力范围（Min/Max Damage），这是基于主属性、副属性、武器系数和攻击力计算得出的。
///
/// 简而言之，每当角色的装备、Buff 或基础属性发生变化时，都需要调用此方法来刷新角色的战斗面板数据。
pub fn Player::recalc_stats(self : Player, equip_changed : Bool) -> Unit {
  let _weapontype = self.character.get_weapontype()
  self.stats.init_totalstats()
  if equip_changed {
    // self.inventory.recalc_stats(weapontype)
  }
  for _ in @maple_stat.all_equip_stats {
    // let inventory_total = self.inventory.get_stat(stat)
    // self.stats.add_value(stat, inventory_total)
  }
  // TODO: Implement passive skills
  self.stats.close_totalstats()
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
pub fn Player::damage(self : Player, attack : MobAttack) -> MobAttackResult {
  let damage = self.stats.calculate_damage(attack.watk)
  self.character.show_damage(damage)
  let fromleft = attack.origin.x > self.character.get_phobj().get_x()
  let missed = damage <= 0
  let immovable = self.get_ladder() is Some(_) ||
    self.character.state is CharState::DIED
  let knockback = !missed && !immovable
  if knockback && @randx.above(self.randomizer, self.stats.get_stance()) {
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
  MobAttackResult::new(attack, damage, direction)
}

///|
pub fn Player::get_skills(self : Player) -> &SkillBook {
  self.skill_book
}

///|
pub fn Player::can_attack(self : Player) -> Bool {
  !self.character.attacking &&
  !self.character.is_climbing() &&
  !self.character.is_sitting() &&
  self.character.look.get_equips().has_weapon()
}

///|
pub fn Player::rush(self : Player, targetx : Double) -> Unit {
  if self.character.get_phobj().on_ground {
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
  _ : Player,
  _ : Int,
  _ : Int,
  _ : Int,
  _ : Int,
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
pub fn Player::attack_by_stance(self : Player, stance : StanceId) -> Unit {
  self.character.attack_by_stance(stance)
}

///|
pub fn Player::change_job(_ : Player, _ : Int) -> Unit {
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

///|
pub let player_ref : Ref[Player?] = Ref(None)

///|
pub fn get_player() -> Player? {
  player_ref.val
}

///|
pub fn set_player(player : Player) -> Unit {
  if player_ref.val is Some(existing_player) {
    @character.unregister_character_by_oid(existing_player.character.get_oid())
    existing_player.entity.destroy()
  }
  player_ref.val = Some(player)
}

///|
/// Advances player physics/animation for one fixed logic step.
pub fn tick_player(
  player : Player,
  physics : @physics.Physics,
  map_info : @map.MapInfo,
) -> Unit {
  player.update(physics, map_info)
  sync_player_world_z(player)
}

///|
fn sync_player_world_z(player : Player) -> Unit {
  let layer = player.character.get_layer()
  let world_y = player.character.get_position().y
  let root_z = @graphics.map_player_z(layer, world_y) -
    @graphics.CHAR_LOOK_ZINDEX
  match @transform.transforms().get(player.entity) {
    Some(current) =>
      @transform.transforms().set(player.entity, {
        ..current,
        translation: @math.Vec3(
          current.translation.x,
          current.translation.y,
          root_z.to_double(),
        ),
      })
    None =>
      @transform.transforms().set(
        player.entity,
        @transform.Transform::from_xyz(0.0, 0.0, root_z.to_double()),
      )
  }
}

///|
fn init {
  @console.register_command("whereami", fn(_args) {
    let map_id = match @game_state.current_phase() {
      @game_state.GamePhase::GameActive(map_id~, ..) => map_id
      @game_state.GamePhase::GameTransiting(map_id~, ..) => map_id
      @game_state.GamePhase::GameStart(map_id~, ..) => map_id
      _ => 0
    }
    let pos = match get_player() {
      Some(player) => player.character.get_position()
      None => @struct.Point::new(0, 0)
    }
    { "ok": true, "code": "OK", "map_id": map_id, "x": pos.x, "y": pos.y }
  })
}
