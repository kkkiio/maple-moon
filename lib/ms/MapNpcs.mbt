typealias Physics = @physics.Physics

typealias Rectangle[T] = @struct.Rectangle[T]

typealias Animation = @graphics.Animation

struct MapNpcs {
  npcs : @map_object.MapObjects[Npc]
  spawns : @queue.T[NpcSpawn]
}

pub fn MapNpcs::new() -> MapNpcs {
  { npcs: @map_object.MapObjects::new(), spawns: @queue.new() }
}

/// Packet which requests a dialog with a server-sided NPC
fn new_talk_to_npc_packet(oid : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::TALK_TO_NPC)..write_int(oid)
}

fn draw(
  self : MapNpcs,
  layer : @layer.Id,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  self.npcs.draw(layer, viewx, viewy, alpha)
}

pub fn update(self : MapNpcs, physics : Physics) -> Unit {
  loop self.spawns.pop() {
    Some(spawn) => {
      let oid = spawn.get_oid()
      match self.npcs.get(oid) {
        Some(npc) => npc.makeactive()
        None => self.npcs.add(spawn.instantiate(physics))
      }
      continue self.spawns.pop()
    }
    None => break
  }
  self.npcs.update(physics)
}

pub fn spawn(self : MapNpcs, spawn : NpcSpawn) -> Unit {
  self.spawns.push(spawn)
}

pub fn remove(self : MapNpcs, oid : Int) -> Unit {
  match self.npcs.get(oid) {
    Some(npc) => npc.deactivate()
    None => ()
  }
}

pub fn clear(self : MapNpcs) -> Unit {
  self.npcs.clear()
}

pub fn send_cursor(
  self : MapNpcs,
  pressed : Bool,
  position : Point[Int],
  viewpos : Point[Int]
) -> CursorState {
  for _, map_object in self.npcs {
    let npc = map_object
    if npc.is_active() && npc.inrange(position, viewpos) {
      if pressed {
        npc.talk(
          fn(id, msgtype, b0, b1, speaker, str) {
            let ui = UINpcTalk::new()
            UI::get().set_element(ui)
            ui.change_text?(id, msgtype, b0, b1, speaker, str).unwrap()
          },
        )
        new_talk_to_npc_packet(npc.get_oid()).dispatch()
        return CursorState::IDLE
      }
      return CursorState::CAN_CLICK
    }
  }
  if pressed {
    CursorState::CLICKING
  } else {
    CursorState::IDLE
  }
}

struct NpcSpawn {
  oid : Int
  id : Int
  position : Point[Int]
  flip : Bool
  fh : Int
}

pub fn get_oid(self : NpcSpawn) -> Int {
  self.oid
}

pub fn instantiate(self : NpcSpawn, physics : Physics) -> Npc {
  let spawnposition = physics.get_y_below(self.position)
  Npc::new(self.id, self.oid, self.flip, self.fh, false, spawnposition)
}

/// Represents a NPC on the current map
struct Npc {
  base : @map_object.MapObjectBase
  animations : Map[String, Animation]
  lines : Map[String, Array[String]]
  dialogue : Map[String, Array[String]]
  talk_state : String
  states : Array[String]
  name : String
  func : String
  hide_name : Bool
  scripted : Bool
  mouse_only : Bool
  npc_id : Int
  flip : Bool
  mut stance : String
  control : Bool
  random : @utils.Randomizer
  // name_label:Text
  // func_label:Text
}

pub fn talk(
  self : Npc,
  talk_func : (Int, Int, Int, Int, Int, String) -> Unit
) -> Unit {
  if self.scripted {
    return
  }
  match
    self.dialogue["d0"]
    .filter(fn(strs) { strs.is_empty().not() })
    .map(fn(strs) { strs[0] }) {
    Some(str) => talk_func(self.npc_id, 0, 0, 1, 0, str)
    None => ()
  }
}

pub fn Npc::new(
  id : Int,
  o : Int,
  fl : Bool,
  f : Int,
  cnt : Bool,
  position : Point[Int]
) -> Npc {
  let base = @map_object.MapObjectBase::new(o)
  let strid = @string_format.extend_id(id, 7) + ".img"
  let mut src = npc_loader().load_res([strid])
  let strsrc = @resource.string_loader().load_res(["Npc.img", id.to_string()])
  let link = src["info"]["link"].get_string()
  if link.is_empty().not() {
    src = npc_loader().load_res([link + ".img"])
  }
  let info = src["info"]
  let hide_name = info["hideName"].get_bool?().unwrap()
  let mouse_only = info["talkMouseOnly"].get_bool?().unwrap()
  let scripted = info["script"].is_null().not() ||
    info["shop"].get_bool?().unwrap()
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
  src.each(
    fn(npcnode) {
      let state = npcnode.name()
      if state != "info" {
        animations[state] = npcnode |> Animation::from_resource
        states.push(state)
      }
      npcnode["speak"].each(
        fn(speaknode) {
          lines
          .get_or_init(state, fn() { Array::new() })
          .push(strsrc[speaknode.get_string()].get_string())
        },
      )
    },
  )
  let name = strsrc["name"].get_string()
  let func = strsrc["func"].get_string()
  let npc_id = id
  let flip = fl.not()
  let control = cnt
  let stance = "stand"
  base.phobj.fhid = f
  base.set_position(position)
  {
    base,
    animations,
    lines,
    dialogue,
    talk_state: "d0",
    states,
    name,
    func,
    hide_name,
    scripted,
    mouse_only,
    npc_id,
    flip,
    stance,
    control,
    random: @utils.Randomizer::default(),
  }
}

pub fn draw(self : Npc, viewx : Double, viewy : Double, alpha : Double) -> Unit {
  let absp = self.base.phobj.get_absolute(viewx, viewy, alpha)
  match self.animations.get(self.stance) {
    Some(ani) => ani.draw(DrawArgument::new5(absp, self.flip), alpha)
    None => ()
  }
  if self.hide_name.not() {
    // self.name_label.draw(absp + Point(0, -4))
    // self.func_label.draw(absp + Point(0, 18))
  }
}

pub fn update(self : Npc, physics : Physics) -> Int {
  if self.base.active.not() {
    return self.base.phobj.fhlayer
  }
  physics.move_object(self.base.phobj)
  match self.animations.get(self.stance) {
    Some(ani) => {
      let aniend = ani.update()
      if aniend && self.states.length() > 0 {
        let next_stance = self.random.next_int(self.states.length())
        let new_stance = self.states[next_stance]
        self.set_stance(new_stance)
      }
    }
    None => ()
  }
  self.base.phobj.fhlayer
}

pub fn set_stance(self : Npc, st : String) -> Unit {
  if self.stance != st {
    self.stance = st
    match self.animations.get(st) {
      Some(ani) => ani.reset()
      None => ()
    }
  }
}

pub fn is_scripted(self : Npc) -> Bool {
  self.scripted
}

pub fn inrange(
  self : Npc,
  cursorpos : Point[Int],
  viewpos : Point[Int]
) -> Bool {
  if self.base.active.not() {
    return false
  }
  let absp = self.base.get_position() + viewpos
  let dim = self.animations[self.stance]
    .map(fn(ani) { ani.get_dimensions() })
    .or_default()
  Rectangle::from4(
    absp.x - dim.x / 2,
    absp.x + dim.x / 2,
    absp.y - dim.y,
    absp.y,
  ).contains(cursorpos)
}

pub fn get_name(self : Npc) -> String {
  self.name
}

pub fn get_func(self : Npc) -> String {
  self.func
}

pub fn get_oid(self : Npc) -> Int {
  self.base.get_oid()
}

pub fn makeactive(self : Npc) -> Unit {
  self.base.makeactive()
}

pub fn deactivate(self : Npc) -> Unit {
  self.base.deactivate()
}

pub fn is_active(self : Npc) -> Bool {
  self.base.is_active()
}

pub fn get_layer(self : Npc) -> Int {
  self.base.get_layer()
}

fn npc_loader() -> @resource.Loader {
  @resource.Loader::new("npc")
}

struct SpawnNpcHandler {} derive(Default)

pub fn SpawnNpcHandler::new() -> SpawnNpcHandler {
  SpawnNpcHandler::default()
}

pub fn handle(self : SpawnNpcHandler, recv : @net.InPacket) -> Unit! {
  let oid = recv.read_int!()
  let id = recv.read_int!()
  let position = recv.read_point!()
  let flip = recv.read_bool!()
  let fh = recv.read_ushort!()
  recv.read_short!() |> ignore // 'rx'
  recv.read_short!() |> ignore // 'ry'
  Stage::get().get_npcs().spawn({ oid, id, position, flip, fh })
}

struct SpawnNpcControllerHandler {} derive(Default)

pub fn SpawnNpcControllerHandler::new() -> SpawnNpcControllerHandler {
  SpawnNpcControllerHandler::default()
}

pub fn handle(self : SpawnNpcControllerHandler, recv : @net.InPacket) -> Unit! {
  let mode = recv.read_byte!()
  let oid = recv.read_int!()
  if mode == 0 {
    Stage::get().get_npcs().remove(oid)
  } else {
    let id = recv.read_int!()
    let position = recv.read_point!()
    let flip = recv.read_bool!()
    let fh = recv.read_ushort!()
    recv.read_short!() |> ignore // 'rx'
    recv.read_short!() |> ignore // 'ry'
    recv.read_bool!() |> ignore // 'minimap'
    Stage::get().get_npcs().spawn({ oid, id, position, flip, fh })
  }
}

struct NpcDialogueHandler {
  ui : UI
}

pub fn NpcDialogueHandler::new(ui : UI) -> NpcDialogueHandler {
  { ui, }
}

pub fn handle(self : NpcDialogueHandler, recv : @net.InPacket) -> Unit! {
  recv.skip!(1)
  let npcid = recv.read_int!()
  let msgtype = recv.read_byte!() // 0 - textonly, 1 - yes/no, 4 - selection, 12 - accept/decline
  let speaker = recv.read_byte!()
  let text = recv.read_string!()
  let (style_b0, style_b1) = if recv.available() && msgtype == 0 {
    // {b0, b1}
    // {0, 1} = next
    // {1, 0} = prev
    // {1, 1} = nextPrev
    // {0, 0} = ok
    (recv.read_ubyte!(), recv.read_ubyte!())
  } else {
    (0, 0)
  }
  let ui = UINpcTalk::new()
  self.ui.set_element(ui)
  self.ui.enable()
  ui.change_text!(npcid, msgtype, style_b0, style_b1, speaker, text)
}
