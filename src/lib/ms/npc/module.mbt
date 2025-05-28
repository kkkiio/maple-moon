///|
struct Module {
  npcs : MapNpcs
  container : &@ui.Container
  get_player_name : () -> String
  npc_talk_resource : NpcTalkResource
  packet_processor : @net.Network
}

///|
pub fn Module::load(
  container : &@ui.Container,
  get_player_name : () -> String,
  packet_processor : @net.Network
) -> @utils.Future[Module] {
  @ui.ui_window_2_loader().load_res(["UtilDlgEx"])
  |> @utils.map(fn(it) {
    let npc_talk_resource = NpcTalkResource::from_resource(it)
    Module::new(container, get_player_name, npc_talk_resource, packet_processor)
  })
}

///|
fn Module::new(
  container : &@ui.Container,
  get_player_name : () -> String,
  npc_talk_resource : NpcTalkResource,
  packet_processor : @net.Network
) -> Module {
  let npcs = MapNpcs::new(
    fn(args) {
      open_npc_talk_ui(npc_talk_resource, container, get_player_name, args)
    },
    packet_processor,
  )
  { npcs, container, get_player_name, npc_talk_resource, packet_processor }
}

///|
pub fn Module::open_npc_talk_ui(self : Module, args : TalkArgs) -> Unit {
  open_npc_talk_ui(
    self.npc_talk_resource,
    self.container,
    self.get_player_name,
    args,
  )
}

///|
fn open_npc_talk_ui(
  npc_talk_resource : NpcTalkResource,
  container : &@ui.Container,
  get_player_name : () -> String,
  args : TalkArgs
) -> Unit {
  let elem = @ui.Element::new(
    fn(hooks) {
      let ui = new_npc_talk_ui(
        hooks,
        npc_talk_resource,
        container,
        args,
        get_player_name(),
      )
      ui
    },
    @ui.UIElementType::NPC_TALK,
  )
  container.add_ui(elem, UINpcTalk::const_focused())
}

///|
pub fn make_handlers(
  self : Module
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    @net.make_handler(@net.SPAWN_NPC, parse_spawn_npc, fn(npc) {
      handle_spawn_npc_parsed(self.npcs, npc)
    }),
    @net.make_handler(@net.SPAWN_NPC_C, parse_spawn_npc_controller, fn(
      ctrl : SpawnNpcController
    ) {
      handle_spawn_npc_controller_parsed(self.npcs, ctrl)
    }),
    @net.make_handler(@net.NPC_DIALOGUE, parse_npc_dialogue, fn(
      dialogue : NpcDialogue
    ) {
      handle_npc_dialogue(
        self.container,
        self.get_player_name,
        self.npc_talk_resource,
        self.packet_processor,
        dialogue,
      )
    }),
  ]
  |> Map::from_array
}

///|
pub fn get_npcs(self : Module) -> MapNpcs {
  self.npcs
}

///|
pub fn parse_spawn_npc(recv : @net.InPacket) -> NpcSpawn! {
  let oid = recv.read_int!()
  let id = recv.read_int!()
  let position = recv.read_point!()
  let flip = recv.read_bool!()
  let fh = recv.read_ushort!()
  recv.read_short!() |> ignore // 'rx'
  recv.read_short!() |> ignore // 'ry'
  { oid, id, position, flip, fh }
}

///|
pub fn handle_spawn_npc_parsed(npcs : MapNpcs, npc : NpcSpawn) -> Unit {
  npcs.spawn(npc)
}

///|
pub struct SpawnNpcController {
  mode : Int
  oid : Int
  npc : NpcSpawn?
} derive(Show, ToJson)

///|
pub fn parse_spawn_npc_controller(recv : @net.InPacket) -> SpawnNpcController! {
  let mode = recv.read_byte!()
  let oid = recv.read_int!()
  let npc = if mode == 0 {
    None
  } else {
    let id = recv.read_int!()
    let position = recv.read_point!()
    let flip = recv.read_bool!()
    let fh = recv.read_ushort!()
    recv.read_short!() |> ignore // 'rx'
    recv.read_short!() |> ignore // 'ry'
    recv.read_bool!() |> ignore // 'minimap'
    Some({ oid, id, position, flip, fh })
  }
  { mode, oid, npc }
}

///|
pub fn handle_spawn_npc_controller_parsed(
  npcs : MapNpcs,
  ctrl : SpawnNpcController
) -> Unit {
  if ctrl.mode == 0 {
    npcs.remove(ctrl.oid)
  } else {
    npcs.spawn(ctrl.npc.unwrap())
  }
}

///|
pub struct NpcDialogue {
  npcid : Int
  t : TalkType
  speaker : Speaker
  text : String
} derive(Show, ToJson)

///|
pub(all) enum Speaker {
  NPC_LEFT = 0
  NPC_RIGHT = 1
  PLAYER_LEFT = 2
  PLAYER_RIGHT = 3
} derive(Show, ToJson)

///|
pub fn Speaker::from_int(i : Int) -> Speaker? {
  let res = match i {
    0 => NPC_LEFT
    1 => NPC_RIGHT
    2 => PLAYER_LEFT
    3 => PLAYER_RIGHT
    _ => return None
  }
  Some(res)
}

///|
pub fn Speaker::int_value(self : Speaker) -> Int = "%identity"

///|
pub fn parse_npc_dialogue(recv : @net.InPacket) -> NpcDialogue! {
  recv.skip!(1)
  let npcid = recv.read_int!()
  let msgtype = recv.read_byte!() // 0 - textonly, 1 - yes/no, 4 - selection, 12 - accept/decline
  let speaker = recv.read_byte!()
  let text = recv.read_string!()
  let (style_b0, style_b1) = if recv.available() && msgtype == 0 {
    // {b0, b1}
    // {0, 1} = next
    // {1, 0} = prev
    // {1, 1} = nextPrev ??
    // {0, 0} = ok
    (recv.read_ubyte!(), recv.read_ubyte!())
  } else {
    (0, 0)
  }
  guard TalkType::from_int(msgtype, style_b0, style_b1) is Some(t) else {
    fail!("unknown talk type: \{msgtype}, \{style_b0}, \{style_b1}")
  }
  guard Speaker::from_int(speaker) is Some(speaker) else {
    fail!("unknown speaker: \{speaker}")
  }
  { npcid, t, speaker, text }
}

///|
pub fn handle_npc_dialogue(
  container : &@ui.Container,
  get_player_name : () -> String,
  npc_talk_resource : NpcTalkResource,
  network : @net.Network,
  dialogue : NpcDialogue
) -> Unit {
  container.add_ui(
    @ui.Element::new(
      fn(hooks) {
        let ui = new_npc_talk_ui(
          hooks,
          npc_talk_resource,
          container,
          {
            npc_id: dialogue.npcid,
            speaker: dialogue.speaker,
            str: dialogue.text,
            talk_action: match dialogue.t {
              TalkType::SEND_YESNO =>
                SEND_YESNO(fn(c) {
                  on_npc_talk_choice(network, TalkChoice::SEND_YESNO(answer=c))
                })
              TalkType::SEND_NEXT =>
                SEND_NEXT(fn(c) {
                  on_npc_talk_choice(network, TalkChoice::SEND_NEXT(next=c))
                })
              TalkType::SEND_PREV =>
                SEND_PREV(fn(c) {
                  on_npc_talk_choice(network, TalkChoice::SEND_PREV(prev=c))
                })
              TalkType::SEND_OK =>
                SEND_OK(fn(c) {
                  on_npc_talk_choice(network, TalkChoice::SEND_OK(ok=c))
                })
              TalkType::SEND_SIMPLE =>
                SEND_SIMPLE(fn(c) {
                  on_npc_talk_choice(network, TalkChoice::SEND_SIMPLE(option=c))
                })
            },
          },
          get_player_name(),
        )
        ui
      },
      @ui.UIElementType::NPC_TALK,
    ),
    UINpcTalk::const_focused(),
  )
}

///|
fn new_npc_talk_ui(
  hooks : @ui.Hooks,
  npc_talk_resource : NpcTalkResource,
  container : &@ui.Container,
  args : TalkArgs,
  player_name : String
) -> UINpcTalk {
  let ui = UINpcTalk::new(npc_talk_resource, hooks)
  ui
  .change_text?(
    args.npc_id,
    match args.talk_action {
      SEND_YESNO(callback) =>
        SEND_YESNO(fn(c) {
          container.remove_ui(@ui.UIElementType::NPC_TALK)
          callback(c)
        })
      SEND_NEXT(callback) =>
        SEND_NEXT(fn(c) {
          container.remove_ui(@ui.UIElementType::NPC_TALK)
          callback(c)
        })
      SEND_PREV(callback) =>
        SEND_PREV(fn(c) {
          container.remove_ui(@ui.UIElementType::NPC_TALK)
          callback(c)
        })
      SEND_OK(callback) =>
        SEND_OK(fn(c) {
          container.remove_ui(@ui.UIElementType::NPC_TALK)
          callback(c)
        })
      SEND_SIMPLE(callback) =>
        SEND_SIMPLE(fn(c) {
          container.remove_ui(@ui.UIElementType::NPC_TALK)
          callback(c)
        })
    },
    args.speaker,
    args.str,
    player_name,
  )
  .unwrap() // TODO: handle error
  ui
}

///|
fn on_npc_talk_choice(network : @net.Network, c : TalkChoice) -> Unit {
  network.send_packet(make_talk_packet(c))
}
