///|
struct Module {
  map_drops : MapDrops
}

///|
pub async fn Module::load(io_service : @io_task.IOService) -> Module {
  let special_item_loader : @resource.AsyncLoader = @resource.AsyncLoader::new(
    "special_item",
    loader=@resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Item/Special",
    ),
  )
  let src = special_item_loader.load_res_async(["0900.img"])
  { map_drops: MapDrops::new(io_service, src) }
}

///|
pub fn Module::get_map_drops(self : Module) -> MapDrops {
  self.map_drops
}

///|
pub fn Module::make_handlers(
  self : Module,
  get_character_by_id_fn : (Int) -> @physics.PhysicsObject?,
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    @net.make_handler(@net.DROP_LOOT, parse_drop_loot, fn(drop : DropLoot) {
      handle_drop_loot_parsed(self.map_drops, drop)
    }),
    @net.make_handler(@net.REMOVE_LOOT, fn(recv) { parse_remove_loot(recv) }, fn(
      remove : RemoveLoot,
    ) {
      handle_remove_loot_parsed(self.map_drops, remove, get_character_by_id_fn)
    }),
  ]
  |> Map::from_array
}
