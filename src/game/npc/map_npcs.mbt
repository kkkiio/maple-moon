///|
struct MapNpcs {
  open_npc_talk_ui : (TalkArgs) -> Unit
  is_npc_talk_ui_open : () -> Bool
  npcs : Map[Int, Npc]
  spawns : @queue.Queue[NpcSpawn]
  pointer_reader : @event.EventReader[@physics2d.PointerEvent]
}

///|
pub(all) struct MapNpcsContext {
  map_npcs : MapNpcs
  physics : @physics.Physics
}

///|
pub(all) struct NpcAnchor {
  /// NPC object id in current map runtime.
  oid : Int
  /// NPC template id.
  npc_id : Int
  /// NPC root entity for hierarchy attach.
  entity : @entity.Entity
  /// NPC physics object for world position query.
  npc_object : @physics.MovingObject
  /// Animation tags eligible for ordinary ambient random playback.
  ambient_states : Array[String]
}

///|
let map_npcs_ctx : Ref[MapNpcsContext?] = Ref(None)

///|
const NPC_INTERACTION_RANGE : Int = 120

///|
fn init {
  @console.register_state_section("npcs", fn() {
    let entries : Array[Json] = []
    for anchor in list_npc_anchors() {
      let position = anchor.npc_object.get_position()
      entries.push({
        "oid": anchor.oid,
        "npc_id": anchor.npc_id,
        "x": position.x,
        "y": position.y,
        "ambient_states": anchor.ambient_states,
      })
    }
    entries.sort_by(fn(lhs, rhs) {
      let lhs_id = match lhs {
        { "npc_id": Number(id, ..), .. } => id.to_int()
        _ => 0
      }
      let rhs_id = match rhs {
        { "npc_id": Number(id, ..), .. } => id.to_int()
        _ => 0
      }
      lhs_id.compare(rhs_id)
    })
    { "entries": entries }
  })
  @console.register_command("teleport_to_npc", fn(args) {
    guard !args.is_empty() else {
      return {
        "ok": false,
        "code": "INVALID_ARGUMENTS",
        "message": "teleport_to_npc requires npc id",
      }
    }
    let npc_id = @string.parse_int(args[0]) catch {
      _ => return { "ok": false, "code": "INVALID_NPC_ID" }
    }
    guard @player.get_player() is Some(player) else {
      return { "ok": false, "code": "PLAYER_NOT_READY" }
    }
    for anchor in list_npc_anchors() {
      guard anchor.npc_id == npc_id else { continue }
      let position = anchor.npc_object.get_position()
      player.set_position(position.x, position.y)
      return {
        "ok": true,
        "code": "TELEPORTED_TO_NPC",
        "npc_id": npc_id,
        "oid": anchor.oid,
        "x": position.x,
        "y": position.y,
      }
    }
    { "ok": false, "code": "NPC_NOT_FOUND", "npc_id": npc_id }
  })
  @console.register_command("talk_to_npc", fn(args) {
    guard !args.is_empty() else {
      return {
        "ok": false,
        "code": "INVALID_ARGUMENTS",
        "message": "talk_to_npc requires npc id",
      }
    }
    let npc_id = @string.parse_int(args[0]) catch {
      _ => return { "ok": false, "code": "INVALID_NPC_ID" }
    }
    for anchor in list_npc_anchors() {
      guard anchor.npc_id == npc_id else { continue }
      @game_server.send(@server_proto.TalkToNpcMessage::{ oid: anchor.oid })
      return {
        "ok": true,
        "code": "NPC_TALK_STARTED",
        "npc_id": npc_id,
        "oid": anchor.oid,
      }
    }
    { "ok": false, "code": "NPC_NOT_FOUND", "npc_id": npc_id }
  })
}

///|
pub fn set_npcs(ctx : MapNpcsContext) -> Unit {
  map_npcs_ctx.val = Some(ctx)
}

///|
pub fn clear_map_npcs() -> Unit {
  match map_npcs_ctx.val {
    Some({ map_npcs, .. }) => map_npcs.clear()
    None => ()
  }
  map_npcs_ctx.val = None
}

///|
/// Advance NPC runtime state once in fixed schedule.
// TODO: Split non-fixed-step logic out of this FixedUpdate system into a separate Update system function.
pub fn map_npcs_fixed_system(_world : @ecs.World) -> Unit {
  guard map_npcs_ctx.val is Some({ map_npcs, physics }) else { return }
  map_npcs.update(physics)
}

///|
/// Handle frame-based NPC pointer interactions.
pub fn map_npcs_pointer_system(_world : @ecs.World) -> Unit {
  guard map_npcs_ctx.val is Some({ map_npcs, .. }) else { return }
  map_npcs.handle_pointer_events()
}

///|
/// Opens NPC talk UI through npc module state machine.
pub fn request_quest_talk(args : TalkArgs) -> Unit {
  guard map_npcs_ctx.val is Some({ map_npcs, .. }) else { return }
  if (map_npcs.is_npc_talk_ui_open)() {
    return
  }
  (map_npcs.open_npc_talk_ui)(args)
}

///|
/// Returns anchors for all loaded NPCs in current map.
pub fn list_npc_anchors() -> Array[NpcAnchor] {
  guard map_npcs_ctx.val is Some({ map_npcs, .. }) else { return [] }
  let anchors = []
  for _, npc in map_npcs.npcs {
    anchors.push({
      oid: npc.get_oid(),
      npc_id: npc.get_npc_id(),
      entity: npc.entity,
      npc_object: npc.get_npc_object(),
      ambient_states: npc.states.copy(),
    })
  }
  anchors
}

///|
/// Starts a conversation with the nearest loaded NPC within 120 world pixels.
/// Ties are resolved by object ID so the same player position always selects
/// the same NPC. Returns `false` when no NPC is in range or a conversation is
/// already open.
///
/// # Example
/// ```moonbit nocheck
/// let opened = try_talk_near(@struct.Point(100, 200))
/// ```
pub fn try_talk_near(player_pos : @struct.Point[Int]) -> Bool {
  guard map_npcs_ctx.val is Some({ map_npcs, .. }) else { return false }
  if (map_npcs.is_npc_talk_ui_open)() {
    return false
  }
  let mut nearest_oid : Int? = None
  let mut nearest_distance = NPC_INTERACTION_RANGE + 1
  for oid, npc in map_npcs.npcs {
    if !npc.entity.is_alive() {
      continue
    }
    let distance = npc.get_npc_object().get_position().distance(player_pos)
    if distance > NPC_INTERACTION_RANGE {
      continue
    }
    let wins_tie = match nearest_oid {
      Some(current_oid) => oid < current_oid
      None => true
    }
    if distance < nearest_distance || (distance == nearest_distance && wins_tie) {
      nearest_distance = distance
      nearest_oid = Some(oid)
    }
  }
  guard nearest_oid is Some(oid) else { return false }
  guard map_npcs.npcs.get(oid) is Some(npc) else { return false }
  map_npcs.open_talk_if_idle(npc)
  @game_server.send(@server_proto.TalkToNpcMessage::{ oid, })
  true
}

///|
pub fn setup_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "spawn_npc",
    @server_proto.Opcode::SPAWN_NPC.int_value(),
    fn(json) raise {
      guard map_npcs_ctx.val is Some({ map_npcs, .. }) else { return }
      let msg : @server_proto.NpcSpawnMessage = @json.from_json(json)
      map_npcs.apply_spawn_npc_message(msg)
    },
  )
  @game_server.add_server_message_handler(
    "spawn_npc_controller",
    @server_proto.Opcode::SPAWN_NPC_C.int_value(),
    fn(json) raise {
      guard map_npcs_ctx.val is Some({ map_npcs, .. }) else { return }
      let msg : @server_proto.NpcSpawnControllerMessage = @json.from_json(json)
      map_npcs.apply_spawn_npc_controller_message(msg)
    },
  )
  @game_server.add_server_message_handler(
    "npc_dialogue",
    @server_proto.Opcode::NPC_DIALOGUE.int_value(),
    fn(json) raise {
      guard map_npcs_ctx.val is Some({ map_npcs, .. }) else { return }
      let msg : @server_proto.NpcDialogueMessage = @json.from_json(json)
      guard TalkType::from_value(msg.talk_type) is Some(talk_type) else {
        fail("unknown local NPC talk type: {msg.talk_type}")
      }
      guard Speaker::from_int(msg.speaker) is Some(speaker) else {
        fail("unknown local NPC speaker: {msg.speaker}")
      }
      handle_npc_dialogue(map_npcs.open_npc_talk_ui, {
        npcid: msg.npcid,
        t: talk_type,
        speaker,
        text: msg.text,
      })
    },
  )
}

///|
/// Apply one `SPAWN_NPC` server message to the current map NPC list.
pub fn MapNpcs::apply_spawn_npc_message(
  self : MapNpcs,
  msg : @server_proto.NpcSpawnMessage,
) -> Unit {
  self.spawn({
    oid: msg.oid,
    id: msg.id,
    position: Point(msg.x, msg.y),
    flip: msg.flip,
    fh: msg.fh,
  })
}

///|
/// Apply one `SPAWN_NPC_C` server message to the current map NPC list.
pub fn MapNpcs::apply_spawn_npc_controller_message(
  self : MapNpcs,
  msg : @server_proto.NpcSpawnControllerMessage,
) -> Unit {
  if msg.mode == 0 {
    self.remove(msg.oid)
  } else {
    self.spawn({
      oid: msg.oid,
      id: msg.id,
      position: Point(msg.x, msg.y),
      flip: msg.flip,
      fh: msg.fh,
    })
  }
}

///|
pub fn MapNpcs::MapNpcs(
  open_npc_talk_ui : (TalkArgs) -> Unit,
  is_npc_talk_ui_open : () -> Bool,
) -> MapNpcs {
  {
    open_npc_talk_ui,
    is_npc_talk_ui_open,
    npcs: Map([]),
    spawns: @queue.Queue([]),
    pointer_reader: @event.EventReader(),
  }
}

///|

///|
/// Drain queued NPC spawns and advance loaded NPCs.
///
/// # Example
/// ```moonbit nocheck
/// map_npcs.update(physics)
/// ```
///
/// # Panics
/// Panics after logging when any queued NPC's required resource closure cannot
/// be loaded.
pub fn MapNpcs::update(self : MapNpcs, physics : @physics.Physics) -> Unit {
  for ;; {
    guard self.spawns.pop() is Some(spawn) else { break }
    let oid = spawn.get_oid()
    if self.npcs.contains(oid) {
      continue
    }
    let npc = spawn.instantiate(physics) catch {
      error => {
        @log.error("failed to load required npc resources", data={
          "oid": spawn.oid,
          "npc_id": spawn.id,
          "error": error,
        })
        abort(
          "npc resource load failed: oid=\{spawn.oid}, npc_id=\{spawn.id}, error=\{error}",
        )
      }
    }
    self.npcs[oid] = npc
  }
  for _, npc in self.npcs {
    npc.update(physics)
  }
}

///|
pub fn MapNpcs::spawn(self : MapNpcs, spawn : NpcSpawn) -> Unit {
  self.spawns.push(spawn)
}

///|
pub fn MapNpcs::remove(self : MapNpcs, oid : Int) -> Unit {
  match self.npcs.get(oid) {
    Some(npc) => {
      npc.destroy()
      self.npcs.remove(oid) |> ignore
    }
    None => ()
  }
}

///|
pub fn MapNpcs::clear(self : MapNpcs) -> Unit {
  while self.spawns.pop() is Some(_) {

  }
  for _, npc in self.npcs {
    npc.destroy()
  }
  self.npcs.clear()
}

///|
fn MapNpcs::npc_by_entity(self : MapNpcs, entity : @entity.Entity) -> Npc? {
  for _, npc in self.npcs {
    if npc.entity == entity {
      return Some(npc)
    }
  }
  None
}

///|
fn MapNpcs::open_talk_if_idle(self : MapNpcs, npc : Npc) -> Unit {
  if (self.is_npc_talk_ui_open)() {
    return
  }
  match npc.talk() {
    Some(talk_args) =>
      (self.open_npc_talk_ui)({
        ..talk_args,
        talk_action: SEND_NEXT(fn(next) {
          on_npc_talk_choice(TalkChoice::SEND_NEXT(next~))
        }),
      })
    None => ()
  }
}

///|
fn MapNpcs::handle_pointer_events(self : MapNpcs) -> Unit {
  let events = @physics2d.pointer_event_bus.read(self.pointer_reader)
  let mut opened_this_frame = false
  for event in events {
    guard event.button is @inputs.MouseButton::Left else { continue }
    guard event.phase is @physics2d.PointerPhase::JustPressed else { continue }
    guard self.npc_by_entity(event.entity) is Some(npc) else { continue }
    if opened_this_frame || (self.is_npc_talk_ui_open)() {
      continue
    }
    self.open_talk_if_idle(npc)
    @game_server.send(@server_proto.TalkToNpcMessage::{ oid: npc.get_oid() })
    opened_this_frame = true
  }
}

///|
struct NpcSpawn {
  oid : Int
  id : Int
  position : @struct.Point[Int]
  flip : Bool
  fh : Int
} derive(Debug, ToJson)

///|
pub fn NpcSpawn::get_oid(self : NpcSpawn) -> Int {
  self.oid
}

///|
pub fn NpcSpawn::instantiate(
  self : NpcSpawn,
  physics : @physics.Physics,
) -> Npc raise {
  let spawnposition = physics.get_y_below(self.position)
  Npc::load(self.id, self.oid, self.flip, self.fh, spawnposition)
}

///|
/// Represents a NPC on the current map
struct Npc {
  entity : @entity.Entity
  oid : Int
  phobj : @physics.PhysicsObject
  animations : Map[String, NpcAnimation]
  animation_graph : @selene_animation.AnimationGraphHandle
  dialogue : Map[String, Array[String]]
  // talk_state : String
  states : Array[String]
  name : String
  func : String
  scripted : Bool
  // mouse_only : Bool
  npc_id : Int
  flip : Bool
  mut stance : String
  mut last_synced_stance : String?
  // control : Bool
  random : @random.Rand
}

///|
priv struct NpcVisualResource {
  animations : Map[String, NpcAnimation]
  animation_graph : @selene_animation.AnimationGraphHandle
  states : Array[String]
}

///|
let npc_visual_cache : Map[String, NpcVisualResource] = Map([])

///|
priv struct NpcAnimation {
  clip : @res.SpriteClip
  node : @selene_animation.AnimationNodeIndex
  dimensions : @struct.Point[Int]
}

///|
pub(all) struct TalkArgs {
  npc_id : Int
  speaker : Speaker
  str : String
  talk_action : TalkAction
}

///|
/// Talk action and callback
pub(all) enum TalkAction {
  SEND_YESNO((Bool?) -> Unit)
  SEND_OK((Unit?) -> Unit)
  SEND_NEXT((Unit?) -> Unit)
  SEND_PREV((Unit?) -> Unit)
  SEND_SIMPLE((Int?) -> Unit)
  SEND_NEXT_PREV((Bool?) -> Unit)
} derive(Debug)

///|
pub fn Npc::talk(self : Npc) -> TalkArgs? {
  if self.scripted {
    return None
  }
  match
    self.dialogue
    .get("d0")
    .filter(fn(strs) { !strs.is_empty() })
    .map(fn(strs) { strs[0] }) {
    Some(str) =>
      Some({
        npc_id: self.npc_id,
        talk_action: SEND_NEXT(fn(_c) {  }),
        speaker: Speaker::NPC_LEFT,
        str,
      })
    None => None
  }
}

///|
pub fn Npc::load(
  id : Int,
  o : Int,
  fl : Bool,
  f : Int,
  position : @struct.Point[Int],
) -> Npc raise {
  let entity = @entity.Entity()
  let phobj = PhysicsObject(on_pos_change=fn(pos) {
    @transform2d.set_xy(entity, pos)
  })
  let strid = @utils.stoi_left_pad0(id, 7) + ".img"
  let mut mx_path = "res://Npc/" + strid + "/mx.json"
  let mut src = @res.require_json(mx_path)
  let strsrc = @res.require_json_node("res://String/Npc.img.json", [
    id.to_string(),
  ])
  let mut mx_npc : MxNpc = @json.from_json(src)
  if mx_npc.info.link is Some(link) {
    mx_path = "res://Npc/" + link + ".img/mx.json"
    src = @res.require_json(mx_path)
    mx_npc = @json.from_json(src)
  }
  let animation_path = @res.resolve_ref(
    @res.resolve(mx_path),
    mx_npc.animations_path,
  )
  let scripted = mx_npc.info.scripted
  let dialogue = Map([])
  let mut i = 0
  while true {
    let key = "d\{i}"
    let str = match strsrc {
      Object(obj) =>
        match obj.get(key) {
          Some(String(s)) => s
          _ => ""
        }
      _ => ""
    }
    if str.is_empty() {
      break
    }
    dialogue.get_or_init(key, fn() { Array::new() }).push(str)
    i += 1
  }
  let visual = match npc_visual_cache.get(animation_path) {
    Some(visual) => visual
    None => {
      let loaded_aseprite = AnimationLoader().load(animation_path)
      let animations : Map[String, NpcAnimation] = Map([])
      let animation_graph = @selene_animation.AnimationGraph()
      let states : Array[String] = []
      for state in loaded_aseprite.list_tags() {
        let clip = loaded_aseprite.clip(state)
        animations[state] = {
          clip,
          node: animation_graph.add_clip(clip.clip),
          dimensions: clip.dimensions,
        }
        if state != "shop" {
          states.push(state)
        }
      }
      let visual = {
        animations,
        animation_graph: @selene_animation.register_animation_graph_asset(
          animation_graph,
        ),
        states,
      }
      npc_visual_cache[animation_path] = visual
      visual
    }
  }
  let name = match strsrc {
    { "name": String(s), .. } => s
    _ => ""
  }
  let func = match strsrc {
    { "func": String(s), .. } => s
    _ => ""
  }
  let npc_id = id
  let flip = !fl
  // let control = cnt
  guard visual.animations.contains("stand") else {
    fail("npc \{id} has no stand animation")
  }
  phobj.set_fhid(f)
  phobj.set_position(
    @selene_math.Vec2(position.x.to_double(), position.y.to_double()),
  )
  {
    entity,
    oid: o,
    phobj,
    animations: visual.animations,
    animation_graph: visual.animation_graph,
    // lines,
    dialogue,
    // talk_state: "d0",
    states: visual.states,
    name,
    func,
    scripted,
    // mouse_only,
    npc_id,
    flip,
    stance: "stand",
    last_synced_stance: None,
    // control,
    random: @random.Rand::new(),
  }
}

///|
// pub impl @map_object.MapObject for Npc with draw(
//   self : Npc,
//   viewx : Double,
//   viewy : Double,
//   alpha : Double,
// ) -> Unit {
//   let absp = self.base.phobj.get_absolute(viewx, viewy, alpha)
//   match self.animations.get(self.stance) {
//     Some(ani) => ani.draw(@graphics.DrawArgument::new14(absp, self.flip), alpha)
//     None => ()
//   }
//   if !(self.hide_name) {
//     self.name_label.draw(absp + Point(0, -4))
//     self.func_label.draw(absp + Point(0, 18))
//   }
// }

///|
pub fn Npc::update(self : Npc, physics : @physics.Physics) -> Unit {
  if !self.entity.is_alive() {
    return
  }
  physics.move_object(self.phobj)
  self.sync_sprite()
  if self.animations.get(self.stance) is Some(animation) &&
    @selene_animation.animation_players().get(self.entity) is Some(player) &&
    player.animation(animation.node) is Some(active) &&
    active.is_finished() &&
    !self.states.is_empty() {
    let next_stance = @randx.next_int(self.random, self.states.length())
    let new_stance = self.states[next_stance]
    if new_stance == self.stance {
      ignore(active.replay())
    } else {
      self.set_stance(new_stance)
      self.sync_sprite()
    }
  }
  self.sync_pickable()
}

///|
pub fn Npc::set_stance(self : Npc, st : String) -> Unit {
  if self.stance != st {
    self.stance = st
    self.last_synced_stance = None
  }
}

///|
fn Npc::sync_sprite(self : Npc) -> Unit {
  guard self.entity.is_alive() else { return }
  guard self.animations.get(self.stance) is Some(animation) else { return }
  let pos = self.phobj.get_position()
  let z = @graphics.map_npc_z(self.phobj.fhlayer, pos.y)
  if @sprite.sprites().get(self.entity) is None ||
    self.last_synced_stance != Some(self.stance) {
    @sprite.sprites().set(self.entity, animation.clip.sprite(flip_x=self.flip))
    @selene_animation.animation_target_ids().set(
      self.entity,
      @selene_animation.AnimationTargetId("self"),
    )
    @selene_animation.animated_bys().set(
      self.entity,
      @selene_animation.AnimatedBy(self.entity),
    )
    @selene_animation.animation_graph_handles().set(
      self.entity,
      self.animation_graph,
    )
    let player = @selene_animation.animation_players().get_or_init(
      self.entity,
      fn() { @selene_animation.AnimationPlayer() },
    )
    let transitions = @selene_animation.animation_transitions().get_or_init(
      self.entity,
      fn() { @selene_animation.AnimationTransitions() },
    )
    ignore(
      transitions.play(
        player,
        animation.node,
        0.0,
        repeat=@selene_animation.RepeatAnimation::Never,
      ),
    )
    @transform.transforms().set(
      self.entity,
      @transform.Transform::from_xyz(
        pos.x.to_double(),
        pos.y.to_double(),
        z.to_double(),
      ),
    )
    self.last_synced_stance = Some(self.stance)
  } else {
    match @transform.transforms().get(self.entity) {
      Some(current) =>
        @transform.transforms().set(self.entity, {
          ..current,
          translation: @selene_math.Vec3(
            current.translation.x,
            current.translation.y,
            z.to_double(),
          ),
        })
      None =>
        @transform.transforms().set(
          self.entity,
          @transform.Transform::from_xyz(0.0, 0.0, z.to_double()),
        )
    }
  }
}

///|
fn Npc::click_rect(self : Npc) -> (@selene_math.Vec2, @selene_math.Vec2)? {
  guard self.animations.get(self.stance) is Some(animation) else { return None }
  let width = animation.dimensions.x.to_double()
  let height = animation.dimensions.y.to_double()
  Some(
    (@selene_math.Vec2(width, height), @selene_math.Vec2(-width / 2.0, -height)),
  )
}

///|
fn Npc::sync_pickable(self : Npc) -> Unit {
  guard self.entity.is_alive() else { return }
  guard self.click_rect() is Some((size, offset)) else { return }
  if @physics2d.pickables().get(self.entity) is None {
    @physics2d.pickables().set(self.entity, @physics2d.Pickable::{
      active: true,
    })
  } else if @physics2d.pickables().get(self.entity) is Some(pickable) {
    pickable.active = true
  }
  @physics2d.shapes().set(
    self.entity,
    @physics2d.CollisionShape::Rect(size~, offset~),
  )
}

///|
pub fn Npc::is_scripted(self : Npc) -> Bool {
  self.scripted
}

///|
pub fn Npc::get_name(self : Npc) -> String {
  self.name
}

///|
pub fn Npc::get_func(self : Npc) -> String {
  self.func
}

///|
pub fn Npc::get_oid(self : Npc) -> Int {
  self.oid
}

///|

///|
pub fn Npc::destroy(self : Npc) -> Unit {
  @graphics.clear_sprite_animation(self.entity)
  @transform.transforms().remove(self.entity) |> ignore
  @physics2d.pickables().remove(self.entity)
  @physics2d.shapes().remove(self.entity)
  if self.entity.is_alive() {
    self.entity.destroy()
  }
}

///|

///|
pub fn Npc::get_npc_object(self : Npc) -> @physics.MovingObject {
  self.phobj.moving_object
}

///|
pub fn Npc::get_npc_id(self : Npc) -> Int {
  self.npc_id
}

///|

///|
using @physics {type PhysicsObject}

///|
using @res {type AnimationLoader}
