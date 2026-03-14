///|
pub fn parse_spawn_npc(recv : @net.InPacket) -> NpcSpawn raise {
  let oid = recv.read_int()
  let id = recv.read_int()
  let position = recv.read_point()
  let flip = recv.read_bool()
  let fh = recv.read_ushort()
  recv.read_short() |> ignore // 'rx'
  recv.read_short() |> ignore // 'ry'
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
pub fn parse_spawn_npc_controller(
  recv : @net.InPacket,
) -> SpawnNpcController raise {
  let mode = recv.read_byte()
  let oid = recv.read_int()
  let npc = if mode == 0 {
    None
  } else {
    let id = recv.read_int()
    let position = recv.read_point()
    let flip = recv.read_bool()
    let fh = recv.read_ushort()
    recv.read_short() |> ignore // 'rx'
    recv.read_short() |> ignore // 'ry'
    recv.read_bool() |> ignore // 'minimap'
    Some({ oid, id, position, flip, fh })
  }
  { mode, oid, npc }
}

///|
pub fn handle_spawn_npc_controller_parsed(
  npcs : MapNpcs,
  ctrl : SpawnNpcController,
) -> Unit {
  if ctrl.mode == 0 {
    npcs.remove(ctrl.oid)
  } else {
    npcs.spawn(ctrl.npc.unwrap())
  }
}

///|
pub enum TalkType {
  SEND_YESNO
  SEND_SIMPLE
  SEND_OK
  SEND_NEXT
  SEND_NEXT_PREV
  SEND_PREV
} derive(Show, Eq, ToJson)

///|
pub fn TalkType::from_int(
  msgtype : Int,
  style_b0 : Int,
  style_b1 : Int,
) -> TalkType? {
  match msgtype {
    0 =>
      match (style_b0, style_b1) {
        (0, 0) => Some(SEND_OK)
        (0, 1) => Some(SEND_NEXT)
        (1, 0) => Some(SEND_PREV)
        (1, 1) => Some(SEND_NEXT_PREV)
        _ => None
      }
    1 => Some(SEND_YESNO)
    4 => Some(SEND_SIMPLE)
    12 => None
    _ => None
  }
}

///|
pub fn TalkType::int_value(self : TalkType) -> Int {
  match self {
    SEND_YESNO => 1
    SEND_SIMPLE => 4
    SEND_OK => 13
    SEND_NEXT => 14
    SEND_NEXT_PREV => 15
    SEND_PREV => 16
  }
}

///|
pub impl Hash for TalkType with hash_combine(self, hasher) {
  hasher.combine(self.int_value())
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
pub(all) enum TalkChoice {
  SEND_YESNO(answer~ : Bool?)
  SEND_SIMPLE(option~ : Int?)
  SEND_OK(ok~ : Unit?)
  SEND_NEXT(next~ : Unit?)
  SEND_NEXT_PREV(next~ : Bool?)
  SEND_PREV(prev~ : Unit?)
} derive(Show)

///|
fn make_talk_message(c : TalkChoice) -> @server_proto.NpcTalkMoreMessage {
  match c {
    TalkChoice::SEND_SIMPLE(option~) =>
      match option {
        Some(option) =>
          {
            lastmsg: TalkType::SEND_SIMPLE.int_value(),
            response: 1,
            selection: Some(option),
          }
        None =>
          {
            lastmsg: TalkType::SEND_SIMPLE.int_value(),
            response: 0,
            selection: None,
          }
      }
    TalkChoice::SEND_YESNO(answer~) =>
      {
        lastmsg: TalkType::SEND_YESNO.int_value(),
        response: match answer {
          Some(true) => 1
          Some(false) => 0
          None => -1
        },
        selection: None,
      }
    TalkChoice::SEND_NEXT(next~) =>
      {
        lastmsg: TalkType::SEND_NEXT.int_value(),
        response: match next {
          Some(_) => 1
          None => -1
        },
        selection: None,
      }
    TalkChoice::SEND_PREV(prev~) =>
      {
        lastmsg: TalkType::SEND_PREV.int_value(),
        response: match prev {
          Some(_) => 1
          None => -1
        },
        selection: None,
      }
    TalkChoice::SEND_OK(ok~) =>
      {
        lastmsg: TalkType::SEND_OK.int_value(),
        response: match ok {
          Some(_) => 1
          None => -1
        },
        selection: None,
      }
    TalkChoice::SEND_NEXT_PREV(next~) =>
      {
        lastmsg: TalkType::SEND_NEXT_PREV.int_value(),
        response: match next {
          Some(true) => 1
          Some(false) => 0
          None => -1
        },
        selection: None,
      }
  }
}

///|
pub fn on_npc_talk_choice(c : TalkChoice) -> Unit {
  @game_server.send(make_talk_message(c))
}

///|
pub fn parse_npc_dialogue(recv : @net.InPacket) -> NpcDialogue raise {
  recv.skip(1)
  let npcid = recv.read_int()
  let msgtype = recv.read_byte() // 0 - textonly, 1 - yes/no, 4 - selection, 12 - accept/decline
  let speaker = recv.read_byte()
  let text = recv.read_string()
  let (style_b0, style_b1) = if recv.available() > 0 && msgtype == 0 {
    (recv.read_ubyte(), recv.read_ubyte())
  } else {
    (0, 0)
  }
  guard TalkType::from_int(msgtype, style_b0, style_b1) is Some(t) else {
    fail("unknown talk type: \{msgtype}, \{style_b0}, \{style_b1}")
  }
  guard Speaker::from_int(speaker) is Some(speaker) else {
    fail("unknown speaker: \{speaker}")
  }
  { npcid, t, speaker, text }
}

///|
pub fn handle_npc_dialogue(
  open_npc_talk_ui : (TalkArgs) -> Unit,
  dialogue : NpcDialogue,
) -> Unit {
  open_npc_talk_ui({
    npc_id: dialogue.npcid,
    speaker: dialogue.speaker,
    str: dialogue.text,
    talk_action: match dialogue.t {
      TalkType::SEND_YESNO =>
        TalkAction::SEND_YESNO(fn(c) {
          on_npc_talk_choice(TalkChoice::SEND_YESNO(answer=c))
        })
      TalkType::SEND_NEXT =>
        TalkAction::SEND_NEXT(fn(c) {
          on_npc_talk_choice(TalkChoice::SEND_NEXT(next=c))
        })
      TalkType::SEND_PREV =>
        TalkAction::SEND_PREV(fn(c) {
          on_npc_talk_choice(TalkChoice::SEND_PREV(prev=c))
        })
      TalkType::SEND_OK =>
        TalkAction::SEND_OK(fn(c) {
          on_npc_talk_choice(TalkChoice::SEND_OK(ok=c))
        })
      TalkType::SEND_SIMPLE =>
        TalkAction::SEND_SIMPLE(fn(c) {
          on_npc_talk_choice(TalkChoice::SEND_SIMPLE(option=c))
        })
      TalkType::SEND_NEXT_PREV =>
        TalkAction::SEND_NEXT_PREV(fn(c) {
          on_npc_talk_choice(TalkChoice::SEND_NEXT_PREV(next=c))
        })
    },
  })
}
