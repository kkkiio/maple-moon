struct Module {
  npcs : MapNpcs
  container : @ui.Container
  get_player_name : () -> String
}

pub fn Module::new(
  container : @ui.Container,
  get_player_name : () -> String
) -> Module {
  let npcs = MapNpcs::new(container, get_player_name)
  { npcs, container, get_player_name }
}

pub fn make_handlers(
  self : Module
) -> Array[(@net.Opcode, (@net.InPacket) -> Unit)] {
  [
    (
      @net.SPAWN_NPC,
      @net.with_log(
        @net.SPAWN_NPC,
        fn(recv : @net.InPacket) { handle_spawn_npc!(self.npcs, recv) },
      ),
    ),
    (
      @net.SPAWN_NPC_C,
      @net.with_log(
        @net.SPAWN_NPC_C,
        fn(recv : @net.InPacket) {
          handle_spawn_npc_controller!(self.npcs, recv)
        },
      ),
    ),
    (
      @net.NPC_DIALOGUE,
      @net.with_log(
        @net.NPC_DIALOGUE,
        fn(recv : @net.InPacket) {
          handle_npc_dialogue!(self.container, self.get_player_name, recv)
        },
      ),
    ),
  ]
}

pub fn get_npcs(self : Module) -> MapNpcs {
  self.npcs
}

pub fn handle_spawn_npc(npcs : MapNpcs, recv : @net.InPacket) -> Unit! {
  let oid = recv.read_int!()
  let id = recv.read_int!()
  let position = recv.read_point!()
  let flip = recv.read_bool!()
  let fh = recv.read_ushort!()
  recv.read_short!() |> ignore // 'rx'
  recv.read_short!() |> ignore // 'ry'
  npcs.spawn({ oid, id, position, flip, fh })
}

pub fn handle_spawn_npc_controller(
  npcs : MapNpcs,
  recv : @net.InPacket
) -> Unit! {
  let mode = recv.read_byte!()
  let oid = recv.read_int!()
  if mode == 0 {
    npcs.remove(oid)
  } else {
    let id = recv.read_int!()
    let position = recv.read_point!()
    let flip = recv.read_bool!()
    let fh = recv.read_ushort!()
    recv.read_short!() |> ignore // 'rx'
    recv.read_short!() |> ignore // 'ry'
    recv.read_bool!() |> ignore // 'minimap'
    npcs.spawn({ oid, id, position, flip, fh })
  }
}

pub fn handle_npc_dialogue(
  container : @ui.Container,
  get_player_name : () -> String,
  recv : @net.InPacket
) -> Unit! {
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
  let npcTalk = UINpcTalk::new()
  container.add_ui(@ui.Element::new(npcTalk), UINpcTalk::const_focused())
  npcTalk.change_text!(
    npcid,
    msgtype,
    style_b0,
    style_b1,
    speaker,
    text,
    get_player_name(),
  )
}
