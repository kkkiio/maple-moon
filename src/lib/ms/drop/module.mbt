///|
struct Module {
  map_drops : MapDrops
}

///|
pub fn Module::load(
  string_loader : @resource.SyncLoader
) -> @utils.Future[Module] {
  special_item_loader
  .load_res(["0900.img"])
  .map(fn(src) { { map_drops: MapDrops::new(string_loader, src) } })
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
    @net.make_handler(@net.DROP_LOOT, parse_drop_loot, fn(drop : DropLoot) {
      handle_drop_loot_parsed(self.map_drops, drop)
    }),
    @net.make_handler(
      @net.REMOVE_LOOT,
      fn(recv) { parse_remove_loot!(get_character_by_id_fn, recv) },
      fn(remove : RemoveLoot) {
        handle_remove_loot_parsed(self.map_drops, remove)
      },
    ),
  ]
  |> Map::from_array
}
