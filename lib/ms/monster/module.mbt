struct Module {
  map_mobs : MapMobs
}

pub fn Module::new() -> Module {
  { map_mobs: MapMobs::new() }
}

pub fn get_map_mobs(self : Module) -> MapMobs {
  self.map_mobs
}

pub fn make_handlers(self : Module) -> Array[(@net.Opcode, @net.PacketHandler)] {
  [
    (@net.SPAWN_MOB, SpawnMobHandler::new(self.map_mobs)),
    (@net.SPAWN_MOB_C, SpawnMobControllerHandler::new(self.map_mobs)),
  ]
}
