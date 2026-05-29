///|
struct MapNpcs {
  open_npc_talk_ui : (TalkArgs) -> Unit
  is_npc_talk_ui_open : () -> Bool
  npcs : Map[Int, Npc]
  loading_npcs : Array[@utils.Future[Result[Npc, Error]]]
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
}

///|
let map_npcs_ctx : Ref[MapNpcsContext?] = Ref(None)

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
    })
  }
  anchors
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
    position: @struct.Point::new(msg.x, msg.y),
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
      position: @struct.Point::new(msg.x, msg.y),
      flip: msg.flip,
      fh: msg.fh,
    })
  }
}

///|
pub fn MapNpcs::new(
  open_npc_talk_ui : (TalkArgs) -> Unit,
  is_npc_talk_ui_open : () -> Bool,
) -> MapNpcs {
  {
    open_npc_talk_ui,
    is_npc_talk_ui_open,
    npcs: Map([]),
    loading_npcs: Array::new(),
    spawns: @queue.Queue([]),
    pointer_reader: @event.EventReader(),
  }
}

///|

///|
pub fn MapNpcs::update(self : MapNpcs, physics : @physics.Physics) -> Unit {
  for ;; {
    guard self.spawns.pop() is Some(spawn) else { break }
    let oid = spawn.get_oid()
    if !self.npcs.contains(oid) {
      self.loading_npcs.push(
        @io_service.submit_background_task(fn() {
          spawn.instantiate(physics)
        }),
      )
    }
  }
  self.loading_npcs.retain(fn(future) {
    guard future.poll() is Some(rs) else { return true }
    match rs {
      Ok(npc) => self.npcs.set(npc.get_oid(), npc)
      Err(e) =>
        @log.error("failed to load npc", data={ "error": e.to_string() })
    }
    false
  })
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
  self.loading_npcs.clear()
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
  Npc::load(
    self.id,
    self.oid,
    self.flip,
    self.fh,
    spawnposition,
  )
}

///|
/// Represents a NPC on the current map
struct Npc {
  entity : @entity.Entity
  oid : Int
  phobj : @physics.PhysicsObject
  animations : Map[String, NpcAnimation]
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
  mut stance_elapsed_ms : Int
  mut last_synced_stance : String?
  // control : Bool
  random : @random.Rand
}

///|
priv struct NpcAnimation {
  clip : @resource.SeleneClip
  duration_ms : Int
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
  let phobj = @physics.PhysicsObject::new(on_pos_change=fn(pos) {
    @transform2d.set_xy(entity, pos)
  })
  let strid = @utils.stoi_left_pad0(id, 7) + ".img"
  let mut mx_path = "assets/Npc/Npc/" + strid + "/mx.json"
  let mut src = @resource.require_json(mx_path)
  let strsrc = @resource.json_navigate("assets/String/Npc.img.json", [id.to_string()])
  let mut mx_npc : MxNpc = @json.from_json(src) catch {
    _ => abort("invalid npc mx data: " + mx_path)
  }
  if mx_npc.info.link is Some(link) {
    mx_path = "assets/Npc/Npc/" + link + ".img/mx.json"
    src = @resource.require_json(mx_path)
    mx_npc = @json.from_json(src) catch {
      _ => abort("invalid linked npc mx data: " + mx_path)
    }
  }
  let animation_loader = @resource.AnimationLoader::new()
  let loaded_aseprite = animation_loader.load(
    @resource.resolve_ref(
      mx_path,
      mx_npc.animations_path,
    ),
  )
  let scripted = mx_npc.info.scripted
  let dialogue = {}
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
  let animations : Map[String, NpcAnimation] = {}
  let states : Array[String] = []
  for state in loaded_aseprite.list_tags() {
    let clip = loaded_aseprite.clip(state) catch {
      _ => abort("npc \{id} missing animation state: \{state}")
    }
    animations[state] = {
      clip,
      duration_ms: clip.duration_ms,
      dimensions: clip.dimensions,
    }
    states.push(state)
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
  let stance = if states.contains("stand") {
    "stand"
  } else if !states.is_empty() {
    states[0]
  } else {
    abort("npc \{id} has no animation states")
  }
  phobj.set_fhid(f)
  phobj.set_position(
    @selene_math.Vec2(position.x.to_double(), position.y.to_double()),
  )
  {
    entity,
    oid: o,
    phobj,
    animations,
    // lines,
    dialogue,
    // talk_state: "d0",
    states,
    name,
    func,
    scripted,
    // mouse_only,
    npc_id,
    flip,
    stance,
    stance_elapsed_ms: 0,
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
//     self.name_label.draw(absp + @struct.Point::new(0, -4))
//     self.func_label.draw(absp + @struct.Point::new(0, 18))
//   }
// }

///|
pub fn Npc::update(self : Npc, physics : @physics.Physics) -> Unit {
  if !self.entity.is_alive() {
    return
  }
  physics.move_object(self.phobj)
  match self.animations.get(self.stance) {
    Some(animation) => {
      self.stance_elapsed_ms += @logic_fps.STEP_TIME_MS
      if animation.duration_ms > 0 &&
        self.stance_elapsed_ms >= animation.duration_ms &&
        self.states.length() > 0 {
        let next_stance = @randx.next_int(self.random, self.states.length())
        let new_stance = self.states[next_stance]
        self.set_stance(new_stance)
      }
    }
    None => ()
  }
  self.sync_sprite()
  self.sync_pickable()
}

///|
pub fn Npc::set_stance(self : Npc, st : String) -> Unit {
  if self.stance != st {
    self.stance = st
    self.stance_elapsed_ms = 0
    self.last_synced_stance = None
  }
}

///|
fn Npc::sync_sprite(self : Npc) -> Unit {
  guard self.entity.is_alive() else { return }
  guard self.animations.get(self.stance) is Some(animation) else { return }
  let pos = self.phobj.get_position()
  let z = @graphics.map_npc_z(self.phobj.fhlayer, pos.y)
  let transform = if self.flip {
    @selene_math.Transform::from_scale(-1.0, 1.0)
  } else {
    @selene_math.Transform()
  }
  if @sprite.sprites().get(self.entity) is None ||
    self.last_synced_stance != Some(self.stance) {
    ignore(transform)
    ignore(z)
    play_aseprite_clip(self.entity, animation.clip, self.flip)
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
fn play_aseprite_clip(
  entity : @entity.Entity,
  clip : @resource.SeleneClip,
  flip_x : Bool,
) -> Unit {
  @selene_animation.animation_target_ids().set(
    entity,
    @selene_animation.AnimationTargetId("self"),
  )
  @selene_animation.animated_bys().set(
    entity,
    @selene_animation.AnimatedBy(entity),
  )
  @selene_animation.animation_graph_handles().set(entity, clip.graph)
  let player = @selene_animation.animation_players().get_or_init(entity, fn() {
    @selene_animation.AnimationPlayer()
  })
  ignore(
    player.play(clip.node, repeat=@selene_animation.RepeatAnimation::Forever),
  )

  let anchor = if flip_x { mirror_anchor_x(clip.anchor) } else { clip.anchor }
  match @sprite.sprites().get(entity) {
    Some(sprite) =>
      @sprite.sprites().set(entity, {
        ..sprite,
        image: Some(clip.image),
        texture_atlas: Some(@sprite.TextureAtlas(clip.layout)),
        anchor,
        flip_x,
      })
    None =>
      @sprite.sprites().set(
        entity,
        @sprite.Sprite(
          image=Some(clip.image),
          texture_atlas=Some(@sprite.TextureAtlas(clip.layout)),
          anchor~,
          flip_x~,
        ),
      )
  }
}

///|
fn mirror_anchor_x(anchor : @sprite.Anchor) -> @sprite.Anchor {
  let @sprite.Anchor(v) = anchor
  @sprite.Anchor(@selene_math.Vec2(-v.0, v.1))
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
  if @selene_animation.animation_players().get(self.entity) is Some(player) {
    ignore(player.stop_all())
  }
  @selene_animation.animation_graph_handles().remove(self.entity)
  @selene_animation.animation_target_ids().remove(self.entity)
  @selene_animation.animated_bys().remove(self.entity)
  @sprite.sprites().remove(self.entity)
  @physics2d.pickables().remove(self.entity)
  @physics2d.shapes().remove(self.entity)
  self.entity.destroy()
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
