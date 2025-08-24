///|
struct MapNpcs {
  open_npc_talk_ui : (TalkArgs) -> Unit
  npcs : @map_object.MapObjects[Npc]
  spawns : @queue.T[NpcSpawn]
  packet_processor : @net.Network
  npc_loader : @resource.SyncLoader
  string_loader : @resource.SyncLoader
}

///|
pub fn MapNpcs::new(
  open_npc_talk_ui : (TalkArgs) -> Unit,
  packet_processor : @net.Network,
  npc_loader~ : @resource.SyncLoader,
  string_loader~ : @resource.SyncLoader
) -> MapNpcs {
  {
    open_npc_talk_ui,
    npcs: @map_object.MapObjects::new(),
    spawns: @queue.new(),
    packet_processor,
    npc_loader,
    string_loader,
  }
}

///|
priv struct TalkToNpcPacket {
  oid : Int
} derive(Show)

///| Packet which requests a dialog with a server-sided NPC
fn TalkToNpcPacket::new(oid : Int) -> TalkToNpcPacket {
  { oid, }
}

///|
impl @net.OutMessage for TalkToNpcPacket with pack(self) {
  let p = @net.OutPacket::new(@net.ClientOpcode::TALK_TO_NPC)
  p.write_int(self.oid)
  p
}

///|
pub fn MapNpcs::draw(
  self : MapNpcs,
  layer : @map_layer.Id,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  self.npcs.draw(layer, viewx, viewy, alpha)
}

///|
pub fn update(self : MapNpcs, physics : @physics.Physics) -> Unit {
  loop self.spawns.pop() {
    Some(spawn) => {
      let oid = spawn.get_oid()
      match self.npcs.get(oid) {
        Some(npc) => npc.makeactive()
        None =>
          self.npcs.add(
            spawn.instantiate(self.npc_loader, self.string_loader, physics),
          )
      }
      continue self.spawns.pop()
    }
    None => break
  }
  self.npcs.update(physics)
}

///|
pub fn spawn(self : MapNpcs, spawn : NpcSpawn) -> Unit {
  self.spawns.push(spawn)
}

///|
pub fn remove(self : MapNpcs, oid : Int) -> Unit {
  match self.npcs.get(oid) {
    Some(npc) => npc.deactivate()
    None => ()
  }
}

///|
pub fn clear(self : MapNpcs) -> Unit {
  self.npcs.clear()
}

///|
pub fn MapNpcs::send_cursor(
  self : MapNpcs,
  pressed : Bool,
  position : @struct.Point[Int],
  viewpos : @struct.Point[Int]
) -> @ui.CursorState? {
  for _, map_object in self.npcs {
    let npc = map_object
    if npc.is_active() && npc.inrange(position, viewpos) {
      if pressed {
        match npc.talk() {
          Some(talk_args) =>
            (self.open_npc_talk_ui)({
              ..talk_args,
              talk_action: SEND_NEXT(fn(next) {
                on_npc_talk_choice(
                  self.packet_processor,
                  TalkChoice::SEND_NEXT(next~),
                )
              }),
            })
          None => ()
        }
        self.packet_processor.send_message(TalkToNpcPacket::new(npc.get_oid()))
        return Some(@ui.CursorState::IDLE)
      }
      return Some(@ui.CursorState::CAN_CLICK)
    }
  }
  None
}

///|
pub fn MapNpcs::listen_npc_changes(
  self : MapNpcs,
  listener : (@map_object.MapObjectEvent[Npc]) -> Bool
) -> Unit {
  self.npcs.listen_object_changes(listener)
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
pub fn get_oid(self : NpcSpawn) -> Int {
  self.oid
}

///|
pub fn NpcSpawn::instantiate(
  self : NpcSpawn,
  npc_loader : @resource.SyncLoader,
  string_loader : @resource.SyncLoader,
  physics : @physics.Physics
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

///| Represents a NPC on the current map
struct Npc {
  base : @map_object.MapObjectBase
  animations : Map[String, @graphics.Animation]
  dialogue : Map[String, Array[String]]
  // talk_state : String
  states : Array[String]
  name : String
  func : String
  hide_name : Bool
  scripted : Bool
  // mouse_only : Bool
  npc_id : Int
  flip : Bool
  mut stance : String
  // control : Bool
  random : @utils.Randomizer
  name_label : @graphics.Text
  func_label : @graphics.Text
}

///|
pub(all) struct TalkArgs {
  npc_id : Int
  speaker : Speaker
  str : String
  talk_action : TalkAction
}

///| Talk action and callback
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
pub fn Npc::load(
  npc_loader : @resource.SyncLoader,
  string_loader : @resource.SyncLoader,
  id : Int,
  o : Int,
  fl : Bool,
  f : Int,
  position : @struct.Point[Int]
) -> Npc {
  let base = @map_object.MapObjectBase::new(o)
  let strid = @string_format.extend_id(id, 7) + ".img"
  let mut src = npc_loader.load_res([strid])
  let strsrc = string_loader.load_res(["Npc.img", id.to_string()])
  let link = src["info"]["link"].get_string()
  if not(link.is_empty()) {
    src = npc_loader.load_res([link + ".img"])
  }
  let info = src["info"]
  let hide_name = info["hideName"].get_bool?().unwrap()
  // let mouse_only = info["talkMouseOnly"].get_bool?().unwrap()
  let scripted = not(info["script"].is_null()) ||
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
  for npcnode in src {
    let state = npcnode.name()
    if state != "info" {
      animations[state] = npcnode |> @graphics.Animation::from_resource
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
  base.phobj.fhid = f
  base.set_position(position)
  let name_label = @graphics.Text::new(
    @graphics.FontId::A13B,
    @graphics.TextAlignment::CENTER,
    @struct.ColorName::YELLOW,
    text=name,
    nametag=true,
  )
  let func_label = @graphics.Text::new(
    @graphics.FontId::A13B,
    @graphics.TextAlignment::CENTER,
    @struct.ColorName::YELLOW,
    text=func,
    nametag=true,
  )
  {
    base,
    animations,
    // lines,
    dialogue,
    // talk_state: "d0",
    states,
    name,
    func,
    hide_name,
    scripted,
    // mouse_only,
    npc_id,
    flip,
    stance,
    // control,
    random: @utils.Randomizer::new(),
    name_label,
    func_label,
  }
}

///|
pub impl @map_object.MapObject for Npc with draw(
  self : Npc,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  let absp = self.base.phobj.get_absolute(viewx, viewy, alpha)
  match self.animations.get(self.stance) {
    Some(ani) => ani.draw(@graphics.DrawArgument::new14(absp, self.flip), alpha)
    None => ()
  }
  if not(self.hide_name) {
    self.name_label.draw(absp + @struct.Point::new(0, -4))
    self.func_label.draw(absp + @struct.Point::new(0, 18))
  }
}

///|
pub impl @map_object.MapObject for Npc with update(
  self : Npc,
  physics : @physics.Physics
) -> Int {
  if not(self.base.active) {
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

///|
pub fn set_stance(self : Npc, st : String) -> Unit {
  if self.stance != st {
    self.stance = st
    match self.animations.get(st) {
      Some(ani) => ani.reset()
      None => ()
    }
  }
}

///|
pub fn is_scripted(self : Npc) -> Bool {
  self.scripted
}

///|
pub fn inrange(
  self : Npc,
  cursorpos : @struct.Point[Int],
  viewpos : @struct.Point[Int]
) -> Bool {
  if not(self.base.active) {
    return false
  }
  let absp = self.base.get_position() + viewpos
  let dim = self.animations
    .get(self.stance)
    .map(fn(ani) { ani.get_dimensions() })
    .or_default()
  @struct.Rectangle::from4(
    absp.x - dim.x / 2,
    absp.x + dim.x / 2,
    absp.y - dim.y,
    absp.y,
  ).contains(cursorpos)
}

///|
pub fn get_name(self : Npc) -> String {
  self.name
}

///|
pub fn get_func(self : Npc) -> String {
  self.func
}

///|
pub impl @map_object.MapObject for Npc with get_oid(self : Npc) -> Int {
  self.base.get_oid()
}

///|
pub impl @map_object.MapObject for Npc with makeactive(self : Npc) -> Unit {
  self.base.makeactive()
}

///|
pub fn deactivate(self : Npc) -> Unit {
  self.base.deactivate()
}

///|
pub impl @map_object.MapObject for Npc with is_active(self : Npc) -> Bool {
  self.base.is_active()
}

///|
pub impl @map_object.MapObject for Npc with get_layer(self : Npc) -> Int {
  self.base.get_layer()
}

///|
pub impl @map_object.MapObject for Npc with get_position(self : Npc) -> @struct.Point[
  Int,
] {
  self.base.get_position()
}

///|
pub fn get_npc_object(self : Npc) -> @physics.MovingObject {
  self.base.phobj.moving_object
}

///|
pub fn get_npc_id(self : Npc) -> Int {
  self.npc_id
}
