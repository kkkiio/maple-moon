// Handler for a packet which contains all character information on first login
// or warps the player to a different map
struct SetFieldHandler {} derive(Default)

type InPacket

pub fn transition(self : SetFieldHandler, mapid : Int, portalid : Int) -> Unit {
  // GraphicsGL::get().lock()
  Stage::get().clear()
  Timer::get().start()
  GraphicsGL::get().clear()
  Stage::get().load(mapid, portalid)
  UI::get().enable()
  Timer::get().start()
  // GraphicsGL::get().unlock()
  Stage::get().transfer_player()
}

pub fn handle(self : SetFieldHandler, recv : InPacket) -> Unit {
  @Constants.constants.set_viewwidth(Setting::get(configWidth).load())
  @Constants.constants.set_viewheight(Setting::get(configHeight).load())
  // let channel = recv.read_int()
  // let mode1 = recv.read_byte()
  // let mode2 = recv.read_byte()
  // if mode1 == 0 && mode2 == 0 {
  //   change_map(recv, channel)
  // } else {
  //   set_field(recv)
  // }
}
