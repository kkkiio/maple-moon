///|
/// Playtest bot action kind owned by the debug runtime.
priv enum BotActionKind {
  Warp(map_id~ : Int, portal_id~ : Int)
  Idle(frames~ : Int)
  WalkTo(x~ : Int, y~ : Int)
  JumpForward
  HoldUp
  Attack
  AttackTarget(oid~ : Int)
}

///|
/// A single pending playtest action.
priv struct PendingAction {
  id : Int
  kind : BotActionKind
  timeout_frames : Int
  mut elapsed_frames : Int
  mut saw_airborne : Bool
  mut attack_pressed : Bool
  start_map_id : Int
  start_portal_id : Int
}

///|
let current_action_ref : Ref[PendingAction?] = Ref(None)

///|
let next_action_id_ref : Ref[Int] = Ref(1)

///|
extern "js" fn install_bot_bindings(
  request_action_text : (String, String) -> String,
  cancel_action_text : (String) -> String,
  state_text : () -> String,
  nearest_monster_text : () -> String,
  nearby_portals_text : () -> String,
) -> Unit =
  #| (
  #|   requestActionText,
  #|   cancelActionText,
  #|   stateText,
  #|   nearestMonsterText,
  #|   nearbyPortalsText
  #| ) => {
  #|   const registry = globalThis.__playtestBot || { pending: new Map() };
  #|   globalThis.__playtestBot = registry;
  #|   const toInt = (value, fallback = 0) => {
  #|     const n = Number(value);
  #|     return Number.isFinite(n) ? Math.trunc(n) : fallback;
  #|   };
  #|   const enqueue = (name, payload = {}, options = {}) => {
  #|     const body = { ...payload };
  #|     if (options && options.timeoutFrames != null) {
  #|       body.timeoutFrames = toInt(options.timeoutFrames, 0);
  #|     }
  #|     const response = JSON.parse(requestActionText(String(name), JSON.stringify(body)));
  #|     if (!response.ok) {
  #|       const error = new Error(response.error || `bot action rejected: ${name}`);
  #|       error.response = response;
  #|       return Promise.reject(error);
  #|     }
  #|     return new Promise((resolve, reject) => {
  #|       registry.pending.set(response.id, { resolve, reject, name });
  #|     });
  #|   };
  #|   globalThis.__bot = {
  #|     warp(mapId, portalId = 0, options = {}) {
  #|       return enqueue("warp", { mapId: toInt(mapId), portalId: toInt(portalId) }, options);
  #|     },
  #|     walk_to(x, y, options = {}) {
  #|       return enqueue("walk_to", { x: toInt(x), y: toInt(y) }, options);
  #|     },
  #|     jump_forward(options = {}) {
  #|       return enqueue("jump_forward", {}, options);
  #|     },
  #|     hold_up(options = {}) {
  #|       return enqueue("hold_up", {}, options);
  #|     },
  #|     attack(options = {}) {
  #|       return enqueue("attack", {}, options);
  #|     },
  #|     attack_target(oid, options = {}) {
  #|       return enqueue("attack_target", { oid: toInt(oid) }, options);
  #|     },
  #|     idle(frames = 1, options = {}) {
  #|       return enqueue("idle", { frames: Math.max(1, toInt(frames, 1)) }, options);
  #|     },
  #|     cancel(reason = "bot action cancelled") {
  #|       return JSON.parse(cancelActionText(String(reason)));
  #|     },
  #|     state() {
  #|       return JSON.parse(stateText());
  #|     },
  #|     nearest_monster() {
  #|       return JSON.parse(nearestMonsterText());
  #|     },
  #|     nearby_portals() {
  #|       return JSON.parse(nearbyPortalsText());
  #|     },
  #|     telemetry: {
  #|       log(message, data = undefined) {
  #|         if (data === undefined) console.log("[playtest]", String(message));
  #|         else console.log("[playtest]", String(message), data);
  #|       },
  #|     },
  #|   };
  #|   globalThis.__bot_cancel_pending = (reason = "bot action cancelled") => {
  #|     return JSON.parse(cancelActionText(String(reason)));
  #|   };
  #| };

///|
extern "js" fn settle_bot_action(
  id : Int,
  ok : Bool,
  payload_text : String,
) -> Unit =
  #| (id, ok, payloadText) => {
  #|   const registry = globalThis.__playtestBot;
  #|   const pending = registry && registry.pending;
  #|   const entry = pending && pending.get(id);
  #|   let payload = null;
  #|   try { payload = JSON.parse(payloadText); } catch (_) { payload = payloadText; }
  #|   if (!entry) return;
  #|   pending.delete(id);
  #|   if (ok) {
  #|     entry.resolve(payload);
  #|   } else {
  #|     const error = new Error((payload && payload.error) || `bot action failed: ${entry.name}`);
  #|     error.payload = payload;
  #|     entry.reject(error);
  #|   }
  #| };

///|
/// Install `globalThis.__bot` for the game_debug JavaScript runtime.
///
/// This function is normally called by `plugin()` during the Startup schedule.
/// Reinstalling replaces the JS binding object while keeping unresolved Promise
/// state in `globalThis.__playtestBot`.
///
/// # Example
/// ```moonbit nocheck
/// @bot_controller.install()
/// ```
pub fn install() -> Unit {
  install_bot_bindings(
    request_action_text,
    cancel_action_text,
    state_text,
    nearest_monster_text,
    fn() { @map.current_portals_json().stringify() },
  )
}

///|
/// Return the debug-only playtest bot plugin.
///
/// The plugin installs `globalThis.__bot` at Startup and advances one pending
/// action each Update by injecting Selene input snapshots. It is intended only
/// for `src/apps/game_debug`.
///
/// # Example
/// ```moonbit nocheck
/// let app = @game_app.base_app().add_plugin(@bot_controller.plugin())
/// ```
pub fn plugin() -> @app.Plugin {
  fn(app : @app.App) -> @app.App {
    app
    .add_system(
      @system.Startup,
      fn(_world) { install() },
      system_name="bot_controller_install",
    )
    .add_system(
      @system.Update,
      bot_action_system,
      system_name="bot_controller_action_system",
    )
  }
}

///|
fn request_action_text(action_name : String, payload_text : String) -> String {
  let payload = @json.parse(payload_text) catch {
    err =>
      return (
        { "ok": false, "error": "invalid bot action payload: \{err}" } : Json).stringify()
  }
  match current_action_ref.val {
    Some(action) =>
      return (
        {
          "ok": false,
          "error": "bot action already pending",
          "pendingId": action.id,
        } : Json).stringify()
    None => ()
  }
  let mut timeout_frames = match action_name {
    "warp" => 900
    "idle" => 300
    "walk_to" => 900
    "jump_forward" => 300
    "hold_up" => 480
    "attack" => 240
    "attack_target" => 1800
    _ => 300
  }
  match payload {
    { "timeoutFrames": Number(v, ..), .. } if v.to_int() > 0 =>
      timeout_frames = v.to_int()
    _ => ()
  }
  let kind : BotActionKind = match action_name {
    "warp" =>
      match payload {
        { "mapId": Number(map_id, ..), "portalId": Number(portal_id, ..), .. } =>
          BotActionKind::Warp(
            map_id=map_id.to_int(),
            portal_id=portal_id.to_int(),
          )
        _ =>
          return (
            { "ok": false, "error": "warp requires numeric mapId and portalId" } :
            Json).stringify()
      }
    "idle" =>
      match payload {
        { "frames": Number(frames, ..), .. } if frames.to_int() > 0 =>
          BotActionKind::Idle(frames=frames.to_int())
        _ =>
          return (
            { "ok": false, "error": "idle requires positive numeric frames" } :
            Json).stringify()
      }
    "walk_to" =>
      match payload {
        { "x": Number(x, ..), "y": Number(y, ..), .. } =>
          BotActionKind::WalkTo(x=x.to_int(), y=y.to_int())
        _ =>
          return (
            { "ok": false, "error": "walk_to requires numeric x and y" } : Json).stringify()
      }
    "jump_forward" => BotActionKind::JumpForward
    "hold_up" => BotActionKind::HoldUp
    "attack" => BotActionKind::Attack
    "attack_target" =>
      match payload {
        { "oid": Number(oid, ..), .. } =>
          BotActionKind::AttackTarget(oid=oid.to_int())
        _ =>
          return (
            { "ok": false, "error": "attack_target requires numeric oid" } :
            Json).stringify()
      }
    _ =>
      return (
        { "ok": false, "error": "unknown bot action: \{action_name}" } : Json).stringify()
  }
  let mut start_map_id = -1
  let mut start_portal_id = -1
  match @game_state.current_phase() {
    @game_state.GamePhase::GameStart(map_id~, portal_id~, ..) => {
      start_map_id = map_id
      start_portal_id = portal_id
    }
    @game_state.GamePhase::GameTransiting(map_id~, portal_id~) => {
      start_map_id = map_id
      start_portal_id = portal_id
    }
    @game_state.GamePhase::GameActive(map_id~, portal_id~) => {
      start_map_id = map_id
      start_portal_id = portal_id
    }
    _ => ()
  }
  let action_id = next_action_id_ref.val
  next_action_id_ref.val = action_id + 1
  current_action_ref.val = Some({
    id: action_id,
    kind,
    timeout_frames,
    elapsed_frames: 0,
    saw_airborne: false,
    attack_pressed: false,
    start_map_id,
    start_portal_id,
  })
  match kind {
    BotActionKind::Warp(map_id~, portal_id~) =>
      @game_server.send(
        @server_proto.AdminCommandMessage::Warp(map_id~, portal_id~),
      )
    _ => ()
  }
  (
    {
      "ok": true,
      "id": action_id,
      "action": action_name,
      "timeoutFrames": timeout_frames,
    } : Json).stringify()
}

///|
fn cancel_action_text(reason : String) -> String {
  match current_action_ref.val {
    Some(action) => {
      @runtime_debug.clear_queued_inputs()
      @runtime_debug.queue_input_snapshot(@inputs.empty_input_snapshot())
      current_action_ref.val = None
      settle_bot_action(
        action.id,
        false,
        (
          {
            "error": reason,
            "cancelled": true,
            "id": action.id,
            "state": @json.parse(state_text()) catch {
              _ => Json::null()
            },
          } : Json).stringify(),
      )
      ({ "ok": true, "cancelled": true, "id": action.id } : Json).stringify()
    }
    None => ({ "ok": true, "cancelled": false } : Json).stringify()
  }
}

///|
fn state_text() -> String {
  let mut phase_name = "GameSetup"
  let mut map_id = -1
  let mut portal_id = -1
  match @game_state.current_phase() {
    @game_state.GamePhase::GameSetup => phase_name = "GameSetup"
    @game_state.GamePhase::SelectCharacter => phase_name = "SelectCharacter"
    @game_state.GamePhase::GameStart(
      map_id=active_map_id,
      portal_id=active_portal_id,
      ..
    ) => {
      phase_name = "GameStart"
      map_id = active_map_id
      portal_id = active_portal_id
    }
    @game_state.GamePhase::GameTransiting(
      map_id=active_map_id,
      portal_id=active_portal_id
    ) => {
      phase_name = "GameTransiting"
      map_id = active_map_id
      portal_id = active_portal_id
    }
    @game_state.GamePhase::GameActive(
      map_id=active_map_id,
      portal_id=active_portal_id
    ) => {
      phase_name = "GameActive"
      map_id = active_map_id
      portal_id = active_portal_id
    }
  }
  let player_json : Json = match @player.get_player() {
    Some(player) => {
      let character = player.character
      let phobj = character.get_phobj()
      let position = character.get_position()
      {
        "oid": character.get_oid(),
        "x": position.x,
        "y": position.y,
        "state": Debug::to_repr(character.get_state()).to_string(),
        "facingRight": character.is_facing_right(),
        "climbing": character.is_climbing(),
        "onGround": phobj.is_on_ground(),
        "hspeed": phobj.get_hspeed(),
        "vspeed": phobj.get_vspeed(),
        "attacking": player.is_attacking(),
        "hp": player.get_stats().get_stat(@maple_stat.Id::HP),
      }
    }
    None => Json::null()
  }
  let action_json : Json = match current_action_ref.val {
    Some(action) => {
      let (name, target) : (String, Json) = match action.kind {
        BotActionKind::Warp(map_id~, portal_id~) =>
          ("warp", ({ "mapId": map_id, "portalId": portal_id } : Json))
        BotActionKind::Idle(frames~) => ("idle", ({ "frames": frames } : Json))
        BotActionKind::WalkTo(x~, y~) =>
          ("walk_to", ({ "x": x, "y": y } : Json))
        BotActionKind::JumpForward => ("jump_forward", Json::null())
        BotActionKind::HoldUp => ("hold_up", Json::null())
        BotActionKind::Attack => ("attack", Json::null())
        BotActionKind::AttackTarget(oid~) =>
          ("attack_target", ({ "oid": oid } : Json))
      }
      {
        "id": action.id,
        "name": name,
        "target": target,
        "elapsedFrames": action.elapsed_frames,
        "timeoutFrames": action.timeout_frames,
      }
    }
    None => Json::null()
  }
  let mut monster_count = 0
  match @monster.get_map_mobs() {
    Some(mobs) =>
      mobs.for_each_mob(fn(_oid, mob) {
        if mob.is_alive() {
          monster_count += 1
        }
      })
    None => ()
  }
  (
    {
      "phase": phase_name,
      "mapId": map_id,
      "portalId": portal_id,
      "player": player_json,
      "action": action_json,
      "aliveMonsters": monster_count,
    } : Json).stringify()
}

///|
fn nearest_monster_text() -> String {
  let mut player_x = 0
  let mut player_y = 0
  match @player.get_player() {
    Some(player) => {
      let position = player.character.get_position()
      player_x = position.x
      player_y = position.y
    }
    None => ()
  }
  let mut best_oid = -1
  let mut best_x = 0
  let mut best_y = 0
  let mut best_distance = 2147483647
  match @monster.get_map_mobs() {
    Some(mobs) =>
      mobs.for_each_mob(fn(oid, mob) {
        if mob.is_alive() {
          let position = mob.get_position()
          let dx = position.x - player_x
          let dy = position.y - player_y
          let distance = dx * dx + dy * dy
          if distance < best_distance {
            best_oid = oid
            best_x = position.x
            best_y = position.y
            best_distance = distance
          }
        }
      })
    None => ()
  }
  if best_oid < 0 {
    Json::null().stringify()
  } else {
    (
      {
        "oid": best_oid,
        "x": best_x,
        "y": best_y,
        "distanceSquared": best_distance,
      } : Json).stringify()
  }
}

///|
fn bot_action_system(_world : @ecs.World) -> Unit {
  guard current_action_ref.val is Some(action) else { return }
  let queue_keys = fn(keys : Array[@inputs.Code]) {
    let snapshot = @inputs.empty_input_snapshot()
    for key in keys {
      snapshot.pressed_keys.add(key)
    }
    @runtime_debug.clear_queued_inputs()
    @runtime_debug.queue_input_snapshot(snapshot)
  }
  let finish = fn(ok : Bool, payload : Json) {
    @runtime_debug.clear_queued_inputs()
    @runtime_debug.queue_input_snapshot(@inputs.empty_input_snapshot())
    current_action_ref.val = None
    settle_bot_action(action.id, ok, payload.stringify())
  }
  action.elapsed_frames = action.elapsed_frames + 1
  if action.elapsed_frames > action.timeout_frames {
    finish(
      false,
      (
        {
          "error": "bot action timed out",
          "id": action.id,
          "elapsedFrames": action.elapsed_frames,
          "state": @json.parse(state_text()) catch {
            _ => Json::null()
          },
        } : Json),
    )
    return
  }
  match action.kind {
    BotActionKind::Warp(map_id~, portal_id~) =>
      match @game_state.current_phase() {
        @game_state.GamePhase::GameActive(
          map_id=active_map_id,
          portal_id=active_portal_id
        ) =>
          if active_map_id == map_id && active_portal_id == portal_id {
            queue_keys([])
            finish(true, ({ "mapId": map_id, "portalId": portal_id } : Json))
          } else {
            queue_keys([])
          }
        _ => queue_keys([])
      }
    BotActionKind::Idle(frames~) => {
      queue_keys([])
      if action.elapsed_frames >= frames {
        finish(true, ({ "frames": frames } : Json))
      }
    }
    BotActionKind::WalkTo(x~, y~) =>
      match @player.get_player() {
        Some(player) => {
          let position = player.character.get_position()
          let dx = x - position.x
          let dy = y - position.y
          let abs_x = if dx < 0 { -dx } else { dx }
          let abs_y = if dy < 0 { -dy } else { dy }
          if abs_x <= 16 && abs_y <= 160 {
            queue_keys([])
            finish(
              true,
              (
                { "x": position.x, "y": position.y, "targetX": x, "targetY": y } :
                Json),
            )
          } else if abs_x > 16 {
            if dx > 0 {
              queue_keys([@inputs.Code::ArrowRight])
            } else {
              queue_keys([@inputs.Code::ArrowLeft])
            }
          } else {
            queue_keys([])
          }
        }
        None => queue_keys([])
      }
    BotActionKind::JumpForward =>
      match @player.get_player() {
        Some(player) => {
          let phobj = player.character.get_phobj()
          if !phobj.is_on_ground() {
            action.saw_airborne = true
          }
          let direction = if player.character.is_facing_right() {
            @inputs.Code::ArrowRight
          } else {
            @inputs.Code::ArrowLeft
          }
          if action.saw_airborne &&
            phobj.is_on_ground() &&
            action.elapsed_frames > 8 {
            queue_keys([])
            let position = player.character.get_position()
            finish(true, ({ "x": position.x, "y": position.y } : Json))
          } else if action.elapsed_frames <= 6 {
            queue_keys([direction, @inputs.Code::Space])
          } else if action.elapsed_frames <= 24 {
            queue_keys([direction])
          } else {
            queue_keys([])
          }
        }
        None => queue_keys([])
      }
    BotActionKind::HoldUp => {
      let mut phase_map_id = -1
      let mut phase_portal_id = -1
      match @game_state.current_phase() {
        @game_state.GamePhase::GameActive(map_id~, portal_id~) => {
          phase_map_id = map_id
          phase_portal_id = portal_id
        }
        _ => ()
      }
      match @player.get_player() {
        Some(player) => {
          let climbing = player.get_ladder() is Some(_)
          if climbing ||
            (
              phase_map_id >= 0 &&
              (
                phase_map_id != action.start_map_id ||
                phase_portal_id != action.start_portal_id
              )
            ) {
            queue_keys([])
            finish(
              true,
              (
                {
                  "mapId": phase_map_id,
                  "portalId": phase_portal_id,
                  "climbing": climbing,
                } : Json),
            )
          } else {
            queue_keys([@inputs.Code::ArrowUp])
          }
        }
        _ => queue_keys([@inputs.Code::ArrowUp])
      }
    }
    BotActionKind::Attack =>
      match @player.get_player() {
        Some(player) =>
          if action.elapsed_frames == 1 {
            action.attack_pressed = true
            queue_keys([@inputs.Code::KeyX])
          } else if action.attack_pressed &&
            action.elapsed_frames > 8 &&
            !player.is_attacking() {
            queue_keys([])
            let position = player.character.get_position()
            finish(true, ({ "x": position.x, "y": position.y } : Json))
          } else {
            queue_keys([])
          }
        None => queue_keys([])
      }
    BotActionKind::AttackTarget(oid~) =>
      match @monster.get_map_mobs() {
        Some(mobs) =>
          match mobs.get_mob(oid) {
            Some(mob) =>
              match @player.get_player() {
                Some(player) => {
                  let player_pos = player.character.get_position()
                  let mob_pos = mob.get_position()
                  let dx = mob_pos.x - player_pos.x
                  let abs_x = if dx < 0 { -dx } else { dx }
                  if abs_x > 72 {
                    if dx > 0 {
                      queue_keys([@inputs.Code::ArrowRight])
                    } else {
                      queue_keys([@inputs.Code::ArrowLeft])
                    }
                  } else {
                    let direction = if dx >= 0 {
                      @inputs.Code::ArrowRight
                    } else {
                      @inputs.Code::ArrowLeft
                    }
                    let phase = action.elapsed_frames % 30
                    if phase < 4 {
                      queue_keys([direction])
                    } else if phase == 4 {
                      action.attack_pressed = true
                      queue_keys([@inputs.Code::KeyX])
                    } else {
                      queue_keys([])
                    }
                  }
                }
                None => queue_keys([])
              }
            None => {
              queue_keys([])
              finish(true, ({ "oid": oid, "killed": true } : Json))
            }
          }
        None => queue_keys([])
      }
  }
}
