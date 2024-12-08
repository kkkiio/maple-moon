///|
struct Module {
  map_drops : MapDrops
}

///|
pub fn Module::new() -> Module {
  { map_drops: MapDrops::new() }
}

///|
pub fn get_map_drops(self : Module) -> MapDrops {
  self.map_drops
}

///|
pub fn make_handlers(
  self : Module,
  get_character_by_id_fn : (Int) -> @physics.PhysicsObject?
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    (
      @net.DROP_LOOT,
      @net.with_log(
        @net.DROP_LOOT,
        fn(recv : @net.InPacket) { handle_drop_loot!(self.map_drops, recv) },
      ),
    ),
    (
      @net.REMOVE_LOOT,
      @net.with_log(
        @net.REMOVE_LOOT,
        fn(recv : @net.InPacket) {
          handle_remove_loot!(self.map_drops, get_character_by_id_fn, recv)
        },
      ),
    ),
  ]
  |> Map::from_array
}
