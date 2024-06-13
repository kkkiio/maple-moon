// Handler for a packet which contains all character information on first login
// or warps the player to a different map
struct SetFieldHandler {} derive(Default)

pub fn transition(self : SetFieldHandler, mapid : Int, portalid : Int) -> Unit {
  // GraphicsGL::get().lock()
  Stage::get().clear()
  Timer::get().start()
  GraphicsGL::get().clear()
  Stage::get().load(mapid, portalid)
  UI::get().enable()
  Timer::get().start()
  // GraphicsGL::get().unlock()
  // Stage::get().transfer_player()
}
