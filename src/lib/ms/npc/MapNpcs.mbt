///|
struct MapNpcs {
  open_npc_talk_ui : (TalkArgs) -> Unit
  npcs : Map[Int, Npc]
  loading_npcs : Array[@utils.Future[Result[Npc, Error]]]
  spawns : @queue.Queue[NpcSpawn]
  npc_loader : @resource.AsyncLoader
  string_loader : @resource.AsyncLoader
}

///|
pub(all) struct MapNpcsContext {
  map_npcs : MapNpcs
  physics : @physics.Physics
}

///|
let map_npcs_ctx : Ref[MapNpcsContext?] = Ref::new(None)

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
pub fn map_npcs_system(_delta : Double) -> Unit {
  guard map_npcs_ctx.val is Some({ map_npcs, physics }) else { return }
  let times = @logic_fps.get_logic_times()
  for i = 0; i < times; i = i + 1 {
    map_npcs.update(physics)
  }
  let mouse_pos = @inputs.mouse.pos
  let cursor_pos = @struct.Point::new(
    mouse_pos[@selene_math.X].to_int(),
    mouse_pos[@selene_math.Y].to_int(),
  )
  let camera_pos = @camera.get_position()
  let view_pos = @struct.Point::new(
    -camera_pos[@selene_math.X].to_int(),
    -camera_pos[@selene_math.Y].to_int(),
  )
  let pressed = @inputs.is_mouse_just_pressed(@inputs.MouseButton::Left)
  match map_npcs.send_cursor(pressed, cursor_pos, view_pos) {
    Some(@ui.CursorState::CAN_CLICK) =>
      @cursor.request_cursor_state(@ui.CursorState::CAN_CLICK)
    _ => ()
  }
}

///|
pub fn setup_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "spawn_npc",
    @net.Opcode::SPAWN_NPC.int_value(),
    fn(json) raise {
      guard map_npcs_ctx.val is Some({ map_npcs, .. }) else { return }
      let msg : @server_proto.NpcSpawnMessage = @json.from_json(json)
      map_npcs.apply_spawn_npc_message(msg)
    },
  )
  @game_server.add_server_message_handler(
    "spawn_npc_controller",
    @net.Opcode::SPAWN_NPC_C.int_value(),
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
  npc_loader~ : @resource.AsyncLoader,
  string_loader~ : @resource.AsyncLoader,
) -> MapNpcs {
  {
    open_npc_talk_ui,
    npcs: Map::new(),
    loading_npcs: Array::new(),
    spawns: @queue.new(),
    npc_loader,
    string_loader,
  }
}

///|

///|
pub fn MapNpcs::update(self : MapNpcs, physics : @physics.Physics) -> Unit {
  for ;; {
    guard self.spawns.pop() is Some(spawn) else { break }
    let oid = spawn.get_oid()
    if not(self.npcs.contains(oid)) {
      self.loading_npcs.push(
        @io_service.submit_background_task(async fn() {
          spawn.instantiate(self.npc_loader, self.string_loader, physics)
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
pub fn MapNpcs::send_cursor(
  self : MapNpcs,
  pressed : Bool,
  position : @struct.Point[Int],
  viewpos : @struct.Point[Int],
) -> @ui.CursorState? {
  for _, map_object in self.npcs {
    let npc = map_object
    if npc.entity.is_alive() && npc.inrange(position, viewpos) {
      if pressed {
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
        @game_server.send(@server_proto.TalkToNpcMessage::{ oid: npc.get_oid() })
        return Some(@ui.CursorState::IDLE)
      }
      return Some(@ui.CursorState::CAN_CLICK)
    }
  }
  None
}

///|
struct NpcSpawn {
  oid : Int
  id : Int
  position : @struct.Point[Int]
  flip : Bool
  fh : Int
} derive(Show, ToJson)

///|
pub fn NpcSpawn::get_oid(self : NpcSpawn) -> Int {
  self.oid
}

///|
pub async fn NpcSpawn::instantiate(
  self : NpcSpawn,
  npc_loader : @resource.AsyncLoader,
  string_loader : @resource.AsyncLoader,
  physics : @physics.Physics,
) -> Npc {
  let spawnposition = physics.get_y_below(self.position)
  Npc::load(
    npc_loader,
    string_loader,
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
  selene : @sprite.Animation
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
  SEND_SIMPLE((Int?) -> Unit) // select option
  SEND_NEXT_PREV((Bool?) -> Unit) // next or prev
} derive(Show)

///|
pub fn Npc::talk(self : Npc) -> TalkArgs? {
  if self.scripted {
    return None
  }
  match
    self.dialogue
    .get("d0")
    .filter(fn(strs) { not(strs.is_empty()) })
    .map(fn(strs) { strs[0] }) {
    Some(str) =>
      Some({
        npc_id: self.npc_id,
        talk_action: SEND_NEXT(fn(_c) {  }), // TODO: init outside
        speaker: Speaker::NPC_LEFT,
        str,
      })
    None => None
  }
}

///|
pub async fn Npc::load(
  npc_loader : @resource.AsyncLoader,
  string_loader : @resource.AsyncLoader,
  id : Int,
  o : Int,
  fl : Bool,
  f : Int,
  position : @struct.Point[Int],
) -> Npc {
  let entity = @entity.Entity::new()
  let phobj = @physics.PhysicsObject::new(on_pos_change=fn(pos) {
    @position.positions.set(entity, @position.Position(pos))
  })
  let strid = @utils.stoi_left_pad0(id, 7) + ".img"
  let mut src = npc_loader.load_res_async([strid])
  let strsrc = string_loader.load_res_async(["Npc.img", id.to_string()])
  let link = src["info"]["link"].get_string()
  if not(link.is_empty()) {
    src = npc_loader.load_res_async([link + ".img"])
  }
  let info = src["info"]
  ignore(info["hideName"].get_bool() catch { _ => panic() })
  // let mouse_only = info["talkMouseOnly"].get_bool?().unwrap()
  let scripted = (not(info["script"].is_null()) || info["shop"].get_bool()) catch {
    _ => panic()
  }
  let dialogue = {}
  let mut i = 0
  while true {
    let key = "d\{i}"
    let str = strsrc[key].get_string()
    if str.is_empty() {
      break
    }
    dialogue.get_or_init(key, fn() { Array::new() }).push(str)
    i += 1
  }
  let animations = {}
  let states = []
  let lines = {}
  for npcnode in src {
    let state = npcnode.name()
    if state != "info" {
      let nx_anim : @resource.NxAnimation = @json.from_json(npcnode.value()) catch {
        _ => panic()
      }
      let selene = @resource.nx_animation_to_selene_animation(
        nx_anim,
        loop_=true,
      )
      animations[state] = {
        selene,
        duration_ms: nx_animation_duration_ms(nx_anim),
        dimensions: nx_animation_dimensions(nx_anim),
      }
      states.push(state)
    }
    for speaknode in npcnode["speak"] {
      lines
      .get_or_init(state, fn() { Array::new() })
      .push(strsrc[speaknode.get_string()].get_string())
    }
  }
  let name = strsrc["name"].get_string()
  let func = strsrc["func"].get_string()
  let npc_id = id
  let flip = not(fl)
  // let control = cnt
  let stance = "stand"
  phobj.set_fhid(f)
  phobj.set_position(
    @selene_math.Vec2D(position.x.to_double(), position.y.to_double()),
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
//   if not(self.hide_name) {
//     self.name_label.draw(absp + @struct.Point::new(0, -4))
//     self.func_label.draw(absp + @struct.Point::new(0, 18))
//   }
// }

///|
pub fn Npc::update(self : Npc, physics : @physics.Physics) -> Unit {
  if not(self.entity.is_alive()) {
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
const NPC_ZINDEX_OFFSET = 4

///|
fn Npc::sync_sprite(self : Npc) -> Unit {
  guard self.entity.is_alive() else { return }
  guard self.animations.get(self.stance) is Some(animation) else { return }
  let z = @graphics.OBJECT_TILE_LAYER_ZINDEX +
    self.phobj.fhlayer +
    NPC_ZINDEX_OFFSET
  let transform = if self.flip {
    @selene_math.Transform::from_scale(-1.0, 1.0)
  } else {
    @selene_math.Transform::new()
  }
  if @sprite.sprites.get(self.entity) is None ||
    self.last_synced_stance != Some(self.stance) {
    let sprite = @sprite.Sprite::from_animation(animation.selene, z, transform~)
    @sprite.sprites.set(self.entity, sprite)
    self.last_synced_stance = Some(self.stance)
  } else {
    match @sprite.sprites.get(self.entity) {
      Some(sprite) => @sprite.sprites.set(self.entity, { ..sprite, zindex: z })
      None => ()
    }
  }
}

///|
pub fn Npc::is_scripted(self : Npc) -> Bool {
  self.scripted
}

///|
pub fn Npc::inrange(
  self : Npc,
  cursorpos : @struct.Point[Int],
  viewpos : @struct.Point[Int],
) -> Bool {
  if not(self.entity.is_alive()) {
    return false
  }
  let absp = self.phobj.get_position() + viewpos
  let dim = self.animations
    .get(self.stance)
    .map(fn(animation) { animation.dimensions })
    .unwrap_or_default()
  @struct.Rectangle::from4(
    absp.x - dim.x / 2,
    absp.x + dim.x / 2,
    absp.y - dim.y,
    absp.y,
  ).contains(cursorpos)
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
  @sprite.sprites.remove(self.entity)
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
fn nx_frame_delay_ms(frame : @resource.NxFrame) -> Int {
  match frame.delay {
    Some(delay) => if delay <= 0 { 100 } else { delay }
    None => 100
  }
}

///|
fn nx_animation_duration_ms(animation : @resource.NxAnimation) -> Int {
  let base = animation.frames.fold(init=0, fn(acc, frame) {
    acc + nx_frame_delay_ms(frame)
  })
  if animation.zigzag && animation.frames.length() > 2 {
    let mut zigzag_extra = 0
    for i = animation.frames.length() - 2; i >= 1; i = i - 1 {
      zigzag_extra += nx_frame_delay_ms(animation.frames[i])
    }
    base + zigzag_extra
  } else {
    base
  }
}

///|
fn nx_animation_dimensions(
  animation : @resource.NxAnimation,
) -> @struct.Point[Int] {
  let mut width = 0
  let mut height = 0
  for frame in animation.frames {
    width = @cmp.maximum(width, frame.texture.w)
    height = @cmp.maximum(height, frame.texture.h)
  }
  @struct.Point::new(width, height)
}
