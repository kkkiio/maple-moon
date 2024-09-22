struct Module {
  map_drops : MapDrops
}

pub fn Module::new() -> Module {
  { map_drops: MapDrops::new() }
}

pub fn get_map_drops(self : Module) -> MapDrops {
  self.map_drops
}

pub fn make_handlers(self : Module) -> Array[(@net.Opcode, @net.PacketHandler)] {
  [(@net.DROP_LOOT, DropLootHandler::new(self.map_drops))]
}
