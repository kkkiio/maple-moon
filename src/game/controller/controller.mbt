///|
using @character {type CharState}

///|
using @server_proto {type ChangeMapMessage}

///|
fn play_jumpsound() -> Unit {
  //   Sound::new(SoundName::SOUND_NAME_JUMP).play()
}

///|
fn cancel_ladder(player : @player.Player) -> Unit {
  player.set_state(CharState::FALL)
  player.set_ladder(None)
}

///|
fn is_action_down(action : @keymap.BasicActionId) -> Bool {
  @keymap.is_pressed(@keymap.Action::BASIC(action))
}

///|
fn has_action(actions : Array[@keymap.Action], target : @keymap.Action) -> Bool {
  for action in actions {
    if action == target {
      return true
    }
  }
  false
}

///|
fn trigger_portal_transition(
  player : @player.Player,
  map_info : @map.MapInfo,
  physics : @physics.Physics,
  warpinfo : @map.PortalWarpInfo,
) -> Bool {
  if warpinfo.intra_map {
    guard @map.get_portal_by_name_current(warpinfo.toname) is Some(spawn_point) else {
      @log.error("portal not found", data={ "warpinfo": warpinfo })
      return false
    }
    let startpos = physics.get_y_below(spawn_point)
    player.respawn(startpos, map_info.is_underwater())
  } else {
    let message = ChangeMapMessage::{
      died: false,
      target_id: -1,
      target_p: warpinfo.name,
      use_wheel: false,
    }
    let stats = player.get_stats()
    stats.set_map_id(warpinfo.map_id)
    @game_server.send(message, log_level=@log.Level::INFO)
  }
  true
}

///|
/// Try to trigger a manually activated portal at the player's current position.
pub fn try_trigger_manual_portal(
  player : @player.Player,
  map_info : @map.MapInfo,
  physics : @physics.Physics,
) -> Bool {
  if player.is_attacking() {
    return false
  }
  let playerpos = player.character.get_position()
  guard @map.find_manual_warp_at_current(playerpos) is Some(warpinfo) else {
    return false
  }
  trigger_portal_transition(player, map_info, physics, warpinfo)
}

///|
/// Try to trigger an auto-activated portal at the player's current position.
pub fn try_trigger_auto_portal(
  player : @player.Player,
  map_info : @map.MapInfo,
  physics : @physics.Physics,
) -> Bool {
  if player.is_attacking() {
    return false
  }
  let playerpos = player.character.get_position()
  guard @map.find_auto_warp_at_current(playerpos) is Some(warpinfo) else {
    return false
  }
  trigger_portal_transition(player, map_info, physics, warpinfo)
}

///|
fn handle_direction_action(
  player : @player.Player,
  action : @keymap.BasicActionId,
) -> Unit {
  match player.character.state {
    STAND if !player.is_attacking() =>
      match action {
        @keymap.BasicActionId::MOVE_LEFT => {
          player.set_facing_right(false)
          player.set_state(CharState::WALK)
        }
        @keymap.BasicActionId::MOVE_RIGHT => {
          player.set_facing_right(true)
          player.set_state(CharState::WALK)
        }
        @keymap.BasicActionId::JUMP => {
          play_jumpsound()
          player.character.get_phobj().set_vforce(-player.get_jumpforce())
        }
        @keymap.BasicActionId::MOVE_DOWN => player.set_state(CharState::PRONE)
        _ => ()
      }
    WALK if !player.is_attacking() =>
      match action {
        @keymap.BasicActionId::MOVE_LEFT => player.set_facing_right(false)
        @keymap.BasicActionId::MOVE_RIGHT => player.set_facing_right(true)
        @keymap.BasicActionId::JUMP => {
          play_jumpsound()
          player.character.get_phobj().set_vforce(-player.get_jumpforce())
        }
        @keymap.BasicActionId::MOVE_DOWN => player.set_state(CharState::PRONE)
        _ => ()
      }
    FALL =>
      match action {
        @keymap.BasicActionId::MOVE_LEFT => player.set_facing_right(false)
        @keymap.BasicActionId::MOVE_RIGHT => player.set_facing_right(true)
        _ => ()
      }
    PRONE =>
      match action {
        @keymap.BasicActionId::JUMP =>
          if player.character.get_phobj().enablejd &&
            is_action_down(@keymap.BasicActionId::MOVE_DOWN) {
            play_jumpsound()
            player.character.get_phobj().moving_object.set_y(
              player.character.get_phobj().groundbelow,
            )
            player.set_state(CharState::FALL)
          }
        _ => ()
      }
    SIT =>
      match action {
        @keymap.BasicActionId::MOVE_LEFT => {
          player.set_facing_right(false)
          player.set_state(CharState::WALK)
        }
        @keymap.BasicActionId::MOVE_RIGHT => {
          player.set_facing_right(true)
          player.set_state(CharState::WALK)
        }
        @keymap.BasicActionId::JUMP => {
          play_jumpsound()
          player.set_state(CharState::STAND)
        }
        @keymap.BasicActionId::MOVE_UP => player.set_state(CharState::STAND)
        _ => ()
      }
    SWIM =>
      match action {
        @keymap.BasicActionId::MOVE_LEFT => player.set_facing_right(false)
        @keymap.BasicActionId::MOVE_RIGHT => player.set_facing_right(true)
        _ => ()
      }
    LADDER | ROPE =>
      match action {
        @keymap.BasicActionId::JUMP =>
          if is_action_down(@keymap.BasicActionId::MOVE_LEFT) {
            play_jumpsound()
            player.set_facing_right(false)
            player.character.get_phobj().moving_object.set_hspeed(
              -player.get_walkforce() * 8.0,
            )
            player.character.get_phobj().moving_object.set_vspeed(
              -player.get_jumpforce() / 1.5,
            )
            cancel_ladder(player)
          } else if is_action_down(@keymap.BasicActionId::MOVE_RIGHT) {
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
    _ => ()
  }
}

///|
/// Handle frame-based player input sampling and action dispatch.
pub fn player_controller_input_system(_world : @ecs.World) -> Unit {
  guard @game_state.current_phase() is GameActive(..) else { return }
  guard @map.get_runtime_context() is Some((map_info, physics)) else { return }
  guard @player.get_player() is Some(player) else { return }
  let just_pressed_actions = @keymap.just_pressed_actions()

  if @keymap.is_pressed(@keymap.Action::BASIC(@keymap.BasicActionId::MOVE_UP)) {
    player.check_ladders(map_info, true)
  } else if @keymap.is_pressed(
      @keymap.Action::BASIC(@keymap.BasicActionId::MOVE_DOWN),
    ) {
    player.check_ladders(map_info, false)
  }

  if has_action(
      just_pressed_actions,
      @keymap.Action::BASIC(@keymap.BasicActionId::MOVE_UP),
    ) {
    try_trigger_manual_portal(player, map_info, physics) |> ignore
  }

  let moving_left = @keymap.is_pressed(
    @keymap.Action::BASIC(@keymap.BasicActionId::MOVE_LEFT),
  )
  let moving_right = @keymap.is_pressed(
    @keymap.Action::BASIC(@keymap.BasicActionId::MOVE_RIGHT),
  )
  if moving_left != moving_right {
    handle_direction_action(
      player,
      if moving_left {
        @keymap.BasicActionId::MOVE_LEFT
      } else {
        @keymap.BasicActionId::MOVE_RIGHT
      },
    )
  }

  for
    action in [
      @keymap.BasicActionId::MOVE_UP,
      @keymap.BasicActionId::MOVE_DOWN,
      @keymap.BasicActionId::JUMP,
    ] {
    if has_action(just_pressed_actions, @keymap.Action::BASIC(action)) {
      handle_direction_action(player, action)
    }
  }

  for action in just_pressed_actions {
    match action {
      @keymap.Action::QUICK_SLOT(slot) =>
        match @keymap.quick_slot_content(slot) {
          Some(@keymap.QuickSlotContent::Skill(skill_id)) =>
            @skill_cast.use_move(player, skill_id)
          Some(@keymap.QuickSlotContent::Item(item_id)) =>
            @inventory.inventory.val.use_item(item_id)
          None => ()
        }
      @keymap.Action::BASIC(@keymap.BasicActionId::ATTACK) =>
        @skill_cast.use_move(player, @combat_proto.REGULAR_ATTACK)
      @keymap.Action::BASIC(@keymap.BasicActionId::INTERACT) => {
        let player_pos = player.character.get_position()
        if !@drop.try_pickup_at(player_pos) {
          @npc.try_talk_near(player_pos) |> ignore
        }
      }
      @keymap.Action::BASIC(_) => ()
      @keymap.Action::UI(_) => ()
    }
  }

  try_trigger_auto_portal(player, map_info, physics) |> ignore
}

///|
/// Advance player movement and state once in fixed schedule.
// TODO: Split non-fixed-step logic out of this FixedUpdate system into a separate Update system function.
pub fn player_controller_fixed_system(_world : @ecs.World) -> Unit {
  guard @game_state.current_phase() is GameActive(..) else { return }
  guard @map.get_runtime_context() is Some((map_info, physics)) else { return }
  guard @player.get_player() is Some(player) else { return }
  @player.tick_player(player, physics, map_info)
}
