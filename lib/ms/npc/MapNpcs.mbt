struct MapNpcs {
  npcs : @map_object.MapObjects[Npc]
  spawns : @queue.T[NpcSpawn]
  container : @ui.Container
  get_player_name : () -> String
}

pub fn MapNpcs::new(
  container : @ui.Container,
  get_player_name : () -> String
) -> MapNpcs {
  {
    npcs: @map_object.MapObjects::new(),
    spawns: @queue.new(),
    container,
    get_player_name,
  }
}

/// Packet which requests a dialog with a server-sided NPC
fn new_talk_to_npc_packet(oid : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::TALK_TO_NPC)..write_int(oid)
}

pub fn draw(
  self : MapNpcs,
  layer : @layer.Id,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  self.npcs.draw(layer, viewx, viewy, alpha)
}

pub fn update(self : MapNpcs, physics : @physics.Physics) -> Unit {
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
  position : @struct.Point[Int],
  viewpos : @struct.Point[Int]
) -> @ui.CursorState {
  for _, map_object in self.npcs {
    let npc = map_object
    if npc.is_active() && npc.inrange(position, viewpos) {
      if pressed {
        match npc.talk() {
          Some({ id, msgtype, b0, b1, speaker, str }) => {
            let ui = UINpcTalk::new()
            self.container.add_ui(
              @ui.Element::new(ui, @ui.UIElementType::NPC_TALK),
              UINpcTalk::const_focused(),
            )
            ui
            .change_text?(
              id,
              msgtype,
              b0,
              b1,
              speaker,
              str,
              (self.get_player_name)(),
            )
            .unwrap()
          }
          None => ()
        }
        new_talk_to_npc_packet(npc.get_oid()).dispatch()
        return @ui.CursorState::IDLE
      }
      return @ui.CursorState::CAN_CLICK
    }
  }
  if pressed {
    @ui.CursorState::CLICKING
  } else {
    @ui.CursorState::IDLE
  }
}

struct NpcSpawn {
  oid : Int
  id : Int
  position : @struct.Point[Int]
  flip : Bool
  fh : Int
}

pub fn get_oid(self : NpcSpawn) -> Int {
  self.oid
}

pub fn instantiate(self : NpcSpawn, physics : @physics.Physics) -> Npc {
  let spawnposition = physics.get_y_below(self.position)
  Npc::new(self.id, self.oid, self.flip, self.fh, spawnposition)
}

/// Represents a NPC on the current map
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

pub struct TalkArgs {
  id : Int
  msgtype : Int
  b0 : Int
  b1 : Int
  speaker : Int
  str : String
}

pub fn talk(self : Npc) -> TalkArgs? {
  if self.scripted {
    return None
  }
  match
    self.dialogue["d0"]
    .filter(fn(strs) { strs.is_empty().not() })
    .map(fn(strs) { strs[0] }) {
    Some(str) =>
      Some({ id: self.npc_id, msgtype: 0, b0: 0, b1: 1, speaker: 0, str })
    None => None
  }
}

pub fn Npc::new(
  id : Int,
  o : Int,
  fl : Bool,
  f : Int,
  position : @struct.Point[Int]
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
  // let mouse_only = info["talkMouseOnly"].get_bool?().unwrap()
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
  let flip = fl.not()
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
    random: @utils.Randomizer::default(),
    name_label,
    func_label,
  }
}

pub fn draw(self : Npc, viewx : Double, viewy : Double, alpha : Double) -> Unit {
  let absp = self.base.phobj.get_absolute(viewx, viewy, alpha)
  match self.animations.get(self.stance) {
    Some(ani) => ani.draw(@graphics.DrawArgument::new14(absp, self.flip), alpha)
    None => ()
  }
  if self.hide_name.not() {
    self.name_label.draw(absp + @struct.Point::new(0, -4))
    self.func_label.draw(absp + @struct.Point::new(0, 18))
  }
}

pub fn update(self : Npc, physics : @physics.Physics) -> Int {
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
  cursorpos : @struct.Point[Int],
  viewpos : @struct.Point[Int]
) -> Bool {
  if self.base.active.not() {
    return false
  }
  let absp = self.base.get_position() + viewpos
  let dim = self.animations[self.stance]
    .map(fn(ani) { ani.get_dimensions() })
    .or_default()
  @struct.Rectangle::from4(
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

pub fn get_position(self : Npc) -> @struct.Point[Int] {
  self.base.get_position()
}
